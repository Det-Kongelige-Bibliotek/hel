require 'resque'
require 'pathname'
require 'find'
require 'full-name-splitter'

# Adds folders/files from extracted email account as new ContentFiles, Instances, and Works,
class EmailIngestJob

  @queue = :email_ingest

  # Ingest individual emails into Valhal
  # @param base_dir_path: the name of the folder in which the emails, attachments, and metadata are contained
  # @param email_dir_name: the name of the folder from where to ingest emails
  # @param attachment_dir_name: the name of the folder in which the attachments are contained
  # @param export_file_name: name for Aid4Mail XML file
  # @param donor_id: Person id of the donor of the email account
  # @param work_id; Work id for parent work
  def self.perform(base_dir_path, email_dir_name, attachment_dir_name, export_file_name, donor_id, work_id)

    attachment_dir_name, email_dir_name, email_dir_path, export_file_path =
        initialize_validate(attachment_dir_name, base_dir_path, donor_id, work_id, email_dir_name, export_file_name)

    # Extract metadata from Aid4Mail XML file
    email_metadata = EmailXMLIngestService.email_xml_ingest(export_file_path, email_dir_path)

    dirs_works = Hash.new

    # A small hack to make the code nicer
    dirs_works[email_dir_path.to_s] = work_id

    # Traverse (in depth first order) the folders present in the email_dir_path and ingest files and folders
    Find.find(email_dir_path) do |path|
      pathname = Pathname.new(path)

      if File.directory?(pathname)
        begin
          if path != email_dir_path
            dirs_works = email_create_folder(pathname, email_metadata, dirs_works, donor_id)
          end
        rescue => e
          Resque.logger.error "A Valhal object for folder #{pathname} could not be created! Error inspect:
                              #{e.inspect}, Error backtrace:  #{e.backtrace.join("\n")}"
        end
      else
        if Rails.env == 'test'
          begin
          EmailCreateEmailJob.perform(pathname.to_s, email_dir_name.to_s, attachment_dir_name.to_s, email_metadata,
                                   dirs_works)
          rescue => e
            Resque.logger.error "A Valhal object for an email or an attachment could not be created! Error inspect:
                            #{e.inspect}, Error backtrace:  #{e.backtrace.join("\n")}"
            puts "A Valhal object for an email or an attachment could not be created! Error inspect:
                            #{e.inspect}, Error backtrace:  #{e.backtrace.join("\n")}"
          end
        else
          Resque.enqueue(EmailCreateEmailJob, pathname.to_s, email_dir_name.to_s, attachment_dir_name.to_s,
                         email_metadata, dirs_works)
        end
      end
    end
  end

  def self.initialize_validate(attachment_dir_name, base_dir_path, donor_id, work_id, email_dir_name, export_file_name)
    fail ArgumentError, 'A path, without trailing slash, to a folder containing data should be given' if base_dir_path.blank?

    fail ArgumentError, 'The folder containing data does not exist!' unless File.directory? base_dir_path

    fail ArgumentError, 'The Person id of the donor of the email account should be given' if donor_id.nil?

    fail ArgumentError, 'The work id of the for parent work should be given' if work_id.nil?

    if email_dir_name.blank?
      email_dir_name = EMAIL_DIR_NAME
    end

    if attachment_dir_name.blank?
      attachment_dir_name = EMAIL_ATTACHMENT_DIR_NAME
    end

    if export_file_name.blank?
      export_file_name = EMAIL_EXPORT_FILE_NAME
    end

    email_dir_path = base_dir_path + '/' + email_dir_name
    fail ArgumentError, 'The email folder does not exist!' unless File.directory? email_dir_path

    attachment_dir_path = base_dir_path + '/' + attachment_dir_name
    fail ArgumentError, 'The attachment folder does not exist!' unless File.directory? attachment_dir_path

    export_file_path = base_dir_path + '/' + export_file_name
    fail ArgumentError, 'The Aid4Mail export xml file does not exist!' unless File.file? export_file_path

    fail 'A MyArchive activity does not exist!' unless Administration::Activity.where(activity: 'MyArchive').size != 0
    return attachment_dir_name, email_dir_name, email_dir_path, export_file_path
  end

  # Creates Valhal folder related objects
  # @param folder_path: the complete path of the folder
  # @param email_metadata: a hash map containing email metadata for the complete email account
  # @param dirs_works: Hash map containing pairs of paths to folders and their associated works
  # @param donor_id: Person id of the donor of the email account
  def self.email_create_folder(folder_path, email_metadata, dirs_works, donor_id)

    work, dirs_works = create_work(folder_path, email_metadata, dirs_works, nil, nil, donor_id)

    instance = create_instance(folder_path, email_metadata, work)

    if Rails.env == 'test'
      EmailCreateFileJob.perform(folder_path.to_s, instance.id)
    else
      Resque.enqueue(EmailCreateFileJob, folder_path.to_s, instance.id)
    end

    Resque.logger.info "Email ingest #{folder_path.basename.to_s} imported with id #{work.id}"

    return dirs_works
  end

  # Creates a Work
  # @param pathname: the complete path of the folder or file for which a Work should be created
  # @param email_metadata: a hash map containing email metadata for the complete email account
  # @param dirs_works: Hash map containing pairs of paths to folders and their associated works
  # @param email_work: Work of an email containing attachments
  # @param email_work_path_without_suffix: Pathname of email file associated with email_work without suffix
  # @param donor_id: Person id of the donor of the email account
  def self.create_work(pathname, email_metadata, dirs_works, email_work, email_work_path_without_suffix, donor_id)

    @unknown = UNKNOWN_NAME

    work = Work.new

    ctime = File.ctime(pathname)
    ctime_iso8601 = ctime.iso8601

    if EDTF.parse(ctime_iso8601).nil?
      work.origin_date = UNKNOWN_EDTF_DATE
    else
      work.origin_date = ctime_iso8601.to_s
    end

    pathname_without_suffix =  pathname.to_s.chomp(File.extname(pathname.to_s))

    # A folder
    if File.directory?(pathname.to_s)
      work = create_folder_work(donor_id, pathname, work)
    end

    # An email
    if File.file?(pathname) && email_metadata.include?(pathname_without_suffix)
      work = create_email_work(email_metadata, pathname_without_suffix, work)
    end

    # An attachment
    if File.file?(pathname) &&  !email_work.nil? && email_metadata.include?(email_work_path_without_suffix) &&
        !email_metadata[email_work_path_without_suffix]["attachments"].empty?
      work = create_attachment_work(email_metadata, email_work, email_work_path_without_suffix, pathname, work)
    end

    fail "Work could not be saved #{work.errors.messages}" unless work.save

    # Work work relations
    parent_folder_path = File.expand_path('..', pathname)

    parent_folder_work = dirs_works[parent_folder_path]

    parent_work = nil
    if parent_folder_work.present?
      parent_work = Work.find(parent_folder_work)
    end

    if parent_work.present?
      work.is_part_of = parent_work
      parent_work.parts += [work]

      fail "Work could not be saved #{work.errors.messages}" unless parent_work.save
    end

    fail "Work could not be saved #{work.errors.messages}" unless work.save

    if !File.file?(pathname)
      dirs_works[pathname.to_s] = work.id
    end

    return work, dirs_works
  end

  def self.create_folder_work(donor_id, pathname, work)

    work.add_title({"value" => pathname.basename.to_s.chomp(File.extname(pathname.basename.to_s))})
    person_default = Authority::Person.find(donor_id)

    work.add_author(person_default)

    fail "Folder Work could not be saved #{work.errors.messages}" unless work.save
    return work
  end

  def self.create_email_work(email_metadata, pathname_without_suffix, work)

    # Subject
    work.add_title({"value" => email_metadata[pathname_without_suffix]["subject"].to_s})

    # From
    if !email_metadata[pathname_without_suffix]["fromName"].empty?
      from_name = email_metadata[pathname_without_suffix]["fromName"].to_s
      names = FullNameSplitter.split(from_name)
      forename = names[0]
      surname = names[1]
      person_from = Authority::Person.find_or_create_person(forename, surname)
      work.add_author(person_from)
    else
      person_from = Authority::Person.find_or_create_person(@unknown, @unknown)
      work.add_author(person_from)
    end

    # FromAddr
    if !email_metadata[pathname_without_suffix]["fromAddr"].empty?
      from_addr = email_metadata[pathname_without_suffix]["fromAddr"].to_s
      person_from.email += [from_addr]
      person_from.save
    else
      person_from.email += [@unknown]
      person_from.save
    end

    # TO
    if !email_metadata[pathname_without_suffix]["to"].empty?
      to = email_metadata[pathname_without_suffix]["to"].to_s
      work = add_email_recipients(to, work)
    else
      person_to = Authority::Person.find_or_create_person(@unknown, @unknown)
      work.add_recipient(person_to)
    end

    # CC
    if !email_metadata[pathname_without_suffix]["cc"].empty?
      cc = email_metadata[pathname_without_suffix]["cc"].to_s
      work = add_email_recipients(cc, work)
    end

    # BCC
    if !email_metadata[pathname_without_suffix]["bcc"].empty?
      bcc = email_metadata[pathname_without_suffix]["bcc"].to_s
      work = add_email_recipients(bcc, work)
    end

    fail "Email Work could not be saved #{work.errors.messages}" unless work.save
    return work
  end

  def self.create_attachment_work(email_metadata, email_work, email_work_path_without_suffix, pathname, work)
    work.add_title({"value" => pathname.basename.to_s.chomp(File.extname(pathname.basename.to_s))})

    # From
    if !email_metadata[email_work_path_without_suffix]["fromName"].empty?
      from_name = email_metadata[email_work_path_without_suffix]["fromName"].to_s
      names = FullNameSplitter.split(from_name)
      forename = names[0]
      surname = names[1]
      person_from = Authority::Person.find_or_create_person(forename, surname)
      work.add_author(person_from)
    else
      person_from = Authority::Person.find_or_create_person(@unknown, @unknown)
      work.add_author(person_from)
    end

    fail "Attachment Work could not be saved #{work.errors.messages}" unless work.save

    work.is_part_of = email_work
    email_work.parts += [work]

    fail "Attachment Work could not be saved #{work.errors.messages}" unless work.save

    fail "Email Work related to attachment Work could not be saved #{email_work.errors.messages}" unless email_work.save

    return work
  end

  # Creates a Instance
  # @param pathname: the complete path of the folder or file for which a Instance should be created
  # @param email_metadata: a hash map containing email metadata for the complete email account
  # @param work: the associated work
  def self.create_instance(pathname, email_metadata, work)

    instance = Instance.new

    activity = Administration::Activity.where(activity: 'MyArchive').first
    fail 'Activity MyArchive is not defined!' unless activity.present?

    instance.set_work = work

    # Instance note == email body in plain text
    pathname_without_suffix =  pathname.to_s.chomp(File.extname(pathname.to_s))

    if email_metadata.has_key?(pathname_without_suffix)
      if !email_metadata[pathname_without_suffix]["body"].empty?
        body = email_metadata[pathname_without_suffix]["body"].to_s
        instance.note = body
      end
    end

    instance.activity = activity.id
    instance.embargo = activity.embargo
    instance.embargo_date = activity.embargo_date
    instance.embargo_condition = activity.embargo_condition
    instance.access_condition = activity.access_condition
    instance.copyright = activity.copyright
    instance.availability = activity.availability
    instance.collection = activity.collection
    instance.copyright_status = activity.copyright_status

    instance.preservation_collection = activity.preservation_collection

    instance.type = 'Email'

    fail "Instance could not be saved #{instance.errors.messages}" unless instance.save
    return instance
  end

  # Adds email recipients relations between a Person and a Work
  # @param recipients: the email recipients
  # @param work: the associated work
  def self.add_email_recipients(recipients, work)

    recipient_lines = recipients.split("\n").reject(&:blank?)

    recipient_lines.each do |recipient|
      name, email = split_name_email(recipient)

      if name.empty?
        person = Authority::Person.where(:email => email).first
        if person.nil?
          person = Authority::Person.find_or_create_person(@unknown, @unknown)
        end
      else
        names = FullNameSplitter.split(name)
        forename = names[0]
        surname = names[1]
        person = Authority::Person.find_or_create_person(forename, surname)
      end
      work.add_recipient(person)
      person.email += [email]

      fail "Person could not be saved #{person.errors.messages}" unless person.save
    end

    return work
  end

  # Given a string containing a email recipients name and email address return the two as separate strings
  # @param recipients: the email recipient
  def self.split_name_email(recipient)

    values = recipient.split("<")

    name = values[0]
    if name.size > 0
      name.chop
    end

    email = values[1].split(">")[0]

    return name, email
  end
end
