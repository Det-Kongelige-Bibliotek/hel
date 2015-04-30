module Authority
  class Person < Thing
    property :family_name, predicate: ::RDF::Vocab::SCHEMA.familyName, multiple: false
    property :given_name, predicate: ::RDF::Vocab::SCHEMA.givenName, multiple: false
    property :full_name, predicate: ::RDF::Vocab::SCHEMA.name, multiple: false
    property :birth_date, predicate: ::RDF::Vocab::SCHEMA.birthDate, multiple: false
    property :death_date, predicate: ::RDF::Vocab::SCHEMA.deathDate, multiple: false
    property :birth_place, predicate: ::RDF::Vocab::SCHEMA.birthPlace, multiple: false
    property :death_place, predicate: ::RDF::Vocab::SCHEMA.deathPlace, multiple: false
    property :nationality, predicate: ::RDF::Vocab::SCHEMA.nationality, multiple: false

    def display_value
      value = ''
      value += "#{family_name}, " if family_name.present?
      value += "#{given_name}, " if given_name.present?
      value += "#{birth_date}-" if birth_date.present?
      value += "#{death_date}" if death_date.present?
      value
    end
  end
end
