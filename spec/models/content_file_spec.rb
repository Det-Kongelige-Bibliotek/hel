require 'spec_helper'

describe 'content' do
  include_context 'shared'

  it 'should allow us to upload a file' do
    i = Instance.new(instance_params)
    c = ContentFile.new
    c.instance = i
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
    c.add_file(f)
    expect(c.fileContent.content).not_to be_nil
  end

  it 'has a relation to an instance' do
    i = Instance.new
    c = ContentFile.new
    c.instance = i
    expect(c.instance).to eql i
  end

  describe '#fits' do
    it 'should respond to add_fits_metadata_datastream' do
      c = ContentFile.new
      c.should respond_to :add_fits_metadata_datastream
    end

    it 'should have a fits datastream' do
      c = ContentFile.new
      expect(c.reflections.keys).to include :fitsMetadata
    end

    it 'fits datastream should initially be nil' do
      c = ContentFile.new
      expect(c.fitsMetadata.content).to be_nil
    end

    describe 'content of fitsmetadata' do
      before :all do
        @c = ContentFile.new
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @c.add_file(f, false)
        @c.add_fits_metadata_datastream(f)
        @c.save!
      end

      it 'should not be nil' do
        expect(@c.fitsMetadata.content).not_to be_nil
      end

      it 'should not be empty' do
        expect(@c.fitsMetadata.content).not_to be_empty
      end

      it 'should have a fits as root' do
        xml = Nokogiri::XML(@c.fitsMetadata.content)
        expect(xml.root.name).to eq "fits"
      end

      it 'should set format name' do
        expect(@c.format_name).not_to be_nil
        expect(@c.format_name).to eq 'Extensible Markup Language'
      end

      it 'should set format mimetype' do
        expect(@c.format_mimetype).not_to be_nil
        expect(@c.format_mimetype).to eq 'text/xml'
      end

      it 'should set format version' do
        expect(@c.format_version).not_to be_nil
        expect(@c.format_version).to eq '1.0'
      end

      it 'should set pronom id' do
        expect(@c).to respond_to(:format_pronom_id)
        expect(@c.format_pronom_id).to eq "unknown"
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
      c = ContentFile.new
      c.format_name = 'format_name'
      c.format_mimetype = 'format_mimetype'
      c.format_version = 'format_version'
      c.save!
      c.reload
      expect(c.format_name).to eq 'format_name'
      expect(c.format_mimetype).to eq 'format_mimetype'
      expect(c.format_version).to eq 'format_version'
    end
  end

  describe '#preservation' do
    describe '#create_preservation_message' do
      before :each do
        @f = ContentFile.create
        @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')), false)
      end
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

      describe '#Update' do
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
      before :each do
        @f = ContentFile.create
        f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
        @f.add_file(f)
        @f.save
        @f.reload
      end

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
  end
end
