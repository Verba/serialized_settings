require 'yaml'
require 'stringio'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/deep_merge'

module SerializedSettings
  class Serializer
    def initialize(data = nil, defaults = nil)
      # set @data
      clear

      hash = case data
             when String
               YAML.load(data)
             when Hash
               data
             end

      update(hash) if hash

      case defaults
      when String, Hash
        @defaults = self.class.new(defaults)
      when Serializer
        @defaults = defaults
      end
    end

    def output
      YAML.dump(@data)
    end

    def output_with_defaults
      return output unless @defaults
      YAML.dump(@defaults.instance_variable_get(:@data).deep_merge(@data))
    end

    def [](key)
      value(key)
    end

    def []=(key, value)
      update(key => value)
    end

    # Get the value at this key/path
    def value(key, with_defaults = true)
      path  = key.to_s.split(".")
      value = deep_fetch(@data, *path)

      if value.nil? && with_defaults && @defaults
        value = @defaults.value(key)
      elsif value.is_a?(Hash)
        if with_defaults &&  @defaults && (default = @defaults.value(key)) && default.is_a?(Hash)
          value = default.deep_merge(value.with_indifferent_access)
        else
          value = value.with_indifferent_access
        end
      end

      value
    end

    # {path => value},
    # {"compete.settings.valore.activated" => true}
    def update(hash)
      hash.each do |key, value|
        deep_update(@data, key.to_s.split(".").reverse.inject(value) {|memo, v| {v => memo}})
      end
    end

    # Replace all the settings with the ones described in this hash.
    def update_all(data)
      clear
      update(data)
    end

    private
    def clear
      @data = {}
    end

    # Follow a path (splatted array) to a value
    # Return nil if the path doesn't terminate in a value
    def deep_fetch(hash, first, *rest)
      data = hash[first]
      if rest.empty?
        data
      elsif data.is_a?(Hash)
        deep_fetch(data, *rest)
      end
    end

    def deep_update(hash, other_hash, tree=[])
      other_hash.each do |k, v|
        k  = k.to_s
        tv = hash[k]

        if v.is_a?(Hash)
          tv = {} unless tv.is_a?(Hash)
          hash[k] = deep_update(tv, v, tree.dup.push(k))
          hash.delete(k) if hash[k].empty?
        else
          if @defaults && @defaults.value(tree.dup.push(k).join(".")) == v
            hash.delete(k)
            next
          end

          hash[k] = v
        end
      end

      hash
    end
  end
end
