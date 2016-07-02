# encoding: utf-8

require File.expand_path('../lib/diftw/version.rb', __FILE__)
Gem::Specification.new do |gem|
  gem.name = 'diftw'
  gem.version = DiFtw::VERSION
  gem.date = '2016-06-29'

  gem.description = 'A small dependency injection library for Ruby'
  gem.summary = 'Dependency Injection For The Win!'
  gem.homepage = 'https://github.com/jhollinger/ruby-diftw'

  gem.authors = ['Jordan Hollinger']
  gem.email = 'jordan.hollinger@gmail.com'

  gem.license = 'MIT'

  gem.files = Dir['lib/**/**'] + ['README.md', 'LICENSE']

  gem.required_ruby_version = '>= 2.0.0'
end
