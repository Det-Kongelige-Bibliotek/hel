# View helpers that are shared between different models
module ApplicationHelper
  # Gets the list of a controlled list
  # @param name of a controlled list
  def get_controlled_vocab(list_name)
    list = Administration::ControlledList.with(:name, list_name)
    list.nil? ? [] : list.elements.map(&:name)
  end

  # Given a list name, return a list of arrays
  # suitable for dropdowns, whereby the display
  # string value is translated via i18n
  # sorted by the value of the first element
  def get_translated_list(list_name)
    list = get_controlled_vocab(list_name)
    list.map!{ |e| [I18n.t("#{list_name}.#{e}".to_sym), e]}
    list.sort { |x,y| x.first <=> y.first }
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
      results.nil? ? [] : results.collect{|result| [result['display_value_ssm'].first,result['id']]}
    end

    private


    def collect_title(titles,id)
      titles.collect {|title| [title,id]}
    end

end
