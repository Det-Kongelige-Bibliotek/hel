require 'resque'
require 'redis'
require 'pathname'

class EmailCreateAttachmentJob

  @queue = :email_create_attachment

  # Creates Valhal attachment related objects
  # @param corresponding_email_dir_path: the complete path of the corresponding email
  # @param email_dir_name: the name of the folder in which the emails are contained
  # @param attachment_dir_name: the name of the folder in which the attachments are contained
  # @param dirsWorks: Hash map containing pairs of paths to folders and their associated works
  # @param email_work_id: ID of Work of an email containing attachments
  # @param email_work_path_without_suffix: Pathname of email file associated with email_work without suffix
  def self.perform(corresponding_email_dir_path, email_dir_name, attachment_dir_name,
      dirs_works, email_work_id, email_work_path_without_suffix)

    redis = Redis.new

    attachmentsFullPath = redis.hget(email_work_path_without_suffix, "attachmentsFullPath").to_s

    attachments_text = redis.hget(email_work_path_without_suffix, "attachmentsFileNames").to_s

    attachments_lines = attachments_text.split("\n").reject(&:blank?)

    attachments_lines.each do |attachment|

      attachment_names = attachment.split("\t")

      attachment_current_path = attachment_names[0]

      attachment_current_name = attachment_current_path.sub(attachmentsFullPath,"")

      attach_dir_path = corresponding_email_dir_path.sub(email_dir_name.to_s, attachment_dir_name.to_s)
      pathname_attachment_file = Pathname(attach_dir_path).join(attachment_current_name)

      email_work = Work.find(email_work_id)

      work_attachment, dirs_works = EmailIngestJob.create_work(pathname_attachment_file, dirs_works,
                                                            email_work, email_work_path_without_suffix, nil)

      instance_attachment = EmailIngestJob.create_instance(pathname_attachment_file, work_attachment)

      if Rails.env == 'test'
        EmailCreateFileJob.perform(pathname_attachment_file.to_s, instance_attachment.id)
      else
        Resque.enqueue(EmailCreateFileJob, pathname_attachment_file.to_s, instance_attachment.id)
      end
      Resque.logger.info "Email ingest #{attachment.to_s} imported with id #{work_attachment.id}"
    end
  end
end
