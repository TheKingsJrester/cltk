require "benchmark"
require "json"

require "../cltk/lexer"
require "../cltk/scanner"

  class JsonLexer < CLTK::Lexer((Int32|String|Float64)?)

    # Skip whitespace.
    rule("\n")
    rule(" ")

    rule(":")  {:COLON}
    rule("[")  {:LBRACK}
    rule("]")  {:RBRACK}
    rule("{")  {:LCBRACK}
    rule("}")  {:RCBRACK}
    rule(",")  {:COMMA}

    rule("true")  { {:BOOL, 0}}
    rule("false")  { {:BOOL, 1}}
    rule("null")  { {:NULL, nil}}

    # String with included quoted strings
    rule(/"(?:[^"\\]|\\.)*"/) { |t| {:STRING, t[1...-1]} }

    # Numeric rules.
    rule(/\-?\d+/) { |t| {:INTEGER, t.to_i} }
    rule(/\-?\d+\.\d+/) { |t| {:FLOAT, t.to_f} }
  end

  class JsonScanner < CLTK::Scanner((Int32|String|Float64)?)

    # Skip whitespace.
    rule("\n")
    rule(" ")

    rule(":")  {:COLON}
    rule("[")  {:LBRACK}
    rule("]")  {:RBRACK}
    rule("{")  {:LCBRACK}
    rule("}")  {:RCBRACK}
    rule(",")  {:COMMA}

    rule("true")  { {:BOOL, 0}}
    rule("false")  { {:BOOL, 1}}
    rule("null")  { {:NULL, nil}}

    # String with included quoted strings
    rule(/"(?:[^"\\]|\\.)*"/) { |t| {:STRING, t[1...-1]} }

    # Numeric rules.
    rule(/\-?\d+/) { |t| {:INTEGER, t.to_i} }
    rule(/\-?\d+\.\d+/) { |t| {:FLOAT, t.to_f} }
  end

txt = "{
  \"username\": \"walter\",
  \"friends\": [
      \"granny\",
      \"sophia\",
      \"maud\"
  ],
  \"address\": {
      \"street\": \"neverstreet\",
      \"number\": 12,
      \"city\": \"nowhere\"
  }
}"

Benchmark.ips do |x|
  x.report("Lexer") do
    JsonLexer.lex(txt)
  end

  x.report("Scanner") do
    JsonScanner.lex(txt)
  end

  x.report("STDLIB") do
    JSON.parse(txt)
  end
end
