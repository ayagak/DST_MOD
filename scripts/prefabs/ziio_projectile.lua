local assets=
{
    Asset("ANIM", "anim/staff_projectile.zip"),
}

local projectile      = TUNING.ZIIOSWORDFUNCTION.PROJECTILE


local function SpawnPoop(inst, owner, target)
    local poop = SpawnPrefab(projectile)

    if target ~= nil and target:IsValid() then
        LaunchAt(poop, target, owner ~= nil and owner:IsValid() and owner or inst)
    else
        poop.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function OnHit(inst, owner, target)
    if projectile then
        SpawnPoop(inst, owner, target)
    end
    inst:Remove()
end

local function OnMiss(inst, owner, target)
    -- if projectile then
    --     SpawnPoop(inst, owner, nil)
    -- end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("projectile")
    inst.AnimState:SetBuild("staff_projectile")
    inst.AnimState:PlayAnimation("ice_spin_loop", true)

	inst.entity:AddLight()
    inst.Light:Enable(true)
	inst.Light:SetRadius(5)
    inst.Light:SetFalloff(0.2)
    inst.Light:SetIntensity(0.95)
    inst.Light:SetColour(255/255,255/255,255/255)

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(40)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.range = 30

    return inst
end



return Prefab( "common/inventory/ziio_projectile", fn, assets)
	  
      
