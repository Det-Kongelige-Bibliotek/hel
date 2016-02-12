class Letter
  include ActiveModel::Model
  attr_accessor :id, :sender, :recipient, :place, :date

  def persisted?
    true
  end

  def self.from_json(data)
     json = JSON.parse(data)
     Letter.new(id: '1234567', sender: json["sender"], recipient: json["recipient"], place: json['place'], date: json['date'])
  end
end