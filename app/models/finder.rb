# This class should be called statically to execute common Solr queries
class Finder
  def self.all_people
    ActiveFedora::SolrService.query(model_query('Authority*Person'))
  end

  def self.all_organizations
    ActiveFedora::SolrService.query("active_fedora_model_ssi:Authority*Organization")
  end

  def self.all_works
    ActiveFedora::SolrService.query(model_query('Work'))
  end

  def self.works_by_title(title)
    ActiveFedora::SolrService.query("#{model_query('Work')} && title_tesim: \"#{title}\"")
  end

  def self.model_query(model)
    "active_fedora_model_ssi: #{model}"
  end

end