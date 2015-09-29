class MixedMaterial < Work
  accepts_nested_attributes_for :instances

  # This is a horrible hack - there is some bug in AF that causes a crash
  # when we save the files as part of the creation procedure.
  # This works around the issue.

  after_save :update_files

  def content_files=(files)
    @files = files
  end

  def update_files
    if @files.present?
      instances.first.update(content_files: @files)
    end
  end
end