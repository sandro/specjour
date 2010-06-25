class Specjour::Rspec::Preloader
  def self.load(spec_file)
    argv_dup = ARGV
    ARGV.replace []
    $LOAD_PATH.unshift File.join(Dir.pwd, 'spec')
    require spec_file
  ensure
    ARGV.replace argv_dup
    $LOAD_PATH.shift
  end
end
