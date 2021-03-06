# -*- coding: utf-8 -*-
require 'spec_helper'

describe Authority::Person do

  describe 'constructor' do
    it 'should be possible to initialize without any values' do
      expect(Authority::Person.new).to be_an Authority::Person
    end
    it 'should be possible to initialize with a name hash' do
      p = Authority::Person.new(
       { 'same_as_uri' => ['http://viaf.org/viaf/44300643'], 'family_name' => 'Joyce', 'given_name' => 'James', 'birth_date' => '1932', 'death_date' => '2009' })
      expect(p).to be_an Authority::Person
      expect(p.full_name).to include 'Joyce, James'
    end
    it 'should be possible to initialize with an array of name hashes' do
      p = Authority::Person.new(
           { 'given_name' => 'Myles', 'family_name' => 'Na Gopaleen', 'same_as_uri' => ['http://example.org'] }
      )
      expect(p.full_name).to include 'Na Gopaleen, Myles'
    end
  end

  before :each do
    @p = Authority::Person.new
  end

  describe 'setters' do
    it 'should allow us to set an authorized name' do
      @p.authorized_personal_name = { 'family' => 'James Joyce'}
      expect(@p.authorized_personal_names[:kb][:family]).to eql 'James Joyce'
    end
    it 'should allow us to set a variant name' do
      @p.alternate_names.push "Sunny Jim"
      expect(@p.alternate_names).to include "Sunny Jim"
    end
  end

  describe 'display_value' do
    it 'contains the full name when this is present' do
      @p.authorized_personal_name = { 'family' => 'James Joyce'}
      expect(@p.display_value).to include 'James Joyce'
    end
    it 'contains the family name when no full name is present' do
      @p.family_name = 'Joyce'
      @p.same_as = [::RDF::URI.new('http://viaf.org/viaf/44300643')]
      expect(@p.display_value).to include 'Joyce'
    end
  end

  describe 'all names' do
    it 'returns an array of structured names' do
      @p.given_name = 'Myles'
      @p.family_name = 'Na Gopaleen'
      @p.same_as = [::RDF::URI.new('http://example.org')]
      expect(@p.full_name).to include('Na Gopaleen, Myles')
    end
  end

  describe 'to_solr' do
    it 'adds all authorized names to the solr doc' do
      @p.given_name = 'Myles'
      @p.family_name = 'Na Gopaleen'
      @p.same_as = [::RDF::URI.new('http://example.org/')]
      expect(@p.to_solr.values.flatten).to include('Na Gopaleen, Myles')
    end
  end
end
