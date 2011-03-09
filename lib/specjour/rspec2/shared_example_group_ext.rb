RSpec::Core::SharedExampleGroup.class_eval do

  def ensure_shared_example_group_name_not_taken(name)
    if RSpec.world.shared_example_groups.has_key?(name)
      Specjour.logger.debug "Shared example group '#{name}' already exists"
    end
  end

end
