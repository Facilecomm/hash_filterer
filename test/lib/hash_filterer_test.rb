require 'test_helper'
require 'test/unit'
require 'hash_filterer'

class HashFiltererTest < Test::Unit::TestCase
  test 'raises when invalid operator' do
    assert_raises HashFilterer::Rule::InvalidOperator do
      HashFilterer.new [rule_hash('cooler than')]
    end
  end

  test 'raises when invalid preprocessor' do
    assert_raises HashFilterer::Rule::InvalidPreprocessor do
      HashFilterer.new [rule_hash(preprocessor: 'toto')]
    end
  end

  test 'applies nil_ok when nil' do
    assert_accepted({})
  end

  test 'applies basic rules' do
    assert_accepted 'toto' => 'a surfer'
    assert_not_accepted 'toto' => 'a swimmer'
  end

  test 'applies inclusion' do
    @config = [rule_hash('IN', 'toto', ['a surfer', 'a swimmer'])]
    assert_accepted 'toto' => 'a swimmer'
    assert_not_accepted 'toto' => 'a diver'
  end

  test 'applies multiple rules' do
    @config = [rule_hash, rule_hash('>', 'level', 3)]
    assert_accepted 'toto' => 'a surfer', 'level' => 5
    assert_not_accepted 'toto' => 'a surfer', 'level' => 3
  end

  test 'works on multiple keys' do
    @config = [rule_hash('==', %w(tata toto))]
    assert_accepted 'tata' => { 'toto' => 'a surfer' }
    assert_not_accepted 'tata' => { 'toto' => 'a swimmer' }
  end

  test 'works with non existing mutiple keys' do
    @config = [rule_hash('==', [%w(tata toto)])]
    assert_accepted 'tata' => {} # as nil_ok
  end

  test 'ok when no rule' do
    assert_equal true, HashFilterer.new(nil).accept?({})
  end

  test 'applies preprocessor' do
    string = 'A Surfer'
    assert_not_accepted 'toto' => string
    @filterer = nil
    @config = [rule_hash(preprocessor: 'downcase')]
    assert_accepted 'toto' => string
  end

  test 'applies multiple preprocessors' do
    string = ' A Surfer '
    assert_not_accepted 'toto' => string
    @filterer = nil
    @config = [rule_hash(preprocessor: %w(downcase strip))]
    assert_accepted 'toto' => string
  end

  test 'stores errors' do
    assert_not_accepted 'toto' => 'a swimmer'
    assert_equal @filterer.error_messages, ['Not a swimmer == a surfer']
  end

  test 'works when array in the middle' do
    @config = [rule_hash('==', %w(tata toto))]
    assert_accepted 'tata' => [{ 'toto' => 'a surfer' }]
  end

  test 'ok when all ok' do
    @config = [rule_hash('==', %w(tata toto))]
    assert_accepted 'tata' => [{ 'toto' => 'a surfer' }, { 'toto' => 'a surfer' }]
  end

  test 'not ok when not all ok' do
    @config = [rule_hash('==', %w(tata toto))]
    assert_not_accepted 'tata' => [{ 'toto' => 'a surfer' }, { 'toto' => 'a swimmer' }]
  end

  test 'does not preprocesses nils' do
    @config = [rule_hash('==', %w(tata toto), preprocessor: 'downcase')]
    assert_accepted 'tata' => [{ 'toto' => 'a surfer' }, {}] # because nil_ok = true
  end

  test 'ok to stores regexps in db' do
    @config = [rule_hash('=~', 'toto', /surfer$/.to_s)]
    assert_accepted 'toto' => 'a surfer'
    assert_not_accepted 'toto' => 'a surfer plouf'
  end

  test 'at_least_one is ok if at least one passes' do
    @config = [rule_hash('==', %w(tata toto), at_least_one: true)]
    assert_accepted 'tata' => [{ 'toto' => 'a surfer' }, { 'toto' => 'a swimmer' }]
    assert_not_accepted 'tata' => [{ 'toto' => 'not a surfer' }, { 'toto' => 'a swimmer' }]
  end

  test 'at_least_one with simple key' do
    @config = [rule_hash(at_least_one: true)]
    assert_accepted 'toto' => 'a surfer'
    assert_not_accepted 'toto' => 'not a surfer'
  end

  test 'fills in error messages' do
    assert_not_accepted 'toto' => 'a swimmer'
    assert_equal ['Not a swimmer == a surfer'], filterer.error_messages
  end

  test 'reset the error at each try' do
    assert_not_accepted 'toto' => 'a swimmer'
    assert_accepted 'toto' => 'a surfer'
    assert_empty filterer.error_messages
  end

  private

  def assert_accepted(hash)
    assert_equal true, filterer.accept?(hash)
  end

  def assert_not_accepted(hash)
    assert_equal false, filterer.accept?(hash)
  end

  def filterer
    @filterer ||= HashFilterer.new config
  end

  def config
    @config ||= [rule_hash]
  end

  def rule_hash(operator = '==', key = 'toto', value = 'a surfer', preprocessor: nil, at_least_one: nil)
    {
      'key' => key,
      'operator' => operator,
      'value' => value,
      'nil_ok' => true,
      'preprocessor' => preprocessor,
      'at_least_one' => at_least_one
    }
  end
end
