/*jslint windows: true, sloppy: true */
/*globals trim: true, formatResult: true*/

// trims excess whitespace
trim = function (input) {
  return String(input).replace(/(?:^\s+)|(\s+$)/g, "");
};

// formats results so mIRC can understand them
formatResult = function (result, error) {
  return {
    result: error ? null : (result || true),
    error: error | false
  }
};