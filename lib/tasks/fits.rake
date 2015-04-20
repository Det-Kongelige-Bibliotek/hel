namespace :valhal do
  desc 'Run FITS for the content files, which does not have fits already'
  task fits: :environment do
    ContentFile.all.each do |cf|
      Resque.enqueue(FitsCharacterizingJob,cf.pid) if cf.fitsMetadata.content.nil?
    end
  end

  desc 'Run FITS for all content files'
  task fits_all: :environment do
    ContentFile.all.each do |cf|
      Resque.enqueue(FitsCharacterizingJob,cf.pid)
    end
  end
end
