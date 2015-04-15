require 'spec_helper'

describe 'LetterData' do

  before :each do
    f = File.new(Rails.root.join('spec', 'fixtures', 'breve', '001541111_000', '001541111_000.xml'))
    xml = Nokogiri::XML(f.read())
    @divs = xml.css('text body div')
    @data = LetterVolumeSplitter::LetterData.new(@divs.first)
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

  describe 'preceding_page_break' do
    it 'should return false when there is no content before the first page break' do
      expect(@data.preceding_page_break?).to eql false
    end

    it 'should return true when there is content before the first page break' do
      data2 = LetterVolumeSplitter::LetterData.new(@divs[1])
      expect(data2.preceding_page_break?).to eql true
    end
  end

  describe 'language' do
    it 'should return the language code if present' do
      expect(@data.language).to eql 'da-DK'
    end
  end
end