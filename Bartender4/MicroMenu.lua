--[[
	Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local MicroMenuMod = Bartender4:NewModule("MicroMenu", "AceHook-3.0")

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype

-- create prototype information
local MicroMenuBar = setmetatable({}, {__index = ButtonBar})

local _G = _G
local table_insert = table.insert

local defaultButtonNames = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"PVPMicroButton",
	"LFDMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton",
}

local defaults = { profile = Bartender4:Merge({
	enabled = true,
	vertical = false,
	visibility = {
		possess = false,
	},
	padding = -3,
	position = {
		scale = 0.8,
	},
}, Bartender4.ButtonBar.defaults) }

function MicroMenuMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("MicroMenu", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function MicroMenuMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("MicroMenu", self.db.profile, L["Micro Menu"]), {__index = MicroMenuBar})
		self:UpdateButtons()

		self:SecureHook("UpdateMicroButtons")
	end
	self:UpdateButtons()
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function MicroMenuMod:UpdateButtons()
	if not self.bar then return end

	local buttons = {}
	local seen = {}

	local function addButton(btn)
		if not btn or seen[btn] then return end
		seen[btn] = true
		table_insert(buttons, btn)
	end

	if type(MICRO_BUTTONS) == "table" then
		for i, name in ipairs(MICRO_BUTTONS) do
			addButton(_G[name])
		end
	end

	if #buttons == 0 then
		for i, name in ipairs(defaultButtonNames) do
			addButton(_G[name])
		end
	end

	-- Also catch custom micro buttons attached to the default micro menu parent.
	local defaultParent = HelpMicroButton and HelpMicroButton:GetParent()
	if defaultParent then
		for i, child in ipairs({defaultParent:GetChildren()}) do
			if child and child:IsObjectType("Button") then
				local name = child:GetName()
				if name and name:find("MicroButton") then
					addButton(child)
				end
			end
		end
	end

	self.bar.buttons = buttons
	MicroMenuMod.button_count = #buttons

	for i, v in pairs(buttons) do
		v:SetParent(self.bar)
		v:Show()
		v:SetFrameLevel(self.bar:GetFrameLevel() + 1)
		v.ClearSetPoint = self.bar.ClearSetPoint
	end

	if self.optionobject then
		self.optionobject.table.general.args.rows.max = #buttons
	end
end

function MicroMenuMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function MicroMenuMod:RestoreButtons()
	if not self:IsEnabled() then return end
	self:UpdateButtons()
	for k,v in pairs(self.bar.buttons) do
		v:SetParent(self.bar)
		v:Show()
	end
	self.bar:UpdateButtonLayout()
end

function MicroMenuMod:UpdateMicroButtons()
	if MainMenuBar.state == "player" then
		self:RestoreButtons()
	end
end

MicroMenuBar.button_width = 28
MicroMenuBar.button_height = 58
MicroMenuBar.vpad_offset = -21
function MicroMenuBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", -105, 30)
		self:SavePosition()
	end

	self:UpdateButtonLayout()
end
