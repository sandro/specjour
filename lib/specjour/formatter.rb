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
      $stdout.print colorize(status[:char], status[:color])
    end

    def print_failures
      puts "Failures:\n\n"
      failures.each_with_index do |test, index|
        exception = test["exception"]
        puts "#{index+1}) #{test["description"]}"
        puts "   #{exception["class"]}: #{exception["message"]}"
        cleaned_backtrace = exception["backtrace"].reject {|l| BACKTRACE_REGEX.match(l)}
        puts cleaned_backtrace
        puts
      end
    end

    def print_rerun
      files = failures.map do |f|
        "#{f["file_path"]}:#{f["line_number"]}"
      end
      cmd = colorize("rspec #{files.join(" ")}", :red)
      puts %(
Rerun failures with this command:

#{cmd}
      )
    end

    def print_summary
      end_time = Time.now
      puts "\n\n"
      print_failures if failures.any?

      puts colorize("Pending: #{pending_count}", :yellow)
      puts colorize("Failed: #{fail_count}", :red)
      puts colorize("Errors: #{error_count}", :magenta)
      puts colorize("Passed: #{pass_count}", :green)

      overall_color = fail_count == 0 ? :green : :red
      overall_time = Time.new(0,1,1) + (end_time - @start_time)
      puts colorize("\nRan: #{tests.size} tests in #{overall_time.strftime("%Mm:%Ss:%Lms")}", overall_color)

      puts "\n\n"
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
