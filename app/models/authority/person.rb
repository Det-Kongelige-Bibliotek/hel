module Authority
  # Model person authority records
  class Person < Authority::Agent
    def authorized_personal_names
      mads.authorized_personal_names
    end

    def add_authorized_personal_name(name_hash)
      mads.add_authorized_personal_name(name_hash)
    end

    # Build a display value from the name and date
    # elements presemt. If none present, return id.
    def display_value
      scheme, name_hash = authorized_personal_names.first
      return super unless scheme.present? && name_hash.size > 0
      "#{scheme.upcase}: #{name_and_date(name_hash)}"
    end

    private

    # build a name and date string from the available elements
    def name_and_date(name_hash)
      name_and_date = ''
      if name_hash[:full]
        name_and_date += name_hash[:full]
      else
        name_and_date += name_hash[:given] if name_hash[:given]
        name_and_date += name_hash[:family] if name_hash[:family]
      end
      name_and_date += ", #{name_hash[:date]}" if name_hash[:date]
      name_and_date
    end
  end
end
