# --------------------------------------------------
# Tests
# --------------------------------------------------
task(:default => "test:all")

namespace(:test) do

  desc "Run all tests"
  task(:all) do
    tests = Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
    cmd = "ruby -rubygems -I.:lib -e'%w( #{tests.join(' ')} ).each {|file| require file }'"
    puts cmd if ENV['VERBOSE']
    system cmd
  end

  desc "Run all tests on multiple ruby versions (requires rvm)"
  task(:portability) do
    %w( 1.8.6  1.8.7  1.9.1  1.9.2 ).each do |version|
      system <<-BASH
        bash -c 'source ~/.rvm/scripts/rvm;
                 rvm #{version};
                 echo "--------- v#{version} ----------\n";
                 rake -s test:all'
      BASH
    end
  end
end

# --------------------------------------------------
# Docs
# --------------------------------------------------
require 'rake/rdoctask'
desc "Generate rdoc documentation."
Rake::RDocTask.new(:rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force') do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.title    = "Watchr"
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('TODO.txt')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Generate YARD Documentation"
task(:yardoc) do
  require 'yard'
  files   = %w( lib/**/*.rb )
  options = %w( -o doc/yard --readme README.rdoc --files LICENSE )
  YARD::CLI::Yardoc.run *(options + files)
end

