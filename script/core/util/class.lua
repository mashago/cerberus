
-- store all class all member map
local _class={} 

-- _class = {[class_ptr] = { k=v, __index=func search from super}}
-- x_class = {__index = _class[x_class], __newindex=func set into _class[x_class]} 
 
function class(super)
	local class_type={}
	class_type.ctor=false
	class_type.super=super

	class_type.new=function(...) 
		-- function to new a obj
		local obj={}
		do
			local create
			create = function(c,...)
				-- recursion do create super
				if c.super then
					create(c.super,...)
				end
				-- call constructor
				if c.ctor then
					c.ctor(obj,...)
				end
			end

			create(class_type,...)
		end

		-- set obj get metatable(get from base class)
		setmetatable(obj,{ __index=_class[class_type] })
		return obj
	end

 	-- set base class set metatable
	-- therefore base class set data or function, obj can get it
	local vtbl={}
	_class[class_type]=vtbl
	setmetatable(class_type,{__newindex=
		function(t,k,v)
			vtbl[k]=v
		end
	})
 
 	-- set base class get metatable(get from super)
	-- if base class has super, base class can get data from super which not found in base class
	if super then
		setmetatable(vtbl,{__index=
			function(t,k)
				local ret=_class[super][k]
				vtbl[k]=ret
				return ret
			end
		})
	end
 
	return class_type
end
