class LetterBookScan

  @queue = :letter_book_scan

  def self.perform(incomming_path,processed_path,img_base_path)
    Dir.glob("#{incomming_path}/*.xml").each do |xml_path|
      basename = File.basename(xml_path).to_s
      sysnum = basename.to_s.split('_')[0]
      Resque.enqueue(LetterBookIngest,xml_path,"#{img_base_path}/#{File.basename(xml_path,'.xml')}","#{processed_path}/#{basename}")
    end
  end
end
