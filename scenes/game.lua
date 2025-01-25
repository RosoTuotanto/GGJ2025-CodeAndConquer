local composer = require("composer")
local scene = composer.newScene()
local camera = display.newGroup()


-- Luo pelikentän taustakuva
local object = display.newImageRect("assets/images/waterground.png", 5500, 5500)
object.x = display.contentCenterX
object.y = display.contentCenterY

-- Pelin päämuuttujat
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenW = display.contentWidth
local screenH = display.contentHeight

-- Lisää pelikenttä kameraan
camera:insert(object)

--------------------------------------------------
-- AUDIO & MUSIC ------
--------------------------------------------------
audio.setVolume( 1 )
local gunshotSound = audio.loadSound( "assets/audio/fx/guns/bubble_wand/bubble_wand_shoot.wav" )
local channels = { gunshot = 1 , explosion = 2 , enemy = 3 , background = 4 , music_drums = 5, music_melody = 6 }
local drums = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_drums_hard.wav")
local melody = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_melody_hard.wav")


local musicFiles = {
    rising_threat = {
        easy = {
            drums = audio.loadSound("assets/audio/rising_threat/rising_threat_rummut_easy.mp3"),
            melody = audio.loadSound("assets/audio/rising_threat/rising_threat_melodia_easy.mp3")
        },
        medium = {
            drums = audio.loadSound("assets/audio/rising_threat/rising_threat_rummut_medium.mp3"),
            melody = audio.loadSound("assets/audio/rising_threat/rising_threat_melodia_medium.mp3")
        },
        hard = {
            drums = audio.loadSound("assets/audio/rising_threat/rising_threat_rummut_hard.mp3"),
            melody = audio.loadSound("assets/audio/rising_threat/rising_threat_melodia_hard.mp3")
        }
    },
    boss = {
        easy = {
            drums = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_3_rummut_easy.mp3"),
            melody = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_3_melodia_easy.mp3")
        },
        medium = {
            drums = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_3_rummut_medium.mp3"),
            melody = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_3_melodia_medium.mp3")
        },
        hard = {
            drums = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_3_rummut_hard.mp3"),
            melody = audio.loadSound("assets/audio/wrath_unleashed/wrath_unleashed_3_melodia_hard.mp3")
        }
    }
    -- journey_ahead = {
    --     easy = {
    --         drums = audio.loadStream("assets/audio/uhmakas_3_rummut_easy.wav"),
    --         melody = audio.loadStream("assets/audio/uhmakas_3_melodia_easy.wav")
    --     },
    --     medium = {
    --         drums = audio.loadStream("assets/audio/uhmakas_3_rummut_medium.wav"),
    --         melody = audio.loadStream("assets/audio/uhmakas_3_melodia_medium.wav")
    --     },
    --     hard = {
    --         drums = audio.loadStream("assets/audio/uhmakas_3_rummut_hard.wav"),
    --         melody = audio.loadStream("assets/audio/uhmakas_3_melodia_hard.wav")
    --     }
    -- }
}


local music = musicFiles.rising_threat.hard   

local function playMusic()
    audio.stop(channels.music_drums)
    audio.stop(channels.music_melody)
    audio.setVolume( 0.75, { channel = channels.music_drums } )
    audio.setVolume( 0.75, {  channel = channels.music_melody} )
    audio.play( music.drums, { channel = channels.music_drums, loops = -1 } )
    audio.play( music.melody, { channel = channels.music_melody, loops = -1 } )
end


local function pauseMelody()
    audio.stop(channels.music_melody)
end

local function gamePausedMusic()
    pauseMelody()
end

local function resumeMusic()
    playMusic()
end

playMusic()

--------------------------------------------------
-- AUDIO & MUSIC ------ END
--------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local loadsave, savedata

-- Lataa kuvasarja
local playerImages = {
    "assets/images/player.png", -- Ensimmäinen kuva
    "assets/images/player2.png", -- Toinen kuva
}
-- Pelaaja
local player = {
    model = display.newImageRect(camera, playerImages[1], 120, 120), -- Käytä kuvaa pelaajahahmona
    currentFrame = 1,
    hp = 100,
    exp = 0,
    level = 1,
    moveSpeed = 5,
    bulletDamage = 10,
}

player.boostSpeed = player.moveSpeed*5  -- Nopeus boostin aikana
player.boostDuration = 80 -- Boostin kesto millisekunteina (2 sekuntia)
player.isBoosting = false -- Tila, onko pelaaja tällä hetkellä boostissa

-- Asetetaan pelaajan hahmo aloituskohtaan
player.model.x = centerX
player.model.y = centerY

player.xStart = player.model.x
player.yStart = player.model.y

-- Asetukset animaatiolle
local animationInterval = 200


-- Funktio kuvan vaihtamiseen
local function animatePlayer()
    -- Vaihda seuraavaan ruutuun
    player.currentFrame = player.currentFrame + 1
    if player.currentFrame > #playerImages then
        player.currentFrame = 1 -- Palaa ensimmäiseen kuvaan
    end

    -- Päivitä pelaajan kuva
    player.model.fill = { type = "image", filename = playerImages[player.currentFrame] }
end

-- Ajastettu animaatio (toistuva tapahtuma)
timer.performWithDelay(animationInterval, animatePlayer, 0) -- Toista loputtomasti



-- Kokemuspisteiden raja seuraavaa tasoa varten
local levelUpExpThreshold = 50 -- EXP tarvitaan level-upiin

-- Viholliset
local enemies = {}
local initialSpawnDelay = 5000 -- millisekuntia (5 sekuntia)
local spawnDelay = initialSpawnDelay
local maxEnemiesPerSpawn = 1 -- Määrä vihollisia per spawn (kasvaa tason mukaan)

-- Pelaajan tason vaikutus vihollisiin
local function calculateEnemyStats()
    local baseHp = 15
    local baseDamage = 10
    local hpIncreasePerLevel = 5
    local damageIncreasePerLevel = 2

    return {
        hp = baseHp + hpIncreasePerLevel * (player.level - 1),
        damage = baseDamage + damageIncreasePerLevel * (player.level - 1)
    }
end

local function spawnEnemy()
    local stats = calculateEnemyStats()

    -- Luo vihollinen kuvatiedostolla
    local enemy = {
        model = display.newImageRect(camera, "assets/images/slime.png", 50, 50), -- Käytä ensimmäistä kuvaa
        hp = stats.hp,
        damage = stats.damage,
        exp = math.random(5, 10) + (player.level - 1) * 2 -- EXP kasvaa tason mukana
    }

    -- Aseta vihollisen sijainti (satunnainen reuna)
    local spawnPosition = math.random(4)
    if spawnPosition == 1 then
        -- Yläreuna
        enemy.model.x = math.random(20, screenW - 20)
        enemy.model.y = -20
    elseif spawnPosition == 2 then
        -- Alareuna
        enemy.model.x = math.random(20, screenW - 20)
        enemy.model.y = screenH + 20
    elseif spawnPosition == 3 then
        -- Vasemmalta
        enemy.model.x = -20
        enemy.model.y = math.random(20, screenH - 20)
    elseif spawnPosition == 4 then
        -- Oikealta
        enemy.model.x = screenW + 20
        enemy.model.y = math.random(20, screenH - 20)
    end

    -- Lisää vihollinen listaan
    table.insert(enemies, enemy)

    -- Animaatio: Vaihda kahden kuvan välillä
    local frame = 1
    local function animateEnemy()
        if enemy.model.removeSelf == nil then
            -- Jos vihollinen on poistettu, lopeta animaatio
            return
        end
        if frame == 1 then
            enemy.model.fill = { type = "image", filename = "assets/images/slime2.png" }
            frame = 2
        else
            enemy.model.fill = { type = "image", filename = "assets/images/slime.png" }
            frame = 1
        end
    end

    -- Käynnistä animaatio 500 ms välein
    timer.performWithDelay(500, animateEnemy, 0)
end

-- Vihollisten spawn-loopin käynnistäminen
local function spawnEnemies()
    for i = 1, maxEnemiesPerSpawn do
        spawnEnemy()
    end

    -- Lisää spawn-aikataulu uudelleen
    timer.performWithDelay(spawnDelay, spawnEnemies)
end

-- Aloita vihollisten spawnaaminen
timer.performWithDelay(spawnDelay, spawnEnemies)



-- HP-paketit
local hpPacks = {}
local function spawnHpPack(x, y)
    -- Luo HP-paketti käyttäen ensimmäistä kuvaa
    local hpPack = display.newImageRect(camera, "/assets/images/healthpack.png", 50, 50)
    hpPack.x = x  -- Aseta x-koordinaatti
    hpPack.y = y  -- Aseta y-koordinaatti

    -- Lisää HP-paketti listaan
    table.insert(hpPacks, hpPack)

    -- Animaatio: Vaihda kahden kuvan välillä
    local frame = 1
    local function animateHpPack()
        if hpPack.removeSelf == nil then
            -- Jos HP-paketti on jo poistettu, lopeta animaatio
            return
        end
        if frame == 1 then
            hpPack.fill = { type = "image", filename = "/assets/images/healthpack2.png" }
            frame = 2
        else
            hpPack.fill = { type = "image", filename = "/assets/images/healthpack.png" }
            frame = 1
        end
    end

    -- Suorita animaatio 500 ms välein toistuvasti
    timer.performWithDelay(500, animateHpPack, 0)
end

-- Luodit
local bullets = {}

-- Kursorin sijainti
local cursorX, cursorY = centerX, centerY

-- Päivitä hiiren sijainti
local function onMouseEvent(event)
    cursorX = event.x
    cursorY = event.y
end

local function checkHpPackCollision()
    for i = #hpPacks, 1, -1 do
        local hpPack = hpPacks[i]
        local dx = player.model.x - hpPack.x
        local dy = player.model.y - hpPack.y
        local distance = math.sqrt(dx^2 + dy^2)

        if distance < 60 + 10 then -- Collision detected with HP pack
            player.hp = math.min(player.hp + 20, 100)  -- Heal player, max HP 100
            print("Pelaajan HP:", player.hp)

            display.remove(hpPack)  -- Remove the HP pack after collecting
            table.remove(hpPacks, i)
        end
    end
end


-- Pelaajan ampuminen
local function fireBullet(event)
    if event.phase == "began" then
        local bullet = display.newImageRect( camera, "/assets/images/bubble6.png", 40, 40 )

        bullet.x = player.model.x
        bullet.y = player.model.y
        local dx = (cursorX - player.model.x)-camera.x
        local dy = (cursorY - player.model.y)-camera.y
        local distance = math.sqrt(dx^2 + dy^2)

        bullet.vx = (dx / distance) * 10
        bullet.vy = (dy / distance) * 10
        bullet.damage = player.bulletDamage -- Käytä pelaajan vahinkoa

        table.insert(bullets, bullet)
    end
end

-- Pelaajan liikkuminen WASD:llä
local keysPressed = { w = false, a = false, s = false, d = false }

local function activateSpeedBoost()
    if player.isBoosting then return end -- Estä boostin päällekkäisyys

    player.isBoosting = true -- Pelaaja on boostissa
    local originalSpeed = player.moveSpeed -- Tallenna alkuperäinen nopeus
    player.moveSpeed = player.boostSpeed -- Aseta nopeus boostinopeudeksi

    -- Palauta nopeus normaaliksi boostin jälkeen
    timer.performWithDelay(player.boostDuration, function()
        player.moveSpeed = originalSpeed
        player.isBoosting = false
    end)
end

local function onKeyEvent(event)
    local key = event.keyName
    if keysPressed[key] ~= nil then
        if event.phase == "down" then
            keysPressed[key] = true
        elseif event.phase == "up" then
            keysPressed[key] = false
        end
    end

        -- Tarkista spacebar boostille
        if key == "space" and event.phase == "down" and not player.isBoosting then
            activateSpeedBoost()
        end
    
        return true
end

local function updatePlayerMovement()
    if keysPressed.w then
        player.model.y = math.max(player.model.y - player.moveSpeed, 0)
       
    end
    if keysPressed.s then
        player.model.y = math.min(player.model.y + player.moveSpeed, screenH)
    end
    if keysPressed.a then
        player.model.x = math.max(player.model.x - player.moveSpeed, 0)
    end
    if keysPressed.d then
        player.model.x = math.min(player.model.x + player.moveSpeed, screenW)
    end

    camera.y = (player.yStart - player.model.y)
    camera.x = (player.xStart - player.model.x)
end

-- Pelin tauottaminen ja jatkaminen
local isPaused = false
local function pauseGame()
    isPaused = true
end

local function resumeGame()
    isPaused = false
end

-- Level-up-näkymä
local function showLevelUpScreen()
    pauseGame()  -- Pause the game
    
    -- Create the background overlay
    local overlay = display.newRect(centerX, centerY, screenW, screenH)
    overlay:setFillColor(0, 0, 0, 0.8)

    -- Create the title
    local title = display.newText("Level Up!", centerX, centerY - 100, native.systemFontBold, 32)
    title:setFillColor(1, 1, 1)

    local friendCount = 0  -- Track the number of friends
    local options = {
        { text = "+20 HP", action = function() player.hp = math.min(player.hp + 20, 100) end },
        { text = "+1 Speed", action = function() player.moveSpeed = player.moveSpeed + 1 end },
        { text = "+5 Bullet Damage", action = function() player.bulletDamage = player.bulletDamage + 5 end },
        { text = "+1 Friend", action = function() 
            if friendCount < 4 then  -- Limit to 4 friends
                friendCount = friendCount + 1
                local friend = display.newImageRect( camera, "assets/images/allyshrimp.png", 30, 30 )
                friend.x = player.model.x
                friend.y = player.model.y

            end
        end }
    }

    -- Shuffle options and pick 3 random ones
    local shuffledOptions = {}
    while #shuffledOptions < 3 and #options > 0 do
        local index = math.random(#options)
        table.insert(shuffledOptions, table.remove(options, index))
    end

    -- Create buttons for the options
    local buttons = {}
    for i, option in ipairs(shuffledOptions) do
        local button = display.newText(option.text, centerX, centerY + 40 * i, native.systemFont, 24)
        button:setFillColor(1, 1, 0)

        -- Button tap action
        button:addEventListener("tap", function()
            option.action()  -- Execute the selected option's action
            -- Remove level-up screen after selecting an option
            display.remove(overlay)
            display.remove(title)
            for _, b in ipairs(buttons) do
                display.remove(b)
            end
            resumeGame()  -- Resume the game
        end)

        table.insert(buttons, button)
    end

    -- Adjust spawn settings after level-up
    spawnDelay = math.max(1000, spawnDelay - 500)  -- Decrease spawn delay, but no less than 1 second
    maxEnemiesPerSpawn = math.min(5, maxEnemiesPerSpawn + 1)  -- Increase the number of enemies spawned, but no more than 5
end


-- Vihollisten liikuttaminen ja törmäys
local function moveEnemies()
    if isPaused then return end
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local dx = player.model.x - enemy.model.x
        local dy = player.model.y - enemy.model.y
        local distance = math.sqrt(dx^2 + dy^2)
        local speed = 2

        if distance > 0 then
            enemy.model.x = enemy.model.x + (dx / distance) * speed
            enemy.model.y = enemy.model.y + (dy / distance) * speed
        end

        -- Pelaajaan osuminen
        if distance < 60 + 15 then
            player.hp = player.hp - enemy.damage
            print("Pelaaja osui viholliseen! Pelaajan HP:", player.hp)

            display.remove(enemy.model)
            table.remove(enemies, i)
        end
    end
end

-- Luotien liikuttaminen
local function moveBullets()
    if isPaused then return end
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.x = bullet.x + bullet.vx
        bullet.y = bullet.y + bullet.vy

        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            local dx = bullet.x - enemy.model.x
            local dy = bullet.y - enemy.model.y
            local distance = math.sqrt(dx^2 + dy^2)
            if distance < 40 + 5 then
                enemy.hp = enemy.hp - bullet.damage
                print("Viholliseen osui! HP:", enemy.hp)
                if enemy.hp <= 0 then
                    player.exp = player.exp + enemy.exp
                    print("Vihollinen kuoli! EXP:", player.exp)

                    -- Satunnainen todennäköisyys HP-paketin tiputukseen (esim. 30% mahdollisuus)
                    if math.random() < 0.3 then
                        spawnHpPack(enemy.model.x, enemy.model.y)  -- HP-paketti tiputetaan
                        print("HP-paketti tiputettu!")
                    end

                    if player.exp >= levelUpExpThreshold then
                        player.exp = 0
                        player.level = player.level + 1
                        print("Taso nousi! Nykyinen taso:", player.level)
                        showLevelUpScreen()
                    end

                    -- Lisää splatter kupla-hajoamispisteeseen
                    local splatter = display.newImageRect(camera, "assets/images/splatter.png", 80, 80)
                    splatter.x = enemy.model.x
                    splatter.y = enemy.model.y

                    -- Voit lisätä animaation tai hävittää kuvan myöhemmin
                    transition.to(splatter, { alpha = 0, time = 5000, onComplete = function() display.remove(splatter) end })

                    display.remove(enemy.model)
                    table.remove(enemies, j)
                end

                display.remove(bullet)
                table.remove(bullets, i)
                break
            end
        end
    end
end



local function restartGame()
    -- Reset any necessary game state variables before transitioning
    player.hp = 100  -- Reset player health
    player.level = 1  -- Reset player level
    player.exp = 0    -- Reset experience
    -- Clear enemies or other game state (if necessary)
    for i = #enemies, 1, -1 do
        display.remove(enemies[i])  -- Remove all enemies
        table.remove(enemies, i)
    end

    -- Remove any timers or listeners
    Runtime:removeEventListener("enterFrame", gameLoop)
    Runtime:removeEventListener("key", onKeyEvent)
    Runtime:removeEventListener("touch", fireBullet)

    -- Transition to the game scene and reset everything
    composer.removeScene("scenes.game")  -- Clear previous scene
    composer.gotoScene("scenes.game", { effect = "fade", time = 500 })  -- Transition to the game scene
end


-- Näytä Game Over ruutu
local function showGameOverScreen()
    pauseGame()  -- Pause the game
    
    -- Create game over screen
    local overlay = display.newRect(centerX, centerY, screenW, screenH)
    overlay:setFillColor(0, 0, 0, 0.8)

    local title = display.newText("Game Over", centerX, centerY - 50, native.systemFontBold, 32)
    title:setFillColor(1, 0, 0)

    local restartButton = display.newText("Restart", centerX, centerY + 50, native.systemFont, 24)
    restartButton:setFillColor(1, 1, 0)
    
    restartButton:addEventListener("tap", restartGame)  -- Restart the game on tap
end


-- Tarkista pelaajan HP
local function checkPlayerHealth()
    if player.hp <= 0 then
        showGameOverScreen()
    end
end



-- Pelin päivitys
local function gameLoop()
    if isPaused then return end
    updatePlayerMovement()
    moveEnemies()
    moveBullets()
    checkPlayerHealth()  -- Tarkistetaan pelaajan terveys
    checkHpPackCollision()  -- Tarkistetaan pelaajan osuminen HP-packeihin
end

-- scene:show -tilassa alustetaan ja käynnistetään spawn- ja peli
function scene:show(event)
    local sceneGroup = self.view
    if event.phase == "did" then
        -- Reset game variables here
        player.hp = 100
        player.level = 1
        player.exp = 0
        -- Reset enemies, bullets, etc.

        -- Start the game logic
        timer.performWithDelay(spawnDelay, spawnEnemies)
        Runtime:addEventListener("key", onKeyEvent)
        Runtime:addEventListener("touch", fireBullet)
        Runtime:addEventListener("mouse", onMouseEvent)
        Runtime:addEventListener("enterFrame", gameLoop)
    end
end

-- scene:hide -tapahtumassa lopetetaan peli ja poistetaan tapahtumakuuntelijat
function scene:hide(event)
    local sceneGroup = self.view
    if event.phase == "will" then
        -- Poistetaan kuuntelijat
        Runtime:removeEventListener("key", onKeyEvent)
        Runtime:removeEventListener("touch", fireBullet)
        Runtime:removeEventListener("mouse", onMouseEvent)
        Runtime:removeEventListener("enterFrame", gameLoop)
    end
end

-- Lisää tapahtumakuuntelijat
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene