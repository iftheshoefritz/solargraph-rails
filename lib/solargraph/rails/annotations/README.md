# annotations

Code in this directory is _not_ loaded or evaluated at runtime, either by solargraph or your application.

The code in [rails_api.rb](../rails_api.rb) loads each of these files inside a YARD  `@!parse` directive.

Files in a subdirectory listed in `VERSION_SCOPED_ANNOTATIONS` in [rails_api.rb](../rails_api.rb) load only when the app's version of that gem (or Solargraph's own version, for `solargraph`) meets the listed requirement, for types the RBS collection lacks in older versions or that older Solargraph versions do not read from it. Rails gems share one version number, so a Rails-version scope is named `rails_before_<version>` and checks `railties`.
