class Specjour::RSpec::Preloader
  def self.load(spec_file)
    $LOAD_PATH.unshift File.join(Dir.pwd, 'spec')
    require spec_file
  ensure
    $LOAD_PATH.shift
  end
end
