require 'spec_helper'

describe Administration::ExternalRepository do

  it_behaves_like 'ActiveModel'

  it 'should have a name' do
    repo = Administration::ExternalRepository.new
    repo.name = 'A External Repository'
    expect(repo.name).to eql 'A External Repository'
  end

  it 'should have a url' do
    repo = Administration::ExternalRepository.new
    repo.url = 'https://test.repo.org/test.git'
    expect(repo.url).to eql 'https://test.repo.org/test.git'
  end

  it 'should have a branch' do
    repo = Administration::ExternalRepository.new
    repo.branch = 'test'
    expect(repo.url).to eql 'test'
  end

  it 'should have an activity' do
    repo = Administration::ExternalRepository.new
    repo.activity = 'activity:1'
    expect(repo.activity).to eql  'activity:1'
  end

  it 'should have an sync_method' do
    repo = Administration::ExternalRepository.new
    repo.sync_method = 'Test'
    expect(repo.sync_method).to eql 'Test'
  end

  it 'should have a sync_status' do
    repo = Administration::ExternalRepository.new
    repo.sync_status = 'SUCCESS'
    expect(repo.sync_status).to eql 'SUCCESS'
  end

  it 'should have a sync_date' do
    repo = Administration::ExternalRepository.new
    now = DateTime.now.to_s
    repo.sync_date = now
    expect(repo.sync_date).to eql now
  end

  it 'should be able to add and clear sync messages' do
    Administration::ExternalRepository.delete_all
    Administration::SyncMessage.delete_all
    repo = Administration::ExternalRepository.new
    repo.name='test'
    repo.save
    expect {
      repo.add_sync_message('bla bla bla')
      repo.save
    }.to change{repo.sync_message.size}.by(1)

    repo.clear_sync_messages
    repo.save
    expect(repo.sync_message.size).to eql 0
  end

end

