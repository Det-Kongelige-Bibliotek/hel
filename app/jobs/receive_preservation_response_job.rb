require 'resque'

include MqListenerHelper

class ReceivePreservationResponseJob

  @queue = 'receive_preservation_response'

  def self.perform(repeat=true)
    if MQ_CONFIG['preservation']['response'].blank?
      Resque.logger.warn 'No preservation response queue defined -> Not listening'
      return
    end

    begin
      uri = MQ_CONFIG['mq_uri']
      conn = Bunny.new(uri)
      conn.start
      ch = conn.create_channel
      @messages = []

      subscribe_to_preservation(ch)

      # wait until no more messages is being handled.
      loop do
        sleep 10.seconds
        break if @messages.empty?
      end

      conn.close
    rescue Bunny::TCPConnectionFailed => e
      Resque.logger.warn 'Connection to RabbitMQ failed'
      Resque.logger.warn e.to_s
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
        @messages << "message#{@messages.size + 1}"
        type = metadata[:type] || metadata['type']
        if type == MQ_MESSAGE_TYPE_PRESERVATION_RESPONSE
          success = handle_preservation_response(JSON.parse(payload))
        else
          Resque.logger.warn "ERROR cannot handle message of type '#{type}'"
        end

        if success
          Resque.logger.info "Successfully handled the #{type} message: #{payload}"
        else
          Resque.logger.warn "Failed handling the #{type} message: #{payload}"
        end
      rescue => e
        Resque.logger.error "Failed trying to handle message: #{payload}\nCaught error: #{e}"
      ensure
        @messages.pop
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
      if Resque.peek(@queue).nil?
        Resque.enqueue_to(@queue, ReceivePreservationResponseJob)
      end
    end
  end
end