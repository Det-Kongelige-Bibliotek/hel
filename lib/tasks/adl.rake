namespace :adl do

  desc 'Init ADL activity and ext. repo'
  task :init, [:git_url, :base_dir,:branch, :image_dir] => :environment do |task, args|
    adl_activity = Administration::Activity.create(activity: "ADL", embargo: "0", access_condition: "",
      copyright: "Attribution-NonCommercial-ShareAlike CC BY-NC-SA", collection: ["dasam3"], preservation_profile: "storage", :dissemination_profiles => ["DisseminationProfiles::Adl"])
    adl_activity.activity_permissions = {"file"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}},
                                "instance"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}}
    adl_activity.save

    repo = Administration::ExternalRepository.create(:name => 'ADL', :url => args.git_url,
                                                     :branch => args.branch, :sync_status =>'NEW', :sync_method => 'ADL',
                                                     :base_dir => args.base_dir, :activity => adl_activity.id,
                                                      :image_dir => args.image_dir)

  end

  desc 'Send all ADL (TEI) instances to dissemination'
  task disseminate_all_adl: :environment do
    adl_activity = Administration::Activity.where(activity: 'ADL').first
    raise "There is no ADL activity" if adl_activity.nil?
    Instance.where(activity: adl_activity.id).select{|i| i.type=='TEI'}.each do |ins|
      Resque.enqueue(DisseminateJob,ins.id)
    end
  end


  desc 'Clean data WARNING: will remove all data from you repository'
  task clean: :environment do
    raise "You do not want to delete all production data" if Rails.env == 'production'
    ContentFile.delete_all
    ActiveFedora::Base.delete_all
    Administration::SyncMessage.delete_all
    Administration::ExternalRepository.delete_all
  end

  desc 'creates a sample adl-bifrost solr doc'
  task test_adl_solr: :environment do
    f = File.open('doc.xml','w')
    doc = DisseminationProfiles::Adl.transform('/home/dgj/adl_texts/texts/aakjaer01val.xml',{})
    doc.write_xml_to f
    f.close
  end

end
