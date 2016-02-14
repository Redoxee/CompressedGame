WindowWidth = 800
WindowHeight = 400
love.load = function()
	love.window.setMode(WindowWidth, WindowHeight)
end

PosX = 400
PosY = 0
CharacterSize = 20
SpeedX = 120

VelocityY = 0
Gravity = -200
JumpForce = 150
WasPressingStomp = false
HasStomp = false
StompForce = -320
LifePoints = 3
BlinkTimer = 0
Points = 0
Multiplier = 1

Enemies = {}
SpawnRate = 1
SpawnTimer = 0
EnemySize = 15
EnemyMinSpeed,EnemyMaxSpeed = 90 , 180

BestScore = "Loading"

reset = function() -- dirty compressed reset
	PosX,PosY,VelocityY,HasStomp,WasPressingStomp,LifePoints,BlinkTimer,Points,Multiplier,Enemies = 400,0,0,false,false,3,0,0,1,{}
end

love.update = function(dt)
	if love.keyboard.isDown("escape") then love.event.push('quit') end

	if LifePoints > 0 then
		local directionX = 0
		if love.keyboard.isDown("right") then directionX = 1 end
		if love.keyboard.isDown("left") then directionX = directionX - 1 end -- If the player is pressing both, the character dont move
		PosX = PosX + directionX * SpeedX * dt
		PosX = math.min(math.max(PosX,0), WindowWidth - CharacterSize) -- Clamping the character into the window

		VelocityY = VelocityY + Gravity * dt
		local isOnGround = PosY <= 1
		if isOnGround then
			HasStomp = false
			Multiplier = 1
			if love.keyboard.isDown("up") then
				VelocityY = JumpForce
			end
		elseif love.keyboard.isDown("down") and not WasPressingStomp and not HasStomp then
			VelocityY = StompForce
			HasStomp = true
		end
		WasPressingStomp = love.keyboard.isDown("down")
		PosY = PosY + VelocityY * dt
		PosY = math.max(PosY , 0)
		updateEnemies(dt)
		local hasHit = false
		for i = #Enemies,1,-1 do
			if rectangleCollision(PosX,PosY,CharacterSize,CharacterSize,Enemies[i].posX,Enemies[i].posY,EnemySize,EnemySize) then
				removeEnemy(i)
				VelocityY = JumpForce
				if HasStomp then
					Points = Points + Multiplier
					Multiplier = Multiplier + 1
				else
					LifePoints = LifePoints - 1
					BlinkTimer = 1
					Multiplier = 1
					if LifePoints == 0 then onGameOver() end
				end
				hasHit = true
			end
		end
		if hasHit then HasStomp = false end
		if BlinkTimer > 0 then BlinkTimer = BlinkTimer - dt end
	else
		if love.keyboard.isDown("r") then reset() end
	end
end

love.draw = function()
	love.graphics.setColor(255,255,20)
	love.graphics.print("Left/Right to move | Up to jump | Down to stomp you'll crush only if you stomp",305,15)
	if LifePoints > 0 then
		love.graphics.print("Life   : " .. tostring(LifePoints) , 15,15)
		love.graphics.print("Points : " .. tostring(Points) .. " Multiplier : " .. tostring(Multiplier), 15 , 35)

		if not (BlinkTimer > 0) or (math.sin(BlinkTimer * math.pi * 15) > .5) then
			if HasStomp then
				love.graphics.setColor(240,240,0)
			else
				love.graphics.setColor(240,240,75)
			end
			local x,y = getPositionFromCamera(PosX,PosY)
			love.graphics.rectangle("fill",x, y - CharacterSize,CharacterSize,CharacterSize)
		end

		love.graphics.setColor(255,65,40)
		for i,enemy in ipairs(Enemies) do
			local x,y = getPositionFromCamera(enemy.posX,enemy.posY)
			love.graphics.rectangle("fill",x,y - EnemySize,EnemySize,EnemySize)
		end
	else
		love.graphics.print("Congratulation you achieved : " .. tostring(Points) .. " Points!" , 325,200)
		love.graphics.print("Best score : " .. tostring(BestScore), 335,220)
		love.graphics.print("Press R to restart", 375,240)
	end
end

getPositionFromCamera = function(x,y)
	return x, y*-1 + WindowHeight
end

updateEnemies = function(dt)
	SpawnTimer = SpawnTimer - dt
	if SpawnTimer < 0 then
		SpawnTimer = SpawnRate
		local goRight = math.random() > .5
		Enemies[#Enemies + 1] = {
			goRight = goRight,
			posY = math.random(0,50),
			posX = goRight and -EnemySize or WindowWidth ,
			speed = math.random(EnemyMinSpeed,EnemyMaxSpeed),
		}
	end
	for i = #Enemies, 1, -1 do
		local enemy = Enemies[i]
		enemy.posX = enemy.posX + enemy.speed * dt * (enemy.goRight and 1 or -1)
 		if (enemy.goRight and enemy.posX > WindowWidth) or (not enemy.goRight and enemy.posX < -EnemySize) then
 			removeEnemy(i)
 		end 
 	end
end

removeEnemy = function(index)
	for i = index,#Enemies - 1 do
		Enemies[i] = Enemies[i + 1]
	end
	Enemies[#Enemies] = nil
end

rectangleCollision = function(x1,y1,width1,height1,x2,y2,width2,height2) -- Simple aabb function
	local isNotColliding = x1 > (x2 + width2) or (x2 > x1 + width1) or y1 > (y2 + height2) or y2 > (y1 + height1)
	return not isNotColliding
end

onGameOver = function()
	queryBestScore()
end
queryBestScore = function()
	if BestScore == "Loading" or (tonumber(BestScore) and tonumber(BestScore) < Points) then
		local http = require("socket.http")
		local b, c, h = http.request("http://antonroy.fr/content/CompressedGame/php/HighScore.php?Score=" .. tostring(Points))
		if c == 200 then BestScore = b else BestScore = "Can't load" end
	end
end
--[[<?php -- Server Side -- yes it is very easy to cheat but I trust you not to
	$host = "stub";
	$db = "stub";
	$dsn = 'stub'.$db.'stub'.$host;
	$user = "stub";
	$pwd = "stub";
	$pdo = new PDO($dsn,$user,$pwd);
	if (isset($_GET["Score"])){
		$_GET["Score"] = htmlspecialchars ($_GET["Score"]);
		$sql = 'SELECT * FROM HighScore WHERE id = 1;';
		$rep = $pdo->query($sql);
		if($rep->rowcount()){
			$rep = $rep->fetch();
			if($rep['Score'] < $_GET["Score"]){
				$sql = 'UPDATE HighScore SET Score='.$_GET["Score"].' WHERE id = 1;';
				$pdo->exec($sql);
			}
		}
	}
	$sql = 'SELECT Score FROM HighScore;';
	$rep = $pdo->query($sql);
	foreach ($rep as $row) {
		echo $row['Score'];
	}
?>--]]