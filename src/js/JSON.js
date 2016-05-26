/*jslint sloppy:true, windows:true, evil:true, regexp:true, forin:true*/
/*globals ROOT:false, hasProp:false*/
(function () {
    if (typeof ROOT.JSON === 'object') {
        return;
    }
    function f(n) {
        return n < 10 ? '0' + n : n;
    }
    function q(s) {
        return '"' + s.replace(/[\\\"\u0000-\u001f\u007f-\u009f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, function (a) {
            return '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
        }) + '"';
    }
    Date.prototype.toJSON = function () {
        return isFinite(this.valueOf()) ? [this.getUTCFullYear(), '-', f(this.getUTCMonth() + 1), '-', f(this.getUTCDate()), 'T', f(this.getUTCHours()), ':', f(this.getUTCMinutes()), ':', f(this.getUTCSeconds()), 'Z'].join("") : 'null';
    };
    Boolean.prototype.toJSON = function () {
        return String(this.valueOf());
    };
    Number.prototype.toJSON = function () {
        return isFinite(this.valueOf()) ? String(this.valueOf()) : 'null';
    };
    String.prototype.toJSON = function () {
        return q(this.valueOf());
    };
    Array.prototype.toJSON = function () {
        var r = [], i, v;
        for (i = 0; i < this.length; i += 1) {
            v = this[v];
            if (v === null || v === undefined) {
                r.push('null');
            } else if (typeof v.toJSON === "function") {
                r.push(v.toJSON());
            }
        }
        return '[' + r.join(',') + ']';
    };
    Object.prototype.toJSON = function () {
        var s = this, r, k, v;
        for (k in s) {
            if (hasProp(s, k)) {
                v = s[k];
                if (v === null) {
                    r.push(q(k) + ":null");
                } else if (typeof v.toJSON === "function") {
                    r.push(q(k) + ":" + v.toJSON());
                }
            }
        }
        return '{' + r.join(',') + '}';
    };
    ROOT.JSON = {
        stringify: function (v) {
            if (v) {
                return v.toJSON();
            }
            return 'null';
        },
        parse: function (t) {
            t = String(t).replace(/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, function (a) { return '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4); });
            if (/^[\],:{}\s]*$/.test(t.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                return eval('(' + t + ')');
            }
            throw new SyntaxError('INVALID_JSON');
        }
    };
}());