# Annotations for Rails before 7.2

gem_rbs_collection types these methods only in its 7.2 and later RBS. Rails 7.0 and 7.1 resolve older RBS directories (actionpack 6.0, older activerecord) that lack them or return untyped, so these annotations fill the gap. `active_support.rb` types methods that only Rails 7.0 and 7.1 define.

`RailsApi` loads this directory only when the app's activesupport (the version every Rails gem pins) is older than 7.2 or not loaded, or Solargraph is older than 0.53 (which reads no gem RBS). Delete it when solargraph-rails stops supporting Rails 7.1.
