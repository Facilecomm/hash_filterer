rm_coverage:
	rm -rf coverage

rubocop:
	bundle exec rubocop

ruby_tests:
	bundle exec rake test

tests: rm_coverage rubocop ruby_tests
