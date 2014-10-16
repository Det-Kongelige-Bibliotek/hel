require 'spec_helper'

describe Authority::Person do
  before :all do
    @p = Authority::Person.new
  end

  it 'should allow us to set an authorized name' do
    @p.add_authorized_personal_name(full: 'James Joyce', scheme: 'viaf')
    expect(@p.authorized_personal_names[:viaf][:full]).to eql 'James Joyce'
  end
  it 'should allow us to set a variant name'
end
