# Run me with:
#
#   $ watchr specs.watchr

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

watch( 'test/test_.*\.rb' )     {|md| run("ruby -rubygems #{md[0]}") }
watch( 'lib/(.*)\.rb' )         {|md| run("ruby -rubygems test/test_#{md[1]}.rb") }
watch( 'test/test_helper\.rb' ) { run_all_tests }

# Ctrl-C
Signal.trap('INT') do
  puts " RERUNING ALL TESTS (Ctrl-\\ to quit)\n\n"
  run_all_tests
end

# Ctrl-\
Signal.trap('QUIT') { abort("\n") }




# vim:ft=ruby
