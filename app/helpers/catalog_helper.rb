module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  ##
  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation.
  # Displays the "showing X through Y of N" message.
  #
  # @param [RSolr::Resource] (or other Kaminari-compatible objects)
  # @return [String]
  def page_entries_info(collection, options = {})
    entry_name = if options[:entry_name]
                   options[:entry_name]
                 elsif collection.respond_to? :model  # DataMapper
                   collection.model.model_name.human.downcase
                 elsif collection.respond_to? :model_name and !collection.model_name.nil? # AR, Blacklight::PaginationMethods
                   collection.model_name.human.downcase
                 elsif collection.is_a?(::Kaminari::PaginatableArray)
                   'entry'
                 else
                   t('blacklight.entry_name.default')
                 end

    entry_name = entry_name.pluralize(collection.total_count, I18n.locale) unless collection.total_count == 1

    # grouped response objects need special handling
    end_num = if collection.respond_to? :groups and render_grouped_response? collection
                collection.groups.length
              else
                collection.limit_value
              end

    end_num = if collection.offset_value + end_num <= collection.total_count
                collection.offset_value + end_num
              else
                collection.total_count
              end

    case collection.total_count
      when 0; t('blacklight.search.pagination_info.no_items_found', :entry_name => entry_name ).html_safe
      when 1; t('blacklight.search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
      else; t('blacklight.search.pagination_info.pages', :entry_name => entry_name, :current_page => collection.current_page, :num_pages => collection.total_pages, :start_num => number_with_delimiter(collection.offset_value + 1) , :end_num => number_with_delimiter(end_num), :total_num => number_with_delimiter(collection.total_count), :count => collection.total_pages).html_safe
    end
  end
end

