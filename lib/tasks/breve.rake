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
end