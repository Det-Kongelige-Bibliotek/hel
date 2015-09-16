# -*- coding: utf-8 -*-
require 'resque'
require 'open3'

class SyncExtRepoADL
  @queue = 'sync_ext_repo'

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
      success = repo.clone
    else
      repo.add_sync_message("Updating git repository")
      success = repo.update
    end

    if (success)
      repo.add_sync_message('Git update success')

      adl_activity = Administration::Activity.find(repo.activity)

      Dir.glob("#{repo.base_dir}/*/*.xml").each do |fname|
        Resque.logger.debug "file #{fname}"
        proccessed_files = proccessed_files+1
        cf = ContentFile.find_by_original_filename(Pathname.new(fname).basename.to_s)
        unless cf.nil?
          Resque.logger.debug("Updating existing file #{fname}")
          if cf.update_tech_metadata_for_external_file
            if cf.save
              updated_files=updated_files+1
              repo.add_sync_message("Updated file #{fname}")
              Resque.enqueue(AddAdlImageFiles,cf.id,repo.image_dir,true)
            else
              repo.add_sync_message("Failed to update file #{fname}: #{cf.errors.messages}")
            end
          end
        else
          begin
            doc = Nokogiri::XML(File.open(fname))
            validator = Validator::RelaxedTei.new
            Resque.logger.debug("Validating TEI")
            msg = validator.is_valid_xml_doc(doc)
            raise "#{fname} is not valid TEI: #{msg}" unless msg.blank?
            Resque.logger.debug("is valid")

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

            i = create_new_work_and_instance(sysno,doc,adl_activity,repo_id)
            new_instances=new_instances+1
            repo.add_sync_message("Created new Work and Instans for '#{i.work.display_value}'")

            cf = add_contentfile_to_instance(fname,i) unless i.nil?
            added_files=added_files+1
            repo.add_sync_message("Added #{fname}")
            Resque.enqueue(AddAdlImageFiles,cf.id,repo.image_dir)
          rescue Exception => e
            Resque.logger.warn "Skipping file #{fname} : #{e.message}"
            Resque.logger.debug "#{e.backtrace.join("\n")}"
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
      Instance.where(result[0]['id'])
    else
      nil
    end
  end

  def self.create_new_work_and_instance(sysno,doc,adl_activity,repo_id=nil)
    Resque.logger.debug "Creating new work"
    w = Work.new
    unless sysno.blank? || sysno == '000000000'
      doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:sourceDesc/xmlns:bibl/xmlns:title").each do |n|
        title = n.text
        titleized_title = title.mb_chars.titleize.wrapped_string
        w.add_title(value: titleized_title)
      end
    else
      doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title").each do |n|
        title = n.text
        titleized_title = title.mb_chars.titleize.wrapped_string
        w.add_title(value: titleized_title)
      end
    end

    authors_found = false
    doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:sourceDesc/xmlns:bibl/xmlns:author").each do |n|
      surname = n.xpath("//xmlns:surname").text.mb_chars.titleize.to_s
      forename = n.xpath("//xmlns:forename").text.mb_chars.titleize.to_s
      p = Authority::Person.find_or_create_person(forename,surname)
      w.add_author(p)
      authors_found = true
    end
    # if no author in source desc/bibl is found look in filedesc
    unless authors_found
      doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:author").each do |n|
        names = n.text
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
    i.work=w

    pub_place = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:sourceDesc/xmlns:bibl/xmlns:pubPlace").text
    pub_name = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:sourceDesc/xmlns:bibl/xmlns:publisher").text
    pub_date = doc.xpath("//xmlns:teiHeader/xmlns:fileDesc/xmlns:sourceDesc/xmlns:bibl/xmlns:date").text
    unless pub_name.blank?
      org = Authority::Organization.find_or_create_organization(pub_name,pub_place)
      i.add_publisher(org)
    end

    if pub_date.present?
      unless EDTF.parse(pub_date).nil?
        i.add_published_date(pub_date)
      else
        Resque.logger.debug "publication date #{pub_date} is not valid EDTF - not ADDED"
      end
    end
    i.system_number = sysno
    i.activity = adl_activity.id
    i.copyright = adl_activity.copyright
    i.collection = adl_activity.collection
    i.preservation_collection = adl_activity.preservation_collection
    i.type = 'TEI'
    i.external_repository = repo_id

    unless i.save
      w.delete
      raise "unable to create instance #{i.errors.messages}"
    end
    Resque.logger.debug "instance created #{i}"
    w.reload
    w.update_index
    i
  end

  def self.add_contentfile_to_instance(fname,i)
    cf = i.add_file(fname,["RelaxedTei"],false)
    raise "unable to add file: #{cf.errors.messages}" unless cf.errors.blank?
    raise "unable to add file: #{i.errors.messages}" unless i.save
    cf
  end

  def self.find_person_from_string(name)
    results = ActiveFedora::SolrService.query("display_value_tesim:#{name.gsub!(" ","+")} && active_fedora_model_ssi:Authority*Person")
    id = ''
    id = results.first[:id] if results.size > 0
    id
  end
end
