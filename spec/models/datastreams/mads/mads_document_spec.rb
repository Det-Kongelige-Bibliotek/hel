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

    describe 'add_authorized_personal_name' do
      before :all do
        @name = { scheme: 'viaf', family: 'Joyce', given: 'James', date: '1882-1941' }
      end

      it 'allows us to add a new personal name' do
        @ds.add_authorized_personal_name(@name)
        expect(@ds.authorized_personal_names[:viaf][:family]).to eql 'Joyce'
      end
      it 'requires at least one name element' do
        no_names = @name.except(:family).except(:given)
        expect {
          @ds.add_authorized_personal_name(no_names)
        }.to raise_error
      end
      it 'requires an authority scheme' do
        expect {
          @ds.add_authorized_personal_name(@name.except(:scheme))
        }.to raise_error
      end
      it 'does not add empty elements' do
        @ds.add_authorized_personal_name(@name.merge(family: ''))
        expect(@ds.authorized_personal_names[:viaf].keys).not_to include(:family)
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

    describe 'identifier(type)' do
      it 'retrieves an identifier of the given type from the document' do
        expect(@ds.identifier('uuid')).to eql 'reallyrandomuuid'
      end
      it 'retrieves nil if no identifier of that type is found' do
        expect(@ds.identifier('not_here')).to eql nil
      end
    end

    describe 'uuid' do
      it 'retrieves an identifier with type uuid' do
        expect(@ds.uuid).to eql ['reallyrandomuuid']
      end
    end
  end
end
