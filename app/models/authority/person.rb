module Authority
  class Person < Thing
    property :family_name, predicate: ::RDF::Vocab::SCHEMA.familyName, multiple: false do |index|
      index.as :stored_searchable
    end
    property :given_name, predicate: ::RDF::Vocab::SCHEMA.givenName, multiple: false do |index|
      index.as :stored_searchable
    end
    property :birth_date, predicate: ::RDF::Vocab::SCHEMA.birthDate, multiple: false
    property :death_date, predicate: ::RDF::Vocab::SCHEMA.deathDate, multiple: false
    property :birth_place, predicate: ::RDF::Vocab::SCHEMA.birthPlace, multiple: false
    property :death_place, predicate: ::RDF::Vocab::SCHEMA.deathPlace, multiple: false
    property :nationality, predicate: ::RDF::Vocab::SCHEMA.nationality, multiple: false

    has_many :relators, predicate: ::RDF::Vocab::Bibframe.relatedTo

    def display_value
      value = (full_name.present?) ? full_name : ''
      value += ', ' if birth_date.present? || death_date.present?
      value += self.display_date if self.display_date.present?
      value
    end

    def display_date
      self.date_range(start_date: birth_date, end_date: death_date)
    end

    def full_name
      if family_name.present?
        full = "#{family_name}"
        full += ", #{given_name}" if given_name.present?
      else
        full = _name
      end
      full
    end

    # Method wrapper for backwards compatibility - do not use this in new code!
    def authorized_personal_name=(name_hash)
      logger.warn 'VALHAL DEPRECATION: authorized_personal_name= is deprecated - use the native accessors instead'
      self.family_name = name_hash['family'] if name_hash['family'].present?
      self.given_name = name_hash['given'] if name_hash['family'].present?
    end

    # As above - backwards compatibility
    def authorized_personal_names
      logger.warn 'VALHAL DEPRECATION: authorized_personal_name= is deprecated - use the native accessors instead'
      { kb: { family: self.family_name, given: self.given_name } }
    end

    # This code cause a "stack level too deep" failure,
    # TODO: investigate and fix
    # def authored_works
    #   related_works('aut')
    # end
    #
    # def related_works(code)
    #   recip_rels = self.relators.to_a.select { |rel| rel.short_role == code }
    #   recip_rels.collect(&:work)
    # end

    #static methods
    def self.find_or_create_person(forename,surname)
      person = Authority::Person.where(:given_name => forename, :family_name => surname).first
      if person.nil?
        person = Authority::Person.create(:given_name => forename, :family_name => surname )
      end
      person
    end

  end
end
