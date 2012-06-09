#!/usr/bin/env watchr

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch( '^test.*/test_.*\.rb'                 )  { |m| ruby  m[0] }
watch( '^lib/(.*)\.rb'                       )  { |m| ruby "test/test_#{m[1]}.rb" }
watch( '^lib/watchr/(.*)\.rb'                )  { |m| ruby "test/test_#{m[1]}.rb" }
watch( '^lib/watchr/event_handlers/(.*)\.rb' )  { |m| ruby "test/event_handlers/test_#{m[1]}.rb" }
watch( '^test/test_helper\.rb'               )  { ruby tests }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { ruby tests  } # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def ruby(*paths)
  run "ruby #{gem_opt} -I.:lib:test -e'%w( #{paths.flatten.join(' ')} ).each {|p| require p }'"
end

def tests
  Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
end

def run( cmd )
  puts   cmd
  system cmd
end

def gem_opt
  defined?(Gem) ? "-rubygems" : ""
end
