module Authority
  class Organization < Thing
    property :founding_date, predicate: ::RDF::Vocab::SCHEMA.foundingDate, multiple: false
    property :dissolution_date, predicate: ::RDF::Vocab::SCHEMA.dissolutionDate, multiple: false
    property :location, predicate: ::RDF::Vocab::SCHEMA.location

    before_save :set_rights_metadata

    def set_rights_metadata
      self.discover_groups = ['Chronos-Alle']
      self.read_groups = ['Chronos-Alle']
      self.edit_groups = ['Chronos-Alle']
    end

    def display_date
      self.date_range(start_date: founding_date, end_date: dissolution_date )
    end

    #static methods
    def self.find_or_create_organization(name,location)
      org = Authority::Organization.where(:_name => name).first
      if org.nil?
        org = Authority::Organization.create(:_name => name, :location => [location])
      end
      org
    end
  end
end

