module Authority
  class Organization < Thing
    property :founding_date, predicate: ::RDF::Vocab::SCHEMA.foundingDate, multiple: false
    property :dissolution_date, predicate: ::RDF::Vocab::SCHEMA.dissolutionDate, multiple: false
    property :location, predicate: ::RDF::Vocab::SCHEMA.location 

  end
end

