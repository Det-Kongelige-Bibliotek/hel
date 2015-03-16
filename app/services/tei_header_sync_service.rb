# Responsible for keeping the teiHeader in sync with the hydra chronos metadata
class TeiHeaderSyncService
  attr_accessor :sheet

  def initialize(sheet)
    puts "initialize called"
    puts sheet
    @xslt = Nokogiri::XSLT(File.read(sheet))
  end

  def update_header(teifile,params)
    doc = Nokogiri::XML.parse(File.read(teifile)) { |config| config.strict }
    @xslt.transform(doc,Nokogiri::XSLT.quote_params(params))
  end

end
