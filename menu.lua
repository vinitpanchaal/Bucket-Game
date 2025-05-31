local composer = require("composer")
local scene = composer.newScene()

_G.gameSettings = {
    highScore = 0
}

local highScoreText

function scene:create(event)
    local sceneGroup = self.view
    local background = display.newImageRect(sceneGroup, "background.jpg", display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    local title = display.newText(sceneGroup, "Ryuk Apple Game", display.contentCenterX, 60, native.systemFontBold, 28)

    highScoreText = display.newText(sceneGroup, "High Score: " .. _G.gameSettings.highScore,
        display.contentCenterX, 110, native.systemFontBold, 20)

    local playBtn = display.newText(sceneGroup, "▶ Play", display.contentCenterX, 180, native.systemFontBold, 28)
    playBtn:setFillColor(0, 1, 0)
    playBtn:addEventListener("tap", function()
        composer.removeScene("game")
        composer.gotoScene("game")
    end)
end

function scene:show(event)
    if event.phase == "did" and highScoreText then
        highScoreText.text = "High Score: " .. _G.gameSettings.highScore
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
return scene
