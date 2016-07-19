module Specjour
  class Formatter
    require 'json'
    include Colors
    BACKTRACE_REGEX = Regexp.new(File.dirname(__FILE__))
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
      :tests

    def initialize(output=$stdout)
      @output = output
      @tests = []
      @failures = []
      @pass_count, @pending_count, @fail_count, @error_count = 0, 0, 0, 0
      @start_time = Time.now
    end

    def print(test)
      status = STATUSES[test['status']]
      @output.print colorize(status[:char], status[:color])
    end

    def print_failures
      @output.puts "Failures:\n\n"
      failures.each_with_index do |test, index|
        exception = test["exception"]
        num = index + 1
        @output.puts colorize("#{num}) #{test["description"]}", :red)
        message = colorize("#{exception["class"]}: #{exception["message"]}", :red)
        @output.printf "%#{num.to_s.size + 2 + message.size}s\n" % message
        cleaned_backtrace = exception["backtrace"].reject {|l| BACKTRACE_REGEX.match(l)}
        @output.puts cleaned_backtrace
        @output.puts
      end
    end

    def print_rerun
      files = failures.map do |f|
        "#{f["file_path"]}:#{f["line_number"]}"
      end.uniq
      cmd = colorize("rspec #{files.join(" ")}", :red)
      @output.puts %(
Rerun failures with this command:

#{cmd}
      )
    end

    def print_summary
      end_time = Time.now
      @output.puts "\n\n"
      print_failures if failures.any?

      @output.puts colorize("Pending: #{pending_count}", :yellow)
      @output.puts colorize("Errors: #{error_count}", :magenta)
      @output.puts colorize("Passed: #{pass_count}", :green)
      @output.puts colorize("Failed: #{fail_count}", :red)

      overall_color = fail_count == 0 ? :green : :red
      overall_time = Time.new(0,1,1) + (end_time - @start_time)
      @output.puts colorize("\nRan: #{tests.size} tests in #{overall_time.strftime("%Mm:%Ss:%Lms")}", overall_color)

      @output.puts "\n\n"
      print_rerun if failures.any?
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

    def exit_status
      exit failures.any? ? 1 : 0
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
