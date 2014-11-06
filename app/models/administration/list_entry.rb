module Administration
  # The individual entries in a ControlledList
  class ListEntry < OhmModelWrapper
    attribute :name
    reference :controlled_list, Administration::ControlledList
  end
end