require 'spec_helper'

# Dummy class for testing
class Stub < ActiveFedora::Base
  include Bibframe::Instance
end

describe Bibframe::Instance do
  before :all do
    @stub = Stub.new
  end
  it 'should allow us to set a language value' do
    @stub.language = 'eng'
    expect(@stub.language).to eql ['eng']
  end
  it 'should allow us to set a language authority' do
    @stub.language_authority = 'I says'
    expect(@stub.language_authority).to eql ['I says']
  end
  it 'should allow us to set an identifier value' do
    @stub.identifier_value = '12345'
    expect(@stub.identifier_value).to eql ['12345']
  end
  it 'should allow us to set an identifier scheme' do
    @stub.identifier_scheme = 'aleph'
    expect(@stub.identifier_scheme).to eql ['aleph']
  end
  it 'should allow us to set a production date' do
    @stub.production_date = '1999'
    expect(@stub.production_date).to eql '1999'
  end
  it 'should allow us to set a production note' do
    @stub.production_note = 'by giant robots!'
    expect(@stub.production_note).to eql 'by giant robots!'
  end
  it 'should allow us to set a distribution date' do
    @stub.distribution_date = '2000'
    expect(@stub.distribution_date).to eql '2000'
  end
  it 'should allow us to set a distribution note' do
    @stub.distribution_note = 'On llamas!'
    expect(@stub.distribution_note).to eql 'On llamas!'
  end
  it 'should allow us to set a publication date' do
    @stub.publication_date = '2000'
    expect(@stub.publication_date).to eql '2000'
  end
  it 'should allow us to set a publication note' do
    @stub.publication_note = 'On the bottom of your fridge'
    expect(@stub.publication_note).to eql 'On the bottom of your fridge'
  end
  it 'should allow us to set and get isbn13' do
    @stub.isbn13 = '9780521169004'
    expect(@stub.isbn13).to eql '9780521169004'
  end

end
