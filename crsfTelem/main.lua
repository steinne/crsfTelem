
-- ###############################################################################
-- ## Script by steinne                                						
-- ## V 1.0, 2020/07/31                                							 
-- ##                                                  						
-- ## For use with betaflight and CRSF Telemetry   								
-- ## based on a widget by dk7xe  												
-- ## https://github.com/dk7xe/horus_telemetry_widget/blob/master/README.md     
-- ###############################################################################

-- Background transparency (1=true/0=false)
local debug = 0

-- Path to pictures on SD-Card
local imagePath = "/WIDGETS/crsfTelem/images/"  

local col_std = BLACK	  -- standard value color: `WHITE`,`GREY`,`LIGHTGREY`,`DARKGREY`,`BLACK`,`YELLOW`,`BLUE`,`RED`,`DARKRED`
local col_min = BLUE      -- standard min value color
local col_max = GREY	  -- standard max value color
local col_alm = RED		  -- standard alarm value color

local homeLat = 0     -- Lat of Home position
local homeLon = 0	-- Long of Home position  

-- Parameter for Lettersize and correction factors of measures  
local modeSize = {sml = SMLSIZE, mid = MIDSIZE, dbl = DBLSIZE}
local modeAlign = {ri = RIGHT, le = LEFT}
local yCorr = {sml = 16, mid = 8,  dbl = 0}
local xCorr = {value = 0.75, value1 = 0.50, center = 7}
local SF  = getFieldInfo("ls4")
local SD_id  = getFieldInfo("sd").id
local SA  = getFieldInfo("sa")
local cellVoltage = 0
local sats = 0
local rss1 = 0 
local rss2 = 0
local rqly = 0


local options = {
--	{ "Source", SOURCE, 1 },
--	{ "Min", VALUE, 0, -1024, 1024 },
--	{ "Max", VALUE, 100, -1024, 1024 }
--	{ "BckGrnd", COLOR, GREY}	-- Arm switch 	
--	{ "GPS", BOOL, 0},	-- using GPS 
    { "Transparency", BOOL, 0},	-- Arm switch 
	{ "Arm", SOURCE, SF['id']},	-- Arm switch 
	{ "FltMode", SOURCE, SD_id},	-- Flt switch
	{ "Rescue", SOURCE, SA['id']}


}

function create(zone, options)
	local thisZone  = { zone=zone, options=options }
		lipoCapa = thisZone.options.BattCpcty
		useArm =  thisZone.options.Arm
		useFlt =  thisZone.options.FltMode
		useBpr =  thisZone.options.Rescue
		usebckgrnd =  thisZone.options.BckGrnd
		transparency = thisZone.options.Transparency
		widget()
	return thisZone
end

function update(thisZone, options)
  thisZone.options = options
end

-- ################## Definition of Widgets #################




------------------
-- Telemetry ID --
------------------
local function getTelemetryId(name)
	field = getFieldInfo(name)
	if field then
	  return field.id
	else
	  return -1
	end
end

---------------
-- Get Value --
--------------- 
local function getValueOrDefault(value)
	local tmp = getValue(value)
	
	if tmp == nil then
		return 0
	end
	
	return tmp
end

----------------------
-- Get Value Rounded--
---------------------- 
local function round(num, decimal)
    local mult = 10^(decimal or 0)
    return math.floor(num * mult + 0.5) / mult
 end


----------------------
-- Get telemetry data
----------------------

local function getTelemetryValues()
	if debug == 1 then
		 cellVoltage   =  25.2 --16.8
		 sats      =  0
		 rss1  =  38 * -1
		 rss2  =  34 * -1
		 rssi  =  math.max(rss1,rss2)
		 rqly  = 90
		 rfmd = 2
		 tpwr = 10
		 rss1min = -57
		 rsnr = 45
	else
		 cellVoltage   =  getValueOrDefault("RxBt")
		 rss1  =  getValueOrDefault("1RSS") * -1
		 rss2  =  getValueOrDefault("2RSS") * -1
		 rssi  =  math.max(rss1,rss2)
		 sats  =  getValueOrDefault("Sats")
		 rqly  =  getValueOrDefault("RQly")
		 rfmd  =  getValueOrDefault("RFMD")
		 tpwr  =  getValueOrDefault("TPWR")
		 rss1min =  getValueOrDefault("1RSSI-")
		 rsnr  =  getValueOrDefault("RSNR")
	end

end


-- ###################### Widgets #########################

function widget()

	    widgetDefinition = {{"rsnr", "battery1"},{"timer","armed","lost"}, {"rssi1", "rqly"}}
		-- widgetDefinition = {{"rssi1", "battery1"},{"fltmd","armed","vtx"}, {"lost", "txbat", "timer"}}
end

------------------------------------------------- 
-- Basic Flight mode       ------------- fltmd --
------------------------------------------------- 
local function fltmdWidget(xCoord, yCoord, cellHeight, name)
	local flm,FM = getFlightMode()	-- FlightMode
	valTxt = FM 

	xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.mid
		
	lcd.drawText(xCoord + 4, yCoord + 2, "Flight Mode", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.mid  + CUSTOM_COLOR) 
end


-------------------------------------------------  
-- TxBat ------------------------------- txbat --
------------------------------------------------- 
local function txbatWidget(xCoord, yCoord, cellHeight, name)
	local myTxBat = getValue("tx-voltage")


	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
		
	lcd.drawText(xCoord + 4, yCoord + 2, "TxBat", modeSize.sml)

	lcd.drawText(xTxt1, yTxt1, round(myTxBat,2), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "V", modeSize.sml + modeAlign.le)
end

------------------------------------------------- 
-- Timer ------------------------------- timer --
------------------------------------------------- 
local function timerWidget(xCoord, yCoord, cellHeight, name)
	local teleV_tmp = model.getTimer(0) -- Timer 1
	local myTimer = teleV_tmp.value
	
	local minute = math.floor(myTimer/60)
	local sec = myTimer - (minute*60)
	if sec > 9 then
		valTxt = string.format("%i",minute)..":"..string.format("%i",sec)
	else
		valTxt = string.format("%i",minute)..":0"..string.format("%i",sec)
	end 
	
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	-- lcd.drawText(xCoord + 4, yCoord + 2, "Timer", modeSize.sml) 
	local myTxBat = getValue("tx-voltage")
	lcd.drawText(xCoord + 4, yCoord + 2, ( "TxBat -- " .. round(myTxBat,3)), modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "m:s", modeSize.sml + modeAlign.le) 
end



------------------------------------------------- 
-- Armed/Disarmed (Switch) ------------- armed --
------------------------------------------------- 
local function armedWidget(xCoord, yCoord, cellHeight, name)
	local switchPos = getValueOrDefault(useArm)
	if switchPos < 50 then
		valTxt = "Disarmed"
		lcd.setColor(CUSTOM_COLOR, col_std)	
	else
		valTxt = "Armed" 
		lcd.setColor(CUSTOM_COLOR, col_alm)	
	end 

	xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.mid
    modelName = model.getInfo().name
    local flm,FM = getFlightMode()	-- FlightMode
	valFlt = ("Flt Mode -- " ..  FM)
	--lcd.drawText(xCoord + 4, yCoord + 2, modelName , modeSize.sml) 
	lcd.drawText(xCoord + 4, yCoord + 2, valFlt , modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.mid  + CUSTOM_COLOR) 
end

------------------------------------------------- 
-- Lost Copter sound (Switch) ----------- lost --
------------------------------------------------- 
local function lostWidget(xCoord, yCoord, cellHeight, name)
	local switchPos = getValueOrDefault(useBpr)
	if switchPos <= 0 then
		valTxt = "Off"
		lcd.setColor(CUSTOM_COLOR, col_std)	
	else
		valTxt = "On" 
		lcd.setColor(CUSTOM_COLOR, col_alm)	
	end

	xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.mid
	lcd.drawText(xCoord + 4, yCoord + 2, "Rescue", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.mid  + CUSTOM_COLOR) 
	
	local satImageResource = ""
	local numSats = sats
	if numSats > 7 and numSats > 0 then
	    satImageResource = imagePath.."fix4.png"
	elseif numSats > 0 and numSats < 8 then
		satImageResource = imagePath.."fix3.png"
	else 
	    satImageResource = imagePath.."fix1.png"
	end
	   
	satImage = Bitmap.open(satImageResource)
	local w, h = Bitmap.getSize(satImage)
	xPic= xCoord + cellWide - w - 2; yPic= yCoord + 5
	lcd.drawBitmap(satImage, xPic, yPic)
end




------------------------------------------------- 
-- Battery ----------------- battery, battery1 --
-------------------------------------------------
local function batteryWidget(xCoord, yCoord, cellHeight, name)
	--local myVoltageID = getTelemetryId("RxBt")
	-- local myVoltage = getValueOrDefault("RxBt")
	local myVoltage = cellVoltage
	local fourLow = 13.9     -- 4 cells 4s | rning
    local fourHigh = 16.8    -- 4 cells 4s
    local sixLow = 20.9    -- 3 cells 3s | Warning
    local sixHigh = 25.2   -- 3 cells 3s
	local battCell = "4S"
	local battType = 4
	local myPercent = 0
    	
	if myVoltage > 3 then
        battType = math.ceil(myVoltage/4.2)
		if battType == 4 then
			battCell = "4S"
			myPercent = math.floor((myVoltage-fourLow) * (100/(fourHigh-fourLow)))
		end
		if battType == 6 then
			battCell = "6S"
			myPercent = math.floor((myVoltage-sixLow) * (100/(sixHigh-sixLow)))
		end
	end
	
	lcd.drawText(xCoord + 4, yCoord + 2,battCell ..  " Lipo", modeSize.sml)
		
	if name == "battery" then
		xTxt1 = xCoord+(cellWide * 0.5)-50; yTxt1 = cellHeight + 55; xTxt2 = xCoord + (cellWide/2)-25; yTxt2 = cellHeight+90; 
		lcd.setColor(CUSTOM_COLOR, col_std)
			
		lcd.drawText(xTxt1, yTxt1, battCell.."-"..lipoCapa, modeSize.mid + CUSTOM_COLOR)
		lcd.drawText(xTxt2, yTxt2, myPercent.."%", modeSize.dbl + CUSTOM_COLOR)
	else
		xTxt1 = xCoord+(cellWide * 0.5)-50; yTxt1 = cellHeight -10; xTxt2 = xCoord + (cellWide/2)-65; yTxt2 = cellHeight + 20; 
		lcd.setColor(CUSTOM_COLOR, col_std)
		
		lcd.drawText(xTxt1, yTxt1, myPercent.."%", modeSize.mid + CUSTOM_COLOR)
		lcd.drawText(xTxt2, yTxt2, round(myVoltage,1), modeSize.dbl + CUSTOM_COLOR)
	end
	
	-- icon Batterie -----
	if myPercent > 90 then batIndex = 7
		elseif myPercent > 70 then batIndex = 6
		elseif myPercent > 50 then batIndex = 5
		elseif myPercent > 30 then	batIndex = 4
		elseif myPercent > 20 then batIndex = 3
		elseif myPercent >10 then batIndex = 2
		else batIndex = 1
	end
	
	if batName ~= imagePath.."bat"..batIndex..".png" then
		batName = imagePath.."bat"..batIndex..".png"
		batImage = Bitmap.open(batName)
	end
	
	w, h = Bitmap.getSize(batImage)
	
	if name == "battery" then
		xPic=xCoord + (cellWide * 0.5) - (w * 0.5); yPic= yCoord - h*0.5 + cellHeight*0.5
	else
		xPic=xCoord + (cellWide * 0.5) + 15; yPic= yCoord - h*0.5 + cellHeight*0.35
	end
	
	lcd.drawBitmap(batImage, xPic, yPic)
end

------------------------------------------------- 
-- LQ -------------------------- RQLY --
------------------------------------------------- 
local function rqlyWidget(xCoord, yCoord, cellHeight, name)

	local myRQLY = rqly     
	lcd.drawText(xCoord + 4, yCoord + 2, "Link Quality", modeSize.sml)
	
	local rfmdVal
	if rfmd == 2 then rfmdVal = "150hz"
	elseif
	    rfmd ==1 then rfmdVal = "50hz"
	else 
	    rfmdVal = "4hz"
	end
		
	
	xTxt1 = xCoord + cellWide * xCorr.value1; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.drawText(xTxt1, yTxt1, round(myRQLY), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "%", modeSize.sml + modeAlign.le)
	lcd.drawText(xCoord + 20, yCoord + 90, "update rate " .. rfmdVal , modeSize.sml)
	-- Icon
	
		if myRQLY <70 then rssiIndex = 1
		elseif
			myRQLY <=72 then rssiIndex = 2
		elseif
			myRQLY <=74 then rssiIndex = 3
		elseif
			myRQLY <=78 then rssiIndex = 4
		elseif
			myRQLY <=80 then rssiIndex = 5
		elseif
			myRQLY <=82 then rssiIndex = 6
		elseif
			myRQLY <=84 then rssiIndex = 7
		elseif
			myRQLY <=86 then rssiIndex = 8
		elseif
			myRQLY <=88 then rssiIndex = 9
		elseif
			myRQLY <=90 then rssiIndex = 10
		elseif
			myRQLY <=94 then rssiIndex = 11
		else
			rssiIndex = 11
		end
			
		if rssiName ~= imagePath.."rssi"..rssiIndex..".png" then
			rssiName = imagePath.."rssi"..rssiIndex..".png"
			rssiImage = Bitmap.open(rssiName)
		end
		
		local w, h = Bitmap.getSize(rssiImage)
		xPic= xCoord + cellWide - w - 2; yPic= yCoord + 5
		lcd.drawBitmap(rssiImage, xPic, yPic)
end

------------------------------------------------- 
-- rsnr --------------------------  --
------------------------------------------------- 
local function rsnrWidget(xCoord, yCoord, cellHeight, name)
	local myRsnr = rsnr	
	lcd.drawText(xCoord + 4, yCoord + 2, "RSNR", modeSize.sml)	
	xTxt1 = xCoord + 85  ; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)	
	lcd.drawText(xTxt1 , yTxt1, round(myRsnr), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "db", modeSize.sml + modeAlign.le)	
end
------------------------------------------------- 
-- RSSI -------------------------- rssi, rssi1 --
------------------------------------------------- 
local function rssiWidget(xCoord, yCoord, cellHeight, name)

	local myRssi = rssi
	local myMinRssi = rss1min 
	
	lcd.drawText(xCoord + 4, yCoord + 2, "RSSI", modeSize.sml)
	
	if name == "rssi" then
		xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
		lcd.setColor(CUSTOM_COLOR, col_std)
		lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMinRssi), modeSize.sml + modeAlign.ri)
	else
		xTxt1 = xCoord + cellWide * xCorr.value1; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
		lcd.setColor(CUSTOM_COLOR, col_std)
		lcd.drawText(xCoord + cellWide - 70, yCoord + 2, round(myMinRssi), modeSize.sml + modeAlign.ri)
	end
		
	lcd.drawText(xTxt1, yTxt1, round(myRssi), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "db", modeSize.sml + modeAlign.le)
	
	-- Icon RSSI -----
		
	    if myRssi <-110 then rssiIndex = 1
		elseif
			myRssi <= -95 then rssiIndex = 2
		elseif
			myRssi <= -90 then rssiIndex = 3
		elseif
			myRssi <= -88 then rssiIndex = 4
		elseif
			myRssi <= -84 then rssiIndex = 5
		elseif
			myRssi <= -82 then rssiIndex = 6
		elseif
			myRssi <= -75 then rssiIndex = 7
		elseif
			myRssi <= -70 then rssiIndex = 8
		elseif
			myRssi <= -58 then rssiIndex = 9
		elseif
			myRssi <= -34 then rssiIndex = 10
		elseif
			myRssi <= -15  then rssiIndex = 11
		else
			rssiIndex = 1
		end
	
 
		if rssiName ~= imagePath.."rssi"..rssiIndex.."f.png" then
			rssiName = imagePath.."rssi"..rssiIndex.."f.png"
			rssiImage = Bitmap.open(rssiName)
		end

		local w, h = Bitmap.getSize(rssiImage)
		xPic= xCoord + cellWide - w - 2; yPic= yCoord + 5
		lcd.drawBitmap(rssiImage, xPic, yPic)
end


-- ####################### Call Widgets #########################
 
local function callWidget(name, xPos, yPos, y1Pos)
	if (xPos ~= nil and yPos ~= nil) then
		if (name == "battery") or (name == "battery1") then
			batteryWidget(xPos, yPos, y1Pos, name)
		elseif (name == "rsnr") then
			rsnrWidget(xPos, yPos, y1Pos, name)		
		elseif (name == "rqly")  then
			rqlyWidget(xPos, yPos, y1Pos, name)	
		elseif (name == "rssi") or (name == "rssi1") then
			rssiWidget(xPos, yPos, y1Pos, name)	
		elseif (name == "fltmd") then
			fltmdWidget(xPos, yPos, y1Pos, name)		
		elseif (name == "lost") then
			lostWidget(xPos, yPos, y1Pos, name)
		elseif (name == "armed") then
			armedWidget(xPos, yPos, y1Pos, name)
		elseif (name == "timer") then
			timerWidget(xPos, yPos, y1Pos, name)			
		elseif (name == "txbat") then
			txbatWidget(xPos, yPos, y1Pos, name)	
		else
			return
		end
	end
end

-- ############################# Build Grid #################################

local function buildGrid(def, thisZone)

	local sumX = thisZone.zone.x
	local sumY = thisZone.zone.y
	
	noCol = # def 	-- Anzahl Spalten berechnen
	cellWide = (thisZone.zone.w / noCol) - 1
				
	-- Rectangle
	if transparency  ~= 1 then 
	    usebckgrnd = lcd.RGB(90, 153, 225)
	  	lcd.setColor(CUSTOM_COLOR, usebckgrnd)
		lcd.drawFilledRectangle(thisZone.zone.x, thisZone.zone.y, thisZone.zone.w, thisZone.zone.h, CUSTOM_COLOR)
		lcd.drawRectangle(thisZone.zone.x, thisZone.zone.y, thisZone.zone.w, thisZone.zone.h, 0, 2)
	else
		lcd.drawRectangle(thisZone.zone.x, thisZone.zone.y, thisZone.zone.w, thisZone.zone.h, 0, 2)
	end
	
	-- Vertical lines
	if noCol == 2 then
		lcd.drawLine(sumX + cellWide, sumY, sumX + cellWide, sumY + thisZone.zone.h - 1, SOLID, 0)
	elseif noCol == 3 then
		lcd.drawLine(sumX + cellWide, sumY, sumX + cellWide, sumY + thisZone.zone.h - 1, SOLID, 0)
		lcd.drawLine(sumX + cellWide*2, sumY, sumX + cellWide*2, sumY + thisZone.zone.h - 1, SOLID, 0)
	end
	
	-- Horizontal lines and calling single widgets
	for i=1, noCol, 1
	do
	
	local tempCellHeight = thisZone.zone.y + (math.floor(thisZone.zone.h / # def[i])*0.35)
		for j=1, # def[i], 1
		do
			-- Horizontal Linen
			if j ~= 1 then
				lcd.drawLine(sumX, sumY, sumX + cellWide, sumY, SOLID, 0)
			end
			
			-- Widgets
			callWidget(def[i][j], sumX , sumY , tempCellHeight)
			sumY = sumY + math.floor(thisZone.zone.h / # def[i])
			tempCellHeight = tempCellHeight + math.floor(thisZone.zone.h / # def[i])
		end
		
		-- reset values
		sumY = thisZone.zone.y
		sumX = sumX + cellWide
	end
end

local function background(thisZone)
end

local function refresh(thisZone)
	getTelemetryValues()
	widget()
	buildGrid(widgetDefinition, thisZone)
end

return { name="crsfTelem", options=options, create=create, update=update, refresh=refresh, background=background }
