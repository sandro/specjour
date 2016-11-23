module Specjour
  class Formatter
    require 'json'
    include Colors
    # description, status [pending,failed,passed] file_path, line_number, exception => [class, message, backtrace]

    STATUSES = Hash.new({char: "?", color: :white}).merge!(
      "passed" => {char: ".", color: :green},
      "failed" => {char: "F", color: :red},
      "error" => {char: "E", color: :magenta},
      "pending" => {char: "P", color: :yellow},
      "other" => {char: "O", color: :white}
    )

    attr_accessor \
      :error_count,
      :fail_count,
      :failures,
      :output,
      :pass_count,
      :pending_count,
      :start_time,
      :end_time,
      :tests

    def initialize(output=$stdout)
      @output = output
      @tests = []
      @failures = []
      @pass_count, @pending_count, @fail_count, @error_count = 0, 0, 0, 0
      @start_time = Time.now
    end

    def print(test)
      if test["status"] == "failed"
        @output.puts
        print_failure(test, fail_count)
      else
        status_format = STATUSES[test['status']]
        @output.print colorize(status_format[:char], status_format[:color])
      end
    end

    def print_failures
      @output.puts "Failures:\n\n"
      failures.each_with_index do |test, index|
        print_failure(test, index)
      end
    end

    def print_failure(test, index)
      exception = test["exception"]
      num = index + 1
      worker = "#{test["hostname"]}[#{test["worker_number"]}]"
      @output.puts colorize("#{num}. #{worker}", :red)
      description = colorize("#{test["description"]}", :red)
      @output.printf "%#{num.to_s.size + 2 + description.size}s\n" % description
      message = colorize("#{exception["class"]}: #{exception["message"]}", :red)
      @output.printf "%#{num.to_s.size + 2 + message.size}s\n" % message
      @output.puts format_backtrace(exception["backtrace"])
      @output.puts
    end

    def format_backtrace(backtrace)
      backtrace = Array(backtrace)
      if Specjour.configuration.full_backtrace
        backtrace
      else
        backtrace.reject {|l| Specjour.configuration.backtrace_exclusion_pattern =~ l}
      end
    end

    def failing_test_paths
      failures.map do |f|
        "#{f["file_path"]}:#{f["line_number"]}"
      end.uniq
    end


    def print_counts
      @output.puts colorize("Pending: #{pending_count}", :yellow)
      @output.puts colorize("Errors: #{error_count}", :magenta)
      @output.puts colorize("Passed: #{pass_count}", :green)
      @output.puts colorize("Failed: #{fail_count}", :red)
    end

    def execution_time
      Time.new(2000,1,1,0,0,0,0) + (end_time - start_time)
    end

    def print_overview
      overall_color = fail_count == 0 ? :green : :red
      @output.puts colorize("\nRan: #{tests.size} tests in #{execution_time.strftime("%Mm:%Ss:%Lms")}", overall_color)
    end

    def print_summary
      @output.puts "\n\n"
      print_failures if failures.any?
      print_counts
      print_overview
      @output.puts "\n"
    end

    def report_test(test)
      print(test)
      tests << test
      case test['status']
      when "passed"
        @pass_count += 1
      when "failed"
        @fail_count += 1
        failures << test
      when "error"
        @error_count += 1
      when "pending"
        @pending_count += 1
      end
    end

    def set_end_time!
      @end_time = Time.now
    end

    def exit_status
      failures.any? ? 1 : 0
    end

  end
end
__END__
Pending:
  Specjour pends as an example
    # No reason given
    # ./spec/specjour_spec.rb:25

Failures:

  1) Specjour fails as an example
     Failure/Error: raise CustomException, 'fails'
     CustomException:
       fails
     # ./spec/specjour_spec.rb:7:in `boo'
     # ./spec/specjour_spec.rb:30:in `block (2 levels) in <top (required)>'

Finished in 0.00297 seconds
14 examples, 1 failure, 1 pending

Failed examples:

rspec ./spec/specjour_spec.rb:29 # Specjour fails as an example
