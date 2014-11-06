require 'spec_helper'

describe Administration::ControlledList do

  it_behaves_like 'ActiveModel'

  it 'should have a name' do
    cr = Administration::ControlledList.new
    cr.name = 'my first controlled list'
    expect(cr.name).to eql 'my first controlled list'
  end

  it 'should have a list of elements' do
    cr = Administration::ControlledList.create
    e = Administration::ListEntry.create(name: 'new element', controlled_list: cr)
    expect(cr.elements.first).to eql e
  end
end