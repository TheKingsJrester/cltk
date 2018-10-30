require "crystal-dfa"
require "./lexer/exceptions"
require "./lexer/environment"
require "./lexer/types"

module CLTK
  module ScannerMethods
    extend self

    # lexes a string by continously matching the dfas
    # against the string, yielding the callbacks with
    # an instance of Environment
    def lex(string, env, rx, callbacks, split_lines : Bool = true)
      split_lines ? string.lines(false).each do |line|
        lex_string(line, env, callbacks, rx)
      end : lex_string(string, env, callbacks, rx)
      env
    end

    # continously match the string against the dfas
    # calling the returned callbacks with the matches
    # to construct the Token Values
    def lex_string(string, env, callbacks, rx)
      i = 0
      # Indicate wether state or flags have changed to reduce lookups
      changed = false
      dfas = nil
      while (i <= string.size - 1)
        s = string[i..-1]

        # We only need the new dfas if a state of flag has changed
        if changed || !dfas
          dfas = rx[{env.state, (env.flags.to_a.empty? ? nil : env.flags.to_a)}]
        end

        size, cbindex = match(s, env, dfas)

        # cache previous position so each token has a 'start' and 'end' position
        token_start = env.position
        # compute new stream offset and count newlines in the matched string
        env.compute_position s[0, size]

        # Check if the rule has a callback
        if cbindex
          # Call the callback and pass its return value to 'env'
          if value = callbacks[-cbindex].try &.call(s[0, size], env)
            env.add_token(value, token_start)
          end
        end

        changed = env.state_changed || env.flags_changed
        env.reset_changed

        i += size
      end
    end
    # runs the set of dfas in @@rx against the string
    # and returns the index and last position of the
    # dfa automaton that achieved the longes match
    def match(string : String, env, dfas)
      match_end = nil
      # Get dfas for current state
      string.each_char_with_index do |c, i|
        break unless dfas.size > 0

        # Check each for each  DFA if current char 'c' lays in its range
        # If it doesn't its removed from 'dfas'
        dfas = dfas.compact_map do |d|
          if dd = d[0].next.find { |x| x[0][0] <= c.ord <= x[0][1] }.try(&.[1])
            match_end = {i + 1, d[1]} if dd.accept
            {dd, d[1]}
          end
        end

      end
      unless match_end
        env.lexing_error.new(env.stream_offset, env.line, env.column, string)
        return {0, 0}
      end
      match_end
    end
  end

  module ScannerFrontend
    macro rule(expression, state = :default, flags = nil, &block)
      {% if expression.is_a? RegexLiteral %}
        rex_rule({{expression.source}}, {{state}}, {{flags}}) {{block}}
      {% else %}
        string_rule({{expression}}, {{state}}, {{flags}}) {{block}}
      {% end %}
    end

    # macro for creating a RegExp Rule
    macro rex_rule(rule, state, flags, &block)
      {% begin %}
        {% unless block.is_a?(Nop) %}
          @@callbacks.unshift(block_to_proc {{block}})
        {% end %}
        @@rx[{ {{state}}, {{flags}} }] ||= Array({DFA::DFA::DState, Int32?}).new
        @@rx[{ {{state}}, {{flags}} }].unshift ({ DFA::RegExp.new({{rule}}).dfa,
                                        {% if block.is_a?(Nop) %}
                                          nil
                                        {% else %}
                                          @@callbacks.size
                                        {% end %}
                                  })
      {% end %}
    end

    # macro for adding a String to the states String Matching DFA
    macro string_rule(string, state, flags, &block)
      @@strings[ { {{state}}, {{flags}} } ] ||= Hash(String, ProcType?).new
      @@strings[ { {{state}}, {{flags}} }][{{string}}] = block_to_proc {{block}}
    end

    # wrap the given block to be yielded in an Environment
    macro block_to_proc(&block)
      {% unless block.is_a? Nop %}
        ProcType.new do |{{block.args.first}}, env|
          env.yield_with_self do
            {{block.body}}
          end
        end
      {% else %}
        nil
      {% end %}
    end
  end

  abstract class BaseScanner
    macro body(t)
      alias TokenValue = {{t}}
      body
    end

    macro body
      CLTK.type_defs
      class_properties
      CLTK.environment
      def_lex
      def_finalize
    end

    macro class_properties
      @@strings = Hash({Symbol, Array(Symbol)?}, Hash(String, ProcType?)).new
      @@callbacks = Array(ProcType).new
      @@rx = Hash({Symbol, Array(Symbol)?}, Array({DFA::DFA::DState, Int32?})).new
      @@is_finalized = false

      # In order to speed up lexing, the string might be split
      # in single lines and therefore fed to the dfas in smaller
      # chunks. this is enabled by default, but can be disabled
      # with this class setter
      class_property split_lines : Bool = true
    end

    macro def_lex
      def self.lex(string)
        finalize unless @@is_finalized
        CLTK::ScannerMethods.lex(string, Environment.new(:default), @@rx, @@callbacks, @@split_lines)
      end

      def lex(string)
        self.class.lex string
      end
    end

    macro def_finalize
      # finalize the Lexer by creating dfas for the provided
      # string rules for fast keyword matching
      def self.finalize
        return if @@is_finalized
        @@strings.each do |state, hash|
          # Create a Regex Union for all strings
          litdfa = DFA::RegExp.new(hash.map { |k, _| Regex.escape(k) }.join("|")).dfa
          # Add it to the regex rules
          @@rx[state] ||= Array({DFA::DFA::DState, Int32?}).new
          @@rx[state] << ({litdfa, @@callbacks.size + 1})
          # Create the callback by merging all into one in which each is indexed
          # by the string
          cb = ProcType.new { |string, env| hash[string].try &.call(string, env) }
          @@callbacks.unshift cb
        end
      @@is_finalized = true
      end
    end
  end

  abstract class Scanner(T) < BaseScanner
    include ScannerFrontend

    macro inherited
        body T
    end
  end

  abstract class GenericScanner < BaseScanner
    include ScannerFrontend

    macro inherited
      body
    end
  end
end
