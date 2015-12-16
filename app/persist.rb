class NSObject
  def to_weak
    WeakRef.new(self)
  end
end

class NSUserDefaults

  # Retrieves the object for the passed key
  def [](key)
    self.objectForKey(key.to_s)
  end

  # Sets the value for a given key and save it right away.
  def []=(key, val)
    self.setObject(val, forKey: key.to_s)
    self.synchronize
  end
end

class Persist
  class << self
    def aliases
      @aliases ||= {}
    end

    def store
      @store ||= Persist.new
    end

    def property(*names)
      names.each { |name|
        define_method("#{name.to_s}".to_weak) { self[name.to_s] }
        define_method("#{name.to_s}?".to_weak) { self["#{name.to_s}?"] }
        define_method("#{name.to_s}_state?".to_weak) { self[name.to_s] ? NSOnState : NSOffState }
        define_method("#{name.to_s}=".to_weak) { |v| change_value(name.to_sym, v) }
      }
    end

    def alias_property(map = {})
      @aliases ||= {}
      map.each { |orig, name|
        @aliases[name.to_s] = orig.to_s
        property name
      }
    end

    def calculated_property(*names, &getter)
      names.each { |name|
        define_method("#{name.to_s}".to_weak) { getter.call(self) }
        define_method("#{name.to_s}?".to_weak) { Util.value_to_bool(getter.call(self)) }
        define_method("#{name.to_s}_state?".to_weak) { getter.call(self) ? NSOnState : NSOffState }
      }
    end

    def validate_map(*keys, &block)
      @validators ||= {}
      keys.each { |key| @validators[key.to_sym] = block }
    end

    def validate_bool(default_value, *keys)
      self.validate_map(*keys) { |_, _, nv| Util.constrain_value_boolean(nv, default_value) }
    end

    def validate?(key, old_value, new_value)
      @validators ||= {}
      (@validators.has_key?(key) && @validators[key].call(key, old_value, new_value)) || new_value
    end

    def depend(deps = {})
      @deps ||= {}
      deps.each { |k, v|
        @deps[k.to_sym] ||= []
        @deps[k.to_sym] << v.to_sym
      }
    end

    def depend?(dep)
      @deps ||= {}
      @deps[dep] || []
    end
  end

  property :last_version

  def identifier
    NSBundle.mainBundle.bundleIdentifier
  end

  def app_key
    @app_key ||= identifier
  end

  def []=(key, value)
    if Persist.aliases.has_key?(key.to_s)
      self[Persist.aliases[key.to_s]] = value
    else
      old_value = self[key.to_s]
      new_value = Persist.validate?(key.to_sym, old_value, value)
      storage.setObject(new_value, forKey: storage_key(key).to_s)
      storage.synchronize
      fire_listeners(key.to_sym, old_value, new_value)
    end
  end

  def [](key)
    is_bool = key.to_s.end_with?('?')
    key2    = is_bool ? key.to_s[0...-1] : key
    rv      = if Persist.aliases.has_key?(key2.to_s)
                self[Persist.aliases[key2.to_s]]
              else
                value = storage.objectForKey storage_key(key2).to_s

                # RubyMotion currently has a bug where the strings returned from
                # standardUserDefaults are missing some methods (e.g. to_data).
                # And because the returned object is slightly different than a normal
                # String, we can't just use `value.is_a?(String)`
                value.class.to_s == 'String' ? value.dup : value
              end
    is_bool ? (rv && rv != 0 && rv != NSOffState) : rv
  end

  def merge(values)
    values.each do |key, value|
      storage.setObject(value, forKey: storage_key(key).to_s)
    end
    storage.synchronize
  end

  def delete(key)
    value = storage.objectForKey storage_key(key).to_s
    storage.removeObjectForKey(storage_key(key).to_s)
    storage.synchronize
    value
  end

  def storage
    NSUserDefaults.standardUserDefaults
  end

  def storage_key(key)
    "#{app_key.to_weak}_#{key.to_weak}".to_weak
  end

  def key_for(key)
    if Persist.aliases.has_key?(key.to_s)
      self.key_for(Persist.aliases[key.to_s])
    else
      storage_key(key.to_s)
    end
  end

  def all
    hash     = storage.dictionaryRepresentation.select { |k, _| k.start_with?(app_key) }
    new_hash = {}
    hash.each do |k, v|
      new_hash[k.sub("#{app_key}_".to_weak, '')] = v
    end
    new_hash
  end

  def no_refresh
    @no_refresh = true
    yield
    @no_refresh = false
  end

  def load_prefs
    self.no_refresh {
      Info.last_version = self.last_version
      self.last_version = Info.version.to_s
    }
  end

  def listen(*keys, &block)
    @listeners ||= {}
    keys.each { |key|
      @listeners[key.to_sym] ||= []
      @listeners[key.to_sym] << block
    }
  end

  def force_listeners(*keys)
    keys.each { |key|
      self[key] = self[key]
    }
  end

  def change_value(key, new_value)
    self[key.to_s] = new_value
  end

  def validate!(*keys)
    keys.each { |key|
      depend!(key)
      self[key.to_s] = self[key.to_s]
    }
  end

  def depend!(key)
    Persist.depend?(key).each { |v| self.validate!(v) }
  end

  def fire_listeners(key, old_value, new_value)
    @listeners ||= {}
    @listeners[key].each { |l| l.call(key, old_value, new_value) } if @listeners.has_key?(key) && !@no_refresh
  end
end