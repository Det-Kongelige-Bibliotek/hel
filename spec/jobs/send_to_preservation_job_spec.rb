require 'spec_helper'
require 'fakeredis'
require 'resque'
require 'resque_spec'

describe 'Send object to preservation' do
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
      @i.preservation_collection = 'eternity'
      @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @i.save!
      @i.reload
    end

    before do
      ResqueSpec.reset!
    end

    describe 'perform' do
      it 'without cascading' do
        @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        @i.save!
        SendToPreservationJob.perform(@i.id,false)
        @i.reload
        expect(@i.preservation_state).to eql PRESERVATION_REQUEST_SEND.keys.first
      end

      it 'with cascading' do
        #pending 'Does not perform cascading, only adds new jobs to the queue for the cascading elements'
        f = ContentFile.new
        @i.content_files << f
        @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        f.save!
        @i.save!
        @i.reload
        SendToPreservationJob.perform(@i.id,true)
        @i.reload
        f.reload
        expect(@i.preservation_state).to eql PRESERVATION_REQUEST_SEND.keys.first
        expect(SendToPreservationJob).to have_queued(f.id)
      end

      it 'check preservation_initiated is being set' do
        @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        @i.save!
        expect(@i.preservation_initiated_date).to be_nil
        SendToPreservationJob.perform(@i.id,false)
        @i.reload
        expect(@i.preservation_state).to eql PRESERVATION_REQUEST_SEND.keys.first
        expect(@i.preservation_initiated_date).not_to be_nil
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
      expect{SendToPreservationJob.perform(a.id, false)}.to raise_error(ArgumentError)
    end
  end
end

