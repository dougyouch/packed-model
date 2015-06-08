module PackedModel
  class List
    include Enumerable

    def initialize(row_class, values=nil)
      raise InvalidPackedModelException.new("row_class must be fixed width") unless row_class.fixed_width?
      @row_class = row_class
      values.force_encoding(Encoding::BINARY) if values.respond_to?(:force_encoding)
      @buffer = values
    end

    # the data in each row is only unpacked when it is accessed from here
    def [](idx)
      if (row = rows[idx]).is_a?(String)
        row = rows[idx] = @row_class.new(row)
      end
      row
    end

    def []=(idx, row)
      row.changed!
      rows[idx] = row
    end

    def <<(row)
      row.changed!
      rows << row
    end

    def remove(idx)
      @must_repack = true
      rows[idx] = nil
    end

    def pack
      return repack if @must_repack
      return @buffer unless @rows
      @buffer ||= ''.force_encoding(Encoding::BINARY)
      start = 0
      @rows.each_with_index do |row, idx|
        # only updated dirty rows
        if ! row.is_a?(String) && row.changed?
          @buffer[start...(start+row_bytesize)] = row.pack
          row.not_changed!
        end
        start += row_bytesize
      end
      @buffer
    end

    # repacks the buffer
    def repack
      @buffer = ''.force_encoding(Encoding::BINARY)
      self.each do |row|
        next unless row
        @buffer << row.pack
      end
      remove_instance_variable "@rows"
      remove_instance_variable("@must_repack") if defined?(@must_repack)
      remove_instance_variable("@results") if defined?(@results)
      @buffer
    end

    # to search the buffer the first field must be a marker and the 2nd is the what you are searching for
    # Example: class TestSearchableModel < PackedModel::Base
    #            attribute :magic, :type => :marker, :value => 20130502
    #            attribute :id, :type => :integer
    #            attribute :name, :type => :char, :size => 20
    #          end
    def find_in_buffer(val)
      return nil unless @buffer
      @results ||= {}
      return @results[val] if @results.has_key?(val)
      index = @buffer.index search_string(val)
      return (@results[val] = nil) unless index
      index = index / row_bytesize
      @results[val] = self[index]
    end

    def size
      rows.size
    end

    def bytesize
      row_bytesize * size
    end

    def each
      self.size.times do |idx|
        yield self[idx]
      end
    end

    private

    # doesn't really unpack the data into models, just creates an array of pointers into the buffer
    # data is not unpacked unless it is accessed
    def unpack(str)
      raise InvalidDataException.new("invalid string for list") unless (str.bytesize % row_bytesize) == 0

      start = 0
      [].tap do |data|
        (str.bytesize / row_bytesize).times do
          data << str[start...(start+row_bytesize)] # essentially we are creating C style pointers into the string at certain locations
          start += row_bytesize
        end
      end
    end

    def rows
      if ! defined?(@rows)
        @rows = @buffer ? unpack(@buffer) : []
      end
      @rows
    end

    def row_bytesize
      @row_class.bytesize
    end

    def search_string(val)
      marker_field = @row_class.fields[0]
      key_field = @row_class.fields[1]
      [marker_field[:value], val].pack "#{marker_field[:pack_directive]}#{key_field[:pack_directive]}"
    end
  end
end
