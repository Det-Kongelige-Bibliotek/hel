require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Receive preservation response messages' do

  before :all do
    valid_attributes = { activity: @default_activity_id, copyright: 'Some Copyright',  collection: 'Some Collection'}
    # The instance to test upon
    @i = Instance.create(valid_attributes)
    # The message to send.
    @m = {'id' => @i.pid, 'model' => @i.class.name, 'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_COMPLETE.keys.first}}
    # The options for the message.
    @o = {'content_type' => 'application/json', 'type' => 'PreservationResponse'}
  end

  before :each do
    @i.preservation_profile = 'eternity'
    @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
    @i.save
  end

  describe 'perform' do

    after :each do
      @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
    end

    it 'receiving response message' do
      destination = MQ_CONFIG['preservation']['response']
      MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

      sleep 10.seconds
      ReceivePreservationResponseJob.perform
      @i.reload
      @i.preservation_state.should eql PRESERVATION_PACKAGE_COMPLETE.keys.first
    end
  end
end

