# This class should be called statically to execute common Solr queries
class Finder

  def self.obj(id)
    ActiveFedora::SolrService.query("id:#{id}")
  end

  def self.all_people(q=nil)
    ActiveFedora::SolrService.query(model_query('Authority*Person') + (q.nil? ? '' : ' && '+typeahead_query(q)), :rows => max_rows)
  end

  def self.all_organizations(q=nil)
    ActiveFedora::SolrService.query("active_fedora_model_ssi:Authority*Organization" + (q.nil? ? '' : ' && '+typeahead_query(q)), :rows => max_rows)
  end

  def self.all_works
    ActiveFedora::SolrService.query(model_query('Work'), :rows => max_rows)
  end

  def self.works_by_title(title)
    ActiveFedora::SolrService.query("#{model_query('Work')} && title_tesim: \"#{title}\"", :rows => max_rows)
  end

  def self.search_by_same_as_uri(uri)
    ActiveFedora::SolrService.query("same_as_uri_tesim:\"#{uri}\" ")
  end

  def self.model_query(model)
    "active_fedora_model_ssi: #{model}"
  end

  def self.typeahead_query(q)
    "typeahead_tesim:#{q}*"
  end

  def self.max_rows
    1000000
  end

end