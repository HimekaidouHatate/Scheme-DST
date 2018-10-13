local assets =
{
	Asset("ANIM", "anim/tunnel.zip" ),
}

local function onremoved(inst, doer)
	if inst.components.scheme ~= nil then
		inst.components.scheme:Disconnect(inst.components.scheme.index)
	end
end

local function GetDesc(inst, viewer)
	local index = inst.components.scheme.index
	local pointer = inst.components.scheme.pointer or "none"
	return string.format( "Index is "..index.." and is connected to "..pointer )
end

local function onaccept(inst, giver, item)
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)
end

local function fn()
	local inst = CreateEntity()    
	
	inst.entity:AddTransform()    
	inst.entity:AddAnimState()    
	inst.entity:AddSoundEmitter()  
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()	
    
    inst.MiniMapEntity:SetIcon("minimap_tunnel.tex")
   
    inst.AnimState:SetBank("tunnel")
    inst.AnimState:SetBuild("tunnel")
	inst.AnimState:SetLayer( LAYER_BACKGROUND )
	inst.AnimState:SetSortOrder( 3 )
	inst.AnimState:SetRayTestOnBB(true)

	inst:AddTag("tunnel") 
	inst:AddTag("teleporter")
    inst:AddTag("_writeable")--Sneak these into pristine state for optimization
	inst.islinked = net_bool(inst.GUID, "islinked")
	
	if not TheWorld.ismastersim then
		return inst
    end

	inst.entity:SetPristine()
	inst:RemoveTag("_writeable")

	inst:SetStateGraph("SGtunnel")
    inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = GetDesc

	inst:AddComponent("scheme")
	inst.components.scheme:InitGate()

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(5,5)
	inst.components.playerprox.onnear = function()
		if inst.components.scheme:IsConnected() and not (inst.sg.currentstate.name == ("open" or "opening")) then
			inst.sg:GoToState("opening")
		end
	end
	inst.components.playerprox.onfar = function()
		if inst.sg.currentstate.name == ("open" or "opening") then
			inst.sg:GoToState("closing")
		end
	end

	--inst:AddComponent("taggable")

	--inst:AddComponent("trader")
    --inst.components.trader.acceptnontradable = true
    --inst.components.trader.onaccept = onaccept
    --inst.components.trader.deleteitemonaccept = false

	inst.OnRemoveEntity = onremoved

    return inst
end

return Prefab( "common/objects/tunnel", fn, assets)