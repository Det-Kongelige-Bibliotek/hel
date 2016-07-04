module DisseminationProfiles
  class DanmarksBreve
    def self.platform
      'Danmarks Breve'
    end

    def self.disseminate(instance)
      Resque.logger.debug "Publishing letter book #{instance.id}"
    end

  end
end