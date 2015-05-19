require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Send object to preservation' do
  include_context 'shared'
  describe 'on an Instance' do
    before :each do
#      a = Administration::Activity.create("activity"=>"Something")
#      valid_attributes = { activity: a.id, copyright: 'Some Copyright',  collection: 'Some Collection'}
      w = Work.create(work_params)
      p = Authority::Person.create(
                               { 'same_as' => 'http://viaf.org/viaf/44300643', 'family_name' => 'Joyce', 'given_name' => 'James', 'birth_date' => '1932', 'death_date' => '2009' })
      w.add_author(p)
#      w.add_title(value: 'Vice Squad!')
      w.save!
      puts "title = " + w.display_value
#      @i = Instance.create(instance_params)
      @i = Instance.create(valid_trykforlaeg)
      @i.set_work = w
#       @i.save!
#    end

#    before :each do
      @i.preservation_profile = 'eternity'
      @i.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
      @i.save!
      @i.reload
      puts "just checking " + @i.work.display_value
      puts "titles #{@i.work.titles.inspect}"
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
        pending
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

