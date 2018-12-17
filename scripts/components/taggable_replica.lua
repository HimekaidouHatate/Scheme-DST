local taggables = require"taggables"

local Taggable = Class(function(self, inst)
    self.inst = inst

    self.screen = nil
    self.opentask = nil
	self._serializeddata = net_string(inst.GUID, "taggable._info") -- this is readonly.
	self.index = net_byte(inst.GUID, "taggable.index")

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("taggable_classified")
        self.classified.entity:SetParent(inst.entity)
		self.inst.classified = self.classified -- leave reference
    else
        if self.classified == nil and inst.taggable_classified ~= nil then
            self.classified = inst.taggable_classified
            inst.taggable_classified.OnRemoveEntity = nil
            inst.taggable_classified = nil
            self:AttachClassified(self.classified)
        end
    end
end)

--------------------------------------------------------------------------

function Taggable:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified:Remove()
            self.classified = nil
        else
            self.classified._parent = nil
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Taggable.OnRemoveEntity = Taggable.OnRemoveFromEntity

--------------------------------------------------------------------------
--Client triggers writing based on receiving access to classified data
--------------------------------------------------------------------------

local function OpenFn(inst, self)
    self.opentask = nil
	if self.classified.shouldUI:value() then
		self:SelectPopup(ThePlayer)
	else
		self:BeginWriting(ThePlayer)
	end
end

function Taggable:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    self.opentask = self.inst:DoTaskInTime(0, OpenFn, self)
end

function Taggable:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    self:EndAction()
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

function Taggable:BeginWriting(doer)
    if self.inst.components.taggable ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.taggable:BeginWriting(doer)
    elseif self.classified ~= nil
        and self.opentask == nil
        and doer ~= nil
        and doer == ThePlayer then

        if doer.HUD == nil then
            -- abort
        else -- if not busy...
            self.screen = taggables.makescreen(self.inst, doer)
        end
    end
end

function Taggable:SelectPopup(doer)
    if self.inst.components.taggable ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.taggable:SelectPopup(doer)
    elseif self.classified ~= nil
        and self.opentask == nil
        and doer ~= nil
        and doer == ThePlayer then

        if doer.HUD == nil then
            -- abort
        else -- if not busy...
            self.screen = doer.HUD:ShowSchemeUI(self.inst)
        end
    end
end

function Taggable:DoAction(doer, text, index)
    --NOTE: text may be network data, so enforcing length is
    --      NOT redundant in order for rendering to be safe.
	if self.inst.components.taggable ~= nil then
		self.inst.components.taggable:DoAction(doer, text, index)
	elseif index ~= nil then --Some.. bad example of implementing overload
		SendModRPCToServer(MOD_RPC["scheme"]["teleport"], index, self.inst)
	elseif self.classified ~= nil and doer == ThePlayer and (text == nil or text:utf8len() <= MAX_WRITEABLE_LENGTH / 4) then
		SendModRPCToServer(MOD_RPC["scheme"]["write"], self.inst, text)
	end
end

function Taggable:Remove(doer)
	if self.classified ~= nil and doer == ThePlayer then
		SendModRPCToServer(MOD_RPC["scheme"]["remove"], self.inst)
	end
end

function Taggable:EndAction()
    if self.opentask ~= nil then
        self.opentask:Cancel()
        self.opentask = nil
    end
    if self.inst.components.taggable ~= nil then
        self.inst.components.taggable:EndAction()
    elseif self.screen ~= nil then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            ThePlayer.HUD:CloseWriteableWidget()
            ThePlayer.HUD:CloseSchemeUI()
        elseif self.screen.inst:IsValid() then
            --Should not have screen and no writer, but just in case...
            self.screen:Kill()
        end
        self.screen = nil
    end
end

function Taggable:SetWriter(writer)
    self.classified.Network:SetClassifiedTarget(writer or self.inst)
    if self.inst.components.taggable == nil then
        --Should only reach here during taggable construction
        assert(writer == nil)
    end
end

return Taggable