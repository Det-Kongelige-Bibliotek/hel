require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe Instance do
  include_context 'shared'

  puts "getting to test 0"
  let(:work_attributes) do
    agent = Authority::Person.create( 'given_name'=> 'Fornavn', 'family_name' => 'Efternavn',  'birth_date' => '1932' , 'death_date' => '2009'    )
#    $valid_attributes = {titles: {'0' => {'value'=> 'A work title'}  }}
  end
    puts "getting to test 1"
# 'scheme' => 'KB',
# , creators: {'0'=>{'id'=> agent.id, 'type'=>'aut'


#  before :all do
#    ActiveFedora::Base.delete_all
#  end

  before :each do
    puts valid_trykforlaeg
    puts instance_params
    puts "getting to test 2"
#    @instance = Instance.new()
    @instance = Instance.new(instance_params)
    puts "getting to test 3"
  end

  describe 'relations' do
#    it 'has many files' do
#      expect(@instance.content_files.size).to eql 0
#    end
    puts "getting to test 4"
    it 'can have an equivalent instance' do
      puts "getting to test 5"
      i = Instance.new(instance_params)
      @instance.set_equivalent= i
      puts "@instance.equivalents"
      puts @instance.equivalents
      puts "i.equivalents"
      puts i.equivalents
      i.save
      @instance.save
      expect(@instance.equivalents).to include i
      expect(i.equivalents).to include @instance
    end
    
  end
=begin
    describe 'to work' do
      before :each do
        @i = Instance.create(instance_params)
        @w = Work.create(work_attributes)
        @i.set_work = @w
        @i.save
        @i.reload
        @w.reload
      end

      it 'can be an instance of a work' do
        expect(@i.work.first.pid).to eql @w.pid
      end

      it 'is a symmetrical relationship' do
        expect(@w.instances).to include @i
      end

      it 'is expressed symmetrically in rels-ext' do
        expect(@w.rels_ext.to_rels_ext).to include('hasInstance')
        expect(@i.rels_ext.to_rels_ext).to include('instanceOf')
      end
    end

    it 'can have parts which are Works' do
      w = Work.create(work_attributes)
      @instance.parts << w
      expect(@instance.parts).to include w
    end
  end

  describe 'administration' do
    it 'should be possible to edit the activity field' do
      @instance.activity = 'TEST'
      @instance.activity.should == 'TEST'
    end

    it 'should be possible to edit the workflow_status field' do
      @instance.workflow_status.should be_nil
      @instance.workflow_status = 'TEST'
      @instance.workflow_status.should == 'TEST'
    end

    it 'should be possible to edit the embargo field' do
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
      @instance.copyright = 'TEST'
      @instance.copyright.should == 'TEST'
    end

    it 'should be possible to edit the material_type field' do
      @instance.material_type.should be_nil
      @instance.material_type = 'TEST'
      @instance.material_type.should == 'TEST'
    end

    it 'should be possible to edit the availability field' do
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

  describe 'to_mods' do
    it 'is wellformed XML' do
      instance = Instance.create(instance_params)
      xsd = Nokogiri::XML::Schema(open('http://www.loc.gov/standards/mods/v3/mods-3-5.xsd').read)
      errors = xsd.validate(Nokogiri::XML.parse(instance.to_mods) { |config| config.strict })
      expect(errors).to eql []
    end
  end

  describe 'to_rdf' do
    before :each do
      @instance = Instance.create(instance_params)
    end
    # This test will only catch the worst errors
    # as the Reader is very forgiving
    # TODO: Find a more stringent validator
    it 'is valid rdf' do
      expect {
        RDF::RDFXML::Reader.new(@instance.to_rdf, validate: true)
      }.not_to raise_error
    end
  end

  describe 'to_solr' do
    it 'should include the title statement' do
      i = Instance.new(instance_params)
      i.title_statement = 'King James Edition'
      vals = i.to_solr.values.flatten
      expect(vals).to include 'King James Edition'
    end
  end

  describe 'find by activity' do
    it 'should find all instances with a given activity name' do
      i = Instance.create(instance_params)
      set = Instance.find_by_activity('test').map{|i| i.pid}
      expect(set).to include i.pid
    end

  end
=end
end
