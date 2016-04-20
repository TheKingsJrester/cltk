module CLTK
  class Parser
    # The Action class is used to indicate what action the parser should
    # take given a current state and input token.
    class Action
      # @return [Integer] ID of this action.
      getter :id

      # @param [Integer] id ID of this action.
      def initialize(id = nil)
        @id = id
      end
    end

    # The Accept class indicates to the parser that it should accept the
    # current parse tree.
    class Accept < Action
      # @return [String] String representation of this action.
      def to_s
        "Accept"
      end
    end

    # The GoTo class indicates to the parser that it should goto the state
    # specified by GoTo.id.
    class GoTo < Action
      # @return [String] String representation of this action.
      def to_s
        "GoTo #{self.id}"
      end
    end

    # The Reduce class indicates to the parser that it should reduce the
    # input stack by the rule specified by Reduce.id.
    class Reduce < Action

      # @param [Production]  production  Production to reduce by
      def initialize(production)
        super(production.id)

        @production = production
      end

      # @return [String] String representation of this action.
      def to_s
        "Reduce by Production #{self.id} : #{@production.to_s}"
      end
    end

    # The Shift class indicates to the parser that it should shift the
    # current input token.
    class Shift < Action
      # @return [String] String representation of this action.
      def to_s
        "Shift to State #{self.id}"
      end
    end

  end
end