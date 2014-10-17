require 'spec_helper'

# Test Stub
class StubNoUUID < ActiveFedora::Base
  include Concerns::UUIDGenerator
end

# Test Stub
class StubWithUUID < ActiveFedora::Base
  include Concerns::UUIDGenerator
  attr_accessor :uuid
end

describe Concerns::UUIDGenerator do

  it 'throws an error if the class has no uuid method' do
    expect { StubNoUUID.create }.to raise_error
  end
  it 'should generate a uuid on object save' do
    obj = StubWithUUID.create
    expect(obj.uuid).to be_a String
    expect(obj.uuid.size).to be > 15
  end

  it 'does not create a new uuid when an object already has one' do
    obj = StubWithUUID.create
    uuid = obj.uuid
    obj.save
    expect(obj.uuid).to eql uuid
  end
end
