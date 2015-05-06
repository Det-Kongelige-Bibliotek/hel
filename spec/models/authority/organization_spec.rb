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

  describe 'constructor' do
    it 'should be possible to initialize without any values' do
      expect(Authority::Organization.new).to be_an Authority::Organization
    end
    it 'should be possible to initialize with a name hash' do
      org = Authority::Organization.new(
       { 'same_as' => 'http://viaf.org/viaf/127954890', 
         '_name' => 'Gyldendalske boghandel, Nordisk forlag',
         'founding_date' => '1770' })
      org.alternate_names.push 'Gyldendal'
      expect(org).to be_an Authority::Organization
      expect(org.display_value).to include 'Nordisk forlag'
      expect(org.alternate_names).to include 'Gyldendal'
    end
    
  end

#  before :each do
#    @p = Authority::Person.new
#  end

end
