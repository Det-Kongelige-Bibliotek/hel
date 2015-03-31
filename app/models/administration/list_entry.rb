module Administration
  # The individual entries in a ControlledList
  class ListEntry < OhmModelWrapper
    attribute :name
    attribute :label
    index :name
    reference :controlled_list, Administration::ControlledList
  end
end