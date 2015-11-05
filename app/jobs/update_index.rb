class UpdateIndex

  @queue = :update_index

  def self.perform
    ActiveFedora::Base.all.each do |obj|
      obj.update_index
    end
  end

end