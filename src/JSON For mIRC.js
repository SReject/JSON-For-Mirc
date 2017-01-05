/*jslint for:true*/
/*globals ActiveXObject, JSONCreate*/
(function() {

    // es5 .forEach() polyfill
    Array.prototype.forEach = function (callback) {
        for (var i = 0; i < this.length; i += 1) {
            callback.call(this, this[i], i);
        }
    };

    // es5 .find() polyfill
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

    // returns the type of an input
    function getType(obj) {
        return Object.prototype.toString.call(obj).match(/^\[object ([^\]]+)\]$/)[1].toLowerCase();
    }

    // returns true if an input object has the specified property
    function hasOwnProp(obj, property) {
        return Object.prototype.hasOwnProperty.call(obj, property);
    }

    // checks if an instance has a pending http request
    // if not, an error is thrown, otherwise the instance is returned
    function httpPending(self) {
        if (self.type !== 'http') {
            throw new Error('HTTP_NOT_INUSE');
        }
        if (self.state !== 'http_pending') {
            throw new Error('HTTP_NOT_PENDING');
        }
        return self.http;
    }

    // Checks if an instance http request has completed
    // if not, an error is thrown, otherwise the instance is returned
    function httpDone(self) {
        if (self.type !== 'http') {
            throw new Error('HTTP_NOT_INUSE');
        }
        if (self.state !== 'done') {
            throw new Error('HTTP_PENDING');
        }
        return self.http;
    }

    // es5 JSON polyfill
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
    JSON.stringify = function (value) {
        var type = getType(value), output = '[';
        if (value === undefined) {
            return;
        }
        if (value === null) {
            return 'null';
        }
        if (type === 'function') {
            return;
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
            }); + '"';
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

    function JSONWrapper(parent, json) {
        if (parent === undefined) {
            parent = {};
        }
        this.state = parent.state || 'init';
        this.type = parent.type || 'text';
        this.error = parent.error || false;
        this.input = parent.input;
        this.isChild = false;
        this.json = parent.json;
        this.http = parent.http || {
            method: 'GET',
            url: '',
            headers: [],
            data: null
        };
        if (json !== undefined) {
            this.isChild = true;
            this.json = json;
        }
    }

    JSONWrapper.prototype = {
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
            var request;
            this.state = 'done';
            try {
                if (this.type === 'http') {
                    request = new ActiveXObject(JSONWrapper.HTTP);
                    request.open(this.http.method, this.http.url, false);
                    this.http.headers.forEach(function (header) {
                        request.setRequestHeader(header[0], header[1]);
                    });
                    request.send(this.http.data);
                    this.input = request.responseText;
                    this.http.response = request;
                }
                this.json = {
                    path: [],
                    value: JSON.parse(this.input)
                };
                return this;
            } catch (e) {
                this.error = e.message;
                throw e;
            }
        },

        walk: function() {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            var args = Array.prototype.slice.call(arguments),
                type = getType(this.json.value),
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
                return this;
            }
            if (type !== 'array' && type !== 'object') {
                throw new Error('ILLEGAL_REFERENCE');
            }
            member = String(args.shift());
            if (fuzzy && /^[~=]./.test(member)) {
                doFuzzy = '~' === member.charAt(0);
                member = member.replace(/^[~=]\x20*/, '');
                if (doFuzzy && type === 'object') {
                    keys = Object.keys(this.json.value);
                    if (/^\d+$/.test(member)) {
                        member = parseInt(member, 10);
                        if (member >= keys.length) {
                            throw new Error('FUZZY_INDEX_NOT_FOUND');
                        }
                        member = keys[member];
                    } else if (!hasOwnProp(this.json.value, member)) {
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
            if (hasOwnProp(this.json.value, member)) {
                path = this.json.path.slice();
                path.push(member);
                result = new JSONWrapper(this, {
                    path: path,
                    value: this.json.value[member]
                });
                args.unshift(fuzzy);
                return result.walk.apply(result, args);
            }
            throw new Error('REFERENCE_NOT_FOUND');
        },

        forEach: function () {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            var self = this,
                args = Array.prototype.slice.call(arguments),
                res = [];
            function resultAdd(member) {
                var path = self.json.path.slice(),
                    ref;
                path.push(member);
                ref = new JSONWrapper(self, {
                    path: path,
                    value: self.json.value[member]
                });
                try {
                    if (args.length > 0) {
                        ref = ref.walk.apply(ref, args.slice());
                    }
                    res.push(ref)
                } catch (ignore) { }
            }

            if (this.jsonType() === 'object') {
                Object.keys(this.json.value).forEach(resultAdd);
                return result;
            }

            if (this.jsonType() === 'array') {
                this.json.value.forEach(function (ignore, index) {
                    resultAdd(index);
                });
                return res;
            }
            throw new Error('ILLEGAL_REFERENCE');
        },

        jsonType: function () {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            return getType(this.json.value);
        },

        jsonPath: function () {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            var result = '';
            this.json.path.forEach(function (item) {
                result += (result ? ' ' : '') + String(item).replace(/([\\ ])/g, function (chr) {
                    return ' ' === chr ? '\s' : '\\';
                });
            });
            return result;
        },

        jsonLength: function () {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            var type = getType(this.json.value);
            if (type === 'string' || type === 'array') {
                return this.json.value.length;
            }
            if (type === 'object') {
                return Object.keys(this.json.value).length;
            }
            throw new Error('INVALID_TYPE');
        },

        jsonValue: function () {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            if (this.jsonType() === 'number' && /./.test(String(this.json.value))) {
                return String(this.json.value);
            }
            return this.json.value;
        },

        jsonString: function () {
            if (this.state !== 'done' || this.error) {
                throw new Error('NOT_PARSED');
            }
            return JSON.stringify(this.json.value);
        },

        jsonDebugString: function () {
            var result = {
                state: this.state,
                input: this.input,
                type: this.type,
                error: this.error,
                http: {
                    url: this.http.url,
                    method: this.http.method,
                    headers: this.http.headers,
                    data: this.http.data
                },
                isChild: this.isChild,
                json: this.json
            };
            if (this.type === "http" && this.state === "done") {
                result.http.response = {
                    status: this.http.response.status,
                    statusText: this.http.response.statusText,
                    headers: (this.http.response.getAllResponseHeaders()).split(/[\r\n]+/g),
                    responseText: this.http.response.responseText
                };
            }
            return JSON.stringify(result);
        }
    };

    JSONWrapper.HTTP = ['MSXML2.SERVERXMLHTTP.6.0', 'MSXML2.SERVERXMLHTTP.3.0', 'MSXML2.SERVERXMLHTTP'].find(function (xhr) {
        try {
            var test = new ActiveXObject(xhr);
            return xhr;
        } catch (ignore) {}
    });

    JSONCreate = function(type, source) {
        var self = new JSONWrapper();
        self.type = (type || 'text').toLowerCase();
        self.state = 'done';
        if (self.type === 'http') {
            if (!JSONWrapper.HTTP) {
                self.error = 'HTTP_NOT_FOUND';
                throw new Error('HTTP_NOT_FOUND');
            }
            self.state = 'http_pending';
            self.http.url = source;
        } else {
            self.state = 'parse_pending';
            self.input = source;
        }
        return self;
    };
}());