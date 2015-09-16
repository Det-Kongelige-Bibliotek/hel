# This class should be called statically to execute common Solr queries
class Finder

  def self.obj(id)
    ActiveFedora::SolrService.query("id:#{id}")
  end

  def self.all_people(q=nil)
    self.all_things(q,'Authority*Person')
  end

  def self.all_organizations(q=nil)
    self.all_things(q,'Authority*Organization')
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

  def self.all_things(q,model)
    ActiveFedora::SolrService.query("typeahead_tesim:#{q} || typeahead_tesim:#{q}*",:fq=>"active_fedora_model_ssi:#{model}", :sort =>'display_value_ssi asc')
  end

  def self.model_query(model)
    "active_fedora_model_ssi: #{model}"
  end

  def self.max_rows
    1000000
  end

end