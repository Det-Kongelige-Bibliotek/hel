module Administration
  class Activity < ActiveFedora::Base

    include Hydra::AccessControls::Permissions
    include Concerns::AdminMetadata
    include Concerns::Preservation

    validates :activity, presence: true

  end
end
