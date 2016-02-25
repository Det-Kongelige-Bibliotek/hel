class LetterBook < Work
  accepts_nested_attributes_for :instances


  def self.new_letterbook(work_params,instance_params)
    lb = LetterBook.new(work_params)
    tei_inst = Instance.new(instance_params.merge({:type => 'TEI'}))
    tiff_inst = Instance.new(instance_params.merge({:type => 'TIFF'}))
    lb.instances=[tei_inst,tiff_inst]
    lb
  end

  def update_work(work_params)
    self.update(work_params)
  end

  def update_instances(instance_params)
    result = true
    self.instances.each do |i|
      result = result && i.update(instance_params)
    end
    result
  end

  def add_tei_file(file)
    i = get_instance('TEI')
    i.add_file(file)
  end


  def add_tiff_file(file)
    i = get_instance('TIFF')
    i.add_file(file)
  end


  def get_instance(type)
    inst = nil
    self.instances.each do |i|
      inst = i if i.type == type
    end
    inst
  end

  def to_solr(solr_doc = {})
    solr_doc.merge!(super)
    solr_doc['cat_ssi'] = 'letterbook'
    solr_doc['file_id_ssi'] = get_file_id
    solr_doc
  end

  def get_file_id
    if self.get_instance("TEI").present? && self.get_instance("TEI").try(:content_files).try(:first).try(:external_file_path).present?
      Pathname.new(self.get_instance("TEI").content_files.first.external_file_path).basename.to_s
    else
      ""
    end
  end


end
