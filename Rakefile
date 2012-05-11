# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'Tortilla'


begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "tortilla"
  gem.homepage = "http://github.com/fishstick/tortilla"
  gem.license = "MIT"
  gem.summary = %Q{TODO: one-line summary of your gem}
  gem.description = %Q{TODO: longer description of your gem}
  gem.email = "waffleface@gmail.com"
  gem.authors = ["Bart Menu"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

namespace :db  do
require 'test/db/setup.rb'
  desc "Reset DB"
  task :reset do

	TortillaDB.instance.setup.reset
  end


desc "another db thing"
task :seed do
       TortillaDB.instance.setup.seed
end
end
