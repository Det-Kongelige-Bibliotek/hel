# This class should be called statically to execute common Solr queries
class Finder

  def self.obj(id)
    ActiveFedora::SolrService.query("id:#{id}")
  end

  def self.all_works
    ActiveFedora::SolrService.query(model_query('Work'), :rows => max_rows)
  end

  def self.works_by_title(title)
    ActiveFedora::SolrService.query("#{model_query('Work')} && title_tesim: \"#{title}\"", :rows => max_rows)
  end

  def self.get_letters(lb_id)
    solr_q = "work_id_ssi:#{lb_id}"
    ActiveFedora::SolrService.query(solr_q,:fq=>"has_model_ssim:Letter", :fq =>'type_ssi:trunk', :rows => max_rows)
  end

  def self.model_query(model)
    "active_fedora_model_ssi: #{model}"
  end

  def self.max_rows
    1000000
  end

end