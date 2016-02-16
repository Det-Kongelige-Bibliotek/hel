class LettersController < ApplicationController
  def update
    # here we do the letter update
    begin
      json = letter_params
      parts = json[:file].rpartition("/")
      coll = "/db#{ parts.first }"
      res = SnippetServer.update_letter(parts.last,json[:id],json.to_json.html_safe,{:c => coll, :op=>'solrize'})
      flash[:notice] = 'Brev Opdateret'
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      flash[:error] = "Kunne ikke opdatere brev. Proplemer med server"
    end
    letter_id = "#{File.dirname(json[:file])}/#{File.basename(json[:file],'.xml')}-#{json[:id]}"

    redirect_to "#{solr_document_path(letter_id)}"
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
      if person_object.present?
        phash['auth_id'] = p['auth_id']
        phash['xml_id'] = p['xml_id']
        phash['given_name'] = person_object.given_name
        phash['family_name'] = person_object.family_name
        result << phash
      else
        logger.error("Unkown person #{p['auth_id']} submittet to letter")
      end
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