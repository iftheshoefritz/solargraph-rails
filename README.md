# Solargraph::Rails - Help solargraph with Rails

## Models
Consider pair of typical Rails models like this:

```sh
rails g model Author lastname:string firstnames:string
rails g model Book title:string isbn:string author:belongs_to
```

```ruby
class Author < ApplicationRecord
  has_many :books

  def sortable_name
    "#{lastname}, #{firstnames}"
  end
end

class Book < ApplicationRecord
  belongs_to :book

  def label
    [author.sortable_name, title, isbn].join("\n")
  end
end
```

The various Ruby intellisense tools are ok at knowing that there are `Book` and `Author` constants, and some (including Solargraph) are aware that objects like `Book.new` have a `.label` method. But what about those "magical" dynamic methods that ActiveRecord creates like `.title`, or `.author`?

Since these attributes are only created at runtime, a simple static analysis of the `Book` class alone can't identify them. Your editor has no idea that these attributes exist, but they're amongst the most common things that you will work with in any Rails app.

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
cd spec/rails7 && bundle install && bundle update solargraph && rbs collection init && rbs collection install
```

4. now tests should pass locally and you can try different changes

5. submit PR

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
