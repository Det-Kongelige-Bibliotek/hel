require 'spec_helper'


describe MqListenerHelper do

  it 'should not allow update with invalid message' do
    message = {}
    expect(handle_preservation_response message).to be false
  end

  describe 'for content file' do
    before :all do
      @cf = ContentFile.create
    end

    it 'should find and update the content file' do
      @cf.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @cf.save!
      expect(@cf.warc_id).to be_nil
      expect(@cf.file_warc_id).to be_nil
      warc_id = '12344321'
      file_warc_id = '9874563210'
      message = {'id' => @cf.pid, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
      expect(handle_preservation_response message).to be true
      @cf.reload
      expect(@cf.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
      expect(@cf.warc_id).to eq warc_id
      expect(@cf.file_warc_id).to eq file_warc_id
    end
  end
end
