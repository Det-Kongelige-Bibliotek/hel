require 'spec_helper'

describe 'Trykforlaeg' do

  it 'is invalid without an isbn13' do
    t = Trykforlaeg.new
    expect(t.valid?).to eq false
  end

  it 'is invalid when the isbn is not valid' do
    t = Trykforlaeg.new
    t.isbn13 = 'abcdefghijklm'
    expect(t.valid?).to eq false
  end

  it 'is valid with an isbn13' do
    t = Trykforlaeg.new
    t.isbn13 = '9780521169004'
    expect(t.valid?).to eq true
  end
end
