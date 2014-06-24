# encoding: utf-8

require 'rubygems'
require 'bundler'
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
  gem.name = "active_service"
  gem.homepage = "http://github.com/zwelchcb/active_service"
  gem.license = "MIT"
  gem.summary = %Q{ActiveService is an object-relational mapper for web services.}
  gem.description = %Q{It facilitates the creation and use of business objects through a uniform interface similar to ActiveRecord. With ActiveRecord, objects are mapped to a database via SQL SELECT, INSERT, UPDATE, and DELETE statements. With ActiveService, objects are mapped to a resource via HTTP GET, POST, PUT and DELETE requests.}
  gem.email = "Zachary.Welch@careerbuilder.com"
  gem.authors = ["zwelchcb"]
  gem.add_dependency 'active_attr', '>=0'
  gem.add_dependency 'typhoeus', '0.6.7'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "active_service #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
