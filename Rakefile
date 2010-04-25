require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "housefire"
    gem.summary = %Q{Send ticket notifications to Campfire}
    gem.description = %Q{Inspired by http://github.com/blog/609-tracking-deploys-with-compare-view}
    gem.email = "dave@wegoto12.com"
    gem.homepage = "http://github.com/dbgrandi/housefire"
    gem.authors = ["dbgrandi"]
    gem.files = FileList['[A-Z]*',
      'generators/**/*.*',
      'lib/**/*.rb',
      'lib/templates/*.erb']
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_dependency('broach', '>= 0.1.4')
    gem.add_dependency('nokogiri' ,'>= 0')
    gem.add_dependency('sanitize' ,'>= 0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Housefire #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

