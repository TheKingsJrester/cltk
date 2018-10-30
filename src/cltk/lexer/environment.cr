module CLTK
  macro environment(no_position = false)
    class Environment
      getter flags          : Set(Symbol)     = Set(Symbol).new
      getter flags_changed  : Bool            = false
      getter states         : Array(Symbol)   = Array(Symbol).new
      getter state_changed  : Bool            = false
      getter tokens         : Array(Token)    = Array(Token).new
      getter stream_offset  : UInt32          = 0
      getter line           : UInt32          = 0
      getter column         : UInt32          = 0

      def initialize(start_state : Symbol)
        @states << start_state
      end

      def push_state(state : Symbol) : Nil
        @states << state
        @state_changed = true
      end

      def pop_state : Nil
        @states.pop
        @state_changed = true
      end

      def set_state(state : Symbol) : Nil
        @states[-1] << state
        @state_changed = true
      end

      def state : Symbol
        @states.last
      end

      def set_flag(flag : Symbol) : Nil
        @flags << flag
        @flags_changed = true
      end

      def unset_flag(flag : Symbol) : Nil
        @flags.delete flag
        @flags_changed = true
      end

      def clear_flags : Nil
        @flags.clear
        @flags_changed = true
      end

      def changed?
        @states_changed || @flags_changed
      end

      def reset_changed
        @states_changed   = false
        @flags_changed    = false
      end

      def add_token(token : Symbol, start_position : Position) : Nil
        @tokens << Token.new(type: token, value: nil, position: {start: start_position, "end": position})
      end

      def add_token(token : {Symbol, TokenValue}|{Symbol}, start_position : Position) : Nil
        @tokens << Token.new(type: token[0], value: token[1]?, position: {start: start_position, "end": position})
      end

      def add_token(token : Token) : Nil
        @tokens << token
      end

      def advance_offset(count : Int32) : Nil
        @stream_offset += count
      end

      def position
        {line: @line, column: @column}
      end

      def compute_position(match : String) : Nil
        advance_offset match.size

        if (newlines = match.count "\n") > 0
          @line += newlines
          @column = match.split("\n").last.size.to_u
        else
          @column += match.size
        end
      end

      def lexing_error
        raise CLTK::Exceptions::LexingError.new(@stream_offset, @line, @column, "")
      end

      def lexing_error(string : String)
        raise CLTK::Exceptions::LexingError.new(@stream_offset, @line, @column, string)
      end

      def yield_with_self
        with self yield
      end
    end
  end
end
