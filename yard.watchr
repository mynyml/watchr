# Run me with:
#
#   $ watchr docs-yard.watchr

def run_yard
  print "Updating yardocs... "
  system('yardoc -o doc/yard --readme README.rdoc --files LICENSE')
  print "done.\n"
end

watch( '^(lib|bin)/.*\.rb' ) { run_yard }
watch( '^README.rdoc'      ) { run_yard }
watch( '^LICENSE'          ) { run_yard }




# vim:ft=ruby
