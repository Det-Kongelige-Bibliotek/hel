module Authority
  # To be subclassed by Person, Organisation, etc.
  class Thing < ActiveFedora::Base

    property :same_as, predicate: ::RDF::Vocab::SCHEMA.sameAs, multiple: false
    property :description, predicate: ::RDF::Vocab::SCHEMA.description, multiple: false
    property :image, predicate: ::RDF::Vocab::SCHEMA.image
    property :name, predicate: ::RDF::Vocab::SCHEMA.name, multiple: false
    property :alternate_names, predicate: ::RDF::Vocab::SCHEMA.alternateName, multiple: true

    def same_as_uri=(uri)
      self.same_as = ::RDF::URI.new(uri)
    end

    def same_as_uri
      self.same_as.to_term.value unless self.same_as.nil?
    end

    def display_value
      value = ''
      value += name if name.present?
      value += ", " if alternate_names.present?
      value += alternate_names.join(", ") if alternate_names.present?
      value
    end

    def to_solr(solr_doc = {})
      solr_doc = super
      Solrizer.insert_field(solr_doc, 'display_value', display_value, :displayable)
      Solrizer.insert_field(solr_doc, 'typeahead', display_value, :stored_searchable)
      solr_doc
    end

    

  end
end
