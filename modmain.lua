PrefabFiles = {
	"tunnel",
	"schemetool",
	"taggable_classified",
}

Assets = {
	Asset( "IMAGE", "images/map_icons/minimap_tunnel.tex"),
	Asset( "ATLAS", "images/map_icons/minimap_tunnel.xml"),
	Asset( "IMAGE", "images/map_icons/schemetool.tex" ),
	Asset( "ATLAS", "images/map_icons/schemetool.xml" ),

	Asset( "ANIM" , "anim/ui_board_5x1.zip"),
}

----- GLOBAL & require list -----
local require = GLOBAL.require
local TECH = GLOBAL.TECH
local RECIPETABS = GLOBAL.RECIPETABS
local TaggableWidget = require "widgets/taggablewidget"
local SchemeUI = require "screens/schemeui"

require "class"
GLOBAL.TUNNELNETWORK = {}
GLOBAL.TUNNELFIRSTINDEX = nil
GLOBAL.TUNNELLASTINDEX = nil
GLOBAL.NUMTUNNEL = 0

AddMinimapAtlas("images/map_icons/minimap_tunnel.xml")
AddMinimapAtlas("images/map_icons/schemetool.xml")
AddRecipe("schemetool", {Ingredient("nightmarefuel", 20), Ingredient("townportaltalisman", 10), Ingredient("orangemooneye", 2)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, nil, nil, nil, "images/inventoryimages/schemetool.xml", "schemetool.tex")
AddReplicableComponent("taggable")
------ Functions ------

RemoveScheme = function(player, target)
	local scheme = target.components.scheme
	if scheme ~= nil then
		if scheme.owner == player.userid or scheme.owner == nil then
			local DELCOST = GetModConfigData("delcost")

			if player ~= nil then
				player.SoundEmitter:PlaySound("dontstarve/common/staff_dissassemble")
		
				if player.components.sanity ~= nil then
					player.components.sanity:DoDelta(-DELCOST)
				end
			end

			target:Remove()
		end
	end
end
AddModRPCHandler("scheme", "remove", RemoveScheme)

SetTaggableText = function(player, target, text)
    local taggable = target.components.taggable
	local scheme = target.components.scheme
    if taggable ~= nil then
		if target.classified.shouldUI:value() then
			taggable:EndAction()
		else
			taggable:DoneAction(player, text)
		end
    end

	if scheme ~= nil then
		scheme:SetOwner(player)
	end
end
AddModRPCHandler("scheme", "write", SetTaggableText)

AddClassPostConstruct("screens/playerhud", function(self, anim, owner)
	self.ShowTaggableWidget = function(self, taggable, config)
		if taggable == nil then
			return
		else
			self.taggablescreen = TaggableWidget(self.owner, taggable, config)
			self:OpenScreenUnderPause(self.taggablescreen)
			if TheFrontEnd:GetActiveScreen() == self.taggablescreen then
				-- Have to set editing AFTER pushscreen finishes.
				self.taggablescreen.edit_text:SetEditing(true)
			end
			return self.taggablescreen
		end
	end

	self.CloseTaggableWidget = function()
		if self.taggablescreen then
			self.taggablescreen:Close()
			self.taggablescreen = nil
		end
	end

	self.ShowSchemeUI = function(src, inst)
		if inst == nil then
			return 
		else
			self.schemescreen = SchemeUI(self.owner, inst)
			self:OpenScreenUnderPause(self.schemescreen)
			return self.schemescreen
		end
	end

	self.CloseSchemeUI = function(src)
		if self.schemescreen ~= nil then
			self.schemescreen:Close()
			self.schemescreen = nil
		end
	end
end)

modimport "scripts/schememanager.lua"
modimport "scripts/actions_scheme.lua"
modimport "scripts/strings_scheme.lua"