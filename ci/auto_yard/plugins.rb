Bundler::Plugin.add_hook('after-install-all') do
  cmd = 'bundle exec yard gems --plugin solargraph'
  STDERR.puts("Installing yard info using #{cmd.inspect}")
  # Attempt to run yard, and if it fails, try again - sometimes YARD gets indigestion on a given gem
  system(cmd + ' || ' + cmd)
  STDERR.puts("Installed yard info using #{cmd.inspect}")
rescue StandardError => e
  STDERR.puts("Error running yard gems: #{e.message}")
  STDERR.puts("Backtrace:\n#{e.backtrace}")
end
