local Assets =
{
	Asset("ANIM", "anim/souldrops.zip"), -- a standard asset
    Asset("ATLAS", "images/inventoryimages/souldrops.xml"),    -- a custom asset, found in the mod folder
}


local function itemfn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("myprefab")
    inst.AnimState:SetBuild("souldrops")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("lightbattery")

    if not TheWorld.ismastersim then   
      return inst  
    end   
    
    inst.entity:SetPristine() 

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/souldrops.xml"

	inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("healer")
    local healer = inst.components.healer
    healer:SetHealthAmount(0)
    healer.souldrops_fn01 = healer.Heal
    function healer:Heal(target)
    	if target.components.sanity then
            target.components.sanity:DoDelta(100)
	    end
        healer:souldrops_fn01(target)
    end

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = 30 * 8
    inst.components.fuel.fueltype = "CAVE"

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(255/255, 255/255, 255/255)
    inst.Light:Enable(true)
    inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )

    MakeHauntableLaunch(inst)
    return inst
end


-- Add some strings for this item
STRINGS.NAMES.SOULDROPS = "Soul Drops"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SOULDROPS = "It recovers player's sanity well."


-- Finally, return a new prefab with the construction function and assets.
return Prefab( "common/inventory/souldrops", itemfn, Assets)
