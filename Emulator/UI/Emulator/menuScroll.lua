--[[
Simple Scrolling Menu Library
by nkorth

Required: love2d
Recommended: hump.gamestate

Public Domain - feel free to hack and redistribute this as much as you want.
]]--
return {
	new = function()
		return {
			items = {},
			selected = 1,
			animOffset = 0,
			addItem = function(self, item)
				table.insert(self.items, item)
			end,
			update = function(self, dt)
				self.animOffset = self.animOffset / (1 + dt*10)
			end,
			draw = function(self)
				local height = 20
				
				love.graphics.setColor(255, 255, 255, 128)
				love.graphics.rectangle('fill', 0, love.graphics.getHeight()/2 - height/2, love.graphics.getWidth(), height)
				
				for i, item in ipairs(self.items) do
					local y = love.graphics.getHeight()/2 + ((i - self.selected) * height) - height/2 - (self.animOffset * height)
					if self.selected == i then
						love.graphics.setColor(255, 255, 255)
					else
						love.graphics.setColor(255, 255, 255, 128)
					end
					love.graphics.print(item.name, 5, y + 5)
				end
			end,
			keypressed = function(self, key)
				if key == 'up' then
					if self.selected > 1 then
						self.selected = self.selected - 1
						self.animOffset = self.animOffset + 1
					else
						self.selected = #self.items
						self.animOffset = self.animOffset - (#self.items-1)
					end
				elseif key == 'down' then
					if self.selected < #self.items then
						self.selected = self.selected + 1
						self.animOffset = self.animOffset - 1
					else
						self.selected = 1
						self.animOffset = self.animOffset + (#self.items-1)
					end
				elseif key == 'return' then
					if self.items[self.selected].action then
						self.items[self.selected]:action()
					end
				end
			end
		}
	end
}