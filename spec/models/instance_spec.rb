require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe Instance do
  include_context 'shared'



  let(:work_attributes) do

  end

  before :each do
    agent = Authority::Person.create('given_name'=> 'Fornavn',
                                     'family_name' => 'Efternavn',
                                     'birth_date' => '1932' ,
                                     'death_date' => '2009')
    @org =  Authority::Organization.new(_name: 'Gyldendalske boghandel, Nordisk forlag',
                                        founding_date: '1770')
    @org.alternate_names.push 'Gyldendal'
    @org.save
    @instance = Instance.new(valid_trykforlaeg)
    @work = Work.new(work_params)
    @work.add_author(agent)
    @instance.set_work=@work
    @instance.add_publisher(@org)
    @work.instances += [@instance]
    @work.save!
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
      i.save!
      i.reload
      expect(i.content_files.size).to eql 1
    end
  end

  # describe 'to work' do
  #   before :each do
  #     @i = Instance.create(instance_params)
  #     @w = Work.create(work_attributes)
  #     @i.set_work = @w
  #     @i.save
  #     @i.reload
  #     @w.reload
  #   end
  #
  #   it 'can be an instance of a work' do
  #     expect(@i.work.first.pid).to eql @w.pid
  #   end
  #
  #   it 'is a symmetrical relationship' do
  #     expect(@w.instances).to include @i
  #   end
  #
  #   it 'is expressed symmetrically in rels-ext' do
  #     expect(@w.rels_ext.to_rels_ext).to include('hasInstance')
  #     expect(@i.rels_ext.to_rels_ext).to include('instanceOf')
  #   end
  # end
  #
  # it 'can have parts which are Works' do
  #   w = Work.create(work_attributes)
  #   @instance.parts << w
  #   expect(@instance.parts).to include w
  # end
  #
  # describe 'administration' do
  #   it 'should be possible to edit the activity field' do
  #     @instance.activity = 'TEST'
  #     @instance.activity.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the workflow_status field' do
  #     @instance.workflow_status.should be_nil
  #     @instance.workflow_status = 'TEST'
  #     @instance.workflow_status.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the embargo field' do
  #     @instance.embargo = 'TEST'
  #     @instance.embargo.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the embargo_date field' do
  #     @instance.embargo_date.should be_nil
  #     @instance.embargo_date = 'TEST'
  #     @instance.embargo_date.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the embargo_condition field' do
  #     @instance.embargo_condition.should be_nil
  #     @instance.embargo_condition = 'TEST'
  #     @instance.embargo_condition.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the access_condition field' do
  #     @instance.access_condition.should be_nil
  #     @instance.access_condition = 'TEST'
  #     @instance.access_condition.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the copyright field' do
  #     @instance.copyright = 'TEST'
  #     @instance.copyright.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the material_type field' do
  #     @instance.material_type.should be_nil
  #     @instance.material_type = 'TEST'
  #     @instance.material_type.should == 'TEST'
  #   end
  #
  #   it 'should be possible to edit the availability field' do
  #     @instance.availability = 'TEST'
  #     @instance.availability.should == 'TEST'
  #   end
  # end
  #
  # it 'should have a uuid on creation' do
  #   i = Instance.new
  #   expect(i.uuid).to be_nil
  #   i.save
  #   expect(i.uuid.present?).to be true
  # end
  #
  # describe 'to_mods' do
  #   it 'is wellformed XML' do
  #     instance = Instance.create(instance_params)
  #     xsd = Nokogiri::XML::Schema(open('http://www.loc.gov/standards/mods/v3/mods-3-5.xsd').read)
  #     errors = xsd.validate(Nokogiri::XML.parse(instance.to_mods) { |config| config.strict })
  #     expect(errors).to eql []
  #   end
  # end
  #
  # describe 'to_rdf' do
  #   before :each do
  #     @instance = Instance.create(instance_params)
  #   end
  #   # This test will only catch the worst errors
  #   # as the Reader is very forgiving
  #   # TODO: Find a more stringent validator
  #   it 'is valid rdf' do
  #     expect {
  #       RDF::RDFXML::Reader.new(@instance.to_rdf, validate: true)
  #     }.not_to raise_error
  #   end
  # end
  #
  # describe 'to_solr' do
  #   it 'should include the title statement' do
  #     i = Instance.new(instance_params)
  #     i.title_statement = 'King James Edition'
  #     vals = i.to_solr.values.flatten
  #     expect(vals).to include 'King James Edition'
  #   end
  # end
  #
  # describe 'find by activity' do
  #   it 'should find all instances with a given activity name' do
  #     i = Instance.create(instance_params)
  #     set = Instance.find_by_activity('test').map{|i| i.pid}
  #     expect(set).to include i.pid
  #   end
  #
  # end

  describe 'preservation' do
    describe '#can_perform_cascading?' do
      it 'should be true for instances' do
        expect(@instance.can_perform_cascading?).to be true
      end
    end

    describe '#cascading_elements' do
      it 'should return an empty list, when it has no files.' do
        expect(@instance.cascading_elements).to be_empty
      end

      it 'should return a list containing the files' do
        cf = ContentFile.new
        cf.instance = @instance
        cf.save!
        @instance.add_file(cf)
        @instance.save
        @instance.reload
        expect(@instance.cascading_elements).not_to be_empty
        expect(@instance.cascading_elements).to include cf
      end
    end

    describe '#create_preservation_message_metadata' do
      it 'should create metadata, which is valid xml' do
        metadata = @instance.create_preservation_message_metadata
        expect {
          Nokogiri::XML.parse(metadata) {|config| config.strict}
        }.to_not raise_error
      end

      it 'should create metadata containing uuid fields for the uuids of both instance and work.' do
        metadata = @instance.create_preservation_message_metadata
        expect(metadata).to include "<uuid>#{@instance.id}</uuid>"
        expect(metadata).to include "<uuid>#{@work.id}</uuid>"
      end

      it 'should contain the WARC id, if it is set' do
        metadata = @instance.create_preservation_message_metadata
        expect(@instance.warc_id).to be_nil
        expect(metadata).not_to include("<warc_id>")
        @instance.warc_id = UUID.new.generate
        @instance.save
        @instance.reload
        metadata = @instance.create_preservation_message_metadata
        expect(@instance.warc_id).not_to be_nil
        expect(metadata).to include("<warc_id>#{@instance.warc_id}</warc_id>")
      end
    end

    describe '#create_preservation_message' do
      it 'should contain UUID' do
        expect(@instance.create_preservation_message).to have_key 'UUID'
        expect(@instance.create_preservation_message['UUID']).to eq @instance.uuid
      end
      it 'should contain Preservation_profile' do
        expect(@instance.create_preservation_message).to have_key 'Preservation_profile'
      end
      it 'should contain Valhal_ID' do
        expect(@instance.create_preservation_message).to have_key 'Valhal_ID'
        expect(@instance.create_preservation_message['Valhal_ID']).to eq @instance.id
      end
      it 'should contain Model' do
        expect(@instance.create_preservation_message).to have_key 'Model'
        expect(@instance.create_preservation_message['Model']).to eq @instance.class.name
      end
      it 'should not contain File_UUID' do
        expect(@instance.create_preservation_message).not_to have_key 'File_UUID'
      end
      it 'should not contain Content_URI' do
        expect(@instance.create_preservation_message).not_to have_key 'Content_URI'
      end
      it 'should not contain warc_id when not preserved' do
        expect(@instance.create_preservation_message).not_to have_key 'warc_id'
      end
      it 'should contain warc_id when preserved' do
        @instance.warc_id = 'WARC_ID.warc'
        @instance.save
        expect(@instance.create_preservation_message).to have_key 'warc_id'
      end
      it 'should contain metadata' do
        expect(@instance.create_preservation_message).to have_key 'metadata'
      end
    end

    describe 'update' do
      it 'should not initially have preservation update' do
        expect(@instance.preservationMetadata.get_updates).to be_empty
      end

      it 'should have a update, when added a update' do
        @instance.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        expect(@instance.preservationMetadata.get_updates).not_to be_empty
        expect(@instance.preservationMetadata.get_updates.size).to eq 1
      end

      it 'should have 3 updates, when adding 3 different updates' do
        @instance.preservationMetadata.insert_update({'warc_id' => 'test1.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        @instance.preservationMetadata.insert_update({'warc_id' => 'test2.warc', 'uuid' => 'uuid-test-1235', 'date' => '2015-07-06'})
        @instance.preservationMetadata.insert_update({'warc_id' => 'test3.warc', 'uuid' => 'uuid-test-1236', 'date' => '2015-07-07'})
        expect(@instance.preservationMetadata.get_updates.size).to eq 3
      end

      it 'should have one update, when adding the same update several times' do
        @instance.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        @instance.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        @instance.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        expect(@instance.preservationMetadata.get_updates.size).to eq 1
      end

    end
  end
end
