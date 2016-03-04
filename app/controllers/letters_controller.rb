require 'htmlentities'

class LettersController < ApplicationController
  def update
    # here we do the letter update
    begin
      json = letter_params
      parts = json[:file].rpartition("/")
      coll = "/db#{ parts.first }"
      res = SnippetServer.update_letter(json.as_json.to_json ,{doc: parts.last, id: json[:xml_id], :c => coll, :op=>'json'})
      solr_doc = SnippetServer.solrize({doc: parts.last, c: coll, id: json[:xml_id], work_id: json[:work_id],status: json[:status]})
      solr = RSolr.connect :url => CONFIG[Rails.env.to_sym][:solr_url]
      solr.update(data: '<?xml version="1.0" encoding="UTF-8"?>'+solr_doc)
      solr.commit
      flash[:notice] = 'Brev Opdateret'
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      flash[:error] = "Kunne ikke opdatere brev. Problemer med server"
    end
    letter_id = "#{File.dirname(json[:file])}/#{File.basename(json[:file],'.xml')}-#{json[:xml_id]}"

    redirect_to "#{solr_document_path(letter_id)}"
  end


  private
  def letter_params
    result = {}
    result[:xml_id] = params['letter']['xml_id']
    result[:work_id] = params['letter']['work_id']
    result[:file] = params['letter']['file']
    result[:sender] = get_person_list(params['letter']['sender'])
    result[:recipient] = get_person_list(params['letter']['recipient'])
    result[:place] = get_place_list(params['letter']['place'])
    result[:date] = params['letter']['date']
    result[:status] = params['letter']['status']
    result
  end

  def get_person_list(persons)
    result = []
    persons.each do |k,p|
      unless p['_destroy'] == '1'
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
    end
    result
  end


  def get_place_list(places)
    result = []
    coder = HTMLEntities.new
    places.each do |k,p|
      puts "place #{p.inspect}"
      unless p['_destroy'] == '1'
        phash = {}
        phash['xml_id'] = p['xml_id']
        phash['name'] = p['name']
        phash['type'] = p['type']
        result << phash
      end
    end
    result
  end


end
