require 'spec_helper'

describe Datastreams::Bibframe::Resource do

  it 'allows us to set an identifier with a scheme and a value' do
    ds = Datastreams::Bibframe::Resource.new
    ds.add_identifier(scheme: 'sysnum', value: '123456')
    expect(ds.identifiers[:sysnum]).to eql '123456'
  end

  it 'allows us to set a uuid' do
    ds = Datastreams::Bibframe::Resource.new
    ds.uuid = 'supercoolreallyrandomuuid'
    expect(ds.uuid).to eql 'supercoolreallyrandomuuid'
  end

  it 'will only save one identifier of a given type' do
    ds = Datastreams::Bibframe::Resource.new
    ds.uuid = 'supercoolreallyrandomuuid'
    ds.uuid = 'evencooleruuid'
    schemes = ds.identifier_nodeset.map { |n| n.css('bf|identifierScheme').text }
    expect(schemes.size).to eql 1
  end

  it 'allows us to set and get the language' do
    ds = Datastreams::Bibframe::Resource.new
    ds.add_language(value: 'franglish', part: 'commentary')
    expect(ds.languages.first.part).to eql 'commentary'
    expect(ds.languages.first.value).to eql 'franglish'
  end
end
