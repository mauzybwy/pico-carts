--(====================================-
-- constants/globals
--(====================================-

timing = 0.25
max_actors = 8
actors = {}
ground = 230
gravity = 0.6
map_w = 100
map_h = 32

cam={
 x=-128,
 y=-128
}

logt = {}



--(====================================-
-- actors
--(====================================-


--------------------
-- make actor ------

function make_actor(k, x, y, d)
	local a = {
		-- sprites
		k = k,
		frame = 0,
		frames = 3,

		-- physics
		x = x,
		y = y,
		h = 8,
		w = 8,
		d = d or -1, -- direction
		dx = 0,
		dy = 0,
		ddx = 0.2, -- acceleration
		friction = 0.8,
		max_dx = 3,
		max_dy = 7,
		jump_dy = 4,
		coyote = 4,
		max_coyote = 4,
		jump_buf = 0,
		max_jump_buf = 4,

		-- lifecycle
		update = update_actor,
		draw = draw_actor,

		-- state
		grounded = true,
		running = false,
		drifting = false,
	}

	if #actors < max_actors then
		add(actors, a)
	end

	return a
end

--------------------
-- draw actor ------

function draw_actor(a)
	-- local fr = a.k + a.frame
	-- 
	-- if a.dy < -0.1 then
	-- 	spr(a.k + 4, a.x, a.y, 1, 1, a.d < 0)
	-- elseif a.dy > 0.1 then
	-- 	spr(a.k + 3, a.x, a.y, 1, 1, a.d < 0)
	-- elseif abs(a.dx) > 0.3 then
	-- 	spr(fr, a.x, a.y, 1, 1, a.d < 0)
	-- else
	-- 	spr(a.k, a.x, a.y, 1, 1, a.d < 0)
	-- end
end

--------------------
-- update actor ----

function update_actor(a)
	-- a.frame += timing
	-- if a.frame >= a.frames then
	-- 	a.frame = 0
	-- end
	-- 
	-- a.x += a.d
	-- 
	-- if a.x > 127 - 8 then
	-- 	a.d = -1
	-- end
	-- if a.x < 0 then
	-- 	a.d = 1
	-- end
end



--(====================================-
-- player
--(====================================-


--------------------
-- update player ---

function update_player(a)
	local ddy = gravity
	local ddx =
		a.ddx * (a.grounded and 1 or 0.6)
	local friction = a.friction

	if a.coyote > 0 and not a.grounded then
		a.coyote -= 1
	end

	-- player control
	maxed = abs(a.dx) >= a.max_dx

	-- left
	if btn(0, b) then
		if not maxed then a.dx -= ddx end
		a.d = -1
		friction = sgn(a.dx) < 0 and 1 or friction
	end

	-- right
	if btn(1, b) then
		if not maxed then a.dx += ddx end
		a.d = 1
		friction = sgn(a.dx) > 0 and 1 or friction
	end

	-- x
	if btn(4, b) then
		-- elongate jump on hold
		if a.dy < 0 then ddy *= 0.4 end

		if a.jump_buf < a.max_jump_buf then
			a.jump_buf += 1
		end
	else
		a.jump_buf = 0
	end

	if
		(a.grounded or a.coyote > 0)
			and a.jump_buf > 0
			and a.jump_buf < a.max_jump_buf
	then
		a.dy = -a.jump_dy
		a.grounded = false
		a.coyote = 0
	end

	-- apply friction
	if a.grounded then
		a.dx = flr_100(a.dx * friction)
	else
		a.dx = flr_100(a.dx)
	end

	-- apply gravity
	if not a.grounded
		and abs(a.dy) < a.max_dy then
		a.dy += ddy
	end

	-- horizontal movement
	local next_x = a.x + a.dx

	if a.dx < 0 and map_xn(next_x, a.y, true) then
		next_x = flr_t(next_x) + a.w
		a.dx = 0
	elseif a.dx > 0 and
		map_xn(next_x + a.w, a.y, true) then
		next_x = flr_t(next_x)
		a.dx = 0
	end

	a.x = flr_100(next_x)

	-- vertical movement
	local next_y = a.y + a.dy
	local flr_solid =
		map_xn(a.x + 2, next_y + a.h)
		or map_xn(a.x + a.w - 2, next_y + a.h)

	-- falling and hit ground
	if a.dy > 0 and flr_solid then
		a.dy = 0
		next_y = flr_t(next_y)
		a.grounded = true

		-- rising and hit ceiling
	elseif a.dy < 0
		and (
		map_xn(a.x + 2, next_y, true)
			or map_xn(a.x + a.w - 2, next_y, true)
	) then	
		a.dy = 0
		next_y = flr_t(next_y) + a.h

		-- grounded?
	else
		a.grounded = abs(a.dy) < 0.1 and flr_solid
	end

	a.y = flr_100(next_y)

	-- other states
	if a.grounded then
		a.coyote = a.max_coyote
	end
	
	a.drifting =
  (sgn(a.dx) != sgn(a.d)) and (abs(a.dx) > 0.1)

	a.running = not drifting and abs(a.dx) > 1
end

--------------------
-- draw player -----

function draw_player(a)
	a.frame += timing
	if a.frame >= a.frames then
		a.frame = 0
	end
	
	-- jumping
	if a.dy > 0.1 then
		spr(a.k + 3, a.x, a.y, 1, 1, a.d < 0)

		-- falling
	elseif a.dy < -0.1 then
		spr(a.k + 4, a.x, a.y, 1, 1, a.d < 0)

		-- running
	elseif abs(a.dx) > 0.3 then
		spr(a.k + a.frame, a.x, a.y, 1, 1, a.d < 0)

		-- standing
	else
		spr(a.k, a.x, a.y, 1, 1, a.d < 0)
	end

	log(a.x.." | "..a.y)
	log(a.dx.." | "..a.dy)


	draw_tail(a)
end

--------------------
-- player tail -----

tail_frames = {
 {16, 17}, -- still
 {17, 18}, -- running
	{16, 16}, -- falling
	{17, 17}, -- jumping
}
tail_idx = 1

function draw_tail(a)
	idx = flr(tail_idx)
 local d = a.d
 local offset = 5

 if a.drifting then  d = -d end

 if (a.d < 0 and not a.drifting)
  or (a.d > 0 and a.drifting) then
  offset = -offset
 end

	local tf_idx = 1
	if a.dy > 0.05 then tf_idx = 3
	elseif a.dy < -0.05 then tf_idx = 4
	elseif a.running then tf_idx = 2
	end
  
	local frames = tail_frames[tf_idx]

	spr(frames[idx], a.x - offset, a.y, 1, 1, d
		< 0)

	tail_idx += 0.05
	if tail_idx > #frames + 1 then
		tail_idx = 1
	end
end



--(====================================-
-- lifecycle
--(====================================-


--------------------
-- init ------------

function _init()
	pl = make_actor(1, 150, ground, 1)
	pl.update = update_player
	pl.draw = draw_player
end

--------------------
-- update ----------

function _update()
	logt={}
	
	for a in all(actors) do
		a:update()
	end
end

--------------------
-- draw ------------

function _draw()
	cls()

	-- player
	local p = actors[1]

	-- backround
	rectfill(0, 0, 127, 127, 1)

	-- camera
	local target_x = p.x - 64
	cam.x += (target_x - cam.x) * 0.1
	cam.x = mid(0, cam.x, map_w * 8 - 128)

	local target_y = p.y - 64
	cam.y += (target_y - cam.y) * 0.3
	cam.y = mid(0, cam.y, map_h * 8 - 128)
	
	camera(cam.x, cam.y)

	-- map
	map(0, 0, 0, 0, map_w, 32)

	-- actors
	for a in all(actors) do
		a:draw()
	end

 camera()

	print(join("\n", unpack(logt)), 0, 0, 7)
end



--(====================================-
-- helpers
--(====================================-


--------------------
-- math ------------

function flr_100(n)
	dec = abs(n) - flr(abs(n))
	hun = flr(dec * 100) / 100
	
 return sgn(n) * (flr(abs(n)) + hun)
end

--(=====-

function flr_t(n)
	return flr(n / 8) * 8
end

--------------------
-- collision (xn) --

function map_xn(x, y, passthru)
	local cx = x
	local cy = y
	
	local tx = cx / 8
	local ty = cy / 8
	
	local m = mget(tx, ty)

	if fget(m, 1) then
		return true
	end

	if (fget(m,0)) then
		return not passthru
	end
end

--(=====-

function aabb_xn(r1, r2)
 return r1.x < r2.x+r2.w and
  r1.x+r1.w > r2.x and
  r1.y < r2.y+r2.h and
  r1.y+r1.h > r2.y
end

--------------------
-- logging ---------

function log(str)
	add(logt,str)
end

function join(d,s,...)
  return ... and s..d..join(d,...) or s or ''
end
