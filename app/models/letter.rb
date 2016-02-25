class Letter
  include ActiveModel::Model
  attr_accessor :id, :work_id, :xml_id, :file, :sender, :recipient, :place, :date

  def persisted?
    true
  end

  def self.from_json(data)
     json = JSON.parse(data)
     Letter.new(id: json["id"], xml_id: json['xml_id'], file: json['file'], sender: json["sender"], recipient: json["recipient"], place: json['place'], date: json['date'])
  end
end