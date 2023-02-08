/*------------------------------------------------------------------------*
https://github.com/mcwhittemore/rgb-to-int
This module takes a number between 0 and 16777215 inclusive and converts it into an rgb object.

Usage:
var intToRGB = require('int-to-rgb');
var rgb = intToRGB(2763306);
console.log(rgb)
*/
var errorMessage = 'Must provide an integer between 0 and 16777215';

module.exports = function(int) {
  if (typeof int !== 'number') throw new Error(errorMessage);
  if (Math.floor(int) !== int) throw new Error(errorMessage);
  if (int < 0 || int > 16777215) throw new Error(errorMessage);

  var red = int >> 16;
  var green = int - (red << 16) >> 8;
  var blue = int - (red << 16) - (green << 8);

  return {
    red: red,
    green: green,
    blue: blue
  }
}
/*-----------------------------------------------------------------------*/
/*------------------------------------------------------------------------*
https://github.com/mcwhittemore/rgb-to-int
This module takes an rgb object and converts it to a number between 0 and 16777215 inclusive
rgb values must be between 0 and 255 inclusive

Usage:
var rgbToInt = require('int-to-rgb');
var int = rgbToInt({
  red: 42,
  green: 42,
  blue: 42
});
console.log(int)
*/

var errorMessage = 'Must be an rgb object';

var check = function(rgb, name) {
  if (typeof rgb[name] !== 'number') throw new Error(errorMessage);
  if (rgb[name] < 0 || rgb[name] > 255) throw new Error(errorMessage);
}

module.exports = function(rgb) {
  if (typeof rgb !== 'object') throw new Error(errorMessage);
  check(rgb, 'red');
  check(rgb, 'green');
  check(rgb, 'blue');

  return rgb.red << 16 | rgb.green << 8 | rgb.blue;
}
/*--------------------------------------------------------------------*/