# Annotations for rbs before 4.3

These annotations restate types that rbs 4.3 and later give in its stdlib RBS ([ruby/rbs#3234](https://github.com/ruby/rbs/pull/3234)). Older rbs versions type them as `untyped`.

`RailsApi` loads this directory only when the rbs Solargraph runs with is older than 4.3 or not loaded, or Solargraph is older than 0.53 (which reads no gem RBS). Delete it when solargraph-rails stops supporting rbs before 4.3.
