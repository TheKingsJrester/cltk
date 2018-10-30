module CLTK
  macro type_defs
      alias BlockReturn = Tuple(Symbol, TokenValue) | Tuple(Symbol) | Symbol
      alias Token = NamedTuple(type: Symbol, value: TokenValue?, position: TokenPosition)
      alias TokenPosition = NamedTuple(start: Position, "end": Position)
      alias Position = NamedTuple(line: UInt32, column: UInt32)
      alias ProcType = Proc(String, Environment, BlockReturn?)
  end
end
