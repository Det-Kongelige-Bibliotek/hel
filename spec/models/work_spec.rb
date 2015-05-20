require 'spec_helper'

describe Work do
  include_context 'shared'
  describe 'init' do
    it 'can be initialized with default params' do
      w = Work.new(work_params)
      expect(w).to be_a Work
    end
  end
  describe 'on creation' do
    it 'should have a uuid on creation' do
      w = Work.new(work_params)
      expect(w.uuid).to be_nil
      w.add_author(person)
      w.save
      expect(w.uuid.present?).to be true
    end
  end

  describe 'validation' do
    it 'should require a title' do
      w = Work.new
      expect(w.valid?).to eql false
      expect(w.errors.messages.keys).to include :titles
    end

    it 'should require a creator' do
      w = Work.new
      expect(w.valid?).to eql false
      expect(w.errors.messages.keys).to include :creators
    end
  end

  # Note - this test suite is slow because
  # adding relationships automatically triggers
  # Fedora saves (it needs a pid to create a relationship)
  # Sorry - but I don't think this can be improved without
  # a Fedora mock (which doesn't exist)
  describe 'Relations:' do
    before :each do
      @work = Work.new(work_params)
      @work.add_author(person)
      @work.save # for these tests to work. Object has to be persisted. Otherwise relations cannot be updated
      @rel = Work.new
      @rel.add_title({'value'=> 'A title'})
      @rel.add_author(person)
      @rel.save # for these tests to work. Object has to be persisted. Otherwise relation cannot be updated
    end

    it 'has many Instances' do
      expect(@work.instances).to respond_to :each
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

    it 'has many parts' do
      @work.parts << @rel
      expect(@work.parts).to include @rel
      expect(@rel.is_part_of).to eql @work
    end

    # Not sure how we should handle Subject
    # TODO: Implement when this is cleared up
    # it 'can have an agent as a subjects' do
    #   @work.add_subject(@agent)
    #   expect(@work.subjects).to include @agent
    # end
    #
    # it 'can have a Work as a subject' do
    #   @work.add_subject(@rel)
    #   expect(@work.subjects).to include @rel
    # end

    # it 'expresses its subject relations in rdf' do
    #   @work.add_subject(@agent)
    #   expect(@work.to_rdf).to include 'bf:subject'
    # end


    it 'can have an author' do
      a = Authority::Person.create(
          'authorized_personal_name' => { 'given'=> 'Fornavn', 'family' => 'Efternavn', 'scheme' => 'KB', 'date' => '1932/2009' }
      )
      @work.add_author(a)
      @work.save
      @work.reload
      a.reload
      expect(@work.authors).to include a
    end

    it 'can have a recipient' do
      @work.add_recipient(person)
      @work.add_author(person)
      @work.save
      @work.reload
      person.reload
      expect(@work.recipients).to include person
    end

    describe 'author_names' do
      it 'returns a hash of all author names' do
        authors = @work.author_names
        expect(authors.keys.first).to be_a String
        expect(authors.values.first).to be_an Authority::Person
      end
    end

    describe 'find_matching_author' do
      it 'returns an author object for the name fragment supplied' do
        expect(@work.find_matching_author('James')).to be_an Authority::Person
      end

      it 'returns nil if no match is found' do
        expect(@work.find_matching_author('Niall')).to eql nil
      end
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

    it 'should update the index when the title value changes' do
      title = Title.new(value: 'A terrible title')
      @work.titles << title
      @work.save
      expect(Finder.works_by_title('A terrible title').size).to eql 1
      title.update(value: 'A somewhat better title')
      expect(Finder.works_by_title('A somewhat better title').size).to eql 1
    end

    it 'should contain all author names' do
      aut = Authority::Person.create(
          'authorized_personal_name' => { 'scheme' => 'viaf', 'family' => 'Joyce', 'given' => 'James', 'date' => '1932/2009' })
      @work.add_author(aut)
      vals = @work.to_solr.values.flatten
      expect(vals).to include 'Joyce, James'
    end
  end

  describe 'originDate' do
    before :each do
      @valid_work = Work.new(work_params)
      @valid_work.add_author(person)
    end
    it 'can have an origin date' do
      @valid_work.origin_date = '1985'
      expect(@valid_work.origin_date).to eql '1985'
    end
    it 'will not save an invalid EDTF date' do
      expect(@valid_work.valid?).to be true
      @valid_work.origin_date = 'sometime last week'
      expect(@valid_work.valid?).to be false
    end

    it 'will save a valid EDTF date' do
      @valid_work.origin_date = '2004-02-01/2005'
      expect(@valid_work.valid?).to be true
    end
  end

end
