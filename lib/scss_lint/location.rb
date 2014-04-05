module SCSSLint
  # Stores a location of [Lint] in a source.
  class Location
    include Comparable

    attr_reader :line, :column, :length

    # @param line [Integer] An one-based index
    # @param column [Integer] An one-based index
    # @param length [Integer] A length in the line
    def initialize(line = 1, column = 1, length = 1)
      raise ArgumentError, "Line must be more than 0, passed #{line}" if line < 1
      raise ArgumentError, "Column must be more than 0, passed #{column}" if column < 1
      raise ArgumentError, "Length must be more than 0, passed #{length}" if length < 1

      @line   = line
      @column = column
      @length = length
    end

    def ==(other)
      [:line, :column, :length].all? do |attr|
        send(attr) == other.send(attr)
      end
    end

    alias_method :eql?, :==

    def <=>(other)
      [:line, :column, :length].each do |attr|
        result = send(attr) <=> other.send(attr)
        return result unless result == 0
      end

      0
    end
  end
end
