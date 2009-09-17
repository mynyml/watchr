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
