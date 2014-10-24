module Authority
  # Model person authority records
  class Person < Authority::Agent
    # All authorized personal names
    # organised by their scheme
    def authorized_personal_names
      mads.authorized_personal_names
    end

    def add_authorized_personal_name(name_hash)
      mads.add_authorized_personal_name(name_hash)
    end

    # Build a display value from the name and date
    # elements presemt. If none present, return id.
    def display_value
      name_hash = authorized_personal_names.values.first
      return super unless name_hash && name_hash.size > 0
      name_and_date(name_hash)
    end

    # return an array of name strings
    def all_names
      name_hashes = authorized_personal_names.values
      name_hashes.map { |h| structured_name(h) }
    end

    def to_solr(solr_doc = {})
      super
      all_names.each do |name|
        Solrizer.insert_field(solr_doc, 'person_name', name, :stored_searchable)
      end
      solr_doc
    end

    private

    # build a name and date string from the available elements
    def name_and_date(name_hash)
      name_and_date = structured_name(name_hash)
      name_and_date += ", #{name_hash[:date]}" if name_hash[:date]
      name_and_date
    end

    # Given a hash with name elements,
    # construct the best possible name string
    # Take either the full name, or a combination
    # of given and family.
    def structured_name(name_hash)
      name = ''
      if name_hash[:full]
        name += name_hash[:full]
      else
        name += name_hash[:given] if name_hash[:given]
        name += ' '
        name += name_hash[:family] if name_hash[:family]
      end
      name.strip
    end
  end
end
