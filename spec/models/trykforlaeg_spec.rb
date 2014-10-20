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

  it 'can accept different isbn13 formats' do
    t = Trykforlaeg.new
    t.isbn13 = '978-3-16-148410-0'
    expect(t.valid?).to eq true
    t.isbn13 = '978-0-321-58410-6'
    expect(t.valid?).to eq true
  end
end
