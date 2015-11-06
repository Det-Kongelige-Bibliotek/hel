# -*- coding: utf-8 -*-
require 'spec_helper'

# same_as
# description
# image
# _name
# alternate_names

# founding_date
# dissolution_date
# location

describe Authority::Organization do
  include_context 'shared'

  describe 'constructor' do
    it 'should be possible to initialize without any values' do
      expect(Authority::Organization.new).to be_an Authority::Organization
    end
    it 'should be possible to initialize with a name hash' do
      org = Authority::Organization.new(org_params)
      org.alternate_names.push 'Gyldendal'
      expect(org).to be_an Authority::Organization
      expect(org.display_value).to include 'Nordisk forlag'
      expect(org.alternate_names).to include 'Gyldendal'
    end
    
  end

  before :each do
    Authority::Organization.destroy_all
  end

  describe 'find_or_create' do
    it 'should find an organisation if it exists' do
      created = Authority::Organization.create(org_params)
      found = Authority::Organization.find_or_create(_name: 'Gyldendalske boghandel, Nordisk forlag')
      expect(found.id).to eql created.id
    end

    it 'should create an organisation if no match is found' do
      found = Authority::Organization.find_or_create(_name: 'Pluto Press')
      expect(found).to be_a Authority::Organization
      expect(found._name).to eql 'Pluto Press'
    end
  end
end
