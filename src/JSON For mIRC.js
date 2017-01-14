/*jslint for:true*/
/*globals ActiveXObject, JSONCreate*/
(function() {
    
    // returns the type of an input
    function getType(obj) {
        if (obj === null) return 'null';
        return Object.prototype.toString.call(obj).match(/^\[object ([^\]]+)\]$/)[1].toLowerCase();
    }

    // returns true if an input object has the specified property
    function hasOwnProp(obj, property) {
        return Object.prototype.hasOwnProperty.call(obj, property);
    }
    
    // Checks if an instance has been parsed
    // if not, an error is thrown otherwise the instance is returned
    function parsed(self) {
        if (self._state !== 'done' || self._error || !self._parse) {
            throw new Error('NOT_PARSED');
        }
        return self;
    }

    // checks if an instance has a pending http request
    // if not, an error is thrown, otherwise the instance is returned
    function httpPending(self) {
        if (self._type !== 'http') {
            throw new Error('HTTP_NOT_INUSE');
        }
        if (self._state !== 'http_pending') {
            throw new Error('HTTP_NOT_PENDING');
        }
        return self._http;
    }

    // Checks if an instance http request has completed
    // if not, an error is thrown, otherwise the instance is returned
    function httpDone(self) {
        if (self._type !== 'http') {
            throw new Error('HTTP_NOT_INUSE');
        }
        if (self._state !== 'done') {
            throw new Error('HTTP_PENDING');
        }
        return self._http;
    }

    // es5 .forEach() polyfill
    Array.prototype.forEach = function (callback) {
        for (var i = 0; i < this.length; i += 1) {
            callback.call(this, this[i], i);
        }
    };

    // es6 .find() polyfill
    Array.prototype.find = function (callback) {
        for (var i = 0; i < this.length; i += 1) {
            if (callback.call(this, this[i])) {
                return this[i];
            }
        }
    };

    // es5 .keys() polyfill
    Object.keys = function (obj) {
        var keys = [], key;
        for (key in obj) {
            if (hasOwnProp(obj, key)) {
                keys.push(key);
            }
        }
        return keys;
    };

    // es5 JSON.parse polyfill
    (JSON = {}).parse = function(i) {
        try {
            i = String(i).replace(/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, function(c) {
                return '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4);
            });
            if (/^[\],:{}\s]*$/.test(i.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                return eval('(' + i + ')');
            }
        } catch (e) {}
        throw new Error("INVALID_JSON");
    };
    
    // es5 JSON.stringify polyfill
    JSON.stringify = function (value) {
        var type = getType(value),
            output = '[';
        if (value === undefined || type === 'function') {
            return;
        }
        if (value === null) {
            return 'null';
        }
        if (type === 'number') {
            return isFinite(value) ? value.toString() : 'null';
        }
        if (type === 'boolean') {
            return value.toString();
        }
        if (type === 'string') {
            return '"' + value.replace(/[\\"\u0000-\u001F\u2028\u2029]/g, function(chr) {
                return {'"': '\\"', '\\': '\\\\', '\b': '\\b', '\f': '\\f', '\n': '\\n', '\r': '\\r', '\t': '\\t'}[chr] || '\\u' + (chr.charCodeAt(0) + 0x10000).toString(16).substr(1);
            }) + '"';
        }
        if (type === 'array') {
            value.forEach(function (item, index) {
                item = JSON.stringify(item);
                if (item) {
                    output += (index ? ',' : '') + item;
                }
            });
            return output + ']';
        }
        output = [];
        Object.keys(value).forEach(function (key) {
            var res = JSON.stringify(value[key]);
            if (res) {
                output.push(JSON.stringify(key) + ':' + res);
            }
        });
        return '{' + output.join(',') + '}';
    };
    
    
    HTTPObject = ['MSXML2.SERVERXMLHTTP.6.0', 'MSXML2.SERVERXMLHTTP.3.0', 'MSXML2.SERVERXMLHTTP'].find(function (xhr) {
        try {
            var test = new ActiveXObject(xhr);
            return xhr;
        } catch (ignore) {}
    });

    function JSONWrapper(parent, json) {
        if (parent === undefined) {
            parent = {};
        }
        if (json === undefined) {
            this._isChild = false;
            this._json = parent._json || {};
        } else {
            this._isChild = true;
            this._json = json;
        }
        this._state = parent._state || 'init';
        this._type = parent._type || 'text';
        this._parse = parent._parse === false ? false : true;
        this._error = parent._error || false;
        this._input = parent._input;
        this._http = parent._http || {
            method: 'GET',
            url: '',
            headers: [],
            data: null,
            timeout: 85000
        };
    }

    JSONWrapper.prototype = {
        state: function () {
            return this._state;
        },

        error: function () {
            return this._error.message;
        },

        inputType: function () {
            return this._type;
        },

        input: function () {
            return this._input || null;
        },

        httpParse: function () {
            return this._parse;
        },

        httpSetMethod: function (method) {
            httpPending(this).method = method;
        },

        httpSetHeader: function (header, value) {
            httpPending(this).headers.push([header, value]);
        },

        httpSetData: function (data) {
            httpPending(this).data = data;
        },

        httpStatus: function() {
            return httpDone(this).response.status;
        },

        httpStatusText: function () {
            return httpDone(this).response.statusText;
        },

        httpHeaders: function() {
            return httpDone(this).response.getAllResponseHeaders();
        },

        httpHeader: function (header) {
            return httpDone(this).response.getResponseHeader(header);
        },

        httpBody: function () {
            return httpDone(this).response.responseText;
        },

        httpHead: function () {
            return this.httpStatus() + ' ' + this.httpStatusText() + '\r\n' + this.httpHeaders();
        },

        httpResponse: function () {
            return this.httpHead() + '\r\n\r\n' + this.httpBody();
        },

        parse: function () {
            this.parse = function () {
                throw new Error('PARSE_NOT_PENDING');
            };
            try {
                this._state = 'done';
                if (this._type === 'http') {
                    try {
                      var request = new ActiveXObject(HTTPObject);
                      request.open(this._http.method, this._http.url, false);
                      this._http.headers.forEach(function (header) {
                          request.setRequestHeader(header[0], header[1]);
                      });
                      request.send(this._http.data);
                    } catch (e) {
                        e.message = "HTTP: " + e.message;
                        throw e;
                    }
                    this._http.response = request;
                    if (!this._parse) {
                        return this;
                    }
                    this._input = request.responseText;
                }
                this._json = {
                    path: [],
                    value: JSON.parse(this._input)
                };
                return this;
            } catch (e) {
                this._error = e.message;
                throw e;
            }
        },

        walk: function() {
            var self = parsed(this),
                args = Array.prototype.slice.call(arguments),
                type = getType(self._json.value),
                fuzzy = false,
                path = [],
                keys,
                member,
                doFuzzy,
                result;
            if (typeof args[0] === 'boolean') {
                fuzzy = args.shift();
            }
            if (!args.length) {
                return self;
            }
            if (type !== 'array' && type !== 'object') {
                throw new Error('ILLEGAL_REFERENCE');
            }
            member = String(args.shift());
            if (fuzzy && /^[~=]./.test(member)) {
                doFuzzy = '~' === member.charAt(0);
                member = member.replace(/^[~=]\x20*/, '');
                if (doFuzzy && type === 'object') {
                    keys = Object.keys(self._json.value);
                    if (/^\d+$/.test(member)) {
                        member = parseInt(member, 10);
                        if (member >= keys.length) {
                            throw new Error('FUZZY_INDEX_NOT_FOUND');
                        }
                        member = keys[member];
                    } else if (!hasOwnProp(self._json.value, member)) {
                        member = member.toLowerCase();
                        member = keys.find(function (item) {
                            return item.toLowerCase() === member;
                        });
                        if (member === undefined) {
                            throw new Error('FUZZY_MEMBER_NOT_FOUND');
                        }
                    }
                }
            }
            if (hasOwnProp(self._json.value, member)) {
                path = self._json.path.slice();
                path.push(member);
                result = new JSONWrapper(self, {
                    path: path,
                    value: self._json.value[member]
                });
                args.unshift(fuzzy);
                return result.walk.apply(result, args);
            }
            throw new Error('REFERENCE_NOT_FOUND');
        },

        forEach: function () {
            var self = parsed(this),
                args = Array.prototype.slice.call(arguments),
                type = self.type(),
                res = [],
                maxDepth = args[0] ? Infinity : 1;

            args.shift();

            function addResult(item, path) {
                var ref = new JSONWrapper(self, {
                        path: path,
                        value: item
                    });

                if (maxDepth !== Infinity && args.length > 1) {
                    ref = ref.walk.apply(ref, args.slice(0))
                }
                res.push(ref);
            }

            function walk(item, path, depth) {
                var type = getType(item);
                path = path.slice(0);

                if (depth > maxDepth) {
                    addResult(item, path);

                } else if (type === 'object') {
                    Object.keys(item).forEach(function (key) {
                        var kpath = path.slice(0);
                        kpath.push(key)
                        walk(item[key], kpath, depth + 1);
                    });

                } else if (type === 'array') {
                    item.forEach(function (value, index) {
                        var kpath = path.slice(0);
                        kpath.push(index);
                        walk(value, kpath, depth +1);
                    });

                } else {
                    addResult(item, path);
                }
            }

            if (type !== 'object' && type !== 'array') {
                throw new Error('ILLEGAL_REFERENCE');
            }
            walk(self._json.value, self._json.path.slice(0), 1);
            return res;
        },

        type: function () {
            return getType(parsed(this)._json.value);
        },

        isContainer: function () {
            return (this.type() === "object" || this.type() === "array");
        },

        pathLength: function () {
            return parsed(this)._json.path.length;
        },
        
        pathAtIndex: function (index) {
            return parsed(this)._json.path[index];
        },

        path: function () {
            var result = '';
            parsed(this)._json.path.forEach(function (item) {
                result += (result ? ' ' : '') + String(item).replace(/([\\ ])/g, function (chr) {
                    return ' ' === chr ? '\s' : '\\';
                });
            });
            return result;
        },

        length: function () {
            var self = parsed(this),
                type = self.type();
            if (type === 'string' || type === 'array') {
                return self._json.value.length;
            }
            if (type === 'object') {
                return Object.keys(self._json.value).length;
            }
            throw new Error('INVALID_TYPE');
        },

        value: function () {
            parsed(this);
            if (this.type() === 'number' && /./.test(String(this._json.value))) {
                return String(this._json.value);
            }
            return this._json.value;
        },

        string: function () {
            return JSON.stringify(parsed(this)._json.value);
        },

        debug: function () {
            var result = {
                state: this._state,
                input: this._input,
                type: this._type,
                error: this._error,
                parse: this._parse,
                http: {
                    url: this._http.url,
                    method: this._http.method,
                    headers: this._http.headers,
                    data: this._http.data,
                    readAs: this._http.readAs
                },
                isChild: this._isChild,
                json: this._json
            };
            if (this._type === "http" && this._state === "done") {
                result.http.response = {
                    status: this._http.response.status,
                    statusText: this._http.response.statusText,
                    headers: (this._http.response.getAllResponseHeaders()).split(/[\r\n]+/g),
                    responseText: this._http.response.responseText
                };
            }
            return JSON.stringify(result);
        }
    };

    JSONCreate = function(type, source, noparse) {
        var self = new JSONWrapper();
        self._state = 'init';
        self._type = (type || 'text').toLowerCase();

        if (self._type === 'http') {
            if (!JSONWrapper.HTTP) {
                self._error = 'HTTP_NOT_FOUND';
                throw new Error('HTTP_NOT_FOUND');
            }
            if (noparse) {
                self._parse = false;
            }
            self._state = 'http_pending';
            self._http.url = source;
        } else {
            self._state = 'parse_pending';
            self._input = source;
        }
        return self;
    };
}());