# -*- coding: utf-8 -*-
require 'spec_helper'

describe  TeiHeaderSyncService do

  before :all do
    # the sysno of this edition is 001541111
    filename = "001541111_000.xml"
    @dir = filename.text.split('.', 2)[0]
    source_file = "#{Rails.root}/spec/fixtures/breve/001541111_000/#{filename}"

    @tei_file   = "/tmp/letters-test/texts/#{filename}"
    work_dir    = "/tmp/letters-test/texts/"

    cmd         = 
      "rm -r #{work_dir};" +
      "mkdir -p #{work_dir};" + 
      "cp #{source_file} #{@tei_file}"

    @xsl  = "#{Rails.root}/app/services/xslt/tei_header_sed.xsl"

    self.executor(cmd)
    @xdoc = Nokogiri::XML.parse(File.new(@tei_file)) { |config| config.strict }
    thing = @xdoc.xpath '//t:publicationStmt/t:idno', 't' => 'http://www.tei-c.org/ns/1.0' 

    @idno = filename.text.split('_', 2)[0]
  end

  describe '#update_header' do
    it 'should be able to edit the header in a tei file' do
      adl_activity = Administration::Activity.new
      adl_activity.activity = "Floral extension"
      adl_activity.copyright = "CC BY-ND"
      adl_activity.collection = "dasamx"
      adl_activity.preservation_profile = "simple"
      adl_activity.save
      instance     = SyncExtRepoADL.create_new_work_and_instance(@idno,
                                                                 @xdoc,
                                                                 adl_activity)

      instance.published_place = "The end of the universe"

      work = instance.work.first
      work.add_title(
                     { value: 'The Importance of Being Earnest', 
                       type: 'Uniform',
                       subtitle: 'and other encounters', lang: 'en' }
                     )
      forename = "New forename"
      surname  = "New surname"
      person   = Authority::Person.find_or_create_person(forename,surname)
      work.add_author(person)
      author   = work.authors.first
      cf       = SyncExtRepoADL.add_contentfile_to_instance(@tei_file,instance)
      result   = TeiHeaderSyncService.perform(@xsl,@tei_file,instance)

      find_sub = result.xpath '//t:sourceDesc/t:bibl/t:title[@type="sub"]', 't' => 'http://www.tei-c.org/ns/1.0' 

      expect(find_sub.text).to eql 'and other encounters'
    end
  end

  def executor(cmd)
    msg = ""
    success = false
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        msg += line
      end
      msg += stderr.read
      exit_status = wait_thr.value
      success = exit_status.success?
    end
    puts msg
    success
  end

end
