module Authority
  # To be subclassed by Person, Organisation, etc.
  class Agent < Authority::Base
    has_many :created_works, class_name: 'Work', property: :creator, inverse_of: :creator_of
    has_many :authored_works, class_name: 'Work', property: :author, inverse_of: :author_of
    has_many :received_works, class_name: 'Work', property: :recipient, inverse_of: :recipient_of
  end
end
