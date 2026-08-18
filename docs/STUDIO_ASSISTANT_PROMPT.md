# Prompt para o Assistente de IA do Roblox Studio

## Como usar

Abra o painel **Assistente** no Studio (aquele do "Perguntar ao Assistente"),
cole o bloco em inglês abaixo e envie. O Assistente do Studio funciona bem
melhor em inglês do que em português, por isso o prompt está nessa língua.

Ele vai construir **apenas geometria** — Parts, Models e Folders. Nenhum
script. Isso é proposital: todo código do jogo vive no repositório e chega ao
Studio pelo Rojo. Se o Assistente oferecer criar Scripts, recuse.

## Por que os nomes importam

O código já escrito procura os objetos pelos nomes exatos listados no prompt.
Os ids `start`, `second` e `third` batem com `GameConfig.areas` em
`src/shared/config/GameConfig.luau`. Se o Assistente renomear alguma coisa,
ou o mapa se ajusta ou o config se ajusta — mas os dois têm que combinar.

Depois que ele terminar, **salve o place** e me diga o que apareceu na árvore do
Explorer, que eu escrevo o código que liga o mapa à economia.

---

## Prompt (copiar tudo daqui para baixo)

```
Build ONLY geometry for an incremental "+1 simulator" game. Do not create any
Script, LocalScript or ModuleScript — all code is managed outside Studio and
will be synced in. If you would normally add scripts, skip them entirely.

Use this exact hierarchy and these exact names. The names are a contract with
existing code, so do not rename, pluralize or reorder anything.

Workspace
  Map (Folder)
    Areas (Folder)
      Area_start (Model)
        Floor (Part)
      Area_second (Model)
        Floor (Part)
      Area_third (Model)
        Floor (Part)
    Gates (Folder)
      Gate_second (Part)
      Gate_third (Part)
    Shop (Model)
      ShopPad (Part)
    Spawns (Folder)
      Spawn_start (SpawnLocation)
      Spawn_second (SpawnLocation)
      Spawn_third (SpawnLocation)

Layout and sizing:

- The three areas sit in a straight line along the +X axis, each one larger and
  visually richer than the last, suggesting progression.
- Area_start/Floor: 120 x 2 x 120 studs, centered at (0, 0, 0).
- Area_second/Floor: 160 x 2 x 160 studs, centered at (220, 0, 0).
- Area_third/Floor: 200 x 2 x 200 studs, centered at (480, 0, 0).
- Every Floor is Anchored, CanCollide true, and Locked.

Gates:

- Gate_second is a wall standing between area one and area two, centered at
  (110, 10, 0), sized 4 x 20 x 120 studs.
- Gate_third stands between area two and area three, centered at (350, 10, 0),
  sized 4 x 20 x 160 studs.
- Both gates are Anchored and CanCollide true. Give them Transparency 0.4 and a
  bright, saturated color so they read clearly as "locked" from a distance.

Shop:

- ShopPad is a low circular platform, 16 studs wide and 1 stud tall, Anchored,
  placed on the starting area at roughly (0, 1.5, 40) — near spawn so a new
  player finds it within the first few seconds.
- Give it a colour that contrasts strongly with Area_start/Floor.

Spawns:

- Spawn_start at (0, 3, -40) on the first area.
- Spawn_second at (220, 3, 0) on the second area.
- Spawn_third at (480, 3, 0) on the third area.
- Only Spawn_start has Enabled set to true. The other two are Enabled false —
  they get switched on by code once the player unlocks that area.
- Set Neutral to true on all three.

Visual direction:

- Read as bright, clean and readable, not realistic. Flat saturated colours and
  SmoothPlastic material.
- Each area gets its own dominant colour so a player instantly knows where they
  are: area one cool and calm, area two warmer, area three intense.
- Keep the total part count low. Simple blocky forms only — no meshes, no
  imported models, no textures, no decals.

Do not add lighting effects, sounds, GUIs, or anything under StarterGui,
ServerScriptService, ReplicatedStorage or StarterPlayer. Only touch Workspace.
```

---

## Depois que ele construir

Confira três coisas antes de me chamar de volta:

1. A pasta `Map` existe dentro de `Workspace` com a árvore acima.
2. Nenhum Script foi criado em lugar nenhum.
3. As pastas `Shared`, `Server` e `Client` continuam intactas — se o Assistente
   tiver mexido nelas, é só reconectar o Rojo que ele reescreve do repositório.
