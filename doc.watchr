# vim:ft=ruby

run_rdoc = lambda { system('rake rdoc') }

watch( '(lib|bin)/.*\.rb', &run_rdoc )
watch( 'README',           &run_rdoc )
watch( 'TODO.txt',         &run_rdoc )
watch( 'LICENSE',          &run_rdoc )
