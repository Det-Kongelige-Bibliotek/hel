# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!


#TODO put this in a resque job and use resque scheduler!!
include MqListenerHelper

# Connect to the RabbitMQ broker, and initialize the listeners
def initialize_listeners
  begin
    uri = MQ_CONFIG["mq_uri"]
    conn = Bunny.new(uri)
    conn.start
    ch = conn.create_channel

    subscribe_to_preservation(ch)
    conn.close
  rescue Bunny::TCPConnectionFailed => e
    puts 'Connection to RabbitMQ failed'
    puts e.to_s
  end
end

# Subscribing to the preservation response queue
# This is ignored, if the configuration is not set.
#@param channel The channel to the message broker.
def subscribe_to_preservation(channel)
  if MQ_CONFIG["preservation"]["response"].blank?
    puts 'No preservation response queue defined -> Not listening'
    return
  end

  destination = MQ_CONFIG["preservation"]["response"]
  q = channel.queue(destination, :durable => true)

  q.subscribe do |delivery_info, metadata, payload|
    begin
      puts "Received the following preservation response message: #{payload}"
      handle_preservation_response(JSON.parse(payload))
    rescue => e
      puts "Try to handle preservation response message: #{payload}\nCaught error: #{e}"
    end
  end
end

#This function starts the listener thread which will poll RabbitMQ at regular intervals set by the polling_interval
def start_listener_thread
  polling_interval = MQ_CONFIG['preservation']['polling_interval_in_minutes']
  puts "polling interval #{polling_interval}"
  return if polling_interval.to_i == 0
  puts "Starting listener treads"
  t = Thread.new do
    while true
      initialize_listeners
      puts "Going to sleep for #{polling_interval} minutes..."
      sleep polling_interval.minutes
    end
  end
  puts t.group.inspect
  puts "num_of_threads = #{t.group.list.size}"
  #I've read here: https://www.agileplannerapp.com/blog/building-agile-planner/rails-background-jobs-in-threads
  #that each thread started in a Rails app gets its own database connection so when the thread terminates we need
  #to close any database connections too.
  ActiveRecord::Base.connection.close
end


if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      puts "Forked"
      # We’re in a smart spawning mode
      # Now is a good time to connect to RabbitMQ
      start_listener_thread
    end
  end

else
  if Rails.env.upcase != 'TEST'
    puts "not PhusionPassenger"
    start_listener_thread
  end
  # We're in direct spawning mode. We don't need to do anything.
end
