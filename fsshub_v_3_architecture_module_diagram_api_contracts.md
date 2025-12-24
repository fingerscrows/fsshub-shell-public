# FSSHUB V3 – Modular Architecture & API Contract

Dokumen ini menurunkan **Rencana V3 (Shell & Vault)** menjadi **arsitektur teknis konkret**: pembagian modul, boundary, serta kontrak API yang eksplisit.

Tujuan dokumen:
- Menjadi blueprint implementasi
- Menjaga disiplin modular
- Mencegah coupling berbahaya antara UI, Auth, dan Feature Logic

---

## 1. High-Level Architecture Diagram

```
┌───────────────────────────┐
│        Roblox Client      │
│        (Executor)         │
│                           │
│  ┌─────────────────────┐  │
│  │   Loader.lua        │  │
│  └─────────┬───────────┘  │
│            │               │
│            ▼               │
│  ┌─────────────────────┐  │
│  │  UI Shell (Public)  │◄─┼── JSDelivr (GitHub Public)
│  │  - Fluent UI        │  │
│  │  - Tabs / Buttons   │  │
│  │  - Event Dispatcher │  │
│  └─────────┬───────────┘  │
│            │               │
│            ▼               │
│  ┌─────────────────────┐  │
│  │ Client API Layer    │  │
│  │ - Request()         │  │
│  │ - Token Cache       │  │
│  │ - Feature Loader    │  │
│  └─────────┬───────────┘  │
│            │ HTTPS         │
└────────────┼───────────────┘
             ▼
┌──────────────────────────────────┐
│ Cloudflare Worker (Gatekeeper)   │
│                                  │
│  ┌──────────────┐                │
│  │ Auth Module  │                │
│  └──────┬───────┘                │
│         │                        │
│  ┌──────▼────────┐               │
│  │ Session Ctrl  │               │
│  └──────┬────────┘               │
│         │                        │
│  ┌──────▼────────┐               │
│  │ Feature Ctrl  │               │
│  └──────┬────────┘               │
│         │                        │
│  ┌──────▼────────┐               │
│  │ Response Pipe │               │
│  └──────┬────────┘               │
│         │                        │
│  ┌──────▼────────┐               │
│  │ Cloudflare KV │◄── Feature Lua│
│  └───────────────┘               │
└──────────────────────────────────┘
```

---

## 2. Modul Breakdown (Client Side)

### 2.1 Loader.lua (Bootstrap Only)
**Tanggung jawab:**
- Entry point tunggal
- Fetch UI Shell
- Tidak tahu apa pun tentang feature logic

**Larangan keras:**
- Tidak boleh auth
- Tidak boleh load feature
- Tidak boleh ada game-specific logic

---

### 2.2 UI Shell (Public)
**Isi:**
- Fluent framework
- Window, Tabs, Toggle, Button
- Event emitter

**Sifat:**
- Stateless
- Tidak menyimpan token
- Tidak tahu endpoint detail

**Contoh event:**
```
UI:OnToggle("AutoFarm", true)
```

---

### 2.3 Client API Layer (Private but Thin)
Ini adalah **adapter antara UI dan Worker**.

**Tanggung jawab:**
- Request ke Worker
- Cache token sesi
- Load & execute feature chunk

**Struktur:**
- ApiClient.lua
- Session.lua
- FeatureLoader.lua

---

## 3. Modul Breakdown (Cloudflare Worker)

### 3.1 Auth Module
**Input:** key
**Output:** session token

Validasi:
- Key exists
- Not banned
- Expired / not

---

### 3.2 Session Controller
**Tanggung jawab:**
- Generate token
- TTL enforcement
- Bind token → key

**Catatan:**
Token **bukan** JWT publik. Gunakan opaque token.

---

### 3.3 Feature Controller
**Tanggung jawab:**
- Validasi token
- Validasi akses feature
- Ambil Lua string dari KV

---

### 3.4 Response Pipeline
**Tanggung jawab:**
- Optional obfuscation
- Chunking
- Response shaping

---

## 4. Cloudflare KV Schema

### 4.1 Keys Namespace
```
key:{USER_KEY} => {
  tier: "free" | "premium",
  banned: false,
  expire: 1700000000
}
```

### 4.2 Session Namespace
```
session:{TOKEN} => {
  key: "XXXX-XXXX",
  expire: 1700000300
}
```

### 4.3 Feature Namespace
```
feature:autofarm => "-- Lua Code String"
feature:esp      => "-- Lua Code String"
```

---

## 5. API Contract (Client ↔ Worker)

### 5.1 Auth Request
**Endpoint:** `/auth`

Request:
```json
{
  "key": "USER-KEY"
}
```

Response:
```json
{
  "ok": true,
  "token": "SESSION_TOKEN",
  "ttl": 300
}
```

---

### 5.2 Feature Request
**Endpoint:** `/feature`

Request:
```json
{
  "token": "SESSION_TOKEN",
  "feature": "autofarm"
}
```

Response:
```json
{
  "ok": true,
  "chunk": "--lua code"
}
```

---

### 5.3 Error Contract (Universal)
```json
{
  "ok": false,
  "error": "INVALID_TOKEN"
}
```

---

## 6. Security Design Rules (WAJIB)

1. UI tidak pernah tahu token
2. Token TTL pendek (3–10 menit)
3. Feature load on-demand
4. Satu request = satu feature
5. Tidak ada bulk feature delivery

---

## 7. Mapping dari V2 → V3

| V2 Module | V3 Target |
|----------|-----------|
| Loader.lua | Tetap (diperkecil) |
| ModuleManager | Feature Controller |
| Auth via GAS | Auth Worker |
| GitHub Private | Cloudflare KV |

---

## 8. Prinsip Utama

> UI cepat, logic tersembunyi, server menentukan segalanya.

Jika prinsip ini dilanggar, V3 akan runtuh.

---

Dokumen ini adalah **kontrak arsitektur**, bukan sekadar dokumentasi.
Jika kamu mau, langkah berikutnya:
- Turunkan ini jadi **folder structure konkret (client + worker)**
- Atau audit V2 dan petakan langsung file mana masuk Shell vs Vault


---

## 9. Folder Structure Konkret (Client + Worker + KV)

Bagian ini menurunkan arsitektur menjadi **struktur folder nyata** yang bisa langsung kamu terapkan di repo.

---

### 9.1 Client Side (Roblox Executor)

```
client/
├─ Loader.lua                # Bootstrap entry (sangat kecil)
│
├─ Shell/                    # PUBLIC (GitHub + JSDelivr)
│  ├─ init.lua               # Entry UI Shell
│  ├─ Fluent/                # UI framework (public)
│  ├─ UI/
│  │  ├─ Window.lua
│  │  ├─ Tabs.lua
│  │  └─ Components.lua
│  └─ Events.lua             # Emit UI events (OnToggle, OnClick)
│
├─ Core/                     # PRIVATE (embedded via loader)
│  ├─ ApiClient.lua          # HTTP abstraction ke Worker
│  ├─ Session.lua            # Token cache + TTL
│  ├─ FeatureLoader.lua      # Loadstring executor
│  └─ Security.lua           # Basic runtime checks
│
└─ Runtime/
   ├─ Context.lua            # GameId, PlaceId, Player info
   └─ Flags.lua              # State feature ON/OFF
```

**Aturan keras (Client):**
- `Shell/` tidak boleh require `Core/`
- `Shell/` tidak tahu token, endpoint detail, atau feature name
- Semua request HARUS lewat `ApiClient`

---

### 9.2 Cloudflare Worker Side

```
worker/
├─ index.js                  # Entry Worker
│
├─ routes/
│  ├─ auth.js                # /auth endpoint
│  └─ feature.js             # /feature endpoint
│
├─ controllers/
│  ├─ AuthController.js
│  ├─ SessionController.js
│  └─ FeatureController.js
│
├─ services/
│  ├─ KVService.js           # Wrapper KV access
│  ├─ TokenService.js        # Generate & validate token
│  └─ Obfuscator.js          # Optional light obfuscation
│
├─ middlewares/
│  ├─ rateLimit.js
│  └─ validateJSON.js
│
└─ config/
   ├─ constants.js
   └─ features.js            # Mapping feature name → KV key
```

**Prinsip Worker:**
- Route hanya delegasi
- Logic di controller
- KV tidak diakses langsung dari route

---

### 9.3 Cloudflare KV Namespace Design

```
KV_NAMESPACE
│
├─ key:{USER_KEY}
│  ├─ tier
│  ├─ banned
│  └─ expire
│
├─ session:{TOKEN}
│  ├─ key
│  ├─ tier
│  └─ expire
│
└─ feature:{FEATURE_NAME}
   ├─ code
   ├─ minTier
   └─ version
```

**Catatan:**
- Jangan simpan metadata feature di client
- Semua keputusan akses di Worker

---

### 9.4 GitHub Repository Split

#### Repo 1 — `fsshub-shell-public`
```
Shell/
Fluent/
UI/
Events.lua
```
➡️ Served via JSDelivr

#### Repo 2 — `fsshub-core-private`
```
Loader.lua
Core/
Runtime/
```
➡️ Tidak di-CDN-kan

---

## 10. Mapping Event UI → Feature Load

Flow nyata saat user klik toggle:

```
[UI Toggle]
   ↓
Events.emit("AutoFarm", true)
   ↓
ApiClient.requestFeature("autofarm")
   ↓
Worker validates token
   ↓
Worker returns chunk
   ↓
FeatureLoader.execute(chunk)
```

UI **tidak tahu**:
- Apa isi chunk
- Dari mana chunk berasal
- Apakah feature premium atau tidak

---

## 11. Golden Rules Implementasi

1. Loader < 50 baris
2. UI boleh bocor, logic tidak
3. Feature = satu file di KV
4. Tidak ada global shared state
5. Semua feature bisa dimatikan server-side

---

Blueprint ini sekarang sudah cukup kuat untuk:
- Mulai refactor V2
- Onboard AI agent / dev lain
- Masuk Fase 1 tanpa kebingungan

Langkah berikutnya yang paling strategis:
- Audit **struktur V2** dan tandai file mana masuk folder di atas
- Atau definisikan **template feature module** (AutoFarm, ESP, dll)

