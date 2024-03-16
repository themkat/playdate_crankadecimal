-- TODO: support doing various operations on at least two numbers? 

-- TODO: what is the best way to handle the current selection?

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
-- TODO: workaround until all settings show.
SETTINGS.showDecimal = true

-- Initialize various settings like menu items
local function init()
   local systemMenu = playdate.getSystemMenu()
   systemMenu:addCheckmarkMenuItem("Show binary result", false, function(value)
                                      SETTINGS.showBinary = value
   end)
   systemMenu:addCheckmarkMenuItem("Show hexadecimal result", false, function(value)
                                      SETTINGS.showHex = value
   end)
   systemMenu:addCheckmarkMenuItem("Show octal result", false, function(value)
                                      SETTINGS.showOctal = value
   end)
   -- TODO: why aren't more showing after the third one?
   systemMenu:addCheckmarkMenuItem("Show decimal result", false, function(value)
                                      SETTINGS.showDecimal = value
   end)
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

   -- TODO: could we maybe show some usage hints? Any actions we could assign to a and b?
   --       maybe one could be switch input format?

   -- TODO: clean up into util functions
   local crankMovement = playdate.getCrankTicks(8)
   currentInput += crankMovement
   currentInput = math.max(0, currentInput)

   -- TODO: Maybe we should indicate what type we are currently inputing somewhere?
   local formatted
   local currentInputType = availableInputTypes[inputType]
   if "HEX" == currentInputType then
      formatted = string.format("%x", currentInput)
   elseif "BIN" == currentInputType then
      formatted = decimalToBinary(currentInput)
   elseif "OCT" == currentInputType then
      formatted = decimalToOctal(currentInput)
   else
      formatted = string.format("%d", currentInput)
   end
   playdate.graphics.drawTextAligned(formatted, 390, 30, kTextAlignment.right)

   -- TODO: when we have several inputs, move this to the next.
   -- TODO: have this selection blink and underline the current input perfectly
   playdate.graphics.drawLine(300, 50, 390, 50)

   -- TODO: should probably  introduce a variable result or something that calculates the final result. Then use that from here.
   local result = currentInput
   
   -- TODO: make the sizing of the various results sized based upon how much is shown.
   --       do we maybe need a few different font sizes for that?
   playdate.graphics.drawText("Result: ", 5, 100)
   if SETTINGS.showDecimal then
      local resultDecimal = string.format("Decimal: %d", result)
      playdate.graphics.drawText(resultDecimal, 5, 120)
   end
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
