# Annotations for Solargraph before 0.60

These annotations restate types that gem_rbs_collection's RBS already provides. Solargraph 0.60 and later read that RBS and give the same results without them. Solargraph 0.48 to 0.52 read no gem RBS, and 0.57 and 0.58 type RBS literal returns as `true`, `false` or a symbol instead of `Boolean` or `Symbol`, so they still need these.

`RailsApi` loads this directory only when Solargraph is older than 0.60. Delete it when solargraph-rails stops supporting Solargraph before 0.60.
