# Responsible for keeping the teiHeader in sync with the hydra chronos metadata
require 'open3'

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
  
  def executor(cmd)
    msg = ""
    success = false
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        msg += line
      end
      msg += stderr.read
      exit_status = wait_thr.value
      success = exit_status.success?
    end
    success
  end

end
