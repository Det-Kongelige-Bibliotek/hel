module Authority
  class Organization < Thing
    property :founding_date, predicate: ::RDF::Vocab::SCHEMA.foundingDate
    property :dissolution_date, predicate: ::RDF::Vocab::SCHEMA.dissolutionDate
    property :location, predicate: ::RDF::Vocab::SCHEMA.location 

  end
end

