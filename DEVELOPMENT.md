# Solargraph-Rails development guide

## Debugging workflow / test matrix issues locally

```sh
npm install -g act
act pull_request
```

## Completion coverage tracking

Solargraph-Rails uses a [set of yaml files](https://github.com/iftheshoefritz/solargraph-rails/tree/master/spec/definitions) to track coverage of found completions.
Those yaml files are generated at runtime from a dummy Rails apps in the spec/rails* directories.

The main goal is to catch any regressions in case of any change. In case a method completion is marked completed and it is not found in solargraph completions, the tests will fail.

### Checking coverage

To see what is completion coverage for solargraph-rails, run the tests with the `PRINT_STATS=true` environment variable:

```
$ PRINT_STATS=true bundle exec rspec
```

What you will see in test output is reported coverage for classes that are tracked:

```
{:class_name=>"ActiveRecord::Base", :total=>800, :covered=>321, :typed=>10, :percent_covered=>40.1, :percent_typed=>1.3}
  provides completions for ActiveRecord::Base
```

### Updating assertions

In case an improvement is made, and more completions are found then being asserted, tests will throw a warning:

```
ActionDispatch::Routing::Mapper.try! is marked as skipped in spec/definitions/routes.yml, but is actually present.
Consider setting skip=false
  provides completions for ActionDispatch::Routing::Mapper
```

In this case there are 2 options:
1. Manually updating yml file and setting `skip: false` for that method
2. Updating yml file in place by passing `update: true` to assertion:

```diff
     assert_matches_definition(
       map,
       'ActionDispatch::Routing::Mapper',
       'rails5/routes',
+      update: true
     )
   end
```

In case of option 2, don't forget to remove the flag after yml file has been updated. Also review git diff, to make sure that no regressions have been set (skip=true was set for entries which previously had skip=false)

A quick way if you want to just start with the existing items:

```
script/copy_definitions.rb 0.57.0 0.58.0
```

### Generating assertions

In case a new set of assertion files has to be created (for a new Rails version for example), a script can be used - https://github.com/iftheshoefritz/solargraph-rails/blob/master/script/generate_definitions.rb.

All you have to do is execute the script and pass it a path to rails app:

```
cd spec/rails8
rails g model model
rails db:drop db:create db:migrate
bundle exec ruby ../../script/generate_definitions.rb .
```

Move .yml files into place, then make sure to review the script and uncomment relevant parts

## Preparing a release (maintainers)

1. Look up [most recent release](https://rubygems.org/gems/solargraph-rails)
2. Open up [commit list](https://github.com/iftheshoefritz/solargraph-rails/compare/v1.2.4...main)
3. Update [CHANGELOG.md](./CHANGELOG.md)
4. Flip to 'files changed view' and refine updates
5. Bump [version](./lib/solargraph/rails/version.rb) appropriately
6. Create branch, commit and merge changes - "Prepare for vX.Y.Z release", branch: `prepare_vX.Y.Z_release`
7. `git config branch.main.remote`
8. Ensure your local main branch is directly from iftheshoefritz
9. `direnv block`
10. `git checkout main && git pull && bundle install && bundle exec rake release`
11. `direnv allow`
