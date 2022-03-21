#!/usr/bin/env lua
-- lexit.lua
-- Solomon Himelbloom
-- 2022-02-08
-- Assignment 3, Exercise 2: Lexer in Lua
-- 
-- Adapted from source:
-- https://github.com/ggchappell/cs331-2022-01/blob/main/lexer.lua

local lexit = {} -- Module table

-- Numeric constants representing lexeme categories.
lexit.KEY = 1
lexit.ID = 2
lexit.NUMLIT = 3
lexit.STRLIT = 4
lexit.OP = 5
lexit.PUNCT = 6
lexit.MAL = 7

-- catnames
lexit.catnames = {
  "Keyword",
  "Identifier",
  "NumericLiteral",
  "StringLiteral",
  "Operator",
  "Punctuation",
  "Malformed"
}

local function isLetter(c)
  if c:len() ~= 1 then
    return false
  elseif c >= "A" and c <= "Z" then
    return true
  elseif c >= "a" and c <= "z" then
    return true
  else
    return false
  end
end

local function isDigit(c)
  if c:len() ~= 1 then
    return false
  elseif c >= "0" and c <= "9" then
    return true
  else
    return false
  end
end

local function isWhitespace(c)
  if c:len() ~= 1 then
      return false
  elseif c == " " or c == "\t" or c == "\n" or c == "\r"
    or c == "\f" then
      return true
  else
    return false
  end
end

local function isPrintableASCII(c)
  if c:len() ~= 1 then
    return false
  elseif c >= " " and c <= "~" then
    return true
  else
    return false
  end
end

local function isIllegal(c)
  if c:len() ~= 1 then
    return false
  elseif isWhitespace(c) then
    return false
  elseif isPrintableASCII(c) then
    return false
  else
    return true
  end
end

function lexit.lex(program)
  -- VARIABLES
  local pos
  local state
  local ch
  local lexstr
  local category
  local handlers
  
  -- STATES
  local DONE = 0
  local START = 1
  local LETTER = 2
  local DIGIT = 3
  local DIGDOT = 4
  local DOT = 5
  local PLUS = 6
  local MINUS = 7
  local STAR = 8
  local STRING = 9
  local OPERATOR = 10
  local EXPONENT = 11

  -- currChar
  local function currChar()
    return program:sub(pos, pos)
  end

  -- nextChar
  local function nextChar()
    return program:sub(pos+1, pos+1)
  end
  
  -- shiftChar
  local function shiftChar(n)
    return program:sub(pos+n, pos+n)
  end

  -- drop1
  local function drop1()
    pos = pos+1
  end

  -- add1
  local function add1()
    lexstr = lexstr .. currChar()
    drop1()
  end

  -- skipToNextLexeme
  local function skipToNextLexeme()
    while true do
      -- Skip whitespace characters
      while isWhitespace(currChar()) do
        drop1()
      end

      -- Done if no comment
      if currChar() ~= "#" then
        break
      end

      -- Skip comment
      drop1() -- Drop leading "#"
      while true do
        if currChar() == "\n" then
          drop1() -- Drop trailing "\n"
          break
        elseif currChar() == "" then -- End of input?
          return
        end
        drop1() -- Drop character inside comment
      end
    end
  end

  local function handle_DONE()
    error("'DONE' state should not be handled\n")
  end

  -- State START: no character read yet.
  local function handle_START()
    if isIllegal(ch) then
      add1()
      state = DONE
      category = lexit.MAL
    elseif isLetter(ch) 
    or ch == "_" then
      add1()
      state = LETTER
    elseif isDigit(ch) then
      add1()
      state = DIGIT
    elseif ch == "." then
      add1()
      state = DONE
      category = lexit.PUNCT
    elseif ch == "+" then
      add1()
      state = DONE
      category = lexit.OP
    elseif ch == "-" then
      add1()
      state = DONE
      category = lexit.OP
    elseif ch == "*"
    or ch == "%"
    or ch == "/"
    or ch == "[" 
    or ch == "]" then
      add1()
      state = STAR
    elseif ch == "!" 
    and nextChar() == "=" then
      add1()
      state = OPERATOR
    elseif ch == "<" 
    or ch == ">"
    or ch == "=" then
      add1()
      state = OPERATOR
    elseif ch == "\'" 
    or ch == "\"" then
      add1()
      state = STRING
    else
      add1()
      state = DONE
      category = lexit.PUNCT
    end
  end

  -- State LETTER: we are in an ID.
  local function handle_LETTER()
    if isLetter(ch) or ch == "_" or isDigit(ch) then
      add1()
    else
      state = DONE
      if lexstr == "and"
      or lexstr == "char"
      or lexstr == "cr"
      or lexstr == "elif"
      or lexstr == "else"
      or lexstr == "false"
      or lexstr == "func"
      or lexstr == "if"
      or lexstr == "not"
      or lexstr == "or"
      or lexstr == "print"
      or lexstr == "read"
      or lexstr == "return"
      or lexstr == "true"
      or lexstr == "while" then
        category = lexit.KEY
      else
        category = lexit.ID
      end
    end
  end

  -- State DIGIT: we are in a NUMLIT, and we have NOT seen ".".
  local function handle_DIGIT()
    if isDigit(ch) then
      add1()
    elseif ch == "." then
      state = DIGDOT
    elseif ch == "e" or ch == "E" then
      if nextChar() == "+" and isDigit(shiftChar(2)) then
        add1()
        add1()
        state = EXPONENT
      elseif isDigit(nextChar()) then
        add1()
        state = EXPONENT
      end
      state = EXPONENT
    else
      state = DONE
      category = lexit.NUMLIT
    end
  end

  -- State DIGDOT: we are in a NUMLIT, and we have seen ".".
  local function handle_DIGDOT()
    if isDigit(ch) then
      add1()
    else
      state = DONE
      category = lexit.NUMLIT
    end
  end

  -- State DOT: we have seen a dot (".") and nothing else.
  local function handle_DOT()
    if isDigit(ch) then
      add1()
      state = DIGDOT
    else
      state = DONE
      category = lexit.PUNCT
    end
  end

  -- State PLUS: we have seen a plus ("+") and nothing else.
  local function handle_PLUS()
    if isDigit(ch) then
      add1()
      state = DIGIT
    elseif ch == "." then
      if isDigit(nextChar()) then  -- lookahead
          add1() -- add dot to lexeme
          state = DIGDOT
        else -- lexeme is just "+"; do not add dot to lexeme
          state = DONE
          category = lexit.OP
        end
    elseif ch == "+" or ch == "=" then
      add1()
      state = DONE
      category = lexit.OP
    else
      state = DONE
      category = lexit.OP
    end
  end

  -- State MINUS: we have seen a minus ("-") and nothing else.
  local function handle_MINUS()
    if isDigit(ch) then
      add1()
      state = DIGIT
    elseif ch == "." then
      if isDigit(nextChar()) then  -- lookahead
        add1() -- add dot to lexeme
        state = DIGDOT
      else -- lexeme is just "-"; do not add dot to lexeme
        state = DONE
        category = lexit.OP
      end
    elseif ch == "-" or ch == "=" then
      add1()
      state = DONE
      category = lexit.OP
    else
      state = DONE
      category = lexit.OP
    end
  end

  -- State STAR: we have seen a star ("*"), slash ("/"), or equal ("=") and nothing else.
  local function handle_STAR() -- Handle * or / or =
    state = DONE
    category = lexit.OP
  end
  
  -- State STRING
  local function handle_STRING()
    if ch == "\"" then
      add1()
      state = DONE
      category = lexit.STRLIT
    elseif ch == "" or ch == "\n" then
      state = DONE
      category = lexit.MAL
    else
      add1()
    end
  end
  
  -- State OPERATOR
  local function handle_OPERATOR()
    if ch == "=" then
      add1()
      state = DONE
      category = lexit.OP
    else
      state = DONE
      category = lexit.OP
    end
  end
  
  -- State EXPONENT
  local function handle_EXPONENT()
    if isDigit(ch) then
      add1()
    else
      state = DONE
      category = lexit.NUMLIT
    end
  end

  handlers = {
    [DONE]=handle_DONE,
    [START]=handle_START,
    [LETTER]=handle_LETTER,
    [DIGIT]=handle_DIGIT,
    [DIGDOT]=handle_DIGDOT,
    [DOT]=handle_DOT,
    [PLUS]=handle_PLUS,
    [MINUS]=handle_MINUS,
    [STAR]=handle_STAR,
    [STRING]=handle_STRING,
    [OPERATOR]=handle_OPERATOR,
    [EXPONENT]=handle_EXPONENT
  }

  -- getLexeme
  local function getLexeme(dummy1, dummy2)
    if pos > program:len() then
      return nil, nil
    end
    lexstr = ""
    state = START
    while state ~= DONE do
      ch = currChar()
      handlers[state]()
    end

    skipToNextLexeme()
    return lexstr, category
  end

  -- Initialize & return the iterator function.
  pos = 1
  skipToNextLexeme()
  return getLexeme, nil, nil
end

return lexit -- Return the module, so client code can use it.
