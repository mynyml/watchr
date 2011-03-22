#!/usr/bin/env watchr

require 'yard'
# --------------------------------------------------
# Rules
# --------------------------------------------------
watch( 'lib/.*\.rb' ) { yard }
watch( 'README.md'  ) { yard }
watch( 'TODO.md'    ) { yard }
watch( 'LICENSE'    ) { yard }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { yard }        # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def yard
  print "Updating yardocs... "; STDOUT.flush
  YARD::CLI::Yardoc.run *%w( -o doc/yard --readme README.md --markup markdown - LICENSE TODO.md )
  print "done\n"
end
