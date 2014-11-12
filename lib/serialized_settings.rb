require 'active_support/concern'
require 'active_support/core_ext/string/inflections'

require 'serialized_settings/serializer'

module SerializedSettings
  extend ActiveSupport::Concern

  module ClassMethods
    # Maintains a serialized key-value store in a column on the model. Supports deep merge on write and optional
    # fallback to a set of defaults.
    #
    # === Parameters
    #
    # * +attr_name+ - The field name that should be serialized
    # * +options+ - A hash of options below
    #
    # === Options
    #
    # [:reader_name]
    #   By default the +attr_name+ method will be redefined to return the +Serializer+ object. Use to specify a
    #   different method name for the reader. Note that this name will also be used as the basis for the writer method
    #   name.
    #
    # [:defaults]
    #   Specify a set of defaults which the +Serializer+ will fallback to should the serialized column not contain
    #   the key requested on read. Pass it a Proc or Hash.
    #
    # === Methods
    #
    # [attr_name]
    #   Returns the +Serializer+ object.
    #
    # [attr_name.value(key, with_defaults=true)]
    #   Returns the value for the specified key.
    #
    # [attr_name.update(hash)]
    #   Updates the values. The hash keys can be specified normally (i.e. +{:cat => {:dog => "value"}}+) or
    #   dot-separated (i.e. +{"cat.dog" => "value"}). It will automatically deep-merge keys.
    #
    # [attr_name.update_all(hash)]
    #   Clears the store, then updates.
    #
    # [find_by_attr_name(settings)]
    #   Acts like ActiveRecord finders to return models that match the supplied settings.
    #   Takes either a string, which will return models for which the value is truthy,
    #   or a hash of keys and values, which will return models where all conditions match.
    #
    def serialize_settings(attr_name, options={})
      reader_name = (options[:reader_name] || attr_name).to_s

      class_eval do
        redefine_method(reader_name) do
          @serialized_settings ||= {}
          @serialized_settings[attr_name] ||= begin
            defaults = case options[:defaults]
                       when Proc
                         options[:defaults].call(self)
                       else
                         options[:defaults]
                       end

            Serializer.new(read_attribute(attr_name), defaults)
          end
        end

        before_save do
          send("#{attr_name}_will_change!")
          write_attribute(attr_name, send(reader_name).output)
        end
      end

      self.class.instance_eval do
        redefine_method("find_by_#{reader_name}") do |*args|
          conditions = args.each_with_object({}) do |arg, args_hash|
            case arg
            when String
              args_hash[arg] = true
            when Hash
              args_hash.merge!(arg)
            else
              raise ArgumentError, "must be String or Hash, got #{arg.class.name}"
            end
          end

          matching = []
          self.find_each do |model|
            matching << model if conditions.each_pair.all? do |setting, value|
              case value
              when true
                model.send(reader_name).value(setting)
              when false, nil
                !model.send(reader_name).value(setting)
              else
                model.send(reader_name).value(setting) == value
              end
            end
          end
          matching
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, SerializedSettings)
