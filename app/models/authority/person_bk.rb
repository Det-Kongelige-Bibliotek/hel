module Authority
  # Model person authority records
  class Person < Authority::Agent
    # Authority::Person can be initialized
    # in several ways
    # 1) without any arguments
    # e.g. Authority::Person.new
    # 2) with a hash of name elements
    # e.g. Authority::Person.new(authorized_personal_name: { full: 'James Joyce', scheme: 'KB' })
    # 3) with an array of name element hashes
    # e.g. Authority::Person.new(
    #       authorized_personal_name: { full: "Flann O'Brien", scheme: 'viaf' },
    #       authorized_personal_name: { given: 'Myles', family: 'Na Gopaleen', scheme: 'nli' }
    #     )

    validate :has_a_name
    # Temporarily removed :dates_are_valid until we deside what to do with non EDTF-date from Aleph

    def has_a_name
      if self.authorized_personal_names.blank?
        errors.add('[authorized_personal_name][][family]','Der skal angives mindst et navn')
      end
    end

    def dates_are_valid
      self.authorized_personal_names.values.each do |name_hash|
        unless (name_hash[:date].blank?)
          errors.add('[authorized_personal_name][][date]','Der skal angives gyldige EDTF datoer') if Date.edtf(name_hash[:date]).nil?
        end
      end
    end

    def initialize(*args)
      super
      return if args.empty? || args.first.nil?
    end

    # All authorized personal names
    # organised by their scheme
    def authorized_personal_names
      self.mads.authorized_personal_names
    end

    def authorized_personal_name
      self.mads.authorized_personal_names
    end


    def authorized_personal_name=(args)
      mads.remove_authorized_personal_names
      if args.is_a? Array
        args.each { |h| add_authorized_personal_name(h) }
      elsif args.is_a? Hash
        add_authorized_personal_name(args)
      end
    end

    def add_authorized_personal_name(name_hash)
      logger.debug("add_authorized_personal_name(#{name_hash})")
      begin
        mads.ensure_valid_name_hash!(name_hash)
        mads.add_authorized_personal_name(name_hash)
        # if we have a blank hash just skip it
      rescue Exception=>ex
        logger.error("add_authorized_personal_name failed #{ex}")
        return
      end
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

    #static methods
    def self.find_or_create_person(forename,surname)
      result = ActiveFedora::SolrService.query('person_name_tesim:"'+surname+', '+forename+'"')
      if (result.size > 0)
        Authority::Person.find(result[0]['id'])
      else
        Authority::Person.create(authorized_personal_name: { 'given' => forename, 'family' => surname})
      end
    end

    def self.get_typeahead_objs
      ActiveFedora::SolrService.query("typeahead_tesim:* && has_model_ssim:*Authority_Person",
                                      {:rows => ActiveFedora::SolrService.count("typeahead_tesim:* && has_model_ssim:*Authority_Person")})
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
        name += name_hash[:family] if name_hash[:family]
        name += ', ' if name_hash[:given] && name_hash[:family]
        name += name_hash[:given] if name_hash[:given]
      end
      name.strip
    end
  end
end
