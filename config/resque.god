rails_env   = ENV['RAILS_ENV']  || "production"
rails_root  = ENV['RAILS_ROOT'] || "/home/rails/current"
workers = ['sync_ext_repo','add_adl_images','fits_characterizing','dissemination','receive_preservation_response','import_from_preservation','send_to_preservation','validate_adl_tei_instance','email_ingest','email_create_email','email_create_attachment','email_create_file','letter_book_scan','letter_book_ingest']

workers.each do |worker|
  God.watch do |w|
    w.dir      = "#{rails_root}"
    w.name     = "resque-#{worker}"
    w.group    = 'resque'
    w.interval = 30.seconds
    w.env      = {"QUEUE"=>worker, "RAILS_ENV"=>rails_env, "PID_FILE"=>"#{rails_root}/pids/#{worker}.pid" }
    w.start    = "rake -f #{rails_root}/Rakefile environment resque:work"
    w.log      = "#{rails_root}/log/resque.log"
    w.err_log  = "#{rails_root}/log/resque_error.log"


    # restart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 350.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
