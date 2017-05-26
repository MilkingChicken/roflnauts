require "not.Decoration"

--- `Effect`
-- Short animation with graphics that plays in various situation.
-- TODO: animation is currently slower than it used to be, check if it is ok; if not then make it possible to change it to 0.06 delay.
Effect = Decoration:extends()

Effect.finished = false

-- Constructor of `Effect`.
function Effect:new (name, x, y, world)
	-- TODO: Load spritesheet statically. Put it to load or somewhere else within non-existent resource manager.
	if Effect:getImage() == nil then
		Effect:setImage(Sprite.newImage("assets/effects.png"))
	end
	Effect.__super.new(self, x, y, world, nil)
	self:setAnimationsList(require("config.animations.effects"))
	self:setAnimation(name)
end

-- Update of `Effect`.
-- Returns true if animation is finished and effect is ready to be deleted.
function Effect:update (dt)
	Effect.__super.update(self, dt)
	return self.finished
end

-- Overridden from `not.Sprite`.
-- Sets finished flag if reached last frame of played animation.
function Effect:goToNextFrame ()
	if not (self.frame == self.current.frames) then
		self.frame = (self.frame % self.current.frames) + 1
	else
		self.finished = true
	end
end

return Effect
