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
    def serialize_settings(attr_name, options={})
      class_eval do
        reader_name = (options[:reader_name] || attr_name).to_s

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
          write_attribute(attr_name, send(reader_name).output)
        end
      end
    end
  end
end
