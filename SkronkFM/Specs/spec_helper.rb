#
#  spec_helper.rb
#  RubyTesting
#
#  Created by John Sheets on 2/04/12.
#  Copyright 2012 FourFringe. All rights reserved.

require "rspec"

if defined?(MACRUBY_VERSION)
  # MacRuby
  framework 'Specs'
  puts "Running tests with MacRuby."
else
  # RubyCocoa
  build_dir = ENV["FRAMEWORK_PATH"] || "."
  specs_framework = File.join(build_dir, "Specs.framework")

  require 'osx/cocoa'

  puts "Linking to test framework: #{specs_framework}"
  puts "Specs.framework missing?..." unless File.exist?(specs_framework)

  OSX.require_framework specs_framework
  include OSX
  puts "Running tests with RubyCocoa."
end

#SPECS_DIR=File.expand_path(File.dirname(__FILE__))

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
#Dir["#{SPECS_DIR}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :spec
end

puts "Done loading config"
