# Annotations for Rails before 7.1

gem_rbs_collection types these methods only in its 7.1 and later RBS; its activerecord 7.0 RBS returns untyped, so these annotations fill the gap.

`RailsApi` loads this directory only when the app's activesupport (the version every Rails gem pins) is older than 7.1 or not loaded, or Solargraph is older than 0.53 (which reads no gem RBS). Delete it when solargraph-rails stops supporting Rails 7.0.
