require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe Instance do
  include_context 'shared'

  @org =  Authority::Organization.new(
               { 'same_as' => 'http://viaf.org/viaf/127954890', 
                 '_name' => 'Gyldendalske boghandel, Nordisk forlag',
                 'founding_date' => '1770' })
  @org.alternate_names.push 'Gyldendal'

  let(:work_attributes) do
    agent = Authority::Person.create('given_name'=> 'Fornavn', 
                                     'family_name' => 'Efternavn',
                                     'birth_date' => '1932' , 
                                     'death_date' => '2009')
  end

  before :each do
    @instance = Instance.new(valid_trykforlaeg)
    @work = Work.new(work_params)
    @instance.set_work=@work
    @instance.add_publisher(@org)
    @work.add_instance(@instance)
    expect(@instance.relators.shift).to be_an Relator
  end

  describe 'relations' do
    it 'can published by a publisher' do
      i = Instance.new(valid_trykforlaeg)
      @work.add_instance(i)
      i.set_work=@work
      i.add_publisher(@org)
    end

    it 'can have an equivalent instance' do
      i1 = Instance.create(valid_trykforlaeg)
      i2 = Instance.create(valid_trykforlaeg)
      i1.add_publisher @org
      i2.add_publisher @org
      @work.add_instance i1
      @work.add_instance i2
      i1.set_work=@work
      i2.set_work=@work
      i1.save
      i2.save
      i1.set_equivalent= i2
      i2.set_equivalent= i1
      expect(1).to eql 1
    end

    describe 'publication' do
      let (:instance) { Instance.new }
      let (:publication_event) { Provider.new }

      it 'can have a publication event' do
        instance.publications << publication_event
        expect(instance.publication).to eql publication_event
      end
    end
  end

  describe 'adding a file' do
    it 'adds a file' do
      i = Instance.new(valid_trykforlaeg)
      i.activity = Administration::Activity.last.id
      f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
      i.add_file(f)
      i.save
      expect(i.content_files.size).to eql 1
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

  describe 'preservation' do
    before :each do
      @i = Instance.create(instance_params)
    end

    describe '#can_perform_cascading?' do
      it 'should be true for instances' do
        expect(@i.can_perform_cascading?).to be true
      end
    end

    describe '#cascading_elements' do
      it 'should return an empty list, when it has no files.' do
        expect(@i.cascading_elements).to be_empty
      end

      it 'should return a list containing the files' do
        cf = ContentFile.create
        @i.content_files << cf
        @i.save
        @i.reload
        expect(@i.cascading_elements).not_to be_empty
        expect(@i.cascading_elements).to include cf
      end
    end

    describe '#create_message_metadata' do
      before :each do
        @w = Work.create(work_attributes)
        @i.set_work = @w
        @i.save
        @i.reload
        @w.reload
      end

      it 'should create metadata, which is valid xml' do
        metadata = @i.create_message_metadata
        xml = Nokogiri::XML.parse(metadata)
        expect(metadata).to eq(xml.root.to_s)
      end

      it 'should create metadata containing uuid fields for the uuids of both instance and work.' do
        metadata = @i.create_message_metadata

        expect(metadata).to include "<uuid>#{@i.uuid}</uuid>"
        expect(metadata).to include "<uuid>#{@w.uuid}</uuid>"
      end

      it 'should contain the WARC id, if it is set' do
        metadata = @i.create_message_metadata
        expect(@i.warc_id).to be_nil
        expect(metadata).not_to include("<warc_id>")
        @i.warc_id = UUID.new.generate
        @i.save
        @i.reload
        metadata = @i.create_message_metadata
        expect(@i.warc_id).not_to be_nil
        expect(metadata).to include("<warc_id>#{@i.warc_id}</warc_id>")
      end
    end

    describe '#create_preservation_message' do
      it 'should contain UUID' do
        expect(@i.create_preservation_message).to have_key 'UUID'
        expect(@i.create_preservation_message['UUID']).to eq @i.uuid
      end
      it 'should contain Preservation_profile' do
        expect(@i.create_preservation_message).to have_key 'Preservation_profile'
      end
      it 'should contain Valhal_ID' do
        expect(@i.create_preservation_message).to have_key 'Valhal_ID'
        expect(@i.create_preservation_message['Valhal_ID']).to eq @i.pid
      end
      it 'should contain Model' do
        expect(@i.create_preservation_message).to have_key 'Model'
        expect(@i.create_preservation_message['Model']).to eq @i.class.name
      end
      it 'should not contain File_UUID' do
        expect(@i.create_preservation_message).not_to have_key 'File_UUID'
      end
      it 'should not contain Content_URI' do
        expect(@i.create_preservation_message).not_to have_key 'Content_URI'
      end
      it 'should not contain warc_id when not preserved' do
        expect(@i.create_preservation_message).not_to have_key 'warc_id'
      end
      it 'should contain warc_id when preserved' do
        @i.warc_id = 'WARC_ID.warc'
        @i.save
        @i.reload
        expect(@i.create_preservation_message).to have_key 'warc_id'
      end

      it 'should contain metadata' do
        expect(@i.create_preservation_message).to have_key 'metadata'
      end
    end
  end
=end
end
