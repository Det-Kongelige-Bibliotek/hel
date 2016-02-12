require 'spec_helper'
require 'fakeredis'
require 'resque'

describe 'Characterizing content files with FITS' do
  include_context 'shared'
  describe 'of a content file' do
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
    end

    it 'should perform the fits characterization' do
      expect(@f.fileContent.content).not_to be_nil
      expect(@f.fitsMetadata.content).to be_nil
      FitsCharacterizingJob.perform(@f.id)
      @f.reload
      expect(@f.fitsMetadata.content).not_to be_nil
    end

    it 'should identify it as an xml file' do
      FitsCharacterizingJob.perform(@f.id)
      @f.reload
      expect(@f.fitsMetadata.content).to include('<identity format="Extensible Markup Language" mimetype="text/xml"')
    end

    it 'should identify the new format, if the content file is overriden' do
      FitsCharacterizingJob.perform(@f.id)
      @f.reload
      expect(@f.fitsMetadata.content).to include('<identity format="Extensible Markup Language" mimetype="text/xml"')
      @f.add_file(File.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'rails.png')))
      @f.save
      FitsCharacterizingJob.perform(@f.id)
      @f.reload
      expect(@f.fitsMetadata.content).to include('<identity format="Portable Network Graphics" mimetype="image/png"')
      expect(@f.format_pronom_id).to eq 'fmt/11'
    end
  end

  it 'should throw error, when given nil' do
    expect{FitsCharacterizingJob.perform(nil)}.to raise_error(ArgumentError)
  end

  it 'should throw error, when given an instance' do
    @i = Instance.create(activity: @default_activity_id, copyright: 'Some Copyright',  collection: ['Some Collection'])
    expect{FitsCharacterizingJob.perform(@i.id)}.to raise_error(ArgumentError)
  end
end

