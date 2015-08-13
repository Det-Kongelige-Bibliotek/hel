# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Administration::Activity do

  it_behaves_like 'ActiveModel'

  let(:activity) { Administration::Activity.new }

  it 'should have an activity' do
    activity.activity = 'my first activity'
    expect(activity.activity).to eql 'my first activity'
  end

  it 'should have multiple DisseminationProfiles' do
    activity.dissemination_profiles = ['ADL']
    expect(activity.dissemination_profiles).to include 'ADL'
  end

end
