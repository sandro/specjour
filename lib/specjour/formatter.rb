module Specjour
  class Formatter
    require 'json'
    # description, status [pending,failed,passed] file_path, line_number, exception => [class, message, backtrace]

    STATUS_CHARS = Hash.new("?").merge!(
      passed: ".",
      failed: "F",
      error: "E",
      pending: "P",
      other: "?"
    )

    attr_reader \
      :error_count,
      :examples,
      :fail_count,
      :failures,
      :pass_count

    def initialize
      @examples = []
      @failures = []
      @pass_count, @fail_count, @error_count = 0
    end

    def add_example(example)
      print(example)
      examples << example
    end

    def print(example)
      $stdout.print STATUS_CHARS[example['status']]
    end

    def print_failures
      failures.each do |example|
        exception = example["exception"]
        puts "FAILURE: #{example["description"]}"
        puts "#{exception["class"]}: #{exception["message"]}"
        puts exception["bracktrace"]
        puts
      end
    end

    def print_exceptions

    end

    def print_summary
      puts "\nRan #{examples.size}"
      puts "Passed: #{pass_count} Failed: #{fail_count} Errors: #{error_count}"
    end
  end
end
