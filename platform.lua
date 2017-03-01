-- `Platform`
-- Static platform physical object with a sprite. `Players` can walk on it.
-- Collision category: [1]

-- WHOLE CODE HAS FLAG OF "need a cleanup"
require "sprite"

-- Metatable of `Platform`
-- nils initialized in constructor
Platform = {
	body = nil,
	shape = nil,
	fixture = nil,
	world = nil,
}
Platform.__index = Platform
setmetatable(Platform, Sprite)

-- Constructor of `Platform`
function Platform:new (game, world, x, y, shape, sprite, animations)
	local o = {}
	setmetatable(o, self)
	o.body  = love.physics.newBody(world, x, y)
	-- MULTIPLE SHAPES NEED TO BE REWRITED!
	o.shape = {}
	if type(shape[1]) == "number" then
		local poly = love.physics.newPolygonShape(shape)
		table.insert(o.shape, poly)
		o.fixture = love.physics.newFixture(o.body, poly)
		o.fixture:setCategory(1)
		o.fixture:setFriction(0.2)
	else
		for i,v in pairs(shape) do
			local poly = love.physics.newPolygonShape(v)
			table.insert(o.shape, poly)
			local fixture = love.physics.newFixture(o.body, poly)
			fixture:setCategory(1)
			fixture:setFriction(0.2)
		end
	end
	-- END HERE
	o:setImage(love.graphics.newImage(sprite))
	o:setAnimationsList(animations)
	o.world = game
	return o
end

-- Position
function Platform:getPosition()
	return self.body:getPosition()
end

-- Draw of `Platform`
function Platform:draw (offset_x, offset_y, scale, debug)
	-- locals
	local offset_x = offset_x or 0
	local offset_y = offset_y or 0
	local scale = scale or 1
	local debug = debug or false
	local x, y = self:getPosition()
	-- pixel grid
	local draw_x = (math.floor(x) + offset_x) * scale
	local draw_y = (math.floor(y) + offset_y) * scale
	-- sprite draw
	Sprite.draw(self, draw_x, draw_y, 0, scale, scale)
	-- debug draw
	if debug then
		love.graphics.setColor(255, 69, 0, 140)
		for i,v in pairs(self.shape) do
			love.graphics.polygon("fill", self.world.camera:translatePoints(self.body:getWorldPoints(v:getPoints())))
		end
	end
end