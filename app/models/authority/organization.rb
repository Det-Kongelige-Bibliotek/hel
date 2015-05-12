module Authority
  class Organization < Thing
    property :founding_date, predicate: ::RDF::Vocab::SCHEMA.foundingDate, multiple: false
    property :dissolution_date, predicate: ::RDF::Vocab::SCHEMA.dissolutionDate, multiple: false
    property :location, predicate: ::RDF::Vocab::SCHEMA.location 


    
    def display_date
      date = self.date_range(:start_date => founding_date,
                             :end_date   => dissolution_date )
      date
    end

  end
end

