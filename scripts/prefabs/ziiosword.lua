require "prefabutil"
require "recipe"
require "modutil"

local assets=
{
    Asset("ANIM", "anim/all_staff.zip"),
    Asset("ANIM", "anim/swap_all_staff.zip"),
    Asset("IMAGE", "images/inventoryimages/ziiosword.tex"),
    Asset("ATLAS", "images/inventoryimages/ziiosword.xml"),
}

local RcpType         = TUNING.ZiioRecipeType
local sideeffect      = TUNING.ZIIOSWORDFUNCTION.PUNISH
-- TOOL SETTINGS
local hammermode      = TUNING.ZIIOSWORDFUNCTION.HAMMER
local digmode         = TUNING.ZIIOSWORDFUNCTION.DIG
local netmode         = TUNING.ZIIOSWORDFUNCTION.NET
local oarmode         = TUNING.ZIIOSWORDFUNCTION.OAR
-- local fishmode        = true
local fishmode        = TUNING.ZIIOSWORDFUNCTION.FISH
local lightmode       = TUNING.ZIIOSWORDFUNCTION.LIGHT
local umbrellamode    = TUNING.ZIIOSWORDFUNCTION.UMBRELLA
local telepoofmode    = TUNING.ZIIOSWORDFUNCTION.TELEPOOF
local walkspeed       = TUNING.ZIIOSWORDFUNCTION.WALKSPEED

-- WAEPON SETTINGS
local damage          = TUNING.ZIIOSWORDFUNCTION.DAMAGE
local rangemode       = TUNING.ZIIOSWORDFUNCTION.RANGE
local projectile      = TUNING.ZIIOSWORDFUNCTION.PROJECTILE
local healthmode      = TUNING.ZIIOSWORDFUNCTION.HEALTH
local sanitymode      = TUNING.ZIIOSWORDFUNCTION.SANITY
local icemode         = TUNING.ZIIOSWORDFUNCTION.ICE
local sleepmode       = TUNING.ZIIOSWORDFUNCTION.SLEEP
local brimstonemode   = TUNING.ZIIOSWORDFUNCTION.BRIMSTONE
local tentaclemode    = TUNING.ZIIOSWORDFUNCTION.TENTACLE


local TENTACLES_BLOCKED_CANT_TAGS = { "INLIMBO", "FX" }

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_all_staff", "swap_all_staff")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    if lightmode then
        inst.Light:Enable(true)
    end
end


local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if lightmode then
        inst.Light:Enable(false)
    end
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    -- 副作用：卸下惩罚（越便宜+伤害高，惩罚力度越大）
    if sideeffect then
        if RcpType == 1 and damage > 999 then
            owner.components.hunger:DoDelta(- owner.components.hunger.max * 0.8)
            owner.components.sanity:DoDelta(- owner.components.sanity.max * 0.8)
            owner.components.health:DoDelta(- owner.components.health.maxhealth * 0.8)
        elseif  RcpType == 1 or damage > 999 then
            owner.components.hunger:DoDelta(- owner.components.hunger.max * 0.5)
            owner.components.sanity:DoDelta(- owner.components.sanity.max * 0.5)
            -- owner.components.health:DoDelta(- owner.components.health.maxhealth * 0.5)
            owner.components.health:SetPercent(0.5)
        elseif RcpType == 2 then
            owner.components.hunger:DoDelta(- owner.components.hunger.max * 0.2)
            owner.components.sanity:DoDelta(- owner.components.sanity.max * 0.2)
            -- owner.components.health:DoDelta(- owner.components.health.maxhealth * 0.2)
            owner.components.health:SetPercent(0.2)
        end
    end    
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function onattack(inst, owner, target)
    if owner.components.health and sideeffect then
        owner.components.hunger:DoDelta(-1)
        owner.components.sanity:DoDelta(-1)
        owner.components.health:DoDelta(-1)
    end
    -- 攻击回血
    if owner.components.health and healthmode then
        owner.components.health:DoDelta(25)
    end
    -- 攻击回精神
    if owner.components.sanity and sanitymode then
        owner.components.sanity:DoDelta(10)
    end
    -- 冰冻效果（2下才冰住）
    if icemode then
        if target.components.freezable ~= nil then
            target.components.freezable:AddColdness(10)
            target.components.freezable:SpawnShatterFX()
        end
    end
    -- 睡眠效果（1~2下才睡着）
    if sleepmode then
        if target.components.sleeper ~= nil then
            target.components.sleeper:AddSleepiness(8, 60, inst)
        elseif target.components.grogginess ~= nil then
            target.components.grogginess:AddGrogginess(8, 60)
        end
    end
    -- 召唤雷电
    if brimstonemode then
        local pt = target:GetPosition()
        local num_lightnings = 4
        owner:StartThread(function()
            for k = 0, num_lightnings do
                local rad = 1
                local angle = k * 1 * PI / num_lightnings
                local pos = pt + Vector3(rad * math.cos(angle), 0, rad * math.sin(angle))
                TheWorld:PushEvent("ms_sendlightningstrike", pos)
                owner.components.sanity:DoDelta(1)
                owner.components.health:DoDelta(2)
                Sleep(.3 + math.random() * .2)
            end
        end)
    end
    -- 召唤触手
    if tentaclemode then
        local pt = target:GetPosition()
        local numtentacles = 3

        owner:StartThread(function()
            if tentaclemode == 'normal' then
                for k = 1, numtentacles do
                    local theta = math.random() * 2 * PI
                    local radius = math.random(3, 8)

                    local result_offset = FindValidPositionByFan(theta, radius, 12, function(offset)
                        local pos = pt + offset
                        --NOTE: The first search includes invisible entities
                        return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, TENTACLES_BLOCKED_CANT_TAGS) <= 0
                            and TheWorld.Map:IsPassableAtPoint(pos:Get())
                            and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
                    end)
                    
                    
                    if result_offset ~= nil then
                        local x, z = pt.x + result_offset.x, pt.z + result_offset.z
                        local tentacle = SpawnPrefab("tentacle")
                        tentacle.Transform:SetPosition(x, 0, z)
                        tentacle.sg:GoToState("attack_pre")
                        tentacle.components.combat:SetTarget(target)
                        tentacle.components.health:SetMaxHealth(100)
                        tentacle:StartThread(function()
                            while tentacle.components.health.currenthealth > 0 do
                                tentacle.components.health:DoDelta(-10)
                                Sleep(1)
                            end
                        end)

                        --need a better effect
                        SpawnPrefab("splash_ocean").Transform:SetPosition(x, 0, z)
                        ShakeAllCameras(CAMERASHAKE.FULL, .2, .02, .25, target, 40)
                    end

                    Sleep(.33)
                end
            
            elseif tentaclemode == 'shadow' then
                for k = 1, numtentacles do
                    local pt = target:GetPosition()
                    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 2, 3, false, true, NoHoles)
                    if offset ~= nil then
                        inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
                        inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
                        local tentacle = SpawnPrefab("shadowtentacle")
                        if tentacle ~= nil then
                            tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                            tentacle.components.combat:SetTarget(target)
                        end
                    end
                end
            end
        end)
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon( "ziiosword.tex" )
    
    if lightmode then
        inst.entity:AddLight()
        inst.Light:SetRadius(10)
        inst.Light:SetFalloff(0.5)
        inst.Light:SetIntensity(0.95)
        inst.Light:SetColour(255/255,255/255,255/255)
    end
    
    inst.AnimState:SetBank("all_staff")
    inst.AnimState:SetBuild("all_staff")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("ziio")
    inst:AddTag("ziiosword")
    inst:AddTag("sharp")
    if lightmode then
        inst:AddTag("light")
    end
    
    if umbrellamode then
        inst:AddTag("umbrella")
        inst:AddTag("waterproofer")
    end


    if fishmode then
        inst:AddTag("fishingrod")
        -- inst:AddTag("accepts_oceanfishingtackle") -- 海钓竿
    end

    if oarmode or fishmode then
        inst:AddTag("allow_action_on_impassable")
    end

    local floater_swap_data =
    {
        sym_build = "swap_all_staff",
        bank = "all_staff",
    }
    MakeInventoryFloatable(inst, "med", 0.05, {1.0, 0.4, 1.0}, true, -17.5, floater_swap_data)

    -- 海钓竿？
    -- if fishmode then
    --     inst:AddComponent("reticule")
    --     inst.components.reticule.targetfn = reticuletargetfn
    --     inst.components.reticule.shouldhidefn = reticuleshouldhidefn
    --     inst.components.reticule.ease = true
    --     inst.components.reticule.ispassableatallpoints = true
    -- end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/ziiosword.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.walkspeedmult = walkspeed,
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(damage)
    if rangemode then inst.components.weapon:SetRange(rangemode, rangemode) end
    inst.components.weapon:SetOnAttack(onattack)
    if projectile then
        inst.components.weapon:SetProjectile("ziio_projectile")
    end

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP,   100)
    inst.components.tool:SetAction(ACTIONS.MINE,   100)
    if hammermode then
        inst.components.tool:SetAction(ACTIONS.HAMMER, 100)
    end
    if digmode then
        inst.components.tool:SetAction(ACTIONS.DIG,    100)
    end
    if netmode then
        inst.components.tool:SetAction(ACTIONS.NET,    100)
    end

    if telepoofmode then
        inst:AddComponent("blinkstaff")
        inst.components.blinkstaff:SetFX("sand_puff_large_front", "sand_puff_large_back")
    end

    inst:AddInherentAction(ACTIONS.TILL)
    inst:AddComponent("farmtiller")


    -- 普通钓竿
    if fishmode then
        inst:AddComponent("fishingrod")
        inst.components.fishingrod:SetWaitTimes(1,3)
        inst.components.fishingrod:SetStrainTimes(0,10)
    end

    -- 海钓竿？
    -- if fishmode then
    --     inst:AddComponent("oceanfishingrod")
    --     inst.components.oceanfishingrod:SetDefaults("oceanfishingbobber_none_projectile", TUNING.OCEANFISHING_TACKLE.BASE, TUNING.OCEANFISHING_LURE.HOOK, {build = "oceanfishing_hook", symbol = "hook"})
    --     inst.components.oceanfishingrod.oncastfn = OnStartedFishing
    --     inst.components.oceanfishingrod.ondonefishing = OnDoneFishing
    --     inst.components.oceanfishingrod.onnewtargetfn = OnHookedSomething
    --     inst.components.oceanfishingrod.gettackledatafn = GetTackle
    -- inst:AddComponent("container")
    -- inst.components.container:WidgetSetup("oceanfishingrod")
    -- inst.components.container.canbeopened = false
    -- inst:ListenForEvent("itemget", OnTackleChanged)
    -- inst:ListenForEvent("itemlose", OnTackleChanged)
    -- end

    if oarmode then
        inst:AddComponent("oar")
        inst.components.oar.force = 1
        inst.components.oar.max_velocity = 1
    end

    if umbrellamode then
        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(1)
    end

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 100

    MakeHauntableWork(inst)
    
    return inst
end

return Prefab( "common/inventory/ziiosword", fn, assets) 
