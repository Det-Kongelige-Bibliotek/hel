require 'resque'
require 'pathname'

class EmailCreateEmailJob
  @queue = :email_create_email

  # Create Valhal email related objects
  # @param email_path: the complete path of the email
  # @param email_dir_name: the name of the folder in which the emails are contained
  # @param attachment_dir_name: the name of the folder in which the attachments are contained
  # @param emailMD: a hash map containing email metadata for the complete email account
  # @param dirsWorks: Hash map containing pairs of paths to folders and their associated works
  def self.perform(email_path, email_dir_name, attachment_dir_name, email_metadata, dirs_works)

    email_path = Pathname.new(email_path)

    work, dirs_works = EmailIngestJob.create_work(email_path, email_metadata, dirs_works, nil, nil, nil, nil)

    @pathname_without_suffix =  email_path.to_s.chomp(File.extname(email_path.to_s))

    # Given that the email has attachments Valhal objects are created for these
    if email_metadata.include?(@pathname_without_suffix) &&
        !email_metadata[@pathname_without_suffix]["attachments"].empty?
      corresponding_email_dir_path = File.dirname(email_path)

      if Rails.env == 'test'
        EmailCreateAttachmentJob.perform(corresponding_email_dir_path.to_s, email_dir_name.to_s, attachment_dir_name.to_s,
                                      email_metadata, dirs_works, work.id, @pathname_without_suffix)
      else
        Resque.enqueue(EmailCreateAttachmentJob, corresponding_email_dir_path.to_s, email_dir_name.to_s,
                       attachment_dir_name.to_s, email_metadata, dirs_works, work.id, @pathname_without_suffix)
      end
    end

    instance = EmailIngestJob.create_instance(email_path, email_metadata, work)

    if Rails.env == 'test'
      EmailCreateFileJob.perform(email_path.to_s, instance.id)
    else
      Resque.enqueue(EmailCreateFileJob, email_path.to_s, instance.id)
    end

    Resque.logger.info "Email ingest #{email_path.basename.to_s} imported with id #{work.id}"
  end
end
