namespace :adl do



  desc 'Init ADL activity and ext. repo'
  task init: :environment do
    adl_activity = Administration::Activity.create(activity: "ADL", embargo: "0", access_condition: "",
      copyright: "Attribution-NonCommercial-ShareAlike CC BY-NC-SA", collection: "dasam3", preservation_profile: "storage")
    adl_activity.permissions = {"file"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}},
                                "instance"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}}
    adl_activity.save

    repo = Administration::ExternalRepository.create(:name => 'ADL', :url => 'git@disdev-01:/opt/git/adl_data.git',
                                                     :branch => 'mini2', :sync_status =>'NEW', :sync_method => 'ADL',
                                                     :base_dir => '/tmp/adl_data', :activity => adl_activity.pid)

  end


  desc 'Clean data'
  task clean: :environment do
    ContentFile.delete_all
    ActiveFedora::Base.delete_all
    Administration::SyncMessage.delete_all
    Administration::ExternalRepository.delete_all
  end

  desc 'Import ADL files to Valhal'
  task :import, [:path] => :environment do |task, args|
    if (!Dir.exist?("#{args.path}"))
      raise "Directory #{args.path} does not exists"
    end

    adl_activity = find_or_create_adl_activity
    raise 'ADL Activity not found - exiting...' unless adl_activity.present?

    Dir.glob("#{args.path}/*/*.xml").each do |fname|
      puts "file #{fname}"
      doc = Nokogiri::XML(File.open(fname))

      if (doc.xpath("//xmlns:teiHeader/xmlns:fileDesc").size > 0)
        id = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:publicationStmt/xmlns:idno").text
        puts ("  ID is #{id}")
        sysno = nil
        volno = nil
        unless id.blank?
          puts ("  ID is #{id}")

          sysno = id.split(":")[0]
          volno = id.split(":")[1]
          puts (" sysno #{sysno} vol #{volno}")
        end

        i = nil
        i = find_instance(sysno) unless sysno.blank? || sysno == '000000000'
        i = create_new_work_and_instance(sysno,doc,adl_activity) if i.nil?
        add_contentfile_to_instance(fname,i) unless i.nil?
      end
    end
  end


  private

  def find_or_create_adl_activity
    adl_params = {
        activity: 'ADL',
        collection: 'dasam3',
        copyright: 'Attribution-NonCommercial-ShareAlike CC BY-NC-SA'
    }
    Administration::Activity.find(activity: 'ADL').first ||
        Administration::Activity.create(adl_params)
  end

  def find_instance(sysno)
    puts "searching for instances"
    result = ActiveFedora::SolrService.query('system_number_tesim:"'+sysno+'" && active_fedora_model_ssi:Instance')
    if (result.size > 0)
      puts "  found instance #{result[0]['id']}"
      Instance.find(result[0]['id'])
    else
      puts "  no instance found"
      nil
    end
  end

  def create_new_work_and_instance(sysno,doc,adl_activity)
    w = Work.new
    doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title").each do |n|
      w.add_title(value: n.text)
    end

    doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").each do |n|
      unless doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").text.blank?
        names = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").text
        # Convert the names to title case in an encoding safe manner
        # e.g. JEPPE AAKJÆR becomes Jeppe Aakjær
        titleized_names = names.mb_chars.titleize.wrapped_string.split(' ')
        surname = titleized_names.pop
        forename = titleized_names.join(' ')
        p = find_or_create_person(forename,surname)
        w.add_author(p)
      end
    end
    unless w.save
      raise "unable to create new work"
    end

    i = Instance.new
    i.set_work=w

    i.system_number = sysno
    i.activity = adl_activity.pid
    i.copyright = adl_activity.copyright
    i.collection = adl_activity.collection
    i.preservation_profile = adl_activity.preservation_profile

    result = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:publicationStmt/xmlns:publisher")
    i.publisher_name = result[0].text unless result.size == 0

    unless i.save
      raise "unable to create instance"
    end
    i
  rescue Exception => e
    puts "unable to create work or instance #{e.inspect}"
    pp i.errors
    pp w.errors
    nil
  end

  def add_contentfile_to_instance(fname,i)
    i.add_file(fname)
    i.save
  end

  def find_or_create_person(forename,surname)
    puts "  searching for person #{surname}, #{forename}"
    result = ActiveFedora::SolrService.query('person_name_tesim:"'+surname+', '+forename+'"')
    if (result.size > 0)
      puts "  found person #{result[0]['id']}"
      Authority::Person.find(result[0]['id'])
    else
      puts " creating person"
      p = Authority::Person.create(authorized_personal_name: { 'given' => forename, 'family' => surname})
      puts " person #{p.pid} created"
      p
    end
  end

end