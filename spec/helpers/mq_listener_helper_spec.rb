require 'spec_helper'


describe MqListenerHelper do
  include MqListenerHelper

  it 'should not allow update with empty message' do
    message = {}
    expect(handle_preservation_response message).to be false
  end

  it 'should not allow update with nil message' do
    message = nil
    expect(handle_preservation_response message).to be false
  end

  it 'should not allow update without \'model\' in message' do
    message = {'id' => 'id', 'preservation' => {}}
    expect(handle_preservation_response message).to be false
  end

  it 'should not allow update without \'preservation\' in message' do
    message = {'id' => 'id', 'model' => 'model'}
    expect(handle_preservation_response message).to be false
  end

  it 'should not allow update without \'id\' in message' do
    message = {'model' => 'model', 'preservation' => {}}
    expect(handle_preservation_response message).to be false
  end

  it 'should raise error when illegal \'model\' in message' do
    message = {'id' => 'id', 'model' => 'model', 'preservation' => {}}
    expect{handle_preservation_response message}.to raise_error(RuntimeError)
  end

  it 'should raise error when \'id\' does not match anything' do
    message = {'id' => 'id', 'model' => 'ContentFile', 'preservation' => {}}
    expect{handle_preservation_response message}.to raise_error(ActiveFedora::ObjectNotFoundError)
  end

  it 'should raise error when \'id\' and \'model\' does not match' do
    cf = ContentFile.new
    cf.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
    cf.save!
    message = {'id' => cf.id, 'model' => 'Instance', 'preservation' => {}}
    expect{handle_preservation_response message}.to raise_error(ActiveFedora::ActiveFedoraError)
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
      message = {'id' => @cf.id, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
      expect(handle_preservation_response message).to be true
      @cf.reload
      expect(@cf.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
      expect(@cf.warc_id).to eq warc_id
      expect(@cf.file_warc_id).to eq file_warc_id
    end
  end
end
