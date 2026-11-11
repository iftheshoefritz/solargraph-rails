# Annotations for Solargraph before 0.53

Solargraph before 0.53 reads no gem RBS, so it misses the RBS collection's turbo-rails types. It finds `Turbo::Broadcastable` and `Turbo::Native::Navigation` through YARD, but without return types, and never applies the `ActiveSupport.on_load` hook that includes `Turbo::Native::Navigation` into `ActionController::Base`. These stubs repeat the collection's turbo-rails signatures and that include.

`RailsApi` loads this directory only when Solargraph is older than 0.53; delete it once solargraph-rails stops supporting those releases.
