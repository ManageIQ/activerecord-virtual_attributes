# Virtual Attributes Changelog

Doing our best at supporting [SemVer](http://semver.org/) with
a nice looking [Changelog](http://keepachangelog.com).

## Version [Unreleased] <small>tbd</small>

## Version [4.0.0] <small>2021-02-07</small>

* Once again, a trivial release: dropped support for activerecord 5.0 and 5.1

## Version [3.0.0] <small>2020-09-28</small>

* fix virtual_aggregate to return a consistent 0 when calculating a sum of no records
* fix virtual delegate to include the type column when fetching associated models for polymorphism
* add virtual_average, virtual_minimum, and virtual_maximum

## Version [2.0.0] <small>2020-05-22</small>

* This is a trivial release, but because it modifies a public interface, the jump makes it look significant.
* removed legacy virtual_column parameter support. (it is not ruby 2.7 compatible)
* fixed warnings in ruby 2.7

## Version [1.6.0] <small>2019-12-02</small>

* rails 5.2 support
* fix Arel#name error
* Display deprecation notices for invalid associations (rather than throw an error)

## Version [1.5.0] <small>2019-12-02</small>

* `select()` no longer modifies `select_values`. It understands virtual attributes at a lower level.
* `includes()` can now handle all proper values presented.
* `virtual_total` added support for `has_many` `:through`
* `virtual_total` with a nil attribute value no longer executes an extra query
* rails 6.0 support, (rails 5.2 only fails `habtm` preloading)
* ruby 2.6.x support (no longer testing ruby 2.4)

## Version [1.4.0] <small>2019-07-13</small>

* fix includes to include all associations
* fix bin/console to now actually run
* select no longer munges field attribute
* support virtual attributes in left_outer_joins

## Version [1.3.1] <small>2019-06-06</small>

* quote column aliases

## Version [1.3.0] <small>2019-05-24</small>

* Rails 5.2 support

## Version [1.2.0] <small>2019-04-23</small>

* Virtual_delegate :type now specified to avoid rare race conditions with attribute discovery
* Delays interpreting delegate until column is used
* Postgres now supports order by virtual_aggregate
* More flexible includes. e.g.: Arrays of symbols now work
* Raises errors for invalid `includes()` and `:uses`

## Version [1.1.0] <small>2019-04-23</small>

* Add legacy types for `VirtualAttribute::Types`
* Fix rails 5.1 bug with `includes()`
* Remove reference to `MiqPreloader`

## Version [1.0.0] <small>2019-03-05</small>

* Renamed to activerecord-virtual_attributes
* Moved from ManageIQ to own repo
* Added support for Rails 5.1

## Version 0.1.0 <small>2019-01-17</small>

* Initial Release
* Extracted from ManageIQ/manageiq

[Unreleased]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v4.0.0...HEAD
[3.0.0]: https://github.com/ManageIQ/activerecord-virtual_attributes/compare/v3.0.0...v4.0.0
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
