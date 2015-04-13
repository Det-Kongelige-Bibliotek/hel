namespace :breve do

  desc 'Create Danmarks Breve Activity'
  task create_activity: :environment do
    raise 'This should only be done in development mode' unless Rails.env == 'development'
    raise 'Danmarks Breve activity already found' unless Administration::Activity.find(activity: 'Danmarks Breve').size == 0
    activity = Administration::Activity.create(
        activity: 'Danmarks Breve', embargo: '0', access_condition: '', copyright: 'CC BY-NC-ND',
        collection: 'Håndskriftsamlingen')
    activity.permissions = {
        "file"=>{ "group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"] }},
        "instance"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}
    }
    activity.save
    puts "saved activity with id #{activity.id}"
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
end