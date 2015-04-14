require 'spec_helper'

describe 'LetterData' do

  before :each do
    f = File.new(Rails.root.join('spec', 'fixtures', 'breve', '001541111_000', '001541111_000.xml'))
    xml = Nokogiri::XML(f.read())
    div = xml.css('text body div').first
    @data = LetterVolumeSplitter::LetterData.new(div)
  end

  describe 'title' do
    it 'should build a title' do
      expect(@data.title).to include 'Tove'
    end

    it 'should parse the sender' do
      expect(@data.sender_name).to eql 'Victor'
    end
  end

  describe 'image refs' do
    it 'should not return nil elements' do
      expect(@data.image_refs).not_to include nil
    end
  end

  describe 'language' do
    it 'should return the language code if present' do
      expect(@data.language).to eql 'da-DK'
    end
  end
end