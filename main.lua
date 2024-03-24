-- TODO: support doing various operations on at least two numbers? 

-- TODO: handling signed vs unsigned numbers?

import "CoreLibs/crank"
import "CoreLibs/ui"
import "CoreLibs/graphics"

local SETTINGS = {}

local availableInputTypes = {}
availableInputTypes[1] = "DEC"
availableInputTypes[2] = "HEX"
availableInputTypes[3] = "BIN"
availableInputTypes[4] = "OCT"
local inputType = 1

-- TODO: how to handle multiple input numbers and an operation? and how should we tweak it on and off?
--       maybe a small bar at the top we can scroll/crank?
-- TODO: maybe we should also add methods to actually calculate the final result as well?
local currentInput = {}
currentInput[1] = 0
currentInput[2] = 69

-- 0 indexed between 3 choices. Might be confusing as Lua is 1-indexed on arrays...
local currentSelection = 0
local isMultiInput = false


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

function playdate.AButtonDown()
   isMultiInput = not isMultiInput

   -- TODO: should we nullify the inputs somehow? maybe double for clear?
   if not isMultiInput then
      currentSelection = 0
   end
end

function playdate.BButtonDown()
   -- cycle the available input types
   local maxInputTypes = table.getsize(availableInputTypes)
   inputType = (inputType % maxInputTypes) + 1
end

function playdate.leftButtonDown()
   -- TODO: what amount is good here? For the big binary numbers, everything seems too small..
   if 0 == currentSelection then
      currentInput[1] += 0xff
   elseif 2 == currentSelection then
      currentInput[2] += 0xff
   end
end

function playdate.rightButtonDown()
   if 0 == currentSelection then
      currentInput[1] -= 0xff
   elseif 2 == currentSelection then
      currentInput[2] -= 0xff
   end
end

function playdate.upButtonDown()
   if isMultiInput then
      currentSelection = math.max(currentSelection - 1, 0)
   end
end

function playdate.downButtonDown()
   if isMultiInput then
      currentSelection = math.min(currentSelection + 1, 2)
   end
end

local function getResult()
   if isMultiInput then
      return currentInput[1] + currentInput[2]
   else
      return currentInput[1]
   end
end

local function drawInputNumber(number, numberType, yPos)
   local formatted
      if "HEX" == numberType then
      formatted = string.format("%x", number)
   elseif "BIN" == numberType then
      formatted = decimalToBinary(number)
   elseif "OCT" == numberType then
      formatted = decimalToOctal(number)
   else
      formatted = string.format("%d", number)
   end
   playdate.graphics.drawTextAligned(formatted, 387, yPos, kTextAlignment.right)
end

-- TODO: a bit unruly and should probably be cleaned up into helpers...
function playdate.update()
   -- TODO: optimize. probably don't need to clear and update if nothing has changed.
   playdate.graphics.clear()
   playdate.graphics.sprite.update()

   -- TODO: clean up into util functions. All additions etc. on current selections should probably be extracted. 
   local crankMovement = playdate.getCrankTicks(16)
   if 0 == currentSelection then
      currentInput[1] += crankMovement
      currentInput[1] = math.max(0, currentInput[1])
   elseif 2 == currentSelection then
      currentInput[2] += crankMovement
      currentInput[2] = math.max(0, currentInput[2])
   end
   
   -- Formatting the input according to type
   -- TODO: signed vs unsigned
   local currentInputType = availableInputTypes[inputType]
   playdate.graphics.drawText(currentInputType, 2, 5)
   playdate.graphics.drawLine(0, 25, 32, 25)
   playdate.graphics.drawLine(32, 0, 32, 95)
   playdate.graphics.drawLine(0, 95, 400, 95)
   drawInputNumber(currentInput[1], currentInputType, 30)

   -- Also draw the operation and second number if multi input
   if isMultiInput then
      playdate.graphics.drawText("+", 380, 50)
      
      drawInputNumber(currentInput[2], currentInputType, 70)
   end
   

   -- TODO: Should probably combine the previous and this one. postponing for readability
   if isMultiInput then
      playdate.graphics.drawText("Op: Multi", 325, 5)
   else
      playdate.graphics.drawText("Op: Single", 325, 5)
   end
   
   -- TODO: make this selection cursor move if we have several selections
   local yCurrentSelectionBase = 37 + (currentSelection * 20)
   playdate.graphics.drawLine(390, yCurrentSelectionBase, 395, yCurrentSelectionBase - 5)
   playdate.graphics.drawLine(390, yCurrentSelectionBase, 395, yCurrentSelectionBase + 5)

   -- TODO: should probably  introduce a variable result or something that calculates the final result. Then use that from here.
   local result = getResult()
   
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
