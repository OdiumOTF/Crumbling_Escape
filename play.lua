local play = {
  assets = {
    score = love.graphics.newFont(20),
    default = love.graphics.getFont(),
    player_image = love.graphics.newImage("assets/player.png"),
	  music = love.audio.newSource("assets/music.wav", "stream"),
    died = love.audio.newSource("assets/died.wav", "static"),
    level = love.audio.newSource("assets/level.wav", "static"),
    jump = love.audio.newSource("assets/jump.wav", "static"),
    debris = love.audio.newSource("assets/debris.wav", "static"),
    door = love.graphics.newImage("assets/door.png"),
    ground = love.graphics.newImage("assets/ground.png")
  },
  entry = {
    x = 0,
    y = 0
  },
  exit = {
    x = 0,
    y = 0,
    width = 0,
    height = 0
  },
  player = {
    x = 0,
    y = 0,
    width = 32,
    height = 64,
    speed = 300,
    y_velocity = 0,
    jump_height = -400,
    gravity = -600
  },
  chunks = {
	  a = love.graphics.newImage("assets/chunk_a.png"),
	  b = love.graphics.newImage("assets/chunk_b.png"),
	  c = love.graphics.newImage("assets/chunk_c.png")
  },
  debris_size = { 8, 16, 32},
  difficulty = 2,
  sound = true,
  map_wall_width = 20,
  game_time_score = 0,
  ground = 0
}

function play:toggle_sound()
  self.sound = not self.sound 
  return self.sound 
end

function play:toggle_difficulty()
  self.difficulty = self.difficulty + 1
  if self.difficulty > 3 then
    self.difficulty = 1
  end
  return self.difficulty
end

function play:entered()
  local window_width, window_height = love.graphics.getDimensions()
	
  self.entry.x = self.map_wall_width + 5
  self.entry.y = window_height - self.map_wall_width * 2

  self.exit.width, self.exit.height = self.assets.door:getDimensions()
  self.exit.x = window_width - self.map_wall_width - self.exit.width
  self.exit.y = window_height - self.map_wall_width - self.exit.height

  self.player.x = self.entry.x
  self.player.y = self.entry.y

  self.ground = window_height - self.map_wall_width * 3

  self.debris = {}

  self.game_time_score = 0
  if self.sound then
    self.assets.music:play()
	self.assets.music:setLooping( true )
  end
end

function play:update(dt)
  local window_width, window_height = love.graphics.getDimensions()

  -- Update game score timer
  self.game_time_score = self.game_time_score + dt

  --PLAYER

  -- Apply player movement
  if love.keyboard.isDown("a", "left") and self.player.x > self.map_wall_width then
    self.player.x = self.player.x - self.player.speed * dt
  end 

  if love.keyboard.isDown("d", "right") and self.player.x < window_width - self.map_wall_width - self.player.width then
    self.player.x = self.player.x + self.player.speed * dt
  end 
  --Jumping
  if love.keyboard.isDown("w", "up") and self.player.y > self.map_wall_width then
    if self.player.y_velocity == 0 then
      self.assets.jump:play()
      self.player.y_velocity = self.player.jump_height
    end
  end 

  --Falling
  if self.player.y_velocity ~= 0 then
    self.player.y = self.player.y + self.player.y_velocity *dt
    self.player.y_velocity = self.player.y_velocity - self.player.gravity * dt
  end

  --Check collision with ground
  if self.player.y > self.ground then
    self.player.y_velocity = 0
    self.player.y = self.ground - self.player.height / 2
  end
  
  --DEBRIS

  -- Spawn more debris if the time permits
    while #self.debris < (self.game_time_score / 4) * self.difficulty and #self.debris < 40 do
      local debris = {
        size = self.debris_size[love.math.random(1,3)],
       speed = love.math.random(200, 350),
       x = love.math.random(5, window_width),
       y = -50
     }
    
     table.insert(self.debris, debris)
      if self.sound then
       self.assets.debris:play()
      end
  end

  -- Apply debris movement
  for k, debris in pairs(self.debris) do
    debris.y = debris.y + debris.speed * dt
  end

  -- Remove debris that has left the map
  for i, debris in ipairs(self.debris) do
    if debris.y > window_height + debris.size then
      table.remove(self.debris, i)
    end
  end

  -- Check debris collisions
  for k, debris in pairs(self.debris) do
    local debris_distance_to_player = (((self.player.x + self.player.width / 2) - debris.x)^2+((self.player.y + self.player.height / 2) - debris.y)^2)^0.5
    if (debris_distance_to_player - self.player.width / 2) < debris.size then
      game.states.scoreboard:add_score(self.game_time_score)
      if self.sound then
		    self.assets.music:stop()
        self.assets.died:play()
      end
      game:change_state("scoreboard")
    end
  end

  -- RESET

  --Check if player has reached exit 
  if self.player.x + self.player.width > self.exit.x and self.player.y > self.exit.y then
    -- Clear all debris
    for i, debris in ipairs(self.debris) do
      table.remove(self.debris, i)
    end
    -- Increase score by 10 for each room
    self.game_time_score = self.game_time_score + 10
    -- move ground up
    self.ground = self.ground - 20
    -- move entry up
    self.entry.y = self.entry.y -20
    -- move exit up
    self.exit.y = self.exit.y - 20
    -- Move player to new entry
    self.player.x = self.map_wall_width + 5
    self.player.y = self.entry.y
    
    self.assets.level:play()
  end
end

function play:draw()
  local window_width, window_height = love.graphics.getDimensions()
  
  -- Draw map wall
  love.graphics.setColor(76 / 255 ,70 / 255, 50 / 255)
  love.graphics.rectangle("fill", 0, 0, window_width, window_height)

  -- Draw map play space
  love.graphics.setColor(255 / 255, 217 / 255, 153 / 255)
  love.graphics.rectangle("fill", self.map_wall_width, self.map_wall_width, 
  window_width - self.map_wall_width * 2, window_height - self.map_wall_width * 2)

  -- Draw exit
  love.graphics.setColor(255 / 255, 255 / 255, 255 / 255)
  love.graphics.draw(self.assets.door, self.exit.x, self.exit.y)

  -- Draw player
  love.graphics.setColor(255 / 255, 255 / 255, 255 / 255)
  love.graphics.draw(self.assets.player_image, self.player.x, self.player.y) 

  -- Draw Ground
  love.graphics.setColor(255 / 255, 255 / 255, 255 / 255)
  local window_tile_width = window_width / 64
  for i = 1, 20 do 
    love.graphics.draw(self.assets.ground, 0 + (64 * (i - 1)), self.ground + 40)
  end
  if self.ground > self.map_wall_width then
    for i = 1,20 do 
      love.graphics.draw(self.assets.ground, 0 + (64 * (i - 1)), self.ground + 40 + 64)
    end
  end
  if self.ground > self.map_wall_width * 2 then
    for i = 1,20 do 
      love.graphics.draw(self.assets.ground, 0 + (64 * (i - 1)), self.ground + 40 + 128)
    end
  end

  -- Draw score timer
  love.graphics.setColor(32 / 255 ,13 / 255, 83 / 255)
  love.graphics.setFont(self.assets.score)
  love.graphics.print("Score: " .. self.game_time_score, 50, 50)
  love.graphics.setFont(self.assets.default)
  
  -- Draw debris chunks depending on the size of the chunk
  love.graphics.setColor(230 / 255 ,208 / 255, 166 / 255)
  for k, debris in pairs(self.debris) do
    if debris.size == 8 then
      love.graphics.draw(self.chunks.a, debris.x - debris.size, debris.y - debris.size)
    elseif debris.size == 16 then
      love.graphics.draw(self.chunks.b, debris.x - debris.size, debris.y - debris.size)
    else 
      love.graphics.draw(self.chunks.c, debris.x - debris.size, debris.y - debris.size)
    end
  end
end

--Might need this later
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

return play