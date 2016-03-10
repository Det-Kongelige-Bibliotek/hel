class Letter
  include ActiveModel::Model
  include ActiveModel::Validations
  attr_accessor :id, :work_id, :xml_id, :file, :sender, :recipient, :place, :date

  validate :validate_date

  def validate_date
    unless date.empty?
      if EDTF.parse(date).nil?
        errors.add(date, 'er ikke EDTF valid.')
      end
    end
  end

  def persisted?
    true
  end

  def self.from_json(data)
     json = JSON.parse(data)
     Letter.new(id: json["id"], xml_id: json['xml_id'], file: json['file'], sender: json["sender"], recipient: json["recipient"], place: json['place'], date: json['date'])
  end
end