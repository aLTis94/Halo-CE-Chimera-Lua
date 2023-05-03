
---------------------------------------------------------
---------------- Auto Bundled Code Block ----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["lanes"] = function()
--------------------
-- Module: 'lanes'
--------------------
--
-- LANES.LUA
--
-- Multithreading and -core support for Lua
--
-- Authors: Asko Kauppi <akauppi@gmail.com>
--          Benoit Germain <bnt.germain@gmail.com>
--
-- History: see CHANGES
--
--[[
===============================================================================

Copyright (C) 2007-10 Asko Kauppi <akauppi@gmail.com>
Copyright (C) 2010-13 Benoit Germain <bnt.germain@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

===============================================================================
]]--

local core = require "lanes.core"
-- Lua 5.1: module() creates a global variable
-- Lua 5.2: module() is gone
-- almost everything module() does is done by require() anyway
-- -> simply create a table, populate it, return it, and be done
local lanesMeta = {}
local lanes = setmetatable( {}, lanesMeta)

-- this function is available in the public interface until it is called, after which it disappears
lanes.configure = function( settings_)

    -- This check is for sublanes requiring Lanes
    --
    -- TBD: We could also have the C level expose 'string.gmatch' for us. But this is simpler.
    --
    if not string then
        error( "To use 'lanes', you will also need to have 'string' available.", 2)
    end
    -- Configure called so remove metatable from lanes
    setmetatable( lanes, nil)
    --
    -- Cache globals for code that might run under sandboxing
    --
    local assert = assert( assert)
    local string_gmatch = assert( string.gmatch)
    local string_format = assert( string.format)
    local select = assert( select)
    local type = assert( type)
    local pairs = assert( pairs)
    local tostring = assert( tostring)
    local error = assert( error)

    local default_params =
    {
        nb_keepers = 1,
        on_state_create = nil,
        shutdown_timeout = 0.25,
        with_timers = true,
        track_lanes = false,
        demote_full_userdata = nil,
        verbose_errors = false,
        -- LuaJIT provides a thread-unsafe allocator by default, so we need to protect it when used in parallel lanes
        allocator = (package.loaded.jit and jit.version) and "protected" or nil
    }
    local boolean_param_checker = function( val_)
        -- non-'boolean-false' should be 'boolean-true' or nil
        return val_ and (val_ == true) or true
    end
    local param_checkers =
    {
        nb_keepers = function( val_)
            -- nb_keepers should be a number > 0
            return type( val_) == "number" and val_ > 0
        end,
        with_timers = boolean_param_checker,
        allocator = function( val_)
            -- can be nil, "protected", or a function
            return val_ and (type( val_) == "function" or val_ == "protected") or true
        end,
        on_state_create = function( val_)
            -- on_state_create may be nil or a function
            return val_ and type( val_) == "function" or true
        end,
        shutdown_timeout = function( val_)
            -- shutdown_timeout should be a number >= 0
            return type( val_) == "number" and val_ >= 0
        end,
        track_lanes = boolean_param_checker,
        demote_full_userdata = boolean_param_checker,
        verbose_errors = boolean_param_checker
    }

    local params_checker = function( settings_)
        if not settings_ then
            return default_params
        end
        -- make a copy of the table to leave the provided one unchanged, *and* to help ensure it won't change behind our back
        local settings = {}
        if type( settings_) ~= "table" then
            error "Bad parameter #1 to lanes.configure(), should be a table"
        end
        -- any setting unknown to Lanes raises an error
        for setting, _ in pairs( settings_) do
            if not param_checkers[setting] then
            error( "Unknown parameter '" .. setting .. "' in configure options")
            end
        end
        -- any setting not present in the provided parameters takes the default value
        for key, checker in pairs( param_checkers) do
            local my_param = settings_[key]
            local param
            if my_param ~= nil then
                param = my_param
            else
                param = default_params[key]
            end
            if not checker( param) then
                error( "Bad " .. key .. ": " .. tostring( param), 2)
            end
            settings[key] = param
        end
        return settings
    end
    local settings = core.configure and core.configure( params_checker( settings_)) or core.settings
    local core_lane_new = assert( core.lane_new)
    local max_prio = assert( core.max_prio)

    lanes.ABOUT =
    {
        author= "Asko Kauppi <akauppi@gmail.com>, Benoit Germain <bnt.germain@gmail.com>",
        description= "Running multiple Lua states in parallel",
        license= "MIT/X11",
        copyright= "Copyright (c) 2007-10, Asko Kauppi; (c) 2011-19, Benoit Germain",
        version = assert( core.version)
    }


    -- Making copies of necessary system libs will pass them on as upvalues;
    -- only the first state doing "require 'lanes'" will need to have 'string'
    -- and 'table' visible.
    --
    local function WR(str)
        io.stderr:write( str.."\n" )
    end

    local function DUMP( tbl )
        if not tbl then return end
        local str=""
        for k,v in pairs(tbl) do
            str= str..k.."="..tostring(v).."\n"
        end
        WR(str)
    end


    ---=== Laning ===---

    -- lane_h[1..n]: lane results, same as via 'lane_h:join()'
    -- lane_h[0]:    can be read to make sure a thread has finished (always gives 'true')
    -- lane_h[-1]:   error message, without propagating the error
    --
    --      Reading a Lane result (or [0]) propagates a possible error in the lane
    --      (and execution does not return). Cancelled lanes give 'nil' values.
    --
    -- lane_h.state: "pending"/"running"/"waiting"/"done"/"error"/"cancelled"
    --
    -- Note: Would be great to be able to have '__ipairs' metamethod, that gets
    --      called by 'ipairs()' function to custom iterate objects. We'd use it
    --      for making sure a lane has ended (results are available); not requiring
    --      the user to precede a loop by explicit 'h[0]' or 'h:join()'.
    --
    --      Or, even better, 'ipairs()' should start valuing '__index' instead
    --      of using raw reads that bypass it.
    --
    -----
    -- lanes.gen( [libs_str|opt_tbl [, ...],] lane_func ) ( [...] ) -> h
    --
    -- 'libs': nil:     no libraries available (default)
    --         "":      only base library ('assert', 'print', 'unpack' etc.)
    --         "math,os": math + os + base libraries (named ones + base)
    --         "*":     all standard libraries available
    --
    -- 'opt': .priority:  int (-3..+3) smaller is lower priority (0 = default)
    --
    --        .globals:  table of globals to set for a new thread (passed by value)
    --
    --        .required: table of packages to require
    --
    --        .gc_cb:    function called when the lane handle is collected
    --
    --        ... (more options may be introduced later) ...
    --
    -- Calling with a function parameter ('lane_func') ends the string/table
    -- modifiers, and prepares a lane generator.

    local valid_libs =
    {
        ["package"] = true,
        ["table"] = true,
        ["io"] = true,
        ["os"] = true,
        ["string"] = true,
        ["math"] = true,
        ["debug"] = true,
        ["bit32"] = true, -- Lua 5.2 only, ignored silently under 5.1
        ["utf8"] = true, -- Lua 5.3 only, ignored silently under 5.1 and 5.2
        ["bit"] = true, -- LuaJIT only, ignored silently under PUC-Lua
        ["jit"] = true, -- LuaJIT only, ignored silently under PUC-Lua
        ["ffi"] = true, -- LuaJIT only, ignored silently under PUC-Lua
        --
        ["base"] = true,
        ["coroutine"] = true, -- part of "base" in Lua 5.1
        ["lanes.core"] = true
    }

    local raise_option_error = function( name_, tv_, v_)
        error( "Bad '" .. name_ .. "' option: " .. tv_ .. " " .. string_format( "%q", tostring( v_)), 4)
    end

    local opt_validators =
    {
        priority = function( v_)
            local tv = type( v_)
            return (tv == "number") and v_ or raise_option_error( "priority", tv, v_)
        end,
        globals = function( v_)
            local tv = type( v_)
            return (tv == "table") and v_ or raise_option_error( "globals", tv, v_)
        end,
        package = function( v_)
            local tv = type( v_)
            return (tv == "table") and v_ or raise_option_error( "package", tv, v_)
        end,
        required = function( v_)
            local tv = type( v_)
            return (tv == "table") and v_ or raise_option_error( "required", tv, v_)
        end,
        gc_cb = function( v_)
            local tv = type( v_)
            return (tv == "function") and v_ or raise_option_error( "gc_cb", tv, v_)
        end
    }

    -- PUBLIC LANES API
    -- receives a sequence of strings and tables, plus a function
    local gen = function( ...)
        -- aggregrate all strings together, separated by "," as well as tables
        -- the strings are a list of libraries to open
        -- the tables contain the lane options
        local opt = {}
        local libs = nil

        local n = select( '#', ...)

        -- we need at least a function
        if n == 0 then
            error( "No parameters!", 2)
        end

        -- all arguments but the last must be nil, strings, or tables
        for i = 1, n - 1 do
            local v = select( i, ...)
            local tv = type( v)
            if tv == "string" then
                libs = libs and libs .. "," .. v or v
            elseif tv == "table" then
                for k, vv in pairs( v) do
                    opt[k]= vv
                end
            elseif v == nil then
                -- skip
            else
                error( "Bad parameter " .. i .. ": " .. tv .. " " .. string_format( "%q", tostring( v)), 2)
            end
        end

        -- the last argument should be a function or a string
        local func = select( n, ...)
        local functype = type( func)
        if functype ~= "function" and functype ~= "string" then
            error( "Last parameter not function or string: " .. functype .. " " .. string_format( "%q", tostring( func)), 2)
        end

        -- check that the caller only provides reserved library names, and those only once
        -- "*" is a special case that doesn't require individual checking
        if libs and libs ~= "*" then
            local found = {}
            for s in string_gmatch(libs, "[%a%d.]+") do
                if not valid_libs[s] then
                    error( "Bad library name: " .. s, 2)
                else
                    found[s] = (found[s] or 0) + 1
                    if found[s] > 1 then
                        error( "libs specification contains '" .. s .. "' more than once", 2)
                    end
                end
            end
        end

        -- validate that each option is known and properly valued
        for k, v in pairs( opt) do
            local validator = opt_validators[k]
            if not validator then
                error( (type( k) == "number" and "Unkeyed option: " .. type( v) .. " " .. string_format( "%q", tostring( v)) or "Bad '" .. tostring( k) .. "' option"), 2)
            else
                opt[k] = validator( v)
            end
        end

        local priority, globals, package, required, gc_cb = opt.priority, opt.globals, opt.package or package, opt.required, opt.gc_cb
        return function( ...)
            -- must pass functions args last else they will be truncated to the first one
            return core_lane_new( func, libs, priority, globals, package, required, gc_cb, ...)
        end
    end -- gen()

    ---=== Timers ===---

    -- PUBLIC LANES API
    local timer = function() error "timers are not active" end
    local timers = timer
    local timer_lane = nil

    -- timer_gateway should always exist, even when the settings disable the timers
    local timer_gateway = assert( core.timer_gateway)

    -----
    -- <void> = sleep( [seconds_])
    --
    -- PUBLIC LANES API
    local sleep = function( seconds_)
        seconds_ = seconds_ or 0.0 -- this causes false and nil to be a valid input, equivalent to 0.0, but that's ok
        if type( seconds_) ~= "number" then
            error( "invalid duration " .. string_format( "%q", tostring(seconds_)))
        end
        -- receive data on a channel no-one ever sends anything, thus blocking for the specified duration
        return timer_gateway:receive( seconds_, "ac100de1-a696-4619-b2f0-a26de9d58ab8")
    end


    if settings.with_timers ~= false then

    --
    -- On first 'require "lanes"', a timer lane is spawned that will maintain
    -- timer tables and sleep in between the timer events. All interaction with
    -- the timer lane happens via a 'timer_gateway' Linda, which is common to
    -- all that 'require "lanes"'.
    --
    -- Linda protocol to timer lane:
    --
    --  TGW_KEY: linda_h, key, [wakeup_at_secs], [repeat_secs]
    --
    local TGW_KEY= "(timer control)"    -- the key does not matter, a 'weird' key may help debugging
    local TGW_QUERY, TGW_REPLY = "(timer query)", "(timer reply)"
    local first_time_key= "first time"

    local first_time = timer_gateway:get( first_time_key) == nil
    timer_gateway:set( first_time_key, true)

    --
    -- Timer lane; initialize only on the first 'require "lanes"' instance (which naturally
    -- has 'table' always declared)
    --
    if first_time then

        local now_secs = core.now_secs
        assert( type( now_secs) == "function")
        -----
        -- Snore loop (run as a lane on the background)
        --
        -- High priority, to get trustworthy timings.
        --
        -- We let the timer lane be a "free running" thread; no handle to it
        -- remains.
        --
        local timer_body = function()
            set_debug_threadname( "LanesTimer")
            --
            -- { [deep_linda_lightuserdata]= { [deep_linda_lightuserdata]=linda_h,
            --                                 [key]= { wakeup_secs [,period_secs] } [, ...] },
            -- }
            --
            -- Collection of all running timers, indexed with linda's & key.
            --
            -- Note that we need to use the deep lightuserdata identifiers, instead
            -- of 'linda_h' themselves as table indices. Otherwise, we'd get multiple
            -- entries for the same timer.
            --
            -- The 'hidden' reference to Linda proxy is used in 'check_timers()' but
            -- also important to keep the Linda alive, even if all outside world threw
            -- away pointers to it (which would ruin uniqueness of the deep pointer).
            -- Now we're safe.
            --
            local collection = {}
            local table_insert = assert( table.insert)

            local get_timers = function()
                local r = {}
                for deep, t in pairs( collection) do
                    -- WR( tostring( deep))
                    local l = t[deep]
                    for key, timer_data in pairs( t) do
                        if key ~= deep then
                            table_insert( r, {l, key, timer_data})
                        end
                    end
                end
                return r
            end -- get_timers()

            --
            -- set_timer( linda_h, key [,wakeup_at_secs [,period_secs]] )
            --
            local set_timer = function( linda, key, wakeup_at, period)
                assert( wakeup_at == nil or wakeup_at > 0.0)
                assert( period == nil or period > 0.0)

                local linda_deep = linda:deep()
                assert( linda_deep)

                -- Find or make a lookup for this timer
                --
                local t1 = collection[linda_deep]
                if not t1 then
                    t1 = { [linda_deep] = linda}     -- proxy to use the Linda
                    collection[linda_deep] = t1
                end

                if wakeup_at == nil then
                    -- Clear the timer
                    --
                    t1[key]= nil

                    -- Remove empty tables from collection; speeds timer checks and
                    -- lets our 'safety reference' proxy be gc:ed as well.
                    --
                    local empty = true
                    for k, _ in pairs( t1) do
                        if k ~= linda_deep then
                            empty = false
                            break
                        end
                    end
                    if empty then
                        collection[linda_deep] = nil
                    end

                    -- Note: any unread timer value is left at 'linda[key]' intensionally;
                    --       clearing a timer just stops it.
                else
                    -- New timer or changing the timings
                    --
                    local t2 = t1[key]
                    if not t2 then
                        t2= {}
                        t1[key]= t2
                    end

                    t2[1] = wakeup_at
                    t2[2] = period   -- can be 'nil'
                end
            end -- set_timer()

            -----
            -- [next_wakeup_at]= check_timers()
            -- Check timers, and wake up the ones expired (if any)
            -- Returns the closest upcoming (remaining) wakeup time (or 'nil' if none).
            local check_timers = function()
                local now = now_secs()
                local next_wakeup

                for linda_deep,t1 in pairs(collection) do
                    for key,t2 in pairs(t1) do
                        --
                        if key==linda_deep then
                            -- no 'continue' in Lua :/
                        else
                            -- 't2': { wakeup_at_secs [,period_secs] }
                            --
                            local wakeup_at= t2[1]
                            local period= t2[2]     -- may be 'nil'

                            if wakeup_at <= now then
                                local linda= t1[linda_deep]
                                assert(linda)

                                linda:set( key, now )

                                -- 'pairs()' allows the values to be modified (and even
                                -- removed) as far as keys are not touched

                                if not period then
                                    -- one-time timer; gone
                                    --
                                    t1[key]= nil
                                    wakeup_at= nil   -- no 'continue' in Lua :/
                                else
                                    -- repeating timer; find next wakeup (may jump multiple repeats)
                                    --
                                    repeat
                                            wakeup_at= wakeup_at+period
                                    until wakeup_at > now

                                    t2[1]= wakeup_at
                                end
                            end

                            if wakeup_at and ((not next_wakeup) or (wakeup_at < next_wakeup)) then
                                next_wakeup= wakeup_at
                            end
                        end
                    end -- t2 loop
                end -- t1 loop

                return next_wakeup  -- may be 'nil'
            end -- check_timers()

            local timer_gateway_batched = timer_gateway.batched
            set_finalizer( function( err, stk)
                if err and type( err) ~= "userdata" then
                    WR( "LanesTimer error: "..tostring(err))
                --elseif type( err) == "userdata" then
                --	WR( "LanesTimer after cancel" )
                --else
                --	WR("LanesTimer finalized")
                end
            end)
            while true do
                local next_wakeup = check_timers()

                -- Sleep until next timer to wake up, or a set/clear command
                --
                local secs
                if next_wakeup then
                    secs =  next_wakeup - now_secs()
                    if secs < 0 then secs = 0 end
                end
                local key, what = timer_gateway:receive( secs, TGW_KEY, TGW_QUERY)

                if key == TGW_KEY then
                    assert( getmetatable( what) == "Linda") -- 'what' should be a linda on which the client sets a timer
                    local _, key, wakeup_at, period = timer_gateway:receive( 0, timer_gateway_batched, TGW_KEY, 3)
                    assert( key)
                    set_timer( what, key, wakeup_at, period and period > 0 and period or nil)
                elseif key == TGW_QUERY then
                    if what == "get_timers" then
                        timer_gateway:send( TGW_REPLY, get_timers())
                    else
                        timer_gateway:send( TGW_REPLY, "unknown query " .. what)
                    end
                --elseif secs == nil then -- got no value while block-waiting?
                --	WR( "timer lane: no linda, aborted?")
                end
            end
        end -- timer_body()
        timer_lane = gen( "*", { package= {}, priority = max_prio}, timer_body)() -- "*" instead of "io,package" for LuaJIT compatibility...
    end -- first_time

    -----
    -- = timer( linda_h, key_val, date_tbl|first_secs [,period_secs] )
    --
    -- PUBLIC LANES API
    timer = function( linda, key, a, period )
        if getmetatable( linda) ~= "Linda" then
            error "expecting a Linda"
        end
        if a == 0.0 then
            -- Caller expects to get current time stamp in Linda, on return
            -- (like the timer had expired instantly); it would be good to set this
            -- as late as possible (to give most current time) but also we want it
            -- to precede any possible timers that might start striking.
            --
            linda:set( key, core.now_secs())

            if not period or period==0.0 then
                timer_gateway:send( TGW_KEY, linda, key, nil, nil )   -- clear the timer
                return  -- nothing more to do
            end
            a= period
        end

        local wakeup_at= type(a)=="table" and core.wakeup_conv(a)    -- given point of time
                                           or (a and core.now_secs()+a or nil)
        -- queue to timer
        --
        timer_gateway:send( TGW_KEY, linda, key, wakeup_at, period )
    end

    -----
    -- {[{linda, slot, when, period}[,...]]} = timers()
    --
    -- PUBLIC LANES API
    timers = function()
        timer_gateway:send( TGW_QUERY, "get_timers")
        local _, r = timer_gateway:receive( TGW_REPLY)
        return r
    end

    end -- settings.with_timers

    -- avoid pulling the whole core module as upvalue when cancel_error is enough
    local cancel_error = assert( core.cancel_error)

    ---=== Lock & atomic generators ===---

    -- These functions are just surface sugar, but make solutions easier to read.
    -- Not many applications should even need explicit locks or atomic counters.

    --
    -- [true [, ...]= trues(uint)
    --
    local function trues( n)
        if n > 0 then
            return true, trues( n - 1)
        end
    end

    --
    -- lock_f = lanes.genlock( linda_h, key [,N_uint=1] )
    --
    -- = lock_f( +M )   -- acquire M
    --      ...locked...
    -- = lock_f( -M )   -- release M
    --
    -- Returns an access function that allows 'N' simultaneous entries between
    -- acquire (+M) and release (-M). For binary locks, use M==1.
    --
    -- PUBLIC LANES API
    local genlock = function( linda, key, N)
        -- clear existing data and set the limit
        N = N or 1
        if linda:set( key) == cancel_error or linda:limit( key, N) == cancel_error then
            return cancel_error
        end

        -- use an optimized version for case N == 1
        return (N == 1) and
        function( M, mode_)
            local timeout = (mode_ == "try") and 0 or nil
            if M > 0 then
                -- 'nil' timeout allows 'key' to be numeric
                return linda:send( timeout, key, true)    -- suspends until been able to push them
            else
                local k = linda:receive( nil, key)
                -- propagate cancel_error if we got it, else return true or false
                return k and ((k ~= cancel_error) and true or k) or false
            end
        end
        or
        function( M, mode_)
            local timeout = (mode_ == "try") and 0 or nil
            if M > 0 then
                -- 'nil' timeout allows 'key' to be numeric
                return linda:send( timeout, key, trues(M))    -- suspends until been able to push them
            else
                local k = linda:receive( nil, linda.batched, key, -M)
                -- propagate cancel_error if we got it, else return true or false
                return k and ((k ~= cancel_error) and true or k) or false
            end
        end
    end


    --
    -- atomic_f = lanes.genatomic( linda_h, key [,initial_num=0.0])
    --
    -- int|cancel_error = atomic_f( [diff_num = 1.0])
    --
    -- Returns an access function that allows atomic increment/decrement of the
    -- number in 'key'.
    --
    -- PUBLIC LANES API
    local genatomic = function( linda, key, initial_val)
        -- clears existing data (also queue). the slot may contain the stored value, and an additional boolean value
        if linda:limit( key, 2) == cancel_error or linda:set( key, initial_val or 0.0) == cancel_error then
            return cancel_error
        end

        return function( diff)
            -- 'nil' allows 'key' to be numeric
            -- suspends until our 'true' is in
            if linda:send( nil, key, true) == cancel_error then
                return cancel_error
            end
            local val = linda:get( key)
            if val ~= cancel_error then
                val = val + (diff or 1.0)
                -- set() releases the lock by emptying queue
                if linda:set( key, val) == cancel_error then
                    val = cancel_error
                end
            end
            return val
        end
    end

    -- activate full interface
    lanes.require = core.require
    lanes.register = core.register
    lanes.gen = gen
    lanes.linda = core.linda
    lanes.cancel_error = core.cancel_error
    lanes.nameof = core.nameof
    lanes.set_singlethreaded = core.set_singlethreaded
    lanes.threads = core.threads or function() error "lane tracking is not available" end -- core.threads isn't registered if settings.track_lanes is false
    lanes.set_thread_priority = core.set_thread_priority
    lanes.set_thread_affinity = core.set_thread_affinity
    lanes.timer = timer
    lanes.timer_lane = timer_lane
    lanes.timers = timers
    lanes.sleep = sleep
    lanes.genlock = genlock
    lanes.now_secs = core.now_secs
    lanes.genatomic = genatomic
    lanes.configure = nil -- no need to call configure() ever again
    return lanes
end -- lanes.configure

lanesMeta.__index = function( t, k)
    -- This is called when some functionality is accessed without calling configure()
    lanes.configure() -- initialize with default settings
    -- Access the required key
    return lanes[k]
end

-- no need to force calling configure() manually excepted the first time (other times will reuse the internally stored settings of the first call)
if core.settings then
    return lanes.configure()
else
    return lanes
end

--the end

end,

["inspect"] = function()
--------------------
-- Module: 'inspect'
--------------------
local inspect ={
  _VERSION = 'inspect.lua 3.1.0',
  _URL     = 'http://github.com/kikito/inspect.lua',
  _DESCRIPTION = 'human-readable representations of tables',
  _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local tostring = tostring

inspect.KEY       = setmetatable({}, {__tostring = function() return 'inspect.KEY' end})
inspect.METATABLE = setmetatable({}, {__tostring = function() return 'inspect.METATABLE' end})

local function rawpairs(t)
  return next, t, nil
end

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smartQuote(str)
  if str:match('"') and not str:match("'") then
    return "'" .. str .. "'"
  end
  return '"' .. str:gsub('"', '\\"') .. '"'
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local shortControlCharEscapes = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v"
}
local longControlCharEscapes = {} -- \a => nil, \0 => \000, 31 => \031
for i=0, 31 do
  local ch = string.char(i)
  if not shortControlCharEscapes[ch] then
    shortControlCharEscapes[ch] = "\\"..i
    longControlCharEscapes[ch]  = string.format("\\%03d", i)
  end
end

local function escape(str)
  return (str:gsub("\\", "\\\\")
             :gsub("(%c)%f[0-9]", longControlCharEscapes)
             :gsub("%c", shortControlCharEscapes))
end

local function isIdentifier(str)
  return type(str) == 'string' and str:match( "^[_%a][_%a%d]*$" )
end

local function isSequenceKey(k, sequenceLength)
  return type(k) == 'number'
     and 1 <= k
     and k <= sequenceLength
     and math.floor(k) == k
end

local defaultTypeOrders = {
  ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

local function sortKeys(a, b)
  local ta, tb = type(a), type(b)

  -- strings and numbers are sorted numerically/alphabetically
  if ta == tb and (ta == 'string' or ta == 'number') then return a < b end

  local dta, dtb = defaultTypeOrders[ta], defaultTypeOrders[tb]
  -- Two default types are compared according to the defaultTypeOrders table
  if dta and dtb then return defaultTypeOrders[ta] < defaultTypeOrders[tb]
  elseif dta     then return true  -- default types before custom ones
  elseif dtb     then return false -- custom types after default ones
  end

  -- custom types are sorted out alphabetically
  return ta < tb
end

-- For implementation reasons, the behavior of rawlen & # is "undefined" when
-- tables aren't pure sequences. So we implement our own # operator.
local function getSequenceLength(t)
  local len = 1
  local v = rawget(t,len)
  while v ~= nil do
    len = len + 1
    v = rawget(t,len)
  end
  return len - 1
end

local function getNonSequentialKeys(t)
  local keys, keysLength = {}, 0
  local sequenceLength = getSequenceLength(t)
  for k,_ in rawpairs(t) do
    if not isSequenceKey(k, sequenceLength) then
      keysLength = keysLength + 1
      keys[keysLength] = k
    end
  end
  table.sort(keys, sortKeys)
  return keys, keysLength, sequenceLength
end

local function countTableAppearances(t, tableAppearances)
  tableAppearances = tableAppearances or {}

  if type(t) == 'table' then
    if not tableAppearances[t] then
      tableAppearances[t] = 1
      for k,v in rawpairs(t) do
        countTableAppearances(k, tableAppearances)
        countTableAppearances(v, tableAppearances)
      end
      countTableAppearances(getmetatable(t), tableAppearances)
    else
      tableAppearances[t] = tableAppearances[t] + 1
    end
  end

  return tableAppearances
end

local copySequence = function(s)
  local copy, len = {}, #s
  for i=1, len do copy[i] = s[i] end
  return copy, len
end

local function makePath(path, ...)
  local keys = {...}
  local newPath, len = copySequence(path)
  for i=1, #keys do
    newPath[len + i] = keys[i]
  end
  return newPath
end

local function processRecursive(process, item, path, visited)
  if item == nil then return nil end
  if visited[item] then return visited[item] end

  local processed = process(item, path)
  if type(processed) == 'table' then
    local processedCopy = {}
    visited[item] = processedCopy
    local processedKey

    for k,v in rawpairs(processed) do
      processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
      if processedKey ~= nil then
        processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
      end
    end

    local mt  = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
    if type(mt) ~= 'table' then mt = nil end -- ignore not nil/table __metatable field
    setmetatable(processedCopy, mt)
    processed = processedCopy
  end
  return processed
end



-------------------------------------------------------------------

local Inspector = {}
local Inspector_mt = {__index = Inspector}

function Inspector:puts(...)
  local args   = {...}
  local buffer = self.buffer
  local len    = #buffer
  for i=1, #args do
    len = len + 1
    buffer[len] = args[i]
  end
end

function Inspector:down(f)
  self.level = self.level + 1
  f()
  self.level = self.level - 1
end

function Inspector:tabify()
  self:puts(self.newline, string.rep(self.indent, self.level))
end

function Inspector:alreadyVisited(v)
  return self.ids[v] ~= nil
end

function Inspector:getId(v)
  local id = self.ids[v]
  if not id then
    local tv = type(v)
    id              = (self.maxIds[tv] or 0) + 1
    self.maxIds[tv] = id
    self.ids[v]     = id
  end
  return tostring(id)
end

function Inspector:putKey(k)
  if isIdentifier(k) then return self:puts(k) end
  self:puts("[")
  self:putValue(k)
  self:puts("]")
end

function Inspector:putTable(t)
  if t == inspect.KEY or t == inspect.METATABLE then
    self:puts(tostring(t))
  elseif self:alreadyVisited(t) then
    self:puts('<table ', self:getId(t), '>')
  elseif self.level >= self.depth then
    self:puts('{...}')
  else
    if self.tableAppearances[t] > 1 then self:puts('<', self:getId(t), '>') end

    local nonSequentialKeys, nonSequentialKeysLength, sequenceLength = getNonSequentialKeys(t)
    local mt                = getmetatable(t)

    self:puts('{')
    self:down(function()
      local count = 0
      for i=1, sequenceLength do
        if count > 0 then self:puts(',') end
        self:puts(' ')
        self:putValue(t[i])
        count = count + 1
      end

      for i=1, nonSequentialKeysLength do
        local k = nonSequentialKeys[i]
        if count > 0 then self:puts(',') end
        self:tabify()
        self:putKey(k)
        self:puts(' = ')
        self:putValue(t[k])
        count = count + 1
      end

      if type(mt) == 'table' then
        if count > 0 then self:puts(',') end
        self:tabify()
        self:puts('<metatable> = ')
        self:putValue(mt)
      end
    end)

    if nonSequentialKeysLength > 0 or type(mt) == 'table' then -- result is multi-lined. Justify closing }
      self:tabify()
    elseif sequenceLength > 0 then -- array tables have one extra space before closing }
      self:puts(' ')
    end

    self:puts('}')
  end
end

function Inspector:putValue(v)
  local tv = type(v)

  if tv == 'string' then
    self:puts(smartQuote(escape(v)))
  elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
         tv == 'cdata' or tv == 'ctype' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:putTable(v)
  else
    self:puts('<', tv, ' ', self:getId(v), '>')
  end
end

-------------------------------------------------------------------

function inspect.inspect(root, options)
  options       = options or {}

  local depth   = options.depth   or math.huge
  local newline = options.newline or '\n'
  local indent  = options.indent  or '  '
  local process = options.process

  if process then
    root = processRecursive(process, root, {}, {})
  end

  local inspector = setmetatable({
    depth            = depth,
    level            = 0,
    buffer           = {},
    ids              = {},
    maxIds           = {},
    newline          = newline,
    indent           = indent,
    tableAppearances = countTableAppearances(root)
  }, Inspector_mt)

  inspector:putValue(root)

  return table.concat(inspector.buffer)
end

setmetatable(inspect, { __call = function(_, ...) return inspect.inspect(...) end })

return inspect


end,

["glue"] = function()
--------------------
-- Module: 'glue'
--------------------
-- Lua extended vocabulary of basic tools.
-- Written by Cosmin Apreutesei. Public domain.
-- Modifications by Sled
local glue = {}

local min, max, floor, ceil, log = math.min, math.max, math.floor, math.ceil, math.log
---@diagnostic disable-next-line: deprecated
local select, unpack, pairs, rawget = select, unpack, pairs, rawget

-- math -----------------------------------------------------------------------

function glue.round(x, p)
    p = p or 1
    return floor(x / p + .5) * p
end

function glue.floor(x, p)
    p = p or 1
    return floor(x / p) * p
end

function glue.ceil(x, p)
    p = p or 1
    return ceil(x / p) * p
end

glue.snap = glue.round

function glue.clamp(x, x0, x1)
    return min(max(x, x0), x1)
end

function glue.lerp(x, x0, x1, y0, y1)
    return y0 + (x - x0) * ((y1 - y0) / (x1 - x0))
end

function glue.nextpow2(x)
    return max(0, 2 ^ (ceil(log(x) / log(2))))
end

-- varargs --------------------------------------------------------------------

if table.pack then
    glue.pack = table.pack
else
    function glue.pack(...)
        return {n = select("#", ...), ...}
    end
end

-- always use this because table.unpack's default j is #t not t.n.
function glue.unpack(t, i, j)
    return unpack(t, i or 1, j or t.n or #t)
end

-- tables ---------------------------------------------------------------------

---Count the keys in a table with an optional upper limit
---@param t table
---@param maxn integer
---@return integer
function glue.count(t, maxn)
    local maxn = maxn or (1 / 0)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
        if n >= maxn then
            break
        end
    end
    return n
end

---Reverse keys with values
---@param t table<any, any>
---@return table
function glue.index(t)
    local dt = {}
    for k, v in pairs(t) do
        dt[v] = k
    end
    return dt
end

local function desc_cmp(a, b)
    return a > b
end

---Put keys in a list, optionally sorted
---@param t table
---@param cmp? boolean | '"asc"' | '"desc"'
---@return string[] | integer[] | any[]
function glue.keys(t, cmp)
    local dt = {}
    for k in pairs(t) do
        dt[#dt + 1] = k
    end
    if cmp == true or cmp == "asc" then
        table.sort(dt)
    elseif cmp == "desc" then
        table.sort(dt, desc_cmp)
    elseif cmp then
        table.sort(dt, cmp)
    end
    return dt
end

---Stateless pairs() that iterate elements in key order
---@param t table
---@param cmp? boolean | '"asc"' | '"desc"'
---@return function
function glue.sortedpairs(t, cmp)
    local kt = glue.keys(t, cmp or true)
    local i = 0
    return function()
        i = i + 1
        return kt[i], t[kt[i]]
    end
end

---Update a table with the contents of other table(s)
---@param dt table
---@param ... any
---@return table
function glue.update(dt, ...)
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t then
            for k, v in pairs(t) do
                dt[k] = v
            end
        end
    end
    return dt
end

---Add the contents of other table(s) without overwriting
---@param dt table
---@param ... any
---@return table
function glue.merge(dt, ...)
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t then
            for k, v in pairs(t) do
                if rawget(dt, k) == nil then
                    dt[k] = v
                end
            end
        end
    end
    return dt
end

---Copy the content of a table and create a new one without references
---@param orig table
---@return table
function glue.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[glue.deepcopy(orig_key)] = glue.deepcopy(orig_value)
        end
        setmetatable(copy, glue.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---Get the value of a table field, and if the field is not present in the\
---table, create it as an empty table, and return it
---@param t table
---@param k any
---@param v0 any
---@return any
function glue.attr(t, k, v0)
    local v = t[k]
    if v == nil then
        if v0 == nil then
            v0 = {}
        end
        v = v0
        t[k] = v
    end
    return v
end

-- lists ----------------------------------------------------------------------

-- extend a list with the elements of other lists.
function glue.extend(dt, ...)
    for j = 1, select("#", ...) do
        local t = select(j, ...)
        if t then
            local j = #dt
            for i = 1, #t do
                dt[j + i] = t[i]
            end
        end
    end
    return dt
end

-- append non-nil arguments to a list.
function glue.append(dt, ...)
    local j = #dt
    for i = 1, select("#", ...) do
        dt[j + i] = select(i, ...)
    end
    return dt
end

-- insert n elements at i, shifting elemens on the right of i (i inclusive)
-- to the right.
local function insert(t, i, n)
    if n == 1 then -- shift 1
        table.insert(t, i, false)
        return
    end
    for p = #t, i, -1 do -- shift n
        t[p + n] = t[p]
    end
end

-- remove n elements at i, shifting elements on the right of i (i inclusive)
-- to the left.
local function remove(t, i, n)
    n = min(n, #t - i + 1)
    if n == 1 then -- shift 1
        table.remove(t, i)
        return
    end
    for p = i + n, #t do -- shift n
        t[p - n] = t[p]
    end
    for p = #t, #t - n + 1, -1 do -- clean tail
        t[p] = nil
    end
end

-- shift all the elements on the right of i (i inclusive) to the left
-- or further to the right.
function glue.shift(t, i, n)
    if n > 0 then
        insert(t, i, n)
    elseif n < 0 then
        remove(t, i, -n)
    end
    return t
end

-- map f over t or extract a column from a list of records.
function glue.map(t, f, ...)
    local dt = {}
    if #t == 0 then -- treat as hashmap
        if type(f) == "function" then
            for k, v in pairs(t) do
                dt[k] = f(k, v, ...)
            end
        else
            for k, v in pairs(t) do
                local sel = v[f]
                if type(sel) == "function" then -- method to apply
                    dt[k] = sel(v, ...)
                else -- field to pluck
                    dt[k] = sel
                end
            end
        end
    else -- treat as array
        if type(f) == "function" then
            for i, v in ipairs(t) do
                dt[i] = f(v, ...)
            end
        else
            for i, v in ipairs(t) do
                local sel = v[f]
                if type(sel) == "function" then -- method to apply
                    dt[i] = sel(v, ...)
                else -- field to pluck
                    dt[i] = sel
                end
            end
        end
    end
    return dt
end

-- arrays ---------------------------------------------------------------------

---Scan list for value, works with ffi arrays too given i and j
---@param v any
---@param t any[]
---@param eq fun(key:any, value:any)
---@param i integer
---@param j integer
---@return integer
function glue.indexof(v, t, eq, i, j)
    i = i or 1
    j = j or #t
    if eq then
        for i = i, j do
            if eq(t[i], v) then
                return i
            end
        end
    else
        for i = i, j do
            if t[i] == v then
                return i
            end
        end
    end
end

---Return the index of a table/array if value exists
---@param array any[]
---@param value any
function glue.arrayhas(array, value)
    for k, v in pairs(array) do
        if (v == value) then
            return k
        end
    end
    return nil
end

---Get new values of an array compared to another
---@param oldarray any[]
---@param newarray any[]
function glue.arraynv(oldarray, newarray)
    local newvalues = {}
    for k, v in pairs(newarray) do
        if (not glue.arrayhas(oldarray, v)) then
            glue.append(newvalues, v)
        end
    end
    return newvalues
end

---Reverse elements of a list in place, works with ffi arrays too given i and j
---@param t any[]
---@param i integer
---@param j integer
---@return any[]
function glue.reverse(t, i, j)
    i = i or 1
    j = (j or #t) + 1
    for k = 1, (j - i) / 2 do
        t[i + k - 1], t[j - k] = t[j - k], t[i + k - 1]
    end
    return t
end

--- Get all the values of a key recursively
---@param t table
---@param dp any
function glue.childsbyparent(t, dp)
    for p, ch in pairs(t) do
        if (p == dp) then
            return ch
        end
        if (ch) then
            local found = glue.childsbyparent(ch, dp)
            if (found) then
                return found
            end
        end
    end
    return nil
end

-- Get the key of a value recursively
---@param t table
---@param dp any
function glue.parentbychild(t, dp)
    for p, ch in pairs(t) do
        if (ch[dp]) then
            return p
        end
        if (ch) then
            local found = glue.parentbychild(ch, dp)
            if (found) then
                return found
            end
        end
    end
    return nil
end

--- Split a list/array into small parts of given size
---@param list any[]
---@param chunks number
function glue.chunks(list, chunks)
    local chunkcounter = 0
    local chunk = {}
    local chunklist = {}
    -- Append chunks to the list in the specified amount of elements
    for k, v in pairs(list) do
        if (chunkcounter == chunks) then
            glue.append(chunklist, chunk)
            chunk = {}
            chunkcounter = 0
        end
        glue.append(chunk, v)
        chunkcounter = chunkcounter + 1
    end
    -- If there was a chunk that was not completed append it
    if (chunkcounter ~= 0) then
        glue.append(chunklist, chunk)
    end
    return chunklist
end

-- binary search for an insert position that keeps the table sorted.
-- works with ffi arrays too if lo and hi are provided.
local cmps = {}
cmps["<"] = function(t, i, v)
    return t[i] < v
end
cmps[">"] = function(t, i, v)
    return t[i] > v
end
cmps["<="] = function(t, i, v)
    return t[i] <= v
end
cmps[">="] = function(t, i, v)
    return t[i] >= v
end
local less = cmps["<"]
function glue.binsearch(v, t, cmp, lo, hi)
    lo, hi = lo or 1, hi or #t
    cmp = cmp and cmps[cmp] or cmp or less
    local len = hi - lo + 1
    if len == 0 then
        return nil
    end
    if len == 1 then
        return not cmp(t, lo, v) and lo or nil
    end
    while lo < hi do
        local mid = floor(lo + (hi - lo) / 2)
        if cmp(t, mid, v) then
            lo = mid + 1
            if lo == hi and cmp(t, lo, v) then
                return nil
            end
        else
            hi = mid
        end
    end
    return lo
end

-- strings --------------------------------------------------------------------

-- string submodule. has its own namespace which can be merged with _G.string.
glue.string = {}

--- Split a string list/array given a separator string
function glue.string.split(s, sep)
    if (sep == nil or sep == "") then
        return 1
    end
    local position, array = 0, {}
    for st, sp in function()
        return string.find(s, sep, position, true)
    end do
        table.insert(array, string.sub(s, position, st - 1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

-- split a string by a separator that can be a pattern or a plain string.
-- return a stateless iterator for the pieces.
local function iterate_once(s, s1)
    return s1 == nil and s or nil
end
function glue.string.gsplit(s, sep, start, plain)
    start = start or 1
    plain = plain or false
    if not s:find(sep, start, plain) then
        return iterate_once, s:sub(start)
    end
    local done = false
    local function pass(i, j, ...)
        if i then
            local seg = s:sub(start, i - 1)
            start = j + 1
            return seg, ...
        else
            done = true
            return s:sub(start)
        end
    end
    return function()
        if done then
            return
        end
        if sep == "" then
            done = true;
            return s:sub(start)
        end
        return pass(s:find(sep, start, plain))
    end
end

---Split a string into lines, optionally including the line terminator
---@param s string
---@param opt any | '"*L"'
---@return function
function glue.lines(s, opt)
    local term = opt == "*L"
    local patt = term and "([^\r\n]*()\r?\n?())" or "([^\r\n]*)()\r?\n?()"
    local next_match = s:gmatch(patt)
    local empty = s == ""
    local ended -- string ended with no line ending
    return function()
        local s, i1, i2 = next_match()
        if s == nil then
            return
        end
        if s == "" and not empty and ended then
            s = nil
        end
        ended = i1 == i2
        return s
    end
end

---String trim12, source: http://lua-users.org/wiki/StringTrim
---@param s any
---@return string
function glue.string.trim(s)
    local from = s:match("^%s*()")
    return from > #s and "" or s:match(".*%S", from)
end

-- escape a string so that it can be matched literally inside a pattern.
local function format_ci_pat(c)
    return ("[%s%s]"):format(c:lower(), c:upper())
end
---Escape a string to match it inside a lua pattern
---@param s string
---@param mode? any
---@return any
function glue.string.esc(s, mode) -- escape is a reserved word in Terra
    s = s:gsub("%%", "%%%%"):gsub("%z", "%%z"):gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    if mode == "*i" then
        s = s:gsub("[%a]", format_ci_pat)
    end
    return s
end

---Convert string or number to hex
---@param s string
---@param upper? boolean
---@return string
function glue.string.tohex(s, upper)
    if type(s) == "number" then
        return (upper and "%08.8X" or "%08.8x"):format(s)
    end
    if upper then
        return (s:gsub(".", function(c)
            return ("%02X"):format(c:byte())
        end))
    else
        return (s:gsub(".", function(c)
            return ("%02x"):format(c:byte())
        end))
    end
end

-- hex to binary string.
function glue.string.fromhex(s)
    if #s % 2 == 1 then
        return glue.string.fromhex("0" .. s)
    end
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

function glue.string.starts(s, p) -- 5x faster than s:find'^...' in LuaJIT 2.1
    return s:sub(1, #p) == p
end

function glue.string.ends(s, p)
    return p == "" or s:sub(-#p) == p
end

function glue.string.subst(s, t) -- subst('{foo} {bar}', {foo=1, bar=2}) -> '1 2'
    return s:gsub("{([_%w]+)}", t)
end

-- publish the string submodule in the glue namespace.
glue.update(glue, glue.string)

-- iterators ------------------------------------------------------------------

-- run an iterator and collect the n-th return value into a list.
local function select_at(i, ...)
    return ..., select(i, ...)
end
local function collect_at(i, f, s, v)
    local t = {}
    repeat
        v, t[#t + 1] = select_at(i, f(s, v))
    until v == nil
    return t
end
local function collect_first(f, s, v)
    local t = {}
    repeat
        v = f(s, v);
        t[#t + 1] = v
    until v == nil
    return t
end
function glue.collect(n, ...)
    if type(n) == "number" then
        return collect_at(n, ...)
    else
        return collect_first(n, ...)
    end
end

-- closures -------------------------------------------------------------------

-- no-op filters.
function glue.pass(...)
    return ...
end
function glue.noop()
end

-- memoize for 0, 1, 2-arg and vararg and 1 retval functions.
local function memoize0(fn) -- for strict no-arg functions
    local v, stored
    return function()
        if not stored then
            v = fn();
            stored = true
        end
        return v
    end
end
local nilkey = {}
local nankey = {}
local function memoize1(fn) -- for strict single-arg functions
    local cache = {}
    return function(arg)
        local k = arg == nil and nilkey or arg ~= arg and nankey or arg
        local v = cache[k]
        if v == nil then
            v = fn(arg);
            cache[k] = v == nil and nilkey or v
        else
            if v == nilkey then
                v = nil
            end
        end
        return v
    end
end
local function memoize2(fn) -- for strict two-arg functions
    local cache = {}
    return function(a1, a2)
        local k1 = a1 ~= a1 and nankey or a1 == nil and nilkey or a1
        local cache2 = cache[k1]
        if cache2 == nil then
            cache2 = {}
            cache[k1] = cache2
        end
        local k2 = a2 ~= a2 and nankey or a2 == nil and nilkey or a2
        local v = cache2[k2]
        if v == nil then
            v = fn(a1, a2)
            cache2[k2] = v == nil and nilkey or v
        else
            if v == nilkey then
                v = nil
            end
        end
        return v
    end
end
local function memoize_vararg(fn, minarg, maxarg)
    local cache = {}
    local values = {}
    return function(...)
        local key = cache
        local narg = min(max(select("#", ...), minarg), maxarg)
        for i = 1, narg do
            local a = select(i, ...)
            local k = a ~= a and nankey or a == nil and nilkey or a
            local t = key[k]
            if not t then
                t = {};
                key[k] = t
            end
            key = t
        end
        local v = values[key]
        if v == nil then
            v = fn(...);
            values[key] = v == nil and nilkey or v
        end
        if v == nilkey then
            v = nil
        end
        return v
    end
end
local memoize_narg = {[0] = memoize0, memoize1, memoize2}
local function choose_memoize_func(func, narg)
    if narg then
        local memoize_narg = memoize_narg[narg]
        if memoize_narg then
            return memoize_narg
        else
            return memoize_vararg, narg, narg
        end
    else
        local info = debug.getinfo(func, "u")
        if info.isvararg then
            return memoize_vararg, info.nparams, 1 / 0
        else
            return choose_memoize_func(func, info.nparams)
        end
    end
end
function glue.memoize(func, narg)
    local memoize, minarg, maxarg = choose_memoize_func(func, narg)
    return memoize(func, minarg, maxarg)
end

-- memoize a function with multiple return values.
function glue.memoize_multiret(func, narg)
    local memoize, minarg, maxarg = choose_memoize_func(func, narg)
    local function wrapper(...)
        return glue.pack(func(...))
    end
    local func = memoize(wrapper, minarg, maxarg)
    return function(...)
        return glue.unpack(func(...))
    end
end

local tuple_mt = {__call = glue.unpack}
function tuple_mt:__tostring()
    local t = {}
    for i = 1, self.n do
        t[i] = tostring(self[i])
    end
    return string.format("(%s)", table.concat(t, ", "))
end
function glue.tuples(narg)
    return glue.memoize(function(...)
        return setmetatable(glue.pack(...), tuple_mt)
    end)
end

-- objects --------------------------------------------------------------------

-- set up dynamic inheritance by creating or updating a table's metatable.
function glue.inherit(t, parent)
    local meta = getmetatable(t)
    if meta then
        meta.__index = parent
    elseif parent ~= nil then
        setmetatable(t, {__index = parent})
    end
    return t
end

-- prototype-based dynamic inheritance with __call constructor.
function glue.object(super, o, ...)
    o = o or {}
    o.__index = super
    o.__call = super and super.__call
    glue.update(o, ...) -- add mixins, defaults, etc.
    return setmetatable(o, o)
end

local function install(self, combine, method_name, hook)
    rawset(self, method_name, combine(self[method_name], hook))
end
local function before(method, hook)
    if method then
        return function(self, ...)
            hook(self, ...)
            return method(self, ...)
        end
    else
        return hook
    end
end
function glue.before(self, method_name, hook)
    install(self, before, method_name, hook)
end
local function after(method, hook)
    if method then
        return function(self, ...)
            method(self, ...)
            return hook(self, ...)
        end
    else
        return hook
    end
end
function glue.after(self, method_name, hook)
    install(self, after, method_name, hook)
end
local function override(method, hook)
    local method = method or glue.noop
    return function(...)
        return hook(method, ...)
    end
end
function glue.override(self, method_name, hook)
    install(self, override, method_name, hook)
end

-- return a metatable that supports virtual properties.
-- can be used with setmetatable() and ffi.metatype().
function glue.gettersandsetters(getters, setters, super)
    local get = getters and function(t, k)
        local get = getters[k]
        if get then
            return get(t)
        end
        return super and super[k]
    end
    local set = setters and function(t, k, v)
        local set = setters[k]
        if set then
            set(t, v);
            return
        end
        rawset(t, k, v)
    end
    return {__index = get, __newindex = set}
end

-- i/o ------------------------------------------------------------------------

-- check if a file exists and can be opened for reading or writing.
function glue.canopen(name, mode)
    local f = io.open(name, mode or "rb")
    if f then
        f:close()
    end
    return f ~= nil and name or nil
end

-- read a file into a string (in binary mode by default).
function glue.readfile(name, mode, open)
    open = open or io.open
    local f, err = open(name, mode == "t" and "r" or "rb")
    if not f then
        return nil, err
    end
    local s, err = f:read "*a"
    if s == nil then
        return nil, err
    end
    f:close()
    return s
end

-- read the output of a command into a string.
function glue.readpipe(cmd, mode, open)
    return glue.readfile(cmd, mode, open or io.popen)
end

-- like os.rename() but behaves like POSIX on Windows too.
if jit then

    local ffi = require "ffi"

    if ffi.os == "Windows" then

        ffi.cdef [[
			int MoveFileExA(
				const char *lpExistingFileName,
				const char *lpNewFileName,
				unsigned long dwFlags
			);
			int GetLastError(void);
		]]

        local MOVEFILE_REPLACE_EXISTING = 1
        local MOVEFILE_WRITE_THROUGH = 8
        local ERROR_FILE_EXISTS = 80
        local ERROR_ALREADY_EXISTS = 183

        function glue.replacefile(oldfile, newfile)
            if ffi.C.MoveFileExA(oldfile, newfile, 0) ~= 0 then
                return true
            end
            local err = ffi.C.GetLastError()
            if err == ERROR_FILE_EXISTS or err == ERROR_ALREADY_EXISTS then
                if ffi.C.MoveFileExA(oldfile, newfile,
                                     bit.bor(MOVEFILE_WRITE_THROUGH, MOVEFILE_REPLACE_EXISTING)) ~=
                    0 then
                    return true
                end
                err = ffi.C.GetLastError()
            end
            return nil, "WinAPI error " .. err
        end

    else

        function glue.replacefile(oldfile, newfile)
            return os.rename(oldfile, newfile)
        end

    end

end

-- write a string, number, table or the results of a read function to a file.
-- uses binary mode by default.
function glue.writefile(filename, s, mode, tmpfile)
    if tmpfile then
        local ok, err = glue.writefile(tmpfile, s, mode)
        if not ok then
            return nil, err
        end
        local ok, err = glue.replacefile(tmpfile, filename)
        if not ok then
            os.remove(tmpfile)
            return nil, err
        else
            return true
        end
    end
    local f, err = io.open(filename, mode == "t" and "w" or "wb")
    if not f then
        return nil, err
    end
    local ok, err
    if type(s) == "table" then
        for i = 1, #s do
            ok, err = f:write(s[i])
            if not ok then
                break
            end
        end
    elseif type(s) == "function" then
        local read = s
        while true do
            ok, err = xpcall(read, debug.traceback)
            if not ok or err == nil then
                break
            end
            ok, err = f:write(err)
            if not ok then
                break
            end
        end
    else -- string or number
        ok, err = f:write(s)
    end
    f:close()
    if not ok then
        os.remove(filename)
        return nil, err
    else
        return true
    end
end

-- virtualize the print function.
function glue.printer(out, format)
    format = format or tostring
    return function(...)
        local n = select("#", ...)
        for i = 1, n do
            out(format((select(i, ...))))
            if i < n then
                out "\t"
            end
        end
        out "\n"
    end
end

-- dates & timestamps ---------------------------------------------------------

-- compute timestamp diff. to UTC because os.time() has no option for UTC.
function glue.utc_diff(t)
    local d1 = os.date("*t", 3600 * 24 * 10)
    local d2 = os.date("!*t", 3600 * 24 * 10)
    d1.isdst = false
    return os.difftime(os.time(d1), os.time(d2))
end

-- overloading os.time to support UTC and get the date components as separate args.
function glue.time(utc, y, m, d, h, M, s, isdst)
    if type(utc) ~= "boolean" then -- shift arg#1
        utc, y, m, d, h, M, s, isdst = nil, utc, y, m, d, h, M, s
    end
    if type(y) == "table" then
        local t = y
        if utc == nil then
            utc = t.utc
        end
        y, m, d, h, M, s, isdst = t.year, t.month, t.day, t.hour, t.min, t.sec, t.isdst
    end
    local utc_diff = utc and glue.utc_diff() or 0
    if not y then
        return os.time() + utc_diff
    else
        s = s or 0
        local t = os.time {
            year = y,
            month = m or 1,
            day = d or 1,
            hour = h or 0,
            min = M or 0,
            sec = s,
            isdst = isdst
        }
        return t and t + s - floor(s) + utc_diff
    end
end

-- get the time at the start of the week of a given time, plus/minus a number of weeks.
function glue.sunday(utc, t, offset)
    if type(utc) ~= "boolean" then -- shift arg#1
        utc, t, offset = false, utc, t
    end
    local d = os.date(utc and "!*t" or "*t", t)
    return glue.time(false, d.year, d.month, d.day - (d.wday - 1) + (offset or 0) * 7)
end

-- get the time at the start of the day of a given time, plus/minus a number of days.
function glue.day(utc, t, offset)
    if type(utc) ~= "boolean" then -- shift arg#1
        utc, t, offset = false, utc, t
    end
    local d = os.date(utc and "!*t" or "*t", t)
    return glue.time(false, d.year, d.month, d.day + (offset or 0))
end

-- get the time at the start of the month of a given time, plus/minus a number of months.
function glue.month(utc, t, offset)
    if type(utc) ~= "boolean" then -- shift arg#1
        utc, t, offset = false, utc, t
    end
    local d = os.date(utc and "!*t" or "*t", t)
    return glue.time(false, d.year, d.month + (offset or 0))
end

-- get the time at the start of the year of a given time, plus/minus a number of years.
function glue.year(utc, t, offset)
    if type(utc) ~= "boolean" then -- shift arg#1
        utc, t, offset = false, utc, t
    end
    local d = os.date(utc and "!*t" or "*t", t)
    return glue.time(false, d.year + (offset or 0))
end

-- error handling -------------------------------------------------------------

-- allocation-free assert() with string formatting.
-- NOTE: unlike standard assert(), this only returns the first argument
-- to avoid returning the error message and it's args along with it so don't
-- use it with functions returning multiple values when you want those values.
function glue.assert(v, err, ...)
    if v then
        return v
    end
    err = err or "assertion failed!"
    if select("#", ...) > 0 then
        err = string.format(err, ...)
    end
    error(err, 2)
end

-- pcall with traceback. LuaJIT and Lua 5.2 only.
local function pcall_error(e)
    return debug.traceback("\n" .. tostring(e))
end
function glue.pcall(f, ...)
    return xpcall(f, pcall_error, ...)
end

local function unprotect(ok, result, ...)
    if not ok then
        return nil, result, ...
    end
    if result == nil then
        result = true
    end -- to distinguish from error.
    return result, ...
end

---Wrap a function that raises errors on failure into a function that follows\
---the Lua convention of returning nil, err on failure
---@param func function
---@return function
function glue.protect(func)
    return function(...)
        return unprotect(pcall(func, ...))
    end
end

-- pcall with finally and except "clauses":
--		local ret,err = fpcall(function(finally, except)
--			local foo = getfoo()
--			finally(function() foo:free() end)
--			except(function(err) io.stderr:write(err, '\n') end)
--		emd)
-- NOTE: a bit bloated at 2 tables and 4 closures. Can we reduce the overhead?
local function fpcall(f, ...)
    local fint, errt = {}, {}
    local function finally(f)
        fint[#fint + 1] = f
    end
    local function onerror(f)
        errt[#errt + 1] = f
    end
    local function err(e)
        for i = #errt, 1, -1 do
            errt[i](e)
        end
        for i = #fint, 1, -1 do
            fint[i]()
        end
        return tostring(e) .. "\n" .. debug.traceback()
    end
    local function pass(ok, ...)
        if ok then
            for i = #fint, 1, -1 do
                fint[i]()
            end
        end
        return ok, ...
    end
    return pass(xpcall(f, err, finally, onerror, ...))
end

function glue.fpcall(...)
    return unprotect(fpcall(...))
end

-- fcall is like fpcall() but without the protection (i.e. raises errors).
local function assert_fpcall(ok, ...)
    if not ok then
        error(..., 2)
    end
    return ...
end
function glue.fcall(...)
    return assert_fpcall(fpcall(...))
end

-- modules --------------------------------------------------------------------

-- create a module table that dynamically inherits another module.
-- naming the module returns the same module table for the same name.
function glue.module(name, parent)
    if type(name) ~= "string" then
        name, parent = parent, name
    end
    if type(parent) == "string" then
        parent = require(parent)
    end
    parent = parent or _M
    local parent_P = parent and assert(parent._P, "parent module has no _P") or _G
    local M = package.loaded[name]
    if M then
        return M, M._P
    end
    local P = {__index = parent_P}
    M = {__index = parent, _P = P}
    P._M = M
    M._M = M
    P._P = P
    setmetatable(P, P)
    setmetatable(M, M)
    if name then
        package.loaded[name] = M
        P[name] = M
    end
    ---@diagnostic disable-next-line: deprecated
    setfenv(2, P)
    return M, P
end

-- setup a module to load sub-modules when accessing specific keys.
function glue.autoload(t, k, v)
    local mt = getmetatable(t) or {}
    if not mt.__autoload then
        local old_index = mt.__index
        local submodules = {}
        mt.__autoload = submodules
        mt.__index = function(t, k)
            -- overriding __index...
            if type(old_index) == "function" then
                local v = old_index(t, k)
                if v ~= nil then
                    return v
                end
            elseif type(old_index) == "table" then
                local v = old_index[k]
                if v ~= nil then
                    return v
                end
            end
            if submodules[k] then
                local mod
                if type(submodules[k]) == "string" then
                    mod = require(submodules[k]) -- module
                else
                    mod = submodules[k](k) -- custom loader
                end
                submodules[k] = nil -- prevent loading twice
                if type(mod) == "table" then -- submodule returned its module table
                    assert(mod[k] ~= nil) -- submodule has our symbol
                    t[k] = mod[k]
                end
                return rawget(t, k)
            end
        end
        setmetatable(t, mt)
    end
    if type(k) == "table" then
        glue.update(mt.__autoload, k) -- multiple key -> module associations.
    else
        mt.__autoload[k] = v -- single key -> module association.
    end
    return t
end

-- portable way to get script's directory, based on arg[0].
-- NOTE: the path is not absolute, but relative to the current directory!
-- NOTE: for bundled executables, this returns the executable's directory.
local dir = rawget(_G, "arg") and arg[0] and arg[0]:gsub("[/\\]?[^/\\]+$", "") or "" -- remove file name
glue.bin = dir == "" and "." or dir

-- portable way to add more paths to package.path, at any place in the list.
-- negative indices count from the end of the list like string.sub().
-- index 'after' means 0.
function glue.luapath(path, index, ext)
    ext = ext or "lua"
    index = index or 1
    local psep = package.config:sub(1, 1) -- '/'
    local tsep = package.config:sub(3, 3) -- ';'
    local wild = package.config:sub(5, 5) -- '?'
    local paths = glue.collect(glue.gsplit(package.path, tsep, nil, true))
    path = path:gsub("[/\\]", psep) -- normalize slashes
    if index == "after" then
        index = 0
    end
    if index < 1 then
        index = #paths + 1 + index
    end
    table.insert(paths, index, path .. psep .. wild .. psep .. "init." .. ext)
    table.insert(paths, index, path .. psep .. wild .. "." .. ext)
    package.path = table.concat(paths, tsep)
end

-- portable way to add more paths to package.cpath, at any place in the list.
-- negative indices count from the end of the list like string.sub().
-- index 'after' means 0.
function glue.cpath(path, index)
    index = index or 1
    local psep = package.config:sub(1, 1) -- '/'
    local tsep = package.config:sub(3, 3) -- ';'
    local wild = package.config:sub(5, 5) -- '?'
    local ext = package.cpath:match("%.([%a]+)%" .. tsep .. "?") -- dll | so | dylib
    local paths = glue.collect(glue.gsplit(package.cpath, tsep, nil, true))
    path = path:gsub("[/\\]", psep) -- normalize slashes
    if index == "after" then
        index = 0
    end
    if index < 1 then
        index = #paths + 1 + index
    end
    table.insert(paths, index, path .. psep .. wild .. "." .. ext)
    package.cpath = table.concat(paths, tsep)
end

-- allocation -----------------------------------------------------------------

-- freelist for Lua tables.
local function create_table()
    return {}
end
function glue.freelist(create, destroy)
    create = create or create_table
    destroy = destroy or glue.noop
    local t = {}
    local n = 0
    local function alloc()
        local e = t[n]
        if e then
            t[n] = false
            n = n - 1
        end
        return e or create()
    end
    local function free(e)
    ---@diagnostic disable-next-line: redundant-parameter
        destroy(e)
        n = n + 1
        t[n] = e
    end
    return alloc, free
end

-- ffi ------------------------------------------------------------------------

if jit then

    local ffi = require "ffi"

    -- static, auto-growing buffer allocation pattern (ctype must be vla).
    function glue.buffer(ctype)
        local vla = ffi.typeof(ctype)
        local buf, len = nil, -1
        return function(minlen)
            if minlen == false then
                buf, len = nil, -1
            elseif minlen > len then
                len = glue.nextpow2(minlen)
                buf = vla(len)
            end
            return buf, len
        end
    end

    -- like glue.buffer() but preserves data on reallocations
    -- also returns minlen instead of capacity.
    function glue.dynarray(ctype)
        local buffer = glue.buffer(ctype)
        local elem_size = ffi.sizeof(ctype, 1)
        local buf0, minlen0
        return function(minlen)
            local buf, len = buffer(minlen)
            if buf ~= buf0 and buf ~= nil and buf0 ~= nil then
                ffi.copy(buf, buf0, minlen0 * elem_size)
            end
            buf0, minlen0 = buf, minlen
            return buf, minlen
        end
    end

    local intptr_ct = ffi.typeof "intptr_t"
    local intptrptr_ct = ffi.typeof "const intptr_t*"
    local intptr1_ct = ffi.typeof "intptr_t[1]"
    local voidptr_ct = ffi.typeof "void*"

    -- x86: convert a pointer's address to a Lua number.
    local function addr32(p)
        return tonumber(ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p)))
    end

    -- x86: convert a number to a pointer, optionally specifying a ctype.
    local function ptr32(ctype, addr)
        if not addr then
            ctype, addr = voidptr_ct, ctype
        end
        return ffi.cast(ctype, addr)
    end

    -- x64: convert a pointer's address to a Lua number or possibly string.
    local function addr64(p)
        local np = ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p))
        local n = tonumber(np)
        if ffi.cast(intptr_ct, n) ~= np then
            -- address too big (ASLR? tagged pointers?): convert to string.
            return ffi.string(intptr1_ct(np), 8)
        end
        return n
    end

    -- x64: convert a number or string to a pointer, optionally specifying a ctype.
    local function ptr64(ctype, addr)
        if not addr then
            ctype, addr = voidptr_ct, ctype
        end
        if type(addr) == "string" then
            return ffi.cast(ctype, ffi.cast(voidptr_ct, ffi.cast(intptrptr_ct, addr)[0]))
        else
            return ffi.cast(ctype, addr)
        end
    end

    glue.addr = ffi.abi "64bit" and addr64 or addr32
    glue.ptr = ffi.abi "64bit" and ptr64 or ptr32

end -- if jit

if bit then

    local band, bor, bnot = bit.band, bit.bor, bit.bnot

    -- extract the bool value of a bitmask from a value.
    function glue.getbit(from, mask)
        return band(from, mask) == mask
    end

    -- set a single bit of a value without affecting other bits.
    function glue.setbit(over, mask, yes)
        return bor(yes and mask or 0, band(over, bnot(mask)))
    end

    local function bor_bit(bits, k, mask, strict)
        local b = bits[k]
        if b then
            return bit.bor(mask, b)
        elseif strict then
            error(string.format("invalid bit %s", k))
        else
            return mask
        end
    end
    function glue.bor(flags, bits, strict)
        local mask = 0
        if type(flags) == "number" then
            return flags -- passthrough
        elseif type(flags) == "string" then
            for k in flags:gmatch "[^%s]+" do
                mask = bor_bit(bits, k, mask, strict)
            end
        elseif type(flags) == "table" then
            for k, v in pairs(flags) do
                k = type(k) == "number" and v or k
                mask = bor_bit(bits, k, mask, strict)
            end
        else
            error "flags expected"
        end
        return mask
    end

end

return glue

end,

["json"] = function()
--------------------
-- Module: 'json'
--------------------
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


return json

end,

["blam"] = function()
--------------------
-- Module: 'blam'
--------------------
------------------------------------------------------------------------------
-- Blam! library for Chimera/SAPP Lua scripting
-- Sledmine, JerryBrick
-- Easier memory handle and provides standard functions for scripting
------------------------------------------------------------------------------
local blam = {_VERSION = "1.7.0"}

------------------------------------------------------------------------------
-- Useful functions for internal usage
------------------------------------------------------------------------------

-- From legacy glue library!
--- String or number to hex
local function tohex(s, upper)
    if type(s) == "number" then
        return (upper and "%08.8X" or "%08.8x"):format(s)
    end
    if upper then
        return (s:sub(".", function(c)
            return ("%02X"):format(c:byte())
        end))
    else
        return (s:gsub(".", function(c)
            return ("%02x"):format(c:byte())
        end))
    end
end

--- Hex to binary string
local function fromhex(s)
    if #s % 2 == 1 then
        return fromhex("0" .. s)
    end
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function split(s, sep)
    if (sep == nil or sep == "") then
        return 1
    end
    local position, array = 0, {}
    for st, sp in function()
        return string.find(s, sep, position, true)
    end do
        table.insert(array, string.sub(s, position, st - 1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

------------------------------------------------------------------------------
-- Blam! engine data
------------------------------------------------------------------------------

-- Engine address list
local addressList = {
    tagDataHeader = 0x40440000,
    cameraType = 0x00647498, -- from giraffe
    gamePaused = 0x004ACA79,
    gameOnMenus = 0x00622058,
    joystickInput = 0x64D998, -- from aLTis
    firstPerson = 0x40000EB8, -- from aLTis
    objectTable = 0x400506B4,
    deviceGroupsTable = 0x00816110,
    widgetsInstance = 0x6B401C
}

-- Server side addresses adjustment
if (api_version or server_type == "sapp") then
    addressList.deviceGroupsTable = 0x006E1C50
end

-- Tag classes values
---@enum tagClasses
local tagClasses = {
    actorVariant = "actv",
    actor = "actr",
    antenna = "ant!",
    biped = "bipd",
    bitmap = "bitm",
    cameraTrack = "trak",
    colorTable = "colo",
    continuousDamageEffect = "cdmg",
    contrail = "cont",
    damageEffect = "jpt!",
    decal = "deca",
    detailObjectCollection = "dobc",
    deviceControl = "ctrl",
    deviceLightFixture = "lifi",
    deviceMachine = "mach",
    device = "devi",
    dialogue = "udlg",
    effect = "effe",
    equipment = "eqip",
    flag = "flag",
    fog = "fog ",
    font = "font",
    garbage = "garb",
    gbxmodel = "mod2",
    globals = "matg",
    glow = "glw!",
    grenadeHudInterface = "grhi",
    hudGlobals = "hudg",
    hudMessageText = "hmt ",
    hudNumber = "hud#",
    itemCollection = "itmc",
    item = "item",
    lensFlare = "lens",
    lightVolume = "mgs2",
    light = "ligh",
    lightning = "elec",
    materialEffects = "foot",
    meter = "metr",
    modelAnimations = "antr",
    modelCollisiionGeometry = "coll",
    model = "mode",
    multiplayerScenarioDescription = "mply",
    object = "obje",
    particleSystem = "pctl",
    particle = "part",
    physics = "phys",
    placeHolder = "plac",
    pointPhysics = "pphy",
    preferencesNetworkGame = "ngpr",
    projectile = "proj",
    scenarioStructureBsp = "sbsp",
    scenario = "scnr",
    scenery = "scen",
    shaderEnvironment = "senv",
    shaderModel = "soso",
    shaderTransparentChicagoExtended = "scex",
    shaderTransparentChicago = "schi",
    shaderTransparentGeneric = "sotr",
    shaderTransparentGlass = "sgla",
    shaderTransparentMeter = "smet",
    shaderTransparentPlasma = "spla",
    shaderTransparentWater = "swat",
    shader = "shdr",
    sky = "sky ",
    soundEnvironment = "snde",
    soundLooping = "lsnd",
    soundScenery = "ssce",
    sound = "snd!",
    spheroid = "boom",
    stringList = "str#",
    tagCollection = "tagc",
    uiWidgetCollection = "Soul",
    uiWidgetDefinition = "DeLa",
    unicodeStringList = "ustr",
    unitHudInterface = "unhi",
    unit = "unit",
    vehicle = "vehi",
    virtualKeyboard = "vcky",
    weaponHudInterface = "wphi",
    weapon = "weap",
    weatherParticleSystem = "rain",
    wind = "wind"
}

-- Blam object classes values
---@enum objectClasses
local objectClasses = {
    biped = 0,
    vehicle = 1,
    weapon = 2,
    equipment = 3,
    garbage = 4,
    projectile = 5,
    scenery = 6,
    machine = 7,
    control = 8,
    lightFixture = 9,
    placeHolder = 10,
    soundScenery = 11
}

-- Camera types
---@enum cameraTypes
local cameraTypes = {
    scripted = 1, -- 22192
    firstPerson = 2, -- 30400
    devcam = 3, -- 30704
    thirdPerson = 4, -- 31952
    deadCamera = 5 -- 23776
}

-- Netgame flag classes
---@enum netgameFlagClasses
local netgameFlagClasses = {
    ctfFlag = 0,
    ctfVehicle = 1,
    ballSpawn = 2,
    raceTrack = 3,
    raceVehicle = 4,
    vegasBank = 5,
    teleportFrom = 6,
    teleportTo = 7,
    hillFlag = 8
}

-- Game type classes
---@enum gameTypeClasses
local gameTypeClasses = {
    none = 0,
    ctf = 1,
    slayer = 2,
    oddball = 3,
    koth = 4,
    race = 5,
    terminator = 6,
    stub = 7,
    ignored1 = 8,
    ignored2 = 9,
    ignored3 = 10,
    ignored4 = 11,
    allGames = 12,
    allExceptCtf = 13,
    allExceptRaceCtf = 14
}

-- Multiplayer team classes
---@enum multiplayerTeamClasses
local multiplayerTeamClasses = {red = 0, blue = 1}

-- Unit team classes
---@enum unitTeamClasses
local unitTeamClasses = {
    defaultByUnit = 0,
    player = 1,
    human = 2,
    covenant = 3,
    flood = 4,
    sentinel = 5,
    unused6 = 6,
    unused7 = 7,
    unused8 = 8,
    unused9 = 9
}

-- Standard console colors
local consoleColors = {
    success = {1, 0.235, 0.82, 0},
    warning = {1, 0.94, 0.75, 0.098},
    error = {1, 1, 0.2, 0.2},
    unknown = {1, 0.66, 0.66, 0.66}
}

-- Offset input from the joystick game data
local joystickInputs = {
    -- No zero values also pressed time until maxmimum byte size
    button1 = 0, -- Triangle
    button2 = 1, -- Circle
    button3 = 2, -- Cross
    button4 = 3, -- Square
    leftBumper = 4,
    rightBumper = 5,
    leftTrigger = 6,
    rightTrigger = 7,
    backButton = 8,
    startButton = 9,
    leftStick = 10,
    rightStick = 11,
    -- Multiple values on the same offset, check dPadValues table
    dPad = 96,
    -- Non zero values
    dPadUp = 100,
    dPadDown = 104,
    dPadLeft = 106,
    dPadRight = 102,
    dPadUpRight = 101,
    dPadDownRight = 103,
    dPadUpLeft = 107,
    dPadDownLeft = 105
    -- TODO Add joys axis
    -- rightJoystick = 30,
}

-- Values for the possible dPad values from the joystick inputs
local dPadValues = {
    noButton = 1020,
    upRight = 766,
    downRight = 768,
    upLeft = 772,
    downLeft = 770,
    left = 771,
    right = 767,
    down = 769,
    up = 765
}

-- Global variables

---	This is the current gametype that is running. If no gametype is running, this will be set to nil
---, possible values are: ctf, slayer, oddball, king, race.
---@type string | nil
gametype = gametype
---This is the index of the local player. This is a value between 0 and 15, this value does not
---match with player index in the server and is not instantly assigned after joining.
---@type number | nil
local_player_index = local_player_index
---This is the name of the current loaded map.
---@type string
map = map
---Return if the map has protected tags data.
---@type boolean
map_is_protected = map_is_protected
---This is the name of the script. If the script is a global script, it will be defined as the
---filename of the script. Otherwise, it will be the name of the map.
---@type string
script_name = script_name
---This is the script type, possible values are global or map.
---@type string
script_type = script_type
---@type '"none"' | '"local"' | '"dedicated"' | '"sapp"'
server_type = server_type
---Return whether or not the script is sandboxed. See Sandoboxed Scripts for more information.
---@deprecated
---@type boolean
sandboxed = sandboxed ---@diagnostic disable-line: deprecated

local backupFunctions = {}

backupFunctions.console_is_open = _G.console_is_open
backupFunctions.console_out = _G.console_out
backupFunctions.execute_script = _G.execute_script
backupFunctions.get_global = _G.get_global
-- backupFunctions.set_global = _G.set_global
backupFunctions.get_tag = _G.get_tag
backupFunctions.set_callback = _G.set_callback

backupFunctions.spawn_object = _G.spawn_object
backupFunctions.delete_object = _G.delete_object
backupFunctions.get_object = _G.get_object
backupFunctions.get_dynamic_player = _G.get_dynamic_player

backupFunctions.hud_message = _G.hud_message

backupFunctions.create_directory = _G.create_directory
backupFunctions.remove_directory = _G.remove_directory
backupFunctions.directory_exists = _G.directory_exists
backupFunctions.list_directory = _G.list_directory
backupFunctions.write_file = _G.write_file
backupFunctions.read_file = _G.read_file
backupFunctions.delete_file = _G.delete_file
backupFunctions.file_exists = _G.file_exists

------------------------------------------------------------------------------
-- Chimera API auto completion
-- EmmyLua autocompletion for some functions!
-- Functions below do not have a real implementation and are not supossed to be imported
------------------------------------------------------------------------------

---Attempt to spawn an object given tag class, tag path and coordinates.
---Given a tag id is also accepted.
---@overload fun(tagId: number, x: number, y: number, z: number):number
---@param tagClass tagClasses Type of the tag to spawn
---@param tagPath string Path of object to spawn
---@param x number
---@param y number
---@param z number
---@return number? objectId
function spawn_object(tagClass, tagPath, x, y, z)
end

---Attempt to get the address of a player unit object given player index, returning nil on failure.<br>
---If no argument is given, the address to the local player’s unit object is returned, instead.
---@param playerIndex? number
---@return number? objectAddress
function get_dynamic_player(playerIndex)
end

spawn_object = backupFunctions.spawn_object
get_dynamic_player = backupFunctions.get_dynamic_player

------------------------------------------------------------------------------
-- SAPP API bindings
------------------------------------------------------------------------------

---Write content to a text file given file path
---@param path string Path to the file to write
---@param content string Content to write into the file
---@return boolean, string? result True if successful otherwise nil, error
function write_file(path, content)
    local file, error = io.open(path, "w")
    if (not file) then
        return false, error
    end
    local success, err = file:write(content)
    file:close()
    if (not success) then
        os.remove(path)
        return false, err
    else
        return true
    end
end

---Read the contents from a file given file path.
---@param path string Path to the file to read
---@return boolean, string? content string if successful otherwise nil, error
function read_file(path)
    local file, error = io.open(path, "r")
    if (not file) then
        return false, error
    end
    local content, error = file:read("*a")
    if (content == nil) then
        return false, error
    end
    file:close()
    return content
end

---Attempt create a directory with the given path.
---
---An error will occur if the directory can not be created.
---@param path string Path to the directory to create
---@return boolean
function create_directory(path)
    local success, error = os.execute("mkdir " .. path)
    if (not success) then
        return false
    end
    return true
end

---Attempt to remove a directory with the given path.
---
---An error will occur if the directory can not be removed.
---@param path string Path to the directory to remove
---@return boolean
function remove_directory(path)
    local success, error = os.execute("rmdir -r " .. path)
    if (not success) then
        return false
    end
    return true
end

---Verify if a directory exists given directory path
---@param path string
---@return boolean
function directory_exists(path)
    print("directory_exists", path)
    return os.execute("dir \"" .. path .. "\" > nul") == 0
end

---List the contents from a directory given directory path
---@param path string
---@return nil | integer | table
function list_directory(path)
    -- TODO This needs a way to separate folders from files
    if (path) then
        local command = "dir \"" .. path .. "\" /B"
        local pipe = io.popen(command, "r")
        if pipe then
            local output = pipe:read("*a")
            if (output) then
                local items = split(output, "\n")
                for index, item in pairs(items) do
                    if (item and item == "") then
                        items[index] = nil
                    end
                end
                return items
            end
        end
    end
    return nil
end

---Delete a file given file path
---@param path string
---@return boolean
function delete_file(path)
    return os.remove(path)
end

---Return if a file exists given file path.
---@param path string
---@return boolean
function file_exists(path)
    local file = io.open(path, "r")
    if (file) then
        file:close()
        return true
    end
    return false
end

---Return the memory address of a tag given tagId or tagClass and tagPath
---@param tagIdOrTagType string | number
---@param tagPath? string
---@return number?
function get_tag(tagIdOrTagType, tagPath)
    if (not tagPath) then
        return lookup_tag(tagIdOrTagType)
    else
        return lookup_tag(tagIdOrTagType, tagPath)
    end
end

---Execute a custom Halo script.
---
---A script can be either a standalone Halo command or a Lisp-formatted Halo scripting block.
---@param command string
function execute_script(command)
    return execute_command(command)
end

---Return the address of the object memory given object id
---@param objectId number
---@return number?
function get_object(objectId)
    if (objectId) then
        local object_memory = get_object_memory(objectId)
        if (object_memory ~= 0) then
            return object_memory
        end
    end
    return nil
end

---Despawn an object given objectId. An error will occur if the object does not exist.
---@param objectId number
function delete_object(objectId)
    destroy_object(objectId)
end

---Output text to the console, optional text colors in decimal format.<br>
---Avoid sending console messages if console_is_open() is true to avoid annoying the player.
---@param message string
---@param red? number
---@param green? number
---@param blue? number
function console_out(message, red, green, blue)
    -- TODO Add color printing to this function on SAPP
    cprint(message)
end

---Return true if the player has the console open, always returns true on SAPP.
---@return boolean
function console_is_open()
    return true
end

---Get the value of a Halo scripting global.\
---An error will be triggered if the global is not found
---@param name string Name of the global variable to get from hsc
---@return boolean | number
function get_global(name)
    error("SAPP can not retrieve global variables as Chimera does.. yet!")
end

---Print message to player HUD.\
---Messages will be printed to console if SAPP uses this function
---@param message string
function hud_message(message)
    cprint(message)
end

---Set the callback for an event game from the game events available on Chimera
---@param event '"command"' | '"frame"' | '"preframe"' | '"map load"' | '"precamera"' | '"rcon message"' | '"tick"' | '"pretick"' | '"unload"'
---@param callback string Global function name to call when the event is triggered
function set_callback(event, callback)
    if event == "tick" then
        register_callback(cb["EVENT_TICK"], callback)
    elseif event == "pretick" then
        error("SAPP does not support pretick event")
    elseif event == "frame" then
        error("SAPP does not support frame event")
    elseif event == "preframe" then
        error("SAPP does not support preframe event")
    elseif event == "map_load" then
        register_callback(cb["EVENT_GAME_START"], callback)
    elseif event == "precamera" then
        error("SAPP does not support precamera event")
    elseif event == "rcon message" then
        _G[callback .. "_rcon_message"] = function (playerIndex, command, environment, password)
            return _G[callback](playerIndex, command, password)
        end
        register_callback(cb["EVENT_COMMAND"], callback .. "_rcon_message")
    elseif event == "command" then
        _G[callback .. "_command"] = function (playerIndex, command, environment)
            return _G[callback](playerIndex, command, environment)
        end
        register_callback(cb["EVENT_COMMAND"], callback .. "_command")
    elseif event == "unload" then
        register_callback(cb["EVENT_GAME_END"], callback)
    else
        error("Unknown event: " .. event)
    end
end

if (api_version) then
    -- Provide global server type variable on SAPP
    server_type = "sapp"
    print("Compatibility with Chimera Lua API has been loaded!")
else
    console_is_open = backupFunctions.console_is_open
    console_out = backupFunctions.console_out
    execute_script = backupFunctions.execute_script
    get_global = backupFunctions.get_global
    -- set_global = -- backupFunctions.set_global
    get_tag = backupFunctions.get_tag
    set_callback = backupFunctions.set_callback
    spawn_object = backupFunctions.spawn_object
    delete_object = backupFunctions.delete_object
    get_object = backupFunctions.get_object
    get_dynamic_player = backupFunctions.get_dynamic_player
    hud_message = backupFunctions.hud_message
    create_directory = backupFunctions.create_directory
    remove_directory = backupFunctions.remove_directory
    directory_exists = backupFunctions.directory_exists
    list_directory = backupFunctions.list_directory
    write_file = backupFunctions.write_file
    read_file = backupFunctions.read_file
    delete_file = backupFunctions.delete_file
    file_exists = backupFunctions.file_exists
end

------------------------------------------------------------------------------
-- Generic functions
------------------------------------------------------------------------------

--- Verify if the given variable is a number
---@param var any
---@return boolean
local function isNumber(var)
    return (type(var) == "number")
end

--- Verify if the given variable is a string
---@param var any
---@return boolean
local function isString(var)
    return (type(var) == "string")
end

--- Verify if the given variable is a boolean
---@param var any
---@return boolean
local function isBoolean(var)
    return (type(var) == "boolean")
end

--- Verify if the given variable is a table
---@param var any
---@return boolean
local function isTable(var)
    return (type(var) == "table")
end

--- Remove spaces and tabs from the beginning and the end of a string
---@param str string
---@return string
local function trim(str)
    return str:match("^%s*(.*)"):match("(.-)%s*$")
end

--- Verify if the value is valid
---@param var any
---@return boolean
local function isValid(var)
    return (var and var ~= "" and var ~= 0)
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------

--- Convert tag class int to string
---@param tagClassInt number
---@return string?
local function tagClassFromInt(tagClassInt)
    if (tagClassInt) then
        local tagClassHex = tohex(tagClassInt)
        local tagClass = ""
        if (tagClassHex) then
            local byte = ""
            for char in string.gmatch(tagClassHex, ".") do
                byte = byte .. char
                if (#byte % 2 == 0) then
                    tagClass = tagClass .. string.char(tonumber(byte, 16))
                    byte = ""
                end
            end
        end
        return tagClass
    end
    return nil
end

--- Return a list of all the objects currently in the map
---@return table
function blam.getObjects()
    local currentObjectsList = {}
    for i = 0, 2047 do
        if (blam.getObject(i)) then
            currentObjectsList[#currentObjectsList + 1] = i
        end
    end
    return currentObjectsList
end

-- Local reference to the original console_out function
local original_console_out = console_out

--- Print a console message. It also supports multi-line messages!
---@param message string
local function consoleOutput(message, ...)
    -- Put the extra arguments into a table
    local args = {...}

    if (message == nil or #args > 5) then
        consoleOutput(debug.traceback("Wrong number of arguments on console output function", 2),
                      consoleColors.error)
    end

    -- Output color
    local colorARGB = {1, 1, 1, 1}

    -- Get the output color from arguments table
    if (isTable(args[1])) then
        colorARGB = args[1]
    elseif (#args == 3 or #args == 4) then
        colorARGB = args
    end

    -- Set alpha channel if not set
    if (#colorARGB == 3) then
        table.insert(colorARGB, 1, 1)
    end

    if message then
        if (isString(message)) then
            -- Explode the string!!
            for line in message:gmatch("([^\n]+)") do
                -- Trim the line
                local trimmedLine = trim(line)

                -- Print the line
                original_console_out(trimmedLine, table.unpack(colorARGB))
            end
        else
            original_console_out(message, table.unpack(colorARGB))
        end
    end
end

--- Convert booleans to bits and bits to booleans
---@param bitOrBool number
---@return boolean | number
local function b2b(bitOrBool)
    if (bitOrBool == 1) then
        return true
    elseif (bitOrBool == 0) then
        return false
    elseif (bitOrBool == true) then
        return 1
    elseif (bitOrBool == false) then
        return 0
    end
    error("B2B error, expected boolean or bit value, got " .. tostring(bitOrBool) .. " " ..
              type(bitOrBool))
end

------------------------------------------------------------------------------
-- Data manipulation and binding
------------------------------------------------------------------------------

local typesOperations

local function readBit(address, propertyData)
    return b2b(read_bit(address, propertyData.bitLevel))
end

local function writeBit(address, propertyData, propertyValue)
    return write_bit(address, propertyData.bitLevel, b2b(propertyValue))
end

local function readByte(address)
    return read_byte(address)
end

local function writeByte(address, propertyData, propertyValue)
    return write_byte(address, propertyValue)
end

local function readShort(address)
    return read_short(address)
end

local function writeShort(address, propertyData, propertyValue)
    return write_short(address, propertyValue)
end

local function readWord(address)
    return read_word(address)
end

local function writeWord(address, propertyData, propertyValue)
    return write_word(address, propertyValue)
end

local function readInt(address)
    return read_int(address)
end

local function writeInt(address, propertyData, propertyValue)
    return write_int(address, propertyValue)
end

local function readDword(address)
    return read_dword(address)
end

local function writeDword(address, propertyData, propertyValue)
    return write_dword(address, propertyValue)
end

local function readFloat(address)
    return read_float(address)
end

local function writeFloat(address, propertyData, propertyValue)
    return write_float(address, propertyValue)
end

local function readChar(address)
    return read_char(address)
end

local function writeChar(address, propertyData, propertyValue)
    return write_char(address, propertyValue)
end

local function readString(address)
    return read_string(address)
end

local function writeString(address, propertyData, propertyValue)
    return write_string(address, propertyValue)
end

--- Return the string of a unicode string given address
---@param address number
---@param rawRead? boolean
---@return string
function blam.readUnicodeString(address, rawRead)
    local stringAddress
    if (rawRead) then
        stringAddress = address
    else
        stringAddress = read_dword(address)
    end
    local length = stringAddress / 2
    local output = ""
    -- TODO Refactor this to support full unicode char size
    for i = 1, length do
        local char = read_string(stringAddress + (i - 1) * 0x2)
        if (char == "") then
            break
        end
        output = output .. char
    end
    return output
end

--- Writes a unicode string in a given address
---@param address number
---@param newString string
---@param forced? boolean
function blam.writeUnicodeString(address, newString, forced)
    local stringAddress
    if (forced) then
        stringAddress = address
    else
        stringAddress = read_dword(address)
    end
    -- Allow cancelling writing when the new string is a boolean false value
    if newString == false then
        return
    end
    -- TODO Refactor this to support writing ASCII and Unicode strings
    for i = 1, #newString do
        write_string(stringAddress + (i - 1) * 0x2, newString:sub(i, i))
        if (i == #newString) then
            write_byte(stringAddress + #newString * 0x2, 0x0)
        end
    end
    if #newString == 0 then
        write_string(stringAddress, "")
    end
end

local function readPointerUnicodeString(address, propertyData)
    return blam.readUnicodeString(address)
end

local function readUnicodeString(address, propertyData)
    return blam.readUnicodeString(address, true)
end

local function writePointerUnicodeString(address, propertyData, propertyValue)
    return blam.writeUnicodeString(address, propertyValue)
end

local function writeUnicodeString(address, propertyData, propertyValue)
    return blam.writeUnicodeString(address, propertyValue, true)
end

local function readList(address, propertyData)
    local operation = typesOperations[propertyData.elementsType]
    local elementCount = read_word(address - 0x4)
    local addressList = read_dword(address) + 0xC
    if (propertyData.noOffset) then
        addressList = read_dword(address)
    end
    local list = {}
    for currentElement = 1, elementCount do
        list[currentElement] = operation.read(addressList +
                                                  (propertyData.jump * (currentElement - 1)))
    end
    return list
end

local function writeList(address, propertyData, propertyValue)
    local operation = typesOperations[propertyData.elementsType]
    local elementCount = read_word(address - 0x4)
    local addressList
    if (propertyData.noOffset) then
        addressList = read_dword(address)
    else
        addressList = read_dword(address) + 0xC
    end
    for currentElement = 1, elementCount do
        local elementValue = propertyValue[currentElement]
        if (elementValue) then
            -- Check if there are problems at sending property data here due to missing property data
            operation.write(addressList + (propertyData.jump * (currentElement - 1)), propertyData,
                            elementValue)
        else
            if (currentElement > #propertyValue) then
                break
            end
        end
    end
end

local function readTable(address, propertyData)
    local table = {}
    local elementsCount = read_byte(address - 0x4)
    local firstElement = read_dword(address)
    for elementPosition = 1, elementsCount do
        local elementAddress = firstElement + ((elementPosition - 1) * propertyData.jump)
        table[elementPosition] = {}
        for subProperty, subPropertyData in pairs(propertyData.rows) do
            local operation = typesOperations[subPropertyData.type]
            table[elementPosition][subProperty] = operation.read(elementAddress +
                                                                     subPropertyData.offset,
                                                                 subPropertyData)
        end
    end
    return table
end

local function writeTable(address, propertyData, propertyValue)
    local elementCount = read_byte(address - 0x4)
    local firstElement = read_dword(address)
    for currentElement = 1, elementCount do
        local elementAddress = firstElement + (currentElement - 1) * propertyData.jump
        if (propertyValue[currentElement]) then
            for subProperty, subPropertyValue in pairs(propertyValue[currentElement]) do
                local subPropertyData = propertyData.rows[subProperty]
                if (subPropertyData) then
                    local operation = typesOperations[subPropertyData.type]
                    operation.write(elementAddress + subPropertyData.offset, subPropertyData,
                                    subPropertyValue)
                end
            end
        else
            if (currentElement > #propertyValue) then
                break
            end
        end
    end
end

local function readTagReference(address)
    -- local tagClass = read_dword(address)
    -- local tagPathPointer = read_dword(address = 0x4)
    local tagId = read_dword(address + 0xC)
    return tagId
end

local function writeTagReference(address, propertyData, propertyValue)
    write_dword(address + 0xC, propertyValue)
end

-- Data types operations references
typesOperations = {
    bit = {read = readBit, write = writeBit},
    byte = {read = readByte, write = writeByte},
    short = {read = readShort, write = writeShort},
    word = {read = readWord, write = writeWord},
    int = {read = readInt, write = writeInt},
    dword = {read = readDword, write = writeDword},
    float = {read = readFloat, write = writeFloat},
    char = {read = readChar, write = writeChar},
    string = {read = readString, write = writeString},
    -- TODO This is not ok, a pointer type with subtyping should be implemented
    pustring = {read = readPointerUnicodeString, write = writePointerUnicodeString},
    ustring = {read = readUnicodeString, write = writeUnicodeString},
    list = {read = readList, write = writeList},
    table = {read = readTable, write = writeTable},
    tagref = {read = readTagReference, write = writeTagReference}
}

-- Magic luablam metatable
local dataBindingMetaTable = {
    __newindex = function(object, property, propertyValue)
        -- Get all the data related to property field
        local propertyData = object.structure[property]
        if (propertyData) then
            local operation = typesOperations[propertyData.type]
            local propertyAddress = object.address + propertyData.offset
            operation.write(propertyAddress, propertyData, propertyValue)
        else
            local errorMessage = "Unable to write an invalid property ('" .. property .. "')"
            error(debug.traceback(errorMessage, 2))
        end
    end,
    __index = function(object, property)
        local objectStructure = object.structure
        local propertyData = objectStructure[property]
        if (propertyData) then
            local operation = typesOperations[propertyData.type]
            local propertyAddress = object.address + propertyData.offset
            return operation.read(propertyAddress, propertyData)
        else
            local errorMessage = "Unable to read an invalid property ('" .. property .. "')"
            error(debug.traceback(errorMessage, 2))
        end
    end
}

------------------------------------------------------------------------------
-- Object functions
------------------------------------------------------------------------------

--- Create a blam object
---@param address number
---@param struct table
---@return table
local function createObject(address, struct)
    -- Create object
    local object = {}

    -- Set up legacy values
    object.address = address
    object.structure = struct

    -- Set mechanisim to bind properties to memory
    setmetatable(object, dataBindingMetaTable)

    return object
end

--- Return a dump of a given LuaBlam object
---@param object table
---@return table
local function dumpObject(object)
    local dump = {}
    for k, v in pairs(object.structure) do
        dump[k] = object[k]
    end
    return dump
end

--- Return a extended parent structure with another given structure
---@param parent table
---@param structure table
---@return table
local function extendStructure(parent, structure)
    local extendedStructure = {}
    for k, v in pairs(parent) do
        extendedStructure[k] = v
    end
    for k, v in pairs(structure) do
        extendedStructure[k] = v
    end
    return extendedStructure
end

------------------------------------------------------------------------------
-- Object structures
------------------------------------------------------------------------------

---@class dataTable
---@field name string
---@field maxElements number
---@field elementSize number
---@field capacity number
---@field size number
---@field nextElementId number
---@field firstElementAddress number

local dataTableStructure = {
    name = {type = "string", offset = 0},
    maxElements = {type = "word", offset = 0x20},
    elementSize = {type = "word", offset = 0x22},
    -- padding1 = {size = 0x0A, offset = 0x24},
    capacity = {type = "word", offset = 0x2E},
    size = {type = "word", offset = 0x30},
    nextElementId = {type = "word", offset = 0x32},
    firstElementAddress = {type = "dword", offset = 0x34}
}

local deviceGroupsTableStructure = {
    name = {type = "string", offset = 0},
    maxElements = {type = "word", offset = 0x20},
    elementSize = {type = "word", offset = 0x22},
    firstElementAddress = {type = "dword", offset = 0x34}
}

---@class blamObject
---@field address number
---@field tagId number Object tag ID
---@field isGhost boolean Set object in some type of ghost mode
---@field isOnGround boolean Is the object touching ground
---@field ignoreGravity boolean Make object to ignore gravity
---@field isInWater boolean Is the object touching on water
---@field dynamicShading boolean Enable disable dynamic shading for lightmaps
---@field isNotCastingShadow boolean Enable/disable object shadow casting
---@field isFrozen boolean Freeze/unfreeze object existence
---@field isOutSideMap boolean Is object outside/inside bsp
---@field isCollideable boolean Enable/disable object collision, does not work with bipeds or vehicles
---@field hasNoCollision boolean Enable/disable object collision, causes animation problems
---@field model number Gbxmodel tag ID
---@field health number Current health of the object
---@field shield number Current shield of the object
---@field colorAUpperRed number Red color channel for A modifier
---@field colorAUpperGreen number Green color channel for A modifier
---@field colorAUpperBlue number Blue color channel for A modifier
---@field colorBUpperRed number Red color channel for B modifier
---@field colorBUpperGreen number Green color channel for B modifier
---@field colorBUpperBlue number Blue color channel for B modifier
---@field colorCUpperRed number Red color channel for C modifier
---@field colorCUpperGreen number Green color channel for C modifier
---@field colorCUpperBlue number Blue color channel for C modifier
---@field colorDUpperRed number Red color channel for D modifier
---@field colorDUpperGreen number Green color channel for D modifier
---@field colorDUpperBlue number Blue color channel for D modifier
---@field colorALowerRed number Red color channel for A modifier
---@field colorALowerGreen number Green color channel for A modifier
---@field colorALowerBlue number Blue color channel for A modifier
---@field colorBLowerRed number Red color channel for B modifier
---@field colorBLowerGreen number Green color channel for B modifier
---@field colorBLowerBlue number Blue color channel for B modifier
---@field colorCLowerRed number Red color channel for C modifier
---@field colorCLowerGreen number Green color channel for C modifier
---@field colorCLowerBlue number Blue color channel for C modifier
---@field colorDLowerRed number Red color channel for D modifier
---@field colorDLowerGreen number Green color channel for D modifier
---@field colorDLowerBlue number Blue color channel for D modifier
---@field x number Current position of the object on X axis
---@field y number Current position of the object on Y axis
---@field z number Current position of the object on Z axis
---@field xVel number Current velocity of the object on X axis
---@field yVel number Current velocity of the object on Y axis
---@field zVel number Current velocity of the object on Z axis
---@field vX number Current x value in first rotation vector
---@field vY number Current y value in first rotation vector
---@field vZ number Current z value in first rotation vector
---@field v2X number Current x value in second rotation vector
---@field v2Y number Current y value in second rotation vector
---@field v2Z number Current z value in second rotation vector
---@field yawVel number Current velocity of the object in yaw
---@field pitchVel number Current velocity of the object in pitch
---@field rollVel number Current velocity of the object in roll
---@field locationId number Current id of the location in the map
---@field boundingRadius number Radius amount of the object in radians
---@field class objectClasses Object type
---@field team number Object multiplayer team
---@field nameIndex number Index of object name in the scenario tag
---@field playerId number Current player id if the object
---@field parentId number Current parent id of the object
---//@field isHealthEmpty boolean Is the object health depleted, also marked as "dead"
---@field isApparentlyDead boolean Is the object apparently dead
---@field isSilentlyKilled boolean Is the object really dead
---@field animationTagId number Current animation tag ID
---@field animation number Current animation index
---@field animationFrame number Current animation frame
---@field isNotDamageable boolean Make the object undamageable
---@field regionPermutation1 number
---@field regionPermutation2 number
---@field regionPermutation3 number
---@field regionPermutation4 number
---@field regionPermutation5 number
---@field regionPermutation6 number
---@field regionPermutation7 number
---@field regionPermutation8 number

-- blamObject structure
local objectStructure = {
    tagId = {type = "dword", offset = 0x0},
    isGhost = {type = "bit", offset = 0x10, bitLevel = 0},
    isOnGround = {type = "bit", offset = 0x10, bitLevel = 1},
    ignoreGravity = {type = "bit", offset = 0x10, bitLevel = 2},
    isInWater = {type = "bit", offset = 0x10, bitLevel = 3},
    isStationary = {type = "bit", offset = 0x10, bitLevel = 5},
    hasNoCollision = {type = "bit", offset = 0x10, bitLevel = 7},
    dynamicShading = {type = "bit", offset = 0x10, bitLevel = 14},
    isNotCastingShadow = {type = "bit", offset = 0x10, bitLevel = 18},
    isFrozen = {type = "bit", offset = 0x10, bitLevel = 20},
    -- FIXME Deprecated property, should be erased at a major release later
    frozen = {type = "bit", offset = 0x10, bitLevel = 20},
    isOutSideMap = {type = "bit", offset = 0x12, bitLevel = 5},
    isCollideable = {type = "bit", offset = 0x10, bitLevel = 24},
    model = {type = "dword", offset = 0x34},
    health = {type = "float", offset = 0xE0},
    shield = {type = "float", offset = 0xE4},
    ---@deprecated
    redA = {type = "float", offset = 0x1B8},
    ---@deprecated
    greenA = {type = "float", offset = 0x1BC},
    ---@deprecated
    blueA = {type = "float", offset = 0x1C0},
    colorAUpperRed = {type = "float", offset = 0x188},
    colorAUpperGreen = {type = "float", offset = 0x18C},
    colorAUpperBlue = {type = "float", offset = 0x190},
    colorBUpperRed = {type = "float", offset = 0x194},
    colorBUpperGreen = {type = "float", offset = 0x198},
    colorBUpperBlue = {type = "float", offset = 0x19C},
    colorCUpperRed = {type = "float", offset = 0x1A0},
    colorCUpperGreen = {type = "float", offset = 0x1A4},
    colorCUpperBlue = {type = "float", offset = 0x1A8},
    colorDUpperRed = {type = "float", offset = 0x1AC},
    colorDUpperGreen = {type = "float", offset = 0x1B0},
    colorDUpperBlue = {type = "float", offset = 0x1B4},
    colorALowerRed = {type = "float", offset = 0x1B8},
    colorALowerGreen = {type = "float", offset = 0x1BC},
    colorALowerBlue = {type = "float", offset = 0x1C0},
    colorBLowerRed = {type = "float", offset = 0x1C4},
    colorBLowerGreen = {type = "float", offset = 0x1C8},
    colorBLowerBlue = {type = "float", offset = 0x1CC},
    colorCLowerRed = {type = "float", offset = 0x1D0},
    colorCLowerGreen = {type = "float", offset = 0x1D4},
    colorCLowerBlue = {type = "float", offset = 0x1D8},
    colorDLowerRed = {type = "float", offset = 0x1DC},
    colorDLowerGreen = {type = "float", offset = 0x1E0},
    colorDLowerBlue = {type = "float", offset = 0x1E4},
    x = {type = "float", offset = 0x5C},
    y = {type = "float", offset = 0x60},
    z = {type = "float", offset = 0x64},
    xVel = {type = "float", offset = 0x68},
    yVel = {type = "float", offset = 0x6C},
    zVel = {type = "float", offset = 0x70},
    vX = {type = "float", offset = 0x74},
    vY = {type = "float", offset = 0x78},
    vZ = {type = "float", offset = 0x7C},
    v2X = {type = "float", offset = 0x80},
    v2Y = {type = "float", offset = 0x84},
    v2Z = {type = "float", offset = 0x88},
    -- FIXME Some order from this values is probaby wrong, expected order is pitch, yaw, roll
    yawVel = {type = "float", offset = 0x8C},
    pitchVel = {type = "float", offset = 0x90},
    rollVel = {type = "float", offset = 0x94},
    locationId = {type = "dword", offset = 0x98},
    boundingRadius = {type = "float", offset = 0xAC},
    ---@deprecated
    type = {type = "word", offset = 0xB4},
    class = {type = "word", offset = 0xB4},
    team = {type = "word", offset = 0xB8},
    nameIndex = {type = "word", offset = 0xBA},
    playerId = {type = "dword", offset = 0xC0},
    parentId = {type = "dword", offset = 0xC4},
    isHealthEmpty = {type = "bit", offset = 0x106, bitLevel = 2},
    isApparentlyDead = {type = "bit", offset = 0x106, bitLevel = 2},
    isSilentlyKilled = {type = "bit", offset = 0x106, bitLevel = 5},
    animationTagId = {type = "dword", offset = 0xCC},
    animation = {type = "word", offset = 0xD0},
    animationFrame = {type = "word", offset = 0xD2},
    isNotDamageable = {type = "bit", offset = 0x106, bitLevel = 11},
    regionPermutation1 = {type = "byte", offset = 0x180},
    regionPermutation2 = {type = "byte", offset = 0x181},
    regionPermutation3 = {type = "byte", offset = 0x182},
    regionPermutation4 = {type = "byte", offset = 0x183},
    regionPermutation5 = {type = "byte", offset = 0x184},
    regionPermutation6 = {type = "byte", offset = 0x185},
    regionPermutation7 = {type = "byte", offset = 0x186},
    regionPermutation8 = {type = "byte", offset = 0x187}
}

---@class biped : blamObject
---@field invisible boolean Biped invisible state
---@field noDropItems boolean Biped ability to drop items at dead
---@field ignoreCollision boolean Biped ignores collisiion
---@field flashlight boolean Biped has flaslight enabled
---@field cameraX number Current position of the biped  X axis
---@field cameraY number Current position of the biped  Y axis
---@field cameraZ number Current position of the biped  Z axis
---@field crouchHold boolean Biped is holding crouch action
---@field jumpHold boolean Biped is holding jump action
---@field actionKeyHold boolean Biped is holding action key
---@field actionKey boolean Biped pressed action key
---@field meleeKey boolean Biped pressed melee key
---@field reloadKey boolean Biped pressed reload key
---@field weaponPTH boolean Biped is holding primary weapon trigger
---@field weaponSTH boolean Biped is holding secondary weapon trigger
---@field flashlightKey boolean Biped pressed flashlight key
---@field grenadeHold boolean Biped is holding grenade action
---@field crouch number Is biped crouch
---@field shooting number Is biped shooting, 0 when not, 1 when shooting
---@field weaponSlot number Current biped weapon slot
---@field zoomLevel number Current biped weapon zoom level, 0xFF when no zoom, up to 255 when zoomed
---@field invisibleScale number Opacity amount of biped invisiblity
---@field primaryNades number Primary grenades count
---@field secondaryNades number Secondary grenades count
---@field landing number Biped landing state, 0 when landing, stays on 0 when landing hard, null otherwise
---@field bumpedObjectId number Object ID that the biped is bumping, vehicles, bipeds, etc, keeps the previous value if not bumping a new object
---@field vehicleSeatIndex number Current vehicle seat index of this biped
---@field vehicleObjectId number Current vehicle objectId of this object
---@field walkingState number Biped walking state, 0 = not walking, 1 = walking, 2 = stoping walking, 3 = stationary
---@field motionState number Biped motion state, 0 = standing , 1 = walking , 2 = jumping/falling
---@field mostRecentDamagerPlayer number Id of the player that caused the most recent damage to this biped

-- Biped structure (extends object structure)
local bipedStructure = extendStructure(objectStructure, {
    invisible = {type = "bit", offset = 0x204, bitLevel = 4},
    noDropItems = {type = "bit", offset = 0x204, bitLevel = 20},
    ignoreCollision = {type = "bit", offset = 0x4CC, bitLevel = 3},
    flashlight = {type = "bit", offset = 0x204, bitLevel = 19},
    cameraX = {type = "float", offset = 0x230},
    cameraY = {type = "float", offset = 0x234},
    cameraZ = {type = "float", offset = 0x238},
    crouchHold = {type = "bit", offset = 0x208, bitLevel = 0},
    jumpHold = {type = "bit", offset = 0x208, bitLevel = 1},
    actionKeyHold = {type = "bit", offset = 0x208, bitLevel = 14},
    actionKey = {type = "bit", offset = 0x208, bitLevel = 6},
    meleeKey = {type = "bit", offset = 0x208, bitLevel = 7},
    reloadKey = {type = "bit", offset = 0x208, bitLevel = 10},
    weaponPTH = {type = "bit", offset = 0x208, bitLevel = 11},
    weaponSTH = {type = "bit", offset = 0x208, bitLevel = 12},
    flashlightKey = {type = "bit", offset = 0x208, bitLevel = 4},
    grenadeHold = {type = "bit", offset = 0x208, bitLevel = 13},
    crouch = {type = "byte", offset = 0x2A0},
    shooting = {type = "float", offset = 0x284},
    weaponSlot = {type = "byte", offset = 0x2A1},
    zoomLevel = {type = "byte", offset = 0x320},
    invisibleScale = {type = "byte", offset = 0x37C},
    primaryNades = {type = "byte", offset = 0x31E},
    secondaryNades = {type = "byte", offset = 0x31F},
    landing = {type = "byte", offset = 0x508},
    bumpedObjectId = {type = "dword", offset = 0x4FC},
    vehicleObjectId = {type = "dword", offset = 0x11C},
    vehicleSeatIndex = {type = "word", offset = 0x2F0},
    walkingState = {type = "char", offset = 0x503},
    motionState = {type = "byte", offset = 0x4D2},
    mostRecentDamagerPlayer = {type = "dword", offset = 0x43C}
})

-- Tag data header structure
local tagDataHeaderStructure = {
    array = {type = "dword", offset = 0x0},
    scenario = {type = "dword", offset = 0x4},
    count = {type = "word", offset = 0xC}
}

---@class tag
---@field class number Type of the tag
---@field index number Tag Index
---@field id number Tag ID
---@field path string Path of the tag
---@field data number Address of the tag data
---@field indexed boolean Is tag indexed on an external map file

-- Tag structure
local tagHeaderStructure = {
    class = {type = "dword", offset = 0x0},
    index = {type = "word", offset = 0xC},
    id = {type = "dword", offset = 0xC},
    path = {type = "dword", offset = 0x10},
    data = {type = "dword", offset = 0x14},
    indexed = {type = "dword", offset = 0x18}
}

---@class tagCollection
---@field count number Number of tags in the collection
---@field tagList table List of tags

-- tagCollection structure
local tagCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {type = "list", offset = 0x4, elementsType = "dword", jump = 0x10}
}

---@class unicodeStringList
---@field count number Number of unicode strings
---@field stringList table List of unicode strings

-- UnicodeStringList structure
local unicodeStringListStructure = {
    count = {type = "byte", offset = 0x0},
    stringList = {type = "list", offset = 0x4, elementsType = "pustring", jump = 0x14}
}

---@class bitmapSequence
---@field name string
---@field firtBitmapIndex number
---@field bitmapCount number

---@class bitmap
---@field type number
---@field format number
---@field usage number
---@field usageFlags number
---@field detailFadeFactor number
---@field sharpenAmount number
---@field bumpHeight number
---@field spriteBudgetSize number
---@field spriteBudgetCount number
---@field colorPlateWidth number
---@field colorPlateHeight number 
---@field compressedColorPlate string
---@field processedPixelData string
---@field blurFilterSize number
---@field alphaBias number
---@field mipmapCount number
---@field spriteUsage number
---@field spriteSpacing number
---@field sequencesCount number
---@field sequences bitmapSequence[]
---@field bitmapsCount number
---@field bitmaps table

-- Bitmap structure
local bitmapStructure = {
    type = {type = "word", offset = 0x0},
    format = {type = "word", offset = 0x2},
    usage = {type = "word", offset = 0x4},
    usageFlags = {type = "word", offset = 0x6},
    detailFadeFactor = {type = "dword", offset = 0x8},
    sharpenAmount = {type = "dword", offset = 0xC},
    bumpHeight = {type = "dword", offset = 0x10},
    spriteBudgetSize = {type = "word", offset = 0x14},
    spriteBudgetCount = {type = "word", offset = 0x16},
    colorPlateWidth = {type = "word", offset = 0x18},
    colorPlateHeight = {type = "word", offset = 0x1A},
    -- compressedColorPlate = {offset = 0x1C},
    -- processedPixelData = {offset = 0x30},
    blurFilterSize = {type = "float", offset = 0x44},
    alphaBias = {type = "float", offset = 0x48},
    mipmapCount = {type = "word", offset = 0x4C},
    spriteUsage = {type = "word", offset = 0x4E},
    spriteSpacing = {type = "word", offset = 0x50},
    -- padding1 = {size = 0x2, offset = 0x52},
    sequencesCount = {type = "byte", offset = 0x54},
    sequences = {
        type = "table",
        offset = 0x58,
        jump = 0x40,
        rows = {
            name = {type = "string", offset = 0x0},
            firstBitmapIndex = {type = "word", offset = 0x20},
            bitmapCount = {type = "word", offset = 0x22}
            -- padding = {size = 0x10, offset = 0x24},
            --[[
            sprites = {
                type = "table",
                offset = 0x34,
                jump = 0x20,
                rows = {
                    bitmapIndex = {type = "word", offset = 0x0},
                    --padding1 = {size = 0x2, offset = 0x2},
                    --padding2 = {size = 0x4, offset = 0x4},
                    left = {type = "float", offset = 0x8},
                    right = {type = "float", offset = 0xC},
                    top = {type = "float", offset = 0x10},
                    bottom = {type = "float", offset = 0x14},
                    registrationX = {type = "float", offset = 0x18},
                    registrationY = {type = "float", offset = 0x1C}
                }
            }
            ]]
        }
    },
    bitmapsCount = {type = "byte", offset = 0x60},
    bitmaps = {
        type = "table",
        offset = 0x64,
        jump = 0x30,
        rows = {
            class = {type = "dword", offset = 0x0},
            width = {type = "word", offset = 0x4},
            height = {type = "word", offset = 0x6},
            depth = {type = "word", offset = 0x8},
            type = {type = "word", offset = 0xA},
            format = {type = "word", offset = 0xC},
            flags = {type = "word", offset = 0xE},
            x = {type = "word", offset = 0x10},
            y = {type = "word", offset = 0x12},
            mipmapCount = {type = "word", offset = 0x14},
            -- padding1 = {size = 0x2, offset = 0x16},
            pixelOffset = {type = "dword", offset = 0x18}
            -- padding2 = {size = 0x4, offset = 0x1C},
            -- padding3 = {size = 0x4, offset = 0x20},
            -- padding4 = {size = 0x4, offset= 0x24},
            -- padding5 = {size = 0x8, offset= 0x28}
        }
    }
}

---@class uiWidgetDefinitionChild
---@field widgetTag number Child uiWidgetDefinition reference
---@field name number Child widget name
---@field customControllerIndex number Custom controller index for this child widget
---@field verticalOffset number Offset in Y axis of this child, relative to the parent
---@field horizontalOffset number Offset in X axis of this child, relative to the parent

---@class uiWidgetDefinitionEventHandler
---@field eventType number Type of the event
---@field gameFunction number Game function of this event
---@field widgetTag number uiWidgetDefinition tag id of the event
---@field script string Name of the script function assigned to this event

---@class uiWidgetDefinition
---@field type number Type of widget
---@field controllerIndex number Index of the player controller
---@field name string Name of the widget
---@field boundsY number Top bound of the widget
---@field boundsX number Left bound of the widget
---@field height number Bottom bound of the widget
---@field width number Right bound of the widget
---@field backgroundBitmap number Tag ID of the background bitmap
---@field eventHandlers uiWidgetDefinitionEventHandler[] tag ID list of the child widgets
---@field unicodeStringListTag number Tag ID of the unicodeStringList from this widget
---@field fontTag number Tag ID of the font from this widget
---@field justification number Text justification of the text from this widget
---@field stringListIndex number Text index from the unicodeStringList tag from this widget
---@field textHorizontalOffset number Text offset in X axis from this widget
---@field textVerticalOffset number Text offset in Y axis from this widget
---@field childWidgetsCount number Number of child widgets
---@field childWidgets uiWidgetDefinitionChild[] List of the child widgets

local uiWidgetDefinitionStructure = {
    type = {type = "word", offset = 0x0},
    controllerIndex = {type = "word", offset = 0x2},
    name = {type = "string", offset = 0x4},
    boundsY = {type = "short", offset = 0x24},
    boundsX = {type = "short", offset = 0x26},
    height = {type = "short", offset = 0x28},
    width = {type = "short", offset = 0x2A},
    backgroundBitmap = {type = "word", offset = 0x44},
    eventHandlers = {
        type = "table",
        offset = 0x54,
        jump = 0x48,
        rows = {
            -- TODO Add real flags support, or a subtyping of table instead
            -- flags = {type = "number", offset = 0x0},
            eventType = {type = "word", offset = 0x4},
            gameFunction = {type = "word", offset = 0x6},
            widgetTag = {type = "tagref", offset = 0x8},
            soundEffectTag = {type = "tagref", offset = 0x18},
            script = {type = "string", offset = 0x28}
        }
    },
    unicodeStringListTag = {type = "tagref", offset = 0xEC},
    fontTag = {type = "tagref", offset = 0xFC},
    -- TODO Add color support for hex and rgb values
    -- textColor = {type = "realargbcolor", offset = 0x10C},
    justification = {type = "word", offset = 0x11C},
    stringListIndex = {type = "short", offset = 0x12E},
    textHorizontalOffset = {type = "short", offset = 0x130},
    textVerticalOffset = {type = "short", offset = 0x132},
    ---@deprecated
    eventType = {type = "byte", offset = 0x03F0},
    ---@deprecated
    tagReference = {type = "word", offset = 0x400},
    childWidgetsCount = {type = "dword", offset = 0x03E0},
    ---@deprecated
    childWidgetsList = {type = "list", offset = 0x03E4, elementsType = "dword", jump = 0x50},
    childWidgets = {
        type = "table",
        offset = 0x03E4,
        jump = 0x50,
        rows = {
            widgetTag = {type = "tagref", offset = 0x0},
            name = {type = "string", offset = 0x10},
            -- flags = {type = "integer", offset = 0x30},
            customControllerIndex = {type = "short", offset = 0x34},
            verticalOffset = {type = "short", offset = 0x36},
            horizontalOffset = {type = "short", offset = 0x38}
        }
    }
}

---@class uiWidgetCollection
---@field count number Number of widgets in the collection
---@field tagList table Tag ID list of the widgets

-- uiWidgetCollection structure
local uiWidgetCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {type = "list", offset = 0x4, elementsType = "dword", jump = 0x10}
}

---@class crosshairOverlay
---@field x number
---@field y number
---@field widthScale number
---@field heightScale number
---@field defaultColorA number
---@field defaultColorR number
---@field defaultColorG number
---@field defaultColorB number
---@field sequenceIndex number

---@class crosshair
---@field type number
---@field mapType number
---@field bitmap number
---@field overlays crosshairOverlay[]

---@class weaponHudInterface
---@field childHud number
---@field totalAmmoCutOff number
---@field loadedAmmoCutOff number
---@field heatCutOff number
---@field ageCutOff number
---@field crosshairs crosshair[]

-- Weapon HUD Interface structure
local weaponHudInterfaceStructure = {
    childHud = {type = "dword", offset = 0xC},
    -- //TODO Check if this property should be moved to a nested property type
    usingParentHudFlashingParameters = {type = "bit", offset = "word", bitLevel = 1},
    -- padding1 = {type = "word", offset = 0x12},
    totalAmmoCutOff = {type = "word", offset = 0x14},
    loadedAmmoCutOff = {type = "word", offset = 0x16},
    heatCutOff = {type = "word", offset = 0x18},
    ageCutOff = {type = "word", offset = 0x1A},
    -- padding2 = {size = 0x20, offset = 0x1C},
    -- screenAlignment = {type = "word", },
    -- padding3 = {size = 0x2, offset = 0x3E},
    -- padding4 = {size = 0x20, offset = 0x40},
    crosshairs = {
        type = "table",
        offset = 0x88,
        jump = 0x68,
        rows = {
            type = {type = "word", offset = 0x0},
            mapType = {type = "word", offset = 0x2},
            -- padding1 = {size = 0x2, offset = 0x4},
            -- padding2 = {size = 0x1C, offset = 0x6},
            bitmap = {type = "dword", offset = 0x30},
            overlays = {
                type = "table",
                offset = 0x38,
                jump = 0x6C,
                rows = {
                    x = {type = "word", offset = 0x0},
                    y = {type = "word", offset = 0x2},
                    widthScale = {type = "float", offset = 0x4},
                    heightScale = {type = "float", offset = 0x8},
                    defaultColorB = {type = "byte", offset = 0x24},
                    defaultColorG = {type = "byte", offset = 0x25},
                    defaultColorR = {type = "byte", offset = 0x26},
                    defaultColorA = {type = "byte", offset = 0x27},
                    sequenceIndex = {type = "byte", offset = 0x46}
                }
            }
        }
    }
}

---@class spawnLocation
---@field x number
---@field y number
---@field z number
---@field rotation number
---@field type number
---@field teamIndex number

---@class cutsceneFlag
---@field name string
---@field x number
---@field y number
---@field z number
---@field vX number
---@field vY number

---@class scenario
---@field sceneryPaletteCount number Number of sceneries in the scenery palette
---@field sceneryPaletteList table Tag ID list of scenerys in the scenery palette
---@field spawnLocationCount number Number of spawns in the scenario
---@field spawnLocationList spawnLocation[] List of spawns in the scenario
---@field vehicleLocationCount number Number of vehicles locations in the scenario
---@field vehicleLocationList table List of vehicles locations in the scenario
---@field netgameEquipmentCount number Number of netgame equipments
---@field netgameEquipmentList table List of netgame equipments
---@field netgameFlagsCount number Number of netgame equipments
---@field netgameFlagsList table List of netgame equipments
---@field objectNamesCount number Count of the object names in the scenario
---@field objectNames string[] List of all the object names in the scenario
---@field cutsceneFlagsCount number Count of all the cutscene flags in the scenario
---@field cutsceneFlags cutsceneFlag[] List of all the cutscene flags in the scenario

-- Scenario structure
local scenarioStructure = {
    sceneryPaletteCount = {type = "byte", offset = 0x021C},
    sceneryPaletteList = {type = "list", offset = 0x0220, elementsType = "dword", jump = 0x30},
    spawnLocationCount = {type = "byte", offset = 0x354},
    spawnLocationList = {
        type = "table",
        offset = 0x358,
        jump = 0x34,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {type = "float", offset = 0xC},
            teamIndex = {type = "byte", offset = 0x10},
            bspIndex = {type = "short", offset = 0x12},
            type = {type = "byte", offset = 0x14}
        }
    },
    vehicleLocationCount = {type = "byte", offset = 0x240},
    vehicleLocationList = {
        type = "table",
        offset = 0x244,
        jump = 0x78,
        rows = {
            type = {type = "word", offset = 0x0},
            nameIndex = {type = "word", offset = 0x2},
            x = {type = "float", offset = 0x8},
            y = {type = "float", offset = 0xC},
            z = {type = "float", offset = 0x10},
            yaw = {type = "float", offset = 0x14},
            pitch = {type = "float", offset = 0x18},
            roll = {type = "float", offset = 0x1C}
        }
    },
    netgameFlagsCount = {type = "byte", offset = 0x378},
    netgameFlagsList = {
        type = "table",
        offset = 0x37C,
        jump = 0x94,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {type = "float", offset = 0xC},
            type = {type = "byte", offset = 0x10},
            teamIndex = {type = "word", offset = 0x12}
        }
    },
    netgameEquipmentCount = {type = "byte", offset = 0x384},
    netgameEquipmentList = {
        type = "table",
        offset = 0x388,
        jump = 0x90,
        rows = {
            levitate = {type = "bit", offset = 0x0, bitLevel = 0},
            type1 = {type = "word", offset = 0x4},
            type2 = {type = "word", offset = 0x6},
            type3 = {type = "word", offset = 0x8},
            type4 = {type = "word", offset = 0xA},
            teamIndex = {type = "byte", offset = 0xC},
            spawnTime = {type = "word", offset = 0xE},
            x = {type = "float", offset = 0x40},
            y = {type = "float", offset = 0x44},
            z = {type = "float", offset = 0x48},
            facing = {type = "float", offset = 0x4C},
            itemCollection = {type = "dword", offset = 0x5C}
        }
    },
    objectNamesCount = {type = "dword", offset = 0x204},
    objectNames = {
        type = "list",
        offset = 0x208,
        elementsType = "string",
        jump = 36,
        noOffset = true
    },
    cutsceneFlagsCount = {type = "dword", offset = 0x4E4},
    cutsceneFlags = {
        type = "table",
        offset = 0x4E8,
        jump = 92,
        rows = {
            name = {type = "string", offset = 0x4},
            x = {type = "float", offset = 0x24},
            y = {type = "float", offset = 0x28},
            z = {type = "float", offset = 0x2C},
            vX = {type = "float", offset = 0x30},
            vY = {type = "float", offset = 0x34}
        }
    }
}

---@class scenery
---@field model number
---@field modifierShader number

-- Scenery structure
local sceneryStructure = {
    model = {type = "word", offset = 0x28 + 0xC},
    modifierShader = {type = "word", offset = 0x90 + 0xC}
}

---@class collisionGeometry
---@field vertexCount number Number of vertex in the collision geometry
---@field vertexList table List of vertex in the collision geometry

-- Collision Model structure
local collisionGeometryStructure = {
    vertexCount = {type = "byte", offset = 0x408},
    vertexList = {
        type = "table",
        offset = 0x40C,
        jump = 0x10,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8}
        }
    }
}

---@class animationClass
---@field name string Name of the animation
---@field type number Type of the animation
---@field frameCount number Frame count of the animation
---@field nextAnimation number Next animation id of the animation
---@field sound number Sound id of the animation

---@class modelAnimations
---@field fpAnimationCount number Number of first-person animations
---@field fpAnimationList number[] List of first-person animations
---@field animationCount number Number of animations of the model
---@field animationList animationClass[] List of animations of the model

-- Model Animation structure
local modelAnimationsStructure = {
    fpAnimationCount = {type = "byte", offset = 0x90},
    fpAnimationList = {
        type = "list",
        offset = 0x94,
        noOffset = true,
        elementsType = "byte",
        jump = 0x2
    },
    animationCount = {type = "byte", offset = 0x74},
    animationList = {
        type = "table",
        offset = 0x78,
        jump = 0xB4,
        rows = {
            name = {type = "string", offset = 0x0},
            type = {type = "word", offset = 0x20},
            frameCount = {type = "byte", offset = 0x22},
            nextAnimation = {type = "byte", offset = 0x38},
            sound = {type = "byte", offset = 0x3C}
        }
    }
}

---@class weapon : blamObject
---@field pressedReloadKey boolean Is weapon trying to reload
---@field isWeaponPunching boolean Is weapon playing melee or grenade animation

local weaponStructure = extendStructure(objectStructure, {
    pressedReloadKey = {type = "bit", offset = 0x230, bitLevel = 3},
    isWeaponPunching = {type = "bit", offset = 0x230, bitLevel = 4}
})

---@class weaponTag
---@field model number Tag ID of the weapon model

-- Weapon structure
local weaponTagStructure = {model = {type = "dword", offset = 0x34}}

-- @class modelMarkers
-- @field name string
-- @field nodeIndex number
-- TODO Add rotation fields, check Guerilla tag
-- @field x number
-- @field y number
-- @field z number

---@class modelRegion
---@field permutationCount number
-- @field markersList modelMarkers[]

---@class modelNode
---@field x number
---@field y number
---@field z number

---@class gbxModel
---@field nodeCount number Number of nodes
---@field nodeList modelNode[] List of the model nodes
---@field regionCount number Number of regions
---@field regionList modelRegion[] List of regions

-- Model structure
local modelStructure = {
    nodeCount = {type = "dword", offset = 0xB8},
    nodeList = {
        type = "table",
        offset = 0xBC,
        jump = 0x9C,
        rows = {
            x = {type = "float", offset = 0x28},
            y = {type = "float", offset = 0x2C},
            z = {type = "float", offset = 0x30}
        }
    },
    regionCount = {type = "dword", offset = 0xC4},
    regionList = {
        type = "table",
        offset = 0xC8,
        jump = 76,
        rows = {
            permutationCount = {type = "dword", offset = 0x40}
            --[[permutationsList = {
                type = "table",
                offset = 0x16C,
                jump = 0x0,
                rows = {
                    name = {type = "string", offset = 0x0},
                    markersList = {
                        type = "table",
                        offset = 0x4C,
                        jump = 0x0,
                        rows = {
                            name = {type = "string", offset = 0x0},
                            nodeIndex = {type = "word", offset = 0x20}
                        }
                    }
                }
            }]]
        }
    }
}

---@class projectile : blamObject
---@field action number Enumeration of denotation action
---@field attachedToObjectId number Id of the attached object
---@field armingTimer number PENDING
---@field xVel number Velocity in x direction
---@field yVel number Velocity in y direction
---@field zVel number Velocity in z direction
---@field yaw number Rotation in yaw direction
---@field pitch number Rotation in pitch direction
---@field roll number Rotation in roll direction

-- Projectile structure
local projectileStructure = extendStructure(objectStructure, {
    action = {type = "word", offset = 0x230},
    attachedToObjectId = {type = "dword", offset = 0x11C},
    armingTimer = {type = "float", offset = 0x248},
    --[[xVel = {type = "float", offset = 0x254},
    yVel = {type = "float", offset = 0x258},
    zVel = {type = "float", offset = 0x25C},]]
    pitch = {type = "float", offset = 0x264},
    yaw = {type = "float", offset = 0x268},
    roll = {type = "float", offset = 0x26C}
})

---@class player
---@field id number Get playerId of this player
---@field host number Check if player is host, 0 when host, null when not
---@field name string Name of this player
---@field team number Team color of this player, 0 when red, 1 when on blue team
---@field objectId number Return the objectId associated to this player
---@field color number Color of the player, only works on "Free for All" gametypes
---@field index number Local index of this player 0-15
---@field speed number Current speed of this player
---@field ping number Ping amount from server of this player in milliseconds
---@field kills number Kills quantity done by this player
---@field assists number Assists count of this player
---@field betraysAndSuicides number Betrays plus suicides count of this player
---@field deaths number Deaths count of this player
---@field suicides number Suicides count of this player

local playerStructure = {
    id = {type = "word", offset = 0x0},
    host = {type = "word", offset = 0x2},
    name = {type = "ustring", forced = true, offset = 0x4},
    team = {type = "byte", offset = 0x20},
    objectId = {type = "dword", offset = 0x34},
    color = {type = "word", offset = 0x60},
    index = {type = "byte", offset = 0x67},
    speed = {type = "float", offset = 0x6C},
    ping = {type = "dword", offset = 0xDC},
    kills = {type = "word", offset = 0x9C},
    assists = {type = "word", offset = 0XA4},
    betraysAndSuicides = {type = "word", offset = 0xAC},
    deaths = {type = "word", offset = 0xAE},
    suicides = {type = "word", offset = 0XB0}
}

---@class firstPersonInterface
---@field firstPersonHands number

---@class multiplayerInformation
---@field flag number Tag ID of the flag object used for multiplayer games
---@field unit number Tag ID of the unit object used for multiplayer games

---@class globalsTag
---@field multiplayerInformation multiplayerInformation[]
---@field firstPersonInterface firstPersonInterface[]

local globalsTagStructure = {
    multiplayerInformation = {
        type = "table",
        jump = 0x0,
        offset = 0x168,
        rows = {flag = {type = "dword", offset = 0xC}, unit = {type = "dword", offset = 0x1C}}
    },
    firstPersonInterface = {
        type = "table",
        jump = 0x0,
        offset = 0x180,
        rows = {firstPersonHands = {type = "dword", offset = 0xC}}
    }
}

---@class firstPerson
---@field weaponObjectId number Weapon Id from the first person view

local firstPersonStructure = {weaponObjectId = {type = "dword", offset = 0x10}}

---@class bipedTag
---@field disableCollision number Disable collision of this biped tag

local bipedTagStructure = {disableCollision = {type = "bit", offset = 0x2F4, bitLevel = 5}}

---@class deviceMachine : blamObject
---@field powerGroupIndex number Power index from the device groups table
---@field power number Position amount of this device machine
---@field powerChange number Power change of this device machine
---@field positonGroupIndex number Power index from the device groups table
---@field position number Position amount of this device machine
---@field positionChange number Position change of this device machine
local deviceMachineStructure = extendStructure(objectStructure, {
    powerGroupIndex = {type = "word", offset = 0x1F8},
    power = {type = "float", offset = 0x1FC},
    powerChange = {type = "float", offset = 0x200},
    positonGroupIndex = {type = "word", offset = 0x204},
    position = {type = "float", offset = 0x208},
    positionChange = {type = "float", offset = 0x20C}
})

---@class hudGlobals
---@field anchor number
---@field x number
---@field y number
---@field width number
---@field height number
---@field upTime number
---@field fadeTime number
---@field iconColorA number
---@field iconColorR number
---@field iconColorG number
---@field iconColorB number
---@field textSpacing number

local hudGlobalsStructure = {
    anchor = {type = "word", offset = 0x0},
    x = {type = "word", offset = 0x24},
    y = {type = "word", offset = 0x26},
    width = {type = "float", offset = 0x28},
    height = {type = "float", offset = 0x2C},
    upTime = {type = "float", offset = 0x68},
    fadeTime = {type = "float", offset = 0x6C},
    iconColorA = {type = "float", offset = 0x70},
    iconColorR = {type = "float", offset = 0x74},
    iconColorG = {type = "float", offset = 0x78},
    iconColorB = {type = "float", offset = 0x7C},
    textColorA = {type = "float", offset = 0x80},
    textColorR = {type = "float", offset = 0x84},
    textColorG = {type = "float", offset = 0x88},
    textColorB = {type = "float", offset = 0x8C},
    textSpacing = {type = "float", offset = 0x90}
}

------------------------------------------------------------------------------
-- LuaBlam globals
------------------------------------------------------------------------------

-- Provide with public blam! data tables
blam.addressList = addressList
blam.tagClasses = tagClasses
blam.objectClasses = objectClasses
blam.joystickInputs = joystickInputs
blam.dPadValues = dPadValues
blam.cameraTypes = cameraTypes
blam.consoleColors = consoleColors
blam.netgameFlagClasses = netgameFlagClasses
blam.gameTypeClasses = gameTypeClasses
blam.multiplayerTeamClasses = multiplayerTeamClasses
blam.unitTeamClasses = unitTeamClasses

---@class tagDataHeader
---@field array any
---@field scenario string
---@field count number

---@type tagDataHeader
blam.tagDataHeader = createObject(addressList.tagDataHeader, tagDataHeaderStructure)

------------------------------------------------------------------------------
-- LuaBlam API
------------------------------------------------------------------------------

-- Add utilities to library
blam.dumpObject = dumpObject
blam.consoleOutput = consoleOutput

--- Get if a value equals a null value in game terms
---@return boolean
function blam.isNull(value)
    if (value == 0xFF or value == 0xFFFF or value == 0xFFFFFFFF or value == nil) then
        return true
    end
    return false
end

---Return if game instance is host
---@return boolean
function blam.isGameHost()
    return server_type == "local"
end

---Return if game instance is single player
---@return boolean
function blam.isGameSinglePlayer()
    return server_type == "none"
end

---Return if the game instance is running on a dedicated server or connected as a "network client"
---@return boolean
function blam.isGameDedicated()
    return server_type == "dedicated"
end

---Return if the game instance is a SAPP server
---@return boolean
function blam.isGameSAPP()
    return server_type == "sapp" or api_version
end

---Get the current game camera type
---@return number?
function blam.getCameraType()
    local camera = read_word(addressList.cameraType)
    if (camera) then
        if (camera == 22192) then
            return cameraTypes.scripted
        elseif (camera == 30400) then
            return cameraTypes.firstPerson
        elseif (camera == 30704) then
            return cameraTypes.devcam
            -- FIXME Validate this value, it seems to be wrong!
        elseif (camera == 21952) then
            return cameraTypes.thirdPerson
        elseif (camera == 23776) then
            return cameraTypes.deadCamera
        end
    end
    return nil
end

--- Get input from joystick assigned in the game
---@param joystickOffset number Offset input from the joystick data, use blam.joystickInputs
---@return boolean | number Value of the joystick input
function blam.getJoystickInput(joystickOffset)
    -- Based on aLTis controller method
    -- TODO Check if it is better to return an entire table with all input values 
    joystickOffset = joystickOffset or 0
    -- Nothing is pressed by default
    ---@type boolean | number
    local inputValue = false
    -- Look for every input from every joystick available
    for controllerId = 0, 3 do
        local inputAddress = addressList.joystickInput + controllerId * 0xA0
        if (joystickOffset >= 30 and joystickOffset <= 38) then
            -- Sticks
            inputValue = inputValue + read_long(inputAddress + joystickOffset)
        elseif (joystickOffset > 96) then
            -- D-pad related
            local tempValue = read_word(inputAddress + 96)
            if (tempValue == joystickOffset - 100) then
                inputValue = true
            end
        else
            inputValue = inputValue + read_byte(inputAddress + joystickOffset)
        end
    end
    return inputValue
end

--- Create a tag object from a given address, this object can't write data to game memory
---@param address integer
---@return tag?
function blam.tag(address)
    if (address and address ~= 0) then
        -- Generate a new tag object from class
        local tag = createObject(address, tagHeaderStructure)

        -- Get all the tag info
        local tagInfo = dumpObject(tag)

        -- Set up values
        tagInfo.address = address
        tagInfo.path = read_string(tagInfo.path)
        tagInfo.class = tagClassFromInt(tagInfo.class --[[@as number]])

        return tagInfo
    end
    return nil
end

--- Return a tag object given tagPath and tagClass or just tagId
---@param tagIdOrTagPath string | number
---@param tagClass? string
---@return tag?
function blam.getTag(tagIdOrTagPath, tagClass, ...)
    local tagId
    local tagPath

    -- Get arguments from table
    if (isNumber(tagIdOrTagPath)) then
        tagId = tagIdOrTagPath
    elseif (isString(tagIdOrTagPath)) then
        tagPath = tagIdOrTagPath
    elseif (not tagIdOrTagPath) then
        return nil
    end

    if (...) then
        consoleOutput(debug.traceback("Wrong number of arguments on get tag function", 2),
                      consoleColors.error)
    end

    local tagAddress

    -- Get tag address
    if (tagId) then
        if (tagId < 0xFFFF) then
            -- Calculate tag id
            tagId = read_dword(blam.tagDataHeader.array + (tagId * 0x20 + 0xC))
        end
        tagAddress = get_tag(tagId)
    elseif (tagClass and tagPath) then
        tagAddress = get_tag(tagClass, tagPath --[[@as string]] )
    end

    if tagAddress then
        return blam.tag(tagAddress)
    end
end

--- Create a player object given player entry table address
---@return player?
function blam.player(address)
    if (isValid(address)) then
        return createObject(address, playerStructure)
    end
    return nil
end

--- Create a blamObject given address
---@param address number
---@return blamObject?
function blam.object(address)
    if (isValid(address)) then
        return createObject(address, objectStructure)
    end
    return nil
end

--- Create a Projectile object given address
---@param address number
---@return projectile?
function blam.projectile(address)
    if (isValid(address)) then
        return createObject(address, projectileStructure)
    end
    return nil
end

--- Create a Biped object from a given address
---@param address number
---@return biped?
function blam.biped(address)
    if (isValid(address)) then
        return createObject(address, bipedStructure)
    end
    return nil
end

--- Create a biped tag from a tag path or id
---@param tag string | number
---@return bipedTag?
function blam.bipedTag(tag)
    if (isValid(tag)) then
        local bipedTag = blam.getTag(tag, tagClasses.biped)
        if (bipedTag) then
            return createObject(bipedTag.data, bipedTagStructure)
        end
    end
    return nil
end

--- Create a Unicode String List object from a tag path or id
---@param tag string | number
---@return unicodeStringList?
function blam.unicodeStringList(tag)
    if (isValid(tag)) then
        local unicodeStringListTag = blam.getTag(tag, tagClasses.unicodeStringList)
        if (unicodeStringListTag) then
            return createObject(unicodeStringListTag.data, unicodeStringListStructure)
        end
    end
    return nil
end

--- Create a bitmap object from a tag path or id
---@param tag string | number
---@return bitmap?
function blam.bitmap(tag)
    if (isValid(tag)) then
        local bitmapTag = blam.getTag(tag, tagClasses.bitmap)
        if (bitmapTag) then
            return createObject(bitmapTag.data, bitmapStructure)
        end
    end
end

--- Create a UI Widget Definition object from a tag path or id
---@param tag string | number
---@return uiWidgetDefinition?
function blam.uiWidgetDefinition(tag)
    if (isValid(tag)) then
        local uiWidgetDefinitionTag = blam.getTag(tag, tagClasses.uiWidgetDefinition)
        if (uiWidgetDefinitionTag) then
            return createObject(uiWidgetDefinitionTag.data, uiWidgetDefinitionStructure)
        end
    end
    return nil
end

--- Create a UI Widget Collection object from a tag path or id
---@param tag string | number
---@return uiWidgetCollection?
function blam.uiWidgetCollection(tag)
    if (isValid(tag)) then
        local uiWidgetCollectionTag = blam.getTag(tag, tagClasses.uiWidgetCollection)
        if (uiWidgetCollectionTag) then
            return createObject(uiWidgetCollectionTag.data, uiWidgetCollectionStructure)
        end
    end
    return nil
end

--- Create a Tag Collection object from a tag path or id
---@param tag string | number
---@return tagCollection?
function blam.tagCollection(tag)
    if (isValid(tag)) then
        local tagCollectionTag = blam.getTag(tag, tagClasses.tagCollection)
        if (tagCollectionTag) then
            return createObject(tagCollectionTag.data, tagCollectionStructure)
        end
    end
    return nil
end

--- Create a Weapon HUD Interface object from a tag path or id
---@param tag string | number
---@return weaponHudInterface?
function blam.weaponHudInterface(tag)
    if (isValid(tag)) then
        local weaponHudInterfaceTag = blam.getTag(tag, tagClasses.weaponHudInterface)
        if (weaponHudInterfaceTag) then
            return createObject(weaponHudInterfaceTag.data, weaponHudInterfaceStructure)
        end
    end
    return nil
end

--- Create a Scenario object from a tag path or id
---@param tag? string | number
---@return scenario?
function blam.scenario(tag)
    local scenarioTag = blam.getTag(tag or 0, tagClasses.scenario)
    if (scenarioTag) then
        return createObject(scenarioTag.data, scenarioStructure)
    end
end

--- Create a Scenery object from a tag path or id
---@param tag string | number
---@return scenery?
function blam.scenery(tag)
    if (isValid(tag)) then
        local sceneryTag = blam.getTag(tag, tagClasses.scenery)
        if (sceneryTag) then
            return createObject(sceneryTag.data, sceneryStructure)
        end
    end
    return nil
end

--- Create a Collision Geometry object from a tag path or id
---@param tag string | number
---@return collisionGeometry?
function blam.collisionGeometry(tag)
    if (isValid(tag)) then
        local collisionGeometryTag = blam.getTag(tag, tagClasses.collisionGeometry)
        if (collisionGeometryTag) then
            return createObject(collisionGeometryTag.data, collisionGeometryStructure)
        end
    end
    return nil
end

--- Create a Model Animations object from a tag path or id
---@param tag string | number
---@return modelAnimations?
function blam.modelAnimations(tag)
    if (isValid(tag)) then
        local modelAnimationsTag = blam.getTag(tag, tagClasses.modelAnimations)
        if (modelAnimationsTag) then
            return createObject(modelAnimationsTag.data, modelAnimationsStructure)
        end
    end
    return nil
end

--- Create a Weapon object from the given object address
---@param address number
---@return weapon?
function blam.weapon(address)
    if (isValid(address)) then
        return createObject(address, weaponStructure)
    end
    return nil
end

--- Create a Weapon tag object from a tag path or id
---@param tag string | number
---@return weaponTag?
function blam.weaponTag(tag)
    if (isValid(tag)) then
        local weaponTag = blam.getTag(tag, tagClasses.weapon)
        if (weaponTag) then
            return createObject(weaponTag.data, weaponTagStructure)
        end
    end
    return nil
end

--- Create a model (gbxmodel) object from a tag path or id
---@param tag string | number
---@return gbxModel?
function blam.model(tag)
    if (isValid(tag)) then
        local modelTag = blam.getTag(tag, tagClasses.model)
        if (modelTag) then
            return createObject(modelTag.data, modelStructure)
        end
    end
    return nil
end
-- Alias
blam.gbxmodel = blam.model

--- Create a Globals tag object from a tag path or id, default globals path by default
---@param tag? string | number
---@return globalsTag?
function blam.globalsTag(tag)
    local tag = tag or "globals\\globals"
    if (isValid(tag)) then
        local globalsTag = blam.getTag(tag, tagClasses.globals)
        if (globalsTag) then
            return createObject(globalsTag.data, globalsTagStructure)
        end
    end
    return nil
end

--- Create a First person object from a given address, game known address by default
---@param address? number
---@return firstPerson
function blam.firstPerson(address)
    return createObject(address or addressList.firstPerson, firstPersonStructure)
end

--- Create a Device Machine object from a given address
---@param address number
---@return deviceMachine?
function blam.deviceMachine(address)
    if (isValid(address)) then
        return createObject(address, deviceMachineStructure)
    end
    return nil
end

--- Create a HUD Globals tag object from a given address
---@param tag string | number
---@return hudGlobals?
function blam.hudGlobals(tag)
    if (isValid(tag)) then
        local hudGlobals = blam.getTag(tag, tagClasses.hudGlobals)
        if (hudGlobals) then
            return createObject(hudGlobals.data, hudGlobalsStructure)
        end
    end
    return nil
end

--- Return a blam object given object index or id.
--- Also returns objectId when given an object index.
---@param idOrIndex number
---@return blamObject?, number?
function blam.getObject(idOrIndex)
    local objectId
    local objectAddress

    -- Get object address
    if (idOrIndex) then
        -- Get object ID
        if (idOrIndex < 0xFFFF) then
            local index = idOrIndex

            -- Get objects table
            local table = createObject(addressList.objectTable, dataTableStructure)
            if (index > table.capacity) then
                return nil
            end

            -- Calculate object ID (this may be invalid, be careful)
            objectId =
                (read_word(table.firstElementAddress + index * table.elementSize) * 0x10000) + index
        else
            objectId = idOrIndex
        end

        objectAddress = get_object(objectId)

        if objectAddress then
            return blam.object(objectAddress), objectId
        end
    end
    return nil
end

--- Return an element from the device machines table
---@param index number
---@return number?
function blam.getDeviceGroup(index)
    -- Get object address
    if (index) then
        -- Get objects table
        local table = createObject(read_dword(addressList.deviceGroupsTable),
                                   deviceGroupsTableStructure)
        -- Calculate object ID (this may be invalid, be careful)
        local itemOffset = table.elementSize * index
        local item = read_float(table.firstElementAddress + itemOffset + 0x4)
        return item
    end
    return nil
end

---@class blamRequest
---@field requestString string
---@field timeout number
---@field callback function<boolean, string>
---@field sentAt number

---@type table<number, blamRequest>
local requestQueue = {}
local requestId = -1
local requestPathMaxLength = 60
---Send a server request to current server trough rcon
---@param method '"GET"' | '"SEND"'
---@param path string Path or name of the resource we want to get
---@param timeout number Time this request will wait for a response, 120ms by default
---@param callback function<boolean, string> Callback function to call when this response returns
---@param retry boolean Retry this request if timeout reaches it's limit
---@param params table<string, any> Optional parameters to send in the request, careful, this will create two requests, one for the resource and another one for the parameters
---@return boolean success
function blam.request(method, path, timeout, callback, retry, params)
    if (server_type ~= "dedicated") then
        console_out("Warning, requests only work while connected to a dedicated server.")
    end
    if (params) then
        console_out("Warning, request params are not supported yet.")
    end
    if (path and path:len() <= requestPathMaxLength) then
        if (method == "GET") then
            requestId = requestId + 1
            local rconRequest = ("rcon blam ?%s?%s"):format(requestId, path)
            requestQueue[requestId] = {
                requestString = rconRequest,
                timeout = timeout or 120,
                callback = callback
            }
            console_out(rconRequest)
            -- execute_script(request)
            return true
        end
    end
    error("Error, url can not contain more than " .. requestPathMaxLength .. " chars.")
    return false
end

---Evaluate if rcon event is a request
---@param password string
---@param message string
---@return boolean
function blam.isRequest(password, message)
    if password == "blam" then
        return true
    end
    if message:sub(1, 1) == "?" then
        return true
    end
    return false
end

---Evaluate rcon event and handle it as a request
---@param message string
---@param password string
---@param playerIndex number
---@return boolean | nil
function blam.handleRequest(message, password, playerIndex)
    if password == "blam" then
        if message:sub(1, 1) == "?" then
            return false
        end
    end
    -- Pass request to the server
    return nil
end

--- Find the path, index and id of a tag given partial tag path and tag type
---@param partialTagPath string
---@param searchTagType string
---@return tag? tag
function blam.findTag(partialTagPath, searchTagType)
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialTagPath, 1, true) and tag.class == searchTagType) then
            return tag
        end
    end
    return nil
end

--- Find the path, index and id of a list of tags given partial tag path and tag type
---@param partialTagPath string
---@param searchTagType string
---@return tag[] tag
function blam.findTagsList(partialTagPath, searchTagType)
    local tagsList
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialTagPath, 1, true) and tag.class == searchTagType) then
            if (not tagsList) then
                tagsList = {}
            end
            tagsList[#tagsList + 1] = tag
        end
    end
    return tagsList
end

local fmod = math.fmod
function blam.getIndexById(id)
    if id then
        local index = fmod(id, 0x10000)
        return index
    end
    return nil
end

return blam

end,

["requestscurl"] = function()
--------------------
-- Module: 'requestscurl'
--------------------
local json = require "json"
local requests = {}

requests.headers = {}
requests.timeout = 300

---@class httpResponse<T> : { url: string, code: number, text: string, headers: table<string, string>, json : fun(): T }

local function paramsToBodyString(params)
    local body = ""
    for k, v in pairs(params) do
        body = body .. k .. "=" .. v .. "&"
    end
    -- Remove last "&"
    body = body:sub(1, #body - 1)
    return body
end

-- Probably an alternative due to performance
-- https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local function urlencode(str)
    -- str = string.gsub(str, "([^0-9a-zA-Z !'()*._~-])", -- locale independent
    str = string.gsub(str, "([ '])", -- locale independent
    function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
    return str
end

---Perform a GET request
---@param url string
---@return httpResponse?
function requests.get(url)
    local curl = require "lcurl.safe"

    local requestHeaders = {}
    for k, v in pairs(requests.headers) do
        requestHeaders[#requestHeaders + 1] = v
    end
    requestHeaders[#requestHeaders + 1] = "Content-Type: application/x-www-form-urlencoded"

    local responseBody = {}
    local responseHeaders = {}

    local request = curl.easy {
        url = urlencode(url),
        timeout = requests.timeout,
        httpheader = requests.headers,
        writefunction = function(input)
            table.insert(responseBody, input)
        end,
        headerfunction = function(header)
            local key = header:match("^([^:]+):")
            if key then
                responseHeaders[key] = header:sub(#key + 2, #header - 2)
            end
        end
    }:perform()

    if request then
        local url = request:getinfo_effective_url()
        local code = request:getinfo_response_code()
        local responseBody = table.concat(responseBody)
        request:close()
        return {
            url = url,
            code = code,
            text = responseBody,
            headers = responseHeaders,
            json = function()
                return json.decode(responseBody)
            end
        }
    end
end

---Perform a POST request
---@param url string
---@param params? table<string, string | number>
---@return httpResponse?
function requests.postform(url, params)
    -- TODO Implement different types of POST
    local curl = require "lcurl.safe"

    local requestHeaders = {}
    for k, v in pairs(requests.headers) do
        requestHeaders[#requestHeaders + 1] = v
    end
    requestHeaders[#requestHeaders + 1] = "Content-Type: application/x-www-form-urlencoded"

    local responseBody = {}
    local responseHeaders = {}

    local request = curl.easy {
        url = urlencode(url),
        timeout = requests.timeout,
        httpheader = headers,
        writefunction = function(input)
            table.insert(responseBody, input)
        end,
        headerfunction = function(header)
            local key = header:match("^([^:]+):")
            if key then
                responseHeaders[key] = header:sub(#key + 2, #header - 2)
            end
        end,
        postfields = paramsToBodyString(params)
    }:perform()
    if request then
        local url = request:getinfo_effective_url()
        local code = request:getinfo_response_code()
        local responseBody = table.concat(responseBody)
        request:close()
        return {
            url = url,
            code = code,
            text = responseBody,
            headers = responseHeaders,
            json = function()
                return json.decode(responseBody)
            end
        }
    end
end

---Perform a PATCH request
---@param url string
---@param params? table<string, string | number>
---@return httpResponse?
function requests.patch(url, params)
    local curl = require "lcurl.safe"
    
    local requestHeaders = {}
    for k, v in pairs(requests.headers) do
        requestHeaders[#requestHeaders + 1] = v
    end
    requestHeaders[#requestHeaders + 1] = "Content-Type: application/json"

    local responseBody = {}
    local responseHeaders = {}

    local request = curl.easy {
        url = urlencode(url),
        timeout = requests.timeout,
        httpheader = requestHeaders,
        writefunction = function(input)
            table.insert(responseBody, input)
        end,
        headerfunction = function(header)
            local key = header:match("^([^:]+):")
            if key then
                responseHeaders[key] = header:sub(#key + 2, #header - 2)
            end
        end,
        postfields = json.encode(params),
        customrequest = "PATCH"
    }:perform()

    if request then
        local url = request:getinfo_effective_url()
        local code = request:getinfo_response_code()
        local responseBody = table.concat(responseBody)
        request:close()
        return {
            url = url,
            code = code,
            text = responseBody,
            headers = responseHeaders,
            json = function()
                return json.decode(responseBody)
            end
        }
    end
end

return requests

end,

["redux"] = function()
--------------------
-- Module: 'redux'
--------------------
local actionTypes = {INIT = "@@lua-redux/INIT"}

local function inverse(table)
    local newTable = {}
    for k, v in pairs(table) do
        newTable[v] = k
    end
    return newTable
end

---@class reduxAction
---@field type string
---@field payload any

---Create a redux store for the application state
---@param reducer fun(action:string, payload:any)
---@param preloadedState any
local function createStore(reducer, preloadedState)
    local store = {reducer = reducer, state = preloadedState, subscribers = {}}

    ---Subscribe a function callback to this store
    ---@param callback function
    ---@return function unsubscribe Unsubscribe function for this store
    function store:subscribe(callback)
        local i = table.insert(self.subscribers, callback)
        return function()
            table.remove(self.subscribers, inverse(self.subscribers)[callback])
        end
    end

    ---Dispatch an action event to the store
    ---@param action reduxAction
    function store:dispatch(action)
        self.state = self.reducer(self.state, action)
        for k, v in pairs(self.subscribers) do
            v()
        end
    end

    ---Return the state of the store
    ---@return any
    function store:getState()
        return self.state
    end

    ---Replace the reducer of this store with a given one
    ---@return any
    function store:replaceReducer(reducer)
        self.reducer = reducer
        self:dispatch({type = actionTypes.INIT})
    end

    store:dispatch({type = actionTypes.INIT})

    return store
end

return {actionTypes = actionTypes, createStore = createStore}

end,

["insecticide"] = function()
--------------------
-- Module: 'insecticide'
--------------------
local blam = require "blam"
inspect = {
    _VERSION = "inspect.lua 3.1.0",
    _URL = "http://github.com/kikito/inspect.lua",
    _DESCRIPTION = "human-readable representations of tables",
    _LICENSE = [[
      MIT LICENSE
  
      Copyright (c) 2013 Enrique García Cota
  
      Permission is hereby granted, free of charge, to any person obtaining a
      copy of this software and associated documentation files (the
      "Software"), to deal in the Software without restriction, including
      without limitation the rights to use, copy, modify, merge, publish,
      distribute, sublicense, and/or sell copies of the Software, and to
      permit persons to whom the Software is furnished to do so, subject to
      the following conditions:
  
      The above copyright notice and this permission notice shall be included
      in all copies or substantial portions of the Software.
  
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
      OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

local tostring = tostring

inspect.KEY = setmetatable({}, {
    __tostring = function()
        return "inspect.KEY"
    end
})
inspect.METATABLE = setmetatable({}, {
    __tostring = function()
        return "inspect.METATABLE"
    end
})

local function rawpairs(t)
    return next, t, nil
end

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smartQuote(str)
    if str:match("\"") and not str:match("'") then
        return "'" .. str .. "'"
    end
    return "\"" .. str:gsub("\"", "\\\"") .. "\""
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local shortControlCharEscapes = {
    ["\a"] = "\\a",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\v"] = "\\v"
}
local longControlCharEscapes = {} -- \a => nil, \0 => \000, 31 => \031
for i = 0, 31 do
    local ch = string.char(i)
    if not shortControlCharEscapes[ch] then
        shortControlCharEscapes[ch] = "\\" .. i
        longControlCharEscapes[ch] = string.format("\\%03d", i)
    end
end

local function escape(str)
    return (str:gsub("\\", "\\\\"):gsub("(%c)%f[0-9]", longControlCharEscapes):gsub("%c",
                                                                                    shortControlCharEscapes))
end

local function isIdentifier(str)
    return type(str) == "string" and str:match("^[_%a][_%a%d]*$")
end

local function isSequenceKey(k, sequenceLength)
    return type(k) == "number" and 1 <= k and k <= sequenceLength and math.floor(k) == k
end

local defaultTypeOrders = {
    ["number"] = 1,
    ["boolean"] = 2,
    ["string"] = 3,
    ["table"] = 4,
    ["function"] = 5,
    ["userdata"] = 6,
    ["thread"] = 7
}

local function sortKeys(a, b)
    local ta, tb = type(a), type(b)

    -- strings and numbers are sorted numerically/alphabetically
    if ta == tb and (ta == "string" or ta == "number") then
        return a < b
    end

    local dta, dtb = defaultTypeOrders[ta], defaultTypeOrders[tb]
    -- Two default types are compared according to the defaultTypeOrders table
    if dta and dtb then
        return defaultTypeOrders[ta] < defaultTypeOrders[tb]
    elseif dta then
        return true -- default types before custom ones
    elseif dtb then
        return false -- custom types after default ones
    end

    -- custom types are sorted out alphabetically
    return ta < tb
end

-- For implementation reasons, the behavior of rawlen & # is "undefined" when
-- tables aren't pure sequences. So we implement our own # operator.
local function getSequenceLength(t)
    local len = 1
    local v = rawget(t, len)
    while v ~= nil do
        len = len + 1
        v = rawget(t, len)
    end
    return len - 1
end

local function getNonSequentialKeys(t)
    local keys, keysLength = {}, 0
    local sequenceLength = getSequenceLength(t)
    for k, _ in rawpairs(t) do
        if not isSequenceKey(k, sequenceLength) then
            keysLength = keysLength + 1
            keys[keysLength] = k
        end
    end
    table.sort(keys, sortKeys)
    return keys, keysLength, sequenceLength
end

local function countTableAppearances(t, tableAppearances)
    tableAppearances = tableAppearances or {}

    if type(t) == "table" then
        if not tableAppearances[t] then
            tableAppearances[t] = 1
            for k, v in rawpairs(t) do
                countTableAppearances(k, tableAppearances)
                countTableAppearances(v, tableAppearances)
            end
            countTableAppearances(getmetatable(t), tableAppearances)
        else
            tableAppearances[t] = tableAppearances[t] + 1
        end
    end

    return tableAppearances
end

local copySequence = function(s)
    local copy, len = {}, #s
    for i = 1, len do
        copy[i] = s[i]
    end
    return copy, len
end

local function makePath(path, ...)
    local keys = {...}
    local newPath, len = copySequence(path)
    for i = 1, #keys do
        newPath[len + i] = keys[i]
    end
    return newPath
end

local function processRecursive(process, item, path, visited)
    if item == nil then
        return nil
    end
    if visited[item] then
        return visited[item]
    end

    local processed = process(item, path)
    if type(processed) == "table" then
        local processedCopy = {}
        visited[item] = processedCopy
        local processedKey

        for k, v in rawpairs(processed) do
            processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
            if processedKey ~= nil then
                processedCopy[processedKey] = processRecursive(process, v,
                                                               makePath(path, processedKey), visited)
            end
        end

        local mt = processRecursive(process, getmetatable(processed),
                                    makePath(path, inspect.METATABLE), visited)
        if type(mt) ~= "table" then
            mt = nil
        end -- ignore not nil/table __metatable field
        setmetatable(processedCopy, mt)
        processed = processedCopy
    end
    return processed
end

-------------------------------------------------------------------

local Inspector = {}
local Inspector_mt = {__index = Inspector}

function Inspector:puts(...)
    local args = {...}
    local buffer = self.buffer
    local len = #buffer
    for i = 1, #args do
        len = len + 1
        buffer[len] = args[i]
    end
end

function Inspector:down(f)
    self.level = self.level + 1
    f()
    self.level = self.level - 1
end

function Inspector:tabify()
    self:puts(self.newline, string.rep(self.indent, self.level))
end

function Inspector:alreadyVisited(v)
    return self.ids[v] ~= nil
end

function Inspector:getId(v)
    local id = self.ids[v]
    if not id then
        local tv = type(v)
        id = (self.maxIds[tv] or 0) + 1
        self.maxIds[tv] = id
        self.ids[v] = id
    end
    return tostring(id)
end

function Inspector:putKey(k)
    if isIdentifier(k) then
        return self:puts(k)
    end
    self:puts("[")
    self:putValue(k)
    self:puts("]")
end

function Inspector:putTable(t)
    if t == inspect.KEY or t == inspect.METATABLE then
        self:puts(tostring(t))
    elseif self:alreadyVisited(t) then
        self:puts("<table ", self:getId(t), ">")
    elseif self.level >= self.depth then
        self:puts("{...}")
    else
        if self.tableAppearances[t] > 1 then
            self:puts("<", self:getId(t), ">")
        end

        local nonSequentialKeys, nonSequentialKeysLength, sequenceLength = getNonSequentialKeys(t)
        local mt = getmetatable(t)

        self:puts("{")
        self:down(function()
            local count = 0
            for i = 1, sequenceLength do
                if count > 0 then
                    self:puts(",")
                end
                self:puts(" ")
                self:putValue(t[i])
                count = count + 1
            end

            for i = 1, nonSequentialKeysLength do
                local k = nonSequentialKeys[i]
                if count > 0 then
                    self:puts(",")
                end
                self:tabify()
                self:putKey(k)
                self:puts(" = ")
                self:putValue(t[k])
                count = count + 1
            end

            if type(mt) == "table" then
                if count > 0 then
                    self:puts(",")
                end
                self:tabify()
                self:puts("<metatable> = ")
                self:putValue(mt)
            end
        end)

        if nonSequentialKeysLength > 0 or type(mt) == "table" then -- result is multi-lined. Justify closing }
            self:tabify()
        elseif sequenceLength > 0 then -- array tables have one extra space before closing }
            self:puts(" ")
        end

        self:puts("}")
    end
end

function Inspector:putValue(v)
    local tv = type(v)

    if tv == "string" then
        self:puts(smartQuote(escape(v)))
    elseif tv == "number" or tv == "boolean" or tv == "nil" or tv == "cdata" or tv == "ctype" then
        self:puts(tostring(v))
    elseif tv == "table" then
        self:putTable(v)
    else
        self:puts("<", tv, " ", self:getId(v), ">")
    end
end

-------------------------------------------------------------------

function inspect.inspect(root, options)
    options = options or {}

    local depth = options.depth or math.huge
    local newline = options.newline or "\n"
    local indent = options.indent or "  "
    local process = options.process

    if process then
        root = processRecursive(process, root, {}, {})
    end

    local inspector = setmetatable({
        depth = depth,
        level = 0,
        buffer = {},
        ids = {},
        maxIds = {},
        newline = newline,
        indent = indent,
        tableAppearances = countTableAppearances(root)
    }, Inspector_mt)

    inspector:putValue(root)

    return table.concat(inspector.buffer)
end

setmetatable(inspect, {
    __call = function(_, ...)
        return inspect.inspect(...)
    end
})

--- Function to send debug messages to console output
---@param message string | number | table | any
---@param color? '"info"' | '"warning"' | '"error"' | '"success"'
function dprint(message, color)
    if DebugMode then
        if (type(message) ~= "string") then
            if message then
                message = tostring(inspect(message)):gsub("\n", "")
            else
                message = tostring(message)
            end
        end
        --print(message)
        if (color == "info") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message, table.unpack(blam.consoleColors.warning))
        elseif (color == "error") then
            console_out(message, table.unpack(blam.consoleColors.error))
        elseif (color == "success") then
            console_out(message, table.unpack(blam.consoleColors.success))
        else
            console_out(message)
        end
    end
end

end,

["base64"] = function()
--------------------
-- Module: 'base64'
--------------------
--[[

 base64 -- v1.5.3 public domain Lua base64 encoder/decoder
 no warranty implied; use at your own risk

 Needs bit32.extract function. If not present it's implemented using BitOp
 or Lua 5.3 native bit operators. For Lua 5.1 fallbacks to pure Lua
 implementation inspired by Rici Lake's post:
   http://ricilake.blogspot.co.uk/2007/10/iterating-bits-in-lua.html

 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/lbase64

 COMPATIBILITY

 Lua 5.1+, LuaJIT

 LICENSE

 See end of file for license information.

--]]


local base64 = {}

local extract = _G.bit32 and _G.bit32.extract -- Lua 5.2/Lua 5.3 in compatibility mode
if not extract then
	if _G.bit then -- LuaJIT
		local shl, shr, band = _G.bit.lshift, _G.bit.rshift, _G.bit.band
		extract = function( v, from, width )
			return band( shr( v, from ), shl( 1, width ) - 1 )
		end
	elseif _G._VERSION == "Lua 5.1" then
		extract = function( v, from, width )
			local w = 0
			local flag = 2^from
			for i = 0, width-1 do
				local flag2 = flag + flag
				if v % flag2 >= flag then
					w = w + 2^i
				end
				flag = flag2
			end
			return w
		end
	else -- Lua 5.3+
		extract = load[[return function( v, from, width )
			return ( v >> from ) & ((1 << width) - 1)
		end]]()
	end
end


function base64.makeencoder( s62, s63, spad )
	local encoder = {}
	for b64code, char in pairs{[0]='A','B','C','D','E','F','G','H','I','J',
		'K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y',
		'Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n',
		'o','p','q','r','s','t','u','v','w','x','y','z','0','1','2',
		'3','4','5','6','7','8','9',s62 or '+',s63 or'/',spad or'='} do
		encoder[b64code] = char:byte()
	end
	return encoder
end

function base64.makedecoder( s62, s63, spad )
	local decoder = {}
	for b64code, charcode in pairs( base64.makeencoder( s62, s63, spad )) do
		decoder[charcode] = b64code
	end
	return decoder
end

local DEFAULT_ENCODER = base64.makeencoder()
local DEFAULT_DECODER = base64.makedecoder()

local char, concat = string.char, table.concat

function base64.encode( str, encoder, usecaching )
	encoder = encoder or DEFAULT_ENCODER
	local t, k, n = {}, 1, #str
	local lastn = n % 3
	local cache = {}
	for i = 1, n-lastn, 3 do
		local a, b, c = str:byte( i, i+2 )
		local v = a*0x10000 + b*0x100 + c
		local s
		if usecaching then
			s = cache[v]
			if not s then
				s = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
				cache[v] = s
			end
		else
			s = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
		end
		t[k] = s
		k = k + 1
	end
	if lastn == 2 then
		local a, b = str:byte( n-1, n )
		local v = a*0x10000 + b*0x100
		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[64])
	elseif lastn == 1 then
		local v = str:byte( n )*0x10000
		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[64], encoder[64])
	end
	return concat( t )
end

function base64.decode( b64, decoder, usecaching )
	decoder = decoder or DEFAULT_DECODER
	local pattern = '[^%w%+%/%=]'
	if decoder then
		local s62, s63
		for charcode, b64code in pairs( decoder ) do
			if b64code == 62 then s62 = charcode
			elseif b64code == 63 then s63 = charcode
			end
		end
		pattern = ('[^%%w%%%s%%%s%%=]'):format( char(s62), char(s63) )
	end
	b64 = b64:gsub( pattern, '' )
	local cache = usecaching and {}
	local t, k = {}, 1
	local n = #b64
	local padding = b64:sub(-2) == '==' and 2 or b64:sub(-1) == '=' and 1 or 0
	for i = 1, padding > 0 and n-4 or n, 4 do
		local a, b, c, d = b64:byte( i, i+3 )
		local s
		if usecaching then
			local v0 = a*0x1000000 + b*0x10000 + c*0x100 + d
			s = cache[v0]
			if not s then
				local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
				s = char( extract(v,16,8), extract(v,8,8), extract(v,0,8))
				cache[v0] = s
			end
		else
			local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
			s = char( extract(v,16,8), extract(v,8,8), extract(v,0,8))
		end
		t[k] = s
		k = k + 1
	end
	if padding == 1 then
		local a, b, c = b64:byte( n-3, n-1 )
		local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40
		t[k] = char( extract(v,16,8), extract(v,8,8))
	elseif padding == 2 then
		local a, b = b64:byte( n-3, n-2 )
		local v = decoder[a]*0x40000 + decoder[b]*0x1000
		t[k] = char( extract(v,16,8))
	end
	return concat( t )
end

return base64

--[[
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2018 Ilya Kolbin
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
--]]

end,

["ini"] = function()
--------------------
-- Module: 'ini'
--------------------
-------------------------------------------------------------------------------
--- INI Module
--- Dynodzzo, Sledmine
--- It has never been that simple to use ini files with Lua
----------------------------------------------------------------------------------
local ini = {
    _VERSION = 1.0,
    _LICENSE = [[
	Copyright (c) 2012 Carreras Nicolas
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER G
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]
}

--- Returns a table containing all the data from an ini string
---@param fileString string Ini encoded string
---@return table Table containing all data from the ini string
function ini.decode(fileString)
    local position, lines = 0, {}
    for st, sp in function()
        return string.find(fileString, "\n", position, true)
    end do
        table.insert(lines, string.sub(fileString, position, st - 1))
        position = sp + 1
    end
    table.insert(lines, string.sub(fileString, position))
    local data = {}
    local section
    for lineNumber, line in pairs(lines) do
        if string.sub(line, 1, 1) == "[" then
            section = string.sub(line, 2, string.find(line, "]") - 1)
            data[section] = {}
        elseif section then
            --local key, value = string.match(line, "([^=]*)=(.*)")
            local key, value = string.match(line, "^([%w|_]+)%s-=%s-(.+)$")
            if key and value then
                value = value:gsub("\r", "")
                if (tonumber(value)) then
                    value = tonumber(value)
                elseif (value == "true") then
                    value = true
                elseif (value == "false") then
                    value = false
                end
                if (tonumber(key)) then
                    key = tonumber(key)
                end
                data[section][key] = value
            end
        end
    end
    return data
end

--- Returns a ini encoded string given data
---@param data table Table containing all data from the ini file
---@return string String encoded as an ini file
function ini.encode(data)
    local content = ""
    for section, param in pairs(data) do
        content = content .. ("[%s]\n"):format(section)
        for key, value in pairs(param) do
            content = content .. ("%s=%s\n"):format(key, tostring(value))
        end
        content = content .. "\n"
    end
    return content
end

--- Returns a table containing all the data from an ini file
---@param fileName string Path to the file to load
---@return table Table containing all data from the ini file
function ini.load(fileName)
    assert(type(fileName) == "string", "Parameter \"fileName\" must be a string.")
    local file = assert(io.open(fileName, "r"), "Error loading file : " .. fileName)
    local data = ini.decode(file:read("*"))
    file:close()
    return data
end

--- Saves all the data from a table to an ini file
---@param fileName string The name of the ini file to fill
---@param data table The table containing all the data to store
function ini.save(fileName, data)
    assert(type(fileName) == "string", "Parameter \"fileName\" must be a string.")
    assert(type(data) == "table", "Parameter \"data\" must be a table.")
    local file = assert(io.open(fileName, "w+b"), "Error loading file :" .. fileName)
    file:write(ini.encode(data))
    file:close()
end

return ini

end,

["discordRPC"] = function()
--------------------
-- Module: 'discordRPC'
--------------------
local ffi = require "cffi"
local discordRPClib = ffi.load "discord-rpc"

function newproxy(new_meta)
    local proxy = {}

    if (new_meta == true) then
        local mt = {}
        setmetatable(proxy, mt)
    elseif (new_meta == false) then
    else
        -- new_meta must have a metatable.
        local mt = getmetatable(new_meta)
        setmetatable(proxy, mt)
    end

    return proxy
end

ffi.cdef [[
typedef struct DiscordRichPresence {
    const char* state;   /* max 128 bytes */
    const char* details; /* max 128 bytes */
    int64_t startTimestamp;
    int64_t endTimestamp;
    const char* largeImageKey;  /* max 32 bytes */
    const char* largeImageText; /* max 128 bytes */
    const char* smallImageKey;  /* max 32 bytes */
    const char* smallImageText; /* max 128 bytes */
    const char* partyId;        /* max 128 bytes */
    int partySize;
    int partyMax;
    const char* matchSecret;    /* max 128 bytes */
    const char* joinSecret;     /* max 128 bytes */
    const char* spectateSecret; /* max 128 bytes */
    int8_t instance;
} DiscordRichPresence;

typedef struct DiscordUser {
    const char* userId;
    const char* username;
    const char* discriminator;
    const char* avatar;
} DiscordUser;

typedef void (*readyPtr)(const DiscordUser* request);
typedef void (*disconnectedPtr)(int errorCode, const char* message);
typedef void (*erroredPtr)(int errorCode, const char* message);
typedef void (*joinGamePtr)(const char* joinSecret);
typedef void (*spectateGamePtr)(const char* spectateSecret);
typedef void (*joinRequestPtr)(const DiscordUser* request);

typedef struct DiscordEventHandlers {
    readyPtr ready;
    disconnectedPtr disconnected;
    erroredPtr errored;
    joinGamePtr joinGame;
    spectateGamePtr spectateGame;
    joinRequestPtr joinRequest;
} DiscordEventHandlers;

void Discord_Initialize(const char* applicationId,
                        DiscordEventHandlers* handlers,
                        int autoRegister,
                        const char* optionalSteamId);

void Discord_Shutdown(void);

void Discord_RunCallbacks(void);

void Discord_UpdatePresence(const DiscordRichPresence* presence);

void Discord_ClearPresence(void);

void Discord_Respond(const char* userid, int reply);

void Discord_UpdateHandlers(DiscordEventHandlers* handlers);
]]

local discordRPC = {} -- module table

-- proxy to detect garbage collection of the module
discordRPC.gcDummy = newproxy(true)

local function unpackDiscordUser(request)
    return ffi.string(request.userId), ffi.string(request.username),
           ffi.string(request.discriminator), ffi.string(request.avatar)
end

-- callback proxies
-- note: callbacks are not JIT compiled (= SLOW), try to avoid doing performance critical tasks in them
-- luajit.org/ext_ffi_semantics.html
local ready_proxy = ffi.cast("readyPtr", function(request)
    if discordRPC.ready then
        discordRPC.ready(unpackDiscordUser(request))
    end
end)

local disconnected_proxy = ffi.cast("disconnectedPtr", function(errorCode, message)
    if discordRPC.disconnected then
        discordRPC.disconnected(errorCode, ffi.string(message))
    end
end)

local errored_proxy = ffi.cast("erroredPtr", function(errorCode, message)
    if discordRPC.errored then
        discordRPC.errored(errorCode, ffi.string(message))
    end
end)

local joinGame_proxy = ffi.cast("joinGamePtr", function(joinSecret)
    if discordRPC.joinGame then
        discordRPC.joinGame(ffi.string(joinSecret))
    end
end)

local spectateGame_proxy = ffi.cast("spectateGamePtr", function(spectateSecret)
    if discordRPC.spectateGame then
        discordRPC.spectateGame(ffi.string(spectateSecret))
    end
end)

local joinRequest_proxy = ffi.cast("joinRequestPtr", function(request)
    if discordRPC.joinRequest then
        discordRPC.joinRequest(unpackDiscordUser(request))
    end
end)

-- helpers
local function checkArg(arg, argType, argName, func, maybeNil)
    assert(type(arg) == argType or (maybeNil and arg == nil), string.format(
               "Argument \"%s\" to function \"%s\" has to be of type \"%s\"", argName, func, argType))
end

local function checkStrArg(arg, maxLen, argName, func, maybeNil)
    if maxLen then
        assert(type(arg) == "string" and arg:len() <= maxLen or (maybeNil and arg == nil),
               string.format(
                   "Argument \"%s\" of function \"%s\" has to be of type string with maximum length %d",
                   argName, func, maxLen))
    else
        checkArg(arg, "string", argName, func, true)
    end
end

local function checkIntArg(arg, maxBits, argName, func, maybeNil)
    maxBits = math.min(maxBits or 32, 52) -- lua number (double) can only store integers < 2^53
    local maxVal = 2 ^ (maxBits - 1) -- assuming signed integers, which, for now, are the only ones in use
    assert(type(arg) == "number" and math.floor(arg) == arg and arg < maxVal and arg >= -maxVal or
               (maybeNil and arg == nil),
           string.format("Argument \"%s\" of function \"%s\" has to be a whole number <= %d",
                         argName, func, maxVal))
end

-- function wrappers
function discordRPC.initialize(applicationId, autoRegister, optionalSteamId)
    local func = "discordRPC.Initialize"
    checkStrArg(applicationId, nil, "applicationId", func)
    checkArg(autoRegister, "boolean", "autoRegister", func)
    if optionalSteamId ~= nil then
        checkStrArg(optionalSteamId, nil, "optionalSteamId", func)
    end

    local eventHandlers = ffi.new("struct DiscordEventHandlers")
    eventHandlers.ready = ready_proxy
    eventHandlers.disconnected = disconnected_proxy
    eventHandlers.errored = errored_proxy
    eventHandlers.joinGame = joinGame_proxy
    eventHandlers.spectateGame = spectateGame_proxy
    eventHandlers.joinRequest = joinRequest_proxy

    discordRPClib.Discord_Initialize(applicationId, eventHandlers, autoRegister and 1 or 0,
                                     optionalSteamId)
end

function discordRPC.shutdown()
    discordRPClib.Discord_Shutdown()
end

function discordRPC.runCallbacks()
    discordRPClib.Discord_RunCallbacks()
end
-- http://luajit.org/ext_ffi_semantics.html#callback :
-- It is not allowed, to let an FFI call into a C function (runCallbacks)
-- get JIT-compiled, which in turn calls a callback, calling into Lua again (e.g. discordRPC.ready).
-- Usually this attempt is caught by the interpreter first and the C function
-- is blacklisted for compilation.
-- solution:
-- "Then you'll need to manually turn off JIT-compilation with jit.off() for
-- the surrounding Lua function that invokes such a message polling function."
-- jit.off(discordRPC.runCallbacks)

function discordRPC.updatePresence(presence)
    local func = "discordRPC.updatePresence"
    checkArg(presence, "table", "presence", func)

    -- -1 for string length because of 0-termination
    checkStrArg(presence.state, 127, "presence.state", func, true)
    checkStrArg(presence.details, 127, "presence.details", func, true)

    checkIntArg(presence.startTimestamp, 64, "presence.startTimestamp", func, true)
    checkIntArg(presence.endTimestamp, 64, "presence.endTimestamp", func, true)

    checkStrArg(presence.largeImageKey, 31, "presence.largeImageKey", func, true)
    checkStrArg(presence.largeImageText, 127, "presence.largeImageText", func, true)
    checkStrArg(presence.smallImageKey, 31, "presence.smallImageKey", func, true)
    checkStrArg(presence.smallImageText, 127, "presence.smallImageText", func, true)
    checkStrArg(presence.partyId, 127, "presence.partyId", func, true)

    checkIntArg(presence.partySize, 32, "presence.partySize", func, true)
    checkIntArg(presence.partyMax, 32, "presence.partyMax", func, true)

    checkStrArg(presence.matchSecret, 127, "presence.matchSecret", func, true)
    checkStrArg(presence.joinSecret, 127, "presence.joinSecret", func, true)
    checkStrArg(presence.spectateSecret, 127, "presence.spectateSecret", func, true)

    checkIntArg(presence.instance, 8, "presence.instance", func, true)

    local cpresence = ffi.new("struct DiscordRichPresence")
    cpresence.state = presence.state
    cpresence.details = presence.details
    cpresence.startTimestamp = presence.startTimestamp or 0
    cpresence.endTimestamp = presence.endTimestamp or 0
    cpresence.largeImageKey = presence.largeImageKey
    cpresence.largeImageText = presence.largeImageText
    cpresence.smallImageKey = presence.smallImageKey
    cpresence.smallImageText = presence.smallImageText
    cpresence.partyId = presence.partyId
    cpresence.partySize = presence.partySize or 0
    cpresence.partyMax = presence.partyMax or 0
    cpresence.matchSecret = presence.matchSecret
    cpresence.joinSecret = presence.joinSecret
    cpresence.spectateSecret = presence.spectateSecret
    cpresence.instance = presence.instance or 0

    discordRPClib.Discord_UpdatePresence(cpresence)
end

function discordRPC.clearPresence()
    discordRPClib.Discord_ClearPresence()
end

local replyMap = {no = 0, yes = 1, ignore = 2}

-- maybe let reply take ints too (0, 1, 2) and add constants to the module
function discordRPC.respond(userId, reply)
    checkStrArg(userId, nil, "userId", "discordRPC.respond")
    assert(replyMap[reply],
           "Argument 'reply' to discordRPC.respond has to be one of \"yes\", \"no\" or \"ignore\"")
    discordRPClib.Discord_Respond(userId, replyMap[reply])
end

-- garbage collection callback
getmetatable(discordRPC.gcDummy).__gc = function()
    discordRPC.shutdown()
    ready_proxy:free()
    disconnected_proxy:free()
    errored_proxy:free()
    joinGame_proxy:free()
    spectateGame_proxy:free()
    joinRequest_proxy:free()
end

return discordRPC

end,

["color"] = function()
--------------------
-- Module: 'color'
--------------------
local color = {}

--- Convert to decimal rgb color from hex string color
---@param hex string
---@param alpha? number
function color.hexToDec(hex, alpha)
    local redColor, greenColor, blueColor = hex:gsub("#", ""):match("(..)(..)(..)")
    redColor, greenColor, blueColor = tonumber(redColor, 16) / 255, tonumber(greenColor, 16) / 255,
                                      tonumber(blueColor, 16) / 255
    redColor, greenColor, blueColor = math.floor(redColor * 100) / 100,
                                      math.floor(greenColor * 100) / 100,
                                      math.floor(blueColor * 100) / 100
    if alpha == nil then
        return redColor, greenColor, blueColor
    elseif alpha > 1 then
        alpha = alpha / 100
    end
    return redColor, greenColor, blueColor, alpha
end

--- Convert to decimal rgb color from byte rgb color
---@param r number
---@param g number
---@param b number
---@param alpha number
function color.rgbToDec(r, g, b, alpha)
    local redColor, greenColor, blueColor = r / 255, g / 255, b / 255
    redColor, greenColor, blueColor = math.floor(redColor * 100) / 100,
                                      math.floor(greenColor * 100) / 100,
                                      math.floor(blueColor * 100) / 100
    if alpha == nil then
        return redColor, greenColor, blueColor
    elseif alpha > 1 then
        alpha = alpha / 100
    end
    return redColor, greenColor, blueColor, alpha
end

--- Convert to rgb bytes to hex string
---@param r number
---@param g number
---@param b number
function color.rgbToHex(r, g, b)
    local rgb = (r * 0x10000) + (g * 0x100) + b
    return string.format("%06x", rgb)
end

--- Convert to rgb bytes to hex string
---@param r number
---@param g number
---@param b number
function color.decToHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

return color

end,

["luna"] = function()
--------------------
-- Module: 'luna'
--------------------
local luna = {
    _VERSION = "1.0.0",
}

luna.string = {}

--- Split a string into a table of substrings by `sep`.
---@param s string
---@param sep string
---@return string[]
---@nodiscard
function string.split(s, sep)
    assert(s ~= nil, "string.split: s must not be nil")
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    local _ = s:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

--- Return a string with all leading whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.ltrim(s)
    assert(s ~= nil, "string.ltrim: s must not be nil")
    return s:match "^%s*(.-)$"
end

--- Return a string with all trailing whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.rtrim(s)
    assert(s ~= nil, "string.rtrim: s must not be nil")
    return s:match "^(.-)%s*$"
end

--- Return a string with all leading and trailing whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.trim(s)
    assert(s ~= nil, "string.trim: s must not be nil")
    -- return s:match "^%s*(.-)%s*$"
    return string.ltrim(string.rtrim(s))
end

--- Return a string with all ocurrences of `pattern` replaced with `replacement`.
---
--- **NOTE**: Pattern is a plain string, not a Lua pattern. Use `string.gsub` for Lua patterns.
---@param s string
---@param pattern string
---@param replacement string
---@return string
---@nodiscard
function string.replace(s, pattern, replacement)
    assert(s ~= nil, "string.replace: s must not be nil")
    assert(pattern ~= nil, "string.replace: pattern must not be nil")
    assert(replacement ~= nil, "string.replace: replacement must not be nil")
    local pattern = pattern:gsub("%%", "%%%%"):gsub("%z", "%%z"):gsub("([%^%$%(%)%.%[%]%*%+%-%?])",
                                                                      "%%%1")
    local replaced, _ = s:gsub(pattern, replacement)
    return replaced
end

--- Return a hex encoded string.
---@param s string
---@return string
---@nodiscard
function string.tohex(s)
    assert(s ~= nil, "string.hex: s must not be nil")
    return (s:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

--- Return a hex decoded string.
---@param s string
---@return string
---@nodiscard
function string.fromhex(s)
    assert(s ~= nil, "string.fromhex: s must not be nil")
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

--- Resturn if a string starts with a given substring.
---@param s string
---@param start string
---@return boolean
---@nodiscard
function string.startswith(s, start)
    assert(s ~= nil, "string.startswith: s must not be nil")
    assert(start ~= nil, "string.startswith: start must not be nil")
    return string.sub(s, 1, string.len(start)) == start
end

--- Resturn if a string ends with a given substring.
---@param s string
---@param ending string
---@return boolean
---@nodiscard
function string.endswith(s, ending)
    assert(s ~= nil, "string.endswith: s must not be nil")
    assert(ending ~= nil, "string.endswith: ending must not be nil")
    return ending == "" or string.sub(s, -string.len(ending)) == ending
end

--- Return a string with template variables replaced with values from a table.
---@param s string
---@param t table<string, string | number | boolean>
---@return string
---@nodiscard
function string.template(s, t)
    assert(s ~= nil, "string.template: s must not be nil")
    assert(t ~= nil, "string.template: t must not be nil")
    return (s:gsub("{(.-)}", function(k)
        return t[k] or ""
    end))
end

luna.string.split = string.split
luna.string.ltrim = string.ltrim
luna.string.rtrim = string.rtrim
luna.string.trim = string.trim
luna.string.replace = string.replace
luna.string.tohex = string.tohex
luna.string.fromhex = string.fromhex
luna.string.startswith = string.startswith
luna.string.endswith = string.endswith
luna.string.template = string.template

luna.table = {}

--- Return a deep copy of a table.
---@generic T
---@param t T
---@return T
---@nodiscard
function table.copy(t)
    assert(t ~= nil, "table.copy: t must not be nil")
    assert(type(t) == "table", "table.copy: t must be a table")
    local u = {}
    for k, v in pairs(t) do
        u[k] = type(v) == "table" and table.copy(v) or v
    end
    return setmetatable(u, getmetatable(t))
end

--- Find and return first index of `value` in `t`.
---@generic V
---@param t table<number, V>: { [number]: V }
---@param value V
---@return number?
---@nodiscard
function table.indexof(t, value)
    assert(t ~= nil, "table.find: t must not be nil")
    assert(type(t) == "table", "table.find: t must be a table")
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
end

-- TODO Check annotations, it seems like flipping a table key pairs with generics doesn't work.
--- Return a table with all keys and values swapped.
---@generic K, V
---@param t table<K, V>
---@return table<V, K>
---@nodiscard
function table.flip(t)
    assert(t ~= nil, "table.flip: t must not be nil")
    assert(type(t) == "table", "table.flip: t must be a table")
    local u = {}
    for k, v in pairs(t) do
        u[v] = k
    end
    return u
end

--- Returns the first element of `t` that satisfies the predicate `f`.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean
---@return V?
---@nodiscard
function table.find(t, f)
    assert(t ~= nil, "table.find: t must not be nil")
    assert(type(t) == "table", "table.find: t must be a table")
    assert(f ~= nil, "table.find: f must not be nil")
    assert(type(f) == "function", "table.find: f must be a function")
    for k, v in pairs(t) do
        if f(v, k) then
            return v
        end
    end
end

--- Returns a list of all keys in `t`.
---@generic K, V
---@param t table<K, V>
---@return K[]
---@nodiscard
function table.keys(t)
    assert(t ~= nil, "table.keys: t must not be nil")
    assert(type(t) == "table", "table.keys: t must be a table")
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

--- Returns a list of all values in `t`.
---@generic K, V
---@param t table<K, V>
---@return V[]
---@nodiscard
function table.values(t)
    assert(t ~= nil, "table.values: t must not be nil")
    assert(type(t) == "table", "table.values: t must be a table")
    local values = {}
    for _, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

--- Returns a table with all elements of `t` that satisfy the predicate `f`.
--- 
--- **NOTE**: It keeps original keys in the new table.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean
---@return table<K, V>
---@nodiscard
function table.filter(t, f)
    assert(t ~= nil, "table.filter: t must not be nil")
    assert(type(t) == "table", "table.filter: t must be a table")
    assert(f ~= nil, "table.filter: f must not be nil")
    assert(type(f) == "function", "table.filter: f must be a function")
    local filtered = {}
    for k, v in pairs(t) do
        if f(v, k) then
            filtered[k] = v
        end
    end
    return filtered
end

--- Returns a table with all elements of `t` mapped by the function `f`.
---
--- **NOTE**: It keeps original keys in the new table.
---@generic K, V, R
---@param t table<K, V>
---@param f fun(v: V, k: K): R
---@return table<K, R>
---@nodiscard
function table.map(t, f)
    assert(t ~= nil, "table.map: t must not be nil")
    assert(type(t) == "table", "table.map: t must be a table")
    assert(f ~= nil, "table.map: f must not be nil")
    assert(type(f) == "function", "table.map: f must be a function")
    local mapped = {}
    for k, v in pairs(t) do
        mapped[k] = f(v, k)
    end
    return mapped
end

luna.table.copy = table.copy
luna.table.indexof = table.indexof
luna.table.flip = table.flip
luna.table.find = table.find
luna.table.keys = table.keys
luna.table.values = table.values
luna.table.filter = table.filter
luna.table.map = table.map

luna.file = {}

--- Read a file as text and return its contents.
---@param path string
---@return string?
---@nodiscard
function luna.file.read(path)
    assert(path ~= nil, "file.read: path must not be nil")
    local file = io.open(path, "r")
    if file then
        local content = file:read "*a"
        file:close()
        return content
    end
end

--- Write text to a file.
---@param path string
---@param content string
---@return boolean
function luna.file.write(path, content)
    assert(path ~= nil, "file.write: path must not be nil")
    assert(content ~= nil, "file.write: content must not be nil")
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

return luna

end,

["insurrection.utils"] = function()
--------------------
-- Module: 'insurrection.utils'
--------------------
local glue = require "glue"
local utils = {}

---Returns the path, filename or name, and extension of a path
---@param path string
---@return {path: string, name: string, extension?: string}
function utils.path(path)
    local split = glue.string.split(path, "\\")
    local pathElements = glue.deepcopy(split --[[@as table]])
    table.remove(pathElements, #pathElements)
    local path = table.concat(pathElements, "\\")
    local name = split[#split]
    local extension
    if name:find(".", 1, true) then
        local split = glue.string.split(name, ".")
        name = split[1]
        extension = split[#split]
    end
    return {path = path, name = name, extension = extension}
end

---Executes a function after a delay
---@param delay number
---@param callback function
function utils.delay(delay, callback)
    _G[tostring(callback)] = function ()
        callback()
        return false
    end
    local timerId = set_timer(delay, tostring(callback))
end


return utils

end,

["insurrection.constants"] = function()
--------------------
-- Module: 'insurrection.constants'
--------------------
local blam = require "blam"
local tagClasses = blam.tagClasses
local findTag = blam.findTag
local function findWidgetTag(partialName)
    return findTag(partialName, blam.tagClasses.uiWidgetDefinition)
end
local core = require "insurrection.core"

local constants = {}

constants.path = {
    pauseMenu = [[insurrection\ui\menus\pause\pause_menu]],
    nameplateCollection = [[insurrection\ui\shared\nameplates]],
    dialog = [[insurrection\ui\menus\dialog\dialog_menu]],
    customSounds = [[insurrection\sound\custom_sounds]]
}

constants.color = {
    white = "#FFFFFF",
    black = "#000000",
    red = "#FE0000",
    blue = "#0201E3",
    gray = "#707E71",
    yellow = "#FFFF01",
    green = "#00FF01",
    pink = "#FF56B9",
    purple = "#AB10F4",
    cyan = "#01FFFF",
    cobalt = "#6493ED",
    orange = "#FF7F00",
    teal = "#1ECC91",
    sage = "#006401",
    brown = "#603814",
    tan = "#C69C6C",
    maroon = "#9D0B0E",
    salmon = "#F5999E"
}

constants.colors = {
    constants.color.white,
    constants.color.black,
    constants.color.red,
    constants.color.blue,
    constants.color.gray,
    constants.color.yellow,
    constants.color.green,
    constants.color.pink,
    constants.color.purple,
    constants.color.cyan,
    constants.color.cobalt,
    constants.color.orange,
    constants.color.teal,
    constants.color.sage,
    constants.color.brown,
    constants.color.tan,
    constants.color.maroon,
    constants.color.salmon
}

function constants.get()
    constants.widgets = {
        --[[
        The following widgets are not used by the game, but are used by Insurrection.
        They are gathered here for later use.
        Ideally, we only want root widgets, so we can search for nested widgets later.
    ]]
        intro = findWidgetTag("intro\\intro_menu"),
        main = findWidgetTag("main_menu"),
        dialog = findWidgetTag("dialog\\dialog_menu"),
        login = findWidgetTag("login_menu"),
        lobby = findWidgetTag("lobby_menu"),
        dashboard = findWidgetTag("dashboard\\dashboard_menu"),
        customization = findWidgetTag("customization_menu"),
        pause = findWidgetTag("pause\\pause_menu"),
        nameplate = findWidgetTag("nameplate_current_profile"),
        tester = findWidgetTag("tester_menu"),
        settings = findWidgetTag("settings\\settings_menu"),
        chimera = findWidgetTag("chimera\\chimera_mod_menu"),
        color = findWidgetTag("customization_color_menu"),
        team = findWidgetTag("pause_choose_team_menu")
    }

    constants.sounds = {
        error = findTag("flag_failure", tagClasses.sound),
        back = findTag("back", tagClasses.sound),
        success = findTag("forward", tagClasses.sound),
        join = findTag("player_join", tagClasses.sound),
        leave = findTag("player_leave", tagClasses.sound)
    }

    constants.tagCollections = {
        nameplates = findTag("nameplates", tagClasses.tagCollection),
        maps = findTag("insurrection_maps", tagClasses.tagCollection)
    }

    constants.widgetCollections = {
        multiplayer = findTag("ui\\shell\\multiplayer", tagClasses.uiWidgetCollection)
    }

    if constants.tagCollections.nameplates then
        local nameplatesTagCollection = blam.tagCollection(constants.tagCollections.nameplates.id)
        if nameplatesTagCollection then
            local nameplateBitmapTags = {}
            for _, tagId in ipairs(nameplatesTagCollection.tagList) do
                local tag = blam.getTag(tagId) --[[@as tag]]
                local nameplateId = core.getTagName(tag.path)
                if nameplateId and not nameplateBitmapTags[nameplateId] then
                    nameplateBitmapTags[nameplateId] = tag
                end
            end
            constants.nameplates = nameplateBitmapTags
        end
    end

    constants.bitmaps = {unknownMapPreview = findTag("unknown_map_preview", tagClasses.bitmap)}
    constants.fonts = {
        text = findTag("text", tagClasses.font),
        title = findTag("title", tagClasses.font),
        subtitle = findTag("subtitle", tagClasses.font),
        button = findTag("button", tagClasses.font),
        shadow = findTag("shadow", tagClasses.font)
    }
end

return constants

end,

["insurrection.translations"] = function()
--------------------
-- Module: 'insurrection.translations'
--------------------
return {
    eng = {
        block_server_ips_subtitle = "Chimera is not blocking server IP addresses.",
        block_server_ips_message = "Insurrection might close the game to enable this feature.\nThis is a security measure to prevent server IP addresses being leaked."
    }
}

end,

["insurrection.menus"] = function()
--------------------
-- Module: 'insurrection.menus'
--------------------
local harmony = require "mods.harmony"
local openWidget = harmony.menu.open_widget
local constants = require "insurrection.constants"

local menus = {}

function menus.dashboard()
    openWidget(constants.widgets.dashboard.id, true)
end

function menus.customization()
    openWidget(constants.widgets.customization.id, true)
end

function menus.lobby()
    openWidget(constants.widgets.lobby.id, true)
end

function menus.pause()
    openWidget(constants.widgets.pause.id, false)
end

function menus.open(widget)
    openWidget(widget, false)
end 

return menus

end,

["insurrection.version"] = function()
--------------------
-- Module: 'insurrection.version'
--------------------
local releaseVersion = "2.4.3"
local metadata = "3a7cb3d.20230429"
local version = releaseVersion
if DebugMode then
    return releaseVersion .. "-dev+" .. metadata
end
return version

end,

["insurrection.mercury"] = function()
--------------------
-- Module: 'insurrection.mercury'
--------------------
------------------------------------------------------------------------------
-- Mercury Communication
-- Gelatinoso, Sledmine
-- Module to communicate with Mercury available on the host system
------------------------------------------------------------------------------
local json = require "json"
local inspect = require "inspect"

local mercury = {}

---@class packageMetadata
---@field name string
---@field label string
---@field author string
---@field version string
---@field internalVersion string
---@field category string
---@field conflicts string[]
---@field mirrors string[]
---@field nextVersion string

---@class mercDependencies
---@field label string
---@field version string

---@class mercFiles
---@field path string
---@field type string
---@field outputPath string

---@class mercUpdates
---@field path string
---@field diffPath string
---@field type string
---@field outputPath string

---@class packageMercury
---@field name string
---@field label string
---@field description string
---@field author string
---@field version string
---@field targetVersion string
---@field internalVersion string
---@field manifestVersion string
---@field files mercFiles[]
---@field updates mercUpdates[]
---@field dependencies mercDependencies[]

--- Get an array of installed Mercury packages
---@return packageMercury[] | nil
function mercury.getInstalled()
    local installedPackages
    local pipe = io.popen("mercury list -j", "r")
    if (pipe) then
        local output = pipe:read("*all")
        console_out(output)
        pipe:close()
        if (output and output ~= "" and not output:find("Warning,")) then
            installedPackages = json.decode(output)
            return installedPackages
        end
    end
end

-- Fetch the latest package index available on the repository
---@return packageMetadata[]
function mercury.fetchPackages()
    -- Get the package index output on json format
    local pipe = io.popen("mercury fetch -j")
    if (pipe) then
        local output = pipe:read("*all")
        pipe:close()
        print(inspect(output))
        if (output and output ~= "" and not output:find("Error,")) then
            local fetchedPackages = json.decode(output)
            return fetchedPackages
        end
    end
    return {}
end

-- Installs selected package
function mercury.installPackage(label)
    local pipe = io.popen("mercury install " .. label)
    if (pipe) then
        local response = pipe:read("*all")
        pipe:close()
        return response
    end
end

function mercury.removePackage(label)
    local result = os.execute("mercury remove " .. label)
    return result
end

return mercury

end,

["insurrection.mods.chimera"] = function()
--------------------
-- Module: 'insurrection.mods.chimera'
--------------------
local harmony = require "mods.harmony"
local glue = require "glue"
local split = glue.string.split
local blam = require "blam"
local tagClasses = blam.tagClasses
local ini = require "ini"
local constants = require "insurrection.constants"

local core = require "insurrection.core"

local chimera = {}

---@class chimeraServer
---@field ip string
---@field port number
---@field password string
---@field dns string?

---@type chimeraServer[]
local servers = {}
local maximumDisplayedServers = 10
local maximumDisplayedOptions = maximumDisplayedServers + 1

local myGamesPath = read_string(0x00647830)

---Load the list of servers from chimera in cache
---@return string[]
function chimera.loadServers(loadHistory)
    servers = {}
    local serversFilePath = myGamesPath .. "\\chimera\\bookmark.txt"
    if loadHistory then
        serversFilePath = myGamesPath .. "\\chimera\\history.txt"
    end
    local serversFile = glue.readfile(serversFilePath, "t")
    if (serversFile) then
        -- Get each server entry from the bookmarks file
        local storedServers = split(serversFile, "\n")
        for serverIndex, serverData in ipairs(storedServers) do
            local serverSplit = split(serverData, " ")

            local serverHost = serverSplit[1]
            local hostSplit = split(serverHost, ":")

            local serverIp = hostSplit[1]
            local serverPort = tonumber(hostSplit[2])
            local serverPassword = serverSplit[2]
            if (serverIp and serverIp ~= "") then
                servers[#servers + 1] = {
                    ip = serverIp,
                    port = serverPort or 2302,
                    password = serverPassword or "x"
                }
            else
                storedServers[serverIndex] = nil
            end
        end
    end
    -- Reflect servers on the UI
    if #servers > 0 then
        local serversTag = blam.findTag("chimera_servers_options", tagClasses.uiWidgetDefinition)
        if serversTag then
            local serversList = blam.uiWidgetDefinition(serversTag.id)
            for serverIndex = 1, maximumDisplayedServers do
                local server = servers[serverIndex]
                local childWidget = serversList.childWidgets[serverIndex + 1]
                if server and childWidget then
                    local serverOption = blam.uiWidgetDefinition(childWidget.widgetTag)
                    local serverOptionStringList = blam.unicodeStringList(
                                                       serverOption.unicodeStringListTag)
                    local stringList = serverOptionStringList.stringList
                    local serverLabel = serverIndex .. " = " .. server.ip .. ":" .. server.port
                    -- local serverLabel = serverIndex .. ":" .. serverPort
                    -- local server, queryError = chimera.queryServer(serverIp, serverPort)
                    local server, queryError
                    if (server) then
                        serverLabel = server.hostname:sub(1, 21) .. " - " .. server.ping .. "ms"
                        if (serverPassword) then
                            stringList[1] = serverLabel .. " [L]"
                        end
                    else
                        if (queryError) then
                            stringList[1] = serverLabel .. " - " .. queryError:upper()
                        else
                            stringList[1] = serverLabel
                        end
                    end
                    serverOptionStringList.stringList = stringList
                end
            end
            serversList.childWidgetsCount = maximumDisplayedOptions
            if (#servers < maximumDisplayedOptions) then
                serversList.childWidgetsCount = #servers + 1
            end
        end
    end
    return nil
end

---@class serverInfo
---@field dedicated string
---@field final string
---@field fraglimit string
---@field game_classic string
---@field game_flags string
---@field gamemode string
---@field gametype string
---@field gamevariant string
---@field gamever string
---@field hostname string
---@field hostport number
---@field mapname string
---@field maxplayers number
---@field nextmap string
---@field nextmode string
---@field numplayers string
---@field password string
---@field ping number
---@field player_flags string
---@field queryid string
---@field sapp string
---@field sapp_flags string
---@field score_t0 string
---@field score_t1 string
---@field team_t0 string
---@field team_t1 string
---@field teamplay string

local inspect = require "inspect"
--- Attempt to query a game server
---@param serverIp string
---@param serverPort number
---@return serverInfo | boolean, string?
function chimera.queryServer(serverIp, serverPort)
    local result, info = pcall(harmony.server.query_status, serverIp, serverPort)
    if (result) then
        print(info)
        local data = split(info, "\\")
        local object = {}
        for i = 2, #data, 2 do
            local key = data[i]
            local value = data[i + 1]
            if (key == "hostport" or key == "maxplayers" or key == "numplayers" or key ==
                "fraglimit" or key == "ping") then
                value = tonumber(value)
            end
            object[key] = value
        end
        print(inspect(object))
        return object
    else
        if (info:find("timeout")) then
            return false, "timeout"
        elseif (info:find("recive")) then
            return false, "no response"
        elseif (info:find("send")) then
            return false, "failed request"
        end
    end
    return false
end

---@class chimeraConfiguration
---@field server_list Serverlist
---@field custom_console Customconsole
---@field memory Memory
---@field controller any[]
---@field font_override Fontoverride
---@field custom_chat Customchat
---@field scoreboard Scoreboard
---@field hotkey Hotkey
---@field video_mode Videomode
---@field name Name
---@field error_handling any[]
---@field halo Halo

---@class Halo
---@field hash string
---@field background_playback number
---@field optimal_defaults number
---@field console number

---@class Name
---@field font string

---@class Videomode
---@field height string
---@field borderless number
---@field refresh_rate number
---@field windowed number
---@field width string
---@field enabled number
---@field vsync number

---@class Hotkey
---@field ctrl_alt_shift_3 string
---@field alt_6 string
---@field ctrl_1 string
---@field alt_5 string
---@field ctrl_6 string
---@field ctrl_0 string
---@field alt_shift_3 string
---@field ctrl_alt_shift_2 string
---@field ctrl_4 string
---@field alt_1 string
---@field enabled number
---@field ctrl_7 string
---@field alt_0 string
---@field alt_8 string
---@field ctrl_9 string
---@field alt_shift_4 string
---@field ctrl_2 string
---@field alt_4 string
---@field ctrl_alt_shift_1 string
---@field ctrl_3 string
---@field f12 string
---@field ctrl_8 string
---@field alt_3 string
---@field alt_shift_2 string
---@field alt_9 string
---@field alt_shift_1 string
---@field alt_7 string
---@field ctrl_5 string
---@field alt_2 string

---@class Scoreboard
---@field font string
---@field fade_time number

---@class Customchat
---@field chat_message_hide_on_console number
---@field server_message_color_r number
---@field chat_input_anchor string
---@field chat_input_x number
---@field chat_input_color_b number
---@field chat_message_color_red_g number
---@field server_message_anchor string
---@field chat_message_color_red_a number
---@field chat_message_anchor string
---@field server_fade_out_time number
---@field chat_fade_out_time number
---@field server_slide_time_length number
---@field chat_input_color_a number
---@field server_message_font string
---@field server_time_up number
---@field chat_input_font string
---@field chat_message_y number
---@field chat_message_w number
---@field chat_slide_time_length number
---@field chat_input_w number
---@field chat_message_color_red_b number
---@field chat_message_h number
---@field chat_message_x number
---@field chat_message_color_blue_g number
---@field server_message_hide_on_console number
---@field server_message_color_a number
---@field server_message_h_chat_open number
---@field chat_message_color_ffa_g number
---@field chat_input_color_r number
---@field server_message_color_g number
---@field chat_message_color_ffa_r number
---@field chat_message_color_ffa_a number
---@field chat_message_font string
---@field chat_input_color_g number
---@field chat_line_height number
---@field chat_message_color_ffa_b number
---@field chat_message_color_blue_a number
---@field chat_message_color_blue_b number
---@field chat_input_y number
---@field server_message_w number
---@field chat_message_h_chat_open number
---@field chat_message_color_red_r number
---@field server_message_color_b number
---@field server_message_y number
---@field chat_message_color_blue_r number
---@field server_message_x number
---@field chat_time_up number
---@field server_line_height number
---@field server_message_h number

---@class Fontoverride
---@field ticker_font_weight number
---@field large_font_override number
---@field large_font_shadow_offset_y number
---@field small_font_offset_x number
---@field smaller_font_family string
---@field smaller_font_offset_y number
---@field ticker_font_offset_x number
---@field smaller_font_shadow_offset_x number
---@field small_font_shadow_offset_y number
---@field system_font_shadow_offset_x number
---@field system_font_shadow_offset_y number
---@field smaller_font_offset_x number
---@field small_font_offset_y number
---@field ticker_font_offset_y number
---@field ticker_font_family string
---@field smaller_font_override number
---@field small_font_family string
---@field console_font_shadow_offset_y number
---@field system_font_y_offset number
---@field large_font_family string
---@field console_font_offset_y number
---@field system_font_override number
---@field system_font_weight number
---@field large_font_size number
---@field ticker_font_override number
---@field small_font_override number
---@field console_font_size number
---@field ticker_font_shadow_offset_x number
---@field large_font_weight number
---@field console_font_family string
---@field enabled number
---@field console_font_weight number
---@field ticker_font_shadow_offset_y number
---@field smaller_font_size number
---@field system_font_size number
---@field small_font_weight number
---@field console_font_override number
---@field ticker_font_size number
---@field smaller_font_shadow_offset_y number
---@field small_font_size number
---@field large_font_offset_y number
---@field system_font_x_offset number
---@field large_font_shadow_offset_x number
---@field smaller_font_weight number
---@field large_font_offset_x number
---@field console_font_shadow_offset_x number
---@field console_font_offset_x number
---@field system_font_family string
---@field small_font_shadow_offset_x number

---@class Memory
---@field download_font string
---@field enable_map_memory_buffer number
---@field map_size number

---@class Customconsole
---@field fade_time number
---@field fade_start number
---@field buffer_size_soft number
---@field enable_scrollback number
---@field line_height number
---@field enabled number
---@field buffer_size number
---@field x_margin number

---@class Serverlist
---@field auto_query number

local insurrectionFontOverride = {
    console_font_family = "Hack Bold",
    console_font_offset_x = 0,
    console_font_offset_y = 0,
    console_font_override = 1,
    console_font_shadow_offset_x = 2,
    console_font_shadow_offset_y = 2,
    console_font_size = 10,
    console_font_weight = 400,
    enabled = 1,
    large_font_family = "Geogrotesque-Regular",
    large_font_offset_x = 0,
    large_font_offset_y = 3,
    large_font_override = 1,
    large_font_shadow_offset_x = 2,
    large_font_shadow_offset_y = 2,
    large_font_size = 13,
    large_font_weight = 400,
    small_font_family = "Geogrotesque-Regular",
    small_font_offset_x = 0,
    small_font_offset_y = 3,
    small_font_override = 1,
    small_font_shadow_offset_x = 2,
    small_font_shadow_offset_y = 2,
    small_font_size = 10,
    small_font_weight = 400,
    smaller_font_family = "Geogrotesque-Regular",
    smaller_font_offset_x = 0,
    smaller_font_offset_y = 4,
    smaller_font_override = 1,
    smaller_font_shadow_offset_x = 0,
    smaller_font_shadow_offset_y = 0,
    smaller_font_size = 10,
    smaller_font_weight = 400,
    system_font_family = "Geogrotesque-Regular",
    system_font_override = 1,
    system_font_shadow_offset_x = 2,
    system_font_shadow_offset_y = 2,
    system_font_size = 11,
    system_font_weight = 400,
    system_font_x_offset = 0,
    system_font_y_offset = 1,
    ticker_font_family = "Geogrotesque-Regular",
    ticker_font_offset_x = 0,
    ticker_font_offset_y = 0,
    ticker_font_override = 1,
    ticker_font_shadow_offset_x = 2,
    ticker_font_shadow_offset_y = 2,
    ticker_font_size = 18,
    ticker_font_weight = 400
}

local chimeraFontOverride = {
    console_font_family = "Hack Bold",
    console_font_offset_x = 0,
    console_font_offset_y = 0,
    console_font_override = 1,
    console_font_shadow_offset_x = 2,
    console_font_shadow_offset_y = 2,
    console_font_size = 14,
    console_font_weight = 400,
    enabled = 1,
    large_font_family = "Interstate-Bold",
    large_font_offset_x = 0,
    large_font_offset_y = 1,
    large_font_override = 1,
    large_font_shadow_offset_x = 2,
    large_font_shadow_offset_y = 2,
    large_font_size = 20,
    large_font_weight = 400,
    small_font_family = "Interstate-Bold",
    small_font_offset_x = 0,
    small_font_offset_y = 3,
    small_font_override = 1,
    small_font_shadow_offset_x = 2,
    small_font_shadow_offset_y = 2,
    small_font_size = 15,
    small_font_weight = 400,
    smaller_font_family = "Interstate-Bold",
    smaller_font_offset_x = 0,
    smaller_font_offset_y = 4,
    smaller_font_override = 1,
    smaller_font_shadow_offset_x = 2,
    smaller_font_shadow_offset_y = 2,
    smaller_font_size = 11,
    smaller_font_weight = 400,
    system_font_family = "Interstate-Bold",
    system_font_override = 1,
    system_font_shadow_offset_x = 2,
    system_font_shadow_offset_y = 2,
    system_font_size = 20,
    system_font_weight = 400,
    system_font_x_offset = 0,
    system_font_y_offset = 1,
    ticker_font_family = "Lucida Console",
    ticker_font_offset_x = 0,
    ticker_font_offset_y = 0,
    ticker_font_override = 1,
    ticker_font_shadow_offset_x = 2,
    ticker_font_shadow_offset_y = 2,
    ticker_font_size = 11,
    ticker_font_weight = 400
}

---Get chimera configuration
---@return chimeraConfiguration?
function chimera.getConfiguration()
    local configIni = glue.readfile("chimera.ini", "t")
    if configIni then
        ---@type chimeraConfiguration
        local configuration = ini.decode(configIni)
        return configuration
    end
end

---Save chimera configuration
---@param configuration chimeraConfiguration
function chimera.saveConfiguration(configuration)
    local configIni = ini.encode(configuration)
    return glue.writefile("chimera.ini", configIni, "t")
end

function chimera.setupFonts(revert)
    local chimeraIni = glue.readfile("chimera.ini", "t")
    if chimeraIni then
        local configuration = chimera.getConfiguration()
        if configuration then
            configuration.font_override = insurrectionFontOverride
            if revert then
                configuration.font_override = chimeraFontOverride
            end
            return chimera.saveConfiguration(configuration)
        end
    end
    return false
end

function chimera.enableBlockServerIp()
    local preferences = chimera.getPreferences()
    if preferences then
        preferences.chimera_block_server_ip = 1
        return chimera.savePreferences(preferences)
    end
    return false
end

---@class chimeraPreferences
---@field chimera_devmode 1|0
---@field chimera_budget 1|0
---@field chimera_widescreen_fix 1|0
---@field chimera_block_gametype_rules 1
---@field chimera_block_gametype_indicator true | false
---@field chimera_uncap_cinematic 1|0
---@field chimera_fov number | "auto"
---@field chimera_af 1|0
---@field chimera_invert_shader_flags 1|0
---@field chimera_show_coordinates 1|0
---@field chimera_mouse_sensitivity number[]
---@field chimera_throttle_fps number
---@field chimera_block_zoom_blur 1|0
---@field chimera_block_server_ip 1|0
---@field chimera_block_buffering 1|0
---@field chimera_show_fps 1|0
---@field chimera_block_loading_screen 1|0
---@field chimera_block_hold_f1 1|0
---@field chimera_block_mouse_acceleration 1|0

---Get chimera preferences
---@return chimeraPreferences?
function chimera.getPreferences()
    local preferencesTxt = glue.readfile(
                               core.getMyGamesHaloCEPath() .. "\\chimera\\preferences.txt", "t")
    if preferencesTxt then
        local preferences = {}
        -- Split the file into lines and iterate over them
        for line in preferencesTxt:gmatch("[^\n]+") do
            -- Search for line that starts with "chimera"
            if line:sub(1, 7) == "chimera" then
                -- Get key and value from line separeted by a space, support numbers as well
                local key, value = line:match("([^ ]+) (.+)")
                if key and value then
                    -- Convert value to number if possible
                    local number = tonumber(value)
                    if number then
                        value = number
                    end
                    -- Convert boolean to flag number if possible
                    if value == "true" then
                        value = 1
                    elseif value == "false" then
                        value = 0
                    end
                    preferences[key] = value
                end
            end
        end
        return preferences
    end
end

function chimera.savePreferences(preferences)
    local preferencesTxt = ""
    for key, value in pairs(preferences) do
        preferencesTxt = preferencesTxt .. key .. " " .. value .. "\n"
    end
    return glue.writefile(core.getMyGamesHaloCEPath() .. "\\chimera\\preferences.txt",
                          preferencesTxt, "t")
end

function chimera.executeCommand(command)
    if not execute_chimera_command then
        console_out("execute_chimera_command is not available.")
        return false
    end
    local result, error = pcall(execute_chimera_command, command, true)
    if result then
        execute_script("cls")
        return true
    end
    console_out(error)
    return false
end

function chimera.fontOverride()
    if create_font_override then
        create_font_override(constants.fonts.text.id, "Geogrotesque-Regular", 14, 400, 2, 2, 1, 1)
        create_font_override(constants.fonts.title.id, "Geogrotesque-Regular", 18, 400, 2, 2, 0, 0)
        create_font_override(constants.fonts.subtitle.id, "Geogrotesque-Regular", 10, 400, 2, 2, 0, 0)
        create_font_override(constants.fonts.button.id, "Geogrotesque-Regular", 13, 400, 2, 2, 1, 1)
        if constants.fonts.shadow then
            create_font_override(constants.fonts.shadow.id, "Geogrotesque-Regular", 10, 400, 0, 0, 0, 0)
        end
        return true
    end
    console_out("create_font_override is not available.")
    return false
end

return chimera

end,

["insurrection.core"] = function()
--------------------
-- Module: 'insurrection.core'
--------------------
local glue = require "glue"
local split = glue.string.split
local inspect = require "inspect"
local blam = require "blam"
local tagClasses = blam.tagClasses
local json = require "json"
local base64 = require "base64"
local harmony = require "mods.harmony"

local mercury = require "insurrection.mercury"
local scriptVersion = "insurrection-" .. require "insurrection.version"
local utils = require "insurrection.utils"

local currentWidgetIdAddress = 0x6B401C
local keyboardInputAddress = 0x64C550
local clientPortAddress = 0x6337F8
local clientPort = read_word(clientPortAddress)
local friendlyClientPort = 2305
local profileNameAddress = 0x6ADE22

local core = {}

function core.loadMercuryPackages()
    local installedPackages = mercury.getInstalled()
    if (installedPackages) then
        console_out(inspect(installedPackages))
        local serverStringsTag = blam.findTag([[chimera_servers_menu\strings\options]],
                                              tagClasses.unicodeStringList)
        local serverStrings = blam.unicodeStringList(serverStringsTag.id)
        local newServers = serverStrings.stringList
        for stringIndex = 1, serverStrings.count do
            newServers[stringIndex] = " "
        end
        for packageIndex, packageLabel in pairs(glue.keys(installedPackages)) do
            local package = installedPackages[packageLabel]
            newServers[packageIndex] = package.name .. " - " .. package.version
        end
        serverStrings.stringList = newServers
    end
end

--- Return the file name of a tag file path
---@param tagPath string
function core.getTagName(tagPath)
    local tagSplit = split(tagPath, "\\")
    local tagName = tagSplit[#tagSplit]
    return tagName
end

function core.loadInsurrectionPatches()
    -- Force usage a more friendly client port
    -- if clientPort ~= friendlyClientPort then
    --    write_dword(clientPortAddress, friendlyClientPort)
    -- end
    local scriptVersionTag = blam.findTag("insurrection_version_footer",
                                          tagClasses.unicodeStringList)
    if (scriptVersionTag) then
        local scriptVersionString = blam.unicodeStringList(scriptVersionTag.id)
        if (scriptVersionString) then
            local strings = scriptVersionString.stringList
            -- Write string version to map tag
            strings[1] = scriptVersion
            scriptVersionString.stringList = strings
        end
        return true
    end
end

function core.saveCredentials(username, password)
    write_file("credentials.json",
               json.encode({username = username, password = base64.encode(password)}))
end

function core.loadCredentials()
    local credentialsFile = read_file("credentials.json")
    if credentialsFile then
        local success, credentials = pcall(json.decode, credentialsFile)
        if success and credentials then
            return credentials.username, base64.decode(credentials.password)
        end
    end
end

function core.loadSettings()
    local settingsFile = read_file("settings.json")
    if settingsFile then
        local success, settings = pcall(json.decode, settingsFile)
        if success and settings then
            return settings
        end
    end
end

function core.saveSettings(settings)
    write_file("settings.json", json.encode(settings))
end

function core.getRenderedUIWidgetTagId()
    local isPlayerOnMenu = read_byte(blam.addressList.gameOnMenus) == 0
    if isPlayerOnMenu then
        local widgetIdAddress = read_dword(currentWidgetIdAddress)
        if widgetIdAddress and widgetIdAddress ~= 0 then
            local widgetId = read_dword(widgetIdAddress)
            return widgetId
        end
    end
end

--- Get the tag widget of the current ui open in the game
---@return tag | nil
function core.getCurrentUIWidgetTag()
    local widgetTagId = core.getRenderedUIWidgetTagId()
    if widgetTagId then
        local widgetTag = blam.getTag(widgetTagId)
        return widgetTag
    end
    return nil
end

---Attempt to translate a input key code
---@param keyCode integer
---@return string | nil name of the given key code
function core.translateKeycode(keyCode)
    if (keyCode == 29) then
        return "backspace"
    elseif (keyCode == 72) then
        return "space"
    else
        return nil
    end
end

local capsLock
---Attempt to map keys to a text string
---@param pressedKey string
---@param text string
---@return string | nil text Given text with mapped modifications applied
function core.mapKeyToText(pressedKey, text)
    if pressedKey == "backspace" then
        return text:sub(1, #text - 1)
    elseif pressedKey == "space" then
        return text .. " "
    elseif pressedKey == "capslock" then
        capsLock = not capsLock
    elseif #pressedKey == 1 and string.byte(pressedKey) > 31 and string.byte(pressedKey) < 127 then
        if capsLock then
            return text .. pressedKey:upper()
        end
        return text .. pressedKey
    end
end

function core.getStringFromWidget(widgetTagId)
    local widget = blam.uiWidgetDefinition(widgetTagId)
    local virtualValue = VirtualInputValue[widgetTagId]
    if virtualValue then
        return virtualValue
    end
    local unicodeStrings = blam.unicodeStringList(widget.unicodeStringListTag)
    return unicodeStrings.stringList[widget.stringListIndex + 1]
end

function core.cleanAllEditableWidgets()
    local editableWidgets = blam.findTagsList("input", tagClasses.uiWidgetDefinition) or {}
    for _, widgetTag in pairs(editableWidgets) do
        local widget = blam.uiWidgetDefinition(widgetTag.id)
        local widgetStrings = blam.unicodeStringList(widget.unicodeStringListTag)
        if widgetStrings then
            local strings = widgetStrings.stringList
            strings[1] = ""
            widgetStrings.stringList = strings
        end
    end
end

function core.setStringToWidget(text, widgetTagId, mask)
    local widgetDefinition = blam.uiWidgetDefinition(widgetTagId)
    if widgetDefinition then
        local unicodeStrings = blam.unicodeStringList(widgetDefinition.unicodeStringListTag)
        if unicodeStrings then
            if blam.isNull(unicodeStrings) then
                error("No unicodeStringList, can't assign text to this widget")
            end
            local stringListIndex = widgetDefinition.stringListIndex
            local newStrings = unicodeStrings.stringList
            if mask then
                VirtualInputValue[widgetTagId] = text
                newStrings[stringListIndex + 1] = string.rep(mask, #text)
            else
                newStrings[stringListIndex + 1] = text
            end
            unicodeStrings.stringList = newStrings
        end
    end
end

---Attempt to connect a game server
---@param host string
---@param port number
---@param password string
function core.connectServer(host, port, password)
    local command = "connect %s:%s \"%s\""
    execute_script(command:format(host, port, password))
end

function core.getMyGamesHaloCEPath()
    local myGamesPath = read_string(0x00647830)
    return myGamesPath
end

function core.getWidgetValues(widgetTagId)
    if core.getCurrentUIWidgetTag() then
        local sucess, widgetHandle = pcall(harmony.menu.find_widgets, widgetTagId)
        if sucess and widgetHandle then
            return harmony.menu.get_widget_values(widgetHandle)
        end
    end
end

function core.setWidgetValues(widgetTagId, values)
    local function setValuesDOMSafe()
        -- Verify there is a widget loaded in the DOM
        local widgetHandle = core.getWidgetHandle(widgetTagId)
        if widgetHandle then
            harmony.menu.set_widget_values(widgetHandle, values)
            return true
        end
    end
    if not setValuesDOMSafe() then
        -- If there is no widget loaded in the DOM, wait 30ms and try again
        -- (this is a workaround for the DOM not being loaded yet)
        utils.delay(30, function()
            setValuesDOMSafe()
        end)
    end
end

function core.getWidgetHandle(widgetTagId)
    if core.getCurrentUIWidgetTag() then
        local sucess, widgetHandle = pcall(harmony.menu.find_widgets, widgetTagId)
        if sucess and widgetHandle then
            return widgetHandle
        end
    end
end

function core.replaceWidgetInDom(widgetTagId, newWidgetTagId)
    local widgetHandle = core.getWidgetHandle(widgetTagId)
    if widgetHandle then
        harmony.menu.replace_widget(widgetHandle, newWidgetTagId)
    end
end

function core.getScreenResolution()
    local width = read_word(0x637CF2)
    local height = read_word(0x637CF0)
    return width, height
end

local function isThreadRunning()
    if #Lanes == 0 then
        return false
    end
    return true
end

---Set game in loading state
---@param isLoading boolean
---@param text? string
---@param blockInput? boolean
function core.loading(isLoading, text, blockInput)
    if isLoading then
        -- There is already another thread running, do not modify loading status
        if isThreadRunning() then
            return
        end
        if blockInput then
            harmony.menu.block_input(true)
        end
        LoadingText = text or "Loading..."
        dprint(LoadingText)
    else
        harmony.menu.block_input(false)
        LoadingText = nil
    end
end

function core.gameProfileName(name)
    local name = name
    if name then
        -- Limit name to 11 characters
        if #name > 11 then
            name = name:sub(1, 11)
        end
        blam.writeUnicodeString(profileNameAddress, name, true)
    end
    local profileName = blam.readUnicodeString(profileNameAddress, true)
    return profileName
end

return core

end,

["insurrection.discord"] = function()
--------------------
-- Module: 'insurrection.discord'
--------------------
local discord = {}
local core = require "insurrection.core"
local interface = require "insurrection.interface"
local base64 = require "base64"

local discordRPC = require "discordRPC"

discord.presence = {
    state = "Playing Insurrection",
    details = nil,
    largeImageKey = "insurrection",
    largeImageText = "Insurrection",
    startTimestamp = os.time(os.date("*t") --[[@as osdate]] )
    -- smallImageKey = "insurrection",
    -- smallImageText = "Insurrection",
    -- instance = 0
}
discord.presence.details = "In the main menu"

discord.ready = false

function discordRPC.ready(userId, username, discriminator, avatar)
    print(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
    core.loading(false)
    discord.ready = true
end

function discordRPC.disconnected(errorCode, message)
    print(string.format("Discord: disconnected (%d: %s)", errorCode, message))
end

function discordRPC.joinGame(joinSecret)
    api.lobby(joinSecret)
end

function discordRPC.joinRequest(userId, username, discriminator, avatar)
    -- print(string.format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator,
    --                    avatar))
    discordRPC.respond(userId, "yes")
end

function discord.startPresence()
    core.loading(true, "Starting Discord Presence...")
    if not discord.ready then
        discordRPC.initialize(base64.decode(read_file("micro")), true)
    end
    discordRPC.clearPresence()
    discordRPC.runCallbacks()
    if DiscordPresenceTimerId then
        pcall(stop_timer, DiscordPresenceTimerId)
    end
    function DiscordUpdate()
        discordRPC.runCallbacks()
        if discord.ready then
            discordRPC.updatePresence(discord.presence)
        else
            core.loading(false)
            if not DebugMode then
                interface.dialog("WARNING", "An error occurred while starting Discord Presence.",
                             "Please ensure that Discord is running and try again.\nDiscord is a required dependency for Insurrection services.")
            end
            return false
        end
    end
    DiscordPresenceTimerId = set_timer(2000, "DiscordUpdate")
end

--- Update the presence state and details
---@param state string
---@param details? string
function discord.updatePresence(state, details)
    discord.presence.state = state
    discord.presence.details = details
    discordRPC.updatePresence(discord.presence)
    discordRPC.runCallbacks()
end

---Set presence party info
---@param partyId string?
---@param partySize number?
---@param partyMax number?
---@param map? string
function discord.setParty(partyId, partySize, partyMax, map)
    if partyId then
        -- TODO Replace with a proper party unique ID
        discord.presence.partyId = partyId .. partyId:reverse()
        discord.presence.joinSecret = partyId
    end
    discord.presence.partySize = partySize
    discord.presence.partyMax = partyMax
    if map then
        discord.presence.details = map
        discord.presence.largeImageKey = map
        discord.presence.largeImageText = map
    end
    discordRPC.updatePresence(discord.presence)
    discordRPC.runCallbacks()
end

function discord.setPartyWithLobby()
    ---@type interfaceState
    local state = store:getState()
    discord.setParty(nil, #state.lobby.players, 16, state.lobby.map)
end

--- Clear the presence info
function discord.clearPresence()
    discordRPC.clearPresence()
end

function discord.stopPresence()
    if DiscordPresenceTimerId then
        pcall(stop_timer, DiscordPresenceTimerId)
    end
    discordRPC.clearPresence()
    discordRPC.shutdown()
end

return discord

end,

["insurrection.api"] = function()
--------------------
-- Module: 'insurrection.api'
--------------------
local lanes = require"lanes".configure()
local json = require "json"
local asyncLibs = "base, table, package, string"
local blam = require "blam"
local requests = require "requestscurl"
local interface = require "insurrection.interface"
local glue = require "glue"
local exists = glue.canopen
local trim = glue.string.trim
local actions = require "insurrection.redux.actions"
local core = require "insurrection.core"
local harmony = require "mods.harmony"
local menus = require "insurrection.menus"
local shared = interface.shared
local constants = require "insurrection.constants"
local loading = core.loading

local api = {}
api.host = read_file("insurrection_host") or "http://localhost:4343/"
if DebugMode then
    api.host = "http://localhost:4343/"
end
api.version = "v1"
api.url = api.host .. api.version
api.variables = {refreshRate = 3000, refreshTimerId = nil}
---@type loginResponse
api.session = {token = nil, lobbyKey = nil, username = nil}

-- Models

---@class requestResult
---@field message string

---@class loginResponse
---@field message string
---@field token? string
---@field player {nameplate: number, publicId: string, name: string, rank: number}
---@field secondsToExpire number

---@class availableParameters
---@field maps string[]
---@field gametypes string[]
---@field templates string[]

---@class serverInstance
---@field password string
---@field template string
---@field host string
---@field port integer
---@field map string
---@field gametype string
---@field cpu integer
---@field owner string
---@field lobbyKey string

---@class lobbyRoom
---@field owner string
---@field players string[]
---@field map string
---@field gametype string
---@field template string
---@field server serverInstance

function async(func, callback, ...)
    if (#Lanes == 0) then
        Lanes[#Lanes + 1] = {thread = lanes.gen(asyncLibs, func)(...), callback = callback}
    else
        dprint("Warning! An async function is trying to add another thread!", "warning")
    end
end

local function connect(map, host, port, password)
    -- dprint("Connecting to " .. tostring(host) .. ":" .. tostring(port) .. " with password " .. tostring(password))
    if exists("maps\\" .. map .. ".map") or
        exists(core.getMyGamesHaloCEPath() .. "\\chimera\\maps\\" .. map .. ".map") then
        discord.setPartyWithLobby()
        -- Force game profile name to be the same as the player's name
        core.gameProfileName(api.session.player.name)
        core.connectServer(host, port, password)
    else
        interface.dialog("ERROR", "LOCAL MAP NOT FOUND",
                         "Map \"" .. map .. "\" was not found on your game files.")
    end
end

---@param response httpResponse<loginResponse>
---@return boolean
local function onLoginResponse(response)
    loading(false)
    if response then
        if response.code == 200 then
            local jsonResponse = response.json()
            api.session.token = jsonResponse.token
            api.session.player = jsonResponse.player
            requests.headers = {"Authorization: Bearer " .. api.session.token}
            -- Save last defined nameplate
            core.saveSettings({nameplate = jsonResponse.player.nameplate})
            interface.loadProfileNameplate()
            api.available()
            menus.dashboard()
            return true
        elseif response.code == 401 then
            local jsonResponse = response.json()
            interface.dialog("ATTENTION", "ERROR " .. response.code, jsonResponse.message)
            return false
        end
    end
    interface.dialog("WARNING", "UNKNOWN ERROR",
                     "An unknown error has ocurred, please try again later.")
    return false
end
function api.login(username, password)
    loading(true, "Logging in...")
    async(requests.postform, function(result)
        onLoginResponse(result[1])
    end, api.url .. "/login", {username = username, password = password})
end

---@param response httpResponse<availableParameters>
---@return boolean
function onAvailableResponse(response)
    loading(false)
    if response then
        if response.code == 200 then
            local jsonResponse = response.json()
            store:dispatch(actions.setAvailableResources(jsonResponse))
            return true
        end
    end
    interface.dialog("ERROR", "UNKNOWN ERROR",
                     "An unknown error has ocurred, please try again later.")
    return false
end
function api.available()
    loading(true, "Loading available parameters...")
    async(requests.get, function(result)
        onAvailableResponse(result[1])
    end, api.url .. "/available")
end

---@param response httpResponse<lobbyResponse | lobbyRoom | requestResult>
---@return boolean
local function onLobbyResponse(response)
    dprint("onLobbyResponse", "info")
    loading(false)
    if response then
        if response.code == 200 then
            ---@class lobbyResponse
            ---@field key string
            ---@field lobby lobbyRoom

            local jsonResponse = response.json()
            if jsonResponse then
                menus.lobby()
                -- We asked for a new lobby room
                if jsonResponse.key then
                    api.session.lobbyKey = jsonResponse.key
                    store:dispatch(actions.setLobby(jsonResponse.key, jsonResponse.lobby))
                    interface.lobbyInit()
                else
                    -- We have to joined an existing lobby
                    local lobby = jsonResponse
                    store:dispatch(actions.setLobby(api.session.lobbyKey, lobby))
                    interface.lobbyInit()
                    -- There is a server already running for this lobby, connect to it
                    if lobby.server then
                        connect(lobby.server.map, lobby.server.host, lobby.server.port,
                                lobby.server.password)
                        return true
                    end
                end
                -- Start a timer to pull lobby data every certain time
                if api.variables.refreshTimerId then
                    api.stopRefreshLobby()
                end
                -- Create global function to be called by the timer
                refreshLobby = function()
                    if api.session.lobbyKey then
                        api.refreshLobby()
                    end
                end
                api.variables.refreshTimerId = set_timer(api.variables.refreshRate, "refreshLobby")
                ---@type interfaceState
                local state = store:getState()
                local isPlayerLobbyOwner = api.session.player and api.session.player.publicId ==
                                               state.lobby.owner
                if isPlayerLobbyOwner then
                    discord.updatePresence("Hosting a lobby", "Waiting for players...")
                    discord.setParty(api.session.lobbyKey, #state.lobby.players, 16, state.lobby.map)
                else
                    discord.updatePresence("In a lobby", "Waiting for players...")
                end
            end
            return true
        elseif response.code == 403 then
            local jsonResponse = response.json()
            if jsonResponse and jsonResponse.key then
                api.lobby(jsonResponse.key)
            end
        else
            api.session.lobbyKey = nil
            local jsonResponse = response.json()
            interface.dialog("ATTENTION", "ERROR " .. response.code, jsonResponse.message)
            return false
        end
    end
    interface.dialog("ERROR", "UNKNOWN ERROR",
                     "An unknown error has ocurred, please try again later.")
    return false
end
function api.lobby(lobbyKey)
    loading(true, "Loading lobby...")
    if lobbyKey then
        api.session.lobbyKey = lobbyKey
        async(requests.get, function(result)
            onLobbyResponse(result[1])
        end, api.url .. "/lobby/" .. lobbyKey)
    else
        async(requests.get, function(result)
            onLobbyResponse(result[1])
        end, api.url .. "/lobby")
    end
end

---@param response httpResponse<lobbyRoom | requestResult>
---@return boolean
local function onLobbyRefreshResponse(response)
    dprint("onLobbyRefreshResponse", "info")
    loading(false)
    if response then
        if response.code == 200 then
            local lobby = response.json()
            if lobby then
                -- Update previously joined lobby data
                store:dispatch(actions.updateLobby(api.session.lobbyKey, lobby))
                interface.lobbyUpdate()
                ---@type interfaceState
                local state = store:getState()
                local isPlayerLobbyOwner = api.session.player and api.session.player.publicId ==
                                               state.lobby.owner
                if not isPlayerLobbyOwner then
                    discord.setParty(nil, #lobby.players, 16, lobby.map)
                else
                    discord.setParty(api.session.lobbyKey, #lobby.players, 16, lobby.map)
                end
                -- Lobby already started, join the server
                if lobby.server and not blam.isGameDedicated() then
                    api.stopRefreshLobby()
                    connect(lobby.server.map, lobby.server.host, lobby.server.port,
                            lobby.server.password)
                end
            end
            return true
        else
            api.stopRefreshLobby()
            -- TODO Add a generic error handling function for this
            local jsonResponse = response.json()
            interface.dialog("ERROR", "ERROR " .. response.code, jsonResponse.message)
            return false
        end
    end
    api.stopRefreshLobby()
    interface.dialog("ERROR", "UNKNOWN ERROR", "An error has ocurred, at refreshing lobby data.")
    return false
end
function api.refreshLobby()
    loading(true, "Refreshing lobby...", false)
    if api.session.lobbyKey then
        dprint("Refreshing lobby data...", "info")
        async(requests.get, function(result)
            onLobbyRefreshResponse(result[1])
        end, api.url .. "/lobby/" .. api.session.lobbyKey)
    end
end
function api.stopRefreshLobby()
    if api.session.lobbyKey then
        discord.updatePresence("Playing Insurrection")
        pcall(stop_timer, api.variables.refreshTimerId)
    end
end
function api.deleteLobby()
    if api.session.lobbyKey then
        discord.updatePresence("Playing Insurrection")
        discord.setParty(nil)
        dprint("DELETING lobby", "warning")
        pcall(stop_timer, api.variables.refreshTimerId)
        api.variables.refreshTimerId = nil
        api.session.lobbyKey = nil
    end
end

---@param response httpResponse<serverBorrowResponse>
---@return boolean
local function onBorrowResponse(response)
    loading(false)
    if response then
        if response.code == 200 then
            -- Prevent lobby from refreshing while we are waiting for the server to start
            -- This is critical to avoid crashing the game due to multitasking stuff
            api.stopRefreshLobby()
            ---@class serverBorrowResponse
            ---@field password string
            ---@field message string
            ---@field port number
            ---@field host string
            ---@field map string

            local jsonResponse = response.json()
            if jsonResponse then
                dprint(jsonResponse)
                connect(jsonResponse.map, jsonResponse.host, jsonResponse.port,
                        jsonResponse.password)
            end
            return true
        elseif response.code == 404 then
            local jsonResponse = response.json()
            interface.dialog("ATTENTION", "ERROR " .. response.code, jsonResponse.message)
            return false
        else
            api.stopRefreshLobby()
            if response.code == 500 then
                interface.dialog("ATTENTION", "ERROR " .. response.code, "Internal Server Error")
                return false
            else
                local jsonResponse = response.json()
                interface.dialog("ATTENTION", "ERROR " .. response.code, jsonResponse.message)
                return false
            end
        end
    end
    api.stopRefreshLobby()
    interface.dialog("ERROR", "UNKNOWN ERROR",
                     "An unknown error has ocurred, please try again later.")
    return false
end
function api.borrow(template, map, gametype)
    loading(true, "Borrowing game server...", false)
    async(requests.get, function(result)
        onBorrowResponse(result[1])
    end, api.url .. "/borrow/" .. template .. "/" .. map .. "/" .. gametype .. "/" ..
              api.session.lobbyKey)
end

---@param response httpResponse<any>
---@return boolean
function onPlayerEditNameplateResponse(response)
    loading(false)
    if response then
        if response.code == 200 then
            interface.dialog("INFORMATION", "CONGRATULATIONS", "Profile customized successfully.")
            return true
        else
            local jsonResponse = response.json()
            if jsonResponse then
                interface.dialog("WARNING", "ERROR " .. response.code, jsonResponse.message)
            end
            return false
        end
    end
    interface.dialog("ERROR", "UNKNOWN ERROR",
                     "An unknown error has ocurred, please try again later.")
    return false
end
---Edit player nameplate
---@param data {nameplateId: string, bipeds: table<string, string>}
function api.playerProfileEdit(data)
    loading(true, "Editing profile...", false)
    async(requests.patch, function(result)
        if onPlayerEditNameplateResponse(result[1]) then
            interface.loadProfileNameplate(nameplateId)
        end
    end, api.url .. "/players", data)
end

local function onLobbyEditResponse(response)
    loading(false)
    if response then
        if response.code == 200 then
            return true
        else
            local jsonResponse = response.json()
            if jsonResponse then
                interface.dialog("ATTENTION", "ERROR " .. response.code, jsonResponse.message)
            end
            return false
        end
    end
    interface.dialog("ERROR", "UNKNOWN ERROR",
                     "An unknown error has ocurred, please try again later.")
    return false
end
function api.editLobby(lobbyKey, data)
    loading(true, "Editing lobby...", false)
    async(requests.patch, function(result)
        onLobbyEditResponse(result[1])
    end, api.url .. "/lobby/" .. lobbyKey, data)
end

return api

end,

["insurrection.components"] = function()
--------------------
-- Module: 'insurrection.components'
--------------------
local blam = require "blam"
local getTag = blam.getTag
local uiWidgetDefinition = blam.uiWidgetDefinition
local unicodeStringList = blam.unicodeStringList
local isNull = blam.isNull
local glue = require "glue"
local core = require "insurrection.core"
local harmony = require "mods.harmony"
local createBezierCurve = harmony.math.create_bezier_curve
local bezierCurve = harmony.math.get_bezier_curve_point

---@class uiComponent
local components = {
    ---@type number
    tagId = nil,
    ---@type tag
    tag = nil,
    ---@type uiWidgetDefinition
    widgetDefinition = nil,
    ---@type uiComponentEvents
    events = {},
    ---@type boolean
    isBackgroundAnimated = false,
    ---@type '"generic"' | '"list"' | '"button"' | '"checkbox"' | '"slider"' | '"dropdown"' | '"text"' | '"image"'
    type = "generic",
    ---@type table<string, widgetAnimation>
    animations = {}
}

---@class uiComponentEvents
---@field onClick fun(value?: string | boolean | number):boolean | nil
---@field onFocus function | nil
---@field onOpen function | nil
---@field onClose function | nil
---@field animate function | nil

---@type table<number, uiComponent>
components.widgets = {}

---@param tagId number
---@return uiComponent
function components.new(tagId)
    local instance = setmetatable({}, {__index = components}) --[[@as uiComponent]]
    instance.tagId = tagId
    instance.tag = getTag(instance.tagId) or error("Invalid tagId") --[[@as tag]]
    instance.selectedWidgetTagId = nil
    instance.widgetDefinition = uiWidgetDefinition(tagId) or error("Invalid tagId") --[[@as uiWidgetDefinition]]
    instance.events = {}
    instance.isBackgroundAnimated = false
    -- dprint("Created component: " .. instance.tag.path, "info")
    components.widgets[tagId] = instance
    return instance
end

---@param self uiComponent
function components.onFocus(self, callback)
    self.events.onFocus = callback
end

---@param self uiComponent
---@return string
function components.getText(self)
    local virtualValue = VirtualInputValue[self.tagId]
    if virtualValue then
        return virtualValue
    end
    local unicodeStrings = blam.unicodeStringList(self.widgetDefinition.unicodeStringListTag)
    if unicodeStrings then
        return unicodeStrings.stringList[self.widgetDefinition.stringListIndex + 1]
    end
    error("No unicodeStringList found for widgetDefinition")
end

---@param self uiComponent
---@param text string
---@param mask? string
function components.setText(self, text, mask)
    local childUnicodeStrings
    local childWidgetDefinition
    local widgetDefinition = self.widgetDefinition
    if self.widgetDefinition.childWidgetsCount > 0 then
        local childTagId = self.widgetDefinition.childWidgets[1].widgetTag
        childWidgetDefinition = uiWidgetDefinition(childTagId) --[[@as uiWidgetDefinition]]
        childUnicodeStrings = unicodeStringList(childWidgetDefinition.unicodeStringListTag)
    end
    local unicodeStrings = unicodeStringList(self.widgetDefinition.unicodeStringListTag)
    if not (unicodeStrings and not isNull(unicodeStrings)) then
        unicodeStrings = childUnicodeStrings --[[@as unicodeStringList]]
        widgetDefinition = childWidgetDefinition --[[@as uiWidgetDefinition]]
    end
    if not (unicodeStrings and not isNull(unicodeStrings)) then
        error("No unicodeStringList found for widgetDefinition " .. self.tag.path)
    end
    local stringListIndex = widgetDefinition.stringListIndex
    local newStrings = unicodeStrings.stringList
    if mask then
        VirtualInputValue[self.tagId] = text
        newStrings[stringListIndex + 1] = string.rep(mask, #text)
    else
        newStrings[stringListIndex + 1] = text
    end
    unicodeStrings.stringList = newStrings
end

---@param self uiComponent
function components.onOpen(self, callback)
    self.events.onOpen = callback
end

---@param self uiComponent
function components.onClose(self, callback)
    self.events.onClose = callback
end

--[[
    -- Fake menu scrolling
    if lastOpenWidgetTag and
        (lastOpenWidgetTag.id == interface.widgets.lobbyWidgetTag.id or lastOpenWidgetTag.id ==
            interface.widgets.customizationWidgetTag.id) then
        local scroll = tonumber(read_char(0x64C73C + 8))
        if scroll > 0 then
            store:dispatch(actions.scroll(false))
        elseif scroll < 0 then
            store:dispatch(actions.scroll(true))
        end
    end
]]

---@param self uiComponent
function components.animate(self)
    self.isBackgroundAnimated = true
end

function components.free()
    components.widgets = {}
end

---@param self uiComponent
---@return tag[]
function components.getChildWidgetTags(self)
    return glue.map(self.widgetDefinition.childWidgets, function(childWidget)
        if not isNull(childWidget.widgetTag) then
            local tag = getTag(childWidget.widgetTag)
            return tag
        end
    end)
end

---@param self uiComponent
function components.findChildWidgetTag(self, name)
    local childWidgetTags = self:getChildWidgetTags()
    for _, childTag in pairs(childWidgetTags) do
        if childTag.path:find(name, 1, true) then
            return childTag
        end
        local widgetDefinition = uiWidgetDefinition(childTag.id)
        if widgetDefinition then
            for _, childWidget in pairs(widgetDefinition.childWidgets) do
                local tag = getTag(childWidget.widgetTag) --[[@as tag]]
                if not isNull(childWidget.widgetTag) then
                    if tag.path:find(name, 1, true) then
                        return tag
                    end
                end
            end
        end
    end
end

---@param self uiComponent
function components.getType(self)
    return self.type
end

---@param self uiComponent
---@param newWidgetTagId number
function components.replace(self, newWidgetTagId)
    core.replaceWidgetInDom(self.tagId, newWidgetTagId)
end

---@enum bezierCurves
local bezierCurves = {
    ["ease in"] = createBezierCurve("ease in"),
    ["ease out"] = createBezierCurve("ease out"),
    ["ease in out"] = createBezierCurve("ease in out")
}

---@class widgetAnimation
---@field finished boolean
---@field timestamp number?
---@field play fun()

---Setup an animation to apply to a widget
---@param duration number Duration of the animation in seconds
---@param property '"horizontal"' | '"vertical"' | '"opacity"' | string Property to animate (e.g. "opacity")
---@param originalOffset number Original offset of the widget
---@param offset number Offset to apply to the widget
---@param bezier? bezierCurves Bezier curve to use, e.g. "ease in"
function components.setAnimation(self, duration, property, originalOffset, offset, bezier)
    local targetWidgetTagId = self.tagId
    local animationId = targetWidgetTagId .. property
    self.animations[animationId] = {
        finished = false,
        timestamp = nil,
        play = function()
            console_out("Playing animation " .. animationId)
            local originalOffset = originalOffset
            local bezierCurveHandle = bezierCurves[bezier] or bezierCurves["ease in"]
            if not self.animations[animationId].timestamp then
                self.animations[animationId].timestamp = harmony.time.set_timestamp()
            end
            local elapsed = harmony.time.get_elapsed_milliseconds(
                                self.animations[animationId].timestamp) / 1000
            self.animations[animationId].elapsed = elapsed
            -- console_out(elapsed)
            -- console_out(duration)
            if (elapsed >= duration) then

                if property == "horizontal" then
                    core.setWidgetValues(targetWidgetTagId, {left_bound = offset})
                elseif property == "vertical" then
                    core.setWidgetValues(targetWidgetTagId, {top_bound = offset})
                else
                    core.setWidgetValues(targetWidgetTagId, {opacity = offset})
                end

                self.animations[animationId].timestamp = nil
                self.animations[animationId].finished = true
                return
            end

            local t = (elapsed / duration)
            local newPosition = bezierCurve(bezierCurveHandle, originalOffset, offset, t)
            if property == "horizontal" then
                core.setWidgetValues(targetWidgetTagId, {left_bound = math.floor(newPosition)})
            elseif property == "vertical" then
                core.setWidgetValues(targetWidgetTagId, {top_bound = math.floor(newPosition)})
            else
                core.setWidgetValues(targetWidgetTagId, {opacity = newPosition})
            end
        end
    }
end

---@param self uiComponent
---@return table?
function components.getWidgetValues(self)
    if core.getWidgetHandle(self.tagId) then
        return core.getWidgetValues(self.tagId)
    end
end

---@param self uiComponent
---@param values table
function components.setWidgetValues(self, values)
    core.setWidgetValues(self.tagId, values)
end

return components

end,

["insurrection.components.checkbox"] = function()
--------------------
-- Module: 'insurrection.components.checkbox'
--------------------
local core = require "insurrection.core"
local components = require "insurrection.components"

---@class uiComponentCheckboxClass : uiComponent
local checkbox = setmetatable({
    ---@type number
    checkboxTagId = nil
}, {__index = components})

---@class uiComponentCheckboxEvents : uiComponentEvents
---@field onToggle fun(value: boolean):boolean | nil

---@class uiComponentCheckbox : uiComponentCheckboxClass
---@field events uiComponentCheckboxEvents

---@return uiComponentCheckbox
function checkbox.new(tagId)
    local instance = setmetatable(components.new(tagId), {__index = checkbox}) --[[@as uiComponentCheckbox]]
    assert(instance.tag.path:find("checkbox", 1, true),
           "Tag " .. instance.tag.path .. " is not a checkbox")
    instance.checkboxTagId = instance:findChildWidgetTag("checkbox").id
    return instance
end

---@param self uiComponentCheckbox
---@return boolean
function checkbox.getValue(self)
    local widgetValues = core.getWidgetValues(self.checkboxTagId)
    assert(widgetValues, "Checkbox " .. self.tag.path .. " does not exist in DOM tree")
    return widgetValues.background_bitmap_index == 1
end

function checkbox.setValue(self, value)
    local value = value and 1 or 0
    core.setWidgetValues(self.checkboxTagId, {background_bitmap_index = value})
end

function checkbox.toggle(self)
    local value = self:getValue()
    self:setValue(not value)
end

---@param self uiComponentCheckbox
function checkbox.onToggle(self, callback)
    self.events.onClick = function()
        local value = self:getValue()
        if value then
            self:toggle()
            callback(false)
        else
            self:toggle()
            callback(true)
        end
    end
end

return checkbox

end,

["insurrection.components.button"] = function()
--------------------
-- Module: 'insurrection.components.button'
--------------------
local core = require "insurrection.core"
local components = require "insurrection.components"

---@class uiComponentButtonClass : uiComponent
local button = setmetatable({}, {__index = components})

---@class uiComponentButtonEvents : uiComponentEvents
---@field onClick fun(value?: string | boolean | number):boolean | nil

---@class uiComponentButton : uiComponentButtonClass
---@field events uiComponentCheckboxEvents

---@param tagId number
---@return uiComponentButton
function button.new(tagId)
    local instance = setmetatable(components.new(tagId), {__index = button}) --[[@as uiComponentButton]]
    return instance
end

---@param self uiComponentButton
function button.onClick(self, callback)
    self.events.onClick = callback
end

return button

end,

["insurrection.components.input"] = function()
--------------------
-- Module: 'insurrection.components.input'
--------------------
local components = require "insurrection.components"

---@class uiComponentInputClass : uiComponent
local input = setmetatable({}, {__index = components})

---@class uiComponentInputEvents : uiComponentEvents
---@field onInputText fun(text: string) | nil

---@class uiComponentInput : uiComponentInputClass
---@field events uiComponentInputEvents

---@param tagId number
---@return uiComponentInput
function input.new(tagId)
    local instance = setmetatable(components.new(tagId), {__index = input}) --[[@as uiComponentInput]]
    return instance
end

---@param self uiComponentInput
function components.onInputText(self, callback)
    if self.widgetDefinition.type == 1 then
        self.events.onInputText = callback
    else
        error("onInputText can only be used on uiWidgetDefinition of type 1")
    end
end

return input

end,

["insurrection.components.list"] = function()
--------------------
-- Module: 'insurrection.components.list'
--------------------
local isNull = require"blam".isNull
local components = require "insurrection.components"
local button = require "insurrection.components.button"
local core = require "insurrection.core"
local glue = require "glue"

---@class uiComponentListClass : uiComponent
local list = setmetatable({
    ---@type number
    firstWidgetIndex = nil,
    ---@type number
    lastWidgetIndex = nil,
    ---@type number
    currentItemIndex = 1,
    ---@type number
    lastSelectedItemIndex = nil,
    ---@type uiComponentListItem[]
    items = {},
    ---@type uiWidgetDefinitionChild[]
    backupChildWidgets = {},
    ---@type boolean
    isScrollable = true
}, {__index = components})

---@class uiComponentListItem 
---@field label string
---@field value string | boolean | number | any
---@field bitmap? number | fun(uiComponent: uiComponent)

---@class uiComponentListEvents : uiComponentEvents
---@field onSelect fun(item: uiComponentListItem)

---@class uiComponentList : uiComponentListClass
---@field events uiComponentListEvents

---@param tagId number
---@return uiComponentList
function list.new(tagId, firstWidgetIndex, lastWidgetIndex)
    local instance = setmetatable(components.new(tagId), {__index = list}) --[[@as uiComponentList]]
    instance.firstWidgetIndex = firstWidgetIndex or 1
    instance.lastWidgetIndex = lastWidgetIndex or instance.widgetDefinition.childWidgetsCount
    return instance
end

---@param self uiComponentList
---@param callback fun(item: uiComponentListItem)
function list.onSelect(self, callback)
    self.events.onSelect = callback
end

---@param self uiComponentList
function list.scroll(self, direction)
    local itemIndex = self.currentItemIndex + direction
    if itemIndex < 1 then
        itemIndex = 1
    elseif itemIndex > #self.items then
        itemIndex = #self.items
    end
    dprint("Scrolling list to item " .. itemIndex)
    self.currentItemIndex = itemIndex
    self:refresh()
end

---@param self uiComponentList
function list.refresh(self)
    local items = self.items
    local itemIndex = self.currentItemIndex
    local widgetDefinition = self.widgetDefinition
    local firstWidgetIndex = self.firstWidgetIndex
    local lastWidgetIndex = self.lastWidgetIndex
    if self.isScrollable then
        firstWidgetIndex = firstWidgetIndex + 1
        lastWidgetIndex = lastWidgetIndex - 1
    end
    for widgetIndex = firstWidgetIndex, lastWidgetIndex do
        local item = items[itemIndex]
        local childWidget = widgetDefinition.childWidgets[widgetIndex]
        if item then
            core.setWidgetValues(childWidget.widgetTag, {opacity = 1})
            if childWidget and not isNull(childWidget.widgetTag) then
                local listButton = button.new(childWidget.widgetTag)
                if item.label then
                    listButton:setText(item.label)
                end
                local onSelect = self.events.onSelect
                -- TODO Check if we need to apply a select event even if no onSelect callback is provided
                if onSelect then
                    local lastSelectedItemIndex = itemIndex
                    listButton:onClick(function()
                        self.lastSelectedItemIndex = lastSelectedItemIndex
                        onSelect(item)
                    end)
                end
                if item.bitmap then
                    if type(item.bitmap) == "number" then
                        -- TODO We might need to animate bitmaps when selected by a function
                        listButton:animate()
                        listButton.widgetDefinition.backgroundBitmap = item.bitmap --[[@as number]]
                    elseif type(item.bitmap) == "function" then
                        item.bitmap(listButton)
                    end
                end
                itemIndex = itemIndex + 1
            end
        else
            core.setWidgetValues(childWidget.widgetTag, {opacity = 0})
        end
    end
end

---@param self uiComponentList
---@param items uiComponentListItem[]
function list.setItems(self, items)
    local widgetDefinition = self.widgetDefinition
    if not widgetDefinition.type == 3 then
        error("setItems can only be used on uiWidgetDefinition of type column_list")
    end
    -- if not (#items > 0) then
    --    error("setItems requires at least one item")
    -- end
    if not self.backupChildWidgets then
        self.backupChildWidgets = glue.map(widgetDefinition.childWidgets, function(childWidget)
            return {
                widgetTag = childWidget.widgetTag,
                name = childWidget.name,
                customControllerIndex = childWidget.customControllerIndex,
                verticalOffset = childWidget.verticalOffset,
                horizontalOffset = childWidget.horizontalOffset
            }
        end)
    end
    self.items = items
    if self.currentItemIndex > #items then
        self.currentItemIndex = 1
    end
    if self.isScrollable then
        local firstWidgetTagId = widgetDefinition.childWidgets[self.firstWidgetIndex].widgetTag
        local lastWidgetTagId = widgetDefinition.childWidgets[self.lastWidgetIndex].widgetTag
        local firstWidget = button.new(firstWidgetTagId)
        local lastWidget = button.new(lastWidgetTagId)
        firstWidget:onClick(function()
            self:scroll(-1)
        end)
        lastWidget:onClick(function()
            self:scroll(1)
        end)
    end
    self:refresh()
end

---@param self uiComponentList
function list.getSelectedItem(self)
    dprint(self.lastSelectedItemIndex)
    return self.items[self.lastSelectedItemIndex]
end

---@param self uiComponentList
function list.scrollable(self, isScrollable)
    self.isScrollable = isScrollable
end

return list

end,

["insurrection.components.dynamic.dialog"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.dialog'
--------------------
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local button = require "insurrection.components.button"

return function()
    local dialog = components.new(constants.widgets.dialog.id)
    local dialogBackButton = button.new(dialog:findChildWidgetTag("ok").id)
    dialogBackButton:onClick(function()
        if dialog.events.onClose then
            dialog.events.onClose()
        end
    end)
    shared.dialog = dialog
end

end,

["insurrection.components.dynamic.customizationColorMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.customizationColorMenu'
--------------------
local color = require "color"
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local list = require "insurrection.components.list"
local button = require "insurrection.components.button"
local blam = require "blam"
local core = require "insurrection.core"
local getWidgetValues = core.getWidgetValues
local setWidgetValues = core.setWidgetValues
local glue = require "glue"
local menus = require "insurrection.menus"

return function()
    local customizationColor = components.new(constants.widgets.color.id)

    local optionsId = customizationColor:findChildWidgetTag("options").id
    local customizationColorListOptions = list.new(optionsId)

    local actionsId = customizationColor:findChildWidgetTag("actions").id
    local customizationColorListActions = list.new(actionsId)

    local saveId = customizationColorListActions:findChildWidgetTag("save").id
    local customizationColorSaveButton = button.new(saveId)
    openSettingsMenu = function()
        menus.open(constants.widgets.settings.id)
        return false
    end
    customizationColorSaveButton:onClick(function()
        set_timer(30, "openSettingsMenu")
    end)
    local colorButtons = customizationColorListOptions:getChildWidgetTags()
    updateColorMenu = function()
        local currentColorDescription = components.new(
                                            blam.findTag("current_color_label",
                                                         blam.tagClasses.uiWidgetDefinition).id)
        -- TODO Get this from memory, not from the UI
        -- It seems like this widget is not found by harmony.menu.find_widgets
        -- local currentColorName = blam.readUnicodeString(core.getWidgetValues(
        --                                                    currentColorDescription.tag.id)
        --                                                    .text, true):lower()
        local colorValue = constants.color[currentColorName]
        local menuBiped
        for objectIndex = 1, 2048 do
            menuBiped = blam.getObject(objectIndex)
            if menuBiped and menuBiped.class == blam.objectClasses.scenery then
                local tag = blam.getTag(menuBiped.tagId)
                if tag and tag.path:find "cyborg" then
                    if colorValue then
                        local r, g, b = color.hexToDec(colorValue)
                        menuBiped.colorCLowerRed = r
                        menuBiped.colorCLowerGreen = g
                        menuBiped.colorCLowerBlue = b
                    end
                    break
                end
            end
        end

        for buttonIndex, tag in pairs(colorButtons) do
            if buttonIndex > 1 and buttonIndex < #colorButtons - 1 then
                local colorButton = button.new(tag.id)
                local colorButtonText = button.new(colorButton:findChildWidgetTag("_text").id)
                local colorIcon = button.new(colorButton:findChildWidgetTag("_icon").id)
                local colorName = blam.readUnicodeString(
                                      getWidgetValues(colorButtonText.tag.id).text, true):lower()
                local colorValue = constants.color[colorName]
                if colorValue then
                    local colorIndex = glue.index(constants.colors)[colorValue] - 1
                    setWidgetValues(colorIcon.tag.id, {background_bitmap_index = colorIndex})
                    colorButton:onClick(function()
                        local r, g, b = color.hexToDec(colorValue)
                        menuBiped.colorCLowerRed = r
                        menuBiped.colorCLowerGreen = g
                        menuBiped.colorCLowerBlue = b
                    end)
                end
            else
                local scrollButton = button.new(tag.id)
                scrollButton:onClick(function()
                    set_timer(30, "updateColorMenu")
                end)
            end
        end
        return false
    end
    customizationColor:onOpen(function()
        set_timer(30, "updateColorMenu")
    end)
end

end,

["insurrection.components.dynamic.loginMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.loginMenu'
--------------------
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local button = require "insurrection.components.button"
local core = require "insurrection.core"
local interface = require "insurrection.interface"

return function()
    local login = components.new(constants.widgets.login.id)
    local usernameInput = button.new(login:findChildWidgetTag("username_input").id)
    local passwordInput = button.new(login:findChildWidgetTag("password_input").id)
    login:onOpen(function()
        -- Start discord presence only if script is loaded in the UI map, prevent crashes in other maps
        if map == "ui" then
            discord.startPresence()
        end
    end)
    -- Load login data
    local savedUserName, savedPassword = core.loadCredentials()
    if savedUserName and savedPassword then
        usernameInput:setText(savedUserName)
        passwordInput:setText(savedPassword, "*")
    end
    local loginButton = button.new(login:findChildWidgetTag("login_button").id)
    loginButton:onClick(function()
        local username, password = usernameInput:getText(), passwordInput:getText()
        if username and password and username ~= "" and password ~= "" then
            core.saveCredentials(username, password)
            api.login(username, password)
        else
            interface.dialog("WARNING", "", "Please enter a username and password.")
        end
    end)
    local registerButton = button.new(login:findChildWidgetTag("register_button").id)
    -- dialogBackButton:onClick(function()
    --    os.execute("start https://discord.shadowmods.net")
    --    dialogBackButton:onClick(nil)
    -- end)
    registerButton:onClick(function()
        interface.dialog("INFORMATION", "Join us on our Discord server!",
                         "We have a Discord Bot to help with the registering process:\n\n\nhttps://discord.shadowmods.net")
    end)
end

end,

["insurrection.components.dynamic.dashboardMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.dashboardMenu'
--------------------
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local button = require "insurrection.components.button"
local input = require "insurrection.components.input"
local interface = require "insurrection.interface"

return function()
    local dashboard = components.new(constants.widgets.dashboard.id)
    local createLobbyButton = button.new(dashboard:findChildWidgetTag("create_lobby_button").id)
    createLobbyButton:onClick(function()
        dprint("Create lobby button clicked")
        api.lobby()
    end)
    local joinLobbyButton = button.new(dashboard:findChildWidgetTag("join_lobby_button").id)
    local joinLobbyInput = input.new(dashboard:findChildWidgetTag("lobby_key_input").id)
    joinLobbyButton:onClick(function()
        local lobbyKey = joinLobbyInput:getText()
        if lobbyKey ~= "" then
            api.lobby(lobbyKey)
        else
            interface.dialog("WARNING", "", "Please specify a lobby key to join.")
        end
    end)

    dashboard:onOpen(function()
        execute_script("set_ui_background")
        api.stopRefreshLobby()
        discord.updatePresence("Playing Insurrection", "In the dashboard")
    end)
    dashboard:onClose(function()
        api.stopRefreshLobby()
        discord.updatePresence("Playing Insurrection", "In the main menu")
    end)
end

end,

["insurrection.components.dynamic.lobbyMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.lobbyMenu'
--------------------
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local button = require "insurrection.components.button"
local list = require "insurrection.components.list"
local input = require "insurrection.components.input"
local blam = require "blam"

return function()
    local lobby = components.new(constants.widgets.lobby.id)
    local lobbySummary = components.new(
                             components.new(lobby:findChildWidgetTag("summary").id):findChildWidgetTag(
                                 "text").id)

    local lobbyOptions = components.new(lobby:findChildWidgetTag("options").id)
    local lobbyDefs = components.new(lobbyOptions:findChildWidgetTag("definitions").id)
    local lobbyDef1 = button.new(lobbyDefs:findChildWidgetTag("template").id)
    local lobbyDef2 = button.new(lobbyDefs:findChildWidgetTag("map").id)
    local lobbyDef3 = button.new(lobbyDefs:findChildWidgetTag("gametype").id)
    -- local lobbySettings = button.new(lobbyDefs:findChildWidgetTag("settings").id)

    local lobbyElementsList = list.new(lobbyOptions:findChildWidgetTag("elements").id)
    local lobbyMapsList =
        list.new(blam.findTag("lobby_maps", blam.tagClasses.uiWidgetDefinition).id)
    local lobbySearch = input.new(lobbyOptions:findChildWidgetTag("search").id)
    local lobbyPlay = button.new(lobbyOptions:findChildWidgetTag("play").id)
    local lobbyBack = button.new(lobbyOptions:findChildWidgetTag("back").id)

    local lobbyPlayers = list.new(lobby:findChildWidgetTag("players").id)
    lobbyPlayers:scrollable(false)

    shared.lobby = lobby
    shared.lobbySummary = lobbySummary
    shared.lobbyDefs = lobbyDefs
    shared.lobbyDef1 = lobbyDef1
    shared.lobbyDef2 = lobbyDef2
    shared.lobbyDef3 = lobbyDef3
    -- shared.lobbySettings = lobbySettings
    shared.lobbyPlay = lobbyPlay
    shared.lobbyElementsList = lobbyElementsList
    shared.lobbyMapsList = lobbyMapsList
    shared.lobbyPlayers = lobbyPlayers
    shared.lobbySearch = lobbySearch

    lobby:onClose(function()
        api.deleteLobby()
    end)
    lobbyBack:onClick(function()
        lobby.events.onClose()
    end)
end

end,

["insurrection.components.dynamic.customizationMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.customizationMenu'
--------------------
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local button = require "insurrection.components.button"
local list = require "insurrection.components.list"
local utils = require "insurrection.utils"
local glue = require "glue"
local blam = require "blam"

return function()
    local customization = components.new(constants.widgets.customization.id)

    local nameplatesList = list.new(customization:findChildWidgetTag("nameplates_options").id, 1, 9)
    local nameplatePreview = components.new(blam.findTag("nameplate_preview",
                                                         blam.tagClasses.uiWidgetDefinition).id)
    nameplatePreview:animate()
    local saveCustomizationButton = button.new(
                                        customization:findChildWidgetTag("save_customization").id)
    nameplatesList:onSelect(function(item)
        nameplatePreview.widgetDefinition.backgroundBitmap = item.bitmap
    end)
    local sortedNameplates = glue.map(glue.keys(constants.nameplates), function(nameplateId)
        return {value = nameplateId, bitmap = constants.nameplates[nameplateId].id}
    end)
    table.sort(sortedNameplates, function(a, b)
        return a.value < b.value
    end)
    nameplatesList:setItems(sortedNameplates)

    local selectBipedsList = list.new(blam.findTag("select_bipeds",
                                                   blam.tagClasses.uiWidgetDefinition).id)
    local mapsList = list.new(selectBipedsList:findChildWidgetTag("select_map_biped").id)
    local bipedsList = list.new(selectBipedsList:findChildWidgetTag("select_custom_biped").id)
    local customizationTypesList = components.new(customization:findChildWidgetTag("types").id)
    local customizationNameplatesButton = button.new(
                                              customizationTypesList:findChildWidgetTag("nameplates").id)
    customizationNameplatesButton:onClick(function()
        execute_script("set_ui_background")
        selectBipedsList:replace(nameplatesList.tagId)
    end)
    local customizationBipedsButton = button.new(
                                          customizationTypesList:findChildWidgetTag("bipeds").id)

    customizationBipedsButton:onClick(function()
        execute_script("set_customization_background")
        nameplatesList:replace(selectBipedsList.tagId)
        ---@type interfaceState
        local state = store:getState()
        local maps = glue.keys(state.available.customization)
        mapsList:onSelect(function(item)
            dprint("mapsList:onSelect")
            bipedsList:setItems(glue.map(item.value, function(bipedPath)
                return {label = utils.path(bipedPath).name, value = bipedPath}
            end))
        end)
        mapsList:setItems(glue.map(maps, function(map)
            return {label = map, value = state.available.customization[map]}
        end))
        bipedsList:setItems(glue.map(state.available.customization[maps[1]], function(bipedPath)
            return {label = utils.path(bipedPath).name, value = bipedPath}
        end))
        bipedsList:onSelect(function(item)
            dprint("bipedsList:onSelect")
        end)
    end)

    saveCustomizationButton:onClick(function()
        local selectedMapItem = mapsList:getSelectedItem()
        local selectedBipedItem = bipedsList:getSelectedItem()
        local currentNameplateId
        if settings and settings.nameplate then
            currentNameplateId = settings.nameplate
        end
        local selectedNameplateItem = nameplatesList:getSelectedItem() or
                                          {value = currentNameplateId}
        dprint("saveCustomizationButton:onClick")
        dprint(selectedMapItem)
        dprint(selectedBipedItem)
        local nameplate = selectedNameplateItem.value
        local bipeds
        if selectedNameplateItem then
            nameplate = selectedNameplateItem.value
        end
        if selectedMapItem and selectedBipedItem then
            bipeds = {[selectedMapItem.label] = selectedBipedItem.value}
        end
        api.playerProfileEdit({nameplate = nameplate, bipeds = bipeds})
    end)
end

end,

["insurrection.components.dynamic.settingsMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.settingsMenu'
--------------------
local components = require "insurrection.components"
local constants = require "insurrection.constants"
local list = require "insurrection.components.list"
local button = require "insurrection.components.button"
local blam = require "blam"

return function()
    -- Hard code settings description text change, because the game doesn't support it
    local settings = components.new(constants.widgets.settings.id)
    local settingsOptions = list.new(settings:findChildWidgetTag("settings_menu_options").id)
    -- TODO Add extended description widget support to lua-blam
    local settingsDescription = components.new(blam.findTag("settings_elements_description",
                                                            blam.tagClasses.uiWidgetDefinition).id)
    local settingsDescriptionText = components.new(
                                        settingsDescription:findChildWidgetTag(
                                            "settings_elements_description_data").id)
    for i = 1, settingsOptions.widgetDefinition.childWidgetsCount - 1 do
        local childWidget = settingsOptions.widgetDefinition.childWidgets[i]
        local button = button.new(childWidget.widgetTag)
        button:onFocus(function()
            settingsDescriptionText.widgetDefinition.stringListIndex = i - 1
        end)
    end
end

end,

["insurrection.components.dynamic.chimeraMenu"] = function()
--------------------
-- Module: 'insurrection.components.dynamic.chimeraMenu'
--------------------
local components = require "insurrection.components"
local checkbox = require "insurrection.components.checkbox"
local constants = require "insurrection.constants"
local chimera = require "insurrection.mods.chimera"
local interface = require "insurrection.interface"
local blam = require "blam"

return function()
    local chimeraMod = components.new(constants.widgets.chimera.id)
    local chimeraOptions = components.new(chimeraMod:findChildWidgetTag("chimera_mod_options").id)
    local checkboxes = {}
    local config = chimera.getConfiguration() or {}
    local preferences = chimera.getPreferences() or {}
    for i = 1, chimeraOptions.widgetDefinition.childWidgetsCount - 1 do
        local childWidget = chimeraOptions.widgetDefinition.childWidgets[i]
        local check = checkbox.new(childWidget.widgetTag)
        checkboxes[check:getText()] = check
        check:onToggle(function(value)
            local optionName = check:getText()
            local optionsToggle = {
                ["USE VSYNC"] = function(value)
                    config.video_mode.vsync = value and 1 or 0
                    chimera.saveConfiguration(config)
                end,
                ["SHOW FPS"] = function(value)
                    preferences.chimera_show_fps = value and 1 or 0
                    chimera.executeCommand("chimera_show_fps " .. (value and 1 or 0))
                end,
                ["WINDOWED MODE"] = function(value)
                    config.video_mode.windowed = value and 1 or 0
                    chimera.saveConfiguration(config)
                end,
                ["BORDERLESS"] = function(value)
                    config.video_mode.borderless = value and 1 or 0
                    chimera.saveConfiguration(config)
                end,
                ["LOAD MAPS ON RAM"] = function(value)
                    config.memory.enable_map_memory_buffer = value and 1 or 0
                    chimera.saveConfiguration(config)
                    interface.dialog("INFORMATION", "You have changed a critical Chimera setting.",
                                     "You need to restart the game for the changes to take effect.")
                end,
                ["ANISOTROPIC FILTER"] = function(value)
                    preferences.chimera_af = value and 1 or 0
                    chimera.executeCommand("chimera_af " .. (value and 1 or 0))
                end,
                ["BLOCK BUFFERING"] = function(value)
                    preferences.chimera_block_buffering = value and 1 or 0
                    chimera.executeCommand("chimera_block_buffering " .. (value and 1 or 0))
                end,
                ["BLOCK HOLD F1 AT START"] = function(value)
                    preferences.chimera_block_hold_f1 = value and 1 or 0
                    chimera.executeCommand("chimera_block_hold_f1 " .. (value and 1 or 0))
                end,
                ["BLOCK LOADING SCREEN"] = function(value)
                    preferences.chimera_block_loading_screen = value and 1 or 0
                    chimera.executeCommand("chimera_block_loading_screen " .. (value and 1 or 0))
                end,
                ["BLOCK ZOOM BLUR"] = function(value)
                    preferences.chimera_block_zoom_blur = value and 1 or 0
                    chimera.executeCommand("chimera_block_zoom_blur " .. (value and 1 or 0))
                end,
                ["BLOCK MOUSE ACCELERATION"] = function(value)
                    preferences.chimera_block_mouse_acceleration = value and 1 or 0
                    chimera.executeCommand("chimera_block_mouse_acceleration " .. (value and 1 or 0))
                end,
                ["DEVMODE"] = function(value)
                    preferences.chimera_devmode = value and 1 or 0
                    chimera.executeCommand("chimera_devmode " .. (value and 1 or 0))
                end,
                ["SHOW BUDGET"] = function(value)
                    preferences.chimera_budget = value and 1 or 0
                    chimera.executeCommand("chimera_budget " .. (value and 1 or 0))
                end
            }
            if optionsToggle[optionName] then
                optionsToggle[optionName](value)
            end
        end)
    end
    chimeraMod:onOpen(function()
        config = chimera.getConfiguration() or {}
        preferences = chimera.getPreferences() or {}
        local optionsMapping = {
            ["USE VSYNC"] = config.video_mode.vsync,
            ["SHOW FPS"] = preferences.chimera_show_fps,
            ["WINDOWED MODE"] = config.video_mode.windowed,
            ["BORDERLESS"] = config.video_mode.borderless,
            ["LOAD MAPS ON RAM"] = config.memory.enable_map_memory_buffer,
            ["ANISOTROPIC FILTER"] = preferences.chimera_af,
            ["BLOCK BUFFERING"] = preferences.chimera_block_buffering,
            ["BLOCK HOLD F1 AT START"] = preferences.chimera_block_hold_f1,
            ["BLOCK LOADING SCREEN"] = preferences.chimera_block_loading_screen,
            ["BLOCK ZOOM BLUR"] = preferences.chimera_block_zoom_blur,
            ["BLOCK MOUSE ACCELERATION"] = preferences.chimera_block_mouse_acceleration,
            ["DEVMODE"] = preferences.chimera_devmode,
            ["SHOW BUDGET"] = preferences.chimera_budget
        }
        for k, check in pairs(checkboxes) do
            check:setValue(optionsMapping[k] == 1)
        end
    end)
end

end,

["insurrection.interface"] = function()
--------------------
-- Module: 'insurrection.interface'
--------------------
local harmony = require "mods.harmony"
local components = require "insurrection.components"
local menus = require "insurrection.menus"
local checkbox = require "insurrection.components.checkbox"
local button = require "insurrection.components.button"
local list = require "insurrection.components.list"
local translations = require "insurrection.translations"
local utils = require "insurrection.utils"

local openWidget = harmony.menu.open_widget
local playSound = harmony.menu.play_sound
local blam = require "blam"
local actions = require "insurrection.redux.actions"
local core = require "insurrection.core"
local glue = require "glue"
local unicodeStringTag = blam.unicodeStringList
local uiWidgetTag = blam.uiWidgetDefinition
local uiWidgetCollection = blam.uiWidgetCollection
local constants = require "insurrection.constants"
local isGameDedicated = blam.isGameDedicated
local chimera = require "insurrection.mods.chimera"

local interface = {}
interface.shared = {}

shared = interface.shared

function interface.load()
    components.free()
    constants.get()
    if script_type ~= "global" then
        interface.dialog("WARNING", "This script must be loaded as a global script.",
                         "Please move it to the global scripts folder and restart the game.")
    end
    IsUICompatible = true
    if IsUICompatible then

        dprint("Overriding Chimera font...")
        chimera.fontOverride()

        dprint("Checking if lobby is active...")
        if api.session.lobbyKey and map == "ui" then
            api.lobby(api.session.lobbyKey)
        end
        -- Start widgets background animation
        dprint("Starting widgets background animation...")
        if BitmapsAnimationTimerId then
            stop_timer(BitmapsAnimationTimerId)
        end
        function On30FPSRate()
            for tagId, component in pairs(components.widgets) do
                if component.isBackgroundAnimated then
                    interface.animateUIWidgetBackground(tagId)
                end
            end
        end
        BitmapsAnimationTimerId = set_timer(33, "On30FPSRate")

        -- Load Insurrection features
        dprint("Loading Insurrection patches...")
        core.loadInsurrectionPatches()

        -- Components initialization
        dprint("Initializing components...")
        interface.loadProfileNameplate()
        core.cleanAllEditableWidgets()

        -- interface.animate()
        if constants.widgets.login then
            require "insurrection.components.dynamic.dialog"()
            require "insurrection.components.dynamic.customizationColorMenu"()
            require "insurrection.components.dynamic.settingsMenu"()
            require "insurrection.components.dynamic.loginMenu"()
            require "insurrection.components.dynamic.dashboardMenu"()
            require "insurrection.components.dynamic.customizationMenu"()
            require "insurrection.components.dynamic.lobbyMenu"()

            local pause = components.new(constants.widgets.pause.id)
            pause:onClose(function()
                interface.blur(false)
            end)

            local tester = components.new(constants.widgets.tester.id)
            local testerAnimTest = components.new(tester:findChildWidgetTag("anim_test").id)
            testerAnimTest:animate()
            testerAnimTest:setAnimation(0.6, "horizontal", 100, 300, "ease in")
        end

        if constants.widgets.chimera then
            require "insurrection.components.dynamic.chimeraMenu"()
        end

        -- Insurrection is running outside the UI
        if constants.widgetCollections.multiplayer then
            local multiplayerWidgetsCollection = uiWidgetCollection(
                                                     constants.widgetCollections.multiplayer.id)
            if multiplayerWidgetsCollection then
                local pause = components.new(multiplayerWidgetsCollection.tagList[1])
                if pause then
                    if constants.widgets.pause then
                        dprint("Loading Insurrection UI in external map...")
                        local insurrectionPause = components.new(constants.widgets.pause.id)
                        local resumeButton = button.new(
                                                 insurrectionPause:findChildWidgetTag(
                                                     "resume_game_button").id)
                        local stockResumeButton = button.new(pause:findChildWidgetTag("resume").id)
                        local exitButton = button.new(
                                               insurrectionPause:findChildWidgetTag("exit_button").id)
                        resumeButton:onClick(function()
                            dprint("Resume button clicked")
                            interface.blur(false)
                            interface.sound("back")
                        end)
                        stockResumeButton:onClick(function()
                            dprint("Stock resume button clicked")
                            interface.sound("back")
                        end)
                        exitButton:onClick(function()
                            api.deleteLobby()
                        end)
                        local insurrectionChooseTeam = components.new(constants.widgets.team.id)
                        local blueTeamButton = button.new(
                                                   insurrectionChooseTeam:findChildWidgetTag(
                                                       "blue_team_button").id)
                        local redTeamButton = button.new(
                                                  insurrectionChooseTeam:findChildWidgetTag(
                                                      "red_team_button").id)
                        blueTeamButton:onClick(function()
                            interface.blur(false)
                        end)
                        redTeamButton:onClick(function()
                            interface.blur(false)
                        end)
                        pause:onOpen(function()
                            if not InvalidatePauseOverride then
                                if map ~= "ui" and (isGameDedicated() or DebugMode) then
                                    dprint("Loading Insurrection UI in external map...")
                                    interface.blur(true)
                                    harmony.menu.set_aspect_ratio(16, 9)
                                    menus.pause()
                                end
                            else
                                harmony.menu.set_aspect_ratio(4, 3)
                            end
                            InvalidatePauseOverride = false
                        end)
                        insurrectionPause:onClose(function()
                            interface.blur(false)
                            harmony.menu.set_aspect_ratio(4, 3)
                        end)
                        local openMapPauseButton = button.new(
                                                       insurrectionPause:findChildWidgetTag(
                                                           "open_map_pause").id)
                        openMapPauseButton:onClick(function()
                            interface.blur(false)
                            InvalidatePauseOverride = true
                            menus.open(pause.tagId)
                        end)
                    end
                end

            end
        end

        -- Set up some chimera configs
        if map == "ui" then
            local preferences = chimera.getPreferences() or {}
            local notServerIpBlocking = not preferences.chimera_block_server_ip or
                                            preferences.chimera_block_server_ip == 0
            if notServerIpBlocking then
                interface.shared.dialog:onClose(function()
                    preferences.chimera_block_server_ip = 1
                    chimera.savePreferences(preferences)
                    if not chimera.executeCommand("chimera_block_server_ip 1") then
                        execute_script("quit")
                    end
                end)
                interface.dialog("WARNING", translations.eng.block_server_ips_subtitle,
                                 translations.eng.block_server_ips_message)
            end
        end
    end
end

function interface.loadProfileNameplate(nameplateId)
    if not constants.tagCollections.nameplates then
        dprint("Error, no nameplates collection found", "error")
        return
    end
    local nameplate = components.new(constants.widgets.nameplate.id)
    local nameplatesTagCollection = blam.tagCollection(constants.tagCollections.nameplates.id)
    if nameplatesTagCollection then
        local nameplateBitmapTags = {}
        for _, tagId in ipairs(nameplatesTagCollection.tagList) do
            local tag = blam.getTag(tagId) --[[@as tag]]
            local nameplateId = core.getTagName(tag.path)
            if nameplateId and not nameplateBitmapTags[nameplateId] then
                nameplateBitmapTags[nameplateId] = tag
            end
        end
        nameplate:animate()
        if nameplateId then
            if not nameplateBitmapTags[nameplateId] then
                dprint("Invalid nameplate id: " .. nameplateId, "warning")
                return
            end
            nameplate.widgetDefinition.backgroundBitmap = nameplateBitmapTags[nameplateId].id
            return
        end

        local settings = core.loadSettings()
        if settings and settings.nameplate and nameplateBitmapTags[settings.nameplate] then
            nameplate.widgetDefinition.backgroundBitmap = nameplateBitmapTags[settings.nameplate].id
        end
    end
end

---Animates UI elements by animating background bitmap
---@param widgetTagId number
function interface.animateUIWidgetBackground(widgetTagId)
    local isUIRendering = core.getRenderedUIWidgetTagId()
    if isUIRendering then
        local widgetRender = interface.getWidgetValues(widgetTagId)
        if widgetRender then
            local widgetBitmap = blam.bitmap(uiWidgetTag(widgetTagId).backgroundBitmap)
            if widgetBitmap then
                if widgetBitmap.bitmapsCount > 1 then
                    if widgetRender.background_bitmap_index < widgetBitmap.bitmapsCount then
                        interface.setWidgetValues(widgetTagId, {
                            background_bitmap_index = widgetRender.background_bitmap_index + 1
                        })
                    else
                        interface.setWidgetValues(widgetTagId, {background_bitmap_index = 0})
                    end
                end
            end
        end
    end
end

---Show a dialog message on the screen
---@param titleText '"WARNING"' | '"INFORMATION"' | '"ERROR"' | string
---@param subtitleText string
---@param bodyText string
function interface.dialog(titleText, subtitleText, bodyText)
    if constants.sounds then
        if titleText == "WARNING" or titleText == "ERROR" then
            playSound(constants.sounds.error.path)
        else
            playSound(constants.sounds.success.path)
        end
    end
    local dialog = shared.dialog

    local title = components.new(dialog:findChildWidgetTag("title").id)
    title:setText(titleText)

    local subtitle = components.new(dialog:findChildWidgetTag("subtitle").id)
    subtitle:setText(subtitleText)

    local body = components.new(dialog:findChildWidgetTag("text").id)
    body:setText(bodyText)

    if titleText == "ERROR" then
        openWidget(constants.widgets.dialog.id, false)
    else
        openWidget(constants.widgets.dialog.id, true)
    end
end

---Play a special interface sound
---@param sound '"error"' | '"success"' | '"back"' | '"join"' | '"leave"'
function interface.sound(sound)
    if sound == "error" then
        playSound(constants.sounds.error.id)
    elseif sound == "success" then
        playSound(constants.sounds.success.id)
    elseif sound == "back" then
        playSound(constants.sounds.back.id)
    elseif sound == "join" then
        playSound(constants.sounds.join.id)
    elseif sound == "leave" then
        playSound(constants.sounds.leave.id)
    else
        dprint("Invalid sound: " .. sound, "error")
    end
end

function interface.lobbyInit()
    local time = os.clock()
    ---@type interfaceState
    local state = store:getState()

    local isPlayerLobbyOwner = api.session.player and api.session.player.publicId ==
                                   state.lobby.owner

    local summary = shared.lobbySummary
    local template = shared.lobbyDef1
    local map = shared.lobbyDef2
    local gametype = shared.lobbyDef3
    local play = shared.lobbyPlay
    local elementsList = shared.lobbyElementsList
    local mapsList = shared.lobbyMapsList
    local mapPreview = components.new(blam.findTag("map_small_preview",
                                                   blam.tagClasses.uiWidgetDefinition).id)
    local playersList = shared.lobbyPlayers
    local search = shared.lobbySearch
    summary:setText("Play with your friends, define your rules and enjoy.")

    if not isPlayerLobbyOwner then
        core.setWidgetValues(elementsList.tagId, {opacity = 0})
        core.setWidgetValues(search.tagId, {opacity = 0})
        core.setWidgetValues(play.tagId, {opacity = 0})
    end

    template:setText(state.lobby.template)
    map:setText(state.lobby.map)
    gametype:setText(state.lobby.gametype)

    if isPlayerLobbyOwner then
        elementsList:onSelect(function(item)
            item.value:setText(item.label)
            api.editLobby(api.session.lobbyKey, {
                template = template:getText(),
                map = map:getText(),
                gametype = gametype:getText()
            })
        end)
        mapsList:onSelect(function(item)
            item.value:setText(item.label)
            api.editLobby(api.session.lobbyKey, {
                template = template:getText(),
                map = map:getText(),
                gametype = gametype:getText()
            })
            mapPreview.widgetDefinition.backgroundBitmap = constants.bitmaps.unknownMapPreview.id
            local mapCollection = blam.tagCollection(constants.tagCollections.maps.id)
            for k, v in pairs(mapCollection.tagList) do
                local bitmapTag = blam.getTag(v) --[[@as tag]]
                local mapName = core.getTagName(bitmapTag.path):lower()
                if mapName == item.label:lower() then
                    mapPreview.widgetDefinition.backgroundBitmap = bitmapTag.id
                end
            end
        end)

        local definitionClick = function(lobbyDef, definition)
            search:setText("")
            ---@type interfaceState
            local state = store:getState()
            local component = elementsList
            if definition == "map" then
                component = mapsList
            end
            component:setItems(table.map(state.available[definition .. "s"], function(element)
                ---@type uiComponentListItem
                local item = {label = element, value = lobbyDef}
                if definition ~= "map" then
                    local gametypeIcons = {
                        "unknown",
                        "assault",
                        "ctf",
                        "forge",
                        "infection",
                        "juggernaut",
                        "king",
                        "oddball",
                        "race",
                        "slayer",
                        "team_slayer"
                    }
                    item.bitmap = function(uiComponent)
                        local icon = component.new(uiComponent:findChildWidgetTag("button_icon").id)
                        local iconToUse = table.find(gametypeIcons, function(icon)
                            if element:find(icon, 1, true) then
                                return true
                            end
                            return false
                        end)
                        local backgroundBitmapIndex = (table.indexof(gametypeIcons, iconToUse) or 1) - 1
                        if backgroundBitmapIndex then
                            icon:setWidgetValues({
                                background_bitmap_index = backgroundBitmapIndex
                            })
                        end
                    end
                end
                return item
            end))
            store:dispatch(actions.setLobbyDefinition(definition))
        end

        template:onClick(function()
            definitionClick(template, "template")
            mapsList:replace(elementsList.tagId)
        end)
        -- Force selection of template at start
        template.events.onClick()
        template:onFocus(function()
            summary:setText(
                "Template defines a set of changes to the base server that will be applied when the lobby is created.")
        end)

        map:onClick(function()
            definitionClick(map, "map")
            elementsList:replace(mapsList.tagId)
        end)
        map:onFocus(function()
            summary:setText(
                "Choose a map from the available list to play on, you need to have the map installed.")
        end)

        gametype:onClick(function()
            definitionClick(gametype, "gametype")
            mapsList:replace(elementsList.tagId)
        end)
        gametype:onFocus(function()
            summary:setText(
                "Game type defines the rules of the game, defines team play, scoring, etc.")
        end)

        play:onClick(function()
            if isPlayerLobbyOwner then
                local template = template:getText()
                local map = map:getText()
                local gametype = gametype:getText()
                api.borrow(template:lower(), map, gametype:lower())
            else
                interface.dialog("WARNING", "", "You are not the owner of the lobby.")
            end
        end)

    end

    playersList:setItems(glue.map(state.lobby.players, function(player)
        local nameplateTag = constants.nameplates[player.nameplate] or {}
        return {label = player.name, value = player, bitmap = nameplateTag.id}
    end))

    local definitionsToComponent = {template = template, map = map, gametype = gametype}
    search:onInputText(function(text)
        ---@type interfaceState
        local state = store:getState()
        local definition = state.definition or "template"
        if definition then
            local filtered = {}
            for _, element in pairs(state.available[definition .. "s"]) do
                if element:lower():find(text:lower(), 1, true) then
                    table.insert(filtered, element)
                end
            end
            local component = elementsList
            if definition == "map" then
                component = mapsList
            end
            component:setItems(glue.map(filtered, function(element)
                return {label = element, value = definitionsToComponent[definition]}
            end))
        end
    end)

    if renderedWidgetId then
        dprint(string.format("Interface update time: %.6f\n", os.clock() - time, "warning"))
    end
end

function interface.lobbyUpdate()
    ---@type interfaceState
    local state = store:getState()

    local lobbyDef1 = shared.lobbyDef1
    local lobbyDef2 = shared.lobbyDef2
    local lobbyDef3 = shared.lobbyDef3
    local lobbyPlayers = shared.lobbyPlayers

    local isPlayerLobbyOwner = api.session.player and api.session.player.publicId ==
                                   state.lobby.owner
    if not isPlayerLobbyOwner then
        lobbyDef1:setText(state.lobby.template)
        lobbyDef2:setText(state.lobby.map)
        lobbyDef3:setText(state.lobby.gametype)
    end

    lobbyPlayers:setItems(glue.map(state.lobby.players, function(player)
        local nameplateTag = constants.nameplates[player.nameplate] or {}
        return {label = player.name, value = player, bitmap = nameplateTag.id}
    end))
end

function interface.getWidgetValues(widgetTagId)
    local sucess, widgetInstanceId = pcall(harmony.menu.find_widgets, widgetTagId)
    if sucess and widgetInstanceId then
        return harmony.menu.get_widget_values(widgetInstanceId)
    end
end

function interface.setWidgetValues(widgetTagId, values)
    local sucess, widgetInstanceId = pcall(harmony.menu.find_widgets, widgetTagId)
    if sucess and widgetInstanceId then
        harmony.menu.set_widget_values(widgetInstanceId, values);
    end
end

function interface.animate()
    local introMenuWidgetTag = blam.findTag([[ui\shell\main_menu]],
                                            blam.tagClasses.uiWidgetDefinition)
    local introMenuWidget = blam.uiWidgetDefinition(introMenuWidgetTag.id)
    local mainMenuWidgetTag = blam.findTag([[menus\main\main_menu]],
                                           blam.tagClasses.uiWidgetDefinition)
    local mainMenuWidget = blam.uiWidgetDefinition(mainMenuWidgetTag.id)
    local mainMenuList = blam.uiWidgetDefinition(mainMenuWidget.childWidgets[2].widgetTag)

    local containerId = mainMenuWidgetTag.id
    local widgetToAnimateId = mainMenuWidget.childWidgets[1].widgetTag
    local initial = introMenuWidget.childWidgets[1].verticalOffset
    local final = mainMenuWidget.childWidgets[1].verticalOffset

    interface.animation(introMenuWidget.childWidgets[1].widgetTag, introMenuWidgetTag.id, 0.2,
                        "vertical", final, initial, "ease out", "show")
    -- Animate the main menu widget
    interface.animation(widgetToAnimateId, containerId, 0.2, "vertical", initial, final, "ease out")
    for _, childWidget in pairs(mainMenuList.childWidgets) do
        -- Animate the main menu list widget
        interface.animation(childWidget.widgetTag, containerId, _ * 0.08, "horizontal",
                            childWidget.horizontalOffset - 50, childWidget.horizontalOffset,
                            "ease in", "show")
        interface.animation(childWidget.widgetTag, containerId, _ * 0.08, "opacity", 0, 1)
    end
    local dialogContainer = blam.uiWidgetDefinition(dialogWidgetTag.id)
    interface.animation(dialogWidgetTag.id, dialogWidgetTag.id, 0.2, "opacity", 0, 1)
end

--- Reset widgets animation data
function interface.animationsReset(widgetTagId)
    for _, animation in pairs(WidgetAnimations) do
        if animation.widgetContainerTagId == widgetTagId then
            animation.timestamp = nil
            animation.finished = false
        end
    end
end

function interface.onInputText(widgetTagId, text)
    local component = components.widgets[widgetTagId]
    if component and component.events.onInputText then
        component.events.onInputText(text)
    end
end

function interface.blur(enable)
    if enable then
        execute_script([[(begin
        (show_hud false)
        (cinematic_screen_effect_start true)
        (cinematic_screen_effect_set_convolution 3 1 1 2 0)
        (cinematic_screen_effect_start false)
    )]])
    else
        execute_script([[(begin
            (show_hud true)
            (cinematic_stop)
        )]])
    end
end

return interface

end,

["insurrection.redux.reducers.interfaceReducer"] = function()
--------------------
-- Module: 'insurrection.redux.reducers.interfaceReducer'
--------------------
local redux = require "redux"
local actions = require "insurrection.redux.actions"
local glue = require "glue"
local chunks = glue.chunks

---@class interfaceState
local defaultState = {
    isLoading = false,
    definition = "template",
    lobbyKey = nil,
    available = {maps = {}, gametypes = {}, templates = {}, customization = {}},
    lobby = {
        owner = "",
        map = "",
        gametype = "",
        template = "",
        players = {}
    },
    ---@type table | string | number
    selected = {template = nil, map = nil, gametype = nil},
    displayed = {},
    filtered = {},
    list = {},
    currentChunk = 1,
    chunkSize = 4
}

---Game interface reducer
---@param state interfaceState
---@param action reduxAction
local function interfaceReducer(state, action)
    dprint(action.type, "info")
    if action.type == redux.actionTypes.INIT then
        return glue.deepcopy(defaultState)
    elseif action.type == actions.types.CLEANUP then
        local clean = glue.deepcopy(defaultState)
        clean.available = state.available
        return clean
    elseif action.type == actions.types.SET_IS_LOADING then
        state.isLoading = action.payload
        return state
    elseif action.type == actions.types.SET_AVAILABLE_RESOURCES then
        state.available = action.payload
        dprint(state)
        return state
    elseif action.type == actions.types.SET_LOBBY then
        state.lobbyKey = action.payload.key
        state.lobby = action.payload.lobby
        local available = state.available
        state.chunkSize = 4
        state.currentChunk = 1
        state.list = available[state.definition .. "s"]
        state.displayed = chunks(available.templates, state.chunkSize)[1]
        ---@diagnostic disable-next-line
        state.selected = glue.deepcopy(defaultState.selected)
        state.selected.template = state.lobby.template
        state.selected.map = state.lobby.map
        state.selected.gametype = state.lobby.gametype
        return state
    elseif action.type == actions.types.UPDATE_LOBBY then
        if action.payload.key then
            state.lobbyKey = action.payload.key
        end
        if action.payload.lobby then
            local session = api.session
            if session and not (session.player.publicId == action.payload.lobby.owner) then
                state.selected.template = action.payload.lobby.template
                state.selected.map = action.payload.lobby.map
                state.selected.gametype = action.payload.lobby.gametype
            end
            state.lobby = action.payload.lobby
        end
        if action.payload.filter then
            state.filtered = glue.map(state.available[state.definition .. "s"],
                                      function(mapName)
                if mapName:lower():find(action.payload.filter:lower(), 1, true) then
                    return mapName
                end
            end)
            state.currentChunk = 1
            if state.filtered then
                state.displayed = chunks(state.filtered, 4)[state.currentChunk] or {}
                table.sort(state.displayed, function(a, b)
                    if a and b then
                        return a < b
                    end
                    return false
                end)
            end
        end
        return state
    elseif action.type == actions.types.SET_LOBBY_DEFINITION then
        state.definition = action.payload
        state.list = state.available[state.definition .. "s"]
        state.currentChunk = 1
        state.chunkSize = 4
        state.displayed = chunks(state.list, state.chunkSize)[state.currentChunk]
        return state
    elseif action.type == actions.types.SET_SELECTED_ITEM then
        state.selected = action.payload
        return state
    elseif action.type == actions.types.SET_SELECTED then
        state.selected[state.definition] = action.payload
        return state
    elseif action.type == actions.types.SET_LIST then
        dprint(state)
        state.chunkSize = action.payload.chunkSize or defaultState.chunkSize
        state.currentChunk = 1
        state.list = action.payload.list
        state.displayed = chunks(action.payload.list, state.chunkSize)[state.currentChunk] or {}
        return state
    elseif action.type == actions.types.SCROLL_LIST then
        local list = state.list
        local chunkCount = #chunks(list, state.chunkSize)
        -- Scroll forward
        if not action.payload.scrollNext then
            if (state.currentChunk < chunkCount) then
                state.currentChunk = state.currentChunk + 1
            end
        else
            if (state.currentChunk > 1) then
                state.currentChunk = state.currentChunk - 1
            end
        end
        if (list and #list > 0) then
            local displayed = chunks(list, state.chunkSize)[state.currentChunk]
            if displayed then
                state.displayed = displayed
            end
        end
        return state
    else
        error("Undefined redux action type!")
    end
    return state
end

return interfaceReducer

end,

["insurrection.redux.actions"] = function()
--------------------
-- Module: 'insurrection.redux.actions'
--------------------
local redux = require "redux"
local actions = {}

actions.types = {
    SET_IS_LOADING = "SET_IS_LOADING",
    SET_LOBBY = "SET_LOBBY",
    UPDATE_LOBBY = "UPDATE_LOBBY",
    SET_LOBBY_DEFINITION = "SET_LOBBY_DEFINITION",
    SET_SELECTED = "SET_SELECTED",
    SET_SELECTED_ITEM = "SET_SELECTED_ITEM",
    SCROLL_LIST = "SCROLL_LIST",
    SET_LIST = "SET_LIST",
    SET_AVAILABLE_RESOURCES = "SET_AVAILABLE_RESOURCES",
    CLEANUP = "CLEANUP",
}

function actions.setIsLoading(loading)
    return {type = actions.types.SET_IS_LOADING, payload = loading}
end

function actions.setLobby(key, lobby)
    return {type = actions.types.SET_LOBBY, payload = {key = key, lobby = lobby}}
end

function actions.updateLobby(key, lobby, filter)
    return {
        type = actions.types.UPDATE_LOBBY,
        payload = {key = key, lobby = lobby, filter = filter}
    }
end

---@param definition '"template"' | '"map"' | '"gametype"'
---@return table
function actions.setLobbyDefinition(definition)
    return {type = actions.types.SET_LOBBY_DEFINITION, payload = definition}
end

function actions.setSelected(element)
    return {type = actions.types.SET_SELECTED, payload = element}
end

function actions.setSelectedItem(element)
    return {type = actions.types.SET_SELECTED_ITEM, payload = element}
end

function actions.scroll(scrollNext)
    return {
        type = actions.types.SCROLL_LIST,
        payload = {scrollNext = scrollNext}
    }
end

function actions.setList(list, chunkSize)
    return {type = actions.types.SET_LIST, payload = {list = list, chunkSize = chunkSize}}
end

function actions.reset()
    return {type = redux.actionTypes.INIT}
end

function actions.clean()
    return {type = actions.types.CLEANUP}
end

function actions.setAvailableResources(available)
    return {type = actions.types.SET_AVAILABLE_RESOURCES, payload = available}
end

return actions

end,

["insurrection.redux.store"] = function()
--------------------
-- Module: 'insurrection.redux.store'
--------------------
local createStore = require "redux".createStore
local interfaceReducer = require "insurrection.redux.reducers.interfaceReducer"
local updateInterface = require "insurrection.interface".lobbyInit

local store = createStore(interfaceReducer)
--store:subscribe(updateInterface)

return store
end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
---------------- Auto Bundled Code Block ----------------
---------------------------------------------------------
DebugMode = false
require "insecticide"
local blam = require "blam"
local components = require "insurrection.components"
local constants  = require "insurrection.constants"
local isNull = blam.isNull
local harmony = require "mods.harmony"
local optic = harmony.optic
local chimera = require "insurrection.mods.chimera"
local core = require "insurrection.core"
local interface = require "insurrection.interface"
store = require "insurrection.redux.store"
local ends = require"glue".string.ends
local _, balltze = pcall(require, "mods.balltze")
require "luna"

clua_version = 2.056
-- Import API after setting up debug mode
api = require "insurrection.api"
IsUICompatible = false
math.randomseed(os.time() + ticks())
local gameStarted = false
---@type uiWidgetDefinition?
local editableWidget
---@type tag?
local editableWidgetTag
---@type tag
local lastOpenWidgetTag
---@type tag
local lastClosedWidgetTag
---@type tag
local lastListFocusedWidgetTag
---@type tag
local lastFocusedWidgetTag
-- Multithread lanes
Lanes = {}
-- Stores values that are masked in the UI
VirtualInputValue = {}
-- Stores animations for UI Widgets
WidgetAnimations = {}
ScreenCornerText = ""
LoadingText = nil
local lastMap = ""
local playerCount = 0

discord = require "insurrection.discord"

-- Setup loading orb sprite
local loadingSprite = optic.create_sprite("loading_orb.png", 32, 32)
local rotateOrbAnimation = optic.create_animation(5000)
optic.set_animation_property(rotateOrbAnimation, "linear", "rotation", 360)
local screenWidth, screenHeight = core.getScreenResolution()

---This event will run when at least one tick has passed after the game has loaded.
---
---Allowing you to safely run code that requires a full loaded game state.
local function onPostGameLoad()
    dprint("Game started!", "success")
    if map == "ui" then
        -- Change UI aspect ratio
        harmony.menu.set_aspect_ratio(16, 9)
        -- Disable menu blur
        execute_script("menu_blur_on")
        -- Enable EAX
        execute_script("sound_enable_eax 1")
        execute_script("sound_enable_hardware 1")
        -- Disconnect from server (prevents getting stuck in a server)
        execute_script("disconnect")
        -- Set network timeout to 10 seconds (keeps connection alive at loading huge maps)
        execute_script("network_connect_timeout 30000")
    else
        harmony.menu.set_aspect_ratio(4, 3)
    end
    -- Load insurrection interface, load constants, widgets, etc.
    interface.load()
end

function OnTick()
    -- Post game load event
    if lastMap ~= map then
        gameStarted = false
        lastMap = map
        if not gameStarted then
            gameStarted = true
            onPostGameLoad()
        end
    end
    -- Multithread callback resolve
    for laneIndex, lane in ipairs(Lanes) do
        if lane.thread.status == "done" then
            harmony.menu.block_input(false)
            table.remove(Lanes, laneIndex)
            lane.callback(lane.thread)
            dprint("Async task finished!", "success")
        elseif lane.thread.status == "error" then
            harmony.menu.block_input(false)
            dprint(lane.thread[1], "error")
            table.remove(Lanes, laneIndex)
        else
            dprint(lane.thread.status, "warning")
        end
    end
    if server_type =="dedicated" or server_type == "local" then
        local newPlayerCount = 0
        for playerIndex = 0, 15 do
            local player = blam.player(get_player(playerIndex))
            if player then
                newPlayerCount = newPlayerCount + 1
            end
        end
        if newPlayerCount < playerCount then
            OnPlayerLeave()
        elseif newPlayerCount > playerCount then
            OnPlayerJoin()
        end
        playerCount = newPlayerCount
    end
end

function OnPlayerJoin()
    --interface.sound("join")
end

function OnPlayerLeave()
    --interface.sound("leave")
end

function OnKeypress(modifiers, char, keycode)
    if editableWidget and editableWidgetTag then
        -- Get pressed key from the keyboard
        local pressedKey
        if (char) then
            pressedKey = char
        elseif (keycode) then
            pressedKey = core.translateKeycode(keycode)
        end
        -- If we pressed a key, update our editable widget
        if pressedKey then
            local inputString = core.getStringFromWidget(editableWidgetTag.id)
            local text = core.mapKeyToText(pressedKey, inputString)
            if text then
                if editableWidget.name:find "password" then
                    core.setStringToWidget(text, editableWidgetTag.id, "*")
                else
                    core.setStringToWidget(text, editableWidgetTag.id)
                end
                interface.onInputText(editableWidgetTag.id, text)
            end
        end
    end
end

function OnMenuAccept(widgetInstanceIndex)
    local widgetTagId = harmony.menu.get_widget_values(widgetInstanceIndex).tag_id
    local component = components.widgets[widgetTagId]
    if component then
        if component.events.onClick then
            return not component.events.onClick()
        end
    end
    return true
end

local function onWidgetFocus(widgetTagId)
    local component = components.widgets[widgetTagId]
    if component and component.events.onFocus then
        component.events.onFocus()
    end
    local focusedWidget = blam.uiWidgetDefinition(widgetTagId)
    local tag = blam.getTag(widgetTagId)
    -- TODO Use widget text flags from widget tag instead (add support for that in lua-blam)
    if focusedWidget and ends(focusedWidget.name, "_input") then
        editableWidget = focusedWidget
        editableWidgetTag = tag
    else
        editableWidget = nil
        editableWidgetTag = nil
    end
end

function OnMenuListTab(pressedKey,
                       listWidgetInstanceIndex,
                       previousFocusedWidgetInstanceIndex)
    local listWidgetTagId = harmony.menu.get_widget_values(listWidgetInstanceIndex).tag_id
    local previousFocusedWidgetId = harmony.menu.get_widget_values(
                                        previousFocusedWidgetInstanceIndex).tag_id
    local widgetListTag = blam.getTag(listWidgetTagId) --[[@as tag]]
    local widgetList = blam.uiWidgetDefinition(listWidgetTagId)
    -- local widget = blam.uiWidgetDefinition(previousFocusedWidgetId)
    for childIndex, child in pairs(widgetList.childWidgets) do
        if child.widgetTag == previousFocusedWidgetId then
            local nextChildIndex
            if pressedKey == "dpad up" or pressedKey == "dpad left" then
                if childIndex - 1 < 1 then
                    nextChildIndex = widgetList.childWidgetsCount
                else
                    nextChildIndex = childIndex - 1
                end
            elseif pressedKey == "dpad down" or pressedKey == "dpad right" then
                if childIndex + 1 > widgetList.childWidgetsCount then
                    nextChildIndex = 1
                else
                    nextChildIndex = childIndex + 1
                end
            end
            local widgetTagId = widgetList.childWidgets[nextChildIndex].widgetTag
            if widgetTagId and not isNull(widgetTagId) then
                -- local widgetTag = blam.getTag(widgetTagId)
                onWidgetFocus(widgetTagId)
            end
        end
    end
    return true
end

function OnMouseFocus(widgetInstanceId)
    local widgetTagId = harmony.menu.get_widget_values(widgetInstanceId).tag_id
    local component = components.widgets[widgetTagId]
    if component and component.events.onFocus then
        component.events.onFocus()
    end
    onWidgetFocus(widgetTagId)
    return true
end

function OnFrame()
    local bounds = {left = 0, top = 460, right = 640, bottom = 480}
    local textColor = {1, 1, 1, 1}
    draw_text(ScreenCornerText or "", bounds.left, bounds.top, bounds.right, bounds.bottom, "console",
              "right", table.unpack(textColor))
    -- Draw loading text on the left side of the screen
    if LoadingText then
        draw_text(LoadingText or "", bounds.left + 16, bounds.top, bounds.left + 200, bounds.bottom,
                  "console", "left", table.unpack(textColor))
        optic.render_sprite(loadingSprite, 8, screenHeight - 32 - 8, 255, ticks() * 8, 1,
                            rotateOrbAnimation, optic.create_animation(0))
    end

    -- Process widget animations queue only if we have a widget open
    local widgetTag = core.getCurrentUIWidgetTag()
    --[[
    if widgetTag then
        for _, component in pairs(components.widgets) do
            for _, animation in pairs(component.animations) do
                if not animation.finished then
                    animation.play()
                end
            end
        end
    end]]
end

function OnWidgetOpen(widgetInstanceIndex)
    local widgetExists, widgetValues = pcall(harmony.menu.get_widget_values, widgetInstanceIndex)
    if widgetExists then
        local widgetTagId = widgetValues.tag_id
        local widgetTag = blam.getTag(widgetTagId, blam.tagClasses.uiWidgetDefinition)
        local component = components.widgets[widgetTagId]
        if component and component.events.onOpen then
            component.events.onOpen()
        end

        if widgetTag then
            local widget = blam.uiWidgetDefinition(widgetTag.id)
            if widget and widget.childWidgetsCount > 0 then
                local optionsWidget = blam.uiWidgetDefinition(
                                          widget.childWidgets[widget.childWidgetsCount].widgetTag)
                -- Auto focus on the first editable widget
                if optionsWidget and optionsWidget.childWidgets[1] then
                    onWidgetFocus(optionsWidget.childWidgets[1].widgetTag)
                end

                interface.animationsReset(widgetTag.id)

            end
            if DebugMode then
                ScreenCornerText = widgetTag.path
            end
        end
    end
    return false
end

function OnWidgetClose(widgetInstanceIndex)
    local widgetExists, widgetValues = pcall(harmony.menu.get_widget_values, widgetInstanceIndex)
    if widgetExists then
        local widgetTagId = widgetValues.tag_id
        local component = components.widgets[widgetTagId]
        if component and component.events.onClose then
            component.events.onClose()
        end
        editableWidget = nil
        ScreenCornerText = ""
    end
    return true
end

function OnCommand(command)
    if command == "insurrection_debug" then
        DebugMode = not DebugMode
        console_out("Debug mode: " .. tostring(DebugMode))
        return false
    elseif command == "insurrection_fonts" then
        chimera.setupFonts()
        interface.dialog("SUCCESS", "Fonts have been setup",
                         "Please restart the game to see changes.")
        return false
    elseif command == "insurrection_revert_fonts" then
        chimera.setupFonts(true)
        interface.dialog("SUCCESS", "Fonts have been reverted",
                         "Please restart the game to see changes.")
        return false
    end
end

function OnMapLoad()
    -- Reset post map load state
    gameStarted = false
    lastMap = ""
    -- Reset script state
    editableWidget = nil
    editableWidgetTag = nil
    Lanes = {}
    VirtualInputValue = {}
    WidgetAnimations = {}
    ScreenCornerText = ""
    LoadingText = nil
end

function OnUnload()
    dprint("Unloading Insurrection...")
    discord.stopPresence()
end

---@param mapName string
function OnMapFileLoad(mapName) 
    if balltze then
        balltze.import_tag_data("ui", constants.path.nameplateCollection, "tag_collection")
        balltze.import_tag_data("ui", constants.path.pauseMenu, "ui_widget_definition")
        balltze.import_tag_data("ui", constants.path.dialog, "ui_widget_definition")
        balltze.import_tag_data("ui", constants.path.customSounds, "tag_collection")
    end
end

set_callback("tick", "OnTick")
set_callback("preframe", "OnFrame")
set_callback("command", "OnCommand")
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
harmony.set_callback("widget accept", "OnMenuAccept")
harmony.set_callback("widget list tab", "OnMenuListTab")
harmony.set_callback("widget mouse focus", "OnMouseFocus")
harmony.set_callback("widget close", "OnWidgetClose")
harmony.set_callback("widget open", "OnWidgetOpen")
harmony.set_callback("key press", "OnKeypress")
if balltze then
    balltze.set_callback("map file load", "OnMapFileLoad")
end