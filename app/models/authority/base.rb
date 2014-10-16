module Authority
  # Base class - contains logic common to all
  # Authority subclasses.
  class Base < ActiveFedora::Base
    has_metadata 'mads', type: Datastreams::MADS::Document
    has_attributes :identifiers, datastream: 'mads', multiple: true
    has_attributes :uuid, datastream: 'mads', multiple: false

    def display_value
      id
    end
    # Get all descendant objects
    # TODO: this could be made faster by using Solr instead
    # @return Array
    def self.descendants
      ObjectSpace.each_object(singleton_class).map(&:all).flatten
    end
  end
end
