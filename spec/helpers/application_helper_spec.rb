require 'spec_helper'
class Dummy
  include ApplicationHelper
end

describe 'ControlledList helpers' do
  before :all do
    @cl = Administration::ControlledList.create(name: 'sample list')
    Administration::ListEntry.create(name: 'jim', label: 'tinker', controlled_list_id: @cl.id)
    Administration::ListEntry.create(name: 'jam', label: 'tailor', controlled_list_id: @cl.id)
    Administration::ListEntry.create(name: 'jon', label: 'soldier', controlled_list_id: @cl.id)
    Administration::ListEntry.create(name: 'jum', label: 'spy', controlled_list_id: @cl.id)
    @dummy = Dummy.new
  end

  after :all do
    @cl.delete
  end

  describe 'get_controlled_vocab' do
    it 'should return an array of values in a controlled list' do
      vals = @dummy.get_controlled_vocab('sample list')
      expect(vals).to be_an Array
      expect(vals.size).to be > 0
    end
  end

  describe 'get_translated_list' do
    it 'should return an array of arrays' do
      vals = @dummy.get_translated_list('sample list')
      expect(vals).to be_an Array
      expect(vals.first).to be_an Array
    end
  end

  describe 'get labelled list' do
    before :all do
      @vals = @dummy.get_list_with_labels('sample list')
    end

    it 'returns an array of arrays' do
      expect(@vals).to be_an Array
      expect(@vals.first).to be_an Array
    end

    it 'has the label as the first value and the name as the last value' do
      expect(@vals.first.first).to eql 'soldier'
      expect(@vals.first.last).to eql 'jon'
    end

    it 'sorts the list by the labels ascending' do
      expect(@vals.first.first).to be < @vals.last.first
    end
  end
end
