local composer = require("composer")
local scene = composer.newScene()

-- Pelin päämuuttujat
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenW = display.contentWidth
local screenH = display.contentHeight

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local loadsave, savedata

-- Pelaaja
local player = {
    model = display.newCircle(centerX, screenH - 50, 20),
    hp = 100,
    exp = 0,
    level = 1,
    moveSpeed = 5,
    bulletDamage = 10
}
player.model:setFillColor(0, 0.5, 1)

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
    local enemy = {
        model = display.newCircle(math.random(20, screenW - 20), -20, 15),
        hp = stats.hp,
        damage = stats.damage,
        exp = math.random(5, 10) + (player.level - 1) * 2 -- EXP kasvaa tason mukana
    }
    enemy.model:setFillColor(1, 0, 0)
    table.insert(enemies, enemy)
end

-- Vihollisten spawn-loopin käynnistäminen
local function spawnEnemies()
    for i = 1, maxEnemiesPerSpawn do
        spawnEnemy()
    end

    -- Lisää spawn-aikataulu uudelleen
    timer.performWithDelay(spawnDelay, spawnEnemies)
end

-- HP-paketit
local hpPacks = {}
local function spawnHpPack(x, y)
    local hpPack = display.newCircle(x, y, 10)
    hpPack:setFillColor(0, 1, 0)
    table.insert(hpPacks, hpPack)
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

        if distance < 20 + 10 then -- Collision detected with HP pack
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
        local bullet = display.newCircle(player.model.x, player.model.y, 5)
        bullet:setFillColor(1, 1, 0)

        local dx = cursorX - player.model.x
        local dy = cursorY - player.model.y
        local distance = math.sqrt(dx^2 + dy^2)

        bullet.vx = (dx / distance) * 10
        bullet.vy = (dy / distance) * 10
        bullet.damage = player.bulletDamage -- Käytä pelaajan vahinkoa

        table.insert(bullets, bullet)
    end
end

-- Pelaajan liikkuminen WASD:llä
local keysPressed = { w = false, a = false, s = false, d = false }

local function onKeyEvent(event)
    local key = event.keyName
    if keysPressed[key] ~= nil then
        if event.phase == "down" then
            keysPressed[key] = true
        elseif event.phase == "up" then
            keysPressed[key] = false
        end
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
    pauseGame()

    -- Luo tausta
    local overlay = display.newRect(centerX, centerY, screenW, screenH)
    overlay:setFillColor(0, 0, 0, 0.8)

    -- Luo otsikko
    local title = display.newText("Level Up!", centerX, centerY - 100, native.systemFontBold, 32)
    title:setFillColor(1, 1, 1)

    -- Luo kolme vaihtoehtoa
    local options = {
        { text = "+20 HP", action = function() player.hp = math.min(player.hp + 20, 100) end },
        { text = "+1 Speed", action = function() player.moveSpeed = player.moveSpeed + 1 end },
        { text = "+5 Bullet Damage", action = function() player.bulletDamage = player.bulletDamage + 5 end }
    }

    -- Satunnaista vaihtoehdot
    local shuffledOptions = {}
    while #options > 0 do
        local index = math.random(#options)
        table.insert(shuffledOptions, table.remove(options, index))
    end

    -- Luo vaihtoehdot-napit
    local buttons = {}
    for i, option in ipairs(shuffledOptions) do
        local button = display.newText(option.text, centerX, centerY - 40 + i * 40, native.systemFont, 24)
        button:setFillColor(1, 1, 0)

        button:addEventListener("tap", function()
            option.action() -- Suorita valitun vaihtoehdon toiminto
            display.remove(overlay)
            display.remove(title)
            for _, b in ipairs(buttons) do
                display.remove(b)
            end
            resumeGame()
        end)

        -- Tason nousun jälkeen spawn-tiheyttä parannetaan
        spawnDelay = math.max(1000, spawnDelay - 500) -- Vähennetään 0,5 sekuntia (minimi 1 sekunti)
        maxEnemiesPerSpawn = math.min(5, maxEnemiesPerSpawn + 1) -- Lisätään enintään 5 vihollista spawnissa

        table.insert(buttons, button)
    end
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
        if distance < 20 + 15 then
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
            if distance < 15 + 5 then
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

-- Näytä Game Over ruutu
local function showGameOverScreen()
    pauseGame()

    local overlay = display.newRect(centerX, centerY, screenW, screenH)
    overlay:setFillColor(0, 0, 0, 0.8)

    local title = display.newText("Game Over", centerX, centerY - 50, native.systemFontBold, 32)
    title:setFillColor(1, 0, 0)

    local restartButton = display.newText("Restart", centerX, centerY + 50, native.systemFont, 24)
    restartButton:setFillColor(1, 1, 0)
    
    restartButton:addEventListener("tap", function()
        composer.gotoScene("game")  -- Vaihdetaan peliin uudelleen
    end)
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
        -- Vihollisten spawn-looppi alkaa
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
