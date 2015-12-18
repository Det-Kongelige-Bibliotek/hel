require 'spec_helper'

describe 'Ingest' do
  include_context 'shared'
  describe 'of email account' do

    before :all do
      activity = Administration::Activity.create(
          "activity"=>'MyArchive', "embargo"=>'1', "access_condition"=>'læsesal', "copyright"=>'CC BY-NC-ND',
          "preservation_collection"=>'storage', "availability"=> '0', "collection"=> ["Håndskriftsamlingen"],
          "activity_permissions"=>{"file"=>{ "group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Admin"],
                                                       "edit"=>["Chronos-Admin"] }}, "instance"=>{"group"=>{"discover"=>["Chronos-Alle"],
                                                                                                            "read"=>["Chronos-NSA","Chronos-Admin"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}}
      )
      @base_dir_path = Pathname.new(Rails.root).join('spec', 'fixtures', 'email').to_s
      @email_dir_name = "Mails"
      @attachment_dir_name = "Attachments"
      @export_file_name = 'Exports.xml'
      @email_dir_path = @base_dir_path.to_s + "/" + @email_dir_name

      @fake_base_dir_path = @base_dir_path + "Fake"
      @fake_email_dir_name= "Nails"
      @fake_attachment_dir_name = "Fattachments"
      @fake_export_file_name = 'Fexports.xml'

      @donor_forename = "Anders"
      @donor_surname = "Sand"
      @donor = Authority::Person.find_or_create_person(@donor_forename, @donor_surname)
      @donor_id = @donor.id

      @parent_work = Work.new('origin_date'=>'1964')
      @parent_work.add_title({'value'=> 'email'})
      @parent_work.add_author(@donor)
      @parent_work.save
      @parent_work_id = @parent_work.id

      EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @attachment_dir_name, @export_file_name,
                             @donor_id, @parent_work_id)

      @inbox_folder = ContentFile.find_by_original_filename("Inbox")
      @inbox_folder_instance =  @inbox_folder.instance
      @inbox_folder_work = @inbox_folder_instance.work

      @email_file = ContentFile.find_by_original_filename("feea79579b7a8dd97cb7bf050780351c.msg")
      @email_instance = @email_file.instance
      @email_work = @email_instance.work

      @attachment_file = ContentFile.find_by_original_filename("ATT00001.txt")
      @attachment_instance = @attachment_file.instance
      @attachment_work = @attachment_instance.work

      @folder_work = @email_work.is_part_of
    end

    after :all do
      # Do nothing as spec_helper should do the cleaning when the test is run again.
    end

    it 'should create email Work with title "HDPIG call follow-up" ' do
      expect(Finder.works_by_title("HDPIG call follow-up").size).to be >= 1
    end

    it 'should create email Contentfile ' do
      expect(@email_file).not_to be_nil
    end

    it 'should create email Instance ' do
      expect(@email_instance).not_to be_nil
    end

    it 'should create email Work ' do
      expect(@email_work).not_to be_nil
    end

    it 'should create attachment Contentfile ' do
      expect(@attachment_file).not_to be_nil
    end

    it 'should create attachment Instance ' do
      expect(@attachment_instance).not_to be_nil
    end

    it 'should create attachment Work ' do
      expect(@attachment_work).not_to be_nil
    end

    it 'email Work has a Instance' do
      expect(@email_work.instances.size).to  be == 1
    end

    it 'email Work has title' do
      expect(@email_work.titles).not_to be_nil
      expect(@email_work.titles.first.value).to include "HDPIG call follow-up"
    end

    it 'should create and link a Person object for the author of email' do
      expect(@email_work.authors).not_to be_nil
      expect(@email_work.authors.first).to be_an_instance_of Authority::Person
      expect(@email_work.authors.first.given_name.to_s).to include "Chris L"
      expect(@email_work.authors.first.family_name.to_s).to include "Awre"
      expect(@email_work.authors.first.given_name.to_s).not_to include "Anders"
      expect(@email_work.authors.first.family_name.to_s).not_to include "Sand"
    end

    it 'should create and link a Person object for the recipient of email' do
      expect(@email_work.recipients).not_to be_nil
      expect(@email_work.recipients.first).to be_an_instance_of Authority::Person
      expect(@email_work.recipients.first.given_name.to_s).to include "C"
      expect(@email_work.recipients.first.family_name.to_s).to include "e"
      expect(@email_work.recipients.first.email.to_s).to include "kb.dk"
    end

    it 'email Work has parent Work (folder)' do
      expect(@folder_work.parts).to include @email_work
      expect(@email_work.is_part_of).to eq @folder_work
    end

    it 'parent Work has title' do
      expect(@folder_work.titles).not_to be_nil
      expect(@folder_work.titles.first.value.to_s).to include "Inbox"
    end

    it 'should create and link a Person object for the author of folder' do
      expect(@folder_work.authors).not_to be_nil
      expect(@folder_work.authors.first).to be_an_instance_of Authority::Person
      expect(@folder_work.authors.first.given_name.to_s).to include "Anders"
      expect(@folder_work.authors.first.family_name.to_s).to include "Sand"
      expect(@folder_work.authors.first.given_name.to_s).not_to include "Chris L"
      expect(@folder_work.authors.first.family_name.to_s).not_to include "Awre"
    end

    it 'email Work has attachment child Work' do
      expect(@email_work.parts).to include @attachment_work
      expect(@attachment_work.is_part_of).to eq @email_work
    end

    it 'attachment child  Work has title' do
      expect(@attachment_work.titles).not_to be_nil
      expect(@attachment_work.titles.first.value).to include "ATT00001"
    end

    it 'attachment Work should create and link a Person object for the author' do
      expect(@attachment_work.authors).not_to be_nil
      expect(@attachment_work.authors.first).to be_an_instance_of Authority::Person
      expect(@attachment_work.authors.first.given_name.to_s).to include "Chris L"
      expect(@attachment_work.authors.first.family_name.to_s).to include "Awre"
      expect(@attachment_work.authors.first.given_name.to_s).not_to include "Anders"
      expect(@attachment_work.authors.first.family_name.to_s).not_to include "Sand"
    end

    it 'Inbox Work has parent Work' do
      expect(@parent_work.parts).to include @inbox_folder_work
      expect(@inbox_folder_work.is_part_of).to eq @parent_work
    end

    it 'should throw error, when given nil' do
      expect{EmailIngestJob.perform(nil, @email_dir_name, @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should not throw error, when given nil' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, nil, @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end
    it 'should not throw error, when given nil' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, nil, @export_file_name,
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end

    it 'should not throw error, when given nil' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @attachment_dir_name, nil,
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end

    it 'should throw error, when given nil' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @attachment_dir_name, @export_file_name,
                                 nil, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should throw error, when given an empty string' do
      expect{EmailIngestJob.perform('', @email_dir_name, @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should not throw error, when given an empty string' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, '', @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end
    it 'should mot throw error, when given an empty string' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, '', @export_file_name,
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end

    it 'should not throw error, when given an empty string' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @attachment_dir_name, '',
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end

    it 'should throw error, when @base_dir_path does not exist' do
      expect{EmailIngestJob.perform(@fake_base_dir_path.to_s, @email_dir_name, @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should throw error, when @email_dir_name does not exist' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @fake_email_dir_name, @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should throw error, when @attachment_dir_name does not exist' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @fake_attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should throw error, when @export_file_name does not exist' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @attachment_dir_name, @fake_export_file_name,
                                 @donor_id, @parent_work_id)}.to raise_error(ArgumentError)
    end

    it 'should not throw error' do
      expect{EmailIngestJob.perform(@base_dir_path.to_s, @email_dir_name, @attachment_dir_name, @export_file_name,
                                 @donor_id, @parent_work_id)}.not_to raise_error
    end
  end
end
