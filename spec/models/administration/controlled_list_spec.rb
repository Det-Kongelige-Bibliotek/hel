require 'spec_helper'

describe Administration::ControlledList do

  it_behaves_like 'ActiveModel'

  it 'should have a name' do
    cr = Administration::ControlledList.new
    cr.name = 'my first controlled list'
    expect(cr.name).to eql 'my first controlled list'
  end

  describe 'entries' do
    it 'should be possible to add entries' do
      cr = Administration::ControlledList.create
      e = Administration::ListEntry.create(name: 'new element', controlled_list: cr)
      expect(cr.elements.first).to eql e
    end

    it 'should be possible to add labels for entries' do
      e = Administration::ListEntry.new(name: 'sv', label: 'Svensk')
      expect(e.label).to eql 'Svensk'
    end
  end
end