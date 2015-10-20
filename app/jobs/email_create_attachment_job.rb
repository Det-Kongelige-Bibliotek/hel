require 'resque'
require 'pathname'

class EmailCreateAttachmentJob

  @queue = :email_create_attachment

  # Creates Valhal attachment related objects
  # @param corresponding_email_dir_path: the complete path of the corresponding email
  # @param email_dir_name: the name of the folder in which the emails are contained
  # @param attachment_dir_name: the name of the folder in which the attachments are contained
  # @param email_metadata: a hash map containing email metadata for the complete email account
  # @param dirsWorks: Hash map containing pairs of paths to folders and their associated works
  # @param email_work_id: ID of Work of an email containing attachments
  # @param email_work_path_without_suffix: Pathname of email file associated with email_work without suffix
  def self.perform(corresponding_email_dir_path, email_dir_name, attachment_dir_name,
      email_metadata, dirs_works, email_work_id, email_work_path_without_suffix)

    attachments_text = email_metadata[email_work_path_without_suffix]["attachments"].to_s

    attachments_lines = attachments_text.split("\n").reject(&:blank?)

    attachments_lines.each do |attachment|
      attach_dir_path = corresponding_email_dir_path.gsub(email_dir_name.to_s, attachment_dir_name.to_s)
      pathname_attachment_file = Pathname.new(attach_dir_path) + Pathname.new(attachment)

      email_work = Work.find(email_work_id)

      work_attachment, dirs_works = EmailIngestJob.create_work(pathname_attachment_file, email_metadata, dirs_works,
                                                            email_work, email_work_path_without_suffix, nil, nil)

      instance_attachment = EmailIngestJob.create_instance(pathname_attachment_file, email_metadata, work_attachment)

      if Rails.env == 'test'
        EmailCreateFileJob.perform(pathname_attachment_file.to_s, instance_attachment.id)
      else
        Resque.enqueue(EmailCreateFileJob, pathname_attachment_file.to_s, instance_attachment.id)
      end
      Resque.logger.info "Email ingest #{attachment.to_s} imported with id #{work_attachment.id}"
    end
  end
end
