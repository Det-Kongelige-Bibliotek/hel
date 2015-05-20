# This class should be called statically to execute common Solr queries
class Finder
  def self.all_people
    ActiveFedora::SolrService.query("active_fedora_model_ssi:Authority*Person")
  end

  def self.all_organizations
    ActiveFedora::SolrService.query("active_fedora_model_ssi:Authority*Organization")
  end

  def self.all_works
    ActiveFedora::SolrService.query("active_fedora_model_ssi:Work")
  end

end