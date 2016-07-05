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
      #  self.send_to_solr(solr_doc)
      rescue Exception => e
        raise "Unable to solrize letters #{e.message}"
      end


      #Create solr doc for volume
      doc = {id: "/letter_books/#{sysnum}/#{lb.get_file_name}", application_ssim: 'DKLetters'}
      doc[:volume_title_ssim] = []
      lb.titles.each do |title|
        doc[:volume_title_ssim] << title.value
      end
      doc[:editor_id_ssim] = []
      doc[:author_id_ssim] = []
      lb.relators.each do |agent|
        doc[:editor_id_ssim] << agent.id if agent.role == 'http://id.loc.gov/vocabulary/relators/edt'
        doc[:author_id_ssim] << agent.id if agent.role == 'http://id.loc.gov/vocabulary/relators/aut'
      end
      doc[:edition_ssi] = instance.edition if instance.edition.present?
      doc[:publisher_name_ssi] = instance.publisher if instance.publisher.present?
      doc[:published_date_ssi] = instance.published_date if instance.published_date.present?
      doc[:note_ssi] = instance.note if instance.note.present?
     # RSolr.connect.xml.add(doc,{})
      puts doc

      #Get all persons in letterbook
      lb.relators.each do |agent|
        if ['http://id.loc.gov/vocabulary/relators/edt','http://id.loc.gov/vocabulary/relators/aut'].include? agent.role
          send_person_to_solr(agent.id)
        end
      end

      #Create solr doc(s) for persons and orgs
      #Get all persons in letters
      letters = Finder.get_all_letters(lb.id)
      letters.each do |letter|
        letter['sender_id_ssim'].each do |sender|
          send_person_to_solr(sender)
        end
        letter['recipient_id_ssim'].each do |sender|
          send_person_to_solr(sender)
        end
      end

    end

    def self.send_to_solr(solr_doc)
      solr = RSolr.connect :url => CONFIG[Rails.env.to_sym][:bifrost_letters_solr_url]
      solr.update(data: '<?xml version="1.0" encoding="UTF-8"?>'+solr_doc)
      solr.commit
    end

    def self.send_person_to_solr(person_id)
      Resque.logger.debug "disseminating author #{person.id}"
      person = Authority::Person.where(id: person_id);
      if person.present?
        doc = {id: person.id, cat_ssi: 'person', work_title_tesim: person.full_name,
               family_name_ssi: person.family_name, given_name_ssi: person.given_name,
               birth_date_ssi: person.birth_date, death_date_ssi: person.death_date, type_ssi: 'trunk', application_ssim: 'DKLetters'}
        #  RSolr.connect.xml.add(doc,{})
        puts doc
      else
        Resque.logger.error "Person #{person_id} not found"
      end
    end
  end
end