# Pdfs sent to printers
class Trykforlaeg < Instance
  validates :published_date, presence: true
  validates_each :copyright_date, :published_date do |record, attr, val|
    record.errors.add(attr, 'must be valid EDTF.') if val.present? && EDTF.parse(val).nil?
  end
  validates :isbn13, presence: true, isbn_format: { with: :isbn13 }
end
