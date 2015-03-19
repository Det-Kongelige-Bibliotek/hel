require 'open3'
require 'resque'

# Responsible for keeping the teiHeader in sync with the hydra chronos metadata
class TeiHeaderSyncService
  @queue = 'sync_ext_repo'

  def self.perform(sheet,tei_file,uri)
    params = ['uri' => uri]
    xslt = Nokogiri::XSLT(File.read(sheet))
    doc = Nokogiri::XML.parse(File.read(tei_file)) { |config| config.strict }
    rdoc = xslt.transform(doc,Nokogiri::XSLT.quote_params(params))
    File.open(tei_file, 'w') { |f| f.print(rdoc.to_xml) }
  end
  
end
