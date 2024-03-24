-- TODO: support doing various operations on at least two numbers? 

-- TODO: handling signed vs unsigned numbers?

import "CoreLibs/crank"
import "CoreLibs/ui"
import "CoreLibs/graphics"

local availableInputTypes = {}
availableInputTypes[1] = "DEC"
availableInputTypes[2] = "HEX"
availableInputTypes[3] = "BIN"
availableInputTypes[4] = "OCT"

local inputType = 1
local currentInput = 10
local SETTINGS = {}

local function saveData()
   playdate.datastore.write(SETTINGS)
end

-- Initialize various settings like menu items
local function init()
   SETTINGS = playdate.datastore.read() or {}
   
   local systemMenu = playdate.getSystemMenu()
   systemMenu:addCheckmarkMenuItem("Show binary result", SETTINGS.showBinary, function(value)
                                      SETTINGS.showBinary = value
   end)
   systemMenu:addCheckmarkMenuItem("Show hexadecimal result", SETTINGS.showHex, function(value)
                                      SETTINGS.showHex = value
   end)
   systemMenu:addCheckmarkMenuItem("Show octal result", SETTINGS.showOctal, function(value)
                                      SETTINGS.showOctal = value
   end)

   -- Set up drawing hints
   local abhintImg = playdate.graphics.image.new("img/abhint")
   local abhintSprite = playdate.graphics.sprite.new(abhintImg)
   abhintSprite:setCenter(0, 0)
   abhintSprite:moveTo(0, 30)
   abhintSprite:add()

   local arrowhintImg = playdate.graphics.image.new("img/arrowhint")
   local arrowhintSprite = playdate.graphics.sprite.new(arrowhintImg)
   arrowhintSprite:setCenter(0, 0)
   arrowhintSprite:moveTo(0,62)
   arrowhintSprite:add()
end

init()

-- utility function for converting to binary string
local function decimalToBinary(number)
   -- TODO: maybe tweak the size depending on the number of bits like the rest of the number? maybe only 8 bits is enough for the smallest numbers to avoid too much info on screen
   -- assuming 32 bits integers as specified by playdate docs
   local result = ""
   local currentNum = number
   local iterations = 32
   while iterations > 0 do
      if iterations % 4 == 0 then
         result = " " .. result
      end

      if 1 == currentNum & 1 then
         result = "1" .. result
      else
         result = "0" .. result
      end

      currentNum = currentNum >> 1
      iterations -= 1
   end

   return result
end

-- utility function for converting to an octal string
local function decimalToOctal(number)
   if 0 == number then
      return "0"
   end

   local result = ""
   local currentNum = number
   while currentNum > 0 do
      local nextDigit = currentNum & 7
      result = nextDigit .. result
      currentNum = currentNum >> 3
   end

   return result
end

function playdate.BButtonDown()
   -- cycle the available input types
   local maxInputTypes = table.getsize(availableInputTypes)
   inputType = (inputType % maxInputTypes) + 1
end

function playdate.update()
   -- TODO: optimize. probably don't need to clear and update if nothing has changed.
   playdate.graphics.clear()
   playdate.graphics.sprite.update()

   -- TODO: could we maybe show some usage hints? Any actions we could assign to a and b?
   --       maybe one could be switch input format?

   -- TODO: clean up into util functions
   local crankMovement = playdate.getCrankTicks(8)
   currentInput += crankMovement
   currentInput = math.max(0, currentInput)
   
   -- Formatting the input according to type
   -- TODO: signed vs unsigned
   local formatted
   local currentInputType = availableInputTypes[inputType]
   playdate.graphics.drawText(currentInputType, 2, 5)
   playdate.graphics.drawLine(0, 25, 32, 25)
   playdate.graphics.drawLine(32, 0, 32, 95)
   playdate.graphics.drawLine(0, 95, 400, 95)
   if "HEX" == currentInputType then
      formatted = string.format("%x", currentInput)
   elseif "BIN" == currentInputType then
      formatted = decimalToBinary(currentInput)
   elseif "OCT" == currentInputType then
      formatted = decimalToOctal(currentInput)
   else
      formatted = string.format("%d", currentInput)
   end
   playdate.graphics.drawTextAligned(formatted, 387, 30, kTextAlignment.right)

   -- TODO: make this selection cursor move if we have several selections
   playdate.graphics.drawLine(390, 37, 395, 32)
   playdate.graphics.drawLine(390, 37, 395, 42)

   -- TODO: should probably  introduce a variable result or something that calculates the final result. Then use that from here.
   local result = currentInput
   
   -- TODO: make the sizing of the various results sized based upon how much is shown.
   --       do we maybe need a few different font sizes for that?
   playdate.graphics.drawText("Result: ", 5, 100)
   local resultDecimal = string.format("Decimal: %d", result)
   playdate.graphics.drawText(resultDecimal, 5, 120)
   if SETTINGS.showHex then
      local resultHex = string.format("Hexadecimal: %x", result)
      playdate.graphics.drawText(resultHex, 5, 140)
   end
   if SETTINGS.showBinary then
      local binaryString = decimalToBinary(result)
      local resultBin = string.format("%s", binaryString)
      playdate.graphics.drawText("Binary:", 5, 160)
      playdate.graphics.drawText(resultBin, 5, 180)
   end
   if SETTINGS.showOctal then
      local octalString = decimalToOctal(result)
      local resultOct = string.format("Octal: %s", octalString)
      playdate.graphics.drawText(resultOct, 5, 200)
   end

   -- Usage hints
   if playdate.isCrankDocked() then
      playdate.ui.crankIndicator:draw()
   end

   -- TODO: a and b button indicators to show what they do
end

-- Closing handling functions
function playdate.gameWillTerminate()
   saveData()
end
