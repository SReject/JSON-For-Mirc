/*jslint windows:true, sloppy:true, forin:true, regexp:true*/
/*globals ROOT:true, trim:true, hasProp:true*/

// Store a reference to the root/global variable
ROOT = this;

// Trims excess whitespace
function trim(input) {
    return String(input).replace(/(?:^\s+)|(\s+$)/g, "");
}

// Returns true if the object has the specified property
function hasProp(obj, prop) {
    return Object.prototype.hasOwnProperty.call(obj, prop);
}

// Returns the constructor for the specified object
function getType(obj) {
    return (Object.prototype.toString.call(obj)).replace(/\[\S+ (.*)\]$/i, function (text, typeText) {
        typeText = typeText.toLowerCase();
        if (typeText === "undefined") {
            return 'null';
        }
        return typeText;
    });
}

// Object.keys polyfill
Object.prototype.keys = function (self) {
    var key, keys = [];
    self = self || this;
    for (key in self) {
        if (hasProp(self, key) && self[key] !== undefined) {
            keys.push(key);
        }
    }
    return keys;
};