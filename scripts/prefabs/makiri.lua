
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
        Asset( "ANIM", "anim/player_idles_shiver.zip" ),
        Asset( "ANIM", "anim/player_actions.zip" ),
        Asset( "ANIM", "anim/player_actions_axe.zip" ),
        Asset( "ANIM", "anim/player_actions_pickaxe.zip" ),
        Asset( "ANIM", "anim/player_actions_shovel.zip" ),
        Asset( "ANIM", "anim/player_actions_blowdart.zip" ),
        Asset( "ANIM", "anim/player_actions_eat.zip" ),
        Asset( "ANIM", "anim/player_actions_item.zip" ),
        Asset( "ANIM", "anim/player_actions_uniqueitem.zip" ),
        Asset( "ANIM", "anim/player_actions_bugnet.zip" ),
        Asset( "ANIM", "anim/player_actions_fishing.zip" ),
        Asset( "ANIM", "anim/player_actions_boomerang.zip" ),
        Asset( "ANIM", "anim/player_bush_hat.zip" ),
        Asset( "ANIM", "anim/player_attacks.zip" ),
        Asset( "ANIM", "anim/player_idles.zip" ),
        Asset( "ANIM", "anim/player_rebirth.zip" ),
        Asset( "ANIM", "anim/player_jump.zip" ),
        Asset( "ANIM", "anim/player_amulet_resurrect.zip" ),
        Asset( "ANIM", "anim/player_teleport.zip" ),
        Asset( "ANIM", "anim/wilson_fx.zip" ),
        Asset( "ANIM", "anim/player_one_man_band.zip" ),
        Asset( "ANIM", "anim/shadow_hands.zip" ),
        Asset( "SOUND", "sound/sfx.fsb" ),
        Asset( "SOUND", "sound/wilson.fsb" ),
        Asset( "ANIM", "anim/beard.zip" ),

        Asset( "ANIM", "anim/makiri.zip" ),
        Asset( "ANIM", "anim/ghost_makiri_build.zip" ),
}
local prefabs = 
{
    "book_birds",
    "book_tentacles",
    "book_gardening",
    "book_sleep",
    "book_brimstone",
}

-- Custom starting items
local start_inv = {
	"bow",
    "quiver",
    "waxwelljournal",
    "spidereggsack",
    "papyrus",
    "papyrus",
    "feather_crow",
    "feather_robin",
}

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when loading or reviving from ghost (optional)
	inst.components.locomotor.walkspeed = 4
	inst.components.locomotor.runspeed = 6
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)

    if not inst:HasTag("playerghost") then
        onbecamehuman(inst)
    end
end

local function DoEffects(pet)
    local x, y, z = pet.Transform:GetWorldPosition()
    SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
end

local function KillPet(pet)
    pet.components.health:Kill()
end

local function OnSpawn(inst, pet)
    --Delayed in case we need to relocate for migration spawning
    pet:DoTaskInTime(0, DoEffects)

    if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
        inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
        inst:ListenForEvent("onremove", inst._onpetlost, pet)
    elseif pet._killtask == nil then
        pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
    end
end

local function OnDespawn(inst, pet)
    DoEffects(pet)
    pet:Remove()
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v._killtask == nil then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "makiri.tex" )
    -- choose which sounds this character will play
	inst.soundsname = "wallace"
    inst:AddTag("insomniac")
    inst:AddTag("spiderwhisperer")
	inst:AddTag("gem_builder")
    inst:AddTag("bookbuilder")
    inst:AddTag("smallcreature") --Makes Catcoons hostile to him	
	inst:AddTag("shadowmagic")
    inst:AddTag("reader")

    inst:AddTag("handyperson")
    inst:AddTag("fastbuilder")
    inst:AddTag("woodcutter")
    inst:AddTag("efficientworker")
    inst:AddTag("extrapick")
    inst:AddTag("bearded")

    inst:AddTag("balloonomancer")

    inst:AddTag("masterchef")
    inst:AddTag("professionalchef")
    inst:AddTag("expertchef")
    inst:AddTag("companion")

end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	
    inst.components.eater.strongstomach = true
	
    inst:AddTag("dogrider")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("warlyextra")

	inst:AddComponent("reader")
    inst:AddComponent("petleash")
    inst.components.petleash:SetOnSpawnFn(OnSpawn)
    inst.components.petleash:SetOnDespawnFn(OnDespawn)
    inst.components.petleash:SetMaxPets(10)
	local myrecipes = {
    "nightmarefuel", "purplegem",
    "researchlab3", "resurrectionstatue", "panflute",
    "onemanband", "nightlight",
    "amulet", "blueamulet", "icestaff", "book_sleep"
}
 
    if inst.components.builder then
        for k, v in pairs(myrecipes) do
            inst.components.builder:AddRecipe(v)
        end
    end
    inst.components.locomotor.walkspeed = (TUNING.WILSON_WALK_SPEED * 2)
    inst.components.locomotor.runspeed = (TUNING.WILSON_RUN_SPEED * 2)
    
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"
	inst:AddTag("maki")
	-- Stats	
	inst.components.health:SetMaxHealth(400)
	inst.components.hunger:SetMax(400)
    inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE*.1)
	inst.components.hunger:SetKillRate(TUNING.WILSON_HEALTH*.1/TUNING.STARVE_KILL_TIME)
	inst.components.sanity:SetMax(450)

    inst.components.sanity.night_drain_mult = 0 

	-- Damage multiplier (optional)
    inst.components.combat.damagemultiplier = 2

    inst.components.builder.science_bonus = 1

	-- Hunger rate (optional)
	inst.components.hunger.hungerrate = 0.1 * TUNING.WILSON_HUNGER_RATE

	inst.OnLoad = onload
    inst.OnNewSpawn = onload

    inst._onpetlost = function(pet) inst.components.sanity:RemoveSanityPenalty(pet) end

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_becomeghost", OnDeath)
end

return MakePlayerCharacter("makiri", prefabs, assets, common_postinit, master_postinit, start_inv)
