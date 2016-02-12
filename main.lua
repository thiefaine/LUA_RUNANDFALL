debug = true
require "TEsound"

-- tou control four gates with the arrows and you can open or close the gates
-- random spawn entities are coming trought the gates, some ares enemies, some are refugies so you have to block the enemies and let pass the refugies with gates.
-- each wave have more and more entities that comes and they are way faster each time

--// Menu \\--
menuTileW, menuTileH = 128, 32

playButtonX, playButtonY = love.window:getWidth() / 4, love.window:getHeight() / 5
optionButtonX, optionButtonY = 3 * love.window:getWidth() / 4, love.window:getHeight() / 5

--playText = {x = love.window:getWidth() / 4, y = love.window:getHeight() / 8, w = "PLAY"}
playText = {x = love.window:getWidth() / 2, y = 0 * love.window:getHeight() / 8, w = "PLAY"}
--settingsText = {x = 3 * love.window:getWidth() / 4, y = love.window:getHeight() / 8, w = "SETTINGS"}
settingsText = {x = love.window:getWidth() / 2, y = 1 * love.window:getHeight() / 8, w = "SETTINGS"}

playOver, optionOver = false, false

--// Gates \\--
gateNorth = {}
gateWest = {}
gateEast = {}
gateSouth = {}

gates = {}

frame = 2
gateFrameTimerMax = 0.03
gateFrameTimer = gateFrameTimerMax

--// Particle information \\--
psystem = nil

--// Waves \\--
wave = 1
speedWave = 0
nbEntitiesMax = 0
nbEntitiesWave = 0
entityTimerMax = 1
entityTimer = entityTimerMax

function scriptWave()
	velocity = 1
	nbEntitiesMax = 10 + wave
	if (wave < 4) then
		speedWave = 100 + wave * 30
		entityTimerMax = 1
	elseif (wave >= 4 and wave < 8) then
		speedWave = 100 + (wave - 2) * 40
		entityTimerMax = 0.8
	elseif (wave >= 8 and wave < 12) then
		speedWave = 100 + (wave - 4) * 40
		entityTimerMax = 0.6
	elseif (wave >= 12) then
		speedWave = 100 + (wave - 6) * 40
		entityTimerMax = 0.4
	end
end

--// Entities \\--
entityTileW, entityTileH = 32, 32
enemies = {}
friends = {}
entities = {friends, enemies}
spawnPoints = {{x = love.window:getWidth() / 2, y = 0}, {x = 0, y = love.window:getHeight() / 2}, {x = love.window:getWidth(), y = love.window:getHeight() / 2}, {x = love.window:getWidth() / 2, y = love.window:getHeight()}}
--UNUSED FOR ANIMATION LATER
--entityAnimationTimerMax = 0.1

--// SLOW MO \\--
enemyInside = false
velocity = 1

--// Alert \\--
gateNumber = 0
typeEntity = 0
sinFrame = 0

--// Game Datas \\--
previousGamemode = 1
gamemode = 1
PVMAX = 10
PV = PVMAX
score = 0

escapePress = false
coolDownEscapeMax = 0.2
coolDownEscape = coolDownEscapeMax

--// Settings \\--
musicPlaying = false
sfxPlaying = false

musicTestPlaying = false
sfxTestPlaying = false

volumeMusic = 0.2
volumeSFX = 0.2

cursorMusic = {x = 200, y = 1 * love.window:getHeight() / 4, w = 250, h = 50, b = 5}
musicButton = {x = 10, y = 1 * love.window:getHeight() / 4, w = "Music"}
musicOver = false

cursorSFX = {x = 200, y = 2 * love.window:getHeight() / 4, w = 250, h = 50, b = 5}
sfxButton = {x = 10, y = 2 * love.window:getHeight() / 4, w = "SFX"}
sfxOver = false

quitButton = {x = 10, y = 3 * love.window:getHeight() / 4, w = "Quit"}
quitOver = false
message = {w = " Press Escape to go back ", x = love.window:getWidth(), y = love.window:getHeight()}

leftButton = {}
rightButton = {}
upButton = {}
downButton = {}

function reset()
	-- Wave information
	wave = 1
	nbEntitiesWave = 0

	-- coming symbol
	gateNumber = 0
	typeEntity = 0
	sinFrame = 0

	-- entities information
	enemies = {}
	friends = {}
	entities = {friends, enemies}
	entityTimer = entityTimerMax

	-- Game Datas
	PV = PVMAX
	score = 0

	-- slo mo
	enemyInside = false

	scriptWave()
end
-- END reset()

function love.keypressed(key, isrepeat)
	if key == "escape" then
		escapePress = true
	end
end

function love.keyreleased(key)
	if key == "escape" then
		escapePress = false
	end
end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function love.load(arg)

	--#### LOAD CONTROLS ####--
	local f = assert(io.open(".config", "r"))
	local t = f:read("*line")
	leftButton = split(string.sub(t, #"LEFT: "), ",")
	t = f:read("*line")
	rightButton = split(string.sub(t, #"RIGHT: "), ",")
	t = f:read("*line")
	upButton = split(string.sub(t, #"UP: "), ",")
	t = f:read("*line")
	downButton = split(string.sub(t, #"DOWN: "), ",")
	f:close()

	--#### LOAD FONTS ####--
	font = love.graphics.newFont("font/Space.ttf", "35")
	font_little = love.graphics.newFont("font/Space.ttf", "25")
	menuFont = love.graphics.newFont("font/kid.ttf", "55")
	love.graphics.setFont(font)

	--#### LOAD SHADERS ###--
	menuShader = love.graphics.newShader("shader/invertedFilter.glsl")
	outlineShader = love.graphics.newShader("shader/outline.glsl")
	redOutline = love.graphics.newShader("shader/redOutline.glsl")

	--#### LOAD SONGS ####--
	music = "song/gate_music.mp3"
	gameStart = "song/gameStart2.mp3"
	pointsIn = "song/bonus.wav"
	electrocution = "song/electrocution_reduced.wav"
	lavaDrop = "song/fallLava.wav"

	--#### LOAD IMAGES ####--
	gameBoard = love.graphics.newImage("asset/gameBoard.png")
	gameBoardMenu = love.graphics.newImage("asset/gameBoardMenu.png")
	menuImg = love.graphics.newImage("asset/menu.png")
	menuButton = {
		love.graphics.newQuad(0 * menuTileW, 0 * menuTileH, menuTileW, menuTileH, menuImg:getWidth(), menuImg:getHeight()),
		love.graphics.newQuad(0 * menuTileW, 1 * menuTileH, menuTileW, menuTileH, menuImg:getWidth(), menuImg:getHeight())
	}

	entitiesImg = love.graphics.newImage("asset/entities.png")
	entityQuad = {
		love.graphics.newQuad(0 * entityTileW, 0 * entityTileH, entityTileW, entityTileH, entitiesImg:getWidth(), entitiesImg:getHeight()),
		love.graphics.newQuad(1 * entityTileW, 0 * entityTileH, entityTileW, entityTileH, entitiesImg:getWidth(), entitiesImg:getHeight())
	}

	local gateTileW, gateTileH = 64, 32
	gateImg = love.graphics.newImage("asset/gates_anim.png")
	gateQuads = {
		love.graphics.newQuad(0 * gateTileW, 0 * gateTileH, gateTileW, gateTileH, gateImg:getWidth(), gateImg:getHeight()),
		love.graphics.newQuad(1 * gateTileW, 0 * gateTileH, gateTileW, gateTileH, gateImg:getWidth(), gateImg:getHeight()),
		love.graphics.newQuad(1 * gateTileW, 1 * gateTileH, gateTileW, gateTileH, gateImg:getWidth(), gateImg:getHeight()),
		love.graphics.newQuad(1 * gateTileW, 2 * gateTileH, gateTileW, gateTileH, gateImg:getWidth(), gateImg:getHeight()),
		love.graphics.newQuad(1 * gateTileW, 3 * gateTileH, gateTileW, gateTileH, gateImg:getWidth(), gateImg:getHeight())
	}
	shaderEffectLayer = love.graphics.newImage("asset/shaderEffectLayer.png")

	-- FOR THE ROTATED ONES THE WIDTH AND HEIGHT ARE INVERTED
	local offsetBorder = 150
	gateNorth = {state = false, quads = gateQuads, x = love.window:getWidth() / 2, y = offsetBorder, w = gateTileW, h = gateTileH, rot = math.rad(0)}
	gateWest = {state = false, quads = gateQuads, x = offsetBorder, y = love.window:getHeight() / 2, w = gateTileH, h = gateTileW, rot = math.rad(-90)}
	gateEast = {state = false, quads = gateQuads, x = love.window:getWidth() - offsetBorder, y = love.window:getHeight() / 2, w = gateTileH, h = gateTileW, rot = math.rad(90)}
	gateSouth = {state = false, quads = gateQuads, x = love.window:getWidth() / 2, y = love.window:getHeight() - offsetBorder, w = gateTileW, h = gateTileH, rot = math.rad(180)}
	gates = {gateNorth, gateWest, gateEast, gateSouth}

	--#### LOAD PARTICLES ###--
	local particleGate = love.graphics.newImage('asset/particleGate.png')
	psystem = love.graphics.newParticleSystem(particleGate, 20)
	psystem:setParticleLifetime(1, 2)
	psystem:setEmissionRate(20)
	psystem:setSizeVariation(1)
	psystem:setLinearAcceleration(-40, -40, 40, 40)
	psystem:setColors(255, 255, 255, 0, 255, 255, 255, 255, 255, 255, 255, 0)
	
	--#### INIT WAVE VALUES ####--
	scriptWave()
	math.randomseed(os.time())

end
-- END love.load(arg)

function moveEntity(entity, dt)
	for i,e in ipairs(entity) do
		if (e.gate == 1) then
			e.y = e.y + speedWave * dt
		elseif (e.gate == 2) then
			e.x = e.x + speedWave * dt
		elseif (e.gate == 3) then
			e.x = e.x - speedWave * dt
		elseif (e.gate == 4) then
			e.y = e.y - speedWave * dt
		end
	end
end
-- END moveEntity(entity, dt)

function checkStopEntity(entity)
	local nbVoid = 0
	for i,e in ipairs(entity) do
		if (math.pow(e.x - love.window:getWidth() / 2, 2) + math.pow(e.y - love.window:getHeight() / 2, 2) <= 1000) then
			table.remove(entity, i)
			nbVoid = nbVoid + 1
		end
	end
	return nbVoid
end
-- END checkStopEntity(entity)

function love.update(dt)
	coolDownEscape = coolDownEscape - dt
	TEsound.cleanup()
	TEsound.volume("music", volumeMusic)
	TEsound.volume("musicVolumeTest", volumeMusic)
	TEsound.volume("sfx", volumeSFX)
	TEsound.volume("sfxVolumeTest", volumeSFX)
	TEsound.pitch("music", velocity)

	if (gamemode == 1) then -- Basic Menu
		menuUpdate(dt)
	elseif (gamemode == 2) then -- Game
		-- When the user let the mouse ever the testing button music / sfx, the song keeps playing ingame
		TEsound.stop("musicVolumeTest")
		TEsound.stop("sfxVolumeTest")
		musicTestPlaying = false
		sfxTestPlaying = false
		gameUpdate(dt)
	elseif (gamemode == 3) then -- Option Menu
		optionUpdate(dt)
	end
end
-- END love.update(dt)

function menuUpdate(dt)
	reset()
	
	-- BACKGROUND UPDATE
	gateFrameTimer = gateFrameTimer - dt
	TEsound.stop("music")
	musicPlaying = false

	if (gateFrameTimer <= 0) then
		gateFrameTimer = gateFrameTimerMax
		frame = frame + 1
	end
	if (frame >= 5) then
		frame = 2
	end

	psystem:update(dt)

	-- MOUSE EVENT
	playOver = false
	optionOver = false

	local x, y = love.mouse.getPosition()
	--if (x >= playButtonX - menuTileW / 2 and x <= playButtonX + menuTileW / 2 and y >= playButtonY - menuTileH / 2 and y <= playButtonY + menuTileH / 2) then
	if (x >= playText.x - menuFont:getWidth(playText.w) / 2 and x <= playText.x + menuFont:getWidth(playText.w) / 2 and y >= playText.y and y <= playText.y + menuFont:getHeight(playText.w)) then
		playOver = true
	--elseif (x >= optionButtonX - menuTileW / 2 and x <= optionButtonX + menuTileW / 2 and y >= optionButtonY - menuTileH / 2 and y <= optionButtonY + menuTileH / 2) then
	elseif (x >= settingsText.x - menuFont:getWidth(settingsText.w) / 2 and x <= settingsText.x + menuFont:getWidth(settingsText.w) / 2 and y >= settingsText.y and y <= settingsText.y + menuFont:getHeight(settingsText.w)) then
		optionOver = true
	end

	if (love.mouse.isDown("l")) then
		if (x >= playText.x - menuFont:getWidth(playText.w) / 2 and x <= playText.x + menuFont:getWidth(playText.w) / 2 and y >= playText.y and y <= playText.y + menuFont:getHeight(playText.w)) then
			TEsound.play(gameStart, "sfx")
			previousGamemode = gamemode
			gamemode = 2
		elseif (x >= settingsText.x - menuFont:getWidth(settingsText.w) / 2 and x <= settingsText.x + menuFont:getWidth(settingsText.w) / 2 and y >= settingsText.y and y <= settingsText.y + menuFont:getHeight(settingsText.w)) then
			previousGamemode = gamemode
			gamemode = 3
		end
	end
	if (escapePress and coolDownEscape <= 0) then
		love.event.quit()
	end
end
-- END menuUpdate(dt)

function gameUpdate(dt)
	-- TIMING UPDATE
	entityTimer = entityTimer - dt
	gateFrameTimer = gateFrameTimer - dt
	sinFrame = sinFrame + 0.2
	enemyInside = false

	if PV > 0 then
		-- SONG PLAYING
		if (not musicPlaying) then
			if (previousGamemode == 3) then
				TEsound.resume("music")
			else
				TEsound.play(music, "music")
			end
			musicPlaying = true
		end
		-- WAVE SETTINGS
		if (nbEntitiesWave >= nbEntitiesMax and #enemies == 0 and #friends == 0) then
			wave = wave + 1
			nbEntitiesWave = 0
			score = score + 100
			scriptWave()
		end

		if (gateFrameTimer <= 0) then
			gateFrameTimer = gateFrameTimerMax
			frame = frame + 1
		end
		if (frame >= 5) then
			frame = 2
		end

		-- KEY EVENT
		gateNorth.state = (love.keyboard.isDown("up", "w") and true or false)
		gateWest.state = (love.keyboard.isDown("left", "a") and true or false)
		gateEast.state = (love.keyboard.isDown("right", "d") and true or false)
		gateSouth.state = (love.keyboard.isDown("down", "s") and true or false)
		if (escapePress and coolDownEscape <= 0) then
			TEsound.pause("music")
			musicPlaying = false
			previousGamemode = gamemode
			gamemode = 3
			coolDownEscape = coolDownEscapeMax
		end

		-- MOVE ENTITIES
		local oldEntities = entities
		moveEntity(enemies, dt)
		moveEntity(friends, dt)

		-- COLLISION GATE
		for j,t in ipairs(entities) do
			for i,e in ipairs(entities[j]) do
				g = gates[e.gate]
				-- !!! the first state of this condition is probably wrong !!! --
				if (g.state == false and (((oldEntities[j][i].y <= g.y - g.h / 2 and e.y >= g.y + g.h / 2) or (oldEntities[j][i].x <= g.x - g.w / 2 and e.x >= g.x + g.w / 2)) or (e.y >= g.y - g.h / 2 and e.y <= g.y + g.h / 2 and e.x >= g.x - g.w / 2 and e.x <= g.x + g.w / 2))) then
					table.remove(t, i)
					minus = (j == 1) and 1 or 0
					PV = PV - minus
					TEsound.play(electrocution, "sfx")
				end
			end
		end

		-- COLLISION MIDDLE MAP
		local pvMinus = checkStopEntity(enemies)
		if (pvMinus ~= 0) then
			PV = PV - pvMinus
			TEsound.play(lavaDrop, "sfx")
		end
		local points = checkStopEntity(friends)
		if (points ~= 0) then
			score = score + 10 * points
			TEsound.play(pointsIn, "sfx")
		end

		-- SLOW MOTION ENEMY INSIDE
		for i,e in ipairs(enemies) do
			g = gates[e.gate]
			local xPos, yPos = math.abs(e.x - love.window:getWidth()/ 2), math.abs(e.y - love.window:getHeight() / 2)
			local xGatePos, yGatePos = 0, 0

			if e.gate == 1 or e.gate == 2 then
				xGatePos, yGatePos = math.abs((g.x + g.w / 2) - love.window:getWidth() / 2), math.abs((g.y + g.h / 2) - love.window:getHeight() / 2)
			else
				xGatePos, yGatePos = math.abs((g.x - g.w / 2) - love.window:getWidth() / 2), math.abs((g.y - g.h / 2) - love.window:getHeight() / 2)
			end

			if (xPos < xGatePos and yPos < yGatePos and PV == 1) then
				enemyInside = true

				speedWave = (speedWave >= 10) and speedWave / 1.1 or speedWave
				entityTimerMax = (speedWave >= 10) and entityTimerMax * 1.1 or entityTimerMax
				velocity = (speedWave >= 10) and velocity / 1.005 or velocity

				distance = xPos + yPos
				--redOutline:send("distance", distance)
				redOutline:send("ePos", {e.x, math.abs(love.window:getHeight() - e.y)})
				-- must retablish parameters after
				-- special reset function should be okay + scriptWave()
			end
		end

		-- SPAWN ENTITY
		if (entityTimer <= 0 and nbEntitiesWave < nbEntitiesMax) then
			nbEntitiesWave = nbEntitiesWave + 1
			entityTimer = entityTimerMax
			gateNumber = math.random(1, 4)
			typeEntity = math.random(1, 2)
			table.insert(entities[typeEntity], {quad = entityQuad[typeEntity], x = spawnPoints[gateNumber].x, y = spawnPoints[gateNumber].y, w = entityTileW, h = entityTileH, gate = gateNumber})
		end

		psystem:update(dt)

	else
		-- GAME OVER
	  	--decrease slowly volume then stop
	  	TEsound.stop("music")
		musicPlaying = false
		if (escapePress and coolDownEscape <= 0) then
			gamemode = 1
			coolDownEscape = coolDownEscapeMax
		end
	end
end
-- END gameUpdate(dt)

function optionUpdate(dt)
	local marge = cursorMusic.b
	local x, y = love.mouse.getPosition()

	if (x >= musicButton.x and x <= musicButton.x + font:getWidth(musicButton.w) and y >= musicButton.y and y <= musicButton.y + font:getHeight(musicButton.w)) then
		musicOver = true
		if (not musicTestPlaying) then
			TEsound.play(music, "musicVolumeTest")
			musicTestPlaying = true
		end
	elseif (x >= sfxButton.x and x <= sfxButton.x + font:getWidth(sfxButton.w) and y >= sfxButton.y and y <= sfxButton.y + font:getHeight(sfxButton.w)) then
		sfxOver = true
		if (not sfxTestPlaying) then
			TEsound.playLooping({gameStart, pointsIn, electrocution, lavaDrop}, "sfxVolumeTest")
			sfxTestPlaying = true
		end
	elseif (x >= quitButton.x and x <= quitButton.x + font:getWidth(quitButton.w) and y >= quitButton.y and y <= quitButton.y + font:getHeight(quitButton.w)) then
		quitOver = true
	else
		TEsound.stop("musicVolumeTest")
		TEsound.stop("sfxVolumeTest")
		musicTestPlaying = false
		sfxTestPlaying = false
		musicOver = false
		sfxOver = false
		quitOver = false
	end

	if (love.mouse.isDown("l")) then
		if (x >= cursorMusic.x - marge and x <= cursorMusic.x + cursorMusic.w + marge and y >= cursorMusic.y - marge and y <= cursorMusic.y + cursorMusic.h + marge) then
			volumeMusic = (x - cursorMusic.x) / cursorMusic.w
			volumeMusic = (volumeMusic <= 0 ) and 0 or volumeMusic
			volumeMusic = (volumeMusic >= 1 ) and 1 or volumeMusic
		elseif (x >= cursorSFX.x - marge and x <= cursorSFX.x + cursorSFX.w + marge and y >= cursorSFX.y - marge and y <= cursorSFX.y + cursorSFX.h + marge) then
			volumeSFX = (x - cursorSFX.x) / cursorSFX.w
			volumeSFX = (volumeSFX <= 0 ) and 0 or volumeSFX
			volumeSFX = (volumeSFX >= 1 ) and 1 or volumeSFX
		elseif (x >= quitButton.x and x <= quitButton.x + font:getWidth(quitButton.w) and y >= quitButton.y and y <= quitButton.y + font:getHeight(quitButton.w)) then
			gamemode = 1
		end
	end
	if (escapePress and coolDownEscape <= 0) then
		local stockGamemode = gamemode
		gamemode = previousGamemode
		previousGamemode = stockGamemode
		coolDownEscape = coolDownEscapeMax
	end
end
-- END optionUpdate(dt)

function drawEntity(entity)
	local rot = {math.rad(0), math.rad(-90), math.rad(90), math.rad(180)}

	for i,e in ipairs(entity) do
		love.graphics.draw(entitiesImg, e.quad, e.x, e.y, gates[e.gate].rot, 1, 1, e.w / 2, e.h / 2)
		-- COLLISION BOX
		--love.graphics.setColor(255, 0, 0)
		--love.graphics.rectangle("line", e.x - e.w/2, e.y - e.h / 2, e.w, e.h)
		--love.graphics.setColor(255, 255, 255)
	end
end
-- END drawEntity(entity)

function rwrc(x, y, w, h, r, mode)
	local right = 0
	local left = math.pi
	local bottom = math.pi * 0.5
	local top = math.pi * 1.5

	r = r or 15
	mode = mode or "fill"
	love.graphics.rectangle(mode, x, y+r, w, h-r*2)
	love.graphics.rectangle(mode, x+r, y, w-r*2, r)
	love.graphics.rectangle(mode, x+r, y+h-r, w-r*2, r)
	love.graphics.arc(mode, x+r, y+r, r, left, top)
	love.graphics.arc(mode, x + w-r, y+r, r, -bottom, right)
	love.graphics.arc(mode, x + w-r, y + h-r, r, right, bottom)
	love.graphics.arc(mode, x+r, y + h-r, r, bottom, left)
end
-- END rwrc(x, y, w, h, r)

function love.draw()
	love.graphics.setBackgroundColor(42, 133, 163)
	if (gamemode == 1) then
		drawMenu()
	elseif (gamemode == 2) then
		drawGame()
	elseif (gamemode == 3) then
		drawOption()
	end
end
-- END love.draw()

function drawMenu()
	love.graphics.clear()
	love.graphics.setColor(255,255,255)

	love.graphics.draw(gameBoardMenu, 0, 0)

	-- FOR THE VERTICAL ONES THE WIDTH AND HEIGHT ARE INVERTED
	love.graphics.draw(gateImg, gateQuads[((gates[1].state == true) and 1 or frame)], gates[1].x, gates[1].y, gates[1].rot, 1, 1, gates[1].w  / 2, gates[1].h / 2)
	love.graphics.draw(gateImg, gateQuads[((gates[2].state == true) and 1 or frame)], gates[2].x, gates[2].y, gates[2].rot, 1, 1, gates[2].h  / 2, gates[2].w / 2)
	love.graphics.draw(gateImg, gateQuads[((gates[3].state == true) and 1 or frame)], gates[3].x, gates[3].y, gates[3].rot, 1, 1, gates[3].h  / 2, gates[3].w / 2)
	love.graphics.draw(gateImg, gateQuads[((gates[4].state == true) and 1 or frame)], gates[4].x, gates[4].y, gates[4].rot, 1, 1, gates[4].w  / 2, gates[4].h / 2)

	for i=1, 4 do
		if (gates[i].state == false) then
			love.graphics.draw(psystem, gates[i].x, gates[i].y)
		end
	end

	--love.graphics.draw(menuImg, menuButton[1], playButtonX, playButtonY, 0, 1, 1, menuTileW / 2, menuTileH / 2)
	--love.graphics.draw(menuImg, menuButton[2], optionButtonX, optionButtonY, 0, 1, 1, menuTileW / 2, menuTileH / 2)

	love.graphics.setColor(0, 0, 0)
	love.graphics.setFont(menuFont)

	love.graphics.printf(playText.w, playText.x, playText.y, 0, "center")
	love.graphics.printf(settingsText.w, settingsText.x, settingsText.y, 0, "center")

	--outlineShader:send("stepSize", {1/menuFont:getWidth(playText.w), 1/menuFont:getWidth(settingsText.w)})
	outlineShader:send("stepSize", {0.5/menuFont:getWidth(playText.w), 0.5/menuFont:getWidth(settingsText.w)})
	love.graphics.setShader(playOver and outlineShader or nil)
	love.graphics.printf(playText.w, playText.x, playText.y, 0, "center")
	love.graphics.setShader(optionOver and outlineShader or nil)
	love.graphics.printf(settingsText.w, settingsText.x, settingsText.y, 0, "center")

	love.graphics.setShader()

	love.graphics.setFont(font)
	love.graphics.setColor(255,255,255)
end
-- END drawMenu()

function drawGame()
	love.graphics.clear()
	if PV > 0 then
		love.graphics.setShader(enemyInside and redOutline or nil)
		love.graphics.draw(gameBoardMenu, 0, 0)
		--love.graphics.draw(gameBoard, 0, 0)
		love.graphics.setShader()

		--love.graphics.setShader(myShader)
		drawEntity(enemies)
		drawEntity(friends)
		--love.graphics.setShader()

		-- FOR THE VERTICAL ONES THE WIDTH AND HEIGHT ARE INVERTED
		love.graphics.draw(gateImg, gateQuads[((gates[1].state == true) and 1 or frame)], gates[1].x, gates[1].y, gates[1].rot, 1, 1, gates[1].w  / 2, gates[1].h / 2)
		love.graphics.draw(gateImg, gateQuads[((gates[2].state == true) and 1 or frame)], gates[2].x, gates[2].y, gates[2].rot, 1, 1, gates[2].h  / 2, gates[2].w / 2)
		love.graphics.draw(gateImg, gateQuads[((gates[3].state == true) and 1 or frame)], gates[3].x, gates[3].y, gates[3].rot, 1, 1, gates[3].h  / 2, gates[3].w / 2)
		love.graphics.draw(gateImg, gateQuads[((gates[4].state == true) and 1 or frame)], gates[4].x, gates[4].y, gates[4].rot, 1, 1, gates[4].w  / 2, gates[4].h / 2)

		for i=1, 4 do
			if (gates[i].state == false) then
				love.graphics.draw(psystem, gates[i].x, gates[i].y)
			end
		end

		-- COLLISION BOX
		--for i,g in ipairs(gates) do
		--	love.graphics.setColor(0, 0, 255)
		--	love.graphics.rectangle("line", g.x - g.w/2, g.y - g.h / 2, g.w, g.h)
		--	love.graphics.setColor(255, 255, 255)

		-- HUD
		local heightPV = 30
		local widthPV = 150
		local oxPV = 10
		local oyPV = 10
		local w = 2

		love.graphics.setColor(20, 20, 20)
		rwrc(oxPV, oyPV, widthPV, heightPV, heightPV / 2, "fill")
		love.graphics.setColor(255 * (PVMAX - PV), 255 * PV / PVMAX, 0)
		rwrc(oxPV + w, oyPV + w, (widthPV - 2 * w - heightPV  / 2) * PV / PVMAX + heightPV / 2, heightPV - 2 * w, (heightPV - 2 * w) / 2, "fill")
		love.graphics.setColor(255, 255, 255)

		love.graphics.print("Wave    "..wave, love.window:getWidth() - 150, 0)

		-- COMING SYMBOL
		local offset = 40
		local r = 8
		local sin = 5 * math.sin(sinFrame)
		local positions = {{x = love.window:getWidth() / 2 - offset, y = offset + sin}, {x = offset + sin, y = love.window:getHeight() / 2 + offset}, {x = love.window:getWidth() - offset - sin, y = love.window:getHeight() / 2 - offset}, {x = love.window:getWidth() / 2 + offset, y = love.window:getHeight() - offset - sin}}
		if (typeEntity == 1) then
			love.graphics.setColor(0, 0, 0)
			love.graphics.circle("fill", positions[gateNumber].x, positions[gateNumber].y, r + 2)
			love.graphics.setColor(0, 255, 0)
			love.graphics.circle("fill", positions[gateNumber].x, positions[gateNumber].y, r)
		elseif (typeEntity == 2) then
			love.graphics.setColor(0, 0, 0)
			love.graphics.circle("fill", positions[gateNumber].x, positions[gateNumber].y, r + 2)
			love.graphics.setColor(255, 0, 0)
			love.graphics.circle("fill", positions[gateNumber].x, positions[gateNumber].y, r)
		end
		love.graphics.setColor(255, 255, 255)

		love.graphics.setShader(enemyInside and redOutline or nil)
		shaderEffectLayer = love.graphics.newImage("asset/shaderEffectLayer.png")
		love.graphics.setShader()

	-- CHECK PV
	else
		love.graphics.clear()

		love.graphics.setColor(90,90,90)
		rwrc(10, 10, love.window:getWidth() - 20, 115, 20, "fill")
		love.graphics.setColor(30,30,30)
		rwrc(15, 15, love.window:getWidth() - 30, 105, 15, "fill")
		love.graphics.setColor(255,255,255)

		love.graphics.printf("Wave   -"..wave, 15, 15, love.window:getWidth(), "center")
		love.graphics.printf("Score   -"..score, 15, 45, love.window:getWidth(), "center")

		love.graphics.print("Game Over", love.window:getWidth() / 2 - 100, love.window:getHeight() / 2)
		love.graphics.print("Press Escape", love.window:getWidth() / 2 - 110, love.window:getHeight() / 2 + 40)
	end
end
-- END drawGame()

function drawOption()
	love.graphics.setBackgroundColor(42, 133, 163)
	love.graphics.clear()

	love.graphics.printf("Settings", love.window:getWidth() / 2, 10, 0, "center")

	love.graphics.setColor(255, musicOver and 150 or 255, 255)
	love.graphics.printf(musicButton.w, musicButton.x, musicButton.y, 0, "left")
	love.graphics.setColor(255, 255, 255, 255)

	love.graphics.setColor(255, sfxOver and 150 or 255, 255)
	love.graphics.printf(sfxButton.w, sfxButton.x, sfxButton.y, 0, "left")
	love.graphics.setColor(255, 255, 255, 255)

	love.graphics.setColor(255, quitOver and 150 or 255, 255)
	love.graphics.printf(quitButton.w, quitButton.x, quitButton.y, 0, "left")
	love.graphics.setColor(255, 255, 255, 255)

	love.graphics.setFont(font_little)
	love.graphics.printf(message.w, message.x - font_little:getWidth(message.w), message.y - font_little:getHeight(message.w), font_little:getWidth(message.w), "left")
	love.graphics.setFont(font)

	local cm = cursorMusic
	local cs = cursorSFX
	love.graphics.setColor(0, 0, 0, 255)
	rwrc(cm.x - cm.b, cm.y - cm.b, cm.w + 2 * cm.b, cm.h + 2 * cm.b, 1)
	rwrc(cs.x - cs.b, cs.y - cs.b, cs.w + 2 * cs.b, cs.h + 2 * cs.b, 1)
	love.graphics.setColor(255 * (1 - volumeMusic), 255 * volumeMusic / 1, 255)
	rwrc(cm.x, cm.y, volumeMusic * cm.w, cm.h, 0)
	love.graphics.setColor(255 * (1 - volumeSFX), 255 * volumeSFX / 1, 255)
	rwrc(cs.x, cs.y, volumeSFX * cs.w, cs.h, 0)
	love.graphics.setColor(255, 255, 255, 255)
end
-- END drawOption()


