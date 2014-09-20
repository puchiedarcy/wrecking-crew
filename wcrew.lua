function debugger(v)
    gui.text(0, 111, v);
end

function readRAMandInputs()
    cameraOffset = memory.readbyte('0x003F');
    buttons = joypad.getdown(1);
end

function convertXLocToPixel(loc)
    return (loc%16)*16;
end

titleOffset = 177;
function convertYLocToPixel(loc)
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

function isButtonPressed(button)
    return buttons[button] ~= nil;
end

goldenHammerDelay = 0;
function switchGoldenHammer()
    local goldenHammerStatus = memory.readbyte('0x005C');
    
    if (isButtonPressed('A') and isButtonPressed('B') and goldenHammerDelay <= 0) then
        goldenHammerStatus = (goldenHammerStatus+1)%2;
        goldenHammerDelay = 60;
    end
    
    if (goldenHammerStatus == 1) then
        gui.text(171, 8, 'Golden Hammer On');
    end
    
    memory.writebyte('0x005C', goldenHammerStatus);
    goldenHammerDelay = goldenHammerDelay - 1;
end

function drawMARIOLetters()
    inLevel = memory.readbyte('0x0037');
    if (inLevel == 1) then
        return;
    end
    
    MARIO = '0x0430';
    MARIOMap = {'M', 'A', 'R', 'I', 'O'};
    MARIOFlag = memory.readbyte(MARIO);
    if (MARIOFlag == 0) then
        gui.text(0, 24, 'NO MARIO');
    else
        drawBox(memory.readbyte(MARIO+MARIOFlag), '#00FFFF');
        drawLetter(memory.readbyte(MARIO+MARIOFlag), MARIOMap[MARIOFlag]); 
        
        for i = MARIOFlag + 1, 5, 1 do
            drawLetter(memory.readbyte(MARIO+i), MARIOMap[i]); 
        end
    end
end

while true do
    readRAMandInputs();
    drawMARIOLetters();
    switchGoldenHammer();
    
    inLevel = memory.readbyte('0x0037');
    if (inLevel == 0) then
        bombCounter = memory.readbyte('0x0440');
        if (bombCounter == 0 or bombCounter == 25) then
            inBonus = memory.readbyte('0x0038');
            if (inBonus == 15) then
                bonusCoin = memory.readbyte('0x034F');
                drawBox(bonusCoin, 'green');
            else
                gui.text(0, 8, 'NO PRIZE BOMB');
            end
        else
            lastBomb = memory.readbyte('0x04D1');
            magicNumber = memory.readbyte('0x005D');
            
            prizeBomb = memory.readbyte('0x0441');
            drawBox(prizeBomb, 'green');
            
            gui.text(0, 8, 'Bomb Counter: ' .. 4 - bombCounter);
            gui.text(0, 16, 'Magic Number: ' .. 8 - (magicNumber % 8));
        end
    end
    
    emu.frameadvance();
end
