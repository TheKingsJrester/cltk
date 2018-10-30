# 0.1.2

- Completely rewrite Lexer and Scanner
- Lexer and Scanner now use the same Tokentype and Position types so no more `LexerCompatibility`
- Lexer and Scanner are now split up into 3 differnt parts:
  - Frontend (Implements the DSL for defining rules)
  - Methods (Implements the lexing methods)
  - Base (Includes all necessary methods and constructs the lexer/scanner)
- Environment is now the same for both
- Scanner now also supports flags
- TokenValue must now be directly declared for the Scanner/Lexer
