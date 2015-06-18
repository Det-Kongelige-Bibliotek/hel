module DisseminationProfiles
  # A Dissemination profile is a class that is
  # responsible for publishing content to a public facing platform.
  # This may be a file server, Solr index etc
  # It must have one method disseminate. This takes an instance as its argument.
  class Adl
    def self.disseminate(instance)
      puts "disseminating #{instance.id}"
    end
  end
end
