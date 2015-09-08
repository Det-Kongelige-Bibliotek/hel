namespace :valhal do
  desc 'Run FITS for the content files, which does not have fits already'
  task fits: :environment do
    ContentFile.all.each do |cf|
      puts "Running FITS on #{cf.id}"
      Resque.enqueue(FitsCharacterizingJob,cf.id) if cf.fitsMetadata.content.nil?
    end
  end

  desc 'Run FITS for all content files'
  task fits_all: :environment do
    ContentFile.all.each do |cf|
      puts "Running FITS on #{cf.id}"
      Resque.enqueue(FitsCharacterizingJob,cf.id)
    end
  end

  desc 'Extract the techMetadata fields from the FITS datastream (does not recharacterize the file with FITS, only re-extracts).'
  task fits_reextract: :environment do
    ContentFile.all.each do |cf|
      puts "Reextracted techMetadata for file #{cf.uuid}: #{cf.extract_techMetadata_from_fits_datastream ? 'success' : 'failure'}"
    end
  end
end
