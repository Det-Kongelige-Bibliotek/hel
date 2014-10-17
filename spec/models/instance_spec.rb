require 'spec_helper'

describe Instance do
  it 'has many files' do
    i = Instance.new
    expect(i.content_files.size).to eql 0
  end

  it 'should have a uuid on creation' do
    i = Instance.new
    expect(i.uuid).to be_nil
    i.save
    expect(i.uuid.present?).to be true
  end
end
