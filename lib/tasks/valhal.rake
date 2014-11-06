namespace :valhal do
  desc 'Add default values to rightsMetadataStream'
  task set_default_rights: :environment do

      Work.all.each do |w|
        puts "setting rights for #{w.pid}"
        add_default_rights(w)
      end
      Instance.all.each do  |i|
        puts "setting rights for #{i.pid}"
        add_default_rights(i)
      end
      ContentFile.all.each do |f|
        puts "setting rights for #{f.pid}"
        add_default_rights(f)
      end
      Authority::Base.all.each do |b|
        puts "setting rights for #{b.pid}"
        add_default_rights(b)
      end
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
    obj.read_groups = ['public']
    obj.edit_groups = ['registered']
    obj.save
    obj.reload
  end
end
