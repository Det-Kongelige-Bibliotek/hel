require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe Instance do
  include_context 'shared'

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
      it 'should contain Preservation_collection' do
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

    describe 'update element' do
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

    describe 'a preservable element' do
      describe 'with initial preservation metadata' do
        it 'should have a preservation metadata stream' do
          @instance.save!
          @instance.preservationMetadata.should be_kind_of Datastreams::PreservationDatastream
        end
        it 'should have a non-empty preservation collection, both as attribute and in the metadatastream.' do
          @instance.save!
          @instance.preservation_collection.should be_kind_of String
          @instance.preservation_collection.should_not be_blank
          @instance.preservationMetadata.preservation_collection.first.should be_kind_of String
          @instance.preservationMetadata.preservation_collection.first.should_not be_blank
        end
        it 'should have an empty preservation comment, both as attribute and in the metadatastream.' do
          @instance.save!
          @instance.preservation_comment.should be_blank
          @instance.preservationMetadata.preservation_comment.should be_empty
        end
        it 'should have a non-empty preservation state, both as attribute and in the metadatastream.' do
          @instance.save!
          @instance.preservation_state.should be_kind_of String
          @instance.preservation_state.should_not be_blank
          @instance.preservationMetadata.preservation_state.first.should be_kind_of String
          @instance.preservationMetadata.preservation_state.first.should_not be_blank
        end
        it 'should have a non-empty preservation details, both as attribute and in the metadatastream.' do
          @instance.save!
          @instance.preservation_details.should be_kind_of String
          @instance.preservation_details.should_not be_blank
          @instance.preservationMetadata.preservation_details.first.should be_kind_of String
          @instance.preservationMetadata.preservation_details.first.should_not be_blank
        end
        it 'should have a non-empty preservation modify date, both as attribute and in the metadatastream.' do
          @instance.save!
          @instance.preservation_modify_date.should be_kind_of String
          @instance.preservation_modify_date.should_not be_blank
          @instance.preservationMetadata.preservation_modify_date.first.should be_kind_of String
          @instance.preservationMetadata.preservation_modify_date.first.should_not be_blank
        end
      end
      describe 'changing the preservation metadata' do
        it 'should be possible to assign and save a preservation collection.' do
          collection = PRESERVATION_CONFIG['preservation_collection'].keys[rand(PRESERVATION_CONFIG['preservation_collection'].size)]
          @instance.preservation_collection = collection
          @instance.save!
          e2 = @instance.reload
          e2.preservation_collection.should == collection
          e2.preservationMetadata.preservation_collection.first.should == collection
        end
        it 'should not be possible to assign and save a preservation collection, which is not in the configuration.' do
          collection = "Preservation-Profile-#{Time.now.to_s}"
          @instance.preservation_collection = collection
          expect{@instance.save!}.to raise_error
        end
        it 'should be possible to assign and save a preservation state.' do
          state = "Preservation-State-#{Time.now.to_s}"
          @instance.preservation_state = state
          @instance.save!
          e2 = @instance.reload
          e2.preservation_state.should == state
          e2.preservationMetadata.preservation_state.first.should == state
        end
        it 'should be possible to assign and save a preservation details.' do
          details = "Preservation-Details-#{Time.now.to_s}"
          @instance.preservation_details = details
          @instance.save!
          e2 = @instance.reload
          e2.preservation_details.should == details
          e2.preservationMetadata.preservation_details.first.should == details
        end
        it 'should be possible to assign and save a preservation collection.' do
          comment = "Preservation-Comment-#{Time.now.to_s}"
          @instance.preservation_comment = comment
          @instance.save!
          e2 = @instance.reload
          e2.preservation_comment.should == comment
          e2.preservationMetadata.preservation_comment.first.should == comment
        end
      end
      describe 'using PreservationHelper' do
        include PreservationHelper
        it 'should change the preservation timestamp with #set_preservation_modified_time' do
          set_preservation_modified_time(@instance)
          @instance.save!
          time = @instance.preservationMetadata.preservation_modify_date
          sleep 2
          set_preservation_modified_time(@instance)
          @instance.save!
          expect(time).not_to equal(@instance.preservationMetadata.preservation_modify_date)
        end
        describe '#update_preservation_metadata_for_element' do
          describe 'preservation element' do
            it 'should be able to update all the preservation metadata fields' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              @instance.save!
              metadata = {'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first,
                                             'preservation_details' => 'From preservation shared spec', 'warc_id' => 'WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              @instance.preservationMetadata.preservation_state.first.should == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
              @instance.preservationMetadata.preservation_details.first.should == 'From preservation shared spec'
              @instance.preservationMetadata.warc_id.first.should == 'WARC_ID'
            end
            it 'should be able to update only the preservation state' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              @instance.save!
              metadata = {'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              @instance.preservationMetadata.preservation_state.first.should == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
              @instance.preservationMetadata.preservation_details.first.should_not == 'From preservation shared spec'
              @instance.preservationMetadata.warc_id.first.should_not == 'WARC_ID'
            end
            it 'should be able to update only the preservation details' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              @instance.save!
              metadata = {'preservation' => {'preservation_details' => 'From preservation shared spec'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              @instance.preservationMetadata.preservation_state.first.should_not == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
              @instance.preservationMetadata.preservation_details.first.should == 'From preservation shared spec'
              @instance.preservationMetadata.warc_id.first.should_not == 'WARC_ID'
            end
            it 'should be able to update only the warc-id' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              @instance.save!
              metadata = {'preservation' => {'warc_id' => 'WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              @instance.preservationMetadata.preservation_state.first.should_not == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
              @instance.preservationMetadata.preservation_details.first.should_not == 'From preservation shared spec'
              @instance.preservationMetadata.warc_id.first.should == 'WARC_ID'
            end
            it 'should be able to update only the file-warc-id' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              @instance.save!
              metadata = {'preservation' => {'file_warc_id' => 'FILE_WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              @instance.preservationMetadata.preservation_state.first.should_not == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
              @instance.preservationMetadata.preservation_details.first.should_not == 'From preservation shared spec'
              @instance.preservationMetadata.file_warc_id.first.should == 'FILE_WARC_ID'
            end
          end
          describe 'update element' do
            it 'should be able to update all the update metadata fields' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              expect(@instance.preservationMetadata.get_updates.size).to eq 0
              @instance.save!
              metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID', 'date' => 'date', 'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(@instance.preservationMetadata.get_updates.size).to eq 1
              expect(@instance.preservationMetadata.get_updates.first['uuid']).to eq 'PRESERVATION_UPDATE_UUID'
              expect(@instance.preservationMetadata.get_updates.first['warc_id']).to eq 'WARC_ID'
              expect(@instance.preservationMetadata.get_updates.first['date']).to eq 'date'
              expect(@instance.preservationMetadata.get_updates.first['file_warc_id']).to eq 'FILE_WARC_ID'
              expect(@instance.preservationMetadata.get_updates.first['file_uuid']).to eq 'file_uuid'
            end
            it 'should only update once, when using the same uuid' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              expect(@instance.preservationMetadata.get_updates.size).to eq 0
              @instance.save!
              metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID', 'date' => 'date', 'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(@instance.preservationMetadata.get_updates.size).to eq 1
            end
            it 'should only update once, when using the same file_uuid' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              expect(@instance.preservationMetadata.get_updates.size).to eq 0
              @instance.save!
              metadata = {'preservation' => {}, 'update' => {'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(@instance.preservationMetadata.get_updates.size).to eq 1
            end
            it 'should be able to update the non-file fields of the update metadata' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              expect(@instance.preservationMetadata.get_updates.size).to eq 0
              @instance.save!
              metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(@instance.preservationMetadata.get_updates.size).to eq 1
              expect(@instance.preservationMetadata.get_updates.first['uuid']).to eq 'PRESERVATION_UPDATE_UUID'
              expect(@instance.preservationMetadata.get_updates.first['warc_id']).to eq 'WARC_ID'
              expect(@instance.preservationMetadata.get_updates.first['date']).to be_blank
              expect(@instance.preservationMetadata.get_updates.first['file_warc_id']).to be_blank
              expect(@instance.preservationMetadata.get_updates.first['file_uuid']).to be_blank
            end
            it 'should be able to update the file fields of the update metadata' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              expect(@instance.preservationMetadata.get_updates.size).to eq 0
              @instance.save!
              metadata = {'preservation' => {}, 'update' => {'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(@instance.preservationMetadata.get_updates.size).to eq 1
              expect(@instance.preservationMetadata.get_updates.first['uuid']).to be_blank
              expect(@instance.preservationMetadata.get_updates.first['warc_id']).to be_blank
              expect(@instance.preservationMetadata.get_updates.first['date']).to be_blank
              expect(@instance.preservationMetadata.get_updates.first['file_warc_id']).to eq 'FILE_WARC_ID'
              expect(@instance.preservationMetadata.get_updates.first['file_uuid']).to eq 'file_uuid'
            end
            it 'should be able to make two updates' do
              @instance.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
              expect(@instance.preservationMetadata.get_updates.size).to eq 0
              @instance.save!
              metadata = {'preservation' => {}, 'update' => {'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID'}}
              expect(update_preservation_metadata_for_element(metadata, @instance)).to be == true
              expect(@instance.preservationMetadata.get_updates.size).to eq 2
            end
          end
        end
      end
    end
  end
end
