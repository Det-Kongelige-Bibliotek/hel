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
    solr_q = "typeahead_tesim:#{q}*"
    ActiveFedora::SolrService.query(solr_q,:fq=>"active_fedora_model_ssi:#{model}", :sort =>'display_value_ssi asc')
  end

  def self.get_all_letters(lb_id)
    solr_q = "work_id_ssi:#{lb_id}"
    ActiveFedora::SolrService.query(solr_q,:fq=>["has_model_ssim:Letter", 'type_ssi:trunk'], :sort =>'position_isi asc', :rows => max_rows)
  end

  def self.get_completed_letters(lb_id)
    solr_q = "work_id_ssi:#{lb_id}"
    ActiveFedora::SolrService.query(solr_q,:fq=>["has_model_ssim:Letter", 'type_ssi:trunk', 'status_ssi:completed'], :rows => max_rows)
  end

  def self.model_query(model)
    "active_fedora_model_ssi: #{model}"
  end

  def self.max_rows
    1000000
  end

end
