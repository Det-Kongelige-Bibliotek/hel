require 'resque'

include MqListenerHelper

class ReceivePreservationResponseJob

  @queue = 'receive_preservation_response'

  def self.perform(repeat=true)
    if MQ_CONFIG['preservation']['response'].blank?
      puts 'No preservation response queue defined -> Not listening'
      return
    end

    begin
      uri = MQ_CONFIG['mq_uri']
      conn = Bunny.new(uri)
      conn.start
      ch = conn.create_channel

      subscribe_to_preservation(ch)
      conn.close
    rescue Bunny::TCPConnectionFailed => e
      puts 'Connection to RabbitMQ failed'
      puts e.to_s
    ensure
      schedule_new_job if repeat
    end
  end

  # Subscribing to the preservation response queue
  # This is ignored, if the configuration is not set.
  #@param channel The channel to the message broker.
  def self.subscribe_to_preservation(channel)
    destination = MQ_CONFIG['preservation']['response']
    q = channel.queue(destination, :durable => true)

    q.subscribe do |delivery_info, metadata, payload|
      begin
        handle_preservation_response(JSON.parse(payload))
      rescue => e
        puts "Try to handle preservation response message: #{payload}\nCaught error: #{e}"
      end
    end
  end

  # Schedules a new Resque job for receiving preservation responses... unless the polling interval is not set.
  def self.schedule_new_job
    polling_interval = MQ_CONFIG['preservation']['polling_interval_in_minutes']
    if polling_interval.nil? || polling_interval.to_i == 0
      puts 'Will not schedule ReceivePreservationResponseJob without a polling interval.'
    else
      # Only add another, if the queue is empty/nil.
      if(Resque.peek(@queue).nil?)
        Resque.enqueue_at(polling_interval.minutes, ReceivePreservationResponseJob)
      end
    end
  end
end