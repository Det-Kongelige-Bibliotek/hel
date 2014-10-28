module Authority
  # Base class - contains logic common to all
  # Authority subclasses.
  class Base < ActiveFedora::Base
    include Concerns::Inheritance
    include Hydra::AccessControls::Permissions

    has_metadata 'mads', type: Datastreams::MADS::Document
    has_attributes :identifiers, datastream: 'mads', multiple: true
    has_attributes :uuid, datastream: 'mads', multiple: false

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
      solr_doc
    end
  end
end
