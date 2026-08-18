# CLAUDE.md — Projeto Roblox

## Contexto do desenvolvedor
- Dev solo. **Windows**, VS Code, Git/GitHub.
- **Zero experiência com Luau e Roblox Studio.** Explique o "porquê" de cada
  conceito novo na primeira vez que ele aparecer. Não assuma que eu sei o que
  é RemoteEvent, ModuleScript, DataStore ou leaderstats.
- Disponibilidade: ~15h/semana.
- Responda em português. Código, nomes e comentários em inglês.
- Você tem acesso ao meu PC. Execute os comandos, crie os arquivos, configure
  o ambiente. Só me peça pra fazer manualmente o que exige a interface do
  Studio ou o navegador.

## Estado atual do ambiente
- Roblox Studio instalado, em português, com um Baseplate aberto.
- Rojo (CLI) já baixado no PC — **validar se está no PATH** com `rojo --version`.
- Pasta do projeto: `roblox-tycoon`, aberta no VS Code.
- **Pendente:** extensão Rojo no VS Code, plugin do Rojo no Studio
  (instalar pela Creator Store, asset "Rojo"), `rojo init`, repositório GitHub.

Primeira tarefa: fechar esse setup e provar a sincronização com um Hello World.
Nenhum sistema de jogo antes disso funcionar.

## Estratégia do negócio
Não é uma aposta única. É **portfólio de jogos pequenos**, lançados rápido,
em cima de trends. Cada jogo é barato de fazer, ensina algo e é uma chance
no algoritmo de descoberta. Público-alvo primário: **Estados Unidos**.

### Gênero de referência
O molde é o **incremental / "+1 simulator"**: ganhar número, gastar número,
ganhar mais rápido. Exemplos que dominam a categoria: Legends of Speed,
Speed Run 4, Sonic Speed Simulator, "Every Second You Get +1 WalkSpeed",
"+1 Muscle to Arm Wrestle".

Regras que esses jogos seguem e nós também seguimos:
- **O título é a mecânica.** O jogador entende o jogo antes de entrar. Título
  em inglês, direto, com o verbo e o número.
- Primeiro progresso visível em menos de 30 segundos.
- Portões de progressão: área nova destravando em marcos de progresso.
- Feedback sensorial em toda ação — som, partícula, número subindo na tela.
- A brecha que a gente explora: quase todos usam velocidade, músculo ou
  tamanho. Variável nova + verbo novo, mesma engenharia.

### Design "streamável"
Steal a Brainrot cresceu por live de TikTok, não por anúncio. Vale desenhar
pra ser assistível: momento de sorte visível, evento que dá pra narrar, algo
que o streamer possa dar pra alguém dentro das regras da plataforma.
Isso é aquisição de graça. Não é prioridade do primeiro jogo, mas influencia
o design desde já.

## Escopo do MVP (não expandir sem eu pedir)
1. Mapa único, loop incremental de uma variável
2. Uma moeda, ganha pelo loop principal
3. ~10 upgrades em curva de custo exponencial suave
4. 2 a 3 portões de área destravando por progresso
5. Save/load persistente
6. Leaderstats visíveis
7. Monetização mínima viável (ver abaixo)

Fora do MVP: pets, trading, PvP, quests diárias, múltiplos mapas, codes.
Se eu pedir algo dessa lista, me lembre que é pós-lançamento.

## Monetização
Monetizar em tudo que for permitido e honesto. Cardápio autorizado:
- **Gamepasses** de utilidade permanente (2x ganhos, auto-coleta, VIP)
- **Cosméticos** — skins, trilhas, efeitos, acessórios. Prioridade alta:
  o público americano adulto compra cosmético com cartão próprio, sem
  intermediário, e cosmético não quebra o balanceamento.
- **Moeda premium** e pacotes de moeda
- **Boosts** temporários de progressão
- **Passe de temporada** com recompensa visível e prazo claro

### Proibido
- **Itens aleatórios pagos** — lootbox, caixa, roleta, ovo surpresa,
  incluindo via moeda intermediária comprável com Robux. A Roblox endureceu
  a política em maio de 2026 (odds numéricas obrigatórias, restrição por
  idade) e está agindo contra simuladores. Portfólio inteiro derrubado num
  sweep destrói a estratégia. Isso não é negociável.
- Timer de FOMO falso, "última chance" recorrente, pop-up de compra cortando
  gameplay.
- Pay-to-win que arruíne a experiência de quem não paga. Pago acelera,
  não desbloqueia o jogo.

Teste que aplico a toda mecânica de venda: o jogador sabe exatamente o que
está levando antes de pagar? Se não, refaça.

## Stack e fluxo de trabalho
- **Rojo** sincroniza o repositório com o Studio ao vivo. Código sempre em
  arquivos `.luau` no repo — nunca me mande colar script manualmente no Studio.
- Assets visuais eu monto no Studio; código fica no repositório.
- Git: commits pequenos e frequentes, mensagem em inglês no imperativo.

### Estrutura de pastas
```
src/
  server/          -> ServerScriptService
    services/      -> um módulo por sistema (Economy, Data, Progression, Passes)
  client/          -> StarterPlayerScripts
    controllers/   -> um módulo por sistema de UI/input
  shared/
    config/        -> valores balanceáveis (custos, taxas, tempos)
    remotes/       -> definição centralizada dos RemoteEvents
```

## Regras de arquitetura
- **Servidor é a única fonte de verdade.** Nenhum valor de economia é
  calculado ou validado no cliente. O cliente exibe e pede.
- Todo RemoteEvent valida tipo e sanidade no servidor: o jogador pode comprar
  isso? tem saldo? é o próximo upgrade da fila? Trate input do cliente como
  hostil.
- Zero número mágico solto no código. Custos, taxas e tempos vivem em
  `shared/config/` pra eu balancear sem tocar em lógica.
- Um módulo, uma responsabilidade. Passou de ~200 linhas, proponha divisão.
- DataStore com retry e tratamento de falha. Salvar no `PlayerRemoving` e no
  `BindToClose`. Se o load falhar, bloqueie o save da sessão em vez de
  sobrescrever com dado vazio. Jogador não pode perder progresso em silêncio.

## Métrica que manda
**Retenção D1.** Abaixo de ~25%, o problema é o loop e não o marketing —
não gastar Robux em anúncio antes de resolver. Instrumente eventos de
analytics desde o MVP: entrada, primeiro upgrade, tempo até sair.

## Como trabalhar comigo
- Antes de implementar sistema novo, descreva o plano em 3–5 linhas e espere
  meu OK.
- Conceito novo do Roblox: explicação de 2 frases junto.
- Se eu pedir algo que é má prática, fura escopo ou arrisca a política da
  plataforma, diga antes de fazer.
- Nada de placeholder silencioso. Se depende de asset que só eu crio no
  Studio, pare e diga exatamente o que criar e como nomear.
