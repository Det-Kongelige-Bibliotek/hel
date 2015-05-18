require 'spec_helper'

describe LanguageCodeConverter do

  describe 'two_to_three conversion' do
    it 'return the three letter code when a matching entry is found' do
      expect(LanguageCodeConverter.two_to_three('da')).to eql 'dan'
    end

    it 'returns nil when no match is found' do
      expect(LanguageCodeConverter.two_to_three('xx')).to be_nil
    end
  end

  describe 'two_to_loc_ref' do
    it 'returns an LOC link when a matching entry is found' do
      expect(LanguageCodeConverter.two_to_loc_ref('da')).to eql 'http://id.loc.gov/vocabulary/languages/dan'
    end

    it 'returns nil if no matching code found' do
      expect(LanguageCodeConverter.two_to_loc_ref('xx')).to be_nil
    end
  end

  describe 'tag_to_loc_ref' do
    it 'parses the language code and returns an LOC link' do
      expect(LanguageCodeConverter.tag_to_loc_ref('da-DK')).to eql 'http://id.loc.gov/vocabulary/languages/dan'
    end

    it 'returns nil if no valid code is found' do
      expect(LanguageCodeConverter.tag_to_loc_ref('xx-YY')).to be_nil
    end
  end
end