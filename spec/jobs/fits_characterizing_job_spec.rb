require 'spec_helper'
require 'fakeredis'
require 'resque'


describe 'Characterizing content files with FITS' do
  describe 'of a content file' do
    before :each do
      @f = ContentFile.create
      @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'test_instance.xml')))
      @f.save
    end

    it 'should perform the fits characterization' do
      expect(@f.fitsMetadata.content).to be_nil
      FitsCharacterizingJob.perform(@f.pid)
      @f.reload
      expect(@f.fitsMetadata.content).not_to be_nil
    end

    it 'should identify it as an xml file' do
      FitsCharacterizingJob.perform(@f.pid)
      @f.reload
      expect(@f.fitsMetadata.content).to include('<identity format="Extensible Markup Language" mimetype="text/xml"')
    end

    it 'should identify the new format, if the content file is overriden' do
      FitsCharacterizingJob.perform(@f.pid)
      @f.reload
      expect(@f.fitsMetadata.content).to include('<identity format="Extensible Markup Language" mimetype="text/xml"')
      @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'rails.png')))
      @f.save
      FitsCharacterizingJob.perform(@f.pid)
      @f.reload
      expect(@f.fitsMetadata.content).to include('<identity format="Portable Network Graphics" mimetype="image/png"')
      expect(@f.format_pronom_id).to eq 'fmt/11'
    end
  end

  it 'should throw error, when given nil' do
    expect{FitsCharacterizingJob.perform(nil)}.to raise_error(ArgumentError)
  end

  it 'should throw error, when given an instance' do
    @i = Instance.create(activity: @default_activity_id, copyright: 'Some Copyright',  collection: 'Some Collection')
    expect{FitsCharacterizingJob.perform(@i.pid)}.to raise_error(ArgumentError)
  end
end

