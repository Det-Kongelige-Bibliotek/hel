require 'spec_helper'

describe Work do
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
      @work = Work.new
      @rel = Work.new
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

    it 'can have a creator' do
      a = Authority::Agent.new
      @work.add_creator(a)
      expect(@work.creators).to include a
      expect(a.created_works).to include @work
    end

    it 'can have an author' do
      a = Authority::Agent.new
      @work.add_author(a)
      expect(@work.authors).to include a
      expect(a.authored_works).to include @work
    end

    it 'can have a recipient' do
      a = Authority::Agent.new
      @work.add_recipient(a)
      expect(@work.recipients).to include a
      expect(a.received_works).to include @work
    end
  end

  describe 'to_solr' do
    before :each do
      @work = Work.new
    end

    it 'should contain all title values' do
      @work.add_title(value: 'Vice Squad!')
      vals = @work.to_solr.values.flatten
      expect(vals).to include 'Vice Squad!'
    end

    it 'should contain all author names' do
      aut = Authority::Person.new
      aut.add_authorized_personal_name(scheme: 'viaf', full: 'James Joyce')
      @work.add_author(aut)
      vals = @work.to_solr.values.flatten
      expect(vals).to include 'James Joyce'
    end
  end
end
