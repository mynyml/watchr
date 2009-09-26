require 'rake/rdoctask'
begin
  require 'yard'
rescue LoadError, RuntimeError
end

desc "Generate rdoc documentation."
Rake::RDocTask.new(:rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force') { |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.title    = "Watchr"
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('TODO.txt')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

if defined? YARD
  YARD::Rake::YardocTask.new do |t|
    t.files   = %w( lib/**/*.rb )
    t.options = %w( -o doc/yard --readme README.rdoc --files LICENSE,TODO.txt )
  end
end

namespace(:test) do

  desc "Run all tests"
  task(:all) do
    tests = Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
    cmd = "ruby -rubygems -Ilib -e'%w( #{tests.join(' ')} ).each {|file| require file }'"
    puts cmd if ENV['VERBOSE']
    system cmd
  end

  desc "Run all tests on multiple ruby versions (requires rvm with 1.8.6 and 1.8.7)"
  task(:portability) do
    versions = %w( 1.8.6  1.8.7 )
    versions.each do |version|
      system <<-BASH
        bash -c 'source ~/.rvm/scripts/rvm;
                 rvm use #{version};
                 echo "--------- `ruby -v` ----------\n";
                 rake -s test:all'
      BASH
    end
  end
end
