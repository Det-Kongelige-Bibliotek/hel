# Validates input parameters and start email ingest job
class EmailIngestService

  # Initialize parameters for email ingest
  # @param epath: the path to the folder in which the emails, attachments, and metadata are contained
  # @param work: Work of the parent work
  def self.initialize(epath, work)
    @base_dir_path = epath
    @email_dir_name = EMAIL_DIR_NAME
    @attachment_dir_name = EMAIL_ATTACHMENT_DIR_NAME
    @export_file_name = EMAIL_EXPORT_FILE_NAME

    @person_id = work.related_agents('aut').first.id
    @work_id = work.id
  end

  # Validate parameters for email ingest
  def self.validate
    @errors = []

    if @base_dir_path.blank?
      @errors << [I18n.t('works.show.path_error')]
    end

    @email_dir_path = @base_dir_path + '/' + @email_dir_name
    unless File.directory? @email_dir_path
      @errors << [I18n.t('works.show.mail_path_error')]
    end

    @attachment_dir_path = @base_dir_path + '/' + @attachment_dir_name
    unless File.directory? @attachment_dir_path
      @errors << [I18n.t('works.show.attachment_path_error')]
    end

    @export_file_path = @base_dir_path + '/' + @export_file_name
    unless File.file? @export_file_path
      @errors << [I18n.t('works.show.export_path_error')]
    end

    unless Administration::Activity.where(activity: 'MyArchive').size != 0
      @errors << [I18n.t('works.show.myarchive_activity')]
    end

    return @errors.join(" ")
  end

  # Enqueue email ingest job
  def self.enqueue_email_ingest_job
    Resque.enqueue(EmailIngestJob, @base_dir_path, @email_dir_name, @attachment_dir_name, @export_file_name,
                   @person_id, @work_id)
  end
end