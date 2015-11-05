require 'spec_helper'

describe 'Trykforlaeg' do
  include_context 'shared'

  describe 'validations' do

    describe 'isbn 13' do
      it 'is invalid without an isbn13' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, isbn13: nil)
        expect(t.valid?).to be false
      end

      it 'is invalid when the isbn is not valid' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, isbn13: 'abcdefghijklm')
        expect(t.valid?).to be false
      end

      it 'is valid with an isbn13' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, isbn13: '9780521169004')
        expect(t.valid?).to be true
      end

      it 'can accept different isbn13 formats' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, isbn13: '978-3-16-148410-0')
        expect(t.valid?).to be true
        t = build(:trykforlaeg, isbn13: '978-0-321-58410-6')
        expect(t.valid?).to be true
      end
    end

    describe 'published date' do
      it 'is invalid without a published date' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: nil)
        expect(t.valid?).to be false
      end

      it 'is invalid with a non-edtf date' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '12-01-2009')
        expect(t.valid?).to be false
      end

      it 'is valid with an edtf date with day precision' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '2001-02-03')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with month precision' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '2001-12')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with year precision' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '2001')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with an approximate year' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '1103~')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with an uncertain year' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '1103?')
        expect(t.valid?).to be true
      end

      it 'is valid with an edtf date with an unspecified year' do
        pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
        t = build(:trykforlaeg, published_date: '110u')
        expect(t.valid?).to be true
      end
    end
  end

  describe 'to_mods' do
    it 'is wellformed XML' do
      pending "AWAITS NEXT ITERATION OF THE TRYKFORLÆG PROJECT"
      tf = Trykforlaeg.create(valid_trykforlaeg)
      xsd = Nokogiri::XML::Schema(open('http://www.loc.gov/standards/mods/v3/mods-3-5.xsd').read)
      errors = xsd.validate(Nokogiri::XML.parse(tf.to_mods) { |config| config.strict })
      expect(errors).to eql []
    end
  end
end
