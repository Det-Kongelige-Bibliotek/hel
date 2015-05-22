require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Send object to preservation' do
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
        expect(f.preservation_state).to eql PRESERVATION_REQUEST_SEND.keys.first
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

