require 'spec_helper'

describe ViewFileController, type: :controller do

  include_context 'shared'

  describe '#import_from_preservation' do

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

    it 'should fail when no arguments are given ' do
      post :import_from_preservation, {}
      response.status.should eq 400
    end

    it 'should be possible to import from preservation' do
      @f.import_token = "TOKEN-#{DateTime.now.to_i}"
      @f.import_token_timeout = (DateTime.now + 1.year).to_s
      @f.save!
      @file = Rack::Test::UploadedFile.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'blank_file.txt'), @f.mime_type)

      post :import_from_preservation, :file => @file, 'uuid' => @f.id, 'type' => 'FILE', 'token' => @f.import_token
      response.status.should eq 200
    end

    it 'should only be possible to import from preservation once. Second time must fail' do
      @f.import_token = "TOKEN-#{DateTime.now.to_i}"
      @f.import_token_timeout = (DateTime.now + 1.year).to_s
      @f.save!
      @file = Rack::Test::UploadedFile.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'blank_file.txt'), @f.mime_type)

      post :import_from_preservation, :file => @file, 'uuid' => @f.id, 'type' => 'FILE', 'token' => @f.import_token
      response.status.should eq 200

      post :import_from_preservation, :file => @file, 'uuid' => @f.id, 'type' => 'FILE', 'token' => @f.import_token
      response.status.should eq 400
    end

    it 'should be not possible to import from preservation, when it has no import token' do
      @file = Rack::Test::UploadedFile.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'blank_file.txt'), @f.mime_type)

      post :import_from_preservation, :file => @file, 'uuid' => @f.id, 'type' => 'FILE', 'token' => @f.import_token
      response.status.should eq 400
    end

    it 'should be not possible to import from preservation, when it import has timed_out' do
      @f.import_token = "TOKEN-#{DateTime.now.to_i}"
      @f.import_token_timeout = (DateTime.now - 1.year).to_s
      @f.save!
      @file = Rack::Test::UploadedFile.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'blank_file.txt'), @f.mime_type)

      post :import_from_preservation, :file => @file, 'uuid' => @f.id, 'type' => 'FILE', 'token' => @f.import_token
      response.status.should eq 400
    end

    it 'should be not possible to import from preservation, when using another type than FILE' do
      @f.import_token = "TOKEN-#{DateTime.now.to_i}"
      @f.import_token_timeout = (DateTime.now + 1.year).to_s
      @f.save!
      @file = Rack::Test::UploadedFile.new(Pathname.new(Rails.root).join('spec', 'fixtures', 'blank_file.txt'), @f.mime_type)

      post :import_from_preservation, :file => @file, 'uuid' => @f.id, 'type' => 'NOT_A_FILE', 'token' => @f.import_token
      response.status.should eq 400
    end
  end
end