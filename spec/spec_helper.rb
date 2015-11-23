RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # todo: might take a little work to make this setting apply
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  # config.disable_monkey_patching!

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
end
