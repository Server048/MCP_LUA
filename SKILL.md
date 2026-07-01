# SKILL: Generate Growtopia Bot Scripts (Universal API)

## What this skill does
You can generate complete, working Growtopia Lua bot scripts for any task the user describes.
Scripts run inside one of three mod-menu executors (Bothax, GentaHax, Growlauncher) via the
Universal Growtopia API Module (`universal_api.lua`), which normalizes all executor differences.

## Module load (always line 1)
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/Server048/MCP_LUA/refs/heads/main/universal_api.lua").content)()
```

---

## HARD CONSTRAINTS — never violate these

| # | Rule |
|---|------|
| 1 | Every loop / blocking logic MUST be inside `M.RunThread(fn)`. Code outside runs once and must return immediately. |
| 2 | `M.Sleep(ms)` only works inside `M.RunThread`. Never call it at top level. |
| 3 | Never call executor-native globals directly (`GetLocal`, `getLocal`, `SendPacket`, `sendPacket`, etc.). Only `M.*`. |
| 4 | `M.GetTile / M.Hit / M.Place / M.Move / M.FindPath / M.IsTile` use **tile units**. Player `.pos.x/.pos.y` are **pixels** → divide by 32 + floor for tile coords. |
| 5 | `M.Move(dx, dy)` is **relative** (offset from current tile). `M.MoveTile(x,y)` / `M.FindPath(x,y)` are **absolute**. |
| 6 | Use `M.GetGems()` for gem count. `me.gems` is only non-nil on GentaHax. |
| 7 | Hook callback returns `true` to block/cancel the event, returns nothing to pass through. |
| 8 | `M.AddHook` label must be unique per script. Reusing a label silently overwrites. |
| 9 | Put `M.Sleep(150–300)` between repeated `M.Hit`/`M.Place` calls to avoid packet spam. |
| 10 | Never invent function names not in the API below. Use `M.SendPacketRaw` / `._raw` as escape hatch for missing features. |

---

## Full API Reference

### Meta
```
M.GetExecutor() → "bothax"|"gentahax"|"growlauncher"|"unknown"
M.Version()     → semver string
M.Log(text)     → print to executor console
```

### Player structs
`Player = { name:string, pos:{x,y}(pixels), netid, userid, country, gems?, facing, invisible, _raw }`
```
M.GetLocal()            → Player?
M.GetPlayer(netid)      → Player?
M.GetPlayerList()       → Player[]   (excludes self)
M.GetInventory()        → {id, amount, flags}[]
M.GetGems()             → number
```

### World structs
`Tile   = { fg, bg, x, y (tile coords), collidable, flags, _raw }`
`Object = { id, pos:{x,y}(pixels), amount, oid, _raw }`
`NPC    = { id, type, pos:{x,y}, _raw }`
```
M.GetWorldName()        → string
M.GetWorld()            → {name, width, height, _raw}?
M.GetTile(x, y)         → Tile?       (tile coords)
M.GetTiles()            → Tile[]
M.GetObjectList()       → Object[]
M.GetNPCList()          → NPC[]
```

### Tile actions
```
M.Hit(x, y)             -- punch tile (value=18), tile coords
M.Punch(x, y)           -- alias of Hit
M.Place(x, y, itemID)   -- place item at tile coords
```

### Movement
```
M.Move(dx, dy)          -- relative tile offset from current pos
M.MoveTile(x, y)        -- absolute tile (= FindPath)
M.FindPath(x, y)        -- absolute pathfind
M.CheckPath(x, y)       → boolean
M.IsTile(x, y)          → boolean  (is bot standing on this tile right now)
M.JoinWorld(name)       -- warp to world
```

### Chat & Packets
```
M.Chat(text)                          -- send chat message
M.SendPacket(ptype, str)              -- text packet (2=action, 3=input)
M.SendPacketRaw(to_client, pkt)       -- raw TankPacket table
M.SendVariant(var, netid?, delay?)    -- var={[0]="FuncName",[1]=arg,...}
```

### Hooks
```
M.AddHook(event, label, fn)
M.RemoveHook(label)
M.RemoveHooks()
```
Events: `"OnVariant"` `"OnSendPacket"` `"OnSendPacketRaw"` `"OnGamePacket"` `"OnDraw"` `"OnTouch"`

`OnVariant` fn signature: `fn(var, netid)` — `var[0]` = function name string
`OnDraw`    fn signature: `fn(dt)` — for ImGui
`OnSendPacket` fn: `fn(ptype, packet)`

### Threading
```
M.RunThread(fn, ...)    -- run fn in background; extra args forwarded
M.Sleep(ms)             -- blocking wait (inside RunThread only)
```

### HTTP
```
M.MakeRequest(url, method?, headers?, body?, timeout?)
  → { status:number?, content:string, error:boolean }
```

### Item DB
```
M.GetItemByID(id)       → ItemInfo?
M.GetItemByName(name)   → ItemInfo?
```

---

## Canonical Patterns (copy-paste these as base)

### Pattern A — Boilerplate (every script)
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/Server048/MCP_LUA/refs/heads/main/universal_api.lua").content)()
M.Log("Script started | executor: " .. M.GetExecutor())
```

### Pattern B — Loop with Sleep
```lua
M.RunThread(function()
    while true do
        -- your logic here
        M.Sleep(500)
    end
end)
```

### Pattern C — Pixel → Tile conversion
```lua
local me = M.GetLocal()
local tx = math.floor(me.pos.x / 32)
local ty = math.floor(me.pos.y / 32)
```

### Pattern D — Walk to tile then act
```lua
M.RunThread(function()
    M.MoveTile(tx, ty)
    M.Sleep(800)       -- wait to arrive
    M.Hit(tx, ty+1)    -- act on tile below
    M.Sleep(200)
end)
```

### Pattern E — Collect nearest dropped item
```lua
M.RunThread(function()
    while true do
        local me = M.GetLocal()
        local mx = math.floor(me.pos.x/32)
        local my = math.floor(me.pos.y/32)
        local best, bestDist = nil, math.huge
        for _, obj in pairs(M.GetObjectList()) do
            local ox = math.floor(obj.pos.x/32)
            local oy = math.floor(obj.pos.y/32)
            local d  = math.abs(ox-mx) + math.abs(oy-my)
            if d < bestDist and M.CheckPath(ox, oy) then
                best, bestDist = {x=ox,y=oy}, d
            end
        end
        if best then M.FindPath(best.x, best.y) end
        M.Sleep(300)
    end
end)
```

### Pattern F — Hook OnVariant
```lua
M.AddHook("OnVariant", "myHook", function(var, netid)
    if var[0] == "OnDialogRequest" then
        return true  -- block
    end
end)
```

### Pattern G — ImGui UI
```lua
M.AddHook("OnDraw", "ui", function(dt)
    if ImGui.Begin("Title") then
        ImGui.Text("line 1")
        if ImGui.Button("Click") then
            -- action
        end
    end
    ImGui.End()
end)
```

---

## Common Item IDs (reference)
| ID   | Item           |
|------|----------------|
| 2    | Dirt           |
| 8    | Dirt Seed      |
| 18   | (fist / punch value) |
| 242  | World Lock     |
| 1796 | Diamond Lock   |
| 4994 | Magnetic Pole  |
| 5000 | Blue Gem Lock  |

---

## Task → Function Mapping

| User asks for              | Key functions to use                                 |
|----------------------------|------------------------------------------------------|
| Farm / break & replant     | `M.Hit`, `M.Place`, `M.Move`, `M.Sleep`             |
| Collect dropped items      | `M.GetObjectList`, `M.FindPath`, `M.CheckPath`       |
| Find tile in world         | `M.GetTiles` + filter `tile.fg == id`               |
| Auto warp / world travel   | `M.JoinWorld`                                        |
| Show UI overlay            | `M.AddHook("OnDraw", ...)` + `ImGui.*`              |
| Block/intercept packet     | `M.AddHook("OnVariant"/"OnSendPacket", ...)` return true |
| Send chat                  | `M.Chat`                                             |
| Read inventory             | `M.GetInventory`                                     |
| Player radar/proximity     | `M.GetPlayerList` + distance calc                   |
| Get item name from ID      | `M.GetItemByID(id).name`                            |

---

## Output format expected from you (AI)
When generating a script:
1. Always start with Pattern A (boilerplate load)
2. Declare config variables at top (item IDs, world names, intervals) as constants with comments
3. Wrap all logic in `M.RunThread`
4. Always `M.Sleep` inside loops
5. Add `M.Log()` checkpoints so user can see progress in console
6. Comment each logical section
7. End file with a `M.Chat` or `M.Log` confirming script started successfully
