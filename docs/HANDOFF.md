# Relatório de sessão — 2026-08-18

Ponto de parada e retomada do projeto. Leia este arquivo primeiro ao voltar.

## Onde o projeto está

O ambiente está completo e verificado. A fundação do motor incremental está
escrita, passa em lint, format e build, mas **ainda não foi executada dentro do
Roblox Studio** — essa é a primeira coisa a fazer na volta.

Repositório: `github.com/itsrogermachado/Roblox-tycoon`

## O que foi feito

### Ambiente

O download original (`rojo-master.zip`) era o **código-fonte** do Rojo, não o
programa. Por isso `rojo --version` nunca funcionou — não existia executável
naquele arquivo. Foi substituído pela instalação correta.

| Ferramenta | Versão | Papel |
| --- | --- | --- |
| Rokit | 1.2.0 | Gerenciador de toolchain; o `rokit.toml` fixa as versões e reproduz o ambiente em qualquer máquina |
| Rojo | 7.7.0 | Sincroniza o repositório com o Studio ao vivo |
| StyLua | 2.5.2 | Formatador, roda ao salvar no VS Code |
| Selene | 0.31.0 | Linter |
| GitHub CLI | 2.97.0 | Instalado, **sem login** — o push funciona pelo VS Code |

Extensões no VS Code: `vscode-rojo`, `luau-lsp` (autocomplete das APIs do
Roblox via sourcemap), `stylua`. Plugin do Rojo instalado direto na pasta de
plugins do Studio, sem passar pela Creator Store.

Sincronização confirmada: as pastas `Shared`, `Server` e `Client` apareceram no
Explorer do Studio vindas de `src/`.

### Decisão de design

A hipótese do `CLAUDE.md` — *"variável nova + verbo novo, mesma engenharia"* —
foi testada e **não se sustenta**. Nenhuma variável física óbvia está livre:

| Variável | Situação |
| --- | --- |
| Velocidade, músculo, tamanho | Saturado |
| Magnetismo | Original morto (~2 jogadores); "Magnet Trash Simulator" de abr/2026 |
| Bounce | "+1 Bounce Every Second", "Highest Bounce?", "Bounce!" |
| Peso / smash | "+1 SMASH a Tower", "Get Heavy Simulator" |

O contraexemplo que resolve o impasse: **+1 Speed Keyboard Escape** usa a
variável mais saturada que existe e fez 3,8 bilhões de visitas, com pico de 6,3
milhões de jogadores simultâneos em julho de 2026. A diferenciação veio do
**cenário** (um teclado gigante) e da **tensão** (a velocidade acumulada é o que
faz o jogador errar a plataforma).

Conclusão adotada: diferenciar por cenário e tensão, não por substantivo. E,
como consequência de engenharia, **o tema virou dado**. Todos os nomes visíveis
ao jogador vivem em `shared/config/GameConfig.luau`; retematizar é editar
config, não reescrever sistemas. O tema atual (`Power` / `Charge` / `Coins`) é
um padrão funcional, não decisão final.

Design completo em `docs/superpowers/specs/2026-08-18-incremental-engine-design.md`.

### Código escrito

Módulos Luau simples, sem framework. Knit e Flamework foram descartados: o MVP
não os justifica e somam uma segunda curva de aprendizado à da linguagem.

```
src/shared/config/GameConfig.luau       tema, loop, portões de área
src/shared/config/UpgradeConfig.luau    10 upgrades, curva exponencial 1,6–1,9
src/shared/config/DataConfig.luau       DataStore versionado, retry, autosave
src/shared/remotes/Remotes.luau         RemoteEvents centralizados
src/server/services/DataService.luau    persistência com trava anti-perda
src/server/services/EconomyService.luau loop e validação de compra
src/server/services/LeaderstatsService.luau  espelho na lista de jogadores
src/client/controllers/StateController.luau  recebe estado autoritativo
```

Três decisões que valem lembrar:

**Trava anti-perda de progresso.** Se o load do DataStore falha, a sessão é
marcada e **nunca é escrita de volta**. Salvar depois de um load falho gravaria
um perfil vazio por cima de um real e apagaria o progresso em definitivo.

**Um só Heartbeat.** Um acumulador único serve todos os jogadores, em vez de um
loop por sessão. Evita drift entre jogadores e uma thread por pessoa.

**Multiplicadores somam antes de multiplicar.** Três níveis de um upgrade de
+0,25 dão `1 + 0,75 = 1,75x`, não `1,25³`. Empilhamento multiplicativo estoura
números legíveis em menos de uma hora de jogo.

## Verificação

Executado e verde: `stylua src` exit 0 · `selene src` 0 erros e 0 avisos ·
`rojo build` bem sucedido.

**Não verificado:** o código nunca rodou dentro do Studio. O loop de economia,
a criação dos leaderstats e a chegada do estado no cliente são corretos no
papel, não em execução.

## Próximos passos, em ordem

1. **Provar o loop no Studio.** Rodar `rojo serve`, conectar, apertar Play e
   confirmar no Output: `[Server] ... online`, `[Client] Ready`, e a cada 5
   segundos uma linha `[Client] Power: N (+1.00/s) | Coins: N (+X/s)`. Os
   leaderstats devem aparecer na lista de jogadores subindo sozinhos.
2. **Construir o mapa.** Usar o prompt em `docs/STUDIO_ASSISTANT_PROMPT.md`. O
   contrato de nomes está lá e o código depende dele.
3. **Ligar os portões de área** ao mapa construído.
4. **Interface.** Começar pela skill `ui-ux-pro-max`, conforme a regra 2 de
   `regras-projeto`. Nenhuma linha de UI antes disso.
5. **Decidir tema e título definitivos** — edição de `GameConfig`, sem tocar em
   lógica.
6. **Monetização e analytics.** Antes de mexer em monetização, verificar a
   redação oficial da política de itens aleatórios de maio/2026 na fonte. A
   regra do `CLAUDE.md` é mais restritiva que qualquer política, então é segura
   de qualquer forma, mas o texto atual precisa ser lido.

## Pendências conhecidas

- `gh auth login` não foi concluído. Não bloqueia nada: o push funciona pela
  autenticação própria do VS Code.
- Sem testes automatizados. Luau em Roblox precisa de TestEZ ou similar; não foi
  instalado ainda.
- O mapa não existe. O jogo hoje é um Baseplate vazio com economia rodando.
