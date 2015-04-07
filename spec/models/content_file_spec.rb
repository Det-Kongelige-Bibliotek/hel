require 'spec_helper'

describe 'content' do

  it 'should allow us to upload a file' do
    c = ContentFile.new
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml'))
    c.add_file(f)
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
      expect(c.datastreams.keys).to include 'fitsMetadata'
    end

    it 'fits datastream should initially be nil' do
      c = ContentFile.new
      expect(c.datastreams['fitsMetadata'].content).to be_nil
      expect(c.fitsMetadata.content).to be_nil
    end

    describe 'content of fitsmetadata' do
      before :all do
        @c = ContentFile.new
        @c.add_fits_metadata_datastream(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
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
        expect(@c.format_pronom_id).to be_nil
      end

    end
  end

  describe '#techMetadata' do
    it 'should have a tectMetadata datastream' do
      c = ContentFile.new
      expect(c.datastreams.keys).to include 'techMetadata'
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

  end
end
