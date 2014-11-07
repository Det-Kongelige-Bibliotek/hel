require 'spec_helper'

# Dummy class for testing
class Stub < ActiveFedora::Base
  include Bibframe::Work
end

describe Bibframe::Work do
  before :all do
    @stub = Stub.new
  end

  describe 'on include' do
    it 'fails when included from a non AF class' do
      expect {
        # doesn't extend AF::Base
        class StubNoAF; include Bibframe::Work; end
      }.to raise_error(RuntimeError)
    end

    it 'does not fail when included from an AF descendant' do
      expect { class Desc < Stub; end }.not_to raise_error
    end
  end

  describe 'Datastreams:' do
    it 'should add Bibframe datastream' do
      expect(@stub.datastreams.keys).to include('bfMetadata')
    end
  end

  describe 'Literals:' do
    it 'should be possible to add a title' do
      @stub.add_title(value: 'The Importance of Being Earnest')
      expect(@stub.title_values).to include('The Importance of Being Earnest')
    end

    it 'should be possible to add a language with a part' do
      @stub.language = { value: 'French', part: 'Spine' }
      expect(@stub.language_values).to include 'French'
    end

    it 'should be possible to add a language without a part' do
      @stub.language = { value: 'Gaeilge' }
      expect(@stub.language_values).to include 'Gaeilge'
    end

    it 'should be possible to add an identifier' do
      @stub.add_identifier(scheme: 'kb', value: 'hoojabooja')
      expect(@stub.identifiers[:kb]).to eql 'hoojabooja'
    end
  end

  describe 'respond_to' do
    it 'should return true for methods the datastream has' do
      expect(@stub.respond_to?(:uuid=)).to eql true
    end
    it 'should return false for methods the datastream does not have' do
      expect(@stub.respond_to?(:nonsense_method)).to eql false
    end
  end
end
