# Solargraph-Rails development guide

## Contributing

1. create fork and clone the repo
2. install gem deps `bundle install`
3. install dummy rails5 app deps and build its yard cache

    ```
    $ cd spec/rails5
    $ bundle install && yard gems
    $ cd ../../
    ```

3. install dummy rails6 app deps and build its yard cache

    ```
    $ cd spec/rails6
    $ bundle install && yard gems
    $ cd ../../
    ```

4. install dummy rails7 app deps and build its yard cache

    ```
    $ cd spec/rails7
    $ bundle install && yard gems
    $ cd ../../
    ```
5. now tests should pass locally and you can try different changes
6. sumbit PR

## Completion coverage tracking

Solargraph-Rails uses a [set of yaml files](https://github.com/iftheshoefritz/solargraph-rails/tree/master/spec/definitions) to track coverage of found completions.
Those yaml files are generated at runtime from a dummy [rails5](https://github.com/iftheshoefritz/solargraph-rails/tree/master/spec/rails5) or [rails6](https://github.com/iftheshoefritz/solargraph-rails/tree/master/spec/rails6) app.

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
ActionDispatch::Routing::Mapper.try! is marked as skipped in spec/definitions/rails5/routes.yml, but is actually present.
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

### Generating assertions

In case a new set of assertion files has to be created (for a new Rails version for example), a script can be used - https://github.com/iftheshoefritz/solargraph-rails/blob/master/script/generate_definitions.rb.

All you have to do is execute the script and pass it a path to rails app:

```
ruby script/generate_definitions.rb spec/rails6
```

Make sure to review the script and uncomment relevant parts
