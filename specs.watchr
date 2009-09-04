# Run me with:
#
#   $ watchr specs.watchr

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def all_test_files
  Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
end

def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_all_tests
  cmd = "ruby -rubygems -I.:lib:test -e'%w( #{all_test_files.join(' ')} ).each {|file| require file }'"
  run(cmd)
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch( '^test.*/test_.*\.rb'                 )   { |m| run( "ruby -rubygems %s"                           % m[0] ) }
watch( '^lib/(.*)\.rb'                       )   { |m| run( "ruby -rubygems test/test_%s.rb"              % m[1] ) }
watch( '^lib/watchr/(.*)\.rb'                )   { |m| run( "ruby -rubygems test/test_%s.rb"              % m[1] ) }
watch( '^lib/watchr/event_handlers/(.*)\.rb' )   { |m| run( "ruby -rubygems test/test_event_handler.rb"   % m[1] ) }
watch( '^test/test_helper\.rb'               )   { run_all_tests }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " RERUNING ALL TESTS (Ctrl-C to quit)\n\n"
  run_all_tests
end

# Ctrl-C
#Signal.trap('INT') { abort("\n") }
Signal.trap('INT') { puts "\n"; exit }






# vim:ft=ruby
