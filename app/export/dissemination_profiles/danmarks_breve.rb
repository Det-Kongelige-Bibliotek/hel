module DisseminationProfiles
  class DanmarksBreve
    def self.platform
      'DanmarksBreve'
    end

    def self.disseminate(instance)
      Resque.logger.debug "Publishing letter book #{instance.id}"
    end

  end
end