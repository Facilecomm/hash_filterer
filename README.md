# hash_filterer
Check hash against a set of rules

## Usage
Usage is pretty simple, there are only 2 methods:
 - accept? => Is the hash passing the rules
 - error_messages => If not passing, messages detailling why
 - rules are defined as an array of hashes, with string keys (so can be stored directly in a hstore or json field)

```ruby
require 'hash_filterer'

rules = [{
  # The key path to the value to be tested (can be an array for nested fields)
  'key' => %w(foo plouf),
  # Operator to check with
  'operator' => '==',
  # value to check against
  'value' => 'bar',
  # Is nil (or missing key) ok or not - default is false
  'nil_ok' => false,
  # optional preprocessor for the value to be tested before being checked. must be a public function of the value
  'preprocessor' => 'downcase',
  # If an intermediate level is an array, do we need all values to pass, or just one ?
  'at_least_one' => true
}]

filterer = HashFilterer.new rules
filterer.accept? 'foo' => { 'plouf' => 'bar' } # true
filterer.accept? 'foo' => { 'plouf' => 'bar-bar' } # false
filterer.error_messages # ["Not bar-bar == bar"]
filterer.accept? 'foo-foo' => { 'plouf' => 'bar-bar' } # false (as nil_ok is false)
filterer.accept? 'foo' => {} # false (as nil_ok is false)
filterer.accept? 'foo' => [{ 'plouf' => 'bar' }, { 'plouf' => 'bar-bar' }] # true (as at_least_one is true)
filterer.error_messages # [] # As apply to previous check
```
