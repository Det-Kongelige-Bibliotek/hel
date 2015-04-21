class Person < ActiveFedora::Base
  property :family_name, predicate: ::RDF::Vocab::SCHEMA.familyName, multiple: false
  property :given_name, predicate: ::RDF::Vocab::SCHEMA.givenName, multiple: false
  property :full_name, predicate: ::RDF::Vocab::SCHEMA.name, multiple: false
  property :birth_date, predicate: ::RDF::Vocab::SCHEMA.birthDate, multiple: false
  property :death_date, predicate: ::RDF::Vocab::SCHEMA.deathDate, multiple: false
  property :birth_place, predicate: ::RDF::Vocab::SCHEMA.birthPlace, multiple: false
  property :death_place, predicate: ::RDF::Vocab::SCHEMA.deathPlace, multiple: false
  property :same_as, predicate: ::RDF::Vocab::SCHEMA.sameAs, multiple: false
  property :nationality, predicate: ::RDF::Vocab::SCHEMA.nationality, multiple: false
  property :alternate_names, predicate: ::RDF::Vocab::SCHEMA.alternateName, multiple: true
  property :description, predicate: ::RDF::Vocab::SCHEMA.description, multiple: true
end