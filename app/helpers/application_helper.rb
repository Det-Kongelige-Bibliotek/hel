module ApplicationHelper

    #Gets the list of a controlled list
    #@param name of a controlled list
    def get_controlled_vocab(controlled_vocab_name)
     vocabulary = Administration::ControlledList.with(:name, controlled_vocab_name)
     vocabulary.nil? ? [] : vocabulary.elements.map { |e| e.name }
    end

    #Renders a title type ahead field
    def render_title_typeahead_field
      results = Work.get_title_typeahead_objs
      select_tag "work[titles][][value]", options_for_select(results.collect {|result| collect_title(result['title_tesim'],result['id'])}.flatten(1)),
                 {include_blank: true, class: 'combobox form-control input-large', data_function: 'title-selected'}
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
