require 'yaml'
require 'stringio'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/deep_merge'

module SerializedSettings
  class Serializer
    def initialize(data = nil, defaults = nil)
      @versions = []

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
      @versions << Marshal.load(Marshal.dump(@data))

      hash.map do |key, value|
        # ["one.two.three", 4] -> {"one" => {"two" => {"three" => 4}}}
        key.to_s.split(".").reverse.inject(value) { |memo, v| {v => memo} }
      end.each do |apply_hash|
        deep_update(@data, apply_hash)
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

    # Update the hash "base" with hash "apply"
    def deep_update(base, apply, tree=[])
      apply.each do |ak, av|
        # All keys must be strings to be a proper "path"
        ak  = ak.to_s
        bv = base[ak]

        # Are we descending?
        if av.is_a?(Hash)
          bv = {} unless base.has_key?(ak)

          raise "Expected hash at #{(tree + [ak]).join(".")}, was #{bv.class}:#{bv.inspect}" unless bv.is_a?(Hash)

          base[ak] = deep_update(bv, av, tree.dup.push(ak))
          base.delete(ak) if base[ak].empty?
        else
          # Are we resetting to default value? We can delete this node
          if @defaults && @defaults.value(tree.dup.push(ak).join(".")) == av
            base.delete(ak)
            next
          end

          base[ak] = av
        end
      end

      base
    end
  end
end
