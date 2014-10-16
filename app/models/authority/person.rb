module Authority
  # Model person authority records
  class Person < Authority::Agent
    def authorized_personal_names
      mads.authorized_personal_names
    end

    def add_authorized_personal_name(name_hash)
      mads.add_authorized_personal_name(name_hash)
    end
  end
end
