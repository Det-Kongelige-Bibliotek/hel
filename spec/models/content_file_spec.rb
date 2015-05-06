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
      c.datastreams.keys.should include 'fitsMetadata'
    end

    it 'fits datastream should initially be nil' do
      c = ContentFile.new
      c.datastreams['fitsMetadata'].content.should be_nil
      c.fitsMetadata.content.should be_nil
    end

    describe 'content of fitsmetadata' do
      before :all do
        @c = ContentFile.new
        @c.add_fits_metadata_datastream(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
      end

      it 'should not be nil' do
        @c.fitsMetadata.content.should_not be_nil
      end

      it 'should not be empty' do
        @c.fitsMetadata.content.should_not be_empty
      end

      it 'should have a fits as root' do
        xml = Nokogiri::XML(@c.fitsMetadata.content)
        puts xml.root.name.should eq "fits"
      end
    end
  end
end
