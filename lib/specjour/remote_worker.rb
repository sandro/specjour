# coding: utf-8
module Specjour

  class SrunrInstance
    include Logger

    attr_reader :session, :exec_channel, :data_channel
    attr_accessor :hostname
    OUT_FILE = "src/careful/srunr.stdout"
    NEXT_TEST_RE = /NEXT_TEST/

    def initialize
      @mutex = Mutex.new
      Specjour.trap_interrupt_with_exit
    end

    def connect(args)
      @session = Net::SSH.start(*args)
    end

    def start(initial_test, done_block, next_block)
      @read_channel = session.open_channel do |ch|
        buffer = StringIO.new "", "w+b"

        get_next_chunk = lambda do
          chunk = nil
          buffer.rewind
          start = buffer.gets
          # log "start is #{start.inspect} #{(buffer.size - buffer.pos)}"
          bytes = start && Integer(start) rescue nil
          if bytes && (buffer.size - buffer.pos) >= bytes
            chunk = buffer.read(bytes)
            # log "bytes #{bytes} chunk is #{chunk.inspect} #{chunk.bytesize} #{chunk.length}"
            rest = buffer.read
            # log "rest #{rest.inspect}"
            buffer.reopen(rest)
          end
          chunk
        end

        ch.on_data do |ch2, data|
          @mutex.synchronize do
            buffer.seek(buffer.size)
            buffer.write(data)
          end

          @mutex.synchronize do
            while chunk = get_next_chunk.call
              done_block.call(chunk)
            end
          end
        end
        ch.request_pty(:modes => { Net::SSH::Connection::Term::ONLCR => 0 }) do |ch2, success|
          ch2.exec("echo -n > #{OUT_FILE}; tail -f #{OUT_FILE}")
        end
      end
      # TODO: Can't use bundle exec here because srunr is in charge of getting the bundle up to date
      @exec_channel = session.exec("bash -l -c 'cd src/careful; xvfb-run -a -s \"-screen 0 1024x768x16\" srunr'") do |ch, stream_type, data|
        p ["stream type is", stream_type, ch.object_id, data]
        ch.on_data do |_, stream|
          p ["on data", stream, Thread.current.object_id]
          if stream =~ NEXT_TEST_RE
            next_test = next_block.call
            if next_test
              run_test(next_test)
            else
              log "No tests left #{ch.object_id} #{@exec_channel.object_id} #{@read_channel.object_id}"
              @read_channel.close
              @exec_channel.eof!
              @exec_channel.close
            end
          end
        end
      end
      register_hostname
      run_test(initial_test)
      @session.loop
    end

    def register_hostname
      @exec_channel.send_data("hostname #{hostname}\n")
    end

    def send_before_suite
      @exec_channel.send_data("before_suite\n")
    end

    def send_after_suite
      @exec_channel.send_data("after_suite\n")
    end

    def run_test(test)
      log("run_test #{test}")
      @exec_channel.send_data("run_test #{test}\n")
    end

  end

  class RemoteWorker
    require "net/ssh"
    require "open3"
    include Logger
    include SocketHelper

    attr_reader :number, :hostname, :ssh_options

    def initialize(opts={})
      @ssh_options = opts[:ssh_options]
      @hostname = ssh_options[0]
      ssh_options[2] ||= {}
      ssh_options[2][:paranoid] ||= false
      @number = opts[:number]
    end

    def start
      log "options #{ssh_options} #{Thread.current.object_id}"
      connection.ready hostname: hostname, worker_size: 1
      rsync_project
      runner = SrunrInstance.new
      runner.hostname = hostname
      runner.connect(ssh_options)
      next_test = connection.next_test
      if next_test
        done_block = lambda do |data|
          parsed = Marshal.load(data)
          connection.report_test(parsed)
        end
        next_block = lambda do
          connection.done
          connection.next_test
        end
        runner.start(next_test, done_block, next_block)
      end
      log "all done test received"

      Specjour.plugin_manager.send_task(:after_suite)

    rescue StandardError, ScriptError => e
      $stderr.puts "Remote Worker RESCUED #{e.class} '#{e.message}'"
      $stderr.puts e.backtrace
      connection.error(e)
    ensure
      remove_connection
    end

    def rsync_project
      ssh_cmd = "ssh -o StrictHostKeyChecking=no"
      command = %W(rsync --exclude tmp/ --exclude log/ --exclude public/assets/paperclip/ --exclude .git --exclude .bundle --exclude /cache --exclude /images_for_dewarp -z -a -e #{ssh_cmd} #{Dir.pwd} #{ssh_options[1]}@#{hostname}:src/)
      log("sending project #{command.join(" ")}")
      o, e, s = Open3.capture3(*command)
      if !s.success?
        raise "Rsync failed: stdout: #{o} stderr: #{e}"
      end
    end

  end
end
