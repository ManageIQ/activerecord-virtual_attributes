# Change Log

The versioning of this gem follows ActiveRecord versioning, and does not follow SemVer.  See the [README](./README.md) for more details.

## [Unreleased]

## [7.1.2] - 2025-06-20

* Introduce virtual_has_many :through [#191](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/191)

## [7.1.1] - 2025-06-18

* Deprecate virtual_delegate without a type [#188](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/188)

## [7.1.0] - 2025-02-19

* Use TableAlias for table aliasing [#168](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/168)
* Rails 7.1 support

## [7.0.0] - 2024-08-01

* Use Arel.literal [#154](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/154)
* drop attribute_builder [#153](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/153)
* dropped virtual_aggregate [#152](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/152)
* resolve rubocops (also fix bin/console) [#151](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/151)
* Rails 7.0 support / dropping 6.1 [#150](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/150)
* condense includes produced by replace_virtual_fields [#149](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/149)
* fix bin/console [#148](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/148)
* Rails 7.0 support pt1 [#146](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/146)
* Fix sqlite3 v2 and rails [#140](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/140)
* Use custom Arel node [#114](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/114)

## [6.1.2] - 2023-10-26

* Fix bind variables for joins with static strings [#124](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/124)
* Add `virtual_total` for `habtm` [#123](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/123)
* Fix: `:uses` clause now works with an array and nested hashes. [#120](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/120)
* Uses symbols in the `includes()` clause. defined by `virtual_attribute :uses` and virtual_delegate. [#128](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/128)

## [6.1.1] - 2022-08-09

* fix HomogeneousIn clauses [#111](https://github.com/ManageIQ/activerecord-virtual_attributes/pull/111)

## [6.1.0] - 2022-02-03

* **BREAKING** Dropped support for Rails 5.0, 5.1, 5.2, 6.0
* **BREAKING** This gem will now no longer follow Semantic Versioning,
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

[Unreleased]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v7.1.2...HEAD
[7.1.2]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v7.1.1...v7.1.2
[7.1.1]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v7.1.0...v7.1.1
[7.1.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v7.0.0...v7.1.0
[7.0.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v6.1.2...v7.0.0
[6.1.2]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v6.1.1...v6.1.2
[6.1.1]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v6.1.0...v6.1.1
[6.1.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v3.0.0...v6.1.0
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
