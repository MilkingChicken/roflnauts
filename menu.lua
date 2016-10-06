-- `Menu` (Scene)
-- It creates single screen of a menu
-- I do know that model I used here and in `World` loading configuration files is not flawless but I did not want to rewrite `World`s one but wanted to keep things similar at least in project scope.

require "music"

-- Here it begins
Menu = {
	scale = getScale(),
	elements, --table
	active = 1,
	music,
	sprite,
	background,
	quads = {
		button = {
			normal = love.graphics.newQuad(0, 0, 58,15, 80,130),
			active = love.graphics.newQuad(0, 0, 58,15, 80,130)
		},
		portrait = {
			normal = love.graphics.newQuad( 0, 15, 32,32, 80,130),
			active = love.graphics.newQuad(32, 15, 32,32, 80,130)
		},
		panorama = {
			normal = love.graphics.newQuad(0,47, 80,42, 80,130),
			active = love.graphics.newQuad(0,88, 80,42, 80,130)
		},
		arrow_l = love.graphics.newQuad(68, 0, 6, 6, 80,130),
		arrow_r = love.graphics.newQuad(74, 0, 6, 6, 80,130),
	}
}
function Menu:new(name)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	self.sprite = love.graphics.newImage("assets/menu.png")
	self.background = love.graphics.newImage("assets/backgrounds/menu.png")
	o.elements = {}
	o:load(name)
	o.music = Music:new("menu.ogg")
	return o
end
function Menu:delete()
	self.music:delete()
end

-- Load menu from file
function Menu:load(name)
	local name = "config/" .. (name or "menumain") .. ".lua"
	local menu = love.filesystem.load(name)
	self.active = 1
	self.elements = menu(self)
	self.elements[self.active]:focus()
end

-- Return reference to quads table and menu sprite
function Menu:getSheet()
	return self.sprite, self.quads
end

-- Cycle elements
function Menu:next()
	self.elements[self.active]:blur()
	self.active = (self.active%#self.elements)+1
	if not self.elements[self.active]:focus() then
		self:next()
	end
end
function Menu:previous()
	self.elements[self.active]:blur()
	if self.active == 1 then
		self.active = #self.elements
	else
		self.active = self.active - 1
	end
	if not self.elements[self.active]:focus() then
		self:previous()
	end
end

-- LÖVE2D callbacks
function Menu:update(dt)
	for _,element in pairs(self.elements) do
		element:update(dt)
	end
end
function Menu:draw()
	local scale = self.scale
	love.graphics.draw(self.background, 0, 0, 0, scale, scale)
	love.graphics.setFont(Font)
	for _,element in pairs(self.elements) do
		element:draw(scale)
	end
end

-- Controller callbacks
function Menu:controlpressed(set, action, key)
	if action == "down" then
		self:next()
	end
	if action == "up" then
		self:previous()
	end
	for _,element in pairs(self.elements) do
		element:controlpressed(set, action, key)
	end
end
function Menu:controlreleased(set, action, key) end