class LetterBookScan

  @queue = :letter_book_scan

  def self.perform(incomming_path,processed_path,img_base_path)
    Dir.glob("#{incomming_path}/*.xml").each do |xml_path|
      basename = File.basename(xml_path).to_s
      unless ContentFile.find_by_original_filename(basename).present?
        sysnum = basename.to_s.split('_')[0]
        Resque.enqueue(LetterBookIngest,xml_path,"#{img_base_path}/#{File.basename(xml_path,'.xml')}","#{processed_path}/#{basename}")
      else
        Resque.logger.warn "#{basname} allready ingested. Skipping it"
      end
    end
  end
end
