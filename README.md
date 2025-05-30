# Solargraph::Rails - Help solargraph with Rails

## Models
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

The various Ruby intellisense tools are ok at knowing that there is a `MyBook` constant, and some (including Solargraph) are aware that objects like `MyBook.new` have a method `.my_method`. But what about those magical dynamic attributes that ActiveRecord creates when Rails starts up? You can see these listed at the top of the file under `# == Schema Information`, the comments helpfully added by the Annotate gem.

Since these attributes are only created at runtime, static analysis alone can't identify them. Your editor has no idea that these attributes exist, but they're amongst the most common things that you will work with in any Rails app.

That's where this plugin for Solargraph comes in: it parses the database schema to give Solargraph some extra hints on top of Solargraph's use of YARD and RBS. For instance:

 ![Go to attribute schema definition](assets/sg_rails_1_0_go_to_attribute_definition.gif)

 ... or ActiveRecord finders:

 ![ActiveRecord method support](assets/sg_rails_1_0_activerecord_support.gif)

 ... or associations:

 ![Association support](assets/sg_rails_1_0_association_completion.gif)

 ... or routes file:

 ![Routes file support](assets/sg_rails_1_0_routes_support.gif)

and more!

## Installation

###  Install `solargraph` and `solargraph-rails`

If you add them to your Gemfile, you'll have to tell your IDE plugin to use bundler to load the right version of solargraph.

### Import Rails RBS types

Use [gem\_rbs\_collection](https://github.com/ruby/gem_rbs_collection)
to install RBS types for Rails:

```sh
rbs collection init
rbs collection install
```

### Add `solargraph-rails` to your `.solargraph.yml`

(if you don't have a `.solargraph.yml` in your project root, you can run `solargraph config` to add one)

```
plugins:
  - solargraph-rails
```

### Build YARD docs
In the project root, run `yard gems`.

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/iftheshoefritz/solargraph_rails.

1. create fork and clone the repo

2. install gem deps `bundle install`

3. install dummy rails app deps:

```
cd spec/rails7 && bundle install && bundle update solargraph && rbs collection init && rbs collection install && cd ../../
```

4. now tests should pass locally and you can try different changes

5. submit PR

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
