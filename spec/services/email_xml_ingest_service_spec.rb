require 'spec_helper'
require 'fakeredis'

describe 'Build dictionary' do
  include_context 'shared'
  describe 'from xml file' do

    before :all do
      @redis = Redis.new
      @export_file_path = Pathname.new(Rails.root).join('spec', 'fixtures', 'email', 'Exports.xml')
      @base_dir_path= Pathname.new(Rails.root).join('spec', 'fixtures', 'email', 'Mails')
      @email_dir_path = "/Inbox/"
      @file_name = "feea79579b7a8dd97cb7bf050780351c"
      @pathkey = @base_dir_path.to_s +  @email_dir_path + @file_name
      EmailXMLIngestService.email_xml_ingest(@export_file_path.to_s, @base_dir_path.to_s)
    end

    it 'should have builded the dictionary' do
      expect(@redis.exists(@pathkey)).not_to be_nil
    end

    it 'should have header felt' do
      expect(@redis.hget(@pathkey, "date")).not_to be_nil
      expect(@redis.hget(@pathkey, "fromName")).not_to be_nil
      expect(@redis.hget(@pathkey, "fromAddr")).not_to be_nil
      expect(@redis.hget(@pathkey, "replyTo")).not_to be_nil
      expect(@redis.hget(@pathkey, "to")).not_to be_nil
      expect(@redis.hget(@pathkey, "cc")).not_to be_nil
      expect(@redis.hget(@pathkey, "bcc")).not_to be_nil
      expect(@redis.hget(@pathkey, "subject")).not_to be_nil
      expect(@redis.hget(@pathkey, "priority")).not_to be_nil
      expect(@redis.hget(@pathkey, "flags")).not_to be_nil
      expect(@redis.hget(@pathkey, "messageId")).not_to be_nil
    end

    it 'should have body felt' do
      expect(@redis.hget(@pathkey, "body")).not_to be_nil
    end

    it 'should have attachments felt' do
      expect(@redis.hget(@pathkey, "attachments")).not_to be_nil
    end

    it 'should have attachmentsFullPath felt' do
      expect(@redis.hget(@pathkey, "attachmentsFullPath")).not_to be_nil
    end

    it 'should have attachmentsFileNames felt' do
      expect(@redis.hget(@pathkey, "attachmentsFileNames")).not_to be_nil
    end

    it 'should include email header information containing a non-empty string' do
      expect(@redis.hget(@pathkey, "date")).not_to be_empty
      expect(@redis.hget(@pathkey, "fromName")).not_to be_empty
      expect(@redis.hget(@pathkey, "fromAddr")).not_to be_empty
      expect(@redis.hget(@pathkey, "to")).not_to be_empty
      expect(@redis.hget(@pathkey, "cc")).not_to be_empty
      expect(@redis.hget(@pathkey, "subject")).not_to be_empty
      expect(@redis.hget(@pathkey, "priority")).not_to be_empty
      expect(@redis.hget(@pathkey, "flags")).not_to be_empty
      expect(@redis.hget(@pathkey, "messageId")).not_to be_empty
    end

    it 'should include email header information containing a empty string' do
      expect(@redis.hget(@pathkey, "replyTo")).to be_empty
      expect(@redis.hget(@pathkey, "bcc")).to be_empty
    end

    it 'should include email body information containing a non-empty string' do
      expect(@redis.hget(@pathkey, "body")).not_to be_empty
    end

    it 'should include email attachments information containing a non-empty string' do
      expect(@redis.hget(@pathkey, "attachments")).not_to be_empty
    end

    it 'should include specific email header information' do
      expect(@redis.hget(@pathkey, "date")).to include("2015-10-09 10:48:02")
      expect(@redis.hget(@pathkey, "fromName")).to include("Chris L Awre")
      expect(@redis.hget(@pathkey, "fromAddr")).to include("C.Awre@hull.ac.uk")
      expect(@redis.hget(@pathkey, "to")).to include("chh@kb.dk")
      expect(@redis.hget(@pathkey, "cc")).to include("cjen@kb.dk")
      expect(@redis.hget(@pathkey, "subject")).to include("HDPIG call follow-up")
      expect(@redis.hget(@pathkey, "priority")).to include("0")
      expect(@redis.hget(@pathkey, "flags")).to include("RE")
      expect(@redis.hget(@pathkey, "messageId")).to include("hull.ac.uk")
    end

    it 'should include specific email body information' do
      expect(@redis.hget(@pathkey, "body")).to include("I had meetings all afternoon")
    end

    it 'should include specific email attachments information' do
      expect(@redis.hget(@pathkey, "attachments")).to include("ATT00001.txt")
    end

    it 'should include specific attachmentsFullPath information' do
      expect(@redis.hget(@pathkey, "attachmentsFullPath")).to include("P:")
    end

    it 'should include specific attachmentsFileNames information' do
      expect(@redis.hget(@pathkey, "attachmentsFileNames")).to include("ATT00001.txt")
    end
  end
end
