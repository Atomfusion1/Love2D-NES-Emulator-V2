
--% Local Variables
local loveDraw = {}
local cycleTime = 0
local averageTimeSpent = 16000
local averageTimeLeft = 0
local averageRatio = .1
local sleepTime = 0
local timerForFPS = love.timer.getTime()

loveDraw.overrideDelay = false
--# Functions StartTimer 
function loveDraw.StartTimer()
    timerForFPS = love.timer.getTime()
end

--# Functions Screen
function loveDraw.DisplayScreen()
    -- * Update Screen Values 
    UpdateScreenValues()
    DrawToScreen() -- * Draw To Screen 
    DelayScreen() -- * Delay Screen
    timerForFPS = love.timer.getTime()
end

--# Update Screen Values
function UpdateScreenValues()
    cycleTime = .97 * cycleTime + .03 * (love.timer.getTime() - timerForFPS)
    sleepTime = .015 - (cycleTime)
    averageTimeSpent = .95 * averageTimeSpent + .05 * math.floor(love.timer.getAverageDelta()*1000*1000)
    averageTimeLeft = .95 * averageTimeLeft  + .05 * math.floor(sleepTime*1000*1000)
    averageRatio = (averageTimeSpent-averageTimeLeft)
end

--# Delay Screen
function DelayScreen()
    loveDraw.overrideDelay = OverRideSpeed
    if sleepTime > 0 and not loveDraw.overrideDelay then
        love.timer.sleep(sleepTime)
    end
end

--# Draw To Screen
function DrawToScreen()
    love.graphics.setColor(0,1,1,1)
    love.graphics.print(string.format("FPS:%d ", love.timer.getFPS()), 10, love.graphics.getHeight()-15)
    love.graphics.setColor(1,0,1,1)
    love.graphics.print(string.format("F. Use (us):%d F. Delay (us):%d delta:%d",
        averageTimeSpent ,averageTimeLeft, averageRatio), 80, love.graphics.getHeight()-15)
    love.graphics.setColor(1,0,0,1)
    love.graphics.print(string.format("Cycle Time (us):%d",math.floor(cycleTime*1000*1000)),410,love.graphics.getHeight()-15)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Press ` or L", 600, love.graphics.getHeight()-15)
end

--% return loveDraw
return loveDraw