require 'spec_helper'

describe  TeiHeaderSyncService do

  before do
    source_file = "#{Rails.root}/spec/fixtures/holb06valid.xml"
    @tei_file   = "/tmp/adl-test/texts/holb06valid.xml"
    work_dir    = "/tmp/adl-test/texts"

    cmd         = 
      "rm -r #{work_dir};" +
      "mkdir -p #{work_dir};" + 
      "cp #{source_file} #{@tei_file}"

    xsl  = "#{Rails.root}/app/services/xslt/tei_header_sed.xsl"
    @sync_service = TeiHeaderSyncService.new(xsl)
    @sync_service.executor(cmd)
  end

  describe '#update_header' do
    it 'should be able to edit the header in a tei file' do
      file_syncer = SyncExtRepoADL.new
      #before :all do 
      # @instance = Instance.create
      # @work     = Work.create
      #end
      result = @sync_service.update_header(@tei_file,[])
#      puts result
    end
  end
end
