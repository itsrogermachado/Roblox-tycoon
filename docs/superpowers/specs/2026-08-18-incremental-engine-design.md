# Design: motor incremental parametrizado

Data: 2026-08-18
Status: implementado (fundação); tema pendente de decisão

## Problema

O `CLAUDE.md` do projeto define o gênero (incremental "+1 simulator") e aposta
numa hipótese de diferenciação: *"quase todos usam velocidade, músculo ou
tamanho. Variável nova + verbo novo, mesma engenharia."*

A hipótese foi testada e não se sustenta.

## Pesquisa (2026-08-18)

Verificação de saturação por variável no catálogo atual do Roblox:

| Variável | Situação encontrada |
| --- | --- |
| Velocidade, músculo, tamanho | Saturado, como o documento já previa |
| Magnetismo | Magnet Simulator original com ~2 jogadores apesar de 151M de visitas históricas; Magnet Trash Simulator lançado em abril/2026 |
| Bounce | "+1 Bounce Every Second", "Highest Bounce?", "Bounce!" |
| Peso / smash | "+1 SMASH a Tower", "Get Heavy Simulator" |

Não existe substantivo físico óbvio disponível. O gênero já varreu o espaço.

O contraexemplo decisivo é o jogo número um de 2026. **+1 Speed Keyboard
Escape** usa a variável mais saturada que existe — velocidade — e mesmo assim
acumulou 3,8 bilhões de visitas e atingiu 6,3 milhões de jogadores simultâneos
num evento em julho de 2026.

A diferenciação dele não veio do substantivo. Veio de duas outras coisas: o
**cenário** (o mapa é um teclado gigante, não uma pista) e a **tensão** (a
velocidade que o jogador acumula também é o que faz ele errar as plataformas,
então o objetivo real não é ficar rápido, é aprender a controlar).

## Decisão

Duas conclusões, uma estratégica e uma de engenharia.

**Estratégica:** diferenciar por cenário e tensão, não por substantivo. Escolher
a variável deixa de ser a decisão bloqueante que parecia ser.

**De engenharia:** o tema vira dado, não código. Todo substantivo e verbo
visível ao jogador mora em `shared/config/GameConfig.luau`. Retematizar o jogo
é editar um arquivo de configuração, não reescrever sistemas. Isso é
exatamente o que o `CLAUDE.md` já pedia com "zero número mágico solto no
código" — aqui a regra foi estendida do balanceamento para o tema.

O tema atual (`Power` / `Charge` / `Coins`) é um valor padrão funcional, não uma
decisão final de produto.

## Arquitetura

Módulos Luau simples, sem framework. Knit e Flamework foram considerados e
descartados: o MVP não tem complexidade que os justifique, e com zero
experiência prévia em Luau um framework adiciona uma segunda curva de
aprendizado em paralelo à da linguagem.

### `shared/config/`

- **`GameConfig`** — camada de tema (nomes, verbo, título) e ajuste do loop
  (intervalo do tick, ganho base, taxa de conversão) e os três portões de área.
- **`UpgradeConfig`** — os dez upgrades do MVP e a curva de custo
  `custo(n) = baseCost * (growth ^ n)`, com `growth` entre 1,6 e 1,9. Cada
  upgrade multiplica exatamente uma das duas taxas, o que evita caso especial
  no `EconomyService`.
- **`DataConfig`** — nome versionado do DataStore, política de retry, intervalo
  de autosave e orçamento de flush no desligamento.

### `shared/remotes/`

- **`Remotes`** — declaração central dos RemoteEvents. O servidor cria as
  instâncias, o cliente espera por elas. Nomear num só lugar elimina a classe
  de bug em que um erro de digitação de um lado cria um segundo remote silencioso.

### `server/services/`

- **`DataService`** — dono exclusivo de leitura e escrita persistente. Retry com
  backoff exponencial, autosave periódico, salvamento em `PlayerRemoving` e em
  `BindToClose`. A regra central: **se o load falhar, a sessão fica travada e
  nunca é escrita de volta**, porque salvar depois de um load falho grava um
  perfil vazio por cima de um real e apaga o progresso em definitivo.
- **`EconomyService`** — o loop e o único lugar onde moeda muda. Um único
  `Heartbeat` com acumulador serve todos os jogadores, em vez de um loop por
  sessão. Toda compra é validada no servidor: id conhecido, nível abaixo do
  máximo, saldo suficiente.
- **`LeaderstatsService`** — espelha o perfil na lista de jogadores. Valores de
  exibição apenas; nada lê de volta como verdade.

### `client/controllers/`

- **`StateController`** — recebe e guarda o snapshot autoritativo. O cliente
  nunca calcula saldo, custo ou multiplicador.

## Multiplicadores: soma antes de multiplicar

Efeitos de upgrade somam antes de multiplicar. Três níveis de um upgrade de
+0,25 dão `1 + 0,75 = 1,75x`, e não `1,25³`. Empilhamento multiplicativo
estoura números legíveis dentro de uma hora de jogo e torna uma curva de dez
upgrades impossível de balancear.

## Fora deste escopo

Interface gráfica, mapa, monetização e analytics. A UI em particular deve
começar pela skill `ui-ux-pro-max`, conforme a regra 2 de `regras-projeto`.

## Verificação

StyLua sem diferenças, Selene com zero erros e zero avisos, `rojo build` bem
sucedido.
