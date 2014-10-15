require 'spec_helper'

describe Datastreams::MADS::Document do
  describe 'person methods' do

    before :all do
      file = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'mads_person.xml'))
      @ds = Datastreams::MADS::Document.from_xml(file)
    end

    describe 'authorized_personal_names' do
      it 'returns a hash of authorized names' do
        expect(@ds.authorized_personal_names).to be_a Hash
      end

      it 'organises the hash by the authority type' do
        expect(@ds.authorized_personal_names.keys).to include(:naf)
      end

      it 'should parse authorised family names' do
        expect(@ds.authorized_personal_names[:naf].keys).to include(:family)
      end
      it 'should parse an authorised given name' do
        expect(@ds.authorized_personal_names[:naf].keys).to include(:given)
      end
      it 'should parse an authorised date' do
        expect(@ds.authorized_personal_names[:naf].keys).to include(:date)
      end

    end

    describe 'other_personal_names' do
      it 'should return an array of other names' do
        expect(@ds.other_personal_names).to be_an Array
      end

      it 'should parse the full name when present' do
        expect(@ds.other_personal_names.first.keys).to include(:full)
        expect(@ds.other_personal_names.first[:full]).to eql 'Gayetsky, Stanley'
      end
    end

    describe 'notes' do
      it 'should return an array of notes' do
        expect(@ds.notes).to be_an Array
      end

      it 'should parse the note elements' do
        expect(@ds.notes.first).to include('Sauter, E.E. St')
      end
    end
  end
end
