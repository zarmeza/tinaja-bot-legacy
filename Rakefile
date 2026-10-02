# frozen_string_literal: true

require 'rake'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)

task default: %i[spec rubocop]

task :run do
  require 'dotenv'
  Dotenv.load
  require_relative 'lib/tinaja_bot'

  bot = TinajaBot::Bot.new token: ENV.fetch('TOKEN', nil), client_id: ENV.fetch('CLIENT_ID', nil)
  bot.run
end
