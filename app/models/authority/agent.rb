module Authority
  # To be subclassed by Person, Organisation, etc.
  class Agent < Authority::Base
    has_and_belongs_to_many :authored_works, class_name: 'Work', property: :author_of, inverse_of: :author
    has_and_belongs_to_many :received_works, class_name: 'Work', property: :recipient, inverse_of: :recipient_of

    #static methods
    def self.get_typeahead_objs
      ActiveFedora::SolrService.query("typeahead_tesim:* && has_model_ssim:*Authority_Agent",
                                      {:rows => ActiveFedora::SolrService.count("typeahead_tesim:* && has_model_ssim:*Authority_Agent")})
    end

  end
end
