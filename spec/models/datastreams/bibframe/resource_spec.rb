require 'spec_helper'

describe Datastreams::Bibframe::Resource do

  it 'should allow us to set and get a uuid' do
    b = Datastreams::Bibframe::Resource.new
    b.uuid = 'randomuuid'
    expect(b.uuid).to eql 'randomuuid'
  end

end
