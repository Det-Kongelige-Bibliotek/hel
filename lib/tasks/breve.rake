namespace :breve do

  desc 'Create Danmarks Breve Activity'
  task create_activity: :environment do
    raise 'This should only be done in development mode' unless Rails.env == 'development'
    exit unless Administration::Activity.find(activity: 'Danmarks Breve').size == 0
    activity = Administration::Activity.create(
        activity: 'Danmarks Breve', embargo: '0', access_condition: '', copyright: 'CC BY-NC-ND',
        preservation_collection: 'simple', collection: 'Håndskriftsamlingen'
    )
    activity.activity_permissions = {
        "file"=>{ "group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"] }},
        "instance"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}
    }
    if activity.save
      puts "saved activity with id #{activity.id}"
    else
      puts activity.errors.messages
      raise 'Activity not saved'
    end
  end

  # The correct folder structure should be something like:
  #  <sysnum>_000
  #          <sysnum>_000.xml
  #          images/
  #            - <sysnum>_000_0010
  #            - <sysnum>_000_0011
  #            etc...
  desc 'Given a path to a folder containing letter data, run the volume and letter import for that folder'
  task :import_from_path, [:path] => :environment do |task, args|
    LetterVolumeIngest.perform(args.path)
  end

  desc "export all persons to a json file"
  task :export_persons, [:file] => :environment do |task,args|
	content = ""
	persons = Authority::Person.all
	persons.each do |p| 
		puts "exporting #{p.to_json}"
		content += p.to_json + "\n"
	end
	File.open(args.file,"w+") do |f| 
		f.write(content) 
	end
  end

  desc "export (some) letterbook data"
  task :export_lb_data, [:file] => :environment do |task,args|
	hash = {}
	LetterBook.all.each do |lb|
		if lb.get_instance('TEI').content_files.first.present?
  			filename = lb.get_instance('TEI').content_files.first.external_file_path.split('/').last
  			hash[filename] = {}
  			hash[filename][:id] = lb.id
  			hash[filename][:status] = lb.get_instance('TEI').status
		end
	end
	File.open(args.file,"w+") do |f| 
		f.write(hash.as_json) 
	end
  end

  task :import_persons_from_file, [:file] => :environment do |task,args|
	File.open(args.file,:externa_encoding => 'UTF-8', :internal_encoding => 'utf-8').each do |line|
		puts "parsing line #{line}"
  		parsed = JSON.parse(line.force_encoding("UTF-8"))
		puts "Saving #{parsed["given_name"]} #{parsed["family_name"]}"
  		obj = Authority::Person.new(id: parsed["id"], 
					same_as_uri: parsed["same_as"].map{|v| v["id"]}, 
					alternate_names: parsed["alternate_names"], 
					description: parsed["description"], 
					given_name: parsed["given_name"].to_s.force_encoding("UTF-8"), 
					family_name: parsed["family_name"].to_s.force_encoding("UTF-8"), 
					additional_name: parsed["additional_name"], 
					gender: parsed["gender"], 
					birth_date: parsed["birth_date"], 
					death_date: parsed["death_date"])
  		obj.save
	end
  end
  
end
