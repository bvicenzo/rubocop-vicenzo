# frozen_string_literal: true

require 'rubocop-vicenzo'
require 'rubocop/rspec/support'
require 'rubocop/rspec/shared_contexts/default_rspec_language_config_context'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed
  config.include_context 'with default RSpec/Language config', :rspec_config
end
