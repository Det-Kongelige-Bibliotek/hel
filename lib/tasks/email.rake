namespace :email do

  desc 'Create MyArchive Activity'
  task create_activity: :environment do
    raise 'This should not be done in production mode' if Rails.env == 'production'
    if Administration::Activity.where(activity: 'MyArchive').size != 0
      puts 'The MyArchive activity already exist!'
      exit
    end
    activity = Administration::Activity.create(
        "activity"=>'MyArchive', "embargo"=>'1', "access_condition"=>'læsesal', "copyright"=>'CC BY-NC-ND',
        "preservation_collection"=>'storage', "availability"=> '0', "collection"=> ["Håndskriftsamlingen"],
        "activity_permissions"=>{"file"=>{ "group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Admin"],
                                                     "edit"=>["Chronos-Admin"] }}, "instance"=>{"group"=>{"discover"=>["Chronos-Alle"],
                                                                                                          "read"=>["Chronos-NSA","Chronos-Admin"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}}
    )
    if activity.save
      puts "saved activity with id #{activity.id}"
    else
      raise "Activity not saved due to the following errors: #{activity.errors.messages}"
    end
  end

  desc 'Given a path, without trailing slash, to a folder containing data, the name of the email folder,
  the name of the attachment folder, the name of the Aid4Mail export xml file,
  and the forename and surname of the donor, this task runs the email ingest. Prerequirements: Using Aid4Mail
  an export xml file, a folder containing emails, and an attachment folder with the same structure as the email folder
  should be produced'
  task :import_from_path, [:base_dir_path, :email_dir_name, :attachment_dir_name, :export_file_name,
                           :donor_forename, :donor_surname] => :environment do |task, args|

    base_dir_path = args.base_dir_path
    email_dir_name = args.email_dir_name
    email_dir_path = base_dir_path + '/' + email_dir_name
    attachment_dir_name = args.attachment_dir_name
    export_file_name = args.export_file_name
    donor_forename = args.donor_forename
    donor_surname = args.donor_surname

    fail ArgumentError, 'The forename of the donor should be given' if donor_forename.nil? ||
        donor_forename.empty?
    fail ArgumentError, 'The surname of the donor should be given' if donor_surname.nil? ||
        donor_surname.empty?

    person_id = Authority::Person.find_or_create_person(donor_forename, donor_surname).id

    if Rails.env == 'test'
      EmailIngestJob.perform(base_dir_path, email_dir_name, attachment_dir_name, export_file_name, person_id)
    else
      Resque.enqueue(EmailIngestJob, base_dir_path, email_dir_name, attachment_dir_name, export_file_name, person_id)
    end
  end
end
