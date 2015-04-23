class Title < ActiveFedora::Base
  belongs_to :work, predicate: ::RDF::Vocab::Bibframe.relatedTo
  property :value, predicate: ::RDF::Vocab::Bibframe.titleValue, multiple: false
  property :variant, predicate: ::RDF::Vocab::Bibframe.titleType, multiple: false
  property :subtitle, predicate: ::RDF::Vocab::Bibframe.subtitle, multiple: false
end