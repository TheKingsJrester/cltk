module CLTK
  module Exceptions
    class LexingError < Exception
      getter :offset, :line, :column, :text

      def initialize(@offset : UInt32|Int32, @line : Int32|UInt32, @column : Int32|UInt32, @text : String)
        super("Unable to lex #{@text} at #{@line}:#{@column} (#{@offset})")
      end
    end
  end
end
