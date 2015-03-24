require 'open3'
require 'resque'

# Responsible for keeping the teiHeader in sync with the hydra chronos metadata
class TeiHeaderSyncService
  @queue = 'sync_ext_repo'

  def self.perform(sheet,tei_file,inst)

    work = inst.work.first
    author = work.authors.first

    parameters = {}
    work.authors.each_with_index do |a,i|
      aut = a.authorized_personal_names.values.first
      parameters["first#{i}"] = aut[:given]
      parameters["last#{i}"]  = aut[:family]
    end

# This didn't work very well. Leave it here as a memo for the time being
#
#   myfuncs = Class.new do
#      def family
#        @alist.first[:family]
#        "mongrel"
#      end
#      def given
#        @alist.first[:given]
#      end
#    end
#    
#    Nokogiri::XSLT.register "http://example.com/functions", myfuncs
#

    work.title_values.each_with_index do |tit,i|
      parameters["title#{i}"]      = tit
    end

    parameters[:publisher] = inst.publisher_name
    parameters[:pub_place] = inst.published_place
    parameters[:date]      = inst.published_date

    xslt = Nokogiri::XSLT(File.read(sheet))
    doc = Nokogiri::XML.parse(File.read(tei_file)) { |config| config.strict }
    rdoc = xslt.transform(doc,Nokogiri::XSLT.quote_params(parameters))
    File.open(tei_file, 'w') { |f| f.print(rdoc.to_xml) }
  end
  
end
