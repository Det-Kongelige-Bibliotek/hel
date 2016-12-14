module DisseminationProfiles
  class DanmarksBreve
    def self.platform
      'DanmarksBreve'
    end

    def self.disseminate(instance)
      Resque.logger.debug "Publishing letter book #{instance.id}"

      lb = instance.work
      raise 'instance has no volume' unless lb.present?

      sysnum = lb.get_file_name.split("_")[0]

      #Solrize letters
      begin
        solr_doc = SnippetServer.solrize({doc: lb.get_file_name, c: "/db/letter_books/#{sysnum}", app: 'DKLetters'})
        Resque.logger.info "#{solr_doc}"
        self.send_to_solr('<?xml version="1.0" encoding="UTF-8"?>'+solr_doc)
        Resque.logger.debug "letters send "
      rescue Exception => e
        raise "Unable to solrize letters #{e.message}"
      end

      #Create solr doc for volume
      doc = {id: "/letter_books/#{sysnum}/#{File.basename(lb.get_file_name,'.xml')}", application_ssim: 'DKLetters', cat_ssi: 'letterbook'}
      doc[:volume_title_ssim] = []
      lb.titles.each do |title|
        doc[:volume_title_ssim] << title.value
      end

      doc[:volume_title_tesim] = []
      lb.titles.each do |title|
        doc[:volume_title_tesim] << title.value
      end

      doc[:editor_id_ssim] = []
      doc[:author_id_ssim] = []
      doc[:editor_name_tesim] = []
      doc[:author_name_tesim] = []
      lb.relators.each do |rel|
        Resque.logger.debug "Letterbook agent #{rel.agent_id} #{rel.agent_id}"
        doc[:editor_id_ssim] << rel.agent_id if rel.role == 'http://id.loc.gov/vocabulary/relators/edt'
        doc[:editor_name_tesim] << self.get_person_name(rel.agent_id) if rel.role == 'http://id.loc.gov/vocabulary/relators/edt'
        doc[:author_id_ssim] << rel.agent_id if rel.role == 'http://id.loc.gov/vocabulary/relators/aut'
        doc[:author_name_tesim] << self.get_person_name(rel.agent_id) if rel.role == 'http://id.loc.gov/vocabulary/relators/aut'
      end
      doc[:edition_ssi] = instance.edition if instance.edition.present?
      doc[:publisher_name_ssi] = instance.publisher_name if instance.publisher.present?
      doc[:publisher_name_tesim] = instance.publisher_name if instance.publisher.present?
      doc[:published_date_ssi] = instance.published_date if instance.published_date.present?
      doc[:note_ssi] = instance.note if instance.note.present?
      self.send_to_solr(RSolr.connect(:url => CONFIG[Rails.env.to_sym][:bifrost_letters_solr_url]).xml.add(doc,{}))
      Resque.logger.info "Sending letterbook to bifrost solr #{doc}"

      persons = Hash.new
      #Get all persons in letterbook
      lb.relators.each do |rel|
        if ['http://id.loc.gov/vocabulary/relators/edt','http://id.loc.gov/vocabulary/relators/aut'].include? rel.role
          Resque.logger.debug "adding letterbook person #{rel.agent_id} #{get_person_doc(rel.agent_id)}"
          persons[rel.agent_id] = get_person_doc(rel.agent_id)
        end
      end

      #Create solr doc(s) for persons and orgs
      #Get all persons in letters
      letters = Finder.get_all_letters(lb.id)
      letters.each do |letter|
        if letter['sender_id_ssim'].present?
          letter['sender_id_ssim'].each do |sender|
            persons[sender] = get_person_doc(sender)
          end
        end
        if letter['recipient_id_ssim'].present?
          letter['recipient_id_ssim'].each do |rcp|
            persons[rcp] = get_person_doc(rcp)
          end
        end
      end
      persons.each do |id,doc|
        self.send_to_solr(RSolr.connect(:url => CONFIG[Rails.env.to_sym][:bifrost_letters_solr_url]).xml.add(doc,{}))
        Resque.logger.info "Sending person to bifrost solr #{doc}"
      end
    end

    def self.send_to_solr(solr_doc)
      Resque.logger.debug("connecting #{CONFIG[Rails.env.to_sym][:bifrost_letters_solr_url]}")
      solr = RSolr.connect :url => CONFIG[Rails.env.to_sym][:bifrost_letters_solr_url]
      Resque.logger.debug("connected")
      solr.update(data:solr_doc)
      Resque.logger.debug("updated")
      solr.commit
      Resque.logger.debug("comitted")
    end

    def self.get_person_doc(person_id)
      person = Authority::Person.where(id: person_id).first;
      doc = {}
      if person.present?
        doc = {id: person.id, cat_ssi: 'person',
               work_title_tesim: person.full_name,
               family_name_ssi: person.family_name,
               family_name_tesim: person.family_name,
               given_name_ssi: person.given_name,
               given_name_tesim: person.given_name,
               birth_date_ssi: person.birth_date, 
               death_date_ssi: person.death_date, 
               type_ssi: 'trunk',
               application_ssim: 'DKLetters'}

      else
        Resque.logger.error "Person #{person_id} not found"
      end
      doc
    end

     def self.get_person_name(person_id)
       person = Authority::Person.where(id: person_id).first;
       if person.present?
         name = person.full_name
       else
         Resque.logger.error "Person #{person_id} not found"
       end
       name
    end
  end
end
