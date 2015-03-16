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
    elements = list.elements.to_a
    elements.map!{ |e| [ (e.label.present? ? e.label : e.name), e.name] }
    elements.sort { |x,y| x.first <=> y.first }
  end

  def get_entry_label(list_name, entry_name)
    Administration::ControlledList.with(:name, list_name).elements.find(name: entry_name).first.label
  end

  def get_preservation_profiles_for_select
    profiles = []
    PRESERVATION_CONFIG['preservation_profile'].each do |key,value|
      profiles << [value['name'], key]
    end
    profiles
  end

  def translate_model_names(name)
    I18n.t("models.#{name.parameterize('_')}")
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

    private


    def collect_title(titles,id)
      titles.collect {|title| [title,id]}
    end

end
