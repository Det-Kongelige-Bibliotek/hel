require 'spec_helper'

describe Work do
  include_context 'shared'
  describe 'on creation' do
    it 'should have a uuid on creation' do
      w = Work.new
      expect(w.uuid).to be_nil
      w.save
      expect(w.uuid.present?).to be true
    end
  end

  # Note - this test suite is slow because
  # adding relationships automatically triggers
  # Fedora saves (it needs a pid to create a relationship)
  # Sorry - but I don't think this can be improved without
  # a Fedora mock (which doesn't exist)
  describe 'Relations:' do
    before :each do
      @agent = Authority::Person.create(
          'authorized_personal_name' => { 'given'=> 'Fornavn', 'family' => 'Efternavn', 'scheme' => 'KB', 'date' => '1932/2009' }
      )
      @work = Work.new
      @work.add_title({'value'=> 'A title'})
      @work.add_author(@agent)
      @work.save # for these tests to work. Object has to be persisted. Otherwise relations cannot be updated
      @rel = Work.new
      @rel.add_title({'value'=> 'A title'})
      @rel.add_author(@agent)
      @rel.save # for these tests to work. Object has to be persisted. Otherwise relation cannot be updated
    end

    it 'has many Instances' do
      expect(@work.instances).to respond_to :each
    end

    it 'can be part of an Instance' do
      i = Instance.new
      i.parts << @work
      expect(i.parts).to include @work
    end

    it 'can be related to other works' do
      @work.add_related(@rel)
      expect(@work.related_works).to include @rel
      expect(@rel.related_works).to include @work
    end

    it 'can be preceded by other works' do
      @work.add_preceding(@rel)
      expect(@work.preceding_works).to include @rel
      expect(@rel.succeeding_works).to include @work
    end

    it 'can be followed by other works' do
      @work.add_succeeding(@rel)
      expect(@work.succeeding_works).to include @rel
      expect(@rel.preceding_works).to include @work
    end

    it 'can have an agent as a subjects' do
      @work.add_subject(@agent)
      expect(@work.subjects).to include @agent
    end

    it 'can have a Work as a subject' do
      @work.add_subject(@rel)
      expect(@work.subjects).to include @rel
    end
    it 'expresses its subject relations in rdf' do
      @work.add_subject(@agent)
      expect(@work.to_rdf).to include 'bf:subject'
    end

    it 'can be part of a work' do
      @work.is_part_of = @rel
      expect(@work.is_part_of).to eql @rel
    end

    it 'can contain other works' do
      @work.parts << @rel
      expect(@work.parts).to include @rel
    end

  end
  describe 'person relations' do

    before :all do
      @victor = Authority::Person.create(
          'authorized_personal_name' => { 'given'=> 'Victor', 'family' => 'Andreasen', 'scheme' => 'KB', 'date' => '1932/2009' }
      )
      @tove = Authority::Person.create(
          'authorized_personal_name' => { 'given'=> 'Tove', 'family' => 'Ditlevsen', 'scheme' => 'KB', 'date' => '1932/2009' }
      )
      @work2 = Work.new
      @work2.add_title({'value'=> 'A title'})
      @work2.add_author(@victor)
      @work2.add_recipient(@tove)
      fail unless @work2.save
      @work2.reload
      @victor.reload
      @tove.reload
    end

    it 'can have an author' do
      expect(@work2.authors).to include @victor
      expect(@victor.authored_works).to include @work2
    end

    it 'can have a recipient' do
      expect(@work2.recipients).to include @tove
      expect(@tove.received_works).to include @work2
    end

    it 'can return the names of authors in a searchable hash' do
      expect(@work2.author_names.keys.first).to eql 'Andreasen, Victor'
    end

    it 'will return the person object matching a given string' do
      expect(@work2.find_matching_author('Victor').id).to eql @victor.id
    end

    it 'will return nil if no matching person object is found' do
      expect(@work2.find_matching_author('Charles')).to be_nil
    end

    # I know this doesn't belong in this section
    # TODO: move into a *general* section
    it 'should be possible to add a language' do
      @work2.add_language('eng')
      @work2.save
      @work2.reload
      expect(@work2.language_values).to include 'eng'
    end
  end

  # In the absence of a proper RDF validator on Ruby
  # these tests are mainly thought of as smoke tests;
  # they will catch the worst bugs, but not subtle problems
  # with invalid RDF output.
  describe 'to_rdf' do
    before :all do
      agent = Authority::Person.create(
          'authorized_personal_name' => { 'given'=> 'Fornavn', 'family' => 'Efternavn', 'scheme' => 'KB', 'date' => '1932/2009' }
      )
      @work = Work.new
      @work.add_title({'value'=> 'A title'})
      @work.add_author(agent)
      @work.save # for these tests to work. Object has to be persisted. Otherwise relations cannot be updated
    end
    # This test will only catch the worst errors
    # as the Reader is very forgiving
    # TODO: Find a more stringent validator
    it 'is valid rdf' do
      expect {
        RDF::RDFXML::Reader.new(@work.to_rdf, validate: true)
      }.not_to raise_error
    end

    it 'includes the hasInstance relations' do
      @work.instances << Instance.new(instance_params)
      @work.save
      expect(@work.to_rdf).to include('hasInstance')
    end
  end

  describe 'to_solr' do
    before :each do
      agent = Authority::Person.create(
          'authorized_personal_name' => { 'given'=> 'Fornavn', 'family' => 'Efternavn', 'scheme' => 'KB', 'date' => '1932/2009' }
      )
      @work = Work.new
      @work.add_title({'value'=> 'A title'})
      @work.add_author(agent)
      @work.save # for these tests to work. Object has to be persisted. Otherwise relations cannot be updated
    end

    it 'should contain all title values' do
      @work.add_title(value: 'Vice Squad!')
      vals = @work.to_solr.values.flatten
      expect(vals).to include 'Vice Squad!'
    end

    it 'should contain all author names' do
      aut = Authority::Person.create(
          'authorized_personal_name' => { 'scheme' => 'viaf', 'family' => 'Joyce', 'given' => 'James', 'date' => '1932/2009' })
      @work.add_author(aut)
      puts("creators #{@work.creators}")
      vals = @work.to_solr.values.flatten
      expect(vals).to include 'Joyce, James'
    end

    it 'should be able to add a list of title hash' do
      title1 = HashWithIndifferentAccess.new
      title2 = HashWithIndifferentAccess.new
      title3 = HashWithIndifferentAccess.new
      title1[:value] = "Title1"
      title2[:value] = "Title2"
      title3[:value] = "Title3"
      @work.titles = {'0' => title1,'1' => title2}
      @work.title_values.should == ['Title1','Title2']
      @work.titles = {'0' => title1,'1' => title3}
      @work.title_values.should == ['Title1','Title3']
    end
  end
end
