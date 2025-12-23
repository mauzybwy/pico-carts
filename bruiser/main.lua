timing = 0.25
max_actors = 8
actors = {}
ground = 100
gravity = 0.6

---------------------------------------------------
-- actors
---------------------------------------------------

function make_actor(k, x, y, d)
	local a = {
		k = k,
		x = x,
		y = y,
		dx = 0,
		dy = 0,
		max_dx = 4,
		ddx = 0.2, -- acceleration
		frame = 0,
		frames = 3,
		d = d or -1, -- direction
		friction = 0.85,
		jump = 5,
		draw = draw_actor,
		move = move_actor,
		grounded = true,
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

function move_actor(a)
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

--------------------------------------------------
-- player
--------------------------------------------------

function move_player(a)
	local ddy = gravity
	local ddx = a.ddx * (a.grounded and 1 or 0.6)
	local friction = a.friction

	-- player control
	if btn(0, b) then
		if abs(a.dx) < a.max_dx then
			a.dx -= ddx
		end
		a.d = -1
		friction = sgn(a.dx) < 0 and 1 or friction
	end

	if btn(1, b) then
		if abs(a.dx) < a.max_dx then
			a.dx += ddx
		end
		a.d = 1
		friction = sgn(a.dx) > 0 and 1 or friction
	end

	if btn(4, b) then
		if pl.grounded then
			a.dy = -a.jump
		else
			ddy *= 0.6
		end
	end

	a.frame += timing
	if a.frame >= a.frames then
		a.frame = 0
	end

	if a.x > 127 - 8 then
		a.d = -1
	end
	if a.x < 0 then
		a.d = 1
	end

	-- candidate position
	a.x += a.dx
	a.y += a.dy

	if a.y >= ground then
		a.grounded = true
		a.y = ground
		a.dy = 0
	else
		a.grounded = false
	end

	if a.grounded then
		a.dx *= friction
	else
		a.dy += ddy
	end
end

function draw_player(a)
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

	draw_tail(a)
end

--------------------------------------------------
-- tail
--------------------------------------------------

tail_frames = {
    {16, 17}, -- still
    {17, 18}, -- running
}
tail_idx = 1

function draw_tail(a)
	idx = flr(tail_idx)
  local drifting =
      (sgn(a.dx) != sgn(a.d)) and (abs(a.dx) >
	    0.1)
  local running = not drifting and abs(a.dx) > 1
  local d = a.d
  local offset = 5

  if drifting then  d = -d end

  if (a.d < 0 and not drifting)
      or (a.d > 0 and drifting) then
     offset = -offset
  end
  
	local frames = tail_frames[1]
  if running then
      frames = tail_frames[2]
  end
                  

	spr(frames[idx], a.x - offset, a.y, 1, 1, d
	< 0)

	tail_idx += 0.05
	if tail_idx > #tail_frames + 1 then
		tail_idx = 1
	end
end

--------------------------------------------------
-- lifecycle
--------------------------------------------------

function _init()
	pl = make_actor(1, 2, ground, 1)
	pl.move = move_player
	pl.draw = draw_player
end

function _draw()
	cls()

	for a in all(actors) do
		a:draw()
	end
end

function _update()
	for a in all(actors) do
		a:move()
	end
end
