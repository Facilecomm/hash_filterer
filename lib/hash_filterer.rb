require 'active_support/all'

# Can be used to check if a given hash respects a list of rules
class HashFilterer
  # Corresponds to a single rule
  class Rule
    class InvalidOperator < ArgumentError; end
    class InvalidPreprocessor < ArgumentError; end

    attr_reader :error_message

    def self.allowed_operators
      ['==', '!=', '>', '<', 'IN', '=~']
    end

    def self.allowed_preprocessors
      # TODO: Make this a config / maybe just remove
      ['downcase', 'upcase', 'nil?', 'blank?', 'to_s', 'to_f', 'to_i', 'strip']
    end

    # nil_ok should be true or false to specify the behavior when the value is nil
    def initialize(key, operator, value, nil_ok, preprocessor, at_least_one) # rubocop:disable Metrics/ParameterLists
      @keys = Array.wrap key
      @operator = operator
      @value = value
      @nil_ok = nil_ok || false
      @preprocessors = Array.wrap preprocessor
      @at_least_one = at_least_one || false
      check_operator!
      check_preprocessor!
    end

    def accept?(hash)
      values = read_values hash
      msgs = values.map do |actual|
        build_message actual unless ok_for actual
      end.compact
      return true if @at_least_one && values.length > msgs.length
      return true if !@at_least_one && msgs.empty?
      @error_message = msgs.join ' and '
      false
    end

    private

    def ok_for(actual)
      return @nil_ok if actual.nil?
      return @value.include? actual if @operator == 'IN'
      return actual =~ Regexp.new(@value) if @operator == '=~'
      actual.public_send @operator, @value
    end

    def build_message(actual)
      actual = 'nil' if actual.nil?
      "Not #{actual} #{@operator} #{@value}"
    end

    def read_values(hash)
      extract_values(hash, @keys.dup).map do |val|
        preprocess_value val
      end
    end

    def preprocess_value(val)
      return nil if val.nil?
      return val if @preprocessors.empty?
      @preprocessors.inject(val) do |memo, prep|
        memo.public_send prep
      end
    end

    def extract_values(hash, current_keys)
      key = current_keys.shift
      return [nil] unless hash.key? key

      val = hash[key]
      return [val] if current_keys.length == 0
      return extract_array_values val, current_keys if val.is_a? Array
      extract_values val, current_keys
    end

    def extract_array_values(val, current_keys)
      return [nil] if val.length == 0
      val.map { |v| extract_values v, current_keys.dup }.sum
    end

    def check_operator!
      fail InvalidOperator unless self.class.allowed_operators.include? @operator
    end

    def check_preprocessor!
      return if @preprocessors.all? { |prep| self.class.allowed_preprocessors.include? prep }
      fail InvalidPreprocessor, @preprocessors
    end
  end

  attr_reader :error_messages

  def initialize(rules)
    @rules = []
    (rules || []).each { |r| add_rule r }
  end

  def accept?(hash)
    @error_messages = []
    @rules.all? do |rule|
      ok = rule.accept? hash
      @error_messages << rule.error_message unless ok
      ok
    end
  end

  private

  def add_rule(rule)
    @rules << Rule.new(
      rule['key'], rule['operator'], rule['value'], rule['nil_ok'], rule['preprocessor'], rule['at_least_one']
    )
  end
end
