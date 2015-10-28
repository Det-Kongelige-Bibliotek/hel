require 'spec_helper'

describe Authority::PeopleController, :type => :controller do

  describe 'destroy' do
    it 'delete the requested person' do
      person = Authority::Person.create(  'given_name'=> 'test1',
                                          'family_name' => 'test',
                                          'birth_date' => '1923',
                                          'death_date' => '2010',
                                          'birth_place' => 'Denmark',
                                          'death_place' => 'Denmark',
                                          'nationality' => 'Danish')
      expect {
        person.destroy
      }.to change(Authority::Person, :count).by(-1)
    end
  end
end