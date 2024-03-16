-- TODO: support a single number the user can tweak on screen using the crank
-- TODO: support doing various operations on at least two numbers? 


-- TODO: should we maybe have a current input type? should this affect what results are shown in any way?
-- TODO: what is the best way to handle the current selection?
--

-- TODO: handling signed vs unsigned numbers?
import "CoreLibs/crank"

local inputType = "HEX"
-- TODO: what is the best way to handle the current input? Number? String?
local currentInput = 10
local SETTINGS = {}

-- Initialize various settings like menu items
local function init()
   local systemMenu = playdate.getSystemMenu()
   systemMenu:addCheckmarkMenuItem("Show binary result", false, function(value)
                                      SETTINGS.showBinary = value
   end)
   systemMenu:addCheckmarkMenuItem("Show hexadecimal result", false, function(value)
                                      SETTINGS.showHex = value
   end)
   systemMenu:addCheckmarkMenuItem("Show decimal result", false, function(value)
                                      SETTINGS.showDecimal = value
   end)
end

init()

-- utility function for converting to binary string
function decimalToBinary(number)
   -- TODO: have some sort of logic to print out a relevant number of bits?
   local result = ""
   local currentNum = number
   while currentNum > 0 do
      if 1 == currentNum & 1 then
         result = "1" .. result
      else
         result = "0" .. result
      end
      
      currentNum = currentNum >> 1
   end

   return result
end


function playdate.BButtonDown()
   -- TODO: do the best way of cycling input specificiers
   inputType = "BIN"
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
   

   local formatted
   if "HEX" == inputType then
      formatted = string.format("%x", currentInput)
   elseif "BIN" == inputType then
      formatted = decimalToBinary(currentInput)
   else
      formatted = string.format("%d", currentInput)
   end
   -- TODO: better placement of the result string (if it grows, part of it gets swallowed up by the right side of the screen)
   playdate.graphics.drawText(formatted, 350, 50)

   -- TODO: make the sizing of the various results sized based upon how much is shown.
   --       do we maybe need a few different font sizes for that?
   playdate.graphics.drawLine(0, 0, 30, 30)
   playdate.graphics.drawText("Result: ", 5, 150)
   if SETTINGS.showDecimal then
      local resultDecimal = string.format("Decimal: %d", currentInput)
      playdate.graphics.drawText(resultDecimal, 5, 175)
   end
   if SETTINGS.showHex then
      local resultHex = string.format("Hexadecimal: %x", currentInput)
      playdate.graphics.drawText(resultHex, 5, 200)
   end
   if SETTINGS.showBinary then
      local binaryString = decimalToBinary(currentInput)
      local resultBin = string.format("Binary: %032s", binaryString)
      playdate.graphics.drawText(resultBin, 5, 200)
   end
end
