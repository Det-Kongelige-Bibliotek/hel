module Administration
  class SyncMessage < OhmModelWrapper
    attribute :msg
    reference :repo, Administration::ExternalRepository
  end
end