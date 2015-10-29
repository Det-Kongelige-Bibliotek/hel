# -*- coding: utf-8 -*-
require 'spec_helper'

describe  TeiHeaderSyncService do

  before :all do
    # the sysno of this edition is 001541111
    filename = "001541111_000.xml"
    @dir = filename.split('.', 2)[0]
    source_file = "#{Rails.root}/spec/fixtures/breve/001541111_000/#{filename}"

    @tei_file   = "/tmp/letters-test/texts/#{filename}"
    work_dir    = "/tmp/letters-test/texts/"

    cmd         = 
      "rm -r #{work_dir};" +
      "mkdir -p #{work_dir};" + 
      "cp #{source_file} #{@tei_file}"

    @xsl  = "#{Rails.root}/app/services/xslt/tei_header_insert.xsl"

    self.executor(cmd)
    @xdoc = Nokogiri::XML.parse(File.new(@tei_file)) { |config| config.strict }
    
    @idno = filename.split('_', 2)[0]
  end

  describe '#update_header' do
    it 'should be able to edit the header in a tei file' do
      pending "USES UNKNOWN FIELDS"
      adl_activity = Administration::Activity.new
      adl_activity.activity = "Floral extension"
      adl_activity.copyright = "CC BY-ND"
      adl_activity.collection = ["dasamx"]
      adl_activity.preservation_collection = "simple"
      adl_activity.save
      work=Work.new
      work.add_title(
                     { value: 'The Importance of Being Earnest', 
                       type: 'Uniform',
                       subtitle: 'and other encounters', lang: 'en' }
                     )
      forename = "New forename"
      surname  = "New surname"
      person   = Authority::Person.find_or_create_person(forename,surname)
      work.add_author(person)
      work.save
      instance=Instance.new
      instance.published_place = "The end of the universe"
      instance.activity = adl_activity.pid
      instance.copyright =  adl_activity.copyright
      instance.collection =  adl_activity.collection
      instance.save
      instance.set_work=work
      instance.save
      cf       = ContentFile.new
      cf.add_external_file(@tei_file)
      cf.save
      instance.add_file(cf)
      instance.save
      work.save
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
