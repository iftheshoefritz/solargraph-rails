# Annotations for Solargraph before 0.62.2

turbo-rails includes `Turbo::Native::Navigation` into `ActionController::Base` from an `ActiveSupport.on_load` hook in its engine. Solargraph 0.62.1 and older (and castwide/solargraph master, which reports 0.62.1) never apply that hook to the gem, so its controller helpers, such as `recede_or_redirect_to`, are missing from controllers. https://github.com/castwide/solargraph/pull/1404 lets solargraph-rails map the hook.

turbo-rails' `Turbo::Broadcastable` and `Turbo::Native::Navigation` live in its engine's `app/` directory. From 0.62.0, Solargraph maps a gem's `require_paths` instead of its YARD docs, so they are missing; older releases find them through YARD, but without return types. The stubs repeat turbo-rails' signatures with return types.

`RailsApi` loads this directory only when Solargraph is older than 0.62.2. Raise that bound if the release after 0.62.1 lacks https://github.com/castwide/solargraph/pull/1404; delete this directory once solargraph-rails stops supporting the releases without it.
