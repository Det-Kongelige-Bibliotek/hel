require 'spec_helper'

describe Datastreams::Bibframe::InstanceMetadata do
  before :all do
    file = File.new('./spec/fixtures/test_instance.xml')
    @ds = Datastreams::Bibframe::InstanceMetadata.from_xml(file)
  end

  it 'should parse the language' do
    expect(@ds.language).to eql ['eng']
  end

  it 'should parse the language authority' do
    expect(@ds.language_authority).to eql ['http://id.loc.gov/vocabulary/languages.html']
  end

  it 'should parse the note' do
    expect(@ds.note).to eql ['Mode of access: World Wide Web.']
  end

  it 'should parse the production date' do
    expect(@ds.production_date).to eql ['1998']
  end
  it 'should parse the production note' do
    expect(@ds.production_note).to eql ['Bangor']
  end

  it 'should parse the publication date' do
    expect(@ds.publication_date).to eql ['1999']
  end

  it 'should parse the publication note' do
    expect(@ds.publication_note).to eql ['Washington D.C.']
  end

  it 'should parse the distribution date' do
    expect(@ds.distribution_date).to eql ['2000']
  end

  it 'should parse the distribution note' do
    expect(@ds.distribution_note).to eql ['Horseback.']
  end

  it 'should parse the identifier value' do
    expect(@ds.identifier_value).to eql ['00078344056']
  end

  it 'should parse the identifier scheme' do
    expect(@ds.identifier_scheme).to eql ['aleph']
  end

  it 'returns a hash of identifiers and their values' do
    h = @ds.identifier_set
    expect(h).to be_a Hash
    expect(h.keys).to include(:aleph)
    expect(h.values).to include('00078344056')
  end

  it 'parses an isbn13' do
    expect(@ds.isbn13).to eql ['9780521169004']
  end
  it 'writes an isbn13' do
    new = Datastreams::Bibframe::InstanceMetadata.new
    new.isbn13 = '0123456789012'
    expect(new.isbn13).to eql ['0123456789012']
  end
end
