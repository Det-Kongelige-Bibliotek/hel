# This class represents a Work model in
# Fedora. Only KB specific logic should
# live in this class. All domain logic
# e.g. Bibframe, Hydra::Rights etc,
# should live in separate modules and
# be mixed in.
class Work < ActiveFedora::Base
  include Bibframe::Work
  include Concerns::UUIDGenerator
  has_many :instances, property: :instance_of
end
