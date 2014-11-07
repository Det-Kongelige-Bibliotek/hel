# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Administration::Activity do

  it_behaves_like 'ActiveModel'

  it 'should have an activity' do
    act = Administration::Activity.new
    act.activity = 'my first activity'
    expect(act.activity).to eql 'my first activity'
  end

end
