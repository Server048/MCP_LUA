# 🌐 Universal Growtopia API Module

Satu API, tiga executor. Tulis script sekali — jalan di **Bothax**, **GentaHax**, dan **Growlauncher** tanpa ubah satu baris pun.

---

## ✨ Fitur

- ✅ Auto-detect executor aktif saat script di-load
- ✅ Normalisasi struktur data (player, tile, object, NPC)
- ✅ Unified hook system dengan nama event yang seragam
- ✅ Fallback aman — fungsi yang tidak tersedia di executor tertentu tidak crash
- ✅ Semua fungsi terdokumentasi dengan tipe parameter

---

## 📦 Cara Load

Simpan `universal_api.lua` di GitHub kamu (raw URL), lalu load dari dalam script:

```lua
-- Ganti URL dengan raw URL GitHub kamu
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

-- Siap pakai!
print(M.GetLocal().name)
```

> ⚠️ Pastikan URL adalah **raw** GitHub (raw.githubusercontent.com), bukan halaman HTML-nya.

---

## 🔍 Executor yang Didukung

| Executor     | Deteksi via                          |
|--------------|--------------------------------------|
| Bothax       | `GetLocal` + `RunThread` + `LogToConsole` (uppercase) |
| GentaHax     | `getMac` / `randomMac` (unique global) |
| Growlauncher | `getWorldTileMap` / `GetWorldName` / `log` |

Kamu bisa cek executor yang aktif dengan:
```lua
print(M.GetExecutor())  -- "bothax" | "gentahax" | "growlauncher" | "unknown"
```

---

## 📖 API Reference

### 🔵 Log

```lua
M.Log(text)
```
Print ke console executor yang aktif.

---

### 🧍 Player

```lua
-- Ambil data diri sendiri
local me = M.GetLocal()
print(me.name)       -- string
print(me.pos.x)      -- float (posisi pixel)
print(me.pos.y)      -- float
print(me.netid)      -- number
print(me.userid)     -- number
print(me.country)    -- string
print(me.gems)       -- number | nil (nil di Bothax & Growlauncher)
print(me.facing)     -- boolean (true = facing left)
print(me.invisible)  -- boolean | nil
-- me._raw → objek asli dari executor (untuk akses field eksklusif)
```

```lua
-- Ambil player lain by netID
local p = M.GetPlayer(5)
if p then print(p.name) end
```

```lua
-- Daftar semua player di world (tanpa diri sendiri)
for _, p in pairs(M.GetPlayerList()) do
    print(p.name .. " | pos: " .. p.pos.x//32 .. "," .. p.pos.y//32)
end
```

```lua
-- Inventory
for _, item in pairs(M.GetInventory()) do
    print("id=" .. item.id .. " amt=" .. item.amount)
end
```

```lua
-- Gem count
print("Gems: " .. M.GetGems())
```

---

### 🌍 World

```lua
-- Info world
local w = M.GetWorld()
print(w.name)    -- "STARTNOSEED"
print(w.width)   -- 100
print(w.height)  -- 60
```

```lua
-- Nama world saja
print(M.GetWorldName())
```

```lua
-- Tile di koordinat tertentu
local tile = M.GetTile(10, 20)
print(tile.fg)         -- foreground item ID
print(tile.bg)         -- background item ID
print(tile.x, tile.y)  -- koordinat tile
print(tile.collidable) -- boolean
```

```lua
-- Semua tile
for _, tile in pairs(M.GetTiles()) do
    if tile.fg == 242 then
        print("WL at " .. tile.x .. "," .. tile.y)
    end
end
```

```lua
-- Dropped items di world
for _, obj in pairs(M.GetObjectList()) do
    if obj.id == 242 then
        print("WL dropped at " .. obj.pos.x//32 .. "," .. obj.pos.y//32)
    end
end
```

```lua
-- NPC list
for _, npc in pairs(M.GetNPCList()) do
    print("NPC id=" .. npc.id .. " type=" .. npc.type)
end
```

---

### 📡 Packets

```lua
-- Text packet (paling umum)
M.SendPacket(2, "action|respawn")
M.SendPacket(2, "action|join_request\nname|START\ninvitedWorld|0")
```

```lua
-- Raw TankPacket
M.SendPacketRaw(false, { type = 3, value = 18, x = 320, y = 192 })
-- to_client=false → kirim ke server
-- to_client=true  → inject ke client lokal
```

```lua
-- Variant List
M.SendVariant({[0]="OnTextOverlay", [1]="Hello from UAPI!"}, -1, 0)
```

---

### 🪝 Hooks

#### Nama Event Universal

| Event              | Keterangan                                 |
|--------------------|--------------------------------------------|
| `"OnVariant"`      | Variant list diterima dari server          |
| `"OnSendPacket"`   | Text packet dikirim ke server              |
| `"OnSendPacketRaw"`| Raw TankPacket dikirim                     |
| `"OnGamePacket"`   | Game update packet diproses                |
| `"OnDraw"`         | Frame ImGui render (gunakan untuk UI)      |
| `"OnTouch"`        | Sentuhan di world/layar *(tidak ada di Growlauncher)* |

```lua
-- Daftar hook
M.AddHook("OnVariant", "myVarHook", function(var, netid)
    if var[0] == "OnDialogRequest" then
        return true  -- block dialog
    end
end)

M.AddHook("OnDraw", "myUI", function(dt)
    if ImGui.Begin("Test") then
        ImGui.Text("Hello UAPI!")
    end
    ImGui.End()
end)

M.AddHook("OnSendPacket", "pktLogger", function(type, pkt)
    M.Log("Sent: " .. tostring(pkt))
end)

-- Hapus satu hook
M.RemoveHook("myVarHook")

-- Hapus semua hook
M.RemoveHooks()
```

---

### 🧵 Threading

```lua
-- WAJIB untuk semua loop agar tidak crash
M.RunThread(function()
    while true do
        local me = M.GetLocal()
        M.Log("Pos: " .. me.pos.x//32 .. "," .. me.pos.y//32)
        M.Sleep(1000)
    end
end)
```

```lua
-- RunThread dengan argumen
M.RunThread(function(nama)
    M.Log("Thread jalan: " .. nama)
    M.Sleep(500)
    M.Log("Done!")
end, "TestBot")
```

---

### 🌐 HTTP Request

```lua
local res = M.MakeRequest("https://example.com/api")
-- res.content → string body response
-- res.status  → HTTP status code (nil di GentaHax)
-- res.error   → boolean

if not res.error then
    M.Log("Response: " .. res.content)
end
```

```lua
-- POST dengan body
local res = M.MakeRequest(
    "https://example.com/api",
    "POST",
    {["Content-Type"] = "application/json"},
    '{"key":"value"}',
    5000
)
```

---

### 🗺️ Pathfinding

```lua
-- Gerak ke tile
M.FindPath(20, 10)

-- Cek apakah tile bisa dicapai
if M.CheckPath(20, 10) then
    M.FindPath(20, 10)
end

-- Pindah world
M.JoinWorld("START")
```

---

### 🔨 Tile Actions — Hit / Place

Shortcut untuk aksi punch & place tile, dibangun di atas `M.SendPacketRaw` (packet `TileChangeRequest`, type 3) — gak perlu nulis raw packet manual lagi.

```lua
-- Punch tile di (10, 20)
M.Hit(10, 20)
M.Punch(10, 20)  -- alias, sama saja

-- Place item id 8 (dirt) di (10, 20)
M.Place(10, 20, 8)
```

---

### 🚶 Movement — Move / MoveTile / IsTile

`M.Move(dx, dy)` itu **relatif** terhadap posisi tile bot saat ini (dibangun dari `M.GetLocal()` + `M.FindPath()`).

```lua
-- Bot di tile x=30. Maju 1 tile (x jadi 31)
M.Move(1, 0)

-- Mundur 1 tile (x jadi 29)
M.Move(-1, 0)

-- Naik 1 tile ke atas (y berkurang 1)
M.Move(0, -1)
```

```lua
-- Pindah ke posisi tile ABSOLUT (sama seperti M.FindPath)
M.MoveTile(50, 20)
```

```lua
-- Cek apakah bot sedang berdiri di tile tertentu
if M.IsTile(50, 20) then
    M.Log("Sudah sampai!")
end
```

---

### 💬 Chat

```lua
M.Chat("Halo dari UAPI!")
```

---

### 🎒 Item Database

```lua
local item = M.GetItemByID(242)
if item then print(item.name) end   -- "World Lock"

local dirt = M.GetItemByName("Dirt")
if dirt then print(dirt.id) end     -- 2
```

---

## 💡 Contoh Lengkap

### 1. Script Dasar — Lihat Info Diri Sendiri
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

local me = M.GetLocal()
M.Log("=== INFO ===")
M.Log("Executor : " .. M.GetExecutor())
M.Log("Nama     : " .. me.name)
M.Log("World    : " .. M.GetWorldName())
M.Log("Pos Tile : " .. me.pos.x//32 .. " , " .. me.pos.y//32)
M.Log("Gems     : " .. M.GetGems())
```

---

### 2. Scan World Lock di Map
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

M.Log("Scanning WL...")
local count = 0
for _, tile in pairs(M.GetTiles()) do
    if tile.fg == 242 then
        count = count + 1
        M.Log(string.format("  WL #%d di (%d, %d)", count, tile.x, tile.y))
    end
end
M.Log("Total WL ditemukan: " .. count)
```

---

### 3. Auto Collect Dropped Item
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

local TARGET_ID = 242  -- World Lock

M.RunThread(function()
    M.Log("Auto collect dimulai...")
    while true do
        local me = M.GetLocal()
        if me then
            for _, obj in pairs(M.GetObjectList()) do
                if obj.id == TARGET_ID then
                    local tx = obj.pos.x // 32
                    local ty = obj.pos.y // 32
                    if M.CheckPath(tx, ty) then
                        M.FindPath(tx, ty)
                        M.Sleep(300)
                    end
                end
            end
        end
        M.Sleep(500)
    end
end)
```

---

### 4. ImGui UI + Hook Variant
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

local blockedDialogs = 0

-- Block semua dialog
M.AddHook("OnVariant", "dialogBlocker", function(var, netid)
    if var[0] == "OnDialogRequest" then
        blockedDialogs = blockedDialogs + 1
        return true  -- block
    end
end)

-- ImGui window
M.AddHook("OnDraw", "mainUI", function(dt)
    if ImGui.Begin("UAPI Demo") then
        local me = M.GetLocal()
        if me then
            ImGui.Text("Name  : " .. me.name)
            ImGui.Text("World : " .. M.GetWorldName())
            ImGui.Text("Pos   : " .. me.pos.x//32 .. " , " .. me.pos.y//32)
        end
        ImGui.Separator()
        ImGui.Text("Dialogs blocked: " .. blockedDialogs)
        if ImGui.Button("Join START") then
            M.JoinWorld("START")
        end
    end
    ImGui.End()
end)
```

---

### 5. Cek Player di Sekitar (radius tile)
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

local RADIUS = 5  -- tile

M.RunThread(function()
    while true do
        local me = M.GetLocal()
        if me then
            local mx = me.pos.x // 32
            local my = me.pos.y // 32
            for _, p in pairs(M.GetPlayerList()) do
                local px = p.pos.x // 32
                local py = p.pos.y // 32
                local dist = math.sqrt((px-mx)^2 + (py-my)^2)
                if dist <= RADIUS then
                    M.Log("Player dekat: " .. p.name .. " (dist=" .. string.format("%.1f", dist) .. ")")
                end
            end
        end
        M.Sleep(2000)
    end
end)
```

---

### 6. Auto Farm Tile (Hit + Place + Move)
```lua
local M = load(MakeRequest("https://raw.githubusercontent.com/username/repo/main/universal_api.lua").content)()

local SEED_ID = 8  -- contoh: dirt seed

M.RunThread(function()
    M.Chat("Auto farm dimulai!")
    for i = 1, 5 do
        local tile = M.GetTile(50 + i, 20)
        if tile and tile.fg ~= 0 then
            M.Hit(50 + i, 20)        -- panen / hancurkan tile
            M.Sleep(300)
        end
        M.Place(50 + i, 20, SEED_ID) -- tanam ulang
        M.Sleep(300)
        M.Move(1, 0)                 -- maju 1 tile
        M.Sleep(500)
    end
    M.Chat("Auto farm selesai!")
end)
```

---

## 🗺️ Peta Perbedaan API

| Fungsi Universal     | Bothax            | GentaHax           | Growlauncher          |
|----------------------|-------------------|--------------------|-----------------------|
| `M.Log`              | `LogToConsole`    | `logToConsole`     | `log`                 |
| `M.GetLocal`         | `GetLocal()`      | `getLocal()`       | `getLocal()`          |
| `M.GetPlayer`        | `GetPlayer(id)`   | `getPlayerByNetID` | `getPlayerByNetID`    |
| `M.GetPlayerList`    | `GetPlayerList()` | `getPlayerlist()`  | `getPlayerList()`     |
| `M.GetInventory`     | `GetInventory()`  | `getInventory()`   | `getInventory()`      |
| `M.GetGems`          | `GetPlayerInfo().gems` | `getLocal().gems` | `getGems()`      |
| `M.GetWorld`         | `GetWorld()`      | `getWorld()`       | `getWorldTileMap()`   |
| `M.GetTile(x,y)`     | `GetTile(x,y)`    | `checkTile(x,y)`   | `getTile(x,y)`        |
| `M.GetTiles`         | `GetTiles()`      | `getTile()` (no arg) | `getTiles()`        |
| `M.GetObjectList`    | `GetObjectList()` | `getWorldObject()` | `getObjectList()`     |
| `M.GetNPCList`       | `GetNPCList()`    | `getNpc()`         | `getNPCList()`        |
| `M.SendPacket`       | `SendPacket`      | `sendPacket`       | `sendPacket`          |
| `M.SendPacketRaw`    | `SendPacketRaw`   | `sendPacketRaw`    | `sendPacketRaw`       |
| `M.SendVariant`      | `SendVariantList` | `sendVariant`      | `sendVariant`         |
| `M.AddHook`          | `AddHook`         | `AddHook`          | `addHook`+`applyHook` |
| `M.RunThread`        | `RunThread`       | `runThread`        | `runThread`/coroutine |
| `M.Sleep`            | `Sleep`           | `sleep`            | `sleep`               |
| `M.MakeRequest`      | `MakeRequest`     | `makeRequest`      | `makeRequest`         |
| `M.FindPath`         | `FindPath`        | `findPath`         | `FindPath`            |
| `M.CheckPath`        | `CheckPath`       | `checkPath`        | `FindPath(x,y,true)`  |
| `M.JoinWorld`        | `RequestJoinWorld`| packet             | packet                |
| `M.GetItemByID`      | `GetItemByIDSafe` | `getItemByID`      | `ItemInfoManager`     |
| `M.Hit` / `M.Punch`  | dibangun dari `M.SendPacketRaw` (type 3, item=0) | sama | sama |
| `M.Place`            | dibangun dari `M.SendPacketRaw` (type 3, item=id) | sama | sama |
| `M.Move`             | dibangun dari `M.GetLocal` + `M.FindPath` (relatif) | sama | sama |
| `M.MoveTile`         | alias `M.FindPath` (absolut) | sama | sama |
| `M.IsTile`           | dibangun dari `M.GetLocal` | sama | sama |
| `M.Chat`             | dibangun dari `M.SendPacket(2, ...)` | sama | sama |

---

## ⚠️ Catatan Penting

- **`M.Hit` / `M.Place` / `M.Move` / `M.Chat`** → ini bukan API dari executor manapun, melainkan shorthand yang kita bangun sendiri di atas `SendPacketRaw`/`SendPacket`/`FindPath` yang sudah ada. Penamaan terinspirasi dari konvensi umum (`hit`, `place`, `move`, `chat`) supaya gak perlu nulis raw packet panjang tiap kali mau aksi simpel.
- **`me._raw`** → selalu tersedia di tiap struct. Gunakan untuk akses field eksklusif executor yang tidak ada di API universal.
- **`me.gems`** → hanya tersedia di **GentaHax** (karena sudah ada di NetAvatar). Di Bothax & Growlauncher gunakan `M.GetGems()`.
- **`OnTouch`** → tidak tersedia di Growlauncher. `M.AddHook("OnTouch", ...)` akan log warning dan tidak mendaftar hook.
- **`M.Sleep`** → harus dipanggil dari dalam `M.RunThread`. Kalau dipanggil di main thread = crash.
- **Growlauncher hooks** → dikelola manual (multiple callbacks di-merge jadi satu function). Ini transparent — tidak perlu kamu handle.

---

## 📜 Lisensi

MIT — bebas dipakai dan dimodifikasi. Credit dihargai tapi tidak wajib.
