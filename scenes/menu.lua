-- Päämoduuli Solar2D:lle
local composer = require("composer")

-- Luo uuden kohtauksen valikolle
local scene = composer.newScene()

-- Funktio, joka luodaan kohtauksen piirtämistä varten
function scene:create(event)
    local sceneGroup = self.view -- Käytä tätä ryhmää lisätäksesi näyttöobjekteja

    -- Taustakuva
    local background = display.newImageRect(sceneGroup, "assets/images/menu.png", display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    -- Funktio painikkeiden tapahtumille
    local function onButtonPress(event)
        if event.target.id == "start" then
            print("Aloita peli!")
            composer.gotoScene("scenes.game") -- Siirrytään pelikohtaukseen
        elseif event.target.id == "exit" then
            print("Poistutaan pelistä!")
            native.requestExit() -- Sulkee sovelluksen
        end
    end

    -- Luo painikkeet
    local startButton = display.newImageRect(sceneGroup, "assets/images/playbutton.png", 800, 150)
    startButton.x = display.contentCenterX
    startButton.y = 500
    startButton.id = "start"
    startButton:addEventListener("tap", onButtonPress)

    local exitButton = display.newImageRect(sceneGroup, "assets/images/exitbutton.png", 800, 150)
    exitButton.x = display.contentCenterX
    exitButton.y = 800
    exitButton.id = "exit"
    exitButton:addEventListener("tap", onButtonPress)
end

-- Lisää tapahtumat kohtaukseen
scene:addEventListener("create", scene)

-- Palauta kohtaus
return scene
