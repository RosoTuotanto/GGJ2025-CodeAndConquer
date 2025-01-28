local composer = require("composer")
local scene = composer.newScene()
local camera = display.newGroup()

-- Luo pelikentän taustakuva 
local object = display.newImageRect("assets/images/waterground.png", 5500, 5500)
local mask = graphics.newMask("assets/images/mask.png")  -- Pelikenttä kuvan maski
object:setMask(mask)  -- Aseta maski tummennuskuvaan

object.x = display.contentCenterX
object.y = display.contentCenterY

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


local laser -- Laser-objekti

local function updateLaser(event)
    if isPaused then return end
    if not laser then
        -- Luo laser vain kerran
        laser = display.newLine(centerX, centerY, event.x, event.y)
        laser:setStrokeColor(1, 0, 0, 0.6) -- Punainen laser
        laser.strokeWidth = 3
    else
        -- Päivitä laserin alku- ja loppupisteet
        laser = display.newLine(centerX, centerY, event.x, event.y)
        laser:setStrokeColor(1, 0, 0, 0.6)
        laser.strokeWidth = 3
    end


    -- Laserin fade-animaatio ja poisto
    transition.to(laser, {
        alpha = 0,
        time = 50,
        onComplete = function()
            display.remove(laser)
        end
    })
end

local function onMouseMove(event)
    crosshair.x = event.x
    crosshair.y = event.y
    crosshair.isVisible = true

    if event.isPrimaryButtonDown and player.laser and not isPaused then
        updateLaser(event)
    end
end

Runtime:addEventListener("mouse", onMouseMove)


-- Pelin päämuuttujat
local friendList = {}
local activeTimers = {}
local isPaused = false

--------------------------------------------------
-- AUDIO & MUSIC ------
--------------------------------------------------
audio.setVolume( 1 )

local gunshotSounds = {
    gunlevel1 = audio.loadSound( "assets/audio/fx/guns/bubble_wand/bubble_wand_shoot.wav" ),
    gunlevel2 = audio.loadSound( "assets/audio/fx/guns/foam_sprayer/foam_sprayer_shoot.wav" ),
    gunlevel3 = audio.loadSound( "assets/audio/fx/guns/bubble_popper/bubble_popper_shoot.wav" ),
    gunlevel4 = audio.loadSound( "assets/audio/fx/guns/bubble_popper/bubble_popper_shoot.wav" ),
    gunlevel5 = audio.loadSound( "assets/audio/fx/guns/bubble_popper/bubble_popper_shoot.wav" ),
    gunlevel6 = audio.loadSound( "assets/audio/fx/guns/bubble_popper/bubble_popper_shoot.wav" ),
    gunlevel7 = audio.loadSound( "assets/audio/fx/guns/bubble_popper/bubble_popper_shoot.wav" )
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
    },
    journey_ahead = {
        easy = {
            drums = audio.loadStream("assets/audio/journey_ahead/journey_ahead_drums_easy.mp3"),
            melody = audio.loadStream("assets/audio/journey_ahead/journey_ahead_melody_easy.mp3")
        },
        medium = {
            drums = audio.loadStream("assets/audio/journey_ahead/journey_ahead_drums_medium.mp3"),
            melody = audio.loadStream("assets/audio/journey_ahead/journey_ahead_melody_medium.mp3")
        },
        hard = {
            drums = audio.loadStream("assets/audio/journey_ahead/journey_ahead_drums_hard.mp3"),
            melody = audio.loadStream("assets/audio/journey_ahead/journey_ahead_melody_hard.mp3")
        }
    }
}

local music = musicFiles.journey_ahead.easy
local intensityLvl = "easy"
local audioboost = false

local function playMusic()
    audio.stop(channels.music_drums)
    audio.stop(channels.music_melody)
    if audioboost then
        audio.setVolume( 0.77, { channel = channels.music_drums } )
        audio.setVolume( 0.77, {  channel = channels.music_melody} )
    else
        audio.setVolume( 0.56, { channel = channels.music_drums } )
        audio.setVolume( 0.56, {  channel = channels.music_melody} )
    end
    
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
local waves = 1
local intensityLvl = "easy"
local currentSong = musicFiles.journey_ahead
local lastIntensity = "easy"

local function getIntensityByLevel(level)
    if lastIntensity == "hard" then
        return "hard"
    elseif lastIntensity == "medium" then
        lastIntensity = "hard"
        return "hard"
    elseif lastIntensity == "easy" and level > 3 then
        lastIntensity = "medium"
        return "medium"
    end

    lastIntensity = "easy"
    return "easy"
end

local function getSongByLevel(level, currentLevel)
    if level >= 10 and currentLevel >= 9 then
        print("Changing song to WRATH UNLEASHED")
        audioboost = true
        -- taustakuvan säätöä
        object:setFillColor(1,0.3,0.3,1);
        return musicFiles.wrath_unleashed
    elseif level >= 3 and currentLevel > 5 then
        print("Changing song to RISING THREAT")
        audioboost = true
        -- taustakuvan säätöä
        object:setFillColor(1,0.6,0.6,1);
        return musicFiles.rising_threat
    else
        print("Changing song to JOURNEY AHEAD")
        return musicFiles.journey_ahead
    end
end

function updateMusicIntensity()
    local newSong = getSongByLevel(player.level, currentLevel)

    if currentSong ~= newSong then
        currentSong = newSong
        intensityLvl = "easy" 
        lastIntensity = intensityLvl
        print("New song loaded, resetting intensity to easy")
    end

    music = currentSong[intensityLvl]
    print("Playing music:", currentSong, "Intensity:", intensityLvl)
    playMusic()
end

local function playerLevelUpMusic(playerLevel)
    local newIntensity = getIntensityByLevel(playerLevel)

    if newIntensity ~= intensityLvl then
        intensityLvl = newIntensity
        print("Intensity CHANGED to", intensityLvl)
        updateMusicIntensity()
    end
    updateMusicIntensity()
end

local function onPlayerLevelUp(newLevel)
    print("Player leveled up to:", newLevel)
    playerLevelUpMusic(newLevel)
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
    autofire = false,
    laser = false
}

local background = display.newImageRect( "/assets/images/uibubble2.png", 1850, 150)
background.x = 960
background.y = 100

local moveSpeedText= display.newText({
    text = "Speed:" .. player.moveSpeed,
    x = 960,
    y = 100,
    font =  native.systemFont,
    fontSize = 56,
})
local function updateMoveSpeedText()
    moveSpeedText.text = "Speed:" .. player.moveSpeed
end

moveSpeedText:setFillColor(0, 0, 0)

local bulletDamageText= display.newText({
    text = "Damage:" .. player.bulletDamage,
    x = 480,
    y = 100,
    font =  native.systemFont,
    fontSize = 56,
})
local function updateBulletDamageText()
    bulletDamageText.text = "Damage:" .. player.bulletDamage
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

local gunImages = {
    "/assets/images/gun.png",
    "/assets/images/gun2.png",
    "/assets/images/gun3.png"
}

local gunDisplay = nil
local currentGunTransition = nil
local currentGunImgLevel = 1


local function createGunDisplay()
    local gunLevel = math.min(player.gunlevel, #gunImages)
    local gunImagePath = gunImages[gunLevel]
    currentGunImgLevel = player.gunlevel
    
    gunDisplay = display.newImageRect(gunImagePath, 250, 250) 
    gunDisplay.rotation = -25
    gunDisplay.x = screenW - 250
    gunDisplay.y = screenH - 175
    gunDisplay.xScale = 0.001
    gunDisplay.yScale = 0.001

    local tempImage = display.newImage(gunImagePath)
    local imageWidth = tempImage.contentWidth
    local imageHeight = tempImage.contentHeight
    tempImage:removeSelf()

    local desiredHeight = 220
    local scaleFactor = desiredHeight / imageHeight
    gunDisplay.height = desiredHeight
    gunDisplay.width = imageWidth * scaleFactor

            
    -- Ylös-alas liike animaatio
    local function rotateCycle(gunmodel)
        if gunmodel == nil then return end
        currentGunTransition = transition.to(gunmodel, {
            rotation = gunmodel.rotation + 50,
            time = 1000,
            transition = easing.inOutQuad,
            onComplete = function()
                -- Kun siirtyminen ylöspäin on valmis, aloita siirtyminen alas
                currentGunTransition = transition.to(gunmodel, {
                    rotation = gunmodel.rotation - 50,
                    time = 1000,
                    transition = easing.inOutQuad
                    , onComplete = function()
                        rotateCycle(gunmodel)
                    end
                })
            end
        })
    end

    transition.to(gunDisplay, {
        xScale = 1,
        yScale = 1,
        time = 500,
        transition = easing.inOutQuad,
        onComplete = function()
            rotateCycle(gunDisplay)
        end
        })


end

local function updateGunDisplay()
    -- local tempRotation = -25

    if gunDisplay then
        if currentGunTransition then
            if currentGunImgLevel == player.gunlevel then return end
            transition.cancel(currentGunTransition)
            transition.to(gunDisplay, {
                xScale = 0,
                yScale = 0,
                time = 500,
                transition = easing.inOutQuad,
                onComplete = function()
                    currentGunTransition = nil
                    -- tempRotation = gunDisplay.rotation
                    display.remove(gunDisplay)
                    gunDisplay = nil
                    createGunDisplay()
                end
                })
                    
        end
    else
        createGunDisplay()
    end
end

updateGunDisplay()

-- Kokemuspisteiden raja seuraavaa tasoa varten
local levelUpExpThreshold = 50 -- EXP tarvitaan level-upiin


local levelConfigs = {
    { level = 1, maxEnemies = 10   , minEnemies = 5    , experienceThreshold =  10    },
    { level = 2, maxEnemies = 100  , minEnemies = 20   , experienceThreshold =  100    },
    { level = 3, maxEnemies = 300  , minEnemies = 50  , experienceThreshold =  100    },
    { level = 4, maxEnemies = 300  , minEnemies = 50  , experienceThreshold =  500   },
    { level = 5, maxEnemies = 300  , minEnemies = 100 , experienceThreshold =  1000  },
    { level = 6, maxEnemies = 300  , minEnemies = 100 , experienceThreshold =  5000  },
    { level = 7, maxEnemies = 400  , minEnemies = 100 , experienceThreshold =  10000  },
    { level = 8, maxEnemies = 500  , minEnemies = 100 , experienceThreshold =  10000  },
    { level = 9, maxEnemies = 500  , minEnemies = 100 , experienceThreshold =  20000  },
    { level = 10, maxEnemies = 600 , minEnemies = 100 , experienceThreshold =  30000  },
    { level = 11, maxEnemies = 600 , minEnemies = 100 , experienceThreshold =  40000  },
    { level = 12, maxEnemies = 700 , minEnemies = 100 , experienceThreshold =  50000  },
    { level = 13, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  60000  },
    { level = 14, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  70000  },
    { level = 15, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  80000  },
    { level = 16, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  90000  },
    { level = 17, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  99000  },
    { level = 18, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  99999  },
    { level = 19, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  99999  },
    { level = 20, maxEnemies = 999 , minEnemies = 100 , experienceThreshold =  99999  }
}

local function increaselevelUpExpThreshold() 
 
    -- levelUpExpThreshold = (levelUpExpThreshold * ((player.level / 2) % 9)) * 1.1
    for _, config in ipairs(levelConfigs) do
        if config.level == player.level then
            levelUpExpThreshold = levelUpExpThreshold + math.min( math.max(((levelUpExpThreshold * (player.level / 2)) * 1.1), config.experienceThreshold), config.experienceThreshold)
            return
        end
    end
    -- Palautetaan oletusarvo, jos tasoa ei löydy listasta
    levelUpExpThreshold = levelUpExpThreshold + math.min( (levelUpExpThreshold * 1.1), 9999)

    -- if levelUpExpThreshold is less than 0 then set it to 9999
    levelUpExpThreshold = math.max(9999, levelUpExpThreshold)
end

local function checkGunUpgrades()
    
    if  player.bulletDamage >= 70 then   
        gunshotSound = gunshotSounds.gunlevel6
        player.bulletSpeed = 100
        player.gunlevel = 7
        player.autofire = true
        player.laser = true

    elseif  player.bulletDamage >= 70 then   
        gunshotSound = gunshotSounds.gunlevel6
        player.bulletSpeed = 70/1
        player.gunlevel = 6
        player.autofire = true
        player.laser = true

    elseif player.bulletDamage >= 60 then
        gunshotSound = gunshotSounds.gunlevel5
        player.bulletSpeed = 70/2
        player.gunlevel = 5
        player.autofire = true
        player.laser = true

    elseif player.bulletDamage >= 50 then
        gunshotSound = gunshotSounds.gunlevel4
        player.bulletSpeed = 70/3
        player.gunlevel = 4
        player.autofire = true
        player.laser = true

    elseif player.bulletDamage >= 40 then
        gunshotSound = gunshotSounds.gunlevel3
        player.bulletSpeed = 70/4
        player.gunlevel = 3
        player.autofire = true
        player.laser = true

    elseif player.bulletDamage >= 20 then
        gunshotSound = gunshotSounds.gunlevel2
        player.bulletSpeed = 70/5
        player.gunlevel = 2
        player.autofire = false
        player.laser = true

    elseif player.bulletDamage >= 15 then
        gunshotSound = gunshotSounds.gunlevel1
        player.bulletSpeed = 70/6
        player.gunlevel = 1
        player.autofire = false

    else
        gunshotSound = gunshotSounds.gunlevel1

    end
    

    updateGunDisplay()

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

local function getLevelMaxEnemies(level)
    for _, config in ipairs(levelConfigs) do
        if config.level == level then
            return math.min(math.max(((currentLevel * enemiesPerLevel) * 1.1), config.minEnemies), config.maxEnemies)
        end
    end
    -- Palautetaan oletusarvo, jos tasoa ei löydy listasta
    return 100
end

local bosslLevels = { 
    [5] = {
        bossName = "Piranha",
        bossResource = nil,
        bossPicture1 = "assets/images/piranha.png",
        bossPicture2 = "assets/images/piranha2.png",
        isSpawned = false,
        isDead = false,
        hp = 2003,
        damage = 10,
        exp = 500,
        speedMultiplier = 1.5,
    },
    [8] = {
        bossName = "Seahorse",
        bossResource = nil,
        bossPicture1 = "assets/images/seahorse.png",
        bossPicture2 = "assets/images/seahorse2.png",
        isSpawned = false,
        isDead = false,
        hp = 5000,
        damage = 20,
        exp = 1700,
        speedMultiplier = 2
    },
    [10] = {
        bossName = "Swordfish",
        bossResource = nil,
        bossPicture1 = "assets/images/swordfish.png",
        bossPicture2 = "assets/images/swordfish2.png",
        isSpawned = false,
        isDead = false,
        hp = 15500,
        damage = 50,
        exp = 9000,
        speedMultiplier = 2
    },
    [15] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 25000,
        damage = 70,
        exp = 19500,
        speedMultiplier = 2
    },
    [17] = {
        bossName = "Hammerhead",
        bossResource = nil,
        bossPicture1 = "assets/images/hammerhead.png",
        bossPicture2 = "assets/images/hammerhead2.png",
        isSpawned = false,
        isDead = false,
        hp = 33300,
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
        hp = 67770,
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
        hp = 400888,
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
        hp = 9999999,
        damage = 50,
        exp = 100000000000,
        speedMultiplier = 2
    }

}

-- Vihollisten varianttitiedot
local enemyVariants = {
    { "assets/images/slime1.png", "assets/images/slime2.png" },
    { "assets/images/slime3.png", "assets/images/slime4.png" },
    { "assets/images/slime5.png", "assets/images/slime6.png" }
}

local function enemyDown()

    -- ei voida edistää peliä jos bossi on olemassa
    if bosslLevels[currentLevel] ~= nil and
        bosslLevels[currentLevel].isSpawned == true and
        bosslLevels[currentLevel].isDead == false
        then
        return
    end

    enemiesDown = enemiesDown + 1

    if enemiesDown >= enemiesPerLevel then

        currentLevel = currentLevel + 1
        onPlayerLevelUp(player.level)
        -- seuraava laskenta käytännössä aina 10%  lisää edellisen tason verran
        enemiesPerLevel = enemiesPerLevel + getLevelMaxEnemies(currentLevel)
        
        -- enemiesPerLevel = enemiesPerLevel  * currentLevel * maxEnemiesPerSpawn
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
    boss.knockbackLeft = {x = 0, y = 0}

    print("bossPicture1: " .. bosslLevels[currentLevel].bossPicture1)
    bosslLevels[currentLevel].isSpawned = true

    bosslLevels[currentLevel].bossResource = boss

    table.insert(enemies, boss)

    local frame = 1
    local function animateBoss()
        -- print("animateBoss(): animoidaan bossi")
        if bosslLevels[currentLevel] == nil then
            removeBoss(boss)
            return
        end

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


        if bosslLevels[currentLevel].bossResource.timer then
            timer.cancel(bosslLevels[currentLevel].bossResource.timer)
        end    
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
-- Vihollisten varianttitiedot (parit)
local enemyVariants = {
    { base = "assets/images/slime1.png", animation = "assets/images/slime2.png" },
    { base = "assets/images/slime3.png", animation = "assets/images/slime4.png" },
    { base = "assets/images/slime5.png", animation = "assets/images/slime6.png" }
}

-- Vihollisen luonti
local function spawnEnemy()
    local stats = calculateEnemyStats()

    -- Valitse satunnainen variantti
    local variantIndex = math.random(1, #enemyVariants)

    -- vihollisen koko on suoraanverrannollinen exp saantiin
    local exp = math.random(5, 10) + (math.pow(player.level - 1,math.random(1, 3))) * 1.15
    local enemysize = (exp%100)+30

    if exp < 50 then
        enemysize = 50

        if exp < 10 then
            exp = 10
        end
    end

    local enemy = {
        model = display.newImageRect(camera, enemyVariants[variantIndex].base, enemysize, enemysize), -- Käytä variantin ensimmäistä kuvaa
        hp = stats.hp,
        damage = stats.damage,
        exp = exp, --math.random(5, 10) + (player.level - 1) * 1.15, -- EXP kasvaa tason mukana
        isBoss = false,
        variant = variantIndex, -- Tallenna viittaus varianttiin
        animationFrame = 1, -- Alkuanimaatiokehys
        knockbackLeft = { x = 0, y = 0 } -- Knockback-vektoria jäljellä
    }

    -- Aseta vihollisen sijainti (satunnainen reuna)
    local spawnPosition = math.random(4)
    if spawnPosition == 1 then
        enemy.model.x = math.random(20, screenW - 20)
        enemy.model.y = -20
    elseif spawnPosition == 2 then
        enemy.model.x = math.random(20, screenW - 20)
        enemy.model.y = screenH + 20
    elseif spawnPosition == 3 then
        enemy.model.x = -20
        enemy.model.y = math.random(20, screenH - 20)
    elseif spawnPosition == 4 then
        enemy.model.x = screenW + 20
        enemy.model.y = math.random(20, screenH - 20)
    end

    -- Ylös-alas liike animaatio
    local function rotateCycle(enemymodel)
        if enemymodel == nil then return end
        -- Liiku ylös
        transition.to(enemymodel.model, {
            rotation = enemymodel.model.rotation - 15,
            time = 500,
            transition = easing.continuousLoop,
            onComplete = function()
                -- Kun siirtyminen ylöspäin on valmis, aloita siirtyminen alas
                transition.to(enemymodel.model, {
                    rotation = enemymodel.model.rotation + 15,
                    time = 500,
                    transition = easing.continuousLoop
                    , onComplete = function()
                        rotateCycle(enemymodel)
                    end
                })
            end
        })
    end

    -- Käynnistä ylös-alas liike
    rotateCycle(enemy)

    -- Lisää vihollinen listaan
    table.insert(enemies, enemy)
end



-- Vihollisten liikuttaminen ja animointi
local function moveEnemies()
    if isPaused then return end
    local playerX, playerY = player.model.x, player.model.y
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local dx = playerX - enemy.model.x -- siirtymä x vektorilla
        local dy = playerY - enemy.model.y -- siirtymä y vektorilla
        local distanceSquared = dx^2 + dy^2
        local collisionDistanceSquared = (60 + 15)^2 -- Törmäysetäisyys
        local isKnockedBack = false
    
        local speed = 2
        if enemy.isBoss then
            speed = (speed * currentLevel) / 3
        end
    
        if enemy.knockbackLeft and (enemy.knockbackLeft.x ~= 0 or enemy.knockbackLeft.y ~= 0) then
            local knockbackMagnitude = 10 -- Knockback-etäisyys
            local knockbackDx = enemy.knockbackLeft.x
            local knockbackDy = enemy.knockbackLeft.y
            local knockbackDistance = math.sqrt(knockbackDx^2 + knockbackDy^2)
    
            if knockbackDistance > 0 then
                enemy.model.x = enemy.model.x - (knockbackDx / knockbackDistance) * knockbackMagnitude
                enemy.model.y = enemy.model.y - (knockbackDy / knockbackDistance) * knockbackMagnitude
                isKnockedBack = true
            end
            enemy.knockbackLeft.x = 0
            enemy.knockbackLeft.y = 0
        else
            -- Vihollinen seuraa pelaajaa, jos knockback ei ole aktiivinen
            if distanceSquared > 0 then
                local distance = math.sqrt(distanceSquared)
                enemy.model.x = enemy.model.x + (dx / distance) * speed
                enemy.model.y = enemy.model.y + (dy / distance) * speed
            end
        end

        -- Törmäystarkistus pelaajan kanssa
        if distanceSquared < collisionDistanceSquared then
            player.hp = player.hp - enemy.damage
            print("Pelaaja osui viholliseen! Pelaajan HP:", player.hp)
            updateHPDisplay()

            if enemy.isBoss then
                bosslLevels[currentLevel].isDead = true
            end
            audio.stop(channels.explosion)
            audio.play(FXfiles.playerHit, { channel = channels.explosion })
            display.remove(enemy.model)
            table.remove(enemies, i)
        end
    end
end

-- Animaation päivitys ajastimella
local function updateEnemyAnimations()
    if isPaused then return end
    for _, enemy in ipairs(enemies) do
        if enemy.isBoss then return end

        local variant = enemyVariants[enemy.variant]
        if enemy.animationFrame == 1 then
            enemy.model.fill = { type = "image", filename = variant.animation }
            enemy.animationFrame = 2
        else
            enemy.model.fill = { type = "image", filename = variant.base }
            enemy.animationFrame = 1
        end
    end
end


-- Vihollisten spawn-loop
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
    -- kaksi kuvaa päällekkäin
    local hpPack1 = display.newImageRect(camera, "/assets/images/healthpack.png", 50, 50)
    hpPack1.x = x
    hpPack1.y = y
    hpPack1:setFillColor(0.7, 0.7, 0.7)  -- Vähentää väriarvojen kirkkautta (70% alkuperäisestä)

    -- Toinen kuva, joka tulee fadeamaan
    local hpPack2 = display.newImageRect(camera, "/assets/images/healthpack2.png", 50, 50)
    hpPack2.x = x
    hpPack2.y = y
    hpPack2.alpha = 0  -- Aluksi piilotetaan tämä kuva (alpha 0)

    
    -- Lisää HP-paketit listaan
    table.insert(hpPacks, {hpPack1, hpPack2})

    -- Animaatio: Fade HP-pack2 kuvaa
    local function fadeHpPack()
        if hpPack2.removeSelf == nil then
            -- Jos HP-paketti on jo poistettu, lopeta animaatio
            return
        end

        -- Fade-in animaatio (hpPack2)
        transition.to(hpPack2, {
            alpha = 1,  -- Tekee hpPack2 näkyväksi
            time = 500,  -- Fade-in kesto
            onComplete = function()
                -- Fade-out animaatio heti fade-in jälkeen
                transition.to(hpPack2, {
                    alpha = 0.4,  -- Tekee hpPack2 piiloon
                    time = 500,  -- Fade-out kesto
                    onComplete = fadeHpPack  -- Käynnistä animaatio uudelleen
                })
            end
        })
    end

    -- Käynnistä animaatio
    fadeHpPack()
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
        local hpPack = hpPacks[i][1]
        local hpPack2 = hpPacks[i][2]
        local dx = player.model.x - hpPack.x
        local dy = player.model.y - hpPack.y
        local distance = math.sqrt(dx^2 + dy^2)

        if distance < 60 + 10 then
            player.hp = math.min(player.hp + 20, 100)
            print("Pelaajan HP:", player.hp)
            audio.stop( channels.pickup )
            audio.play( FXfiles.healthPickup, { channel = channels.pickup, loops = 0, fadein = 0, fadeout = 0 } )
                     
            display.remove(hpPack)

            -- Skew-efekti ja venytys HP-kuvalle 2
            transition.to(hpPack2, {
                xScale = 1.5,    -- Venyttää hieman x-suunnassa
                yScale = 1.5,   -- Litistää y-suunnassa olemattomiin
                alpha = 1,
                time = 100,
                transition = easing.inOutQuad,
                onComplete = function()
                    transition.to(hpPack2, {
                        xScale = 1.5,    -- Venyttää hieman x-suunnassa
                        yScale = 0.01,   -- Litistää y-suunnassa olemattomiin
                        alpha = 0,
                        time = 300,
                        transition = easing.inOutQuad,
                        onComplete = function()
                            -- Poista molemmat kuvat ja päivitä lista
                            display.remove(hpPack2)
                        end
                    })
                end
            })
            
            table.remove(hpPacks, i)
            updateHPDisplay()
        end
    end
end



-- AUTOFIRE MEKANIIKKA

local isShooting = false
local autoFireTimer = nil
local bulletCreationOnGoing = false

local function createBullet()
    if isPaused then return end
        bulletCreationOnGoing = true
        local shooter = {player.model}
        audio.stop(channels.gunshot)
        audio.play(gunshotSound, { channel = channels.gunshot, loops = 0, fadein = 0, fadeout = 0 });
        

        if #friendList > 0 then
            for i=1, #friendList do
                table.insert(shooter,friendList[i])
            end
        end

        for i=1, #shooter do
            local bubblelvl = math.min(6,player.gunlevel) -- maximum level of pics :(
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
    bulletCreationOnGoing = false
end

local function startAutoFire()
    createBullet()
    if not isShooting then
        isShooting = true
        autoFireTimer = timer.performWithDelay(150 / player.gunlevel * 2, createBullet, 0) -- Ammu 200 ms välein
    end
end

local function stopAutoFire()
    if isShooting then
        isShooting = false
        if autoFireTimer then
            timer.cancel(autoFireTimer)
            autoFireTimer = nil
        end
    end
end

-- Pelaajan ampuminen
local function fireBullet(event)
    
    if player.autofire then
        if event.phase == "began" then
            startAutoFire(event)
        elseif event.phase == "ended" or event.phase == "cancelled" then
            stopAutoFire()
        end
        return
    end

    if event.phase == "began" then
        createBullet(event)
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

-- Pelin tauottaminen ja jatkaminen
local function pauseGame()
    for _, t in ipairs(activeTimers) do
        if t and timer.resume(t) ~= nil then
            timer.pause(t)
        end
    end
    isPaused = true
    gamePausedMusic()
    -- timer.pauseAll()
end

local function resumeGame()
    for _, t in ipairs(activeTimers) do
        timer.resume(t)
    end
    isPaused = false
    resumeMusic()
    -- timer.resumeAll()
end


-- Variables to hold pause overlay elements
local overlay, bubble, title


local removeEventListeners = function()
    Runtime:removeEventListener("touch", fireBullet)
end

local addEventListeners = function()
    Runtime:addEventListener("touch", fireBullet)
end

-- Function to toggle pause
local function togglePause()
    
    if not isPaused then
        -- Pausing the game
        pauseGame()
        
        -- Check if overlay and other elements exist; create only if they don't
        if not overlay then
            overlay = display.newRect(centerX, centerY, screenW, screenH)
            overlay:setFillColor(0, 0, 0, 0.8)
        end
        
        if not bubble then
            bubble = display.newImageRect("assets/images/uibubble5.png", 400, 400)
            bubble.x = centerX
            bubble.y = centerY
            bubble:toFront()
        end
        
        if not title then
            title = display.newText("Pause.", centerX, centerY, native.systemFontBold, 32)
            title:setFillColor(0, 0, 0)
        end

        removeEventListeners()
    else
        -- Unpausing the game
        if overlay then
            display.remove(overlay)
            overlay = nil
        end
        
        if bubble then
            display.remove(bubble)
            bubble = nil
        end
        
        if title then
            display.remove(title)
            title = nil
        end
                
        addEventListeners()
        audio.play(FXfiles.perkChosen, { channel = channels.explosion })
        resumeGame()
    end
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

    -- pelin pysäyttäminen hetkellisesti
    if key == "p" and event.phase == "down"  or  event.keyName == "escape"  and event.phase == "down" then --esc
        togglePause()
        return true
    else

        -- Tarkista spacebar boostille
        if key == "space" and event.phase == "down" and not player.isBoosting then
            activateSpeedBoost()
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

    camera.y = (player.yStart - player.model.y)
    camera.x = (player.xStart - player.model.x)

    -- Päivitä laser
    if laser then
        -- Laske hiiren osoittimen ja pelaajan välinen ero
        local mouseX, mouseY = laser._endX, laser._endY -- Laserin loppukoordinaatit
        if mouseX and mouseY then
            laser = display.newLine(centerX, centerY, mouseX, mouseY)
            laser:setStrokeColor(1, 0, 0, 0.6) -- Punainen laser
            laser.strokeWidth = 3
                        -- Laserin fade-animaatio ja poisto
            transition.to(laser, {
                alpha = 0,
                time = 50,
                onComplete = function()
                    display.remove(laser)
                end
            })
        end
    end
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
            transition.to(button, { 
                time = 500, 
                xScale = 3,    -- Venyttää hieman x-suunnassa
                yScale = 3,   -- Litistää y-suunnassa olemattomiin
                alpha = 0, onComplete = function()
                    display.remove(button) 
                end 
            })

            option.action()  -- Execute the selected option's action
            -- Remove level-up screen after selecting an option
            display.remove(overlay)
            display.remove(title)
            display.remove(bubble)
            for _, b in ipairs(buttons) do
                if b ~= button then display.remove(b) end
            end
            audio.play(FXfiles.perkChosen,{ channel = channels.explosion })
            
            checkGunUpgrades()
            resumeGame()  -- Resume the game
        end)
        table.insert(buttons, button)
    end

    -- Adjust spawn settings after level-up
    spawnDelay = math.max(1000, spawnDelay - 500)  -- Decrease spawn delay, but no less than 1 second
    maxEnemiesPerSpawn = math.min(5, maxEnemiesPerSpawn + 1)  -- Increase the number of enemies spawned, but no more than 5
end

local function moveAndCheckBullets(bulletTable)
    if isPaused then return end

    local screenWidth = display.contentWidth
    local screenHeight = display.contentHeight
    local buffer = 2000 -- Jätetään pieni varmuusalue ruudun ulkopuolelle

    for i = #bulletTable, 1, -1 do
        local bullet = bulletTable[i]
        bullet.x = bullet.x + bullet.vx
        bullet.y = bullet.y + bullet.vy

        -- Tarkista, onko luoti poistunut ruudulta
        if bullet.x < -buffer or bullet.x > screenWidth + buffer or 
           bullet.y < -buffer or bullet.y > screenHeight + buffer then
            display.remove(bullet)
            table.remove(bulletTable, i)
        else
            -- Tarkista törmäykset vihollisten kanssa
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                local dx = bullet.x - enemy.model.x
                local dy = bullet.y - enemy.model.y
                local distanceSquared = dx^2 + dy^2 -- Optimointi: Vältetään sqrt()
                local collisionDistance = (40 + 5)^2 -- Suorakulmaisen alueen neliö

                if distanceSquared < collisionDistance then
                    -- Osuma havaittu
                    enemies[j].knockbackLeft = { x = -bullet.vx * 50, y = -bullet.vy * 50 }
                    
                    enemy.hp = enemy.hp - bullet.damage

                    if enemy.isBoss then
                        print("Bossiin osui! HP:", enemy.hp)
                    end

                    if enemy.hp <= 0 then
                        audio.play(FXfiles.enemyDie,{ channel = channels.explosion })

                        if enemy.isBoss then
                            bosslLevels[currentLevel].isDead = true
                        end

                        enemyDown()        
                                    
                        -- Satunnainen todennäköisyys HP-paketin tiputukseen (esim. 3015% mahdollisuus)
                        if math.random() < 0.15 then
                            spawnHpPack(enemy.model.x, enemy.model.y)  -- HP-paketti tiputetaan
                            print("HP-paketti tiputettu!")
                        end

                        print("vihollisen antama exp: ", enemy.exp)

                        -- Vihollinen kuoli, käsittele EXP ja palkkiot
                        player.exp = player.exp + enemy.exp

                        print("pelaajan taso: ",player.level)
                        print("pelin taso: ",currentLevel)

                        print("seuraavaan pelaajan leveliin tarvittava exp: ", (levelUpExpThreshold - player.exp))
                        
                        print("seuraavaan pelin leveliin tarvittava killcount: ", (enemiesPerLevel - enemiesDown))



                        if player.exp >= levelUpExpThreshold then
                            player.level = player.level + 1
                            audio.play(FXfiles.lvlUp, { channel = channels.explosion })
                            print("Pelaajan taso nousi! Nykyinen taso:", player.level)
                            updateLevelText()
                            showLevelUpScreen()
                            onPlayerLevelUp(player.level)
                            increaselevelUpExpThreshold()
                        end

                        -- Lisää splatter-animaatio
                        local splatter = display.newImageRect(camera, "assets/images/splatter.png", 80, 80)
                        splatter.x = enemy.model.x
                        splatter.y = enemy.model.y
                        transition.to(splatter, { alpha = 0, time = 5000, onComplete = function() display.remove(splatter) end })

                        display.remove(enemy.model)
                        table.remove(enemies, j)
                    else
                        audio.play(FXfiles.enemyDamage,{ channel = channels.explosion })
                    end

                    display.remove(bullet)
                    table.remove(bulletTable, i)
                    break
                end
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
        for _, t in ipairs(activeTimers) do
        if t and timer.resume(t) ~= nil then
            timer.pause(t)
        end
        activeTimers = {}
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

local function moveBullets()
    moveAndCheckBullets(bullets) 
    moveAndCheckBullets(friendBullets)
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

        player.hp = 100
        player.level = 1
        player.exp = 0
        currentLevel = 1
        levelUpExpThreshold = 50

        -- Ajastin animaation päivitykseen
        local animationTimer = timer.performWithDelay(animationInterval, animatePlayer, 0)                    
        table.insert(activeTimers, animationTimer)

        -- Ajastettu animaatio (toistuva tapahtuma)
        local enemyAnimationTimer = timer.performWithDelay(400, updateEnemyAnimations, 0)                  
        table.insert(activeTimers, enemyAnimationTimer)

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

-- Ajastettu vihollisten spawn
-- local spawnTimer = timer.performWithDelay(spawnDelay, spawnEnemies, 0)                  
-- table.insert(activeTimers, spawnTimer)

-- Ajastin animaation päivitykseen
-- local animationTimer = timer.performWithDelay(animationInterval, animatePlayer, 0)                    
-- table.insert(activeTimers, animationTimer)

-- -- Ajastettu animaatio (toistuva tapahtuma)
-- local enemyAnimationTimer = timer.performWithDelay(400, updateEnemyAnimations, 0)                  
-- table.insert(activeTimers, enemyAnimationTimer)



scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene 
