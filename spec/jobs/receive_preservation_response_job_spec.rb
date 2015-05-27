require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Receive preservation response messages' do
  include_context 'shared'
  describe 'on an Instance' do

    before :each do
      w = Work.create(work_params)
      p = Authority::Person.create({ 'same_as' => 'http://viaf.org/viaf/44300643',
                                     'family_name' => 'Joyce',
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
      # The message to send.
      @m = {'id' => @i.id, 'model' => @i.class.name, 'preservation' => {'preservation_state' => PRESERVATION_PACKAGE_COMPLETE.keys.first}}
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

      it 'receiving response message' do
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

        puts "sending #{@m.to_json} on #{destination}"
        ReceivePreservationResponseJob.perform(false)
        sleep 1.seconds
        @i.reload
        @i.preservation_state.should eql PRESERVATION_PACKAGE_COMPLETE.keys.first
      end
    end
  end

end

