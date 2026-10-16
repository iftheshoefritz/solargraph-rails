# annotations

Code in this directory is _not_ loaded or evaluated at runtime, either by solargraph or your application.

The code in [rails_api.rb](../rails_api.rb) loads each of these files inside a YARD  `@!parse` directive.

Files in a subdirectory listed in `VERSION_SCOPED_ANNOTATIONS` in [rails_api.rb](../rails_api.rb) load only when the app's version of that gem meets the listed requirement or that gem is not loaded, for types the RBS collection lacks in older versions. Every Rails gem depends on `activesupport` at its own version, so a Rails-version scope is named `rails_before_<version>` and checks `activesupport`. Solargraph before 0.53 reads no gem RBS, so every subdirectory loads there.
