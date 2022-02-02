# Change Log

Versioning of this gem follows ActiveRecord versioning, and does not follow SemVer.

e.g.: virtual attributes 6.1.x supports all versions of rails 6.1.

Use the latest version of both this gem and rails where the first 2 digits match.

## [Unreleased]

## [6.1.0] - 2022-02-03

* **BREAKING** Dropped support for Rails 5.0, 5.1, 5.2
* **BREAKING** This gem will now no longer follow Symantic Versioning,
  but instead follow Rails' versioning numbers in order to simplify version
  matches between them both.
* Added Rails 6.1 support
* Ruby 3.0 compatibility: kwargs, regular expression fixes
* changed extension mechanism from `arel_attribute()` to `arel_table[]`
* Auto add grouping to virtual attribute arel

## [3.0.0] - 2020-09-28

* fix virtual_aggregate to return a consistent 0 when calculating a sum of no records
* fix virtual delegate to include the type column when fetching associated models for polymorphism
* add virtual_average, virtual_minimum, and virtual_maximum

## [2.0.0] - 2020-05-22

* This is a trivial release, but because it modifies a public interface, the jump makes it look significant.
* **BREAKING** removed legacy virtual_column parameter support. (it is not ruby 2.7 compatible)
* fixed warnings in ruby 2.7

## [1.6.0] - 2019-12-02

* rails 5.2 support
* fix Arel#name error
* Display deprecation notices for invalid associations (rather than throw an error)

## [1.5.0] - 2019-12-02

* `select()` no longer modifies `select_values`. It understands virtual attributes at a lower level.
* `includes()` can now handle all proper values presented.
* `virtual_total` added support for `has_many` `:through`
* `virtual_total` with a nil attribute value no longer executes an extra query
* rails 6.0 support, (rails 5.2 only fails `habtm` preloading)
* ruby 2.6.x support (no longer testing ruby 2.4)

## [1.4.0] - 2019-07-13

* fix includes to include all associations
* fix bin/console to now actually run
* select no longer munges field attribute
* support virtual attributes in left_outer_joins

## [1.3.1] - 2019-06-06

* quote column aliases

## [1.3.0] - 2019-05-24

* Rails 5.2 support

## [1.2.0] - 2019-04-23

* Virtual_delegate :type now specified to avoid rare race conditions with attribute discovery
* Delays interpreting delegate until column is used
* Postgres now supports order by virtual_aggregate
* More flexible includes. e.g.: Arrays of symbols now work
* Raises errors for invalid `includes()` and `:uses`

## [1.1.0] - 2019-04-23

* Add legacy types for `VirtualAttribute::Types`
* Fix rails 5.1 bug with `includes()`
* Remove reference to `MiqPreloader`

## [1.0.0] - 2019-03-05

* Renamed to activerecord-virtual_attributes
* Moved from ManageIQ to own repo
* Added support for Rails 5.1

## 0.1.0 - 2019-01-17

* Initial Release
* Extracted from ManageIQ/manageiq

[Unreleased]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v6.1.0...HEAD
[6.1.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v3.0.0...v6.0.0
[3.0.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.6.0...v2.0.0
[1.6.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v0.1.0...v1.0.0
