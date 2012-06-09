#!/usr/bin/env watchr

def gemspec() Dir['*.gemspec'].first end
# --------------------------------------------------
# Rules
# --------------------------------------------------
watch( gemspec ) { build }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { build }       # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def build
  puts; system "gem build #{gemspec}"
  FileUtils.mv( Dir['*.gem'], 'pkg/' )
end
