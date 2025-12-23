timing = 0.25
max_actors = 8
actors = {}
ground = 88
gravity = 0.6

cam_x = 0
cam_y = 0

----------------------------------------
-- actors
----------------------------------------

function make_actor(k, x, y, d)
	local a = {
		-- sprites
		k = k,
		frame = 0,
		frames = 3,

		-- physics
		x = x,
		y = y,
		d = d or -1, -- direction
		dx = 0,
		dy = 0,
		ddx = 0.2, -- acceleration
		friction = 0.8,
		max_dx = 4,
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

function draw_actor(a)
	local fr = a.k + a.frame

	if a.dy < -0.1 then
		spr(a.k + 4, a.x, a.y, 1, 1, a.d < 0)
	elseif a.dy > 0.1 then
		spr(a.k + 3, a.x, a.y, 1, 1, a.d < 0)
	elseif abs(a.dx) > 0.3 then
		spr(fr, a.x, a.y, 1, 1, a.d < 0)
	else
		spr(a.k, a.x, a.y, 1, 1, a.d < 0)
	end
end

function update_actor(a)
	a.frame += timing
	if a.frame >= a.frames then
		a.frame = 0
	end

	a.x += a.d

	if a.x > 127 - 8 then
		a.d = -1
	end
	if a.x < 0 then
		a.d = 1
	end
end

----------------------------------------
-- player
----------------------------------------

function update_player(a)
	local ddy = gravity
	local ddx =
		a.ddx * (a.grounded and 1 or 0.6)
	local friction = a.friction

	if a.coyote > 0 and not a.grounded then
		a.coyote -= 1
	end

	-- player control

	-- left
	if btn(0, b) then
		if abs(a.dx) < a.max_dx then
			a.dx -= ddx
		end
		a.d = -1
		friction = sgn(a.dx) < 0 and 1 or friction
	end

	-- right
	if btn(1, b) then
		if abs(a.dx) < a.max_dx then
			a.dx += ddx
		end
		a.d = 1
		friction = sgn(a.dx) > 0 and 1 or friction
	end

	-- x
	if btn(4, b) then
		-- elongate jump on hold
		if a.dy < 0 then ddy *= 0.4 end
		
		a.jump_buf += 1
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

	if a.dx < 0 and solid(next_x, a.y, true) then
		next_x = flr(next_x / 8) * 8 + 8
		a.dx = 0
	elseif a.dx > 0 and
		solid(next_x + 8, a.y, true) then
		next_x = flr(next_x / 8) * 8
		a.dx = 0
	end

	a.x = flr_100(next_x)

		-- vertical movement
	local next_y = a.y + a.dy
	local flr_solid =
		solid(a.x + 2, next_y + 8)
				or solid(a.x + 4, next_y + 8)

	-- falling and hit ground
	if a.dy > 0 and flr_solid then
		a.dy = 0
		next_y = flr(next_y / 8) * 8
		a.grounded = true

	-- rising and hit ceiling
	elseif a.dy < 0
		and (
		solid(a.x + 2, next_y, true)
			or solid(a.x + 4, next_y, true)
	) then	
		a.dy = 0
		next_y = flr(next_y / 8) * 8 + 8

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

	draw_tail(a)
end

----------------------------------------
-- tail
----------------------------------------

tail_frames = {
    {16, 17}, -- still
    {17, 18}, -- running
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
  
	local frames = tail_frames[1]
  if a.running then
      frames = tail_frames[2]
  end
                  

	spr(frames[idx], a.x - offset, a.y, 1, 1, d
	< 0)

	tail_idx += 0.05
	if tail_idx > #tail_frames + 1 then
		tail_idx = 1
	end
end

----------------------------------------
-- lifecycle
----------------------------------------

function _init()
	pl = make_actor(1, 2, ground, 1)
	pl.update = update_player
	pl.draw = draw_player
end

function _update()
	for a in all(actors) do
		a:update()
	end
end

function _draw()
	cls()

	-- sky
	rectfill(0, 0, 127, 127, 1)

	-- bottom
	rectfill(0, 116, 127, 127, 4)

 local p = actors[1] 

	
	print(p.jump_buf, 4, 120, 0)

	camera(0,  0)

	-- draw the entire map at (0, 0), allowing
 -- the camera and clipping region to decide
 -- what is shown
 map(0, 0, 0, 0, 128, 32)

 -- reset the camera then print the camera
 -- coordinates on screen
 camera()

	for a in all(actors) do
		a:draw()
	end
end

function flr_100(n)
 return flr(abs(n) * 100) / 100 * sgn(n)
end

function solid (x, y, passthru)
	local tx = x / 8
	local ty = y / 8

	if (x < 0 or x >= 128 ) then
		return true
	end
	
	local m = mget(tx, ty)

	if fget(m, 1) then
		return true
	end

	if (fget(m,0)) then
		return not passthru
	end
end
