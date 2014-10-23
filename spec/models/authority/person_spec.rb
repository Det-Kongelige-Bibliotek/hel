require 'spec_helper'

describe Authority::Person do
  before :each do
    @p = Authority::Person.new
  end

  it 'should allow us to set an authorized name' do
    @p.add_authorized_personal_name(full: 'James Joyce', scheme: 'viaf')
    expect(@p.authorized_personal_names[:viaf][:full]).to eql 'James Joyce'
  end
  it 'should allow us to set a variant name'

  describe 'display_value' do
    it 'contains the full name when this is present' do
      @p.add_authorized_personal_name(full: 'James Joyce', scheme: 'viaf')
      expect(@p.display_value).to include 'James Joyce'
    end
    it 'contains the family name when no full name is present' do
      @p.add_authorized_personal_name(family: 'Joyce', scheme: 'viaf')
      expect(@p.display_value).to include 'Joyce'
    end

    it 'returns the id if no names are present' do
      expect(@p.display_value).to eql @p.id
    end
  end

  describe 'all names' do
    it 'returns an array of structured names' do
      @p.add_authorized_personal_name(full: "Flann O'Brien", scheme: 'viaf')
      @p.add_authorized_personal_name(given: 'Myles', family: 'Na Gopaleen', scheme: 'nli')
      expect(@p.all_names).to include('Myles Na Gopaleen')
      expect(@p.all_names).to include("Flann O'Brien")
    end
  end

  describe 'to_solr' do
    it 'adds all authorized names to the solr doc' do
      @p.add_authorized_personal_name(full: "Flann O'Brien", scheme: 'viaf')
      @p.add_authorized_personal_name(given: 'Myles', family: 'Na Gopaleen', scheme: 'nli')
      expect(@p.to_solr.values.flatten).to include('Myles Na Gopaleen')
      expect(@p.to_solr.values.flatten).to include("Flann O'Brien")
    end
  end
end
