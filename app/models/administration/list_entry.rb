module Administration
  # The individual entries in a ControlledList
  class ListEntry < OhmModelWrapper
    attribute :name
    attribute :label
    index :name
    reference :controlled_list, Administration::ControlledList

    # Given the name of an entry - find it and get the corresponding label
    # e.g. Administration::ListEntry.get_label('http://id.loc.gov/vocabulary/relators/abr') => 'Abridger'
    def self.get_label(name)
      self.where(name: name).first.label rescue nil
    end
  end
end