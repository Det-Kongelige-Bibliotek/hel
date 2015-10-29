require 'spec_helper'

describe Authority::BasesController, :type => :controller do
  describe 'new' do
    it 'create new authority object' do
      authority = Authority::Bases.new
      expect(authority).to be_a Authority
    end
  end
end
