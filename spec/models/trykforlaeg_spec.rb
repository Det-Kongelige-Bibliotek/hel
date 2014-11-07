require 'spec_helper'

describe 'Trykforlaeg' do

  describe 'validations' do

    describe 'isbn 13' do
      it 'is invalid without an isbn13' do
        t = build(:trykforlaeg, isbn13: nil)
        expect(t.valid?).to be false
      end

      it 'is invalid when the isbn is not valid' do
        t = build(:trykforlaeg, isbn13: 'abcdefghijklm')
        expect(t.valid?).to be false
      end

      it 'is valid with an isbn13' do
        t = build(:trykforlaeg, isbn13: '9780521169004')
        expect(t.valid?).to be true
      end

      it 'can accept different isbn13 formats' do
        t = build(:trykforlaeg, isbn13: '978-3-16-148410-0')
        expect(t.valid?).to be true
        t = build(:trykforlaeg, isbn13: '978-0-321-58410-6')
        expect(t.valid?).to be true
      end
    end

    describe 'published date' do
      it 'is invalid without a published date' do
        t = build(:trykforlaeg, published_date: nil)
        expect(t.valid?).to be false
      end

      it 'is invalid with a non-edtf date' do
        t = build(:trykforlaeg, published_date: '12-01-2009')
        expect(t.valid?).to be false
      end

      it 'is valid with an edtf date with day precision' do
        t = build(:trykforlaeg, published_date: '2001-02-03')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with month precision' do
        t = build(:trykforlaeg, published_date: '2001-12')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with year precision' do
        t = build(:trykforlaeg, published_date: '2001')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with an approximate year' do
        t = build(:trykforlaeg, published_date: '1103~')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with an uncertain year' do
        t = build(:trykforlaeg, published_date: '1103?')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with an unspecified year' do
        t = build(:trykforlaeg, published_date: '110u')
        expect(t.valid?).to be true
      end
    end
  end
end
