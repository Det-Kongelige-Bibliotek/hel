require 'spec_helper'

describe Datastreams::Bibframe::InstanceMetadata do

  describe 'parsing' do

    before :all do
      file = File.new('./spec/fixtures/test_instance.xml')
      @ds = Datastreams::Bibframe::InstanceMetadata.from_xml(file)
    end

    it 'parses the mode of issuance' do
      expect(@ds.mode_of_issuance).to eql ['single unit']
    end
    it 'parses the title statement' do
      expect(@ds.title_statement).to eql ['Ars minor fragment.']
    end
    it 'parses the dimensions' do
      expect(@ds.dimensions).to eql ['10.7 x 30.8 cm.']
    end
    it 'parses the extent' do
      expect(@ds.extent).to eql ['parts of 2 leaves ;']
    end
    it 'parses the copyright date' do
      expect(@ds.copyright_date).to eql ['ca. 1453-1454.']
    end
    it 'parses an isbn13' do
      expect(@ds.isbn13).to eql ['9780521169004']
    end
    it 'parses a published date' do
      expect(@ds.published_date).to eql ['1454']
    end
  end

  describe 'writing' do
    it 'writes an isbn13' do
      new = Datastreams::Bibframe::InstanceMetadata.new
      new.isbn13 = '0123456789012'
      expect(new.isbn13).to eql ['0123456789012']
    end

    it 'writes a copyright date' do
      new = Datastreams::Bibframe::InstanceMetadata.new
      new.copyright_date = '19-05-2085'
      expect(new.copyright_date).to eql ['19-05-2085']
    end

  end
end
