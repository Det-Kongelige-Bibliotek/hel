require 'spec_helper'
require 'fakeredis'
require 'resque'

describe 'ingest a letter_book' do
  include_context 'shared'

  describe 'tei file' do
    it 'it should read an xml file' do 
      LetterBookIngest.perfom("spec/fixtures/breve/001003523_000/001003523_000.xml")
    end
  end

end

