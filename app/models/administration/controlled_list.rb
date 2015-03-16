module Administration
  # Model for containing sets of controlled vocabulary terms
  # for example Relator codes etc.
  class ControlledList < OhmModelWrapper
    attribute :name
    unique :name
    collection :elements, Administration::ListEntry

    def elements=(elems)
      self.save unless self.persisted?
      elems.each do |new|
        entry = nil
        values = params_to_hash(new)
        if values.key?(:id) && values[:id].present?
          entry = Administration::ListEntry[values[:id]]
          values.merge!(controlled_list_id: self.id)
          entry.update(values)
        elsif values.key?(:name) && values[:name].present?
          entry = Administration::ListEntry.new(values.merge(controlled_list_id: self.id))
        end
        entry.save if entry.present?
      end
      save
    end

    # convert a hash with string keys
    # to one with symbol keys
    def params_to_hash(params)
      symboled = {}
      params.each{ |k,v| symboled[k.to_sym] = v if v.present? }
      symboled
    end
  end
end