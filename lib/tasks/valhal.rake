namespace :valhal do
  desc 'Add default values to rightsMetadataStream'
  task set_default_rights: :environment do
      Work.all.collect {|t| add_default_rights(t)}
      Instance.all.collect {|t| add_default_rights(t)}
      Trykforlaeg.all.collect {|t| add_default_rights(t)}
      ContentFile.all.collect {|t| add_default_rights(t)}
      Authority::Base.all.collect {|t| add_default_rights(t)}
  end

  desc 'Load pre-configured ControlledLists'
  task load_controlled_lists: :environment do
    Administration::ControlledList.delete_all
    Administration::ListEntry.delete_all
    lists = YAML.load_file(Rails.root.join('config', 'controlled_lists.yml'))
    lists.each_value do |val|
      current = Administration::ControlledList.create(name: val['name'])
      if val.has_key?('entries')
        val['entries'].each do |entry|
          Administration::ListEntry.create(name: entry, controlled_list: current)
        end
      end
    end
  end

  private

  def add_default_rights(obj)
    puts "Setting rights on #{obj.class} #{obj.pid}"
    begin
      obj.edit_groups = ['Chronos-Admin']
      obj.save
    rescue => e
      puts "Error setting rights on #{obj.class} #{obj.pid} #{e}"
    end
  end
end
