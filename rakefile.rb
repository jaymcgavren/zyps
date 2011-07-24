require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts = "--exclude spec,gems\/"
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.title = "Zyps"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
