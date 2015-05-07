module Authority
class Place < Thing
  property :address, predicate: ::RDF::Vocab::SCHEMA.address, multiple: false
  property :geo, predicate: ::RDF::Vocab::SCHEMA.geo, multiple: false

end
end