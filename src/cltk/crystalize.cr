require "./version"
require "./lexer/crystalize"

module CLTK
  class Scanner
    def self.serialize
      finalize unless @@is_finalized
      ScannerSerializer.serialize @@rx, @@raw_callbacks
    end

    # Serializes the scanner and writes to *path*
    def self.serialize_to_file(path : String, wrap_module : Bool=false, module_name : String="")
      ScannerSerializer.write_to_file(serialize, path, wrap_module, module_name)
    end

    # Serializes the scanner and writes to *io*
    def self.serialize_to_io(io, wrap_module : Bool=false, module_name : String="")
      ScannerSerializer.write_to_io(serialize, io, wrap_module, moudle_name)
    end
  end
end
