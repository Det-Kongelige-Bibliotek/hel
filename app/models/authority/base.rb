module Authority
  # Base class - contains logic common to all
  # Authority subclasses.
  class Base < ActiveFedora::Base
    has_metadata 'mads', type: Datastreams::MADS::Document
    has_attributes :identifiers, datastream: 'mads', multiple: true
    has_attributes :uuid, datastream: 'mads', multiple: false
  end
end
