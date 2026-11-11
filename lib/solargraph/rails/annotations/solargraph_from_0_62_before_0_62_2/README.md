# Annotations for Solargraph 0.62.0 to 0.62.1

From 0.62.0, Solargraph maps a gem's `require_paths` instead of its YARD docs, so Rails engines' `app/` code, such as turbo-rails' `Turbo::Broadcastable` and `Turbo::Native::Navigation`, is missing. Older releases find it through YARD, so these stubs must not load there. https://github.com/castwide/solargraph/pull/1404 lets solargraph-rails add engine `app/` directories to the mapping.

The stubs repeat turbo-rails' signatures with the return types its method bodies produce. They also declare the job classes those types name, `Turbo::Streams::ActionBroadcastJob` and `Turbo::Streams::BroadcastJob`, which live in turbo-rails' `app/jobs` and so are missing too.

`RailsApi` loads this directory only on Solargraph 0.62.0 and 0.62.1 (and castwide/solargraph master, which reports 0.62.1). Raise the upper bound if the release after 0.62.1 lacks https://github.com/castwide/solargraph/pull/1404; delete this directory once solargraph-rails stops supporting the releases without it.
