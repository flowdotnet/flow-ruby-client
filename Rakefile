#require 'rubygems'
require 'rake'
require 'rake/testtask'

task :clean do
end

desc "Generate documentation"
task :doc do
  sh "yard doc #{FileList['lib/**/*.rb']} "
end

task "default" => ["test"]

Rake::TestTask.new('test') do |t|
  t.libs << 'test/lib'
  t.test_files = FileList['test/test_*.rb']
   
  t.warning = false
  t.verbose = true
end

