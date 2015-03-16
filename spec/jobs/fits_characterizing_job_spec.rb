require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Characterizing content files with FITS' do
  before :each do
    @f = ContentFile.create
    @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
    @f.save
  end

  it 'should perform the fits characterization' do
    @f.fitsMetadata.content.should be_nil
    FitsCharacterizingJob.perform(@f.pid)
    @f.reload
    @f.fitsMetadata.content.should_not be_nil
  end
end

