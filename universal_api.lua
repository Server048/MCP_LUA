--[[
    ╔══════════════════════════════════════════════════════════╗
    ║           UNIVERSAL GROWTOPIA API MODULE                 ║
    ║     Compatible: Bothax · GentaHax · Growlauncher         ║
    ║     Version : 1.0.0                                      ║
    ║     Usage   : local M = load(MakeRequest(url).content)() ║
    ╚══════════════════════════════════════════════════════════╝
--]]

local M = {}

-- ════════════════════════════════════════════════════════════
-- §1  EXECUTOR DETECTION
-- ════════════════════════════════════════════════════════════

local function _detect()
    -- Bothax  → uppercase globals + RunThread + LogToConsole
    if type(GetLocal) == "function"
    and type(RunThread) == "function"
    and type(LogToConsole) == "function" then
        return "bothax"
    end
    -- GentaHax → unique getMac / randomMac globals
    if type(getMac) == "function" or type(randomMac) == "function" then
        return "gentahax"
    end
    -- Growlauncher → getWorldTileMap / GetWorldName / log
    if type(getWorldTileMap) == "function"
    or type(GetWorldName) == "function"
    or type(getCurrentWorldName) == "function" then
        return "growlauncher"
    end
    -- Last-resort: lowercase getLocal + log = Growlauncher
    if type(getLocal) == "function" and type(log) == "function" then
        return "growlauncher"
    end
    return "unknown"
end

M.executor = _detect()
local EX    = M.executor   -- shorthand used throughout

-- ════════════════════════════════════════════════════════════
-- §2  INTERNAL NORMALIZERS
-- ════════════════════════════════════════════════════════════

-- Normalize NetAvatar from any executor into a common structure:
--   { name, pos={x,y}, netid, userid, country, gems, facing, invisible, _raw }
local function _normPlayer(p)
    if not p then return nil end
    local px, py = 0, 0
    if p.pos then
        px, py = p.pos.x or 0, p.pos.y or 0
    elseif p.posX then
        px, py = p.posX or 0, p.posY or 0
    end
    return {
        name      = p.name,
        pos       = { x = px, y = py },
        netid     = p.netid  or p.netId  or 0,
        userid    = p.userid or p.userId or 0,
        country   = p.country or "",
        gems      = p.gems,                    -- nil on Bothax/Growlauncher
        facing    = p.isleft or p.facing,
        invisible = p.invisible,
        _raw      = p
    }
end

-- Normalize Tile → { fg, bg, x, y, collidable, flags, _raw }
local function _normTile(t)
    if not t then return nil end
    local tx, ty = 0, 0
    if t.x then
        tx, ty = t.x, t.y
    elseif t.pos then
        tx, ty = t.pos.x or 0, t.pos.y or 0
    end
    return {
        fg        = t.fg or 0,
        bg        = t.bg or 0,
        x         = tx,
        y         = ty,
        collidable = t.collidable or t.isCollideable or false,
        flags     = t.flags,
        _raw      = t
    }
end

-- Normalize WorldObject → { id, pos={x,y}, amount, oid, _raw }
local function _normObject(o)
    if not o then return nil end
    local px, py = 0, 0
    if o.pos then px, py = o.pos.x or 0, o.pos.y or 0 end
    return {
        id     = o.id or o.itemid or o.itemId or 0,
        pos    = { x = px, y = py },
        amount = o.amount or 0,
        oid    = o.oid,
        _raw   = o
    }
end

-- Normalize NPC → { id, type, pos={x,y}, _raw }
local function _normNPC(n)
    if not n then return nil end
    local px, py = 0, 0
    if n.pos     then px, py = n.pos.x or 0,     n.pos.y or 0
    elseif n.current then px, py = n.current.x or 0, n.current.y or 0 end
    return { id = n.id, type = n.type, pos = {x=px, y=py}, _raw = n }
end

local function _mapList(raw, fn)
    local out = {}
    for _, v in pairs(raw or {}) do
        table.insert(out, fn(v))
    end
    return out
end

-- ════════════════════════════════════════════════════════════
-- §3  LOG / CONSOLE
-- ════════════════════════════════════════════════════════════

---Print text to the executor's console.
---@param text any
function M.Log(text)
    text = tostring(text)
    if     EX == "bothax"      then LogToConsole(text)
    elseif EX == "gentahax"    then logToConsole(text)
    elseif EX == "growlauncher" then log(text)
    else   print(text)
    end
end

-- ════════════════════════════════════════════════════════════
-- §4  PLAYER
-- ════════════════════════════════════════════════════════════

---Return the local player as a normalized table.
---@return table {name, pos, netid, userid, country, gems, facing, invisible, _raw}
function M.GetLocal()
    if     EX == "bothax"       then return _normPlayer(GetLocal())
    elseif EX == "gentahax"     then return _normPlayer(getLocal())
    elseif EX == "growlauncher" then return _normPlayer(getLocal())
    end
    return nil
end

---Return a player by netID.
---@param netid number
---@return table|nil
function M.GetPlayer(netid)
    if     EX == "bothax"       then return _normPlayer(GetPlayer(netid))
    elseif EX == "gentahax"     then return _normPlayer(getPlayerByNetID(netid))
    elseif EX == "growlauncher" then return _normPlayer(getPlayerByNetID(netid))
    end
    return nil
end

---Return all players in the world (excluding self).
---@return table[]
function M.GetPlayerList()
    local raw
    if     EX == "bothax"       then raw = GetPlayerList()
    elseif EX == "gentahax"     then raw = getPlayerlist()
    elseif EX == "growlauncher" then raw = getPlayerList()
    else   raw = {}
    end
    return _mapList(raw, _normPlayer)
end

---Return inventory as { id, amount, flags }.
---@return table[]
function M.GetInventory()
    local raw
    if     EX == "bothax"       then raw = GetInventory()
    elseif EX == "gentahax"     then raw = getInventory()
    elseif EX == "growlauncher" then raw = getInventory()
    else   raw = {}
    end
    return _mapList(raw, function(item)
        return { id = item.id, amount = item.amount, flags = item.flags }
    end)
end

---Return local player's gem count.
---@return number
function M.GetGems()
    if EX == "bothax" then
        local info = GetPlayerInfo and GetPlayerInfo()
        return (info and info.gems) or 0
    elseif EX == "gentahax" then
        local me = getLocal()
        return (me and me.gems) or 0
    elseif EX == "growlauncher" then
        return type(getGems) == "function" and getGems() or 0
    end
    return 0
end

-- ════════════════════════════════════════════════════════════
-- §5  WORLD
-- ════════════════════════════════════════════════════════════

---Return the current world name.
---@return string
function M.GetWorldName()
    if EX == "bothax" then
        local w = GetWorld(); return (w and w.name) or ""
    elseif EX == "gentahax" then
        local w = getWorld(); return (w and w.name) or ""
    elseif EX == "growlauncher" then
        if type(GetWorldName)        == "function" then return GetWorldName() end
        if type(getCurrentWorldName) == "function" then return getCurrentWorldName() end
    end
    return ""
end

---Return world info as { name, width, height, _raw }.
---@return table|nil
function M.GetWorld()
    if EX == "bothax" then
        local w = GetWorld()
        return w and { name=w.name, width=w.width, height=w.height, _raw=w }
    elseif EX == "gentahax" then
        local w = getWorld()
        return w and { name=w.name, width=w.width, height=w.height, _raw=w }
    elseif EX == "growlauncher" then
        local name = M.GetWorldName()
        local wm   = type(getWorldTileMap)=="function" and getWorldTileMap() or nil
        return { name=name, width=(wm and wm.x or 0), height=(wm and wm.y or 0), _raw=wm }
    end
    return nil
end

---Return tile data at (x, y) as { fg, bg, x, y, collidable, flags, _raw }.
---@param x number
---@param y number
---@return table|nil
function M.GetTile(x, y)
    if     EX == "bothax"       then return _normTile(GetTile(x, y))
    elseif EX == "gentahax"     then return _normTile(checkTile(x, y))
    elseif EX == "growlauncher" then return _normTile(getTile(x, y))
    end
    return nil
end

---Return ALL tiles in the world.
---@return table[]
function M.GetTiles()
    local raw
    if     EX == "bothax"       then raw = GetTiles()
    elseif EX == "gentahax"     then raw = getTile()    -- no-arg = all tiles
    elseif EX == "growlauncher" then raw = getTiles()
    else   raw = {}
    end
    return _mapList(raw, _normTile)
end

---Return all dropped objects as { id, pos, amount, oid, _raw }.
---@return table[]
function M.GetObjectList()
    local raw
    if     EX == "bothax"       then raw = GetObjectList()
    elseif EX == "gentahax"     then raw = getWorldObject()
    elseif EX == "growlauncher" then raw = getObjectList()
    else   raw = {}
    end
    return _mapList(raw, _normObject)
end

---Return all NPCs as { id, type, pos, _raw }.
---@return table[]
function M.GetNPCList()
    local raw
    if     EX == "bothax"       then raw = GetNPCList()
    elseif EX == "gentahax"     then raw = getNpc()
    elseif EX == "growlauncher" then raw = getNPCList()
    else   raw = {}
    end
    return _mapList(raw, _normNPC)
end

-- ════════════════════════════════════════════════════════════
-- §6  PACKETS
-- ════════════════════════════════════════════════════════════

---Send a text packet to the server.
---@param ptype  number  (2 = generic action, 3 = input)
---@param packet string
function M.SendPacket(ptype, packet)
    if     EX == "bothax"       then SendPacket(ptype, packet)
    elseif EX == "gentahax"     then sendPacket(ptype, packet)
    elseif EX == "growlauncher" then sendPacket(ptype, packet)
    end
end

---Send a raw TankPacket.
---@param to_client boolean  true = inject locally, false = send to server
---@param pkt       table    TankPacket/GameUpdatePacket fields
function M.SendPacketRaw(to_client, pkt)
    if     EX == "bothax"       then SendPacketRaw(to_client, pkt)
    elseif EX == "gentahax"     then sendPacketRaw(to_client, pkt)
    elseif EX == "growlauncher" then sendPacketRaw(to_client, pkt)
    end
end

---Send a VariantList.
---@param var   table  {[0]="FuncName", [1]=arg1, ...}
---@param netid number (default -1 = broadcast)
---@param delay number ms (default 0)
function M.SendVariant(var, netid, delay)
    netid = netid or -1
    delay = delay or 0
    if     EX == "bothax"       then SendVariantList(var, netid, delay)
    elseif EX == "gentahax"     then sendVariant(var, netid, delay)
    elseif EX == "growlauncher" then sendVariant(var, nil, netid, delay)
    end
end

-- ════════════════════════════════════════════════════════════
-- §7  HOOKS
-- ════════════════════════════════════════════════════════════
--[[
  Universal hook event names (use these in M.AddHook):

  "OnVariant"        – variant list received from server
  "OnSendPacket"     – text packet sent to server
  "OnSendPacketRaw"  – raw TankPacket sent
  "OnGamePacket"     – game update packet processed
  "OnDraw"           – ImGui frame render
  "OnTouch"          – world/screen touch

  Mapped internally per executor:
  ┌─────────────────┬─────────────────────┬────────────────────┬──────────────────┐
  │ Universal       │ Bothax              │ GentaHax           │ Growlauncher     │
  ├─────────────────┼─────────────────────┼────────────────────┼──────────────────┤
  │ OnVariant       │ OnVariant           │ OnVarlist          │ onVariant        │
  │ OnSendPacket    │ OnSendPacket        │ OnTextPacket       │ onSendPacket     │
  │ OnSendPacketRaw │ OnSendPacketRaw     │ OnRawPacket        │ onSendPacketRaw  │
  │ OnGamePacket    │ OnProcessTankUpdate │ OnGameUpdatePacket │ onGamePacket     │
  │ OnDraw          │ OnDraw              │ OnRender           │ onDrawImGui      │
  │ OnTouch         │ OnWorldTouch        │ OnTouch            │ (unavailable)    │
  └─────────────────┴─────────────────────┴────────────────────┴──────────────────┘
--]]

local _HOOK_MAP = {
    bothax = {
        OnVariant       = "OnVariant",
        OnSendPacket    = "OnSendPacket",
        OnSendPacketRaw = "OnSendPacketRaw",
        OnGamePacket    = "OnProcessTankUpdate",
        OnDraw          = "OnDraw",
        OnTouch         = "OnWorldTouch",
    },
    gentahax = {
        OnVariant       = "OnVarlist",
        OnSendPacket    = "OnTextPacket",
        OnSendPacketRaw = "OnRawPacket",
        OnGamePacket    = "OnGameUpdatePacket",
        OnDraw          = "OnRender",
        OnTouch         = "OnTouch",
    },
    growlauncher = {
        OnVariant       = "onVariant",
        OnSendPacket    = "onSendPacket",
        OnSendPacketRaw = "onSendPacketRaw",
        OnGamePacket    = "onGamePacket",
        OnDraw          = "onDrawImGui",
        OnTouch         = nil,  -- no equivalent in Growlauncher
    },
}

-- Growlauncher stores multiple callbacks per event in this table
-- { [universalEvent] = { [label] = fn, ... } }
local _gl_cbs = {}

local function _gl_rebuild(event)
    local glEvent = _HOOK_MAP.growlauncher[event]
    if not glEvent or not _gl_cbs[event] then return end
    local handlers = _gl_cbs[event]
    -- Merge all callbacks into one function
    local merged = function(...)
        for _, fn in pairs(handlers) do
            if fn(...) == true then return true end
        end
    end
    addHook(merged, glEvent)
    applyHook()
end

---Register a callback for a universal hook event.
---@param event string  Universal event name (see table above)
---@param label string|number  Unique ID for this hook
---@param fn    function  Callback; return true to block event
function M.AddHook(event, label, fn)
    if EX == "bothax" then
        local mapped = _HOOK_MAP.bothax[event]
        if mapped then AddHook(mapped, label, fn)
        else M.Log("[UAPI] Unknown hook: " .. event) end

    elseif EX == "gentahax" then
        local mapped = _HOOK_MAP.gentahax[event]
        if mapped then AddHook(mapped, label, fn)
        else M.Log("[UAPI] Unknown hook: " .. event) end

    elseif EX == "growlauncher" then
        local glEvent = _HOOK_MAP.growlauncher[event]
        if not glEvent then
            M.Log("[UAPI] Hook '" .. event .. "' not supported on Growlauncher")
            return
        end
        if not _gl_cbs[event] then _gl_cbs[event] = {} end
        _gl_cbs[event][label] = fn
        _gl_rebuild(event)
    end
end

---Remove a hook by its label.
---@param label string|number
function M.RemoveHook(label)
    if EX == "bothax" then
        RemoveHook(label)
    elseif EX == "gentahax" then
        RemoveHook(label)
    elseif EX == "growlauncher" then
        for event, handlers in pairs(_gl_cbs) do
            if handlers[label] then
                handlers[label] = nil
                _gl_rebuild(event)
            end
        end
    end
end

---Remove ALL registered hooks.
function M.RemoveHooks()
    if EX == "bothax" then
        RemoveHooks()
    elseif EX == "gentahax" then
        RemoveHooks()
    elseif EX == "growlauncher" then
        _gl_cbs = {}
        for _, glEvent in pairs(_HOOK_MAP.growlauncher) do
            if glEvent then pcall(removeHook, glEvent) end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- §8  THREADING
-- ════════════════════════════════════════════════════════════

---Run a function in a background thread. All loops must be inside RunThread.
---@param fn   function
---@param ...  any  Arguments passed to fn
function M.RunThread(fn, ...)
    local args = {...}
    local wrapper = function() fn(table.unpack(args)) end
    if EX == "bothax" then
        RunThread(wrapper)
    elseif EX == "gentahax" then
        runThread(wrapper)
    elseif EX == "growlauncher" then
        if type(runThread)  == "function" then runThread(wrapper)
        elseif type(thread) == "function" then thread(wrapper)
        else
            -- Fallback: coroutine (won't yield Sleep but better than nothing)
            local co = coroutine.create(wrapper)
            coroutine.resume(co)
        end
    end
end

---Pause current thread for ms milliseconds. Must be inside RunThread.
---@param ms number
function M.Sleep(ms)
    if     EX == "bothax"       then Sleep(ms)
    elseif EX == "gentahax"     then sleep(ms)
    elseif EX == "growlauncher" then
        if type(sleep) == "function" then sleep(ms) end
    end
end

-- ════════════════════════════════════════════════════════════
-- §9  HTTP
-- ════════════════════════════════════════════════════════════

---Send an HTTP request.
---Returns { status, content, error }
---@param url     string
---@param method  string   (default "GET")
---@param headers table    (default {})
---@param body    string   (default "")
---@param timeout number   ms (default 5000)
---@return table {status, content, error}
function M.MakeRequest(url, method, headers, body, timeout)
    method  = method  or "GET"
    headers = headers or {}
    body    = body    or ""
    timeout = timeout or 5000

    if EX == "bothax" then
        local ok, res = pcall(MakeRequest, url, method, headers, body, timeout)
        if not ok then return { status=0, content="", error=true } end
        return { status=res.status, content=res.content, error=res.error }

    elseif EX == "gentahax" then
        local ok, res = pcall(makeRequest, url, method, headers, body, timeout)
        if not ok then return { status=0, content="", error=true } end
        return { status=nil, content=res.content or "", error=false }

    elseif EX == "growlauncher" then
        local fn = (type(makeRequest)=="function" and makeRequest)
                or (type(MakeRequest)=="function" and MakeRequest)
        if not fn then return { status=0, content="", error=true } end
        local ok, res = pcall(fn, url, method, headers, body, timeout)
        if not ok then return { status=0, content="", error=true } end
        return { status=res.status, content=res.content or "", error=false }
    end

    return { status=0, content="", error=true }
end

-- ════════════════════════════════════════════════════════════
-- §10  TILE ACTIONS (Hit / Place)
-- ════════════════════════════════════════════════════════════
---Low-level tile action packet builder.
---@param x      number  target tile x
---@param y      number  target tile y
---@param value  number  18 = punch/break (fist), otherwise item ID to place
local function _tileAction(x, y, value)
    local me = M.GetLocal()
    local px = math.floor(me.pos.x / 32) + (x or 0)
    local py = math.floor(me.pos.y / 32) + (y or 0)
    M.SendPacketRaw(false, {
        type  = 3,                         -- PACKET_TILE_CHANGE_REQUEST
        value = value or 18,
        px    = px,
        py    = py,
        x     = me and me.pos.x or 0,      -- local player's pixel pos
        y     = me and me.pos.y or 0,
    })
end

---Punch/break the tile at (x, y) with the fist (value 18).
---@param x number
---@param y number
function M.Hit(x, y)
    _tileAction(x, y, 18)
end
M.Punch = M.Hit  -- alias

---Place an item at tile (x, y).
---@param x      number
---@param y      number
---@param itemID number
function M.Place(x, y, itemID)
    _tileAction(x, y, itemID)
end

---Consume an item at tile (x, y).
---@param x      number
---@param y      number
---@param itemID number
function M.Use(x, y, itemID)
    _tileAction(x, y, itemID)
end

-- ════════════════════════════════════════════════════════════
-- §10b  MOVEMENT
-- ════════════════════════════════════════════════════════════
--[[
  M.Move(dx, dy) is RELATIVE to the bot's current tile.
  Example: bot is at tile x=30. M.Move(1, 0)  → walks to x=31 (forward)
                                  M.Move(-1, 0) → walks to x=29 (backward)
  Built on top of M.GetLocal() + M.FindPath().
--]]

---Move relative to current tile position.
---@param dx number  tiles to move on X (+right / -left)
---@param dy number  tiles to move on Y (+down / -up)
function M.Move(dx, dy)
    local me = M.GetLocal()
    if not me then return end
    local tx = math.floor(me.pos.x / 32) + (dx or 0)
    local ty = math.floor(me.pos.y / 32) + (dy or 0)
    M.FindPath(tx, ty)
end

---Move to an absolute tile position (alias of M.FindPath).
---@param x number
---@param y number
function M.MoveTile(x, y)
    M.FindPath(x, y)
end

---Returns true if the bot is currently standing on tile (x, y).
---@param x number
---@param y number
---@return boolean
function M.IsTile(x, y)
    local me = M.GetLocal()
    if not me then return false end
    local tx = math.floor(me.pos.x / 32)
    local ty = math.floor(me.pos.y / 32)
    return tx == x and ty == y
end

-- ════════════════════════════════════════════════════════════
-- §10c  CHAT
-- ════════════════════════════════════════════════════════════

---Send a chat message in-game.
---@param text string
function M.Chat(text)
    M.SendPacket(2, "action|input\n|text|" .. tostring(text))
end

-- ════════════════════════════════════════════════════════════
-- §10d  UTILITY
-- ════════════════════════════════════════════════════════════

---Move the player to tile (x, y) via pathfinding.
---@param x number
---@param y number
function M.FindPath(x, y)
    if     EX == "bothax"       then FindPath(x, y)
    elseif EX == "gentahax"     then findPath(x, y)
    elseif EX == "growlauncher" then FindPath(x, y)
    end
end

---Check if tile (x, y) is pathable. Returns boolean.
---@param x number
---@param y number
---@return boolean
function M.CheckPath(x, y)
    if     EX == "bothax"       then return CheckPath(x, y)
    elseif EX == "gentahax"     then return checkPath(x, y)
    elseif EX == "growlauncher" then return FindPath(x, y, true)
    end
    return false
end

---Warp to a world by name.
---@param name string
function M.JoinWorld(name)
    if EX == "bothax" then
        RequestJoinWorld(name)
    else
        -- GentaHax & Growlauncher don't have a direct call — use packet
        M.SendPacket(2, "action|join_request\nname|" .. name:upper() .. "\ninvitedWorld|0")
    end
end

-- ════════════════════════════════════════════════════════════
-- §11  ITEM DATABASE
-- ════════════════════════════════════════════════════════════

---Return ItemInfo by numeric ID.
---@param id number
---@return table|nil
function M.GetItemByID(id)
    if EX == "bothax" then
        return GetItemByIDSafe and GetItemByIDSafe(id)
    elseif EX == "gentahax" then
        return getItemByID and getItemByID(id)
    elseif EX == "growlauncher" then
        local ns = _G["ItemInfoManager"]
        return ns and type(ns.getItemByID)=="function" and ns.getItemByID(id)
    end
    return nil
end

---Return ItemInfo by exact name.
---@param name string
---@return table|nil
function M.GetItemByName(name)
    if EX == "bothax" then
        return GetItemByName and GetItemByName(name)
    elseif EX == "gentahax" then
        return getItemByName and getItemByName(name)
    elseif EX == "growlauncher" then
        local ns = _G["ItemInfoManager"]
        return ns and type(ns.getItemByName)=="function" and ns.getItemByName(name)
    end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- §12  META
-- ════════════════════════════════════════════════════════════

---Return which executor was detected.
---@return string  "bothax" | "gentahax" | "growlauncher" | "unknown"
function M.GetExecutor()
    return EX
end

---Return module version string.
---@return string
function M.Version()
    return "1.1.1"
end

-- ════════════════════════════════════════════════════════════
-- INIT LOG
-- ════════════════════════════════════════════════════════════
M.Log(string.format("`9[UAPI v%s]`^ Loaded — Executor: `5%s", M.Version(), EX))
M.Log("`2[ DEV ] `^Original Dev Team ToolKIT")
return M
