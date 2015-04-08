# Responsible for converting between different standard formats
class ConversionService
  attr_accessor :marc
  def initialize(marc)
    @aleph_marc = marc
  end


  # Given an aleph marc file and a pdf link transform to standard marc and insert link
  # in relevant file
  def to_marc21(pdf_uri)
    doc = Nokogiri::XML.parse(@aleph_marc) { |config| config.strict }
    slim_xslt = Nokogiri::XSLT(File.read("#{Rails.root}/app/services/xslt/oaimarc2slimmarc.xsl"))
    slim_xslt.transform(doc, Nokogiri::XSLT.quote_params(['pdfUri', pdf_uri]))
  end

  # Given a standard marc xml file transform to mods using LOC stylesheet
  def to_mods(pdf_uri = '')
    marc2mods = Nokogiri::XSLT(File.read("#{Rails.root}/app/services/xslt/marcToMODS.xsl"))
    marc2mods.transform(self.to_marc21(pdf_uri))
  end

  # convenience method to allow immediate generation
  # of a work from an aleph search
  # E.g. ConversionService.work_from_aleph('isbn', '9788711396322')
  # will return a work with metadata based on the Aleph record
  # Empty searches return nil
  # Possible field values include isbn and sys (for system number)
  def self.work_from_aleph(aleph_field, aleph_value)
    service = AlephService.new
    rec = service.find_first(aleph_field, aleph_value)
    return nil unless rec.present?
    converter = ConversionService.new(rec)
    doc = converter.to_mods
    mods = Datastreams::Mods.from_xml(doc)
    work = Work.new
    work.from_mods(mods)
    work
  end
end
