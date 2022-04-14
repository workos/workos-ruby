# frozen_string_literal: true

module WorkOS
  # A Temporary wrapper class for a Hash, currently the base class for
  # WorOS::DirectoryGroup and WorkOS::DirectoryUser. Makes all the Hash
  # methods available to those classes, but will also emit a deprecation
  # warning whenever any of them are used.
  #
  # Once we deprecate Hash compatibility, this model can be deleted.
  class DeprecatedHashWrapper < Hash
    (public_instance_methods - Object.methods).each do |method_name|
      define_method method_name do |*args, &block|
        print_deprecation_warning(method_name)
        super(*args, &block)
      end
    end

    # call the original implementation of :replace in Hash,
    # so we don't show the deprecation warning
    def replace_without_warning(new_hash)
      method(:replace).super_method&.call(new_hash)
    end

    def [](attribute_name)
      usage = "#{object_name}.#{attribute_name}"
      warning_message = "WARNING: The Hash style access for #{class_name} attributes is deprecated
and will be removed in a future version. Please use `#{usage}` or equivalent accessor.\n"

      print_deprecation_warning('[]', warning_message)

      super(attribute_name.to_sym)
    end

    private

    def deprecation_warning(method_name)
      usage = "#{object_name}.to_h.#{method_name}"

      "WARNING: Hash compatibility for #{class_name} is deprecated and will be removed
in a future version. Please use `#{usage}` to access methods on the attribute Hash object.\n"
    end

    def print_deprecation_warning(method_name, warning_message = deprecation_warning(method_name))
      if RUBY_VERSION > '3'
        warn warning_message, category: :deprecated
      else
        warn warning_message
      end
    end

    def class_name
      self.class.name
    end

    # We want to do class_name.demodulize.underscore here, but that's not available in Ruby 1.9, so
    # implementing the demodulize and underscore methods here.
    def object_name
      i = class_name.rindex('::')
      object_name = i ? class_name[(i + 2)..-1] : class_name
      underscore(object_name)
    end

    def underscore(camel_cased_word)
      return camel_cased_word.to_s unless /[A-Z-]|::/.match?(camel_cased_word)

      word = camel_cased_word.to_s.gsub('::', '/')
      word.gsub!(/(?:(?<=([A-Za-z\d]))|\b)((?=a)b)(?=\b|[^a-z])/) do
        "#{Regexp.last_match(1) && '_'}#{Regexp.last_match(2).downcase}"
      end
      word.gsub!(/([A-Z]+)(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) { (Regexp.last_match(1) || Regexp.last_match(2)) << '_' }
      word.tr!('-', '_')
      word.downcase!
      word
    end
  end
end
