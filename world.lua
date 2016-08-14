-- `World`
-- Used to manage physical world and everything inside it: clouds, platforms, nauts, background etc.

-- WHOLE CODE HAS FLAG OF "need a cleanup"

require "ground"
require "player"
require "cloud"
require "effect"
require "decoration"
require "ray"

-- Metatable of `World`
-- nils initialized in constructor
World = {
	-- inside
	world = nil,
	Nauts = nil,
	Platforms = nil,
	Clouds = nil,
	Decorations = nil,
	Effects = nil,
	Rays = nil,
	camera = nil,
	-- cloud generator
	clouds_delay = 5,
	-- Map
	map = nil,
	background = nil,
	-- Gameplay status
	lastNaut = false,
	-- "WINNER"
	win_move = 0,
	-- Music
	music = nil
}

-- Constructor of `World` ZA WARUDO!
function World:new(map, ...)
	-- Meta
	local o = {}
	setmetatable(o, self)
	self.__index = self
	-- Physical world initialization
	love.physics.setMeter(64)
	o.world = love.physics.newWorld(0, 9.81*64, true)
	o.world:setCallbacks(o.beginContact, o.endContact)
	-- Empty tables for objects
	local n = {}
	o.Nauts = n
	local p     = {}
	o.Platforms = {}
	local c  = {}
	o.Clouds = c
	local e   = {}
	o.Effects = e
	local d = {}
	o.Decorations = d
	local r = {}
	o.Rays = r
	-- Random init
	math.randomseed(os.time())
	-- Map
	local map = map or "default"
	o:loadMap(map)
	-- Nauts
	o:spawnNauts(...)
	-- Create camera
	o.camera = Camera:new(o)
	-- Play music
	o.music = Music:new(o.map.theme)
	return o
end

-- The end of the world
function World:delete()
	self.world:destroy()
	for _,platform in pairs(self.Platforms) do
	 	platform:delete()
	end
	for _,naut in pairs(self.Nauts) do
		naut:delete()
	end
	self.music:delete()
	self = nil
end

-- Load map from file
function World:loadMap(name)
	local name = name or "default"
	name = "maps/" .. name .. ".lua"
	local map = love.filesystem.load(name)
	self.map = map()
	-- Platforms
	for _,platform in pairs(self.map.platforms) do
		self:createPlatform(platform.x, platform.y, platform.shape, platform.sprite)
	end
	-- Decorations
	for _,decoration in pairs(self.map.decorations) do
		self:createDecoration(decoration.x, decoration.y, decoration.sprite)
	end
	-- Background
	self.background = love.graphics.newImage(self.map.background)
	-- Clouds
	if self.map.clouds then
		for i=1,6 do
			self:randomizeCloud(false)
		end
	end
end

-- Spawn all the nauts for the round
function World:spawnNauts(...)
	local params = {...}
	local nauts = nil
	if type(params[1][1]) == "table" then
		nauts = params[1]
	else
		nauts = params
	end
	for _,naut in pairs(nauts) do
		local x,y = self:getSpawnPosition()
		local spawn = self:createNaut(x, y, naut[1])
		spawn:assignControlSet(naut[2])
	end
end

-- Get respawn location
function World:getSpawnPosition()
	local n = math.random(1, #self.map.respawns)
	return self.map.respawns[n].x, self.map.respawns[n].y
end

-- Add new platform to the world
function World:createPlatform(x, y, polygon, sprite)
	table.insert(self.Platforms, Ground:new(self, self.world, x, y, polygon, sprite))
end

-- Add new naut to the world
function World:createNaut(x, y, name)
	local naut = Player:new(self, self.world, x, y, name)
	table.insert(self.Nauts, naut)
	return naut
end

-- Add new decoration to the world
function World:createDecoration(x, y, sprite)
	table.insert(self.Decorations, Decoration:new(x, y, sprite))
end

-- Add new cloud to the world
function World:createCloud(x, y, t, v)
	table.insert(self.Clouds, Cloud:new(x, y, t, v))
end

-- Randomize Cloud creation
function World:randomizeCloud(outside)
	if outside == nil then
		outside = true
	else
		outside = outside
	end
	local x,y,t,v
	local m = self.map
	if outside then
		x = m.center_x-m.width*1.2+math.random(-50,20)
	else
		x = math.random(m.center_x-m.width/2,m.center_x+m.width/2)
	end
	y = math.random(m.center_y-m.height/2, m.center_y+m.height/2)
	t = math.random(1,3)
	v = math.random(8,18)
	self:createCloud(x, y, t, v)
end

-- Add an effect behind nauts
function World:createEffect(name, x, y)
	table.insert(self.Effects, Effect:new(name, x, y))
end

-- Add a ray
function World:createRay(naut)
	table.insert(self.Rays, Ray:new(naut, self))
end

-- get Nauts functions
-- more than -1 lives
function World:getNautsPlayable()
	local nauts = {}
	for _,naut in pairs(self.Nauts) do
		if naut.lives > -1 then
			table.insert(nauts, naut)
		end
	end
	return nauts
end
-- are alive
function World:getNautsAlive()
	local nauts = {}
	for _,naut in self.Nauts do
		if naut.alive then
			table.insert(nauts, naut)
		end
	end
	return nauts
end
-- all of them
function World:getNautsAll()
	return self.Nauts
end

-- get Map name
function World:getMapName()
	return self.map.name
end

-- Event: when player is killed
function World:onNautKilled(naut)
	self.camera:startShake()
	self:createRay(naut)
	local nauts = self:getNautsPlayable()
	if self.lastNaut then
		local m = Menu:new()
		for _,controller in pairs(Controllers) do
			m:assignController(controller)
		end
		changeScene(m)
	elseif #nauts < 2 then
		self.lastNaut = true
	end
end

function World:getBounce(f)
	local f = f or 1
	return math.sin(self.win_move*f*math.pi)
end

-- LÖVE2D callbacks
-- Update ZU WARUDO
function World:update(dt)
	-- Physical world
	self.world:update(dt)
	-- Camera
	self.camera:update(dt)
	-- Nauts
	for _,naut in pairs(self.Nauts) do
		naut:update(dt)
	end
	-- Clouds
	if self.map.clouds then
		-- generator
		local n = table.getn(self.Clouds)
		self.clouds_delay = self.clouds_delay - dt
		if self.clouds_delay < 0 and
		   n < 18
		then
			self:randomizeCloud()
			self.clouds_delay = self.clouds_delay + World.clouds_delay -- World.clouds_delay is initial
		end
		-- movement
		for _,cloud in pairs(self.Clouds) do
			if cloud:update(dt) > 340 then
				table.remove(self.Clouds, _)
			end
		end
	end
	-- Effects
	for _,effect in pairs(self.Effects) do
		if effect:update(dt) then
			table.remove(self.Effects, _)
		end
	end
	-- Rays
	for _,ray in pairs(self.Rays) do
		if ray:update(dt) then
			table.remove(self.Rays, _)
		end
	end
	-- Bounce `winner`
	self.win_move = self.win_move + dt
	if self.win_move > 2 then
		self.win_move = self.win_move - 2
	end
end
-- Draw
function World:draw()
	-- Camera stuff
	local offset_x, offset_y = self.camera:getOffsets()
	local scale = self.camera.scale
	local scaler = self.camera.scaler
	
	-- Background
	love.graphics.draw(self.background, 0, 0, 0, scaler, scaler)
	
	-- This needs to be reworked!
	-- Draw clouds
	for _,cloud in pairs(self.Clouds) do
		cloud:draw(offset_x, offset_y, scale)
	end

	-- Draw decorations
	for _,decoration in pairs(self.Decorations) do
		decoration:draw(offset_x, offset_y, scale)
	end

	-- Draw effects
	for _,effect in pairs(self.Effects) do
		effect:draw(offset_x,offset_y, scale)
	end

	-- Draw player
	for _,naut in pairs(self.Nauts) do
		naut:draw(offset_x, offset_y, scale, debug)
	end

	-- Draw ground
	for _,platform in pairs(self.Platforms) do
		platform:draw(offset_x, offset_y, scale, debug)
	end

	-- Draw rays
	for _,ray in pairs(self.Rays) do
		ray:draw(offset_x, offset_y, scale)
	end

	-- draw center
	if debug then
		local c = self.camera
		local w, h = love.graphics.getWidth(), love.graphics.getHeight()
		-- draw map center
		love.graphics.setColor(130,130,130)
		love.graphics.setLineWidth(1)
		love.graphics.setLineStyle("rough")
		local cx, cy = c:getPositionScaled()
		local x1, y1 = c:translatePosition(self.map.center_x, cy)
		local x2, y2 = c:translatePosition(self.map.center_x, cy+h)
		love.graphics.line(x1,y1,x2,y2)
		local x1, y1 = c:translatePosition(cx, self.map.center_y)
		local x2, y2 = c:translatePosition(cx+w, self.map.center_y)
		love.graphics.line(x1,y1,x2,y2)
		-- draw ox, oy
		love.graphics.setColor(200,200,200)
		love.graphics.setLineStyle("rough")
		local cx, cy = c:getPositionScaled()
		local x1, y1 = c:translatePosition(0, cy)
		local x2, y2 = c:translatePosition(0, cy+h)
		love.graphics.line(x1,y1,x2,y2)
		local x1, y1 = c:translatePosition(cx, 0)
		local x2, y2 = c:translatePosition(cx+w, 0)
		love.graphics.line(x1,y1,x2,y2)
	end

	-- Draw HUDs
	for _,naut in pairs(self.Nauts) do
		-- I have no idea where to place them T_T
		-- let's do: bottom-left, bottom-right, top-left, top-right
		local w, h = love.graphics.getWidth()/scale, love.graphics.getHeight()/scale
		local y, e = 1, 1
		if _ < 3 then y, e = h-33, 0 end
		naut:drawHUD(1+(_%2)*(w-34), y, scale, e)
	end
	
	-- Draw winner
	if self.lastNaut then
		local w, h = love.graphics.getWidth()/scale, love.graphics.getHeight()/scale
		local angle = self:getBounce(2)
		local dy = self:getBounce()*3
		love.graphics.setFont(Bold)
		love.graphics.printf("WINNER",(w/2)*scale,(42+dy)*scale,336,"center",(angle*5)*math.pi/180,scale,scale,168,12)
		love.graphics.setFont(Font)
		love.graphics.printf("rofl, now kill yourself", w/2*scale, 18*scale, 160, "center", 0, scale, scale, 80, 3)
	end
end

-- Box2D callbacks
-- beginContact
function World.beginContact(a, b, coll)
	if a:getCategory() == 1 then
		local x,y = coll:getNormal()
		if y < -0.6 then
			print(b:getUserData().name .. " is not in air")
			-- Move them to Player
			b:getUserData().inAir = false
			b:getUserData().jumpnumber = 2
			b:getUserData().salto = false
			b:getUserData():createEffect("land")
		end
		local vx, vy = b:getUserData().body:getLinearVelocity()
		if math.abs(x) == 1 or (y < -0.6 and x == 0) then
			b:getUserData():playSound(3)
		end
	end
end
-- endContact
function World.endContact(a, b, coll)
	if a:getCategory() == 1 then
		print(b:getUserData().name .. " is in air")
		-- Move them to Player
		b:getUserData().inAir = true
	end
end

-- Controller callbacks
function World:controlpressed(set, action, key)
	if key == "f6" and debug then
		local map = self:getMapName()
		local nauts = {}
		for _,naut in pairs(self:getNautsAll()) do
			table.insert(nauts, {naut.name, naut:getControlSet()})
		end
		local new = World:new(map, nauts)
		changeScene(new)
	end
	for k,naut in pairs(self:getNautsAll()) do
		naut:controlpressed(set, action, key)
	end
end
function World:controlreleased(set, action, key)
	for k,naut in pairs(self:getNautsAll()) do
		naut:controlreleased(set, action, key)
	end
end