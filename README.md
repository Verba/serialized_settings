[![Build Status](https://travis-ci.org/Verba/serialized_settings.svg?branch=master)](https://travis-ci.org/Verba/serialized_settings)

Instead of just storing a hash for metadata (usually settings) for your ActiveRecord model, why not use...

SERIALIZED SETTINGS?
====================

```ruby
class AddSettingsDataColumnToUser < ActiveRecord::Migration
  def change
    add_column :users, :settings_data, :text
  end
end
```

```ruby
class User < ActiveRecord::Base
  serialize_settings(
    :settings_data,
    reader_name: :settings,
    # A Proc here will let you set per-user settings default hashes
    defaults: Proc.new {|record| record.settings_defaults}
  )
end
```

```ruby
class User < ActiveRecord::Base
  serialize_settings(
    :settings_data,
    reader_name: :settings,
    defaults: YAML.load(Rails.configuration.x.user_default_yaml)
  )
end
```

In either case, here's how you use it:

```ruby
user.settings.update("i.take.a.path.down.hash.trees" => true)
# => [{"i" => {"take" => {"a" => {"path" => {"down" => {"hash" => {"trees" => true}}}}}}}]
user.save
# => true
# (Serilizes to YAML and shoves it in the "settings_data" field, as above)
user.settings.value("i.take.a.path.down.hash.trees")
# => true
```

It will traverse down this path and set the value, deeply merging along the way. Access through `#value` will deeply-access considering the defaults tree.