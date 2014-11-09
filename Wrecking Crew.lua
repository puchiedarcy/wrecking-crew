lineHeight = 8;
bottomLine = 225;
function debugger(v)
    gui.text(100, bottomLine, v);
end

function readRAMandInputs()
    cameraOffset = memory.readbyte('0x003F');
    inLevelFlag = memory.readbyte('0x0037');
    buttons = joypad.getdown(1);
    music = memory.readbyte('0x0038');
end

function convertXLocToPixel(loc)
    return (loc%16)*16;
end

function convertYLocToPixel(loc)
    local titleOffset = 177;
    return titleOffset + math.floor(loc/16)*32 - cameraOffset;
end

function drawBox(loc, color)
    local boxHeight = 22;
    local boxWidth = 16;
    local locX = convertXLocToPixel(loc);
    local locY = convertYLocToPixel(loc);
    
    gui.line(locX,          locY,           locX+boxWidth, locY,           color);
    gui.line(locX+boxWidth, locY,           locX+boxWidth, locY+boxHeight, color);
    gui.line(locX,          locY+boxHeight, locX+boxWidth, locY+boxHeight, color);
    gui.line(locX,          locY,           locX,          locY+boxHeight, color);
end

function drawLetter(loc, letter)
    local locX = convertXLocToPixel(loc);
    local locY = convertYLocToPixel(loc);
    
    gui.text(locX, locY, letter);
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function isButtonPressed(button)
    return buttons[button] ~= nil;
end

function inLevel()
    return inLevelFlag == 0;
end

function inBonus()
    return music == 15;
end

goldenHammerDelay = 0;
function switchGoldenHammer()
    local goldenHammerStatus = memory.readbyte('0x005C');
    
    if (isButtonPressed('A') and isButtonPressed('B') and goldenHammerDelay <= 0) then
        goldenHammerStatus = (goldenHammerStatus+1)%2;
        goldenHammerDelay = 60;
    end
    
    if (goldenHammerStatus == 1) then
        gui.text(171, bottomLine, 'Golden Hammer On');
    end
    
    memory.writebyte('0x005C', goldenHammerStatus);
    
    if goldenHammerDelay < 0 then
        goldenHammerDelay = 0;
    else
        goldenHammerDelay =  goldenHammerDelay - 1;
    end
end

function drawMARIOLetters()
    local MARIO = '0x0430';
    local MARIOMap = {'M', 'A', 'R', 'I', 'O'};
    local MARIOFlag = memory.readbyte(MARIO);
    if (MARIOFlag == 0) then
        gui.text(0, bottomLine, 'NO MARIO');
    else
        drawBox(memory.readbyte(MARIO+MARIOFlag), '#00FFFF');
        drawLetter(memory.readbyte(MARIO+MARIOFlag), MARIOMap[MARIOFlag]); 
        
        for i = MARIOFlag + 1, 5, 1 do
            drawLetter(memory.readbyte(MARIO+i), MARIOMap[i]); 
        end
    end
end

function drawPrizeBomb()
    local bombCounter = memory.readbyte('0x0440');
    if (bombCounter == 0) then
        gui.text(0, lineHeight, 'NO PRIZE BOMB');
    else
        local magicNumber = memory.readbyte('0x005D');
        local prizeBomb = memory.readbyte('0x0441');
        drawBox(prizeBomb, 'green');
        
        gui.text(0, lineHeight, 'Bomb Counter: ' .. 4 - bombCounter);
        gui.text(0, lineHeight*2, 'Magic Number: ' .. 8 - (magicNumber % 8));
    end
end

function drawFireballCountdown()
    local countdown = memory.readbyte('0x03DD');
    gui.text(197, lineHeight, 'Fireball: ' .. countdown);
end

function drawBonusCoin()
    local bonusCoin = memory.readbyte('0x034F');
    drawBox(bonusCoin, 'green');
end

inGameTimerFrames = 0;
function drawInGameTimer()
    local marioState = memory.readbyte('0x0300');
    local music = memory.readbyte('0x038');
    
    if (marioState ~= 12 and music == 4) then
        inGameTimerFrames = inGameTimerFrames + 1;
    elseif (music ~= 5 and music ~= 6 and music ~= 10 and music ~= 11) then
        inGameTimerFrames = 0;
    end
    
    local inGameSeconds = math.floor(inGameTimerFrames / 60);
    local inGameHundredths = round((inGameTimerFrames % 60) * 1.66666666666, 0);
    
    gui.text(111, lineHeight, 'Time: ' .. inGameSeconds .. '.' .. string.format("%02d", inGameHundredths));
end

function speedupPhaseIntro()
    local countdownTimer = memory.readbyte('0x021');
    
    if (countdownTimer > 96) then
        memory.writebyte('0x021', 0);
    end
end

while true do
    readRAMandInputs();
    switchGoldenHammer();
    
    if (inLevel()) then
        if (inBonus()) then
            drawBonusCoin();
        else
            drawMARIOLetters();
            drawPrizeBomb();
            drawFireballCountdown();
            drawInGameTimer();
            speedupPhaseIntro();
        end
    end
    
    emu.frameadvance();
end
