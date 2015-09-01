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
end
