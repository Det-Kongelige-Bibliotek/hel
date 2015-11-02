require 'spec_helper'


describe MqListenerHelper do
  include_context 'shared'
  include MqListenerHelper

  it 'should not allow update with empty message' do
    message = {}
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

  it 'should not allow update when missing \'id\'' do
    warc_id = '12344321'
    file_warc_id = '9874563210'
    message = {'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
    expect(handle_preservation_response message).to be false
  end

  it 'should not allow update when missing \'model\'' do
    warc_id = '12344321'
    file_warc_id = '9874563210'
    message = {'id' => 'id', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
    expect(handle_preservation_response message).to be false
  end

  it 'should not allow update when missing \'preservation\' element' do
    message = {'id' => 'id', 'model' => 'contentfile'}
    expect(handle_preservation_response message).to be false
  end

  it 'should raise an error if \'model\' is not a valid object-type' do
    warc_id = '12344321'
    file_warc_id = '9874563210'
    message = {'id' => 'id', 'model' => 'this_is_not_a_valid_model', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
    expect{handle_preservation_response message}.to raise_error
  end

  it 'should raise an error if \'model\' is not a valid object-type' do
    warc_id = '12344321'
    file_warc_id = '9874563210'
    message = {'id' => 'id', 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
    expect{handle_preservation_response message}.to raise_error(ActiveFedora::ObjectNotFoundError)
  end

  describe '#Handle_preservation_response ' do
    describe 'for content file' do
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

        @f.preservation_collection = 'eternity'
        @f.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        #@f.warc_id = 'warc_id'
        @f.save
      end

      it 'should update with warc id only' do
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        warc_id = '12344321'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect(handle_preservation_response message).to be true
        @f.reload
        expect(@f.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
        expect(@f.warc_id).to eq warc_id
        expect(@f.file_warc_id).to be_nil
      end

      it 'should find and update the content file' do
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        file_warc_id = '9874563210'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect(handle_preservation_response message).to be true
        @f.reload
        expect(@f.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to eq file_warc_id
      end

      it 'should find and update the content file with both file_warc_id and warc_id' do
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        warc_id = '12344321'
        file_warc_id = '9874563210'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect(handle_preservation_response message).to be true
        @f.reload
        expect(@f.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
        expect(@f.warc_id).to eq warc_id
        expect(@f.file_warc_id).to eq file_warc_id
      end

      it 'should raise error, if preservation has not yet started' do
        @f.preservation_state = PRESERVATION_STATE_NOT_STARTED.keys.first
        @f.save!
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        warc_id = '12344321'
        file_warc_id = '9874563210'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'warc_id' => warc_id, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect{handle_preservation_response message}.to raise_error(ArgumentError)
      end

      it 'should update warc offsets' do
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        expect(@f.warc_offset).to be_nil
        expect(@f.file_warc_offset).to be_nil
        warc_id = '12344321'
        file_warc_id = '9874563210'
        offset = '1234#4321'
        file_offset = '12345#54321'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'file_warc_offset' => file_offset, 'warc_id' => warc_id, 'warc_offset' => offset, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect(handle_preservation_response message).to be true
        @f.reload
        expect(@f.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
        expect(@f.warc_id).to eq warc_id
        expect(@f.file_warc_id).to eq file_warc_id
        expect(@f.warc_offset).to eq offset
        expect(@f.file_warc_offset).to eq file_offset
      end

      it 'should not update warc offset, when no warc id is given' do
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        expect(@f.warc_offset).to be_nil
        expect(@f.file_warc_offset).to be_nil
        #warc_id = '12344321'
        file_warc_id = '9874563210'
        offset = '1234#4321'
        file_offset = '12345#54321'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'file_warc_id' => file_warc_id, 'file_warc_offset' => file_offset, 'warc_offset' => offset, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect(handle_preservation_response message).to be true
        @f.reload
        expect(@f.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to eq file_warc_id
        expect(@f.warc_offset).to be_nil
        expect(@f.file_warc_offset).to eq file_offset
      end

      it 'should not update file warc offset, when no file warc id is given' do
        expect(@f.warc_id).to be_nil
        expect(@f.file_warc_id).to be_nil
        expect(@f.warc_offset).to be_nil
        expect(@f.file_warc_offset).to be_nil
        warc_id = '12344321'
        #file_warc_id = '9874563210'
        offset = '1234#4321'
        file_offset = '12345#54321'
        message = {'id' => @f.id, 'model' => 'contentfile', 'preservation' => {'file_warc_offset' => file_offset, 'warc_id' => warc_id, 'warc_offset' => offset, 'preservation_state' => PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first}}
        expect(handle_preservation_response message).to be true
        @f.reload
        expect(@f.preservation_state).to eq PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA.keys.first
        expect(@f.warc_id).to eq warc_id
        expect(@f.file_warc_id).to be_nil
        expect(@f.warc_offset).to eq offset
        expect(@f.file_warc_offset).to be_nil
      end
    end
  end
end
