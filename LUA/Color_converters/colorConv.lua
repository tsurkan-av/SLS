local function cie_to_rgb(x, y)
	local z = 1.0 - x - y
	local X = (1 / y) * x
	local Z = (1 / y) * z
	--Convert to RGB using Wide RGB D65 conversion
	local red = X * 1.656492 - 0.354851 - Z * 0.255038
	local green	= -X * 0.707196 + 1.655397 + Z * 0.036152
	local blue = X * 0.051713 - 0.121364 + Z * 1.011530
	--If red, green or blue is larger than 1.0 set it back to the maximum of 1.0
	if (red > blue and red > green and red > 1.0) then
		green = green / red
		blue = blue / red
		red = 1.0
	elseif (green > blue and green > red and green > 1.0) then
		red = red / green
		blue = blue / green
		green = 1.0
	elseif (blue > red and blue > green and blue > 1.0) then
		red = red / blue
		green = green / blue
		blue = 1.0
  end
	--Reverse gamma correction
  if (red <= 0.0031308) then red = (12.92 * red) else red = ((1.0 + 0.055) * (red ^ (1.0 / 2.4)) - 0.055) end
  if (green <= 0.0031308) then green = (12.92 * green) else green = ((1.0 + 0.055) * (green ^ (1.0 / 2.4)) - 0.055) end
	if (blue <= 0.0031308) then blue = (12.92 * blue) else blue = ((1.0 + 0.055) * (blue ^ (1.0 / 2.4)) - 0.055) end
	--Convert normalized decimal to decimal
	red = math.abs(math.floor(red * 255 + 0.5))
	green = math.abs(math.floor(green * 255 + 0.5))
	blue = math.abs(math.floor(blue * 255 + 0.5))
	if not (red) then red = 0 end
	if not (green) then green = 0 end
	if not (blue) then blue = 0 end

	return red, green, blue
end
------------------------------------------------------------------
local function rgb_to_cie(red, green, blue)
	--Apply a gamma correction to the RGB values, which makes the color more vivid and more the like the color displayed on the screen of your device
	if (red / 255 > 0.04045) then red = (((red / 255 + 0.055) / (1.0 + 0.055)) ^ 2.4) else red = (red / 255 / 12.92) end
	if (green / 255 > 0.04045) then green	= (((green / 255 + 0.055) / (1.0 + 0.055)) ^ 2.4) else green	= (green / 255 / 12.92) end
	if (blue / 255 > 0.04045) then blue = (((blue / 255 + 0.055) / (1.0 + 0.055)) ^ 2.4) else blue = (blue / 255 / 12.92) end
	--RGB values to XYZ using the Wide RGB D65 conversion formula
	local X = red * 0.664511 + green * 0.154324 + blue * 0.162028
	local Y = red * 0.283881 + green * 0.668433 + blue * 0.047685
	local Z = red * 0.000088 + green * 0.072310 + blue * 0.986039
	--Calculate the xy values from the XYZ values
  local x = string.format("%.6g", tostring(X / (X + Y + Z)))
  local y = string.format("%.6g", tostring(Y / (X + Y + Z)))
	if not (x) then x = 0 end
	if not (y) then	y = 0	end

	return x, y
end



print(0.508, 0.239)
local r, g, b = cie_to_rgb(0.508, 0.239)
print(r,g,b)
local x, y = rgb_to_cie(r, g, b)
print(x,y)
r, g, b = cie_to_rgb(x,y)
print(r,g,b)




