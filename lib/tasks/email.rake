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
end
