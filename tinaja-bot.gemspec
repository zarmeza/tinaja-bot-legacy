# frozen_string_literal: true

require File.expand_path('lib/tinaja-bot/version', __dir__)

Gem::Specification.new do |s|
  s.name = 'tinaja-bot'
  s.version = TinajaBot::VERSION
  s.executables << 'tinaja-bot'
  s.summary               = 'A bot for TINAJA Ingeniería Discord server'
  s.description           = 'A bot for TINAJA Ingeniería Discord server'
  s.authors               = ['Eleazar Meza']
  s.email                 = 'meza.eleazar@gmail.com'
  s.homepage              = 'https://github.com/elshaka/tinaja-bot'
  s.license               = 'MIT'
  s.files = Dir['README.md', 'LICENSE',
                'CHANGELOG.md', 'lib/**/*.rb',
                'lib/**/*.rake',
                'tinaja-bot.gemspec',
                'Gemfile', 'Rakefile']
  s.extra_rdoc_files = ['README.md']

  s.required_ruby_version = '~> 3.3'
  s.add_dependency 'discordrb', '~> 3.5'
  s.add_dependency 'httparty', '~> 0.22.0'
  s.add_dependency 'watir', '~> 7.3'
  s.metadata['rubygems_mfa_required'] = 'true'
end
