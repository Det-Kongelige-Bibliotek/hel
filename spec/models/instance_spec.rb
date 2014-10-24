require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe Instance do
  before :all do
    @instance = Instance.new
  end

  describe 'relations' do
    it 'has many files' do
      expect(@instance.content_files.size).to eql 0
    end

    it 'can be an instance of a work' do
      expect(@instance.respond_to?(:work)).to eql true
    end

    it 'can have parts which are Works' do
      w = Work.new
      @instance.parts << w
      expect(@instance.parts).to include w
    end
  end

  describe 'administration' do
    it 'should be possible to edit the activity field' do
      @instance.activity.should be_nil
      @instance.activity = 'TEST'
      @instance.activity.should == 'TEST'
    end

    it 'should be possible to edit the workflow_status field' do
      @instance.workflow_status.should be_nil
      @instance.workflow_status = 'TEST'
      @instance.workflow_status.should == 'TEST'
    end

    it 'should be possible to edit the embargo field' do
      @instance.embargo.should be_nil
      @instance.embargo = 'TEST'
      @instance.embargo.should == 'TEST'
    end

    it 'should be possible to edit the embargo_date field' do
      @instance.embargo_date.should be_nil
      @instance.embargo_date = 'TEST'
      @instance.embargo_date.should == 'TEST'
    end

    it 'should be possible to edit the embargo_condition field' do
      @instance.embargo_condition.should be_nil
      @instance.embargo_condition = 'TEST'
      @instance.embargo_condition.should == 'TEST'
    end

    it 'should be possible to edit the access_condition field' do
      @instance.access_condition.should be_nil
      @instance.access_condition = 'TEST'
      @instance.access_condition.should == 'TEST'
    end

    it 'should be possible to edit the copyright field' do
      @instance.copyright.should be_nil
      @instance.copyright = 'TEST'
      @instance.copyright.should == 'TEST'
    end

    it 'should be possible to edit the material_type field' do
      @instance.material_type.should be_nil
      @instance.material_type = 'TEST'
      @instance.material_type.should == 'TEST'
    end

    it 'should be possible to edit the availability field' do
      @instance.availability.should be_nil
      @instance.availability = 'TEST'
      @instance.availability.should == 'TEST'
    end
  end

  it 'should have a uuid on creation' do
    i = Instance.new
    expect(i.uuid).to be_nil
    i.save
    expect(i.uuid.present?).to be true
  end

  describe 'to_solr' do
    it 'should include the title statement' do
      i = Instance.new
      i.title_statement = 'King James Edition'
      vals = i.to_solr.values.flatten
      expect(vals).to include 'King James Edition'
    end
  end
end
