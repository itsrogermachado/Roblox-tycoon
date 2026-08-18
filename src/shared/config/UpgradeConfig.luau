--!strict
--[[
	UpgradeConfig
	-------------
	The ten MVP upgrades and their cost curve.

	Costs follow a smooth exponential: cost(n) = baseCost * (growth ^ n).
	A growth factor around 1.6 is the genre standard -- low enough that the
	next purchase always feels reachable, high enough that the numbers grow
	fast and the player feels the scale change.

	Every upgrade multiplies exactly one of the two loop rates. Keeping the
	effect shape uniform means EconomyService never needs a special case.
]]

export type UpgradeKind = "StatRate" | "CurrencyRate"

export type Upgrade = {
	id: string,
	displayName: string,
	description: string,
	kind: UpgradeKind,
	-- Multiplier added per level owned. Level 3 of a 0.25 upgrade gives +75%.
	effectPerLevel: number,
	baseCost: number,
	costGrowth: number,
	maxLevel: number,
}

local UpgradeConfig = {}

UpgradeConfig.upgrades = {
	{
		id = "faster_charge",
		displayName = "Faster Charge",
		description = "Gain Power more quickly every second.",
		kind = "StatRate",
		effectPerLevel = 0.25,
		baseCost = 25,
		costGrowth = 1.6,
		maxLevel = 20,
	},
	{
		id = "better_payout",
		displayName = "Better Payout",
		description = "Earn more Coins from the Power you already have.",
		kind = "CurrencyRate",
		effectPerLevel = 0.25,
		baseCost = 40,
		costGrowth = 1.6,
		maxLevel = 20,
	},
	{
		id = "twin_coils",
		displayName = "Twin Coils",
		description = "A second coil doubles down on Power gain.",
		kind = "StatRate",
		effectPerLevel = 0.5,
		baseCost = 250,
		costGrowth = 1.7,
		maxLevel = 15,
	},
	{
		id = "coin_press",
		displayName = "Coin Press",
		description = "Stamp Coins faster from the same Power.",
		kind = "CurrencyRate",
		effectPerLevel = 0.5,
		baseCost = 400,
		costGrowth = 1.7,
		maxLevel = 15,
	},
	{
		id = "overclock",
		displayName = "Overclock",
		description = "Push the core past its rated limit.",
		kind = "StatRate",
		effectPerLevel = 1,
		baseCost = 2500,
		costGrowth = 1.75,
		maxLevel = 12,
	},
	{
		id = "refinery",
		displayName = "Refinery",
		description = "Refine raw output into far more Coins.",
		kind = "CurrencyRate",
		effectPerLevel = 1,
		baseCost = 4000,
		costGrowth = 1.75,
		maxLevel = 12,
	},
	{
		id = "reactor_core",
		displayName = "Reactor Core",
		description = "Industrial-grade Power generation.",
		kind = "StatRate",
		effectPerLevel = 2.5,
		baseCost = 30000,
		costGrowth = 1.8,
		maxLevel = 10,
	},
	{
		id = "mint",
		displayName = "The Mint",
		description = "Turn Power into Coins at industrial scale.",
		kind = "CurrencyRate",
		effectPerLevel = 2.5,
		baseCost = 50000,
		costGrowth = 1.8,
		maxLevel = 10,
	},
	{
		id = "singularity",
		displayName = "Singularity",
		description = "Bend the rules of Power generation entirely.",
		kind = "StatRate",
		effectPerLevel = 10,
		baseCost = 500000,
		costGrowth = 1.9,
		maxLevel = 8,
	},
	{
		id = "vault",
		displayName = "The Vault",
		description = "Every point of Power pays out like never before.",
		kind = "CurrencyRate",
		effectPerLevel = 10,
		baseCost = 750000,
		costGrowth = 1.9,
		maxLevel = 8,
	},
} :: { Upgrade }

-- Fast lookup by id, built once at require time. The remote handler needs to
-- reject unknown ids cheaply, and a linear scan per purchase request would be
-- an easy denial-of-service surface.
local byId: { [string]: Upgrade } = {}
for _, upgrade in UpgradeConfig.upgrades do
	byId[upgrade.id] = upgrade
end

function UpgradeConfig.get(id: string): Upgrade?
	return byId[id]
end

--[[
	Cost of moving from `currentLevel` to `currentLevel + 1`.
	Rounded so the player never sees a fractional price.
]]
function UpgradeConfig.costAtLevel(upgrade: Upgrade, currentLevel: number): number
	return math.floor(upgrade.baseCost * (upgrade.costGrowth ^ currentLevel))
end

return UpgradeConfig
