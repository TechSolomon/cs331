-- interpit.lua
-- Solomon Himelbloom
-- Glenn G. Chappell
-- 2022-03-30
--
-- For CS F331 / CSCE A331 Spring 2022
-- Interpret AST from parseit.parse
-- Solution to Assignment 6, Exercise 2


-- *** To run a Tenrec program, use tenrec.lua, which uses this file.


-- *********************************************************************
-- Module Table Initialization
-- *********************************************************************


local interpit = {}  -- Our module


-- *********************************************************************
-- Symbolic Constants for AST
-- *********************************************************************


local STMT_LIST    = 1
local PRINT_STMT   = 2
local RETURN_STMT  = 3
local ASSN_STMT    = 4
local FUNC_CALL    = 5
local FUNC_DEF     = 6
local IF_STMT      = 7
local WHILE_LOOP   = 8
local STRLIT_OUT   = 9
local CR_OUT       = 10
local CHAR_CALL    = 11
local BIN_OP       = 12
local UN_OP        = 13
local NUMLIT_VAL   = 14
local BOOLLIT_VAL  = 15
local READ_CALL    = 16
local SIMPLE_VAR   = 17
local ARRAY_VAR    = 18


-- *********************************************************************
-- Utility Functions
-- *********************************************************************


-- numToInt
-- Given a number, return the number rounded toward zero.
local function numToInt(n)
    assert(type(n) == "number")

    if n >= 0 then
        return math.floor(n)
    else
        return math.ceil(n)
    end
end


-- strToNum
-- Given a string, attempt to interpret it as an integer. If this
-- succeeds, return the integer. Otherwise, return 0.
local function strToNum(s)
    assert(type(s) == "string")

    -- Try to do string -> number conversion; make protected call
    -- (pcall), so we can handle errors.
    local success, value = pcall(function() return tonumber(s) end)

    -- Return integer value, or 0 on error.
    if success then
        if value == nil then
            return 0
        else
            return numToInt(value)
        end
    else
        return 0
    end
end


-- numToStr
-- Given a number, return its string form.
local function numToStr(n)
    assert(type(n) == "number")

    return tostring(n)
end


-- boolToInt
-- Given a boolean, return 1 if it is true, 0 if it is false.
local function boolToInt(b)
    assert(type(b) == "boolean")

    if b then
        return 1
    else
        return 0
    end
end


-- astToStr
-- Given an AST, produce a string holding the AST in (roughly) Lua form,
-- with numbers replaced by names of symbolic constants used in parseit.
-- A table is assumed to represent an array.
-- See the Assignment 4 description for the AST Specification.
--
-- THIS FUNCTION IS INTENDED FOR USE IN DEBUGGING ONLY!
-- IT SHOULD NOT BE CALLED IN THE FINAL VERSION OF THE CODE.
function astToStr(x)
    local symbolNames = {
        "STMT_LIST", "PRINT_STMT", "RETURN_STMT", "ASSN_STMT",
        "FUNC_CALL", "FUNC_DEF", "IF_STMT", "WHILE_LOOP", "STRLIT_OUT",
        "CR_OUT", "CHAR_CALL", "BIN_OP", "UN_OP", "NUMLIT_VAL",
        "BOOLLIT_VAL", "READ_CALL", "SIMPLE_VAR", "ARRAY_VAR",
    }
    if type(x) == "number" then
        local name = symbolNames[x]
        if name == nil then
            return "<Unknown numerical constant: "..x..">"
        else
            return name
        end
    elseif type(x) == "string" then
        return '"'..x..'"'
    elseif type(x) == "boolean" then
        if x then
            return "true"
        else
            return "false"
        end
    elseif type(x) == "table" then
        local first = true
        local result = "{"
        for k = 1, #x do
            if not first then
                result = result .. ","
            end
            result = result .. astToStr(x[k])
            first = false
        end
        result = result .. "}"
        return result
    elseif type(x) == "nil" then
        return "nil"
    else
        return "<"..type(x)..">"
    end
end


-- *********************************************************************
-- Primary Function for Client Code
-- *********************************************************************


-- interp
-- Interpreter, given AST returned by parseit.parse.
-- Parameters:
--   ast     - AST constructed by parseit.parse
--   state   - Table holding Tenrec variables & functions
--             - AST for function xyz is in state.f["xyz"]
--             - Value of simple variable xyz is in state.v["xyz"]
--             - Value of array item xyz[42] is in state.a["xyz"][42]
--   incall  - Function to call for line input
--             - incall() inputs line, returns string with no newline
--   outcall - Function to call for string output
--             - outcall(str) outputs str with no added newline
--             - To print a newline, do outcall("\n")
-- Return Value:
--   state, updated with changed variable values
function interpit.interp(ast, state, incall, outcall)
    -- Each local interpretation function is given the AST for the
    -- portion of the code it is interpreting. The function-wide
    -- versions of state, incall, and outcall may be used. The
    -- function-wide version of state may be modified as appropriate.


    -- Forward declare local functions
    local interp_stmt_list
    local interp_stmt
    local eval_expr


    -- interp_stmt_list
    -- Given the ast for a statement list, execute it.
    function interp_stmt_list(ast)
        for i = 2, #ast do
            interp_stmt(ast[i])
        end
    end


    -- interp_stmt
    -- Given the ast for a statement, execute it.
    function interp_stmt(ast)
        if ast[1] == PRINT_STMT then
            for i = 2, #ast do
                if ast[i][1] == STRLIT_OUT then
                    local str = ast[i][2]
                    outcall(str:sub(2, str:len()-1))
                elseif ast[i][1] == CR_OUT then
                    outcall("\n")
                elseif ast[i][1] == CHAR_CALL then
                    local value = eval_expr(ast[i][2])
                    if (value < 0) or (value > 255) then
                        value = 0
                    end
                    outcall(string.char(value))
                else  -- Expression
                    local val = eval_expr(ast[i])
                    outcall(numToStr(val))
                end
            end
        elseif ast[1] == FUNC_DEF then
            local funcname = ast[2]
            local funcbody = ast[3]
            state.f[funcname] = funcbody
        elseif ast[1] == FUNC_CALL then
            local funcname = ast[2]
            local funcbody = state.f[funcname]
            if funcbody == nil then
                funcbody = { STMT_LIST }
            end
            interp_stmt_list(funcbody)
            if state.v["return"] ~= nil then
                result = state.v["return"]
            else
                result = 0
            end
        elseif ast[1] == ASSN_STMT then
            local varname = ast[2][2]
            local varval = eval_expr(ast[3])
            if ast[2][1] == SIMPLE_VAR then
                state.v[varname] = varval
            elseif ast[2][1] == ARRAY_VAR then
                local index = eval_expr(ast[2][3])
                if (state.a[varname] == nil) then
                    state.a[varname] = {}
                end
                state.a[varname][index] = varval
            end
        elseif ast[1] == IF_STMT then
            local endpoint = false
            for location = 2, #ast-1, 2 do
                if (eval_expr(ast[location]) ~= 0) then
                    interp_stmt_list(ast[location+1])
                    endpoint = true
                    break
                end
            end
            if (not endpoint) and (#ast % 2 == 0) then
                interp_stmt_list(ast[#ast])
                return
            end
        elseif ast[1] == WHILE_LOOP then
            while (eval_expr(ast[2]) ~= 0) do
                interp_stmt_list(ast[3])
            end
                elseif ast[1] == RETURN_STMT then
            local val = eval_expr(ast[2])
            state.v["return"] = val
        else
            print("*** UNIMPLEMENTED STATEMENT")
        end
    end


    -- eval_expr
    -- Given the AST for an expression, evaluate it and return the
    -- value.
    function eval_expr(ast)
        local result

        if ast[1] == NUMLIT_VAL then
            result = strToNum(ast[2])
        elseif ast[1] == BOOLLIT_VAL then
            local boolval = ast[2]
            if boolval == "true" then
                result = 1
            else
                result = 0
            end
        elseif ast[1] == SIMPLE_VAR then
            local varname = ast[2]
            result = state.v[varname]
            if (result == nil) then
                result = 0
            else
                result = result
            end
        elseif ast[1] == FUNC_CALL then
            local funcname = ast[2]
            local funcbody = state.f[funcname]
            if funcbody == nil then
                funcbody = { STMT_LIST }
            end
            interp_stmt_list(funcbody)
            if state.v["return"] ~= nil then
                result = state.v["return"]
            else
                result = 0
            end
        elseif ast[1] == READ_CALL then
            local location = incall()
            result = strToNum(location)
        elseif ast[1] == ARRAY_VAR then
            local structure = ast[2]
            local index = eval_expr(ast[3])
            if state.a[structure] == nil then
                result = 0
            elseif state.a[structure][index] == nil then
                result = 0
            else
                result = state.a[structure][index]
            end
        elseif ast[1][1] == BIN_OP then
            local op = ast[1][2]
            local left = eval_expr(ast[2])
            local right = eval_expr(ast[3])

            if op == "+" then
                result = left + right
            elseif op == "-" then
                result = left - right
            elseif op == "*" then
                result = left * right
            elseif op == "/" then
                if right == 0 then
                    result = 0
                else
                    result = numToInt(left / right)
                end
            elseif op == "%" then
                if right == 0 then
                    result = 0
                else
                    result = left % right
                end
            elseif op == "==" then
                result = boolToInt(left == right)
            elseif op == "!=" then
                result = boolToInt(left ~= right)
            elseif op == "<" then
                result = boolToInt(left < right)
            elseif op == "<=" then
                result = boolToInt(left <= right)
            elseif op == ">" then
                result = boolToInt(left > right)
            elseif op == ">=" then
                result = boolToInt(left >= right)
            elseif op == "and" then
                if left == 0 or right == 0 then
                    result = 0
                else
                    result = 1
                end
            elseif op == "or" then
                if left == 0 and right == 0 then
                    result = 0
                else
                    result = 1
                end
            end
        elseif ast[1][1] == UN_OP then
            local op = ast[1][2]
            local value = eval_expr(ast[2])
            if op == "-" then
                result = -value
            elseif op == "+" then
                result = value
            elseif op == "not" then
                if value == 0 then
                    result = 1
                else
                    result = 0
                end
            end
        else
            print("*** UNIMPLEMENTED EXPRESSION")
            result = 42  -- DUMMY VALUE
        end

        return result
    end


    -- Body of function interp
    interp_stmt_list(ast)
    return state
end


-- *********************************************************************
-- Module Table Return
-- *********************************************************************


return interpit

