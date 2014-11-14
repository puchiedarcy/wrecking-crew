lineHeight = 8;
bottomLine = 225;
customInputDelay = 0;
showCustomMenu = false;
customMenu = {
    "Golden Hammer",
    "Record",
    "Replay",
    "Repeat",
    "NG+"
};
customMenuCursor = 0;
customMenuValues = {
    false,
    false,
    false,
    false,
    false
};
recording = false;
replaying = false;

function debugger(v)
    gui.text(100, bottomLine, v);
end

sqlite = require('lsqlite3');
db = sqlite.open('wcrewdb.sqlite');
db:exec([[
    create table best_times (
        phase integer primary key,
        frames integer not null,
        length integer not null
    );
]]);

for i=1, 100 do
    local e = db:exec('insert into best_times values (' .. i .. ', 0, 0);' );
end

function readRAMandInputs()
    cameraOffset = memory.readbyte('0x003F');
    inLevelFlag = memory.readbyte('0x0037');
    buttons1p = joypad.getdown(1);
    buttons2p = joypad.getdown(2);
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

function isButtonPressed(player, button)
    if (player == 1) then
        return buttons1p[button] ~= nil;
    elseif (player == 2) then
        return buttons2p[button] ~= nil;
    end
end

function parseCustomInput()
    if customInputDelay > 0 then
        customInputDelay = customInputDelay - 1;
        return;
    end
    
    if (inLevel()) then
        if (isButtonPressed(1, 'B') and isButtonPressed(1, 'A') and customInputDelay <= 0) then
            switchGoldenHammer();
            customInputDelay = 60;
        
        end
    else
        if (not showCustomMenu and isButtonPressed(1, 'left')) then
            showCustomMenu = true;
            customInputDelay = 12;
            
        elseif (showCustomMenu and isButtonPressed(1, 'left')) then
            showCustomMenu = false;
            customMenuCursor = 0;
            customInputDelay = 12;
            
        elseif (showCustomMenu and isButtonPressed(1, 'right')) then
            customMenuCursor = (customMenuCursor + 1) % #customMenu;
            customInputDelay = 12;
            
        elseif (showCustomMenu and isButtonPressed(1, 'B')) then
            --decrement
            customInputDelay = 12;
            
        elseif (showCustomMenu and isButtonPressed(1, 'A')) then
            --increment
            customMenuValues[customMenuCursor+1] = not customMenuValues[customMenuCursor+1];
            customInputDelay = 12;
            
        elseif (not showCustomMenu and isButtonPressed(1, 'B') and isButtonPressed(1, 'A')) then
            if (memory.readbyte('0x0060') ~= 0) then
                memory.writebyte('0x0060', 0);
            else
                memory.writebyte('0x0060', 50);
            end
            customInputDelay = 60;
            
        end
    end
end

function inLevel()
    return inLevelFlag == 0;
end

function inBonus()
    return music == 15;
end

function switchGoldenHammer()
    local phase = memory.readbyte('0x0092') + 1;
    if (phase == 1 or phase == 2 or phase == 3) then
        return;
    end
    
    local goldenHammerStatus = memory.readbyte('0x005C');
    goldenHammerStatus = (goldenHammerStatus+1)%2;
    
    memory.writebyte('0x005C', goldenHammerStatus);
end

function drawGoldenHammerStatus()
    local goldenHammerStatus = memory.readbyte('0x005C');
    
    if (goldenHammerStatus == 1) then
        gui.text(171, bottomLine, 'Golden Hammer On');
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
        gui.text(2, lineHeight*2, 'Magic Number: ' .. 8 - (magicNumber % 8));
    end
end

function drawFireballCountdown()
    local fireballCountdown = memory.readbyte('0x03DD');
    gui.text(197, lineHeight, 'Fireball: ' .. fireballCountdown);
end

function drawBonusCoin()
    local bonusCoin = memory.readbyte('0x034F');
    drawBox(bonusCoin, 'green');
end

inGameTimerFrames = 0;
movieLength = 0;
function drawInGameTimer()
    local marioState = memory.readbyte('0x0300');
    local music = memory.readbyte('0x038');
    local phase = memory.readbyte('0x0092') + 1;
    
    for row in db:rows('SELECT frames, length FROM best_times where phase = ' .. phase .. ';') do
        bestTimeInFrames = row[1];
        bestMovieLength = row[2];
    end
    
    if (marioState == 14) then
        inGameTimerFrames = 0;
        movieLength = 0;
        return;
    end
    
    movieLength = movieLength + 1;
    
    if (marioState == 12 and music == 4) then
        startReplaying(phase, bestMovieLength);
        startRecording(phase);
    elseif (marioState ~= 12 and marioState ~= 13 and music == 4) then
        inGameTimerFrames = inGameTimerFrames + 1;
    elseif (music == 6) then
        if ((bestTimeInFrames == 0 or inGameTimerFrames < bestTimeInFrames) and inGameTimerFrames > 0) then
            gui.text(107, lineHeight*12, "New record!");
        end
    elseif (music == 7) then
        stopRecording();
        stopReplaying();
        if ((bestTimeInFrames == 0 or inGameTimerFrames < bestTimeInFrames) and inGameTimerFrames > 0) then
            local e = db:exec('UPDATE best_times SET frames = ' .. inGameTimerFrames .. ', length = ' .. movieLength .. ' where phase = ' .. phase .. ';');
        end
    elseif (music == 1) then
        inGameTimerFrames = 0;
    end
    
    local inGameSeconds = math.floor(inGameTimerFrames / 60);
    local inGameHundredths = round((inGameTimerFrames % 60) * 1.66666666666, 0);
    gui.text(111, lineHeight, 'Time: ' .. inGameSeconds .. '.' .. string.format("%02d", inGameHundredths));
    
    local bestGameSeconds = math.floor(bestTimeInFrames / 60);
    local bestGameHundredths = round((bestTimeInFrames % 60) * 1.66666666666, 0);
    gui.text(110, lineHeight*2, 'Best: ' .. bestGameSeconds .. '.' .. string.format("%02d", bestGameHundredths));
end

function speedupPhaseIntro()
    local countdownTimer = memory.readbyte('0x021');
    
    if (countdownTimer > 96) then
        memory.writebyte('0x0021', 0);
    end
end

function startReplaying(phase, frames)
    if (customMenuValues[3]) then
        if (not replaying) then
            replaying = true;
            movie.play(phase, 0);
        end
    end
end

function stopReplaying()
    if (customMenuValues[3]) then
        replaying = false;
        if (movie.active()) then
            movie.stop();
        end
    end
end

function drawCustomMenu()
    if (showCustomMenu) then
        gui.rect(50, 58, 205, 181, 'black', 'green');
        
        local y = 72;
        local spacing = 16;
        for i = 1, #customMenu do
            gui.text(72, y, customMenu[i]);
            y = y + 16;
        end
        
        y = 72;
        for i = 1, #customMenu do
            gui.text(150, y, tostring(customMenuValues[i]));
            y = y + 16;
        end
        
        gui.box(60, 72 + customMenuCursor*spacing, 65, 77 + customMenuCursor*spacing);
    end
end

function startRecording(phase)
    if (customMenuValues[2]) then
        if (not recording) then
            recording = true;
            movie.record(phase);
        end
    end
end

function stopRecording()
    if (customMenuValues[2]) then
        recording = false;
        if (movie.active()) then
            movie.stop();
        end
    end
end

function setCustomOptions()
    if (customMenuValues[1]) then
        --repeat
        memory.writebyte('0x005C', 1);
    end
    
    if (customMenuValues[3]) then
        customMenuValues[2] = false;
    end
    
    if (customMenuValues[2]) then
        customMenuValues[3] = false;
    end
    
    if (customMenuValues[4]) then
        --repeat
        memory.writebyte('0x0092', memory.readbyte('0x0060'));
    end
    
    if (customMenuValues[5]) then
        --NG+
        memory.writebyte('0x0094', 1);
    end
end

while true do
    readRAMandInputs();
    parseCustomInput();
    setCustomOptions();
    
    if (inLevel()) then
        if (inBonus()) then
            stopRecording();
            drawBonusCoin();
        else
            --speedupPhaseIntro();
            --drawMARIOLetters();
            drawPrizeBomb();
            drawFireballCountdown();
            drawInGameTimer();
            drawGoldenHammerStatus();
        end
    else
        stopRecording();
        stopReplaying();
        drawCustomMenu();
    end
    
    emu.frameadvance();
end