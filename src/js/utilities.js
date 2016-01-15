/*jslint windows:true, sloppy:true*/
/*globals trim:true, hasProp:true, formatResult:true*/

// Trims excess whitespace
function trim(input) {
    return String(input).replace(/(?:^\s+)|(\s+$)/g, "");
}

// Returns true of the specified object has the specified property
function hasProp(obj, prop) {
    return Object.prototype.hasOwnProperty.call(obj, prop);
}

// Formats results so mIRC can understand them
function formatResult(result, error) {
    return {
        result: error ? null : (result || true),
        error: error || false
    };
}

// Object.keys polyfill
Object.prototype.keys = function (self) {
    var key, keys = [];
    self = self || this;
    for (key in self) {
        if (hasProp(self, key)) {
            keys.push(key);
        }
    }
    return key;
}