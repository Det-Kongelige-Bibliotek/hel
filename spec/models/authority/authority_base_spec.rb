require 'spec_helper'

describe Authority::Base do

  before :all do
    @b = Authority::Base.new
  end
  describe 'uuid' do
    it 'allows us to set and get a uuid' do
      @b.uuid = 'xyz'
      expect(@b.uuid).to eql 'xyz'
    end
  end
  it 'should have a MADS datastream' do
    expect(@b.datastreams.keys).to include 'mads'
  end

  it 'should return all descendant class' do
    p = Authority::Person.create
    expect(Authority::Base.descendants).to include(p)
    p.delete
  end
end
