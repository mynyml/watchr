# vim:ft=ruby

def all_test_files
  Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
end

run_all_tests = lambda {
  cmd = "ruby -rubygems -I.:lib:test -e'%w( #{all_test_files.join(' ')} ).each {|file| require file }'"
  puts(cmd)
  system(cmd)
}

watch( 'test/test_(.*)\.rb' ) {|md| system("ruby -rubygems #{md[0]}") }
watch( 'lib/(.*)\.rb' )       {|md| system("ruby -rubygems test/test_#{md[1]}.rb") }
watch( 'test/test_helper\.rb', &run_all_tests )

Signal.trap('INT') do
  puts " RERUNING ALL TESTS (Ctrl-\\ to quit)"
  puts
  run_all_tests.call
end
