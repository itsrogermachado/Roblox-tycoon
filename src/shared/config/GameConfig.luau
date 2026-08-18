--!strict
--[[
	GameConfig
	----------
	Theme layer for the incremental loop.

	Research finding (2026-08): every obvious physical variable in the "+1"
	genre is already claimed -- speed, muscle, size, magnet, bounce, weight.
	The top game of 2026 ("+1 Speed Keyboard Escape", 6.3M peak CCU) used the
	MOST saturated variable and still won, because it changed the setting and
	the tension rather than the noun.

	So the engine treats the theme as data. Every player-facing noun and verb
	lives here. Retheming the game is an edit to this file, not a rewrite.
]]

export type Theme = {
	statName: string,
	statVerb: string,
	currencyName: string,
	title: string,
}

local GameConfig = {}

-- Player-facing naming. Swap these to retheme without touching game logic.
GameConfig.theme = {
	statName = "Power",
	statVerb = "Charge",
	currencyName = "Coins",
	title = "+1 Power Every Second",
} :: Theme

-- Core loop tuning. All economy math reads from here so balancing never
-- requires touching logic. See docs/superpowers/specs for the reasoning.
GameConfig.loop = {
	-- How often the server advances the economy, in seconds. One tick per
	-- second keeps the numbers readable and the network chatter low.
	tickInterval = 1,

	-- Stat gained per tick before upgrades. The "+1" of the genre.
	baseStatPerTick = 1,

	-- Currency earned per tick, per point of stat. Progress must be visible
	-- in under 30 seconds, so this is deliberately generous at the start.
	baseCurrencyPerStat = 0.5,

	-- Starting values for a brand new player.
	startingStat = 0,
	startingCurrency = 0,
}

-- Progression gates. Each area unlocks at a stat threshold. Thresholds sit on
-- the same exponential shape as the upgrade curve so the pacing stays even.
GameConfig.areas = {
	{ id = "start", displayName = "The Yard", requiredStat = 0 },
	{ id = "second", displayName = "The Works", requiredStat = 250 },
	{ id = "third", displayName = "The Reactor", requiredStat = 2500 },
}

return GameConfig
