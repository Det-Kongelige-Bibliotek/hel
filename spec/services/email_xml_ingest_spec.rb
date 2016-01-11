require 'spec_helper'

describe 'Build dictionary' do
  include_context 'shared'
  describe 'from xml file' do

    before :all do
      @export_file_path = Pathname.new(Rails.root).join('spec', 'fixtures', 'email', 'Exports.xml')
      @base_dir_path= Pathname.new(Rails.root).join('spec', 'fixtures', 'email', 'Mails')
      @email_dir_path = "/Inbox/"
      @file_name = "feea79579b7a8dd97cb7bf050780351c"
      @pathkey = @base_dir_path.to_s +  @email_dir_path + @file_name
      @email_metadata = EmailXMLIngest.email_xml_ingest(@export_file_path.to_s, @base_dir_path.to_s)
    end

    it 'should have builded the dictionary' do
      expect(@email_metadata).not_to be_nil
    end

    it 'should have header felt' do
      expect(@email_metadata[@pathkey]["date"]).not_to be_nil
      expect(@email_metadata[@pathkey]["fromName"]).not_to be_nil
      expect(@email_metadata[@pathkey]["fromAddr"]).not_to be_nil
      expect(@email_metadata[@pathkey]["replyTo"]).not_to be_nil
      expect(@email_metadata[@pathkey]["to"]).not_to be_nil
      expect(@email_metadata[@pathkey]["cc"]).not_to be_nil
      expect(@email_metadata[@pathkey]["bcc"]).not_to be_nil
      expect(@email_metadata[@pathkey]["subject"]).not_to be_nil
      expect(@email_metadata[@pathkey]["priority"]).not_to be_nil
      expect(@email_metadata[@pathkey]["flags"]).not_to be_nil
      expect(@email_metadata[@pathkey]["messageId"]).not_to be_nil
    end

    it 'should have body felt' do
      expect(@email_metadata[@pathkey]["body"]).not_to be_nil
    end

    it 'should have attachments felt' do
      expect(@email_metadata[@pathkey]["attachments"]).not_to be_nil
    end

    it 'should have attachmentsFullPath felt' do
      expect(@email_metadata[@pathkey]["attachmentsFullPath"]).not_to be_nil
    end

    it 'should have attachmentsFileNames felt' do
      expect(@email_metadata[@pathkey]["attachmentsFileNames"]).not_to be_nil
    end

    it 'should include email header information containing a non-empty string' do
      expect(@email_metadata[@pathkey]["date"]).not_to be_empty
      expect(@email_metadata[@pathkey]["fromName"]).not_to be_empty
      expect(@email_metadata[@pathkey]["fromAddr"]).not_to be_empty
      expect(@email_metadata[@pathkey]["to"]).not_to be_empty
      expect(@email_metadata[@pathkey]["cc"]).not_to be_empty
      expect(@email_metadata[@pathkey]["subject"]).not_to be_empty
      expect(@email_metadata[@pathkey]["priority"]).not_to be_empty
      expect(@email_metadata[@pathkey]["flags"]).not_to be_empty
      expect(@email_metadata[@pathkey]["messageId"]).not_to be_empty
    end

    it 'should include email header information containing a empty string' do
      expect(@email_metadata[@pathkey]["replyTo"]).to be_empty
      expect(@email_metadata[@pathkey]["bcc"]).to be_empty
    end

    it 'should include email body information containing a non-empty string' do
      expect(@email_metadata[@pathkey]["body"]).not_to be_empty
    end

    it 'should include email attachments information containing a non-empty string' do
      expect(@email_metadata[@pathkey]["attachments"]).not_to be_empty
    end

    it 'should include specific email header information' do
      expect(@email_metadata[@pathkey]["date"]).to include("2015-10-09 10:48:02")
      expect(@email_metadata[@pathkey]["fromName"]).to include("Chris L Awre")
      expect(@email_metadata[@pathkey]["fromAddr"]).to include("C.Awre@hull.ac.uk")
      expect(@email_metadata[@pathkey]["to"]).to include("chh@kb.dk")
      expect(@email_metadata[@pathkey]["cc"]).to include("cjen@kb.dk")
      expect(@email_metadata[@pathkey]["subject"]).to include("HDPIG call follow-up")
      expect(@email_metadata[@pathkey]["priority"]).to include("0")
      expect(@email_metadata[@pathkey]["flags"]).to include("RE")
      expect(@email_metadata[@pathkey]["messageId"]).to include("hull.ac.uk")
    end

    it 'should include specific email body information' do
      expect(@email_metadata[@pathkey]["body"]).to include("I had meetings all afternoon")
    end

    it 'should include specific email attachments information' do
      expect(@email_metadata[@pathkey]["attachments"]).to include("ATT00001.txt")
    end

    it 'should include specific attachmentsFullPath information' do
      expect(@email_metadata[@pathkey]["attachmentsFullPath"]).to include("P:")
    end

    it 'should include specific attachmentsFileNames information' do
      expect(@email_metadata[@pathkey]["attachmentsFileNames"]).to include("ATT00001.txt")
    end
  end
end
