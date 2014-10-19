# Pdfs sent to printers
class Trykforlaeg < Instance
  validates :isbn13, presence: true, isbn_format: { with: :isbn13 }
end
