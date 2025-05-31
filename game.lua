local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")

local score = 0
local lives = 3
local scoreText
local heartIcons = {}
local moveBucket
local onCollision
local ballTimer
local pauseOverlay
local bucket
local gameOver

function scene:create(event)
    local sceneGroup = self.view
    physics.start()
    physics.setGravity(0, 9.8)

    local screenW = display.contentWidth
    local screenH = display.contentHeight

    display.setStatusBar(display.HiddenStatusBar)

    -- 🎨 Background (optional)
    local background = display.newImageRect(sceneGroup, "background.jpg", screenW, screenH)
    background.x = screenW * 0.5
    background.y = screenH * 0.5

    -- 🏆 Score
    score = 0
    lives = 3
    scoreText = display.newText(sceneGroup, "Score: " .. score, screenW * 0.5, 30, native.systemFontBold, 24)

    -- ❤️ Heart Icons
    local heartSpacing = 40
    for i = 1, 3 do
        local heart = display.newImageRect(sceneGroup, "heart-bg.png", 28, 28)
        heart.x = screenW - 20 - (i - 1) * heartSpacing
        heart.y = 30
        table.insert(heartIcons, heart)
    end

    -- 🪣 Bucket
    local bucketWidth = 120
    local bucketHeight = 72
    bucket = display.newImageRect(sceneGroup, "bucket-new-bg.png", bucketWidth, bucketHeight)
    bucket.x = screenW * 0.5
    bucket.y = screenH - bucketHeight * 0.5 - 20
    bucket.name = "bucket"

    physics.addBody(bucket, "static", {
        bounce = 0,
        shape = {
            -bucketWidth/2, -bucketHeight/2,
             bucketWidth/2, -bucketHeight/2,
             bucketWidth/2,  bucketHeight/2,
            -bucketWidth/2,  bucketHeight/2
        }
    })

    -- 🧲 Move Bucket
    moveBucket = function(event)
        if event.phase == "began" or event.phase == "moved" then
            local newX = event.x
            local halfBucket = bucketWidth / 2
            if newX < halfBucket then newX = halfBucket end
            if newX > screenW - halfBucket then newX = screenW - halfBucket end
            bucket.x = newX
        end
        return true
    end
    Runtime:addEventListener("touch", moveBucket)

    -- 💔 Lose Life
    local function loseLife()
        if lives > 0 then
            lives = lives - 1
            display.remove(heartIcons[#heartIcons])
            table.remove(heartIcons)
            if lives == 0 then
                gameOver()
            end
        end
    end

    -- 🍎 Spawn Apple
    local function spawnBall()
        local apple = display.newImageRect(sceneGroup, "apple.png", 32, 32)
        apple.x = math.random(40, screenW - 40)
        apple.y = -40
        apple.name = "ball"
        apple.scored = false

        physics.addBody(apple, { radius = 15, bounce = 0 })
        apple.gravityScale = 0.8

        apple.enterFrame = function(self)
            if self.y > screenH + 20 then
                Runtime:removeEventListener("enterFrame", self)
                display.remove(self)
                loseLife()
            end
        end
        Runtime:addEventListener("enterFrame", apple)
    end
    ballTimer = timer.performWithDelay(1000, spawnBall, 0)

    -- 💥 Collision
    onCollision = function(event)
        if event.phase == "began" then
            local obj1 = event.object1
            local obj2 = event.object2

            local ball = nil
            if obj1.name == "ball" and obj2.name == "bucket" then
                ball = obj1
            elseif obj2.name == "ball" and obj1.name == "bucket" then
                ball = obj2
            end

            if ball and not ball.scored then
                ball.scored = true
                Runtime:removeEventListener("enterFrame", ball)
                display.remove(ball)

                score = score + 1
                scoreText.text = "Score: " .. score

                if score > _G.gameSettings.highScore then
                    _G.gameSettings.highScore = score
                end
            end
        end
    end
    Runtime:addEventListener("collision", onCollision)

    -- 💀 Game Over
    gameOver = function()
        physics.pause()
        if ballTimer then timer.cancel(ballTimer) end

        local gameOverText = display.newText(sceneGroup, "Game Over", screenW * 0.5, screenH * 0.5, native.systemFontBold, 36)
        gameOverText:setFillColor(1, 0, 0)

        timer.performWithDelay(2000, function()
            composer.gotoScene("menu")
        end)
    end

    -- ☰ Pause Menu
    local function drawHamburger(x, y)
        local group = display.newGroup()
        local spacing = 6
        for i = 0, 2 do
            local line = display.newRect(group, x, y + i * spacing, 24, 3)
            line:setFillColor(1)
        end
        return group
    end

    local menuButton = drawHamburger(30, 30)
    sceneGroup:insert(menuButton)

    menuButton:addEventListener("tap", function()
        physics.pause()
        if ballTimer then timer.pause(ballTimer) end

        pauseOverlay = display.newGroup()
        sceneGroup:insert(pauseOverlay)

        local bg = display.newRect(pauseOverlay, screenW * 0.5, screenH * 0.5, screenW, screenH)
        bg:setFillColor(0, 0, 0, 0.6)

        local box = display.newRoundedRect(pauseOverlay, screenW * 0.5, screenH * 0.5, 250, 180, 16)
        box:setFillColor(0.2, 0.2, 0.2)

        local resumeBtn = display.newText(pauseOverlay, "Continue ▶", screenW * 0.5, screenH * 0.5 - 30, native.systemFontBold, 22)
        resumeBtn:setFillColor(0, 1, 0)

        local menuBtn = display.newText(pauseOverlay, "Main Menu", screenW * 0.5, screenH * 0.5 + 30, native.systemFontBold, 22)
        menuBtn:setFillColor(1, 0, 0)

        resumeBtn:addEventListener("tap", function()
            physics.start()
            if ballTimer then timer.resume(ballTimer) end
            if pauseOverlay then pauseOverlay:removeSelf() pauseOverlay = nil end
        end)

        menuBtn:addEventListener("tap", function()
            composer.gotoScene("menu")
        end)
    end)
end

function scene:hide(event)
    if event.phase == "will" then
        Runtime:removeEventListener("touch", moveBucket)
        Runtime:removeEventListener("collision", onCollision)
        if ballTimer then
            timer.cancel(ballTimer)
            ballTimer = nil
        end
    end
end

function scene:show(event)
    if event.phase == "did" then
        Runtime:addEventListener("touch", moveBucket)
        Runtime:addEventListener("collision", onCollision)
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("show", scene)
return scene
