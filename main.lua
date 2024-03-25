-- TODO: any way to get the 0 and 1s to take up the same space in the view? Custom font?

import "CoreLibs/crank"
import "CoreLibs/ui"
import "CoreLibs/graphics"

local SETTINGS = {}

-- stupid way to easily cycle between the different input types
local availableInputTypes = {}
availableInputTypes[1] = "DEC"
availableInputTypes[2] = "HEX"
availableInputTypes[3] = "BIN"
availableInputTypes[4] = "OCT"
local inputType = 1

-- The user inputs
local currentInput = {}
currentInput[1] = 0
currentInput[2] = 69

-- Simple lookup table to cycle operations easily
local availableOperations = {}
availableOperations[1] = "+"
availableOperations[2] = "-"
availableOperations[3] = "AND"
availableOperations[4] = "OR"
availableOperations[5] = "XOR"
local currentOperation = 1

-- table.getsize sometimes return wrong number, so making a constant
local NUM_OPERATIONS = 5

local selectionCrankTicks = {}
selectionCrankTicks[1] = 16
selectionCrankTicks[2] = 6
selectionCrankTicks[3] = 16

-- 0 indexed between 3 choices. Might be confusing as Lua is 1-indexed on arrays...
local currentSelection = 0
local isMultiInput = false

-- Simple toggle to avoid unnecessary redraws
-- (starts as true to draw the first time)
local shouldRedraw = true

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
   while math.abs(currentNum) > 0 do
      local nextDigit = currentNum & 7
      result = nextDigit .. result
      currentNum = currentNum >> 3
   end

   return result
end

function playdate.AButtonDown()
   shouldRedraw = true
   isMultiInput = not isMultiInput

   if not isMultiInput then
      currentSelection = 0

      -- also clear the inputs when switching from multiview
      currentInput[1] = 0
      currentInput[2] = 0
   end
end

function playdate.BButtonDown()
   -- cycle the available input types
   local maxInputTypes = table.getsize(availableInputTypes)
   inputType = (inputType % maxInputTypes) + 1
   shouldRedraw = true
end

function playdate.leftButtonDown()
   -- TODO: what amount is good here? For the big binary numbers, everything seems too small..
   if 0 == currentSelection then
      currentInput[1] += 0xff
   elseif 2 == currentSelection then
      currentInput[2] += 0xff
   end

   shouldRedraw = true
end

function playdate.rightButtonDown()
   if 0 == currentSelection then
      currentInput[1] -= 0xff
   elseif 2 == currentSelection then
      currentInput[2] -= 0xff
   end

   shouldRedraw = true
end

function playdate.upButtonDown()
   if isMultiInput then
      currentSelection = math.max(currentSelection - 1, 0)
      shouldRedraw = true
   end
end

function playdate.downButtonDown()
   if isMultiInput then
      currentSelection = math.min(currentSelection + 1, 2)
      shouldRedraw = true
   end
end

local function calculateMultiInputResult()
   local operation = availableOperations[currentOperation]
   if "+" == operation then
      return currentInput[1] + currentInput[2]
   elseif "-" == operation then
      return currentInput[1] - currentInput[2]
   elseif "AND" == operation then
      return currentInput[1] & currentInput[2]
   elseif "OR" == operation then
      return currentInput[1] | currentInput[2]
   elseif "XOR" == operation then
      return currentInput[1] ~ currentInput[2]
   else
      -- Should never end up here unless something is unimplemented. Ends up with runtime error
      -- (now I miss Rust match arms :( )
      return "WTF"
   end
end

local function getResult()
   if isMultiInput then
      return calculateMultiInputResult()
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

-- Simple utility function for calculating the cycling of operations from the crank movement
local function getNextOperationsValue(crankMovement)
   if 0 < crankMovement then
      return (currentOperation % NUM_OPERATIONS) + 1
   elseif 0 > crankMovement then
      return (((NUM_OPERATIONS - 1) + (currentOperation - 1) % NUM_OPERATIONS) % NUM_OPERATIONS) + 1
   else
      return currentOperation
   end
end

-- TODO: a bit unruly and should probably be cleaned up into helpers...
function playdate.update()
   local crankMovement = playdate.getCrankTicks(selectionCrankTicks[currentSelection + 1])
   if 0 == currentSelection then
      currentInput[1] += crankMovement
   elseif 1 == currentSelection then
      currentOperation = getNextOperationsValue(crankMovement)
   elseif 2 == currentSelection then
      currentInput[2] += crankMovement
   end

   shouldRedraw = shouldRedraw or (0 ~= crankMovement)

   if shouldRedraw then
      playdate.graphics.clear()
      playdate.graphics.sprite.update()

      -- Formatting the input according to type
      local currentInputType = availableInputTypes[inputType]
      playdate.graphics.drawText(currentInputType, 2, 5)
      playdate.graphics.drawLine(0, 25, 32, 25)
      playdate.graphics.drawLine(32, 0, 32, 95)
      playdate.graphics.drawLine(0, 95, 400, 95)
      drawInputNumber(currentInput[1], currentInputType, 30)

      -- Also draw the operation and second number if multi input
      if isMultiInput then
         playdate.graphics.drawText("Op: Multi", 325, 5)
         playdate.graphics.drawTextAligned(availableOperations[currentOperation], 380, 50, kTextAlignment.right)
         drawInputNumber(currentInput[2], currentInputType, 70)
      else
         playdate.graphics.drawText("Op: Single", 325, 5)
      end

      local yCurrentSelectionBase = 37 + (currentSelection * 20)
      playdate.graphics.drawLine(390, yCurrentSelectionBase, 395, yCurrentSelectionBase - 5)
      playdate.graphics.drawLine(390, yCurrentSelectionBase, 395, yCurrentSelectionBase + 5)

      local result = getResult()

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
      shouldRedraw = false
   end

   -- Usage hints
   if playdate.isCrankDocked() then
      playdate.ui.crankIndicator:draw()
   end
end

-- Closing handling functions
function playdate.gameWillTerminate()
   saveData()
end
