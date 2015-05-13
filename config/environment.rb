# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

require 'resque'

def initialize_listener_jobs
  #puts "Enqueueing ReceivePreservationResponseJob"
  Resque.enqueue(ReceivePreservationResponseJob)
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      puts "Forked"
      # We’re in a smart spawning mode
      # Now is a good time to connect to RabbitMQ
      initialize_listener_jobs
    end
  end
else
  if Rails.env.upcase != 'TEST'
    puts "not PhusionPassenger"
    initialize_listener_jobs
  end
  # We're in direct spawning mode. We don't need to do anything.
end
