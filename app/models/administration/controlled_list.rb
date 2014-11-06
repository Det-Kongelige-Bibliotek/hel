module Administration
  # Model for containing sets of controlled vocabulary terms
  # for example Relator codes etc.
  class ControlledList < OhmModelWrapper
    attribute :name
    unique :name
    collection :elements, Administration::ListEntry

    def elements=(elements)
      self.save unless self.persisted?
      elements.each do |new|
        hash = params_to_hash(new)
        if hash.key?(:id) && hash[:id].present?
          entry = Administration::ListEntry[hash[:id]]
          hash.merge!(controlled_list_id: self.id)
          entry.update(hash)
        elsif hash.key?(:name) && hash[:name].present?
          entry = Administration::ListEntry.new(name: hash[:name], controlled_list_id: self.id)
        end
        entry.save if defined?(entry) and entry
      end
      save
    end
# convert a hash with string keys
# to one with symbol keys
    def params_to_hash(params)
      symboled = {}
      params.each{ |k,v| symboled[k.to_sym] = v }
      symboled
    end
  end
end