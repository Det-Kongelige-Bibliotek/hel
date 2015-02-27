require 'resque'
require 'open3'

class SyncExtRepoADL
  @queue = 'sync_ext_repo'

  @git_dir = '/tmp/adl_data'

  def self.perform(repo_id)
    Resque.logger.debug "Starting ADL sync"
    repo = Administration::ExternalRepository[repo_id]
    repo.clear_sync_messages
    repo.add_sync_message("Starting ADL sync")
    proccessed_files = 0
    updated_files = 0
    added_files = 0
    new_instances = 0

    if repo.sync_status == 'NEW'
      repo.add_sync_message("Cloning new git repository")
      success = SyncExtRepoADL.clone(repo)
    else
      repo.add_sync_message("Updating git repository")
      success = SyncExtRepoADL.update(repo)
    end

    if (success)
      repo.add_sync_message('Git update success')

      adl_activity = Administration::Activity.find(repo.activity)

      Dir.glob("#{@git_dir}/*/*.xml").each do |fname|
        Resque.logger.debug "file #{fname}"
        proccessed_files = proccessed_files+1
        cf = ContentFile.find_by_original_filename(Pathname.new(fname).basename.to_s)
        unless cf.nil?
          Resque.logger.debug("Updating existing file #{fname}")
          if cf.update_tech_metadata_for_external_file
            if cf.save
              updated_files=updated_files+1
              repo.add_sync_message("Updated file #{fname}")
            else
              repo.add_sync_message("Failed to update file #{fname}: #{cf.errors.messages}")
            end
          end
        else
          begin
            doc = Nokogiri::XML(File.open(fname))

            raise "file has no TEI header" unless (doc.xpath("//xmlns:teiHeader/xmlns:fileDesc").size > 0)

            id = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:publicationStmt/xmlns:idno").text
            Resque.logger.debug ("  ID is #{id}")
            sysno = nil
            volno = nil
            unless id.blank?
              sysno = id.split(":")[0]
              volno = id.split(":")[1]
              Resque.logger.debug " sysno #{sysno} vol #{volno}"
            end

            i = nil
            i = find_instance(sysno) unless sysno.blank? || sysno == '000000000'
            if (i.nil?)
              i = create_new_work_and_instance(sysno,doc,adl_activity)
              new_instances=new_instances+1
              repo.add_sync_message("Created new Work and Instans for '#{i.work.first.display_value}'")
            else
              repo.add_sync_message("Found existing Instance for '#{i.work.first.display_value}'")
            end
            cf = add_contentfile_to_instance(fname,i) unless i.nil?
            added_files=added_files+1
            repo.add_sync_message("Added #{fname}")
          rescue Exception => e
            Resque.logger.warn "Skipping file"
            Resque.logger.warn e.message
            Resque.logger.warn e.backtrace.join("\n")
            repo.add_sync_message("Skipping file #{fname} : #{e.message}")
          end
        end
      end
    else
      repo.add_sync_message('Git update failed.')
      repo.sync_status = 'FAILED'
    end
    repo.sync_status = 'SUCCESS'
    repo.sync_date = DateTime.now.to_s
    repo.add_sync_message('----------------------------------')
    repo.add_sync_message("Number of processed files #{proccessed_files}")
    repo.add_sync_message("Number of updated files #{updated_files}")
    repo.add_sync_message("Number of new files #{added_files}")
    repo.add_sync_message("Number of new works and instances #{new_instances}")
    repo.add_sync_message('----------------------------------')
    repo.add_sync_message('ADL sync finished')
    repo.save
  end


  private
  def self.clone(repo)
    cmd = "git clone #{repo.url} #{@git_dir}; cd #{@git_dir}; git fetch; git checkout #{repo.branch}"
    success = false
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        repo.add_sync_message(line)
      end
      repo.add_sync_message(stderr.read)
      exit_status = wait_thr.value
      success = exit_status.success?
    end
    success
  end

  def self.update(repo)
    cmd = "cd #{@git_dir};git checkout -f #{repo.branch};git pull"
    success = false
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        repo.add_sync_message(line)
      end
      repo.add_sync_message(stderr.read)
      exit_status = wait_thr.value
      success = exit_status.success?
    end
    success
  end


  def self.find_instance(sysno)
    result = ActiveFedora::SolrService.query('system_number_tesim:"'+sysno+'" && active_fedora_model_ssi:Instance')
    if (result.size > 0)
      Instance.find(result[0]['id'])
    else
      nil
    end
  end

  def self.create_new_work_and_instance(sysno,doc,adl_activity)
    Resque.logger.debug "Creating new work"
    w = Work.new
    doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title").each do |n|
      title = n.text
      titleized_title = title.mb_chars.titleize.wrapped_string
      w.add_title(value: titleized_title)
    end

    doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").each do |n|
      unless doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").text.blank?
        names = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").text
        # Convert the names to title case in an encoding safe manner
        # e.g. JEPPE AAKJÆR becomes Jeppe Aakjær
        titleized_names = names.mb_chars.titleize.wrapped_string.split(' ')
        surname = titleized_names.pop
        forename = titleized_names.join(' ')
        p = Authority::Person.find_or_create_person(forename,surname)
        w.add_author(p)
      end
    end
    unless w.save
      raise "Error saving work #{w.errors.messages}"
    end

    Resque.logger.debug "Creating new instance"
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
      w.delete
      raise "unable to create instance #{i.errors.messages}"
    end
    i
  end

  def self.add_contentfile_to_instance(fname,i)
    cf = i.add_file(fname,["RelaxedTei"])
    raise "unable to add file: #{cf.errors.messages}" unless cf.errors.blank?
    raise "unable to add file: #{i.errors.messages}" unless i.save
  end
end