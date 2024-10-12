--- A doubly linked list (DLL)
--- Optimized with node recycling and cached list sizes.
---@code
--- dll = require("github.com/aduermael/modzh/dll")
--- local list = dll()
--- list:pushBack(value)  -- Adds a value to the end of the list
--- list:pushFront(value)  -- Adds a value to the front of the list
--- local value = list:popFront()  -- Removes and returns the first value
--- local value = list:popBack()  -- Removes and returns the last value
--- list:flush()  -- Removes all elements from the list
--- print(list:front())  -- Returns the first value without removing it
--- print(list:back())  -- Returns the last value without removing it
--- for value, isLast in list:iteratorFrontToBack() do  -- Iterates from front to back
--- for value, isFirst in list:iteratorBackToFront() do  -- Iterates from back to front
--- print("size:", #list)  -- Returns the number of elements in the list

local privateFields = setmetatable({}, { __mode = "k" })

local fields
local n
local v

local recycledNodes = {}
local function recycleNode(node)
	node.value = nil
	node.next = nil
	node.prev = nil
	table.insert(recycledNodes, node)
end
local function getOrCreateNode(value)
	n = table.remove(recycledNodes)
	if n == nil then
		n = {
			-- next = nil,
			-- prev = nil,
		}
	end
	n.value = value
	return n
end

local dllMT = {
	__index = {
		pushBack = function(self, value)
			fields = privateFields[self]
			if fields == nil then
				error("dll:pushBack(value) should be called with `:`", 2)
			end
			-- note: it's ok to push a nil value
			n = getOrCreateNode(value)
			if fields.back ~= nil then
				fields.back.next = n
				n.prev = fields.back
				fields.back = n
			else -- list is empty
				fields.front = n
				fields.back = n
			end
			fields.size = fields.size + 1
		end,
		pushFront = function(self, value)
			fields = privateFields[self]
			if fields == nil then
				error("dll:pushFront(value) should be called with `:`", 2)
			end
			-- note: it's ok to push a nil value
			n = getOrCreateNode(value)
			if fields.front ~= nil then
				fields.front.prev = n
				n.next = fields.front
				fields.front = n
			else -- list is empty
				fields.front = n
				fields.back = n
			end
			fields.size = fields.size + 1
		end,
		popFront = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:popFront() should be called with `:`", 2)
			end
			n = fields.front
			if n ~= nil then
				fields.size = fields.size - 1
				fields.front = n.next
				if fields.front == nil then -- list now empty
					fields.back = nil
				else
					fields.front.prev = nil
				end
				v = n.value
				recycleNode(n)
				return v
			end
			return nil
		end,
		popBack = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:popBack() should be called with `:`", 2)
			end
			n = fields.back
			if n ~= nil then
				fields.size = fields.size - 1
				fields.back = n.prev
				if fields.back == nil then -- list now empty
					fields.front = nil
				else
					fields.back.next = nil
				end
				v = n.value
				recycleNode(n)
				return v
			end
			return nil
		end,
		flush = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:flush() should be called with `:`", 2)
			end
			while fields.front ~= nil do
				n = fields.front
				fields.front = n.next
				recycleNode(n)
			end
			fields.back = nil
			fields.size = 0
		end,
		front = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:front() should be called with `:`", 2)
			end
			if fields.front ~= nil then
				return fields.front.value
			end
			return nil
		end,
		back = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:back() should be called with `:`", 2)
			end
			if fields.back ~= nil then
				return fields.back.value
			end
			return nil
		end,
		iteratorFrontToBack = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:iteratorFrontToBack() should be called with `:`", 2)
			end
			local current = fields.front
			local value
			local isLast
			return function()
				if current then
					value = current.value
					isLast = current.next == nil
					current = current.next
					return value, isLast
				end
			end
		end,
		iteratorBackToFront = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("dll:iteratorBackToFront() should be called with `:`", 2)
			end
			local current = fields.back
			local value
			local isFirst
			return function()
				if current then
					value = current.value
					isFirst = current.prev == nil
					current = current.prev
					return value, isFirst
				end
			end
		end,
	},
	__newindex = function()
		error("dll table is read-only", 2)
	end,
	__len = function(l)
		fields = privateFields[l]
		if fields == nil then
			return 0
		end
		return fields.size
	end,
}

local mod = setmetatable({}, {
	__newindex = function()
		error("dll module is read-only", 2)
	end,
	__call = function()
		local l = {}
		privateFields[l] = {
			size = 0,
			front = nil,
			back = nil,
		}
		setmetatable(l, dllMT)
		return l
	end,
	__metatable = false,
})

return mod
