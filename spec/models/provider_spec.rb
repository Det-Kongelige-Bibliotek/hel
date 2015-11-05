require 'spec_helper'

describe Provider do
  let(:provider) { Provider.new}

  it 'should respond to copyright date' do
    provider.copyright_date = '2005'
    expect(provider.copyright_date).to eql '2005'
  end
  it 'should respond to provider date' do
    provider.provider_date = '2005'
    expect(provider.provider_date).to eql '2005'
  end

  it 'should respond to agent' do
    provider.agent = Authority::Organization.new(_name: 'Gyldendal')
    expect(provider.agent).to be_an Authority::Organization
    expect(provider.agent._name).to eql 'Gyldendal'
  end

  it 'should respond to provider place' do
    provider.place = Authority::Place.new(_name: 'København')
    expect(provider.place).to be_an Authority::Place
    expect(provider.place._name).to eql 'København'
  end

  it 'should respond to provider role' do
    provider.role = 'publisher'
    expect(provider.role).to eql'publisher'
  end

  it 'only accepts valid EDTF date values for copyright date' do
    provider.copyright_date = 'abcd'
    expect(provider.valid?).to eql false
    provider.copyright_date = '1983'
    expect(provider.valid?).to eql true
  end

  it 'only accepts valid EDTF date values for provider date' do
    provider.provider_date = 'abcd'
    expect(provider.valid?).to eql false
    provider.provider_date = '1983'
    expect(provider.valid?).to eql true
  end
end