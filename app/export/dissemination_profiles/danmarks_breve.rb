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
        solr_doc = SnippetServer.solrize({doc: lb.get_file_name, c: "/db/letter_books/#{sysnum}", work_id: lb.id, app: 'DKLetters'})
        self.send_to_solr(solr_doc)
      rescue Exception => e
        #Handle Solr error
      end


      #Create solr doc for volume


      #Create solr doc(s) for persons and orgs

      #Get all persons in letterbook

      #Get all persons in letters

    end

  end

  def self.send_to_solr(solr_doc)
    solr = RSolr.connect :url => CONFIG[Rails.env.to_sym][:bifrost_letters_solr_url]
    solr.update(data: '<?xml version="1.0" encoding="UTF-8"?>'+solr_doc)
    solr.commit
  end
end