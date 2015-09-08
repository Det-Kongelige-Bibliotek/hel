require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Receive responses messages from preservation' do
  include_context 'shared'
  describe 'Preservation responses on an Instance' do

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
      @o = {'content_type' => 'application/json', 'type' => MQ_MESSAGE_TYPE_PRESERVATION_RESPONSE}

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
        ReceiveResponsesFromPreservationJob.perform(false)
        sleep 1.seconds
        @i.reload
        expect(@i.preservation_state).to eq PRESERVATION_PACKAGE_COMPLETE.keys.first
      end

      it 'should receiving and handle preservation response message for updated preservation' do
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@u.to_json, destination, @o)

        #puts "sending #{@u.to_json} on #{destination}"
        ReceiveResponsesFromPreservationJob.perform(false)
        sleep 1.seconds
        @i.reload
        expect(@i.preservation_state).to eq PRESERVATION_PACKAGE_COMPLETE.keys.first
        expect(@i.preservationMetadata.get_updates.size).to eq 1
        expect(@i.preservationMetadata.get_updates.first['uuid']).to eq 'random_uuid'
        expect(@i.preservationMetadata.get_updates.first['warc_id']).to eq 'random-warc-id'
      end

    end
  end

  describe 'Preservaiton import response on a ContentFile' do
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
      @f = ContentFile.new
      @f.instance = @i
      # expect(@f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')), false)).to be_true
      @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
      @f.save!
      # The options for the message.
      @o = {'content_type' => 'application/json', 'type' => MQ_MESSAGE_TYPE_PRESERVATION_IMPORT_RESPONSE}

      @f.preservation_profile = 'eternity'
      @f.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @f.warc_id = 'warc_id'
      @f.save
    end

    describe 'perform' do
      it 'should receiving and handle preservation import response message with all response variables' do
        @m = {'uuid' => @f.id, 'type' => 'FILE', 'response' => {'state' => PRESERVATION_IMPORT_FINISHED.keys.first, 'details' => 'This is the details', 'date' => DateTime.now.to_s}}
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

        #puts "sending #{@m.to_json} on #{destination}"
        ReceiveResponsesFromPreservationJob.perform(false)
        sleep 1.seconds
        @f.reload
        expect(@f.import_state).to eq PRESERVATION_IMPORT_FINISHED.keys.first
        expect(@f.import_details).to eq @m['response']['detail']
        expect(@f.import_update_date).to eq @m['response']['date']
      end
      it 'should receiving and handle preservation import response message with only state' do
        @m = {'uuid' => @f.id, 'type' => 'FILE', 'response' => {'state' => PRESERVATION_IMPORT_FINISHED.keys.first, 'details' => nil, 'date' => nil}}
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

        ReceiveResponsesFromPreservationJob.perform(false)
        sleep 1.seconds
        @f.reload
        expect(@f.import_state).to eq PRESERVATION_IMPORT_FINISHED.keys.first
        expect(@f.import_details).to be_nil
        expect(@f.import_update_date).to be_nil
      end
      it 'should receiving and handle preservation import response message with only details' do
        @m = {'uuid' => @f.id, 'type' => 'FILE', 'response' => {'state' => nil, 'details' => 'Details', 'date' => nil}}
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

        ReceiveResponsesFromPreservationJob.perform(false)
        sleep 1.seconds
        @f.reload
        expect(@f.import_state).to_not eq PRESERVATION_IMPORT_FINISHED.keys.first
        expect(@f.import_details).to eq @m['response']['detail']
        expect(@f.import_update_date).to be_nil
      end
      it 'should receiving and handle preservation import response message with only date' do
        @m = {'uuid' => @f.id, 'type' => 'FILE', 'response' => {'state' => nil, 'details' => nil, 'date' => DateTime.now.to_s}}
        destination = MQ_CONFIG['preservation']['response']
        MqHelper.send_on_rabbitmq(@m.to_json, destination, @o)

        ReceiveResponsesFromPreservationJob.perform(false)
        sleep 1.seconds
        @f.reload
        expect(@f.import_state).to_not eq PRESERVATION_IMPORT_FINISHED.keys.first
        expect(@f.import_details).to be_nil
        expect(@f.import_update_date).to eq @m['response']['date']
      end
    end
  end
end

