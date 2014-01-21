module PackedModel
  class Base
    def self.fields
      []
    end

    def fields
      self.class.fields
    end

    def self.keys
      []
    end

    def self.all_field_options
      {}
    end

    def self.field_options(key)
      all_field_options[key.to_sym]
    end

    def self.field_index(key)
      field_options(key)[:index]
    end

    def keys
      self.class.keys
    end

    def self.fixed_width?
      true
    end

    def fixed_width?
      self.class.fixed_width?
    end

    def self.attribute(name, options={}, &block)
      options[:name] = name.to_sym
      raise "duplicate field name #{name}" if self.keys.include?(options[:name])
      options[:index] = self.fields.size
      options[:type] ||= :string
      case options[:type]
      when :string
        options[:strip] = true
        options[:null] = true
        options[:pack_directive] = 'Z*'
      when :integer, :int
        options[:default] ||= 0 # pack 'N' directive requires a value for an integer
        options[:bytesize] = 4
        options[:pack_directive] = 'N' # network byte order
      when :char
        options[:size] ||= 1
        options[:bytesize] = options[:size]
        options[:pack_directive] = "a#{options[:size]}"
      when :marker
        raise "missing value for marker" unless options[:value]
        options[:default] = options[:value]
        options[:bytesize] = 4
        options[:pack_directive] = 'N' # network byte order
        options[:unpack_callback] ||= create_marker_unpack_callback(options[:index], options[:value])
      when :custom
        raise "missing pack_directive for #{name}" unless options[:pack_directive]
      else
        raise "Unknown type #{options[:type]}"
      end

      add_unpack_callback(options[:unpack_callback]) if options[:unpack_callback].is_a?(Proc)
      add_unpack_callback(create_strip_unpack_callback(options[:index], options[:null])) if options[:strip]

      class_eval do
        attrs = self.fields << options
        ks = self.keys << options[:name]
        defaults = self.default_values << options[:default]
        ps = self.pack_string << options[:pack_directive]
        kopts = self.all_field_options.merge name.to_sym => options

        class << self; self end.send(:define_method, "fields") do
          attrs
        end
        class << self; self end.send(:define_method, "keys") do
          ks
        end
        class << self; self end.send(:define_method, "default_values") do
          defaults
        end
        class << self; self end.send(:define_method, "pack_string") do
          ps
        end
        class << self; self end.send(:define_method, "all_field_options") do
          kopts
        end

        if self.fixed_width? && options[:bytesize].nil?
          class << self; self end.send(:define_method, "fixed_width?") do
            false
          end
          class << self; self end.send(:define_method, "bytesize") do
            nil
          end
        end

        if self.fixed_width?
          bs = self.bytesize + options[:bytesize]
          class << self; self end.send(:define_method, "bytesize") do
            bs
          end
        end
      end

      method_src = <<-METHOD
        def #{name}
          @values[#{options[:index]}] || #{options[:default].inspect}
        end
        METHOD

      case options[:type]
      when :string, :char
        method_src << <<-METHOD
        def #{name}=(val)
          val = val.nil? ? nil : val.to_s
          @changed = @changed || @values[#{options[:index]}] != val
          @values[#{options[:index]}] = val
        end
        METHOD
      when :integer, :int
        method_src << <<-METHOD
        def #{name}=(val)
          val = val.to_i
          @changed = @changed || @values[#{options[:index]}] != val
          @values[#{options[:index]}] = val
        end
        METHOD
      when :custom
        if options[:filter].is_a?(Symbol) || options[:filter].is_a?(String)
          method_src << <<-METHOD
          def #{name}=(val)
            val = val.#{options[:filter]}
            @changed = @changed || @values[#{options[:index]}] != val
            @values[#{options[:index]}] = val
          end
          METHOD
        elsif options[:filter] ||= block
          method_src << <<-METHOD
          def #{name}=(val)
            val = self.class.field_options(#{name.inspect})[:filter].call(val)
            @changed = @changed || @values[#{options[:index]}] != val
            @values[#{options[:index]}] = val
          end
          METHOD
        else
          method_src << <<-METHOD
          def #{name}=(val)
            @changed = @changed || @values[#{options[:index]}] != val
            @values[#{options[:index]}] = val
          end
          METHOD
        end
      end

      self.class_eval method_src, __FILE__, __LINE__
    end

    @@valid_true_boolean_values = nil
    def self.valid_true_boolean_values
      @@valid_true_boolean_values ||= [true, 1, '1', 'true', 'on', 'yes']
    end

    def self.bit_vector(name, fields, options={})
      raise "too many fields for bit vecotr #{name}" if fields.size > 32

      self.attribute name, {:type => :integer, :fields => fields}.merge(options)

      name_equals = "#{name}="

      fields.each_with_index do |fld, idx|
        mask = 1 << idx
        neg_mask = 0xFFFFFFFF ^ mask

        define_method fld do
          (self.send(name) & mask) == mask
        end

        define_method "#{fld}=" do |val|
          if self.class.valid_true_boolean_values.include?(val)
            self.send(name_equals, self.send(name) | mask)
          else
            self.send(name_equals, self.send(name) & neg_mask)
          end
        end
      end
    end

    def initialize(values=nil)
      case values
      when String
        raise InvalidDataException.new("fixed width model expected #{self.bytesize} but got #{values.bytesize}") if self.fixed_width? && self.bytesize != values.bytesize
        self.unpack values
      when Hash
        @changed = true
        @values = []
        values.each do |k, v|
          send("#{k}=", v) if self.class.field_options(k)
        end
        fields.each do |options|
          next unless options[:fields]
          options[:fields].each do |field|
            send("#{field}=", values[field]) if values.has_key?(field)
          end
        end
        # set default values
        fields.each_with_index do |field, idx|
          @values[idx] ||= self.class.default_values[idx]
        end
      when NilClass
        @changed = true
        @values = self.class.default_values.dup
      else
        raise InvalidDataException.new("invalid values")
      end
    end

    def values
      @values
    end

    def changed?
      !! @changed
    end

    def changed!
      @changed = true
    end

    def not_changed!
      @changed = false
    end

    def to_hash
      Hash[self.keys.zip @values]
    end
    alias to_h to_hash

    def pack
      @values.pack self.class.pack_string
    end

    def bytesize
      self.class.fixed_width? ? self.class.bytesize : (@bytesize ||= self.pack.bytesize)
    end
    alias size bytesize

    def unpack(str)
      @values = str.unpack(self.class.pack_string)
      self.unpack_callbacks.each { |c| c.call self } if self.unpack_callbacks
    end

    def self.add_unpack_callback(callback)
      @unpack_callbacks ||= []
      @unpack_callbacks << callback
    end

    def self.unpack_callbacks
      @unpack_callbacks
    end

    def unpack_callbacks
      self.class.unpack_callbacks
    end

    private

    def self.default_values
      []
    end

    def self.bytesize
      0
    end

    def self.pack_string
      ""
    end

    def self.create_marker_unpack_callback(index, value)
      Proc.new do |m|
        raise BadMarkerException.new("unpack failed, invalid marker value (#{m.values[index]}) expected #{value}") unless m.values[index] == value
      end
    end

    def self.create_strip_unpack_callback(index, null)
      if null
        Proc.new do |m|
          if m.values[index].empty?
            m.values[index] = nil
          else
            m.values[index].strip!
          end
        end
      else
        Proc.new do |m|
          m.values[index].strip!
        end
      end
    end
  end
end

