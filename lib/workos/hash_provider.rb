# frozen_string_literal: true

# @oagen-ignore-file — hand-maintained runtime
module WorkOS
  module HashProvider
    def to_h
      self.class::HASH_ATTRS.each_with_object({}) do |(raw_key, attr_name), hash|
        hash[raw_key] = serialize_field(instance_variable_get(:"@#{attr_name}"))
      end
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    def inspect
      attrs = self.class::HASH_ATTRS.values.filter_map do |attr_name|
        value = instance_variable_get(:"@#{attr_name}")
        next if value.nil?

        "#{attr_name}=#{value.inspect}"
      end

      return "#<#{self.class}>" if attrs.empty?

      "#<#{self.class} #{attrs.join(" ")}>"
    end

    private

    def serialize_field(value)
      case value
      when nil
        nil
      when Array
        value.map { |item| serialize_field(item) }
      when Hash
        value.each_with_object({}) { |(key, item), hash| hash[key] = serialize_field(item) }
      else
        (value.respond_to?(:to_h) && !value.is_a?(Hash)) ? value.to_h : value
      end
    end
  end
end
