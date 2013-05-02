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
        options[:pack_directive] = 'Z*' # null terminated string
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
      when :custom
        raise "missing pack_directive for #{name}" unless options[:pack_directive]
      else
        raise "Unknown type #{options[:type]}"
      end

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
          val = val.nil? ? nil : val.to_i
          @changed = @changed || @values[#{options[:index]}] != val
          @values[#{options[:index]}] = val
        end
        METHOD
      when :custom
        if options[:filter].is_a?(Symbol) || options[:filter].is_a?(String)
          method_src << <<-METHOD
          def #{name}=(val)
            val = val.nil? ? nil : val.#{options[:filter]}
            @changed = @changed || @values[#{options[:index]}] != val
            @values[#{options[:index]}] = val
          end
          METHOD
        elsif options[:filter] ||= block
          method_src << <<-METHOD
          def #{name}=(val)
            val = val.nil? ? nil : self.class.field_options(#{name.inspect})[:filter].call(val)
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
      self.fields.each do |field|
        case field[:type]
        when :string
          if @values[field[:index]].empty?
            @values[field[:index]] = nil
          else
            @values[field[:index]].strip!
          end
        when :char
          @values[field[:index]].strip! if field[:strip]
        when :marker
          marker_value = @values[field[:index]]
          raise BadMarkerException.new("unpack failed, invalid marker value (#{marker_value}) expected #{field[:value]}") unless marker_value == field[:value]
        end
      end
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
  end
end

