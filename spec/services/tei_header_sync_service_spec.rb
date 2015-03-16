require 'spec_helper'

describe  TeiHeaderSyncService do

  before do
    @tei_file = "#{Rails.root}/spec/fixtures/holb06valid.xml"
    xsl  = "#{Rails.root}/app/services/xslt/tei_header_sed.xsl"
    @sync_service = TeiHeaderSyncService.new(xsl)
  end

  describe '#update_header' do
    it 'should be able to edit the header in a tei file' do
      #before :all do 
      # @instance = Instance.create
      # @work     = Work.create
      #end
      result = @sync_service.update_header(@tei_file,[])
      puts result
    end
  end
end
