class LettersController < ApplicationController
  def update
    # here we do the letter update
    SnippetServer.update_letter(letter_params.to_json)
    render text: letter_params.to_json
  end



  private
  def letter_params
    result = {}
    result[:id] = params['letter']['id']
    result[:file] = params['letter']['file']
    result[:sender] = get_person_list(params['letter']['sender'])
    result[:recipient] = get_person_list(params['letter']['recipient'])
    result[:place] = get_place_list(params['letter']['place'])
    result[:date] = params['letter']['date']
    result
  end

  def get_person_list(persons)
    result = []
    persons.each do |k,p|
      phash = {}
      person_object = Authority::Person.where(id: p['auth_id']).first
      phash['auth_id'] = p['auth_id']
      phash['xml_id'] = p['xml_id']
      if person_object.present?
        phash['given_name'] = person_object.given_name
        phash['family_name'] = person_object.family_name
      else
        logger.error("Unkown person #{p['auth_id']} submittet to letter")
      end
      result << phash
      puts result.to_json
    end
    result
  end


  def get_place_list(places)
    result = []
    places.each do |k,p|
      phash = {}
      phash['auth_id'] = p['auth_id']
      phash['xml_id'] = p['xml_id']
      phash['place'] = p['place']
      result << phash
    end
    result
  end
end