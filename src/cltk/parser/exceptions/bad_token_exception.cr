module CLTK
  class Parser
    module Exceptions
      # A BadToken error indicates that a token was observed in the input stream
      # that wasn't used in the grammar's definition.
      class BadToken < Exception
        def initialize(@token : Token)
          @backtrace = [] of String
          super(message)
        end

        # @return [String] String representation of the error.
        def to_s
          "Unexpected token: #{@token} not present in grammar definition."
        end
      end
    end
  end
end
