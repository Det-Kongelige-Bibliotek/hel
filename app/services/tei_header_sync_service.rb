require 'open3'
require 'resque'

# Responsible for keeping the teiHeader in sync with the hydra chronos metadata
class TeiHeaderSyncService
  @queue = 'sync_ext_repo'

  def self.perform(sheet,tei_file,inst)

    puts inst.pid
    puts inst.publisher_name
    work = inst.work.first
    puts work.title_values.first
#      puts work.subtitle
    author = work.authors.first
    alist  = author.authorized_personal_names.values
    puts alist.first[:family]
    puts alist.first[:given]
    #before :all do 
    # @inst = Inst.create
    # @work     = Work.create
    #end

    params = ['first' => alist.first[:given],
              'last'  => alist.first[:family] ]
    xslt = Nokogiri::XSLT(File.read(sheet))
    doc = Nokogiri::XML.parse(File.read(tei_file)) { |config| config.strict }
    rdoc = xslt.transform(doc,Nokogiri::XSLT.quote_params(params))
    File.open(tei_file, 'w') { |f| f.print(rdoc.to_xml) }
  end
  
end
