goldenHammerStatus = 0;

function drawBox(loc)
    boxHeight = 22;
    boxColor = 'green';
    titleOffset = 177;
    cameraOffset = memory.readbyte('0x003F');
    
    locX = (loc%16)*16;
    locY = titleOffset + math.floor(loc/16)*32;
    
    gui.line(locX,    locY-cameraOffset,           locX+16, locY-cameraOffset,           boxColor);
    gui.line(locX+16, locY-cameraOffset,           locX+16, locY+boxHeight-cameraOffset, boxColor);
    gui.line(locX,    locY+boxHeight-cameraOffset, locX+16, locY+boxHeight-cameraOffset, boxColor);
    gui.line(locX,    locY-cameraOffset,           locX,    locY+boxHeight-cameraOffset, boxColor);
end

function switchGoldenHammer()
    buttons = joypad.getdown(1);

    isAPressed = false;
    isBPressed = false;
    for i in pairs(buttons) do
        if (i == 'A') then
            isAPressed = true;
        end
        if (i == 'B') then
            isBPressed = true;
        end
    end
    
    if (isAPressed and isBPressed) then
        goldenHammerStatus = memory.readbyte('0x005C');
        goldenHammerStatus = (goldenHammerStatus+1)%2;
    end
    
    if (goldenHammerStatus == 1) then
        gui.text(171, 8, 'Golden Hammer On');
    end
    memory.writebyte('0x005C', goldenHammerStatus);
end

while true do
    inLevel = memory.readbyte('0x0037');
    if (inLevel == 0) then
        bombCounter = memory.readbyte('0x0440');
        if (bombCounter == 0) then
            inBonus = memory.readbyte('0x0038');
            if (inBonus == 15) then
                bonusCoin = memory.readbyte('0x034F');
                drawBox(bonusCoin);
            else
                gui.text(0, 8, 'NO PRIZE BOMB');
            end
        else
            lastBomb = memory.readbyte('0x04D1');
            magicNumber = memory.readbyte('0x005D');
            
            prizeBomb = memory.readbyte('0x0441');
            drawBox(prizeBomb);
            
            gui.text(0, 8, 'Bomb Counter: ' .. 4 - bombCounter);
            gui.text(0, 16, 'Magic Number: ' .. 8 - (magicNumber % 8));
        end
    end
    
    switchGoldenHammer();
    emu.frameadvance()
end