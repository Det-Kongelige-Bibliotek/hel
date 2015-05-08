require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Send object to preservation' do

  describe 'on an Instance' do
    before :all do
      valid_attributes = { activity: @default_activity_id, copyright: 'Some Copyright',  collection: 'Some Collection'}
      @i = Instance.create(valid_attributes)
    end

    before :each do
      @i.preservation_profile = 'eternity'
      @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @i.save
    end

    describe 'perform' do
      it 'without cascading' do
        @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        @i.save!
        SendToPreservationJob.perform(@i.pid,false)
        @i.reload
        @i.preservation_state.should eql PRESERVATION_REQUEST_SEND.keys.first
      end

      it 'with cascading' do
        f = ContentFile.create
        @i.content_files << f
        @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        @i.save!
        @i.reload
        SendToPreservationJob.perform(@i.pid,true)
        @i.reload
        f.reload
        @i.preservation_state.should eql PRESERVATION_REQUEST_SEND.keys.first
        f.preservation_state.should eql PRESERVATION_REQUEST_SEND.keys.first
      end

    end
  end

  describe 'a non-existing object' do
    it 'should raise an error' do
      expect{SendToPreservationJob.perform(nil, false)}.to raise_error(ArgumentError)
    end
  end

  describe 'on a non-preservable object' do
    it 'should raise an error' do
      a = ActiveFedora::Base.create
      expect{SendToPreservationJob.perform(a.pid, false)}.to raise_error(ArgumentError)
    end
  end
end

