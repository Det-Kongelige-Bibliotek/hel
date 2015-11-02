require 'resque'
require 'resque/scheduler'

namespace :valhal do
  # Schedules resque jobs for receiving preservation responses.
  task schedule_preservation_receiver: :environment do
    polling_interval = MQ_CONFIG['preservation']['polling_interval_in_minutes']
    if polling_interval.nil? || polling_interval.to_i == 0
      puts 'Will not schedule ReceivePreservationResponseJob without a polling interval.'
    else
      Resque.enqueue_at(polling_interval.minutes, ReceiveResponsesFromPreservationJob)
    end
  end

  desc 'Save all object again'
  task save_everything: :environment do
    ActiveFedora::Base.all.each do |b|
      puts "Cannot save #{b.id}" unless b.save
    end
  end

  desc 'Change the preservation collection'
  task fix_preservation_collection: :environment do
    ActiveFedora::Base.all.each do |b|
      if b.respond_to? :preservation_collection
        b.preservation_collection = Nokogiri::XML.parse(b.preservationMetadata.content).xpath('fields/preservation_profile/text()').to_s if b.preservation_collection.blank?

        if b.preservation_collection == "eternity"
          b.preservation_collection = "A"
          puts "Cannot save #{b.id}" unless b.save
        end
        puts b.preservation_collection
      end
    end
  end
end
