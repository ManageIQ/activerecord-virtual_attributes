# VirtualAttributes

[![CI](https://github.com/ManageIQ/activerecord-virtual_attributes/actions/workflows/ci.yaml/badge.svg)](https://github.com/ManageIQ/activerecord-virtual_attributes/actions/workflows/ci.yaml)

VirtualAttributes allows you to define a ruby method that acts like an attribute or relation.

Sometimes you have a model with an attribute defined in ruby but you want to sort or filter by it. Filtering by that attribute necessitates fetching all the rows from the database and filtering in ruby. For large tables, this is slow and takes up a lot of memory.

This gem allows you to represent these attributes in sql so `ORDER BY` `WHERE` clauses will work.

This also allows you to calculate counts and treat those as a field accessible with `select(:child_count)` to get rid of the N+1 problem of running a `count(*)` on a subcollection for each row.

## Versioning

As of v6.1.0, the versioning of this gem follows ActiveRecord versioning, and does not follow SemVer (e.g. virtual attributes v6.1.x supports all versions of Rails 6.1). Version v3.0.0 supports Rails 6.0 and lower.

Use the latest version of both this gem and Rails where the first 2 digits match.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-virtual_attributes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-virtual_attributes

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To test with different database adapters, set the DB environment variable:

    DB=postgresql bundle exec rake
    DB=mysql bundle exec rake
    DB=sqlite3 bundle exec rake

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/activerecord-virtual_attributes .

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
