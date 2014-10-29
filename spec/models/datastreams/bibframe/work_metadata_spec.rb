require 'spec_helper'

describe Datastreams::Bibframe::WorkMetadata do
  before :all do
    file = File.new('./spec/fixtures/gutenberg.xml')
    @ds = Datastreams::Bibframe::WorkMetadata.from_xml(file)
  end

  describe 'titles' do
    it 'returns an array of title objects' do
      expect(@ds.titles).to be_an Array
      expect(@ds.titles.first).to be_a Datastreams::Bibframe::Title
    end

    it 'has a titleType for each title object' do
      expect(@ds.titles.first.type).to eql 'uniform'
    end

    it 'has a subtitle for each title object' do
      expect(@ds.titles.first.subtitle).to eql 'Heroes * Villains * Towers * Punishment!'
    end

    it 'has a value for each title object' do
      expect(@ds.titles.first.value).to be_a String
    end

    it 'has a value for each title value' do
      expect(@ds.titles.first.value).to eql 'Gutenberg Bible'
    end

    it 'has a lang for each title object' do
      expect(@ds.titles.first.lang).to eql 'en'
    end

    it 'can return an array of title values only' do
      expect(@ds.title_values).to be_an Array
      expect(@ds.title_values).to include 'The Mazarin Bible'
    end

    it 'allows us to write a title' do
      ds = Datastreams::Bibframe::WorkMetadata.new
      ds.add_title(type: 'uniform', subtitle: 'and so on...', lang: 'en', value: 'Great Expectations')
      expect(ds.titles.first.subtitle).to eql 'and so on...'
      expect(ds.titles.first.type).to eql 'uniform'
      expect(ds.titles.first.value).to eql 'Great Expectations'
      expect(ds.titles.first.lang).to eql 'en'
    end
  end

  it 'parses a note' do
    expect(@ds.note).to eql ['A printed bible!']
  end

  it 'parses the language' do
    expect(@ds.languages.first.value).to eql 'Latin'
  end

  it 'parses the uuid' do
    expect(@ds.uuid).to eql 'reallyrandomuuid'
  end

  it 'allows us to write a uuid' do
    ds = Datastreams::Bibframe::WorkMetadata.new
    ds.uuid = 'anotherrandomuuid'
    expect(ds.uuid).to eql 'anotherrandomuuid'
  end
end
