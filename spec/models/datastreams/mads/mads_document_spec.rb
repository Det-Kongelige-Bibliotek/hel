require 'spec_helper'

describe Datastreams::MADS::Document do
  describe 'person methods' do

    before :all do
      file = File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'mads_person.xml'))
      @ds = Datastreams::MADS::Document.from_xml(file)
    end

    describe 'authorized_personal_names' do
      it 'should parse authorised family names'
      it 'should parse an authorised given name'
      it 'should parse an authorised date'
      it 'should return a hash organised by authority types'
    end

    describe 'variants' do
      it 'should return an array of other names'
    end

    describe 'notes' do
      it 'should return a list of notes'
    end
  end
end
