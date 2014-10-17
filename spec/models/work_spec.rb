require 'spec_helper'

describe Work do

  it 'should have a uuid on creation' do
    w = Work.new
    expect(w.uuid).to be_nil
    w.save
    expect(w.uuid.present?).to be true
  end
end
