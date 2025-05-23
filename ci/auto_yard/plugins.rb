Bundler::Plugin.add_hook('after-install-all') do
  system('bundle exec yard gems')
end
