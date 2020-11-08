# SolargraphRails - Add ActiveRecord dynamic attributes to solargraph

Given a typical Rails model like this:

```ruby
# == Schema Information
#
# Table name: my_books
#
#  id         :integer          not null, primary key
#  author     :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class MyBook < ApplicationRecord
  def my_method
    "hello"
  end

  ...

end
```

The various Ruby intellisense tools are ok at knowing that there is a `MyBook` constant, and some (including Solargraph) are even aware that objects like `MyBook.new` have a method `.my_method`. But what about those magical dynamic attributes that ActiveRecord creates when Rails starts up? You can see these listed at the top of the file under `# == Schema Information`, the comments helpfully added by the Annotate gem.

Since these attributes are only created at runtime, static analysis alone can't identify them. Your editor has no idea that these attributes exist, but they're amongst the most common things that you will work with in any Rails app.

That's where this plugin for Solargraph comes in: it parses the schema comments left by Annotate and uses those to give Solargraph some extra hints.

With this you get autocompletion on ActiveRecord attributes:

 ![Autocompletion of dynamic attributes like created_at](assets/solar_rails_autocomplete.gif)
 
... and go to definition commands take you to the schema comment for that column:


 ![Go to definition of dynamic attributes like created_at](assets/solar_rails_goto.gif)

This has all been hacked together quite quickly so a lot is in WIP. Check out the issues and contribute if you are interested.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solargraph_rails'
```

And then execute:

    $ bundle install
    
    
Then add `solargraph_rails` as a plugin to your `.solargraph.yml` file:

```
plugins:
  - solargraph_rails
```

## Development

Check out the source, start hacking, put up a PR :).

When you make changes, you probably need to shut down solargraph and restart it (maybe that requires you to shut down your whole editor?). You can speed up the feedback loop by running `api_map = Solargraph::ApiMap.load(Rails.root)` in the root of the Rails project where solargraph_rails is installed. This may require restarting the rails console each time, or at least killing Spring.

Once you have an `api_map`, you can interrogate it with Solargraph code like: `pins = api_map.get_methods('MyBook')`. More examples here: https://solargraph.org/guides/code-examples

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iftheshoefritz/solargraph_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
