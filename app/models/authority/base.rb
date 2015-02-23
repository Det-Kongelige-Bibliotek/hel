module Authority
  # Base class - contains logic common to all
  # Authority subclasses.
  class Base < ActiveFedora::Base
    include Concerns::Inheritance
    include Hydra::AccessControls::Permissions

    has_and_belongs_to_many :subject_of, class_name: 'Work', property: :subject_of, inverse_of: :subject

    has_metadata 'mads', type: Datastreams::MADS::Document
    has_attributes :identifiers, datastream: 'mads', multiple: true
    has_attributes :uuid, datastream: 'mads', multiple: false

    before_save :set_rights_metadata

    def display_value
      id
    end
    # Get all descendant objects
    # TODO: look at improving performance
    # @return Array
    def self.descendants
      objs = ActiveFedora::SolrService.query('has_model_ssim: *Authority_Base')
      objs.map { |e| ActiveFedora::Base.find(e['id']) }
    end

    def to_solr(solr_doc = {})
      super
      Solrizer.insert_field(solr_doc, 'display_value', display_value, :displayable)
      Solrizer.insert_field(solr_doc, 'typeahead', display_value, :stored_searchable)
      solr_doc
    end

    # method to set the rights metadata stream based on activity
    def set_rights_metadata
      self.edit_groups = ['Chronos-Pligtaflevering']
      self.read_groups = ['Chronos-Alle']
      self.discover_groups = ['Chronos-Alle']
    end
  end
end
