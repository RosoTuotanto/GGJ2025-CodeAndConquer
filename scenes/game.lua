local composer = require("composer")
local scene = composer.newScene()
local camera = display.newGroup()
local friendList = {}

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

native.setProperty( "mouseCursor", "crosshair" )
native.setProperty( "mouseCursorVisible", false)
local crosshair = display.newImageRect("assets/images/crosshair.png", 64, 64)
crosshair.isVisible = false
local function onMouseMove(event)
    crosshair.x = event.x
    crosshair.y = event.y
    crosshair.isVisible = true
end

Runtime:addEventListener("mouse", onMouseMove)

--------------------------------------------------
-- AUDIO & MUSIC ------
--------------------------------------------------
audio.setVolume( 1 )

local gunshotSounds = {
    gunlevel1 = audio.loadSound( "assets/audio/fx/guns/bubble_wand/bubble_wand_shoot.wav" ),
    gunlevel2 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" ),
    gunlevel3 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" ),
    gunlevel4 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" ),
    gunlevel5 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" ),
    gunlevel6 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" ),
    gunlevel7 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" )
}

local gunshotSound = audio.loadSound( gunshotSounds.gunlevel1 )


local channels = { gunshot = 1 , explosion = 2 , enemy = 3 , background = 4 , music_drums = 5, music_melody = 6 , pickup = 7}

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
    wrath_unleashed = {
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

local music = musicFiles.rising_threat.easy   
local intensityLvl = "easy"

local function playMusic()
    audio.stop(channels.music_drums)
    audio.stop(channels.music_melody)
    audio.setVolume( 0.55, { channel = channels.music_drums } )
    audio.setVolume( 0.55, {  channel = channels.music_melody} )
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

local function pauseMusic()
    audio.stop(channels.music_drums)
    audio.stop(channels.music_melody)
end

local FXfiles = {   
    gameover = audio.loadSound("assets/audio/fx/environment/gameover_jingle.wav"),
    gameoverSlap = audio.loadSound("assets/audio/fx/environment/gameover_slap.wav"),
    lvlUp = audio.loadSound("assets/audio/fx/environment/lvl_up.wav"),
    perkChosen = audio.loadSound("assets/audio/fx/environment/perk_chosen.wav"),
    waveClear = audio.loadSound("assets/audio/fx/environment/wave_clear_jingle.wav"),
    enemyDamage = audio.loadSound("assets/audio/fx/environment/enemy_damage.wav"),
    enemyDie = audio.loadSound("assets/audio/fx/environment/enemy_die.wav"),
    playerHit = audio.loadSound("assets/audio/fx/environment/player_hit.wav"),
    healthPickup = audio.loadSound("assets/audio/fx/environment/health_pickup.wav")
}

local function getIntensityByLevel(level)
    if level <= 5 then
        return "easy"
    elseif level <= 6 then
        return "medium"
    else
        return "hard"
    end
end

function updateMusicIntensity()
    
    if player.level >= 5 and currentLevel > 5 then
        -- sorry not yet working changing system
        music = musicFiles.wrath_unleashed[intensityLvl]
    else
        -- music = musicFiles.rising_threat[intensityLvl]
        music = musicFiles.wrath_unleashed[intensityLvl]
    end
    playMusic()
    pauseMelody()
end

local function playerLevelUpMusic(playerlevel)
    
    local intensity = getIntensityByLevel(playerlevel)
    if intensity ~= intensityLvl then
        intensityLvl = intensity
        print("intensity CHANGED", intensityLvl)
        updateMusicIntensity()
    end

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


player = {
    model = display.newImageRect(camera, playerImages[1], 120, 120), -- Käytä kuvaa pelaajahahmona
    currentFrame = 1,
    hp = 100,
    exp = 0,
    level = 1,
    moveSpeed = 2,
    bulletDamage = 10,
    bulletSpeed = 10,
}

local background = display.newImageRect( "/assets/images/uibubble2.png", 1850, 150)
background.x = 960
background.y = 100

local moveSpeedText= display.newText({
    text = "MS:" .. player.moveSpeed,
    x = 960,
    y = 100,
    font =  native.systemFont,
    fontSize = 56,
})
local function updateMoveSpeedText()
    moveSpeedText.text = "MS:" .. player.moveSpeed
end

moveSpeedText:setFillColor(0, 0, 0)

local bulletDamageText= display.newText({
    text = "DMG:" .. player.bulletDamage,
    x = 480,
    y = 100,
    font =  native.systemFont,
    fontSize = 56,
})
local function updateBulletDamageText()
    bulletDamageText.text = "DMG:" .. player.bulletDamage
end

bulletDamageText:setFillColor(0, 0, 0)

local friendCountText = display.newText({
    text = "Friends: " .. #friendList,
    x = 1540,
    y = 100,
    font =  native.systemFont,
    fontSize = 56,
})
    -- Funktio päivittää friendCountin tekstin
local function updateFriendCountText()
    friendCountText.text = "Friends: " .. #friendList
end

friendCountText:setFillColor(0, 0, 0)

local background = display.newImageRect( "/assets/images/uibubblelvl.png", 150, 150)
background.x = 952
background.y = 990

local levelText = display.newText({
    text = player.level,
    x = 960,
    y = 1000,
    font =  native.systemFont,
    fontSize = 56,
})
local function updateLevelText()
    levelText.text = player.level
end

levelText:setFillColor(0, 0, 0)


local background = display.newImageRect( "/assets/images/uibubblehp2.png", 150, 150)
background.x = 90
background.y = 1000


local hpText = display.newText({
    text = player.hp,
    x = 75,
    y = 997,
    font = native.systemFont,
    fontSize = 27,
    fontColor = blue
})

hpText:setFillColor(1, 0, 0)

local hpText2 = display.newText({
    text = "100",
    x = 123,
    y = 1021,
    font = native.systemFont,
    fontSize = 27,
})

hpText2:setFillColor(0, 0, 0)

hpText:toFront() 


local function updateHPDisplay()
    hpText.text = player.hp
end

player.boostSpeed = player.moveSpeed*5
player.boostDuration = 80
player.isBoosting = false
player.gunlevel = 1

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

local function increaselevelUpExpThreshold() 
    levelUpExpThreshold = (levelUpExpThreshold * player.level / 2) * 1.1
end

local function checkGunUpgrades()
    
    if  player.bulletDamage >= 70 then    
        gunshotSound = gunshotSounds.gunlevel7
        player.bulletSpeed = 70/1
        player.gunlevel = 6

    elseif player.bulletDamage >= 60 then
        gunshotSound = gunshotSounds.gunlevel6
        player.bulletSpeed = 70/2
        player.gunlevel = 5

    elseif player.bulletDamage >= 50 then
        gunshotSound = gunshotSounds.gunlevel5
        player.bulletSpeed = 70/3
        player.gunlevel = 4

    elseif player.bulletDamage >= 40 then
        gunshotSound = gunshotSounds.gunlevel4
        player.bulletSpeed = 70/4
        player.gunlevel = 3

    elseif player.bulletDamage >= 20 then
        gunshotSound = gunshotSounds.gunlevel3
        player.bulletSpeed = 70/5
        player.gunlevel = 2

    elseif player.bulletDamage >= 15 then
        gunshotSound = gunshotSounds.gunlevel2
        player.bulletSpeed = 70/6
        player.gunlevel = 1

    else
        gunshotSound = gunshotSounds.gunlevel1

    end

end

-- Viholliset
local enemies = {}
local initialSpawnDelay = 5000 -- millisekuntia (5 sekuntia)
local spawnDelay = initialSpawnDelay
local maxEnemiesPerSpawn = 1 -- Määrä vihollisia per spawn (kasvaa tason mukaan)
currentLevel = 1 -- käytännössä määrää pelin kulun!
local enemiesPerLevel = 1  * currentLevel * maxEnemiesPerSpawn -- Määrä vihollisia per taso (kasvaa tason mukaan)
local totalEnemiesSpawned = 0
local enemiesDown = 0

local bosslLevels = { 
    [5] = {
        bossName = "Piranha",
        bossResource = nil,
        bossPicture1 = "assets/images/piranha.png",
        bossPicture2 = "assets/images/piranha2.png",
        isSpawned = false,
        isDead = false,
        hp = 200,
        damage = 10,
        exp = 200,
        speedMultiplier = 1.5,
    },
    [8] = {
        bossName = "Seahorse",
        bossResource = nil,
        bossPicture1 = "assets/images/seahorse.png",
        bossPicture2 = "assets/images/seahorse2.png",
        isSpawned = false,
        isDead = false,
        hp = 2000,
        damage = 20,
        exp = 700,
        speedMultiplier = 2
    },
    [12] = {
        bossName = "Swordfish",
        bossResource = nil,
        bossPicture1 = "assets/images/swordfish.png",
        bossPicture2 = "assets/images/swordfish2.png",
        isSpawned = false,
        isDead = false,
        hp = 3500,
        damage = 50,
        exp = 2000,
        speedMultiplier = 2
    },
    [15] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 15000,
        damage = 70,
        exp = 10500,
        speedMultiplier = 2
    },
    [17] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 300,
        damage = 50,
        exp = 100000,
        speedMultiplier = 2
    },
    [30] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 350,
        damage = 50,
        exp = 100000000,
        speedMultiplier = 2
    },
    [35] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 400,
        damage = 50,
        exp = 1000000000,
        speedMultiplier = 2
    },
    [40] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 450,
        damage = 50,
        exp = 100000000000,
        speedMultiplier = 2
    }

}

local function enemyDown()
    enemiesDown = enemiesDown + 1

    if enemiesDown >= enemiesPerLevel then
        -- ei voida edistää peliä jos bossi on olemassa
        if bosslLevels[currentLevel] ~= nil and
         bosslLevels[currentLevel].isSpawned == true and
         bosslLevels[currentLevel].isDead == false
          then
            return
        end

        currentLevel = currentLevel + 1
        enemiesPerLevel = enemiesPerLevel  * currentLevel * maxEnemiesPerSpawn
        print("Taso", currentLevel, "aloittaa")
        print("vihuja nitistettävä", enemiesPerLevel, "!")
        print("enemiesDown", enemiesDown)
        if bosslLevels[currentLevel] ~= nil then
          if bosslLevels[currentLevel].isSpawned == false then
            spawnBoss()
          end
        end
    end

end

function spawnBoss()
    print("Spawnataan boss")
    local boss = {}
    boss.model = display.newImageRect(camera, bosslLevels[currentLevel].bossPicture1, 100 * (currentLevel * 0.3), 100 * (currentLevel * 0.3))

    local tempImage = display.newImage(bosslLevels[currentLevel].bossPicture1)
    local imageWidth = tempImage.contentWidth
    local imageHeight = tempImage.contentHeight
    tempImage:removeSelf()

    local desiredHeight = 100 * (currentLevel * 0.5)
    local scaleFactor = desiredHeight / imageHeight
    boss.model.height = desiredHeight
    boss.model.width = imageWidth * scaleFactor

    boss.x = display.contentCenterX
    boss.y = display.contentCenterY
    boss.hp = bosslLevels[currentLevel].hp
    boss.damage = bosslLevels[currentLevel].damage
    boss.exp = bosslLevels[currentLevel].exp
    boss.isDead = false
    boss.isBoss = true

    print("bossPicture1: " .. bosslLevels[currentLevel].bossPicture1)
    bosslLevels[currentLevel].isSpawned = true

    bosslLevels[currentLevel].bossResource = boss

    table.insert(enemies, boss)

    local frame = 1
    local function animateBoss()
        -- print("animateBoss(): animoidaan bossi")
        local boss = bosslLevels[currentLevel].bossResource
        
        if boss.isDead or not boss.model then
            removeBoss(boss)
            if bosslLevels[currentLevel].bossResource.timer then timer.cancel(bosslLevels[currentLevel].bossResource.timer)
                bosslLevels[currentLevel].bossResource.timer = nil
            end
            if boss.timer then timer.cancel(boss.timer)
            end
            
            return
        end
        if boss.model.removeSelf == nil then
            removeBoss(boss)
            if bosslLevels[currentLevel].bossResource.timer then timer.cancel(bosslLevels[currentLevel].bossResource.timer)
                bosslLevels[currentLevel].bossResource.timer = nil
            end
            if boss.timer then timer.cancel(boss.timer)
            end
            return
        end
        -- print("animateBoss(): animoidaan bossia EDELLEEN")
        if frame == 1 then
            boss.model.fill = { type = "image", filename = bosslLevels[currentLevel].bossPicture1 }
            frame = 2
        else
            boss.model.fill = { type = "image", filename = bosslLevels[currentLevel].bossPicture2 } 
            frame = 1
        end
        local dx = player.model.x - boss.model.x
        local dy = player.model.y - boss.model.y
        local angle = math.deg(math.atan2(dy, dx)) -- Kulma radiaaneista asteiksi

        boss.model.rotation = angle

        if dx < 0 then
            boss.model.yScale = -1
        else
            boss.model.yScale = 1
        end
    end

    -- Käynnistä animaatio 300 ms välein
    bosslLevels[currentLevel].bossResource.timer = timer.performWithDelay(300, animateBoss, 0)
end

function removeBoss(boss)
    print("removeBoss(): poistetaan boss")
    if boss ~= nil then
            
        if boss.timer then
            timer.cancel(boss.timer)
            boss.timer = nil
        end
        if boss.model.removeSelf then
            boss.model:removeSelf()
            boss.model = nil
        end
        boss.isDead = true
    end

    if bosslLevels[currentLevel] then
        bosslLevels[currentLevel].isDead = true
    end

    if bosslLevels[currentLevel].bossResource.timer then
        timer.cancel(bosslLevels[currentLevel].bossResource.timer)
    end

end

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
        model = display.newImageRect(camera, "assets/images/slime1.png", 50, 50), -- Käytä ensimmäistä kuvaa
        hp = stats.hp,
        damage = stats.damage,
        exp = math.random(5, 10) + (player.level - 1) * 1.15, -- EXP kasvaa tason mukana
        isBoss = false,
        variant = 2 * math.random(3) - 1
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
            enemy.model.fill = { type = "image", filename = "assets/images/slime" .. enemy.variant .. ".png" }
            frame = 2
        else
            enemy.model.fill = { type = "image", filename = "assets/images/slime" .. (enemy.variant + 1).. ".png" }
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
local  friendBullets = {}
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

        if distance < 60 + 10 then
            player.hp = math.min(player.hp + 20, 100)
            print("Pelaajan HP:", player.hp)
            audio.stop( channels.pickup )
            audio.play( FXfiles.healthPickup, { channel = channels.pickup, loops = 0, fadein = 0, fadeout = 0 } )
            display.remove(hpPack)
            table.remove(hpPacks, i)
            updateHPDisplay()
        end
    end
end

-- Pelaajan ampuminen
local function fireBullet(event)
    
    if event.phase == "began" then
        local shooter = {player.model}
        audio.stop(channels.gunshot)
        audio.play(gunshotSound, { channel = channels.gunshot, loops = 0, fadein = 0, fadeout = 0 });
        

        if #friendList > 0 then
            for i=1, #friendList do
                table.insert(shooter,friendList[i])
            end
        end

        for i=1, #shooter do

            local bullet = display.newImageRect(camera, "/assets/images/bubble" .. player.gunlevel .. ".png", 40, 40)

            local origin = shooter[i]

            bullet.x = origin.x
            bullet.y = origin.y
            local dx = (cursorX - origin.x)-camera.x
            local dy = (cursorY - origin.y)-camera.y
            local distance = math.sqrt(dx^2 + dy^2)

            bullet.vx = (dx / distance) * player.bulletSpeed
            bullet.vy = (dy / distance) * player.bulletSpeed

            local damageMultiplier = origin == player.model and 1 or 0.5
            bullet.damage = player.bulletDamage*damageMultiplier-- Käytä pelaajan vahinkoa
            
        table.insert(bullets, bullet)

        end
    end
end

-- AUTOFIRE MEKANIIKKA

-- local isShooting = false
-- local autoFireTimer = nil

-- local function startAutoFire()
--     fireBullet()
--     if not isShooting then
--         isShooting = true
--         autoFireTimer = timer.performWithDelay(300 / player.gunlevel * 2, fireBullet, 0) -- Ammu 200 ms välein
--     end
-- end

-- local function stopAutoFire()
--     if isShooting then
--         isShooting = false
--         if autoFireTimer then
--             timer.cancel(autoFireTimer)
--             autoFireTimer = nil
--         end
--     end
-- end

-- local function onTouch(event)
--     if event.phase == "began" then
--         startAutoFire()
--     elseif event.phase == "ended" or event.phase == "cancelled" then
--         stopAutoFire()
--     end
-- end

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
    gamePausedMusic()
    timer.pauseAll()
end

local function resumeGame()
    isPaused = false
    resumeMusic()
    timer.resumeAll()
end

-- Funktio, joka luo uuden ystävän
local function createFriend()
    local friend = display.newImageRect(camera, "assets/images/allyshrimp.png", 30, 30)
    friend.x = player.model.x
    friend.y = player.model.y

    friendList[#friendList +1] = friend
    return friend
end


-- Level-up-näkymä
local function showLevelUpScreen()
    pauseGame()

    local overlay = display.newRect(centerX, centerY, screenW, screenH)
    overlay:setFillColor(0, 0, 0, 0.8)

    local bubble = display.newImageRect("assets/images/uibubble5.png", 400, 400)  -- Muokkaa kokoa tarvittaessa
    bubble.x = centerX
    bubble.y = centerY
    bubble:toFront() 


    local title = display.newText("Level Up!", centerX, centerY - 100, native.systemFontBold, 32)
    title:setFillColor(0, 0, 0)

    local friendCount = 0  -- Track the number of friends
    local options = {
        { text = "+20 HP", action = 
            function() 
                player.hp = math.min(player.hp + 20, 100) 
            end },
        { text = "+1 Speed", action = 
            function() 
                player.moveSpeed = player.moveSpeed + 1
                updateMoveSpeedText()
            end },
        { text = "+5 Bullet Damage", action = 
            function() 
                player.bulletDamage = player.bulletDamage + 5
                updateBulletDamageText()
            end },
        { text = "+1 Friend", action = 
            function()
                createFriend()  -- Kutsu luontifunktiota
                updateFriendCountText()  -- Päivitä tekstin näyttö
            end
        }
    }

    friendCountText:toFront()
    crosshair:toFront()
    -- Shuffle options and pick 3 random ones
    local shuffledOptions = {}
    while #shuffledOptions < 3 and #options > 0 do
        local index = math.random(#options)
        table.insert(shuffledOptions, table.remove(options, index))
    end

    -- Create buttons for the options
    local buttons = {}
    for i, option in ipairs(shuffledOptions) do
        local button = display.newText(option.text, centerX, centerY + 40 * i, native.systemFont, 30)
        button:setFillColor(0, 0, 0)

        -- Button tap action
        button:addEventListener("tap", function()
            option.action()  -- Execute the selected option's action
            -- Remove level-up screen after selecting an option
            display.remove(overlay)
            display.remove(title)
            display.remove(bubble)
            for _, b in ipairs(buttons) do
                display.remove(b)
            end
            audio.play(FXfiles.perkChosen,{ channel = channels.explosion })
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

        if enemy.isBoss then
            speed = (speed * currentLevel) / 3
        end

        if distance > 0 then
            enemy.model.x = enemy.model.x + (dx / distance) * speed
            enemy.model.y = enemy.model.y + (dy / distance) * speed
        end

        -- Pelaajaan osuminen
        if distance < 60 + 15 then
            player.hp = player.hp - enemy.damage
            print("Pelaaja osui viholliseen! Pelaajan HP:", player.hp)
            updateHPDisplay()

            if enemy.isBoss then
                bosslLevels[currentLevel].isDead = true
            end
            audio.stop( channels.explosion )
            audio.play(FXfiles.playerHit,{ channel = channels.explosion })
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
                if enemy.isBoss then
                    print("Bossiin osui! HP:", enemy.hp)
                else
                    --print("Viholliseen osui! HP:", enemy.hp)
                end

                audio.stop( channels.explosion )
                if enemy.hp <= 0 then 
                    audio.play(FXfiles.enemyDie,{ channel = channels.explosion })
                else
                    audio.play(FXfiles.enemyDamage,{ channel = channels.explosion })
                end

                    if enemy.hp <= 0 then
                    if enemy.isBoss then
                        bosslLevels[currentLevel].isDead = true
                    end

                    enemyDown(enemy)
                    player.exp = player.exp + enemy.exp
                    print("Vihollinen kuoli! EXP:", player.exp)

                    -- Satunnainen todennäköisyys HP-paketin tiputukseen (esim. 30% mahdollisuus)
                    if math.random() < 0.3 then
                        spawnHpPack(enemy.model.x, enemy.model.y)  -- HP-paketti tiputetaan
                        print("HP-paketti tiputettu!")
                    end

                    if player.exp >= levelUpExpThreshold then
                        -- player.exp = 0
                        player.level = player.level + 1
                        audio.play(FXfiles.lvlUp,{ channel = channels.explosion })
                        print("Taso nousi! Nykyinen taso:", player.level)
                        updateLevelText()
                        showLevelUpScreen()
                        playerLevelUpMusic(player.level)
                        checkGunUpgrades()
                        increaselevelUpExpThreshold()
                        print("Level up threshold increased to:", levelUpExpThreshold)
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

local function moveFriendBullets()
    if isPaused then return end
    for i = #friendBullets, 1, -1 do
        local friendBullet = friendBullets[i]
        friendBullet.x = friendBullet.x + friendBullet.vx
        friendBullet.y = friendBullet.y + friendBullet.vy

        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            local dx = friendBullet.x - enemy.model.x
            local dy = friendBullet.y - enemy.model.y
            local distance = math.sqrt(dx^2 + dy^2)
            if distance < 40 + 5 then
                enemy.hp = enemy.hp - friendBullet.damage
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
                        -- player.exp = 0
                        player.level = player.level + 1
                        audio.play(FXfiles.lvlUp,{ channel = channels.explosion })
                        print("Taso nousi! Nykyinen taso:", player.level)
                        updateLevelText()
                        showLevelUpScreen()
                        playerLevelUpMusic(player.level)
                        checkGunUpgrades()
                        increaselevelUpExpThreshold()
                        print("Level up threshold increased to:", levelUpExpThreshold)
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

                display.remove(friendBullet)
                table.remove(friendBullets, i)
                break
            end
        end
    end
end

crosshair:toFront()

local function restartGame()
    player.hp = 100
    player.level = 1
    player.exp = 0
    for i = #enemies, 1, -1 do
        display.remove(enemies[i])
        table.remove(enemies, i)
    end

    for i = #friendList, 1, -1 do
        display.remove(friendList[i])
        table.remove(friendList, i)
    end

    if bosslLevels[currentLevel] ~= nil then
        if  bosslLevels[currentLevel].bossResource.timer then

            timer.cancel(bosslLevels[currentLevel].bossResource.timer)
            bosslLevels[currentLevel].bossResource.timer = nil
        end
    end
    
    Runtime:removeEventListener("enterFrame", gameLoop)
    Runtime:removeEventListener("key", onKeyEvent)
    Runtime:removeEventListener("touch", fireBullet)
    composer.removeScene("scenes.game")
    composer.gotoScene("scenes.game", { effect = "fade", time = 500 })
end


-- Näytä Game Over ruutu
local function showGameOverScreen()
    pauseGame()  -- Pause the game
    pauseMusic()

    audio.play(FXfiles.gameOver,{ channel = channels.explosion })
    audio.play(FXfiles.gameoverSlap,{ channel = channels.background })
    -- Create game over screen
    local overlay = display.newRect(centerX, centerY, screenW, screenH)
    overlay:setFillColor(0, 0, 0, 0.8)

    local title = display.newText("Game Over", centerX, centerY - 50, native.systemFontBold, 32)
    title:setFillColor(1, 0, 0)

    local restartButton = display.newText("Restart", centerX, centerY + 250, native.systemFont, 54)
    restartButton:setFillColor(1, 1, 0)

    restartButton:addEventListener("tap", restartGame)
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
    moveFriendBullets()
    checkPlayerHealth()  -- Tarkistetaan pelaajan terveys
    checkHpPackCollision()  -- Tarkistetaan pelaajan osuminen HP-packeihin
end

-- scene:show -tilassa alustetaan ja käynnistetään spawn- ja peli
function scene:show(event)
    local sceneGroup = self.view
    if event.phase == "did" then

        player.hp = 100
        player.level = 1
        player.exp = 0

        timer.performWithDelay(spawnDelay, spawnEnemies)
        Runtime:addEventListener("key", onKeyEvent)
        Runtime:addEventListener("touch", fireBullet)
        Runtime:addEventListener("mouse", onMouseEvent)
        Runtime:addEventListener("enterFrame", gameLoop)
    end
end


function scene:hide(event)
    local sceneGroup = self.view
    if event.phase == "will" then
        Runtime:removeEventListener("key", onKeyEvent)
        Runtime:removeEventListener("touch", fireBullet)
        Runtime:removeEventListener("mouse", onMouseEvent)
        Runtime:removeEventListener("enterFrame", gameLoop)
    end
end

scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene 
