module Authority
  # To be subclassed by Person, Organisation, etc.
  class Thing < ActiveFedora::Base

    property :same_as, predicate: ::RDF::Vocab::SCHEMA.sameAs, multiple: true
    property :description, predicate: ::RDF::Vocab::SCHEMA.description, multiple: false
    property :image, predicate: ::RDF::Vocab::SCHEMA.image
    property :_name, predicate: ::RDF::Vocab::SCHEMA.name, multiple: false do |index|
      index.as :stored_searchable
    end
    property :alternate_names, predicate: ::RDF::Vocab::SCHEMA.alternateName, multiple: true

    before_save do
      edit_groups=['Chronos-Admin']
    end

    def same_as_uri=(uris)
      uris.each do |uri|
        self.same_as += [::RDF::URI.new(uri)] if uri.present?
      end
    end

    def same_as_uri
      result = []
      self.same_as.each do |s|
        result << s.to_term.value unless s.nil?
      end
      result
    end

    def display_value
      value = ''
      value += _name if _name.present?
      if alternate_names.present? then
        value += ", " 
        value += alternate_names.join(", ")
      end
      value
    end

    def date_range(dates={})
      date = ""
      date += "#{dates[:start_date]}-" if dates[:start_date].present?
      if  dates[:end_date].present? then
        if  dates[:start_date].present? then
          date += "#{dates[:end_date]}" 
        else
          date += "-" + "#{dates[:end_date]}" 
        end
      end
      date
    end

    def to_solr(solr_doc = {})
      solr_doc.merge!(super)
      Solrizer.insert_field(solr_doc, 'display_value', display_value, :stored_searchable, :displayable)
      Solrizer.insert_field(solr_doc, 'display_value', display_value, :stored_sortable)
      Solrizer.insert_field(solr_doc, 'typeahead', display_value, :stored_searchable)
      Solrizer.insert_field(solr_doc, 'same_as_uri', same_as_uri, :stored_searchable)

      solr_doc
    end


    # Given a set of parameters, attempt to find a matching object
    # if no object is found create a new one with these params
    def self.find_or_create(search_params)
      results = self.where(search_params)
      if results.size > 0
        logger.error "Multiple objects found with search_params #{search_params}" if results.size > 1
        results.first
      else
        self.create(search_params)
      end
    end

  end
end
