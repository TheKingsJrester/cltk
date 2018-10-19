require "crystal-dfa"
require "ecr"

module CLTK
  class ScannerSerializer
    alias DFAStates = Hash(Symbol, Hash(UInt64, {DFA::DFA::DState, Int32?}))

    alias DStateType = NamedTuple(accept: Bool, next: Array(NamedTuple(atom: Tuple(Int32, Int32), state: UInt64))?, callback: Int32?)

    alias DFAStateHash = Hash(Symbol, Hash(UInt64, DStateType))

    alias Callback = NamedTuple(arg: String?, body: String)

    private def self.add_dfa_state(dfa_state : {DFA::DFA::DState, Int32?}, dfa_states : Hash(UInt64, {DFA::DFA::DState, Int32?}))
      unless dfa_states[dfa_state[0].object_id.hash]?
        dfa_states[dfa_state[0].object_id.hash] = dfa_state
        dfa_state[0].next.each do |state|
          add_dfa_state({state[1], nil}, dfa_states)
        end
      end
    end

    # Collects all DFA states and creates a Hash with each State indexed by a unique number
    private def self.collect_dfa_states(rx : Hash(Symbol, Array({DFA::DFA::DState, Int32?}))) : DFAStates
      rx.each_with_object(DFAStates.new) do |(scanner_state, states), dfa_states|
        states.each do |state|
          dfa_states[scanner_state] ||= Hash(UInt64, {DFA::DFA::DState, Int32?}).new
          add_dfa_state state, dfa_states[scanner_state]
        end
      end
    end

    # Transfrom the 'DState's into 'DStateType's
    private def self.transform_dfa_states(dfa_states : DFAStates) : DFAStateHash
      dfa_state_types = Hash(Symbol, Hash(UInt64, DStateType)).new
      dfa_states.each do |scanner_state, dfa_scanner_state_hash|
        dfa_scanner_state_hash.each do |dfa_state_hash, dfa_state|
          dfa_state_types[scanner_state] ||= Hash(UInt64, DStateType).new

          _next = dfa_state[0].next.each_with_object(Array(NamedTuple(atom: {Int32, Int32}, state: UInt64)).new) do | (atom_type, d_state), _next |
            _next << { atom: atom_type, state: d_state.object_id.hash }
          end

          _next = nil if _next.empty?

          dfa_state_types[scanner_state][dfa_state_hash] = {accept: dfa_state[0].accept, next: _next, callback: dfa_state[1]}
        end
      end
      dfa_state_types
    end

    # Collects the callbacks fro all regex and strings
    private def self.collect_callbacks(raw_callbacks)
      callbacks = Array(Callback).new

      raw_callbacks[0].each do |rx, rx_callback|
        callbacks << {arg: rx_callback[:arg], body: rx_callback[:body]}
      end

      callbacks << {arg: "string", body: "STRING_CALLBACKS[string].try &.call(string, env)"}

      {callbacks: callbacks, string_callbacks: raw_callbacks[1]}
    end

    # Collects all necessary data and makes it serializable
    def self.serialize(rx, raw_callbacks)
      dfa_states = collect_dfa_states rx
      dfa_states = transform_dfa_states dfa_states
      callback_data = collect_callbacks raw_callbacks

      {dfa_states: dfa_states, callback_data: callback_data}
    end

    private def self.write_to_io(io : IO, dfa_table, callbacks, string_callbacks,
                        wrap_module : Bool, module_name : String,
                        token_value : String)
      ECR.embed "cltk/templates/scanner_template.ecr", io
      io
    end

    # writes *data* to *path*, and wraps into module *module_name* if *wrap_module* is true
    def self.write_to_file(data, path : String, wrap_module, module_name)
      File.open path, mode: "w" do |file|
        write_to_io data, file, wrap_module, module_name
      end
    end

    # writes *data* to *io*, and wraps into module *module_name* if *wrap_module* is true
    def self.write_to_io(data, io, wrap_module, module_name)
      dfa_table = data[:dfa_states]
      callbacks = data[:callback_data][:callbacks]
      string_callbacks = data[:callback_data][:string_callbacks]
      token_value = TokenValue.to_s
      write_to_io io, dfa_table, callbacks, string_callbacks, wrap_module, module_name, token_value
    end
  end
end
