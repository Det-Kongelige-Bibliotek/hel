require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Receive preservation response messages' do
  include_context 'shared'
  describe 'on an Instance' do

    before :each do
      w = Work.create(work_params)
      p = Authority::Person.create({ 'family_name' => 'Joyce',
                                     'given_name' => 'James',
                                     'birth_date' => '1932',
                                     'death_date' => '2009' })
      w.add_author(p)
      w.save!
      @i = Instance.create(valid_trykforlaeg)
      @i.set_work = w
      @i.preservation_profile = 'eternity'
      @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @i.save!
      @i.reload
      # The preservation message to send.
      @m = {'id' => @i.id, 'model' => @i.class.name, 'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_COMPLETE.keys.first}}
      # The update preservation message to send.
      @u = {'id' => @i.id, 'model' => @i.class.name, 'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_COMPLETE.keys.first}, 'update' => {'uuid' => 'random_uuid', 'warc_id' => 'random-warc-id'}}
      # The options for the message.
      @o = {'content_type' => 'application/json', 'type' => 'PreservationResponse'}

      @i.preservation_profile = 'eternity'
      @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @i.save
    end

    describe 'perform' do

      after :each do
        @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      end

      it 'should receiving and handle preservation response message' do
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

        #puts "sending #{@m.to_json} on #{destination}"
        ReceivePreservationResponseJob.perform(false)
        sleep 1.seconds
        @i.reload
        expect(@i.preservation_state).to eq PRESERVATION_PACKAGE_COMPLETE.keys.first
      end

      it 'should receiving and handle preservation response message for updated preservation' do
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@u.to_json, destination, @o)

        #puts "sending #{@u.to_json} on #{destination}"
        ReceivePreservationResponseJob.perform(false)
        sleep 1.seconds
        @i.reload
        expect(@i.preservation_state).to eq PRESERVATION_PACKAGE_COMPLETE.keys.first
        expect(@i.preservationMetadata.get_updates.size).to eq 1
        expect(@i.preservationMetadata.get_updates.first['uuid']).to eq 'random_uuid'
        expect(@i.preservationMetadata.get_updates.first['warc_id']).to eq 'random-warc-id'
      end

    end
  end
end

