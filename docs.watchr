# Run me with:
#
#   $ watchr docs.watchr

def run_rdoc
  system('rake --silent rdoc')
end

def run_yard
  print "\nUpdating yardocs... "
  system('rake --silent yardoc')
  print "done.\n"
end

def document
  run_rdoc
  run_yard
end

watch( 'lib/.*\.rb'  ) { document }
watch( 'README.rdoc' ) { document }
watch( 'TODO.txt'    ) { document }
watch( 'LICENSE'     ) { document }


# vim:ft=ruby
