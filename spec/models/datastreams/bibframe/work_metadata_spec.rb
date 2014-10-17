require 'spec_helper'

describe Datastreams::Bibframe::WorkMetadata do
  before :all do
    file = File.new('./spec/fixtures/test_book.xml')
    @ds = Datastreams::Bibframe::WorkMetadata.from_xml(file)
  end
  it 'parses a title' do
    expect(@ds.title)
    .to eql ['Historic American sheet music, 1850-1920']
  end

  it 'has a subtitle method' do
    expect(@ds.subtitle)
    .to eql ['selected from the collections of Duke University.']
  end

  it 'parses a note' do
    expect(@ds.note)
    .to eql ['Mode of access: World Wide Web.']
  end

  it 'parses the language' do
    expect(@ds.language).to eql ['eng']
  end

  it 'parses the language authority' do
    expect(@ds.language_authority)
    .to eql ['http://id.loc.gov/vocabulary/languages.html']
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
