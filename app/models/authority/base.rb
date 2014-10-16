module Authority
  # Base class - contains logic common to all
  # Authority subclasses.
  class Base < ActiveFedora::Base
    has_metadata 'mads', type: Datastreams::MADS::Document
    has_attributes :identifiers, datastream: 'mads', multiple: true
    has_attributes :uuid, datastream: 'mads', multiple: false

    # Get all descendant objects
    # @return Array
    def self.descendants
      ObjectSpace.each_object(singleton_class).map(&:all).flatten
    end
  end
end
