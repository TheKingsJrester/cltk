require "string_scanner"

require "./lexer/exceptions"
require "./lexer/environment"
require "./lexer/types"

module CLTK
  module LexerFrontend
    macro rule(expression, state = :default, flags = nil, &block)
      @@rules[{ {{state}}, {{flags}} }] ||= Hash(Regex, ProcType?).new
      {% if expression.is_a? StringLiteral %}
        regexp = Regex.new Regex.escape({{expression}})
      {% else %}
        regexp = {{expression}}
      {% end %}
      @@rules[{ {{state}}, {{flags}} }][regexp] = block_to_proc {{block}}
    end

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

  module LexerMethods
    extend self

    def lex(input : String, env, rules, match_first = true)
      scanner = StringScanner.new(input)
      changed = false
      current_rules = nil
      until scanner.eos?
        match = nil

        if changed || !current_rules
          current_rules = rules[{env.state, (env.flags.empty? ? nil : env.flags.to_a)}]
        end

        current_rules.each do |rule, callback|

          if txt = scanner.check(rule)
            if !match || match.first.size < txt.size
              match = {txt, callback}
              break if match_first
            end
          end
        end

        if match
          scanner.offset += match[0].size
          token_start = env.position
          env.compute_position match[0]
          if (callback = match[1])
            res = callback.call(match[0], env)
            if res
              env.add_token res, token_start
            end
          end
        else
          env.lexing_error(scanner.rest)
        end

        changed ||= env.changed?
        env.reset_changed

      end
      env
    end
  end

  abstract class BaseLexer
    macro body(t)
      alias TokenValue = {{t}}
      body
    end

    macro body
      CLTK.type_defs
      class_properties
      CLTK.environment
      def_lex
    end

    macro class_properties
      @@rules = Hash({Symbol, Array(Symbol)?}, Hash(Regex, ProcType?)).new
    end

    macro def_lex
      def self.lex(string)
        CLTK::LexerMethods.lex string, Environment.new(:default), @@rules
      end

      def lex(string)
        self.class.lex string
      end
    end
  end

  abstract class Lexer(T) < BaseLexer
    include LexerFrontend

    macro inherited
      body T
    end
  end

  abstract class GenericLexer < BaseLexer
    include LexerFrontend

    macro inherited
      body
    end
  end
end
