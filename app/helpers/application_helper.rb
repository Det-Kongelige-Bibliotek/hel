# View helpers that are shared between different models
module ApplicationHelper
  # Gets the list of a controlled list
  # @param name of a controlled list
  def get_controlled_vocab(list_name)
    list = Administration::ControlledList.with(:name, list_name)
    list.nil? ? [] : list.elements.map(&:name)
  end

  # Given a list name, return a list of arrays
  # suitable for dropdowns, whereby the string
  # displayed is either the element's label if present
  # or the element's name if not.
  # The list is sorted by the value of the labels ascending
  def get_list_with_labels(list_name)
    list = Administration::ControlledList.with(:name, list_name)
    elements = list.nil? ? [] : list.elements.to_a
    elements.map!{ |e| [ (e.label.present? ? e.label : e.name), e.name] }
    elements.sort { |x,y| x.first <=> y.first }
  end

  def get_entry_label(list_name, entry_name)
    entry = Administration::ControlledList.with(:name, list_name).elements.where(name: entry_name).first
    entry.label.present? ? entry.label : entry.name
  end

  def get_preservation_profiles_for_select
    profiles = []
    PRESERVATION_CONFIG['preservation_profile'].each do |key,value|
      profiles << [value['name'], key]
    end
    profiles
  end

  def translate_model_names(name)
    I18n.t("models.#{name.parameterize('_')}", default: name)
  end

  # Renders a title type ahead field
  def render_title_typeahead_field
    results = Work.get_title_typeahead_objs
    select_tag 'work[titles][][value]', options_for_select(results.map { |result| collect_title(result['title_tesim'],result['id']) }.flatten(1)),
    { include_blank: true, class: 'combobox form-control input-large', data_function: 'title-selected' }
  end

  #Renders a list of Agents for a typeahead field
  def get_agent_list
    results = Authority::Agent.get_typeahead_objs
    agents = results.nil? ? [] : results.collect{|result| [result['display_value_ssm'].first,result['id']]}
    agents.sort {|a,b| a.first.downcase <=> b.first.downcase }
  end

  def subjects_for_select
    docs = Finder.all_people + Finder.all_works
    docs.map {|doc| [ doc['display_value_ssm'].try(:first), doc['id'] ] }
  end

  #Returns a list of select options
  #Param query_result : a solr query
  #Param display_field : the solr field to be used as display field
  def select_fields(query_result, display_field = 'display_value_ssm')
    result = query_result.nil? ? [] : query_result.collect { |val| [ display_value(val, display_field), val['id'] ] }
    result.sort { |a,b| a.first.downcase <=> b.first.downcase }
  end

  # Given a solr doc and a display field, show the field or 'Unknown'
  def display_value(val, display_field)
    val[display_field].first rescue t :unknown
  end

  # Given a url from a ControlledList, create a link to this url
  # with the value of the corresponding label.
  # E.g. given the corresponding entry in the system
  # <%= rdf_resource_link('http://id.loc.gov/vocabulary/languages/abk') %>
  # Will produce: <a href="http://id.loc.gov/vocabulary/languages/abk">Abkhaz</a>
  def rdf_resource_link(entry)
    link_to Administration::ListEntry.get_label(entry), entry if entry.present?
  end

  private

  def collect_title(titles,id)
    titles.collect {|title| [title,id]}
  end

  def get_activity_name(id)
    Administration::Activity.find(id).activity
  end

  # Convert the field symbol given by an error into a name
  def just_field_name(field_sym)
    field_sym.to_s.split('.').last
  end


  # Generate a link to a instance given a work_id and instance id
  # Note: This code could be made much simpler if we
  def get_work_instance_link_for_search_result(work_id,inst_id)
    solr_id = inst_id.gsub(':','\:')
    doc =ActiveFedora::SolrService.query("id:#{solr_id}").first
    # catch cases where instance isn't present for some reason
    if doc.nil?
      link_to 'Work', work_path(work_id)
    elsif doc['active_fedora_model_ssi'] == 'Trygforlaeg'
      link_to "#{doc['active_fedora_model_ssi']} (#{doc['type_ssm'].first})", work_trykforlaeg_path(work_id, inst_id)
    else
      link_to "#{doc['active_fedora_model_ssi']} (#{doc['type_ssm'].first})", work_instance_path(work_id, inst_id)
    end
  end
end
