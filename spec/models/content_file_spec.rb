require 'spec_helper'

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
      it 'should contain Preservation_profile' do
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
      it 'should be possible to assign and save a preservation profile.' do
        profile = PRESERVATION_CONFIG['preservation_profile'].keys[rand(PRESERVATION_CONFIG['preservation_profile'].size)]
        @f.preservation_profile = profile
        @f.save!
        e2 = @f.reload
        e2.preservation_profile.should == profile
        e2.preservationMetadata.preservation_profile.first.should == profile
      end
      it 'should not be possible to assign and save a preservation profile, which is not in the configuration.' do
        profile = "Preservation-Profile-#{Time.now.to_s}"
        @f.preservation_profile = profile
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
      it 'should be possible to assign and save a preservation profile.' do
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
  end
end
