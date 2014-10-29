require 'spec_helper'

describe Bibframe::Instance do
  before :all do
    @instance = Instance.new
  end

  describe 'on include' do
    it 'fails when included from a non AF class' do
      expect {
        # doesn't extend AF::Base
        class StubNoAF; include Bibframe::Instance; end
      }.to raise_error(RuntimeError)
    end

    it 'does not fail when included from an AF descendant' do
      expect { Instance.new }.not_to raise_error
    end
  end

  describe 'literals' do
    it 'should allow us to set and get notes' do
      @instance.note = ['a note']
      expect(@instance.note).to eql ['a note']
    end

    it 'should allow us to set and get a copyright date' do
      @instance.copyright_date = '19-02-2012'
      expect(@instance.copyright_date).to eql '19-02-2012'
    end

    it 'should allow us to set and get isbn13' do
      @instance.isbn13 = '9780521169004'
      expect(@instance.isbn13).to eql '9780521169004'
    end

    it 'should allow us to set and get a mode of issuance' do
      @instance.mode_of_issuance = 'printed'
      expect(@instance.mode_of_issuance).to eql 'printed'
    end

    it 'should allow us to set and get a title statement' do
      @instance.title_statement = 'Published in Rome'
      expect(@instance.title_statement).to eql 'Published in Rome'
    end

    it 'should allow us to set and get an extent' do
      @instance.extent = 'incomplete'
      expect(@instance.extent).to eql 'incomplete'
    end

    it 'should allow us to set and get dimensions' do
      @instance.dimensions = '36cm'
      expect(@instance.dimensions).to eql '36cm'
    end

    it 'should allow us to set and get a uuid' do
      @instance.uuid = 'veryrandomuuid'
      expect(@instance.uuid).to eql 'veryrandomuuid'
    end
  end
end
