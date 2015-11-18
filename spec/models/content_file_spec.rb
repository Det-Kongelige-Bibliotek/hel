require 'spec_helper'
require 'securerandom'

describe 'content' do
  include_context 'shared'

  before :each do
    w = Work.create(work_params)
    p = Authority::Person.create({ 'family_name' => 'Joyce',
                                   'given_name' => 'James',
                                   'birth_date' => '1932',
                                   'death_date' => '2009' })
    w.add_author(p)
    w.save!
    @i = Instance.create(valid_trykforlaeg)
    @i.set_work = w
    @f = ContentFile.new
    @f.instance = @i
    # expect(@f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')), false)).to be_true
    @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
    @f.save!
  end

  it 'should allow us to upload a file' do
    expect(@f.fileContent.content).not_to be_nil
  end

  it 'has a relation to an instance' do
    expect(@f.instance).to eql @i
  end

  describe '#fits' do
    it 'should respond to add_fits_metadata_datastream' do
      expect(@f).to respond_to :add_fits_metadata_datastream
    end

    it 'should have a fits datastream' do
      expect(@f.reflections.keys).to include :fitsMetadata
    end

    it 'fits datastream should initially be nil' do
      expect(@f.fitsMetadata.content).to be_nil
    end

    describe 'content of fitsmetadata' do
      it 'should not be nil' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f.fitsMetadata.content).not_to be_nil
      end

      it 'should not be empty' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f.fitsMetadata.content).not_to be_empty
      end

      it 'should have a fits as root' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        xml = Nokogiri::XML(@f.fitsMetadata.content)
        expect(xml.root.name).to eq "fits"
      end

      it 'should set format name' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f.format_name).not_to be_nil
        expect(@f.format_name).to eq 'Extensible Markup Language'
      end

      it 'should set format mimetype' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f.format_mimetype).not_to be_nil
        expect(@f.format_mimetype).to eq 'text/xml'
      end

      it 'should set format version' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f.format_version).not_to be_nil
        expect(@f.format_version).to eq '1.0'
      end

      it 'should set pronom id' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f).to respond_to(:format_pronom_id)
        expect(@f.format_pronom_id).to eq "unknown"
      end

      it 'should discover a conflict and put it into the pronom-id' do
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'mods-3-5.xsd'))
        @f.add_fits_metadata_datastream(f)
        @f.save!
        expect(@f.format_pronom_id).to include 'CONFLICT'
      end
    end
  end

  describe '#techMetadata' do
    it 'should have a tectMetadata datastream' do
      c = ContentFile.new
      expect(c.reflections.keys).to include :techMetadata
    end

    it 'should have a format variables' do
      c = ContentFile.new
      expect(c).to respond_to :format_name, :format_version, :format_mimetype
    end

    it 'should have most fields set by adding the file' do
      c = ContentFile.new
      f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
      expect(c.last_modified).to be_nil
      expect(c.created).to be_nil
      expect(c.last_accessed).to be_nil
      expect(c.original_filename).to be_nil
      expect(c.mime_type).to be_nil
      expect(c.file_uuid).to be_nil
      expect(c.checksum).to be_nil
      expect(c.size).to be_nil

      c.instance = Instance.create(instance_params)
      c.add_file(f)
      c.save!
      c.reload

      expect(c.last_modified).not_to be_nil
      expect(c.created).not_to be_nil
      expect(c.last_accessed).not_to be_nil
      expect(c.original_filename).not_to be_nil
      expect(c.mime_type).not_to be_nil
      expect(c.file_uuid).not_to be_nil
      expect(c.checksum).not_to be_nil
      expect(c.size).not_to be_nil
    end

    describe 'dissemination' do
      let(:cf) { ContentFile.new }
      describe 'dissemination_checksums' do
        it 'should have multiple dissemination_checksums' do
          expect(cf.respond_to? :dissemination_checksums).to eql true
        end

        it 'should allow us to set a dissemination checksum' do
          cf.dissemination_checksums = ['ADL:blablabla']
          expect(cf.dissemination_checksums).to eql ['ADL:blablabla']
        end
      end

      describe 'disseminated_versions' do
        it 'returns a hash of values' do
          expect(cf.disseminated_versions).to be_a Hash
        end

        it 'updates the disseminated checksums' do
          cf.add_dissemination_checksum('ADL', 'blablabla')
          expect(cf.disseminated_versions).not_to be_empty
          expect(cf.disseminated_versions['ADL']).to eql 'blablabla'
        end

        it 'overwrites the existing checksum if one is present' do
          cf.add_dissemination_checksum('ADL', 'blablabla')
          cf.add_dissemination_checksum('Bifrost', 'blablabla')
          cf.add_dissemination_checksum('ADL', 'blueblueblueblue')
          expect(cf.dissemination_checksums.size).to eq(2)
        end
      end
    end

    it 'should have be able to set the format variables' do
      @f.format_name = 'format_name'
      @f.format_mimetype = 'format_mimetype'
      @f.format_version = 'format_version'
      @f.save!
      @f.reload
      expect(@f.format_name).to eq 'format_name'
      expect(@f.format_mimetype).to eq 'format_mimetype'
      expect(@f.format_version).to eq 'format_version'
    end
  end

  describe '#preservation' do
    describe '#can_perform_cascading?' do
      it 'should be true for instances' do
        expect(@f.can_perform_cascading?).to be false
      end
    end

    describe '#create_preservation_message' do
      it 'should contain UUID' do
        expect(@f.create_preservation_message).to have_key 'UUID'
        expect(@f.create_preservation_message['UUID']).not_to be_nil
        expect(@f.create_preservation_message['UUID']).to eq @f.uuid
      end
      it 'should contain Preservation_collection' do
        expect(@f.create_preservation_message).to have_key 'Preservation_profile'
      end
      it 'should contain Valhal_ID' do
        expect(@f.create_preservation_message).to have_key 'Valhal_ID'
        expect(@f.create_preservation_message['Valhal_ID']).not_to be_nil
        expect(@f.create_preservation_message['Valhal_ID']).to eq @f.id
      end
      it 'should contain Model' do
        expect(@f.create_preservation_message).to have_key 'Model'
        expect(@f.create_preservation_message['Model']).not_to be_nil
        expect(@f.create_preservation_message['Model']).to eq @f.class.name
      end
      it 'should contain File_UUID' do
        expect(@f.create_preservation_message).to have_key 'File_UUID'
      end
      it 'should contain Content_URI' do
        expect(@f.create_preservation_message).to have_key 'Content_URI'
      end
      it 'should not contain warc_id when not preserved' do
        expect(@f.create_preservation_message).not_to have_key 'warc_id'
      end
      it 'should contain warc_id when preserved' do
        @f.warc_id = 'WARC_ID.warc'
        @f.save
        @f.reload
        expect(@f.create_preservation_message).to have_key 'warc_id'
      end
      it 'should contain metadata' do
        expect(@f.create_preservation_message).to have_key 'metadata'
      end

      describe '#Content_URI for update message' do
        it 'should contain File_UUID but not Content_URI, when initiation date is newer than last modified.' do
          @f.file_warc_id = "file_warc.id"
          f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
          @f.add_file(f)
          @f.preservation_initiated_date = DateTime.now.strftime("%FT%T.%L%:z")
          @f.save
          @f.reload
          expect(@f.create_preservation_message).to have_key 'File_UUID'
          expect(@f.create_preservation_message).not_to have_key 'Content_URI'
        end

        it 'should contain File_UUID and Content_URI, when initiation date is later than last modified.' do
          @f.preservation_initiated_date = DateTime.now.strftime("%FT%T.%L%:z")
          @f.file_warc_id = "file_warc.id"
          f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
          @f.add_file(f)
          @f.last_modified = DateTime.now.strftime("%FT%T.%L%:z")
          @f.save
          @f.reload
          expect(@f.create_preservation_message).to have_key 'File_UUID'
          expect(@f.create_preservation_message).to have_key 'Content_URI'
        end
      end
    end

    describe '#create_preservation_message_metadata' do
      it 'should have provenanceMetadata and a uuid' do
        metadata = @f.create_preservation_message_metadata
        expect(metadata).to include "<provenanceMetadata>"
        expect(metadata).to include "<uuid>#{@f.id}</uuid>"
      end
      it 'should have techMetadata' do
        metadata = @f.create_preservation_message_metadata
        expect(metadata).to include '<techMetadata>'
        expect(metadata).to include "<file_uuid>#{@f.file_uuid}</file_uuid>"
        expect(metadata).to include "<mime_type>#{@f.mime_type}</mime_type>"
        expect(metadata).to include "<file_checksum>#{@f.checksum}</file_checksum>"
        expect(metadata).to include "<file_size>#{@f.size}</file_size>"
      end
      it 'should have preservationMetadata' do
        expect(@f.create_preservation_message_metadata).to include '<preservationMetadata>'
      end
      it 'should contain the WARC id, if it is set' do
        metadata = @f.create_preservation_message_metadata
        expect(@f.warc_id).to be_nil
        expect(metadata).not_to include("<warc_id>")
        @f.warc_id = UUID.new.generate
        @f.save
        @f.reload
        metadata = @f.create_preservation_message_metadata
        expect(@f.warc_id).not_to be_nil
        expect(metadata).to include("<warc_id>#{@f.warc_id}</warc_id>")
      end

      describe '#fitsMetadata' do
        it 'should not have fitsMetadata before running characterization' do
          expect(@f.create_preservation_message_metadata).not_to include '<fitsMetadata>'
        end
        it 'should have fitsMetadata after running characterization' do
          @f.add_fits_metadata_datastream(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
          @f.save!
          @f.reload
          metadata = @f.create_preservation_message_metadata
          expect(metadata).to include 'fitsMetadata'
          expect(metadata).to include '<identity format="Extensible Markup Language" mimetype="text/xml" toolname="FITS" '
        end
      end
    end

    describe 'update element' do
      it 'should not initially have preservation update' do
        expect(@f.preservationMetadata.get_updates).to be_empty
      end

      it 'should have a update, when added a update' do
        @f.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        expect(@f.preservationMetadata.get_updates).not_to be_empty
        expect(@f.preservationMetadata.get_updates.size).to eq 1
      end

      it 'should have 3 updates, when adding 3 different updates' do
        @f.preservationMetadata.insert_update({'warc_id' => 'test1.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        @f.preservationMetadata.insert_update({'warc_id' => 'test2.warc', 'uuid' => 'uuid-test-1235', 'date' => '2015-07-06'})
        @f.preservationMetadata.insert_update({'warc_id' => 'test3.warc', 'uuid' => 'uuid-test-1236', 'date' => '2015-07-07'})
        expect(@f.preservationMetadata.get_updates.size).to eq 3
      end

      it 'should have one update, when adding the same update several times' do
        @f.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        @f.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        @f.preservationMetadata.insert_update({'warc_id' => 'test.warc', 'uuid' => 'uuid-test-1234', 'date' => '2015-07-05'})
        expect(@f.preservationMetadata.get_updates.size).to eq 1
      end
    end

    describe 'changing the preservation metadata' do
      it 'should be possible to assign and save a preservation collection.' do
        collection = PRESERVATION_CONFIG['preservation_collection'].keys[rand(PRESERVATION_CONFIG['preservation_collection'].size)]
        @f.preservation_collection = collection
        @f.save!
        e2 = @f.reload
        e2.preservation_collection.should == collection
        e2.preservationMetadata.preservation_collection.first.should == collection
      end
      it 'should not be possible to assign and save a preservation collection, which is not in the configuration.' do
        collection = "Preservation-Profile-#{Time.now.to_s}"
        @f.preservation_collection = collection
        expect{@f.save!}.to raise_error
      end
      it 'should be possible to assign and save a preservation state.' do
        state = "Preservation-State-#{Time.now.to_s}"
        @f.preservation_state = state
        @f.save!
        e2 = @f.reload
        e2.preservation_state.should == state
        e2.preservationMetadata.preservation_state.first.should == state
      end
      it 'should be possible to assign and save a preservation details.' do
        details = "Preservation-Details-#{Time.now.to_s}"
        @f.preservation_details = details
        @f.save!
        e2 = @f.reload
        e2.preservation_details.should == details
        e2.preservationMetadata.preservation_details.first.should == details
      end
      it 'should be possible to assign and save a preservation collection.' do
        comment = "Preservation-Comment-#{Time.now.to_s}"
        @f.preservation_comment = comment
        @f.save!
        e2 = @f.reload
        e2.preservation_comment.should == comment
        e2.preservationMetadata.preservation_comment.first.should == comment
      end
    end

    describe 'using PreservationHelper' do
      include PreservationHelper
      it 'should change the preservation timestamp with #set_preservation_modified_time' do
        set_preservation_modified_time(@f)
        @f.save!
        time = @f.preservationMetadata.preservation_modify_date
        sleep 2
        set_preservation_modified_time(@f)
        @f.save!
        expect(time).not_to equal(@f.preservationMetadata.preservation_modify_date)
      end
      describe '#update_preservation_metadata_for_element' do
        describe 'preservation element' do
          it 'should be able to update all the preservation metadata fields' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            @f.save!
            metadata = {'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first,
                                           'preservation_details' => 'From preservation shared spec', 'warc_id' => 'WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            @f.preservationMetadata.preservation_state.first.should == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
            @f.preservationMetadata.preservation_details.first.should == 'From preservation shared spec'
            @f.preservationMetadata.warc_id.first.should == 'WARC_ID'
          end
          it 'should be able to update only the preservation state' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            @f.save!
            metadata = {'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            @f.preservationMetadata.preservation_state.first.should == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
            @f.preservationMetadata.preservation_details.first.should_not == 'From preservation shared spec'
            @f.preservationMetadata.warc_id.first.should_not == 'WARC_ID'
          end
          it 'should be able to update only the preservation details' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            @f.save!
            metadata = {'preservation' => {'preservation_details' => 'From preservation shared spec'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            @f.preservationMetadata.preservation_state.first.should_not == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
            @f.preservationMetadata.preservation_details.first.should == 'From preservation shared spec'
            @f.preservationMetadata.warc_id.first.should_not == 'WARC_ID'
          end
          it 'should be able to update only the warc-id' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            @f.save!
            metadata = {'preservation' => {'warc_id' => 'WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            @f.preservationMetadata.preservation_state.first.should_not == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
            @f.preservationMetadata.preservation_details.first.should_not == 'From preservation shared spec'
            @f.preservationMetadata.warc_id.first.should == 'WARC_ID'
          end
          it 'should be able to update only the file-warc-id' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            @f.save!
            metadata = {'preservation' => {'file_warc_id' => 'FILE_WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            @f.preservationMetadata.preservation_state.first.should_not == PRESERVATION_PACKAGE_UPLOAD_SUCCESS.keys.first
            @f.preservationMetadata.preservation_details.first.should_not == 'From preservation shared spec'
            @f.preservationMetadata.file_warc_id.first.should == 'FILE_WARC_ID'
          end
        end
        describe 'update element' do
          it 'should be able to update all the update metadata fields' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            expect(@f.preservationMetadata.get_updates.size).to eq 0
            @f.save!
            metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID', 'date' => 'date', 'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(@f.preservationMetadata.get_updates.size).to eq 1
            expect(@f.preservationMetadata.get_updates.first['uuid']).to eq 'PRESERVATION_UPDATE_UUID'
            expect(@f.preservationMetadata.get_updates.first['warc_id']).to eq 'WARC_ID'
            expect(@f.preservationMetadata.get_updates.first['date']).to eq 'date'
            expect(@f.preservationMetadata.get_updates.first['file_warc_id']).to eq 'FILE_WARC_ID'
            expect(@f.preservationMetadata.get_updates.first['file_uuid']).to eq 'file_uuid'
          end
          it 'should only update once, when using the same uuid' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            expect(@f.preservationMetadata.get_updates.size).to eq 0
            @f.save!
            metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID', 'date' => 'date', 'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(@f.preservationMetadata.get_updates.size).to eq 1
          end
          it 'should only update once, when using the same file_uuid' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            expect(@f.preservationMetadata.get_updates.size).to eq 0
            @f.save!
            metadata = {'preservation' => {}, 'update' => {'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(@f.preservationMetadata.get_updates.size).to eq 1
          end
          it 'should be able to update the non-file fields of the update metadata' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            expect(@f.preservationMetadata.get_updates.size).to eq 0
            @f.save!
            metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(@f.preservationMetadata.get_updates.size).to eq 1
            expect(@f.preservationMetadata.get_updates.first['uuid']).to eq 'PRESERVATION_UPDATE_UUID'
            expect(@f.preservationMetadata.get_updates.first['warc_id']).to eq 'WARC_ID'
            expect(@f.preservationMetadata.get_updates.first['date']).to be_blank
            expect(@f.preservationMetadata.get_updates.first['file_warc_id']).to be_blank
            expect(@f.preservationMetadata.get_updates.first['file_uuid']).to be_blank
          end
          it 'should be able to update the file fields of the update metadata' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            expect(@f.preservationMetadata.get_updates.size).to eq 0
            @f.save!
            metadata = {'preservation' => {}, 'update' => {'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(@f.preservationMetadata.get_updates.size).to eq 1
            expect(@f.preservationMetadata.get_updates.first['uuid']).to be_blank
            expect(@f.preservationMetadata.get_updates.first['warc_id']).to be_blank
            expect(@f.preservationMetadata.get_updates.first['date']).to be_blank
            expect(@f.preservationMetadata.get_updates.first['file_warc_id']).to eq 'FILE_WARC_ID'
            expect(@f.preservationMetadata.get_updates.first['file_uuid']).to eq 'file_uuid'
          end
          it 'should be able to make two updates' do
            @f.preservationMetadata.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
            expect(@f.preservationMetadata.get_updates.size).to eq 0
            @f.save!
            metadata = {'preservation' => {}, 'update' => {'file_uuid' => 'file_uuid', 'file_warc_id' => 'FILE_WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            metadata = {'preservation' => {}, 'update' => {'uuid' => 'PRESERVATION_UPDATE_UUID', 'warc_id' => 'WARC_ID'}}
            expect(update_preservation_metadata_for_element(metadata, @f)).to be == true
            expect(@f.preservationMetadata.get_updates.size).to eq 2
          end
        end
      end
    end

    describe '#preservation_import' do
      it 'should respond to import variables' do
        expect(@f.respond_to? :import_token).to eql true
        expect(@f.respond_to? :import_token_timeout).to eql true
        expect(@f.respond_to? :import_state).to eql true
      end

      it 'should not have a token or timeout initially' do
        expect(@f.import_token).to be_blank
        expect(@f.import_token_timeout).to be_blank
      end

      describe '#create_import_from_preservation message' do
        it 'should be a non-empty Hash' do
          message = @f.create_import_from_preservation_message('FILE')
          expect(message).to_not be_nil
          expect(message).to_not be_empty
          expect(message.class).to eq Hash
        end
        it 'should have type the same as argument' do
          type = SecureRandom.hex(32)
          expect(@f.create_import_from_preservation_message(type)['type']).to eq type
        end
        it 'should have the uuid of the file' do
          expect(@f.create_import_from_preservation_message('type')['uuid']).to eq @f.id
        end
        it 'should have the preservation collection of the file' do
          puts @f.create_import_from_preservation_message('type')
          puts @f.preservation_collection
          expect(@f.create_import_from_preservation_message('type')['preservation_profile']).to eq @f.preservation_collection
        end
        it 'should have the warc_id of the file' do
          @f.warc_id = SecureRandom.hex(32)
          expect(@f.create_import_from_preservation_message('type')['warc']['warc_file_id']).to eq @f.warc_id
        end
        it 'should have a warc_record_id identical to the id of the file' do
          expect(@f.create_import_from_preservation_message('type')['warc']['warc_record_id']).to eq @f.id
        end
        it 'should not have a warc_offset' do
          expect(@f.create_import_from_preservation_message('type')['warc']['warc_offset']).to be_blank
        end
        it 'should have a warc_offset, when it has been set' do
          @f.file_warc_offset = '1234#4321'
          expect(@f.create_import_from_preservation_message('type')['warc']['warc_offset']).to eq '1234'
        end
        it 'should not have a warc_record_size' do
          expect(@f.create_import_from_preservation_message('type')['warc']['warc_record_size']).to be_blank
        end
        it 'should have a warc_record_size, when the offset has been set' do
          @f.file_warc_offset = '1234#4321'
          expect(@f.create_import_from_preservation_message('type')['warc']['warc_record_size']).to eq ((4321-1234).to_s)
        end
        it 'should not have a security token when not defined' do
          expect(@f.import_token).to be_blank
          expect(@f.create_import_from_preservation_message('type')['security']['token']).to be_blank
        end
        it 'should not have a security token timeout when not defined' do
          expect(@f.import_token_timeout).to be_blank
          expect(@f.create_import_from_preservation_message('type')['security']['token_timeout']).to be_blank
        end
        it 'should have a security token when defined' do
          @f.import_token = SecureRandom.hex(32)
          expect(@f.create_import_from_preservation_message('type')['security']['token']).not_to be_blank
          expect(@f.create_import_from_preservation_message('type')['security']['token']).to eq @f.import_token
        end
        it 'should not have a security token timeout when not defined' do
          @f.import_token_timeout = DateTime.now.to_s
          expect(@f.create_import_from_preservation_message('type')['security']['token_timeout']).not_to be_blank
          expect(@f.create_import_from_preservation_message('type')['security']['token_timeout']).to eq @f.import_token_timeout
        end

        describe '#Updates' do
          it 'should deliver the right update-id' do
            warc_file_id = SecureRandom.hex(32)
            warc_record_id = SecureRandom.hex(32)
            @f.preservationMetadata.insert_update( {'file_uuid' => warc_record_id, 'file_warc_id' => warc_file_id} )
            expect(@f.create_import_from_preservation_message('type', warc_record_id)['warc']['warc_file_id']).to eq warc_file_id
            expect(@f.create_import_from_preservation_message('type', warc_record_id)['warc']['warc_record_id']).to eq warc_record_id
          end
          it 'should has update offset' do
            warc_file_id = SecureRandom.hex(32)
            warc_record_id = SecureRandom.hex(32)
            @f.preservationMetadata.insert_update( {'file_uuid' => warc_record_id, 'file_warc_id' => warc_file_id, 'file_warc_offset' => '1234#4321'} )
            expect(@f.create_import_from_preservation_message('type', warc_record_id)['warc']['warc_file_id']).to eq warc_file_id
            expect(@f.create_import_from_preservation_message('type', warc_record_id)['warc']['warc_record_id']).to eq warc_record_id
            expect(@f.create_import_from_preservation_message('type', warc_record_id)['warc']['warc_offset']).to eq '1234'
            expect(@f.create_import_from_preservation_message('type', warc_record_id)['warc']['warc_record_size']).to eq ((4321-1234).to_s)
          end
          it 'should throw an error when no updates exists' do
            expect{@f.create_import_from_preservation_message('type', SecureRandom.hex(32))}.to raise_error
          end
          it 'should throw an error when a non-existing update is refered to' do
            warc_file_id = SecureRandom.hex(32)
            warc_record_id = SecureRandom.hex(32)
            @f.preservationMetadata.insert_update( {'file_uuid' => warc_record_id, 'file_warc_id' => warc_file_id} )
            expect{@f.create_import_from_preservation_message('type', SecureRandom.hex(32))}.to raise_error
          end
        end
      end

      describe '#create_import_token' do
        it 'should not have a token before it has been created' do
          expect(@f.import_token).to be_blank
        end
        it 'should not have a token timeout before it has been created' do
          expect(@f.import_token_timeout).to be_blank
        end
        it 'should have a token when the create method has been called' do
          @f.create_import_token
          expect(@f.import_token).not_to be_blank
        end
        it 'should have a token timeout when the create method has been called' do
          @f.create_import_token
          expect(@f.import_token_timeout).not_to be_blank
        end
      end

      describe '#validate_import' do
        it 'should fail when no warc_id is defined' do
          expect(@f.validate_import('FILE', nil)).to be_falsey
        end
        it 'should fail when no preservation_collection has been defined' do
          @f.warc_id = 'warc_id'
          expect(@f.validate_import('FILE', nil)).to be_falsey
        end
        it 'should fail when the preservation_collection is not a longterm preservation collection - thus not having preserved in yggdrasil' do
          @f.warc_id = 'warc_id'
          @f.preservation_collection = (PRESERVATION_CONFIG['preservation_collection'].select {|p| p['yggdrasil'] == 'false'}).keys.sample
          expect(@f.validate_import('FILE', nil)).to be_falsey
        end
        it 'should fail when using another collection type than \'FILE\'' do
          @f.warc_id = 'warc_id'
          @f.preservation_collection = (PRESERVATION_CONFIG['preservation_collection'].select {|k,v| v['yggdrasil'] == 'true'}).keys.sample
          expect(@f.validate_import('NOT_FILE', nil)).to be_falsey
        end
        it 'should be able to success' do
          @f.warc_id = 'warc_id'
          @f.preservation_collection = (PRESERVATION_CONFIG['preservation_collection'].select {|k,v| v['yggdrasil'] == 'true'}).keys.sample
          expect(@f.validate_import('FILE', nil)).to be_truthy
        end
        describe '#updates' do
          it 'should file when no updates'  do
            @f.warc_id = 'warc_id'
            @f.preservation_collection = (PRESERVATION_CONFIG['preservation_collection'].select {|k,v| v['yggdrasil'] == 'true'}).keys.sample
            expect(@f.validate_import('FILE', SecureRandom.hex(32))).to be_falsey
          end
          it 'should fail when requesting a non-existing update'  do
            warc_file_id = SecureRandom.hex(32)
            warc_record_id = SecureRandom.hex(32)
            @f.warc_id = 'warc_id'
            @f.preservation_collection = (PRESERVATION_CONFIG['preservation_collection'].select {|k,v| v['yggdrasil'] == 'true'}).keys.sample
            @f.preservationMetadata.insert_update( {'file_uuid' => warc_record_id, 'file_warc_id' => warc_file_id} )
            expect(@f.validate_import('FILE', SecureRandom.hex(32))).to be_falsey
          end
          it 'should be possible to find a update'  do
            warc_file_id = SecureRandom.hex(32)
            warc_record_id = SecureRandom.hex(32)
            @f.warc_id = 'warc_id'
            @f.preservation_collection = (PRESERVATION_CONFIG['preservation_collection'].select {|k,v| v['yggdrasil'] == 'true'}).keys.sample
            @f.preservationMetadata.insert_update( {'file_uuid' => warc_record_id, 'file_warc_id' => warc_file_id} )
            expect(@f.validate_import('FILE', warc_record_id)).to be_truthy
          end
        end
      end

      # TODO send_request_to_import
      # TODO initiate_import_from_preservation
    end
  end
end
