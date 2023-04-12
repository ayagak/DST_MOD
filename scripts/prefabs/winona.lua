local MakePlayerCharacter = require("prefabs/player_common")
ConfigFolderName = "workshop-1386223812"
local healthset = GetModConfigData("healthset",ConfigFolderName) or 100
local sanityset = GetModConfigData("sanityset",ConfigFolderName) or 150
local hungerset = GetModConfigData("hungerset",ConfigFolderName) or 100
local chopspeedmod = GetModConfigData("chopspeedmod",ConfigFolderName) or true
local speedmod = GetModConfigData("speedmod",ConfigFolderName) or 1.25
local damagedeltmod = GetModConfigData("damagedeltmod",ConfigFolderName) or 0.6
local damagetakenmod = GetModConfigData("damagetakenmod",ConfigFolderName) or 1.3
local hungermod = GetModConfigData("hungermod",ConfigFolderName) or 0.5
local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/winona.fsb"),
}

local start_inv =
{
    default =
    {
    },

}

local prefabs = FlattenTree(start_inv, true)

for k, v in pairs(start_inv) do
    for i1, v1 in ipairs(v) do
        if not table.contains(prefabs, v1) then
            table.insert(prefabs, v1)
        end
    end
end

local function common_postinit(inst)
    inst:AddTag("handyperson")
    inst:AddTag("fastbuilder")
	inst:AddTag("woodcutter")
	--[[if chopspeedmod then
		inst:AddTag("woodcutter")
	elseif not chopspeedmod and inst:HasTag("woodcutter") then
		inst:RemoveTag("woodcutter")
	end]]--
	inst:AddTag("efficientworker")
	inst:AddTag("extrapick")
end

local function master_postinit(inst)
-- huge thanks to Mrlordowaffles for teaching me how to do this --
	local self = inst.components.combat
	local _GetAttacked = self.GetAttacked
	self.GetAttacked = function(self, attacker, damage, weapon, stimuli)
	if attacker and damage then
		-- Damage Taken
		damage = damage * damagetakenmod
	end	
	return _GetAttacked(self, attacker, damage, weapon, stimuli)
	end
------------------------------------------------------------------
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default
	inst.components.health:SetMaxHealth(healthset)
	inst.components.hunger:SetMax(hungerset)
	inst.components.sanity:SetMax(sanityset)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "winona_speed_mod", speedmod)
	inst.components.combat.damagemultiplier = damagedeltmod
	inst.components.hunger.hungerrate = hungermod * TUNING.WILSON_HUNGER_RATE
    inst.components.grue:SetResistance(1)

    if TheNet:GetServerGameMode() == "lavaarena" then
        event_server_data("lavaarena", "prefabs/winona").master_postinit(inst)
    end
end

return MakePlayerCharacter("winona", prefabs, assets, common_postinit, master_postinit)
