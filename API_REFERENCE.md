# Universal Growtopia API — Reference (for LLM / MCP code generation)

Module URL (load this in every generated script):
```
https://raw.githubusercontent.com/Server048/MCP_LUA/refs/heads/main/universal_api.lua
```

Load pattern (always the first line of any generated script):
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/Server048/MCP_LUA/refs/heads/main/universal_api.lua").content)()
```

Target runtime: Lua 5.4, sandboxed, running inside one of three GT mod-menu executors (Bothax / GentaHax / Growlauncher). The module auto-detects which executor is active — **never call executor-native globals directly** (e.g. `GetLocal()`, `getLocal()`, `sendPacket()`). Always go through `M.*`.

---

## HARD RULES (violating these breaks the script)

1. Every loop / blocking logic MUST run inside `M.RunThread(fn)`. Code outside `RunThread` runs once and must return immediately.
2. `M.Sleep(ms)` only works inside `M.RunThread`. Calling it at top level either no-ops or errors.
3. Never call raw executor globals (`GetLocal`, `getLocal`, `SendPacket`, `sendPacket`, `ImGui.*` aside, etc). Only `M.*`.
4. Tile/world coordinates used by `M.GetTile`, `M.Hit`, `M.Place`, `M.Move`, `M.FindPath`, `M.IsTile` are **tile units** (not pixels). Player position fields (`.pos.x`, `.pos.y`) are **pixels** — divide by 32 and `math.floor` to get tile coords.
5. `M.Move(dx, dy)` is RELATIVE to the bot's current tile. `M.MoveTile(x, y)` / `M.FindPath(x, y)` are ABSOLUTE.
6. Every returned struct (player/tile/object/npc) has a `._raw` field containing the original executor object, for accessing fields not covered by this API.
7. `me.gems` is only populated on GentaHax. On Bothax/Growlauncher it is `nil` — always use `M.GetGems()` for gem count, never `me.gems`.
8. `"OnTouch"` hook has no equivalent on Growlauncher — `M.AddHook("OnTouch", ...)` silently no-ops there (logs a warning). Don't rely on it for cross-executor scripts.
9. `M.Hit` / `M.Place` packet fields (`value`, `px`, `py`, `x`, `y`) are confirmed correct on Bothax. Treat as best-effort on GentaHax/Growlauncher.
10. `M.GetExecutor()` returns `"bothax" | "gentahax" | "growlauncher" | "unknown"` — use only for logging/debugging, never branch user-facing logic on it; the whole point of this module is executor-agnostic code.
11. `M.AddHook(event, label, fn)` — `label` must be a unique string per hook; reusing a label overwrites the previous hook silently (on Growlauncher) or may error (on Bothax/GentaHax).
12. `fn` callbacks in `M.AddHook` should `return true` to block/cancel the event, or return nothing to let it pass through.

---

## Function Index

### Diagnostics
| Signature | Returns | Notes |
|---|---|---|
| `M.GetExecutor()` | `string` | `"bothax"\|"gentahax"\|"growlauncher"\|"unknown"` |
| `M.Version()` | `string` | module semver |
| `M.Log(text)` | — | prints to executor console |

### Player
| Signature | Returns | Notes |
|---|---|---|
| `M.GetLocal()` | `Player?` | local player struct |
| `M.GetPlayer(netid)` | `Player?` | by net ID |
| `M.GetPlayerList()` | `Player[]` | all players excluding self |
| `M.GetInventory()` | `{id:number, amount:number, flags:any}[]` | |
| `M.GetGems()` | `number` | always use this, not `me.gems` |

`Player` struct: `{ name:string, pos:{x:number,y:number} (pixels), netid:number, userid:number, country:string, gems:number?, facing:any, invisible:any, _raw:any }`

### World
| Signature | Returns | Notes |
|---|---|---|
| `M.GetWorldName()` | `string` | |
| `M.GetWorld()` | `{name,width,height,_raw}?` | |
| `M.GetTile(x, y)` | `Tile?` | tile coords |
| `M.GetTiles()` | `Tile[]` | all tiles in world |
| `M.GetObjectList()` | `WorldObject[]` | dropped items |
| `M.GetNPCList()` | `NPC[]` | |

`Tile`: `{ fg:number, bg:number, x:number, y:number, collidable:boolean, flags:any, _raw:any }`
`WorldObject`: `{ id:number, pos:{x,y} (pixels), amount:number, oid:any, _raw:any }`
`NPC`: `{ id:any, type:any, pos:{x,y}, _raw:any }`

### Tile Actions
| Signature | Notes |
|---|---|
| `M.Hit(x, y)` | punch/break tile at tile coords (x,y). Alias: `M.Punch(x, y)` |
| `M.Place(x, y, itemID)` | place `itemID` at tile coords (x,y) |

### Movement
| Signature | Notes |
|---|---|
| `M.Move(dx, dy)` | relative move in tiles from current position |
| `M.MoveTile(x, y)` | absolute move to tile (x,y) |
| `M.FindPath(x, y)` | low-level absolute pathfind (same as MoveTile) |
| `M.CheckPath(x, y)` | `boolean` — is tile reachable |
| `M.IsTile(x, y)` | `boolean` — is bot currently standing on tile (x,y) |
| `M.JoinWorld(name)` | warp to world by name |

### Chat / Packets
| Signature | Notes |
|---|---|
| `M.Chat(text)` | send chat message |
| `M.SendPacket(ptype, packet)` | raw text packet (e.g. `M.SendPacket(2, "action|respawn")`) |
| `M.SendPacketRaw(to_client, pkt)` | raw TankPacket table. `to_client=false` → send to server |
| `M.SendVariant(var, netid, delay)` | `var = {[0]="FuncName", [1]=arg, ...}`. `netid` default `-1` (broadcast), `delay` default `0` |

### Hooks
| Signature | Notes |
|---|---|
| `M.AddHook(event, label, fn)` | `event` ∈ `"OnVariant"\|"OnSendPacket"\|"OnSendPacketRaw"\|"OnGamePacket"\|"OnDraw"\|"OnTouch"` |
| `M.RemoveHook(label)` | remove one hook |
| `M.RemoveHooks()` | remove all hooks |

`OnVariant` callback signature: `fn(var, netid)` — `var[0]` is the function name string (e.g. `"OnDialogRequest"`).
`OnDraw` callback signature: `fn(dt)` — use for ImGui rendering.
`OnSendPacket` callback signature: `fn(ptype, packet)`.

### Threading
| Signature | Notes |
|---|---|
| `M.RunThread(fn, ...)` | run `fn` in background thread, extra args forwarded to `fn` |
| `M.Sleep(ms)` | blocking sleep, only valid inside `RunThread` |

### HTTP
| Signature | Returns | Notes |
|---|---|---|
| `M.MakeRequest(url, method?, headers?, body?, timeout?)` | `{status:number?, content:string, error:boolean}` | `method` default `"GET"`, `timeout` default `5000` |

### Item Database
| Signature | Returns |
|---|---|
| `M.GetItemByID(id)` | `ItemInfo?` |
| `M.GetItemByName(name)` | `ItemInfo?` |

---

## Canonical Patterns

### 1. Boilerplate every generated script starts with
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/Server048/MCP_LUA/refs/heads/main/universal_api.lua").content)()
M.Log("Script started on " .. M.GetExecutor())
```

### 2. Any continuous/looping behavior
```lua
M.RunThread(function()
    while true do
        -- logic here
        M.Sleep(500) -- never omit; tight loops without Sleep will freeze/crash
    end
end)
```

### 3. Convert player pixel position → tile coords
```lua
local me = M.GetLocal()
local tx = math.floor(me.pos.x / 32)
local ty = math.floor(me.pos.y / 32)
```

### 4. Move + interact pattern
```lua
M.RunThread(function()
    M.MoveTile(50, 20)
    M.Sleep(800)              -- give pathfinding time to arrive
    M.Hit(50, 21)              -- break tile below
    M.Sleep(300)
    M.Place(50, 21, 8)         -- place dirt
end)
```

### 5. Block a server dialog (hook + return true)
```lua
M.AddHook("OnVariant", "blockDialog", function(var, netid)
    if var[0] == "OnDialogRequest" then
        return true -- blocks it from reaching the executor's UI
    end
end)
```

### 6. ImGui UI loop
```lua
M.AddHook("OnDraw", "ui", function(dt)
    if ImGui.Begin("Window") then
        ImGui.Text("Gems: " .. M.GetGems())
    end
    ImGui.End()
end)
```

### 7. Scan world for an item ID
```lua
local found = {}
for _, tile in pairs(M.GetTiles()) do
    if tile.fg == 242 then table.insert(found, tile) end
end
```

---

## When generating code for this module

- Always start from the boilerplate in Pattern 1.
- Wrap all repeating/blocking logic in `M.RunThread` per Pattern 2.
- Never invent function names not listed in the Function Index above — if a needed capability isn't listed, use `M.SendPacket` / `M.SendPacketRaw` / `M.SendVariant` as the escape hatch, or fall back to `._raw` on a struct.
- Prefer tile-coordinate functions (`M.Hit`, `M.Place`, `M.Move`, `M.GetTile`) over manual pixel math wherever possible.
- Default `M.Sleep` between repeated `M.Hit`/`M.Place` calls to ~150–300ms to avoid spamming packets.
