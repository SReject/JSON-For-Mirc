(function(root) {

    // use to create a binary stream
    var binaryStream = new ActiveXObject('ADODB.Stream');
    binaryStream.type = 2;
    binaryStream.open();
    binaryStream.charset = 'iso-8859-1';
    function binaryStreamReset() {
        binaryStream.position = 0;
        binaryStream.setEOS();
        binaryStream.type = 2;
        binaryStream.charset = 'iso-8859-1';
    }

    // es5 .forEach() semi-polyfill
    Array.prototype.forEach = function (callback) {
        for (var i = 0; i < this.length; i += 1) {
            callback.call(this, this[i], i);
        }
    };

    // es6 .find() semi-polyfill
    Array.prototype.find = function (callback) {
        for (var i = 0; i < this.length; i += 1) {
            if (callback.call(this, this[i])) {
                return this[i];
            }
        }
    };
    
    // http/web object detection
    HTTPObject = ['WinHttp.WinHttpRequest.5.1'].find(function (whr) {
        try {
            return new ActiveXObject(whr), whr;
        } catch (ignore) {}
    });

    // returns the type of an input
    function GETTYPE(obj) {
        if (obj === null) {
            return 'null';
        }
        return Object.prototype.toString.call(obj).match(/^\[object ([^\]]+)\]$/)[1].toLowerCase();
    }

    // Returns an array containing all of an object's own properties' key names
    function GETKEYS(obj) {
        var keys = [], key;
        for (key in obj) {
            if (HASKEY(obj, key)) {
                keys.push(key);
            }
        }
        return keys;
    }

    // returns true if an input object has the specified property
    function HASKEY(obj, property) {
        return Object.prototype.hasOwnProperty.call(obj, property);
    }

    // Checks if an instance has been parsed
    // if not, an error is thrown otherwise the instance is returned
    function PARSED(self) {
        if (self._state !== 'done' || self._error || !self._parse) {
            throw new Error('NOT_PARSED');
        }
        return self;
    }

    // checks if an instance has a pending http request
    // if not, an error is thrown, otherwise the instance is returned
    function HTTPPENDING(self) {
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
    function HTTPDONE(self) {
        if (self._type !== 'http') {
            throw new Error('HTTP_NOT_INUSE');
        }
        if (self._state !== 'done') {
            throw new Error('HTTP_PENDING');
        }
        return self._http;
    }

    // es5 JSON.stringify equivulant
    function STRINGIFY(value) {
        var type = GETTYPE(value),
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
                item = STRINGIFY(item);
                if (item) {
                    output += (index ? ',' : '') + item;
                }
            });
            return output + ']';
        }
        output = [];
        GETKEYS(value).forEach(function (key) {
            var res = STRINGIFY(value[key]);
            if (res) {
                output.push(STRINGIFY(key) + ':' + res);
            }
        });
        return '{' + output.join(',') + '}';
    }

    // JSON instance constructor
    function JSONInstance(parent, json) {
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
        this._type  = parent._type || 'text';
        this._parse = parent._parse === false ? false : true;
        this._error = parent._error || false;
        this._input = parent._input;
        this._http = parent._http || {
            method: 'GET',
            url: '',
            headers: [],
            insecure: false,
            redirects: true,

            hasData: false,
            dataLength: 0,
            dataType: 'application/x-www-form-urlencoded',
            data: null
        };
    }

    JSONInstance.prototype = {
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
            HTTPPENDING(this).method = method;
        },

        httpSetHeader: function (header, value) {
            var http = HTTPPENDING(this);

            var lcHeader = (header + "").toLowerCase();

            if (lcHeader === 'content-type') {
                http.dataType = value;

            } else if (lcHeader === 'content-length') {
                http.dataLength = value;

            } else {
                http.headers.push([header, value]);
            }
        },

        httpSetData: function (data, length) {
            var http = HTTPPENDING(this);

            if (data != null) {
                http.hasData = true;
                http.dataLength = length != null ? length : http.dataLength;
                http.data = data;
            }
        },

        httpStatus: function() {
            return HTTPDONE(this).response.status;
        },

        httpStatusText: function () {
            return HTTPDONE(this).response.statusText;
        },

        httpHeaders: function() {
            return HTTPDONE(this).response.getAllResponseHeaders();
        },

        httpHeader: function (header) {
            return HTTPDONE(this).response.getResponseHeader(header);
        },

        httpBody: function () {
            return HTTPDONE(this).response.responseBody;
        },

        httpHead: function () {
            return this.httpStatus() + ' ' + this.httpStatusText() + '\r\n' + this.httpHeaders();
        },

        httpResponse: function () {
            return this.httpHead() + '\r\n\r\n' + this._http.response.responseText;
        },

        // Retrieves and parses input json
        parse: function () {

            // overwrite the parse function so subsequent calls returns in an error
            this.parse = function () {
                throw new Error('PARSE_NOT_PENDING');
            };

            var request, json;

            this._state = 'done';
            try {

                // if the type is an http request
                if (this._type === 'http') {
                    try {

                        // Create the request, and store it witht he handler
                        request = new ActiveXObject(HTTPObject);
                        this._http.response = request;

                        // If indicated, ignore all ssl certificate errors
                        if (this._http.insecure) {
                            request.Option(4) = 13056;
                        }

                        // If indicated, do not follow redirects
                        if (!this._http.redirects) {
                            request.Option(6) = false;
                        }
                        
                        // initialize the request
                        request.open(this._http.method, this._http.url, false);

                        // Apply headers
                        this._http.headers.forEach(function (header) {
                            request.setRequestHeader(header[0], header[1]);
                        });

                        // make request with body
                        if (this._http.hasData === true) {
                            request.setRequestHeader('Content-Type',   this._http.dataType);
                            request.setRequestHeader('Content-Length', this._http.dataLength);
                            request.send(this._http.data);

                        // make bodiless request
                        } else {
                            request.send();
                        }

                        // if the response isn't to be parsed, return the handle instance
                        if (this._parse === false) {
                            return this;
                        }

                        // otherwise store the response as the input data to be parsed
                        this._input = request.responseText;

                    // handle http errors
                    } catch (e) {
                        e.message = "HTTP: " + e.message;
                        throw e;
                    }
                }

                // Parse the input data
                json = String(this._input).replace(/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, function(chr) {
                    return '\\u' + ('0000' + chr.charCodeAt(0).toString(16)).slice(-4);
                });
                if (!/^[\],:{}\s]*$/.test(json.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                    throw new Error("INVALID_JSON");
                }
                try {
                    json = eval('(' + json + ')');
                } catch (e) {
                    throw new Error("INVALID_JSON");
                }

                // Return the handle
                this._json = {
                    path: [],
                    value: json
                };
                return this;

            // Store any errors in the instance and rethrow the error
            } catch (e) {
                this._error = e.message;
                throw e;
            }
        },

        walk: function () {
            var self   = PARSED(this),
                result = self._json.value,
                args   = Array.prototype.slice.call(arguments),
                fuzzy  = args.shift(),
                path   = self._json.path.slice(0),
                type,
                member,
                isFuzzy,
                keys;

            while (args.length) {
                type = GETTYPE(result);
                member = String(args.shift());
                if (type !== 'array' && type !== 'object') {
                    throw new Error('ILLEGAL_REFERENCE');
                }
                if (fuzzy && /^[~=]./.test(member)) {
                    isFuzzy = '~' === member.charAt(0);
                    member = member.replace(/^[~=]\x20?/, '');
                    if (type == 'object' && isFuzzy) {
                        keys = GETKEYS(result);
                        if (/^\d+$/.test(member)) {
                            member = parseInt(member, 10);
                            if (member >= keys.length) {
                                throw new Error('FUZZY_INDEX_NOT_FOUND');
                            }
                            member = keys[member];
                        } else if (!HASKEY(result, member)) {
                            member = member.toLowerCase();
                            member = keys.find(function (key) {
                                return member === key.toLowerCase();
                            });
                            if (member == undefined) {
                                throw new Error('FUZZY_MEMBER_NOT_FOUND');
                            }
                        }
                    }
                }
                if (!HASKEY(result, member)) {
                    throw new Error('REFERENCE_NOT_FOUND');
                }
                path.push(member);
                result = result[member];
            }
            return new JSONInstance(self, {
                path: path,
                value: result
            });
        },

        forEach: function () {
            var self = PARSED(this),
                args = Array.prototype.slice.call(arguments),
                type = self.type(),
                res = [],
                maxDepth = args[0] ? Infinity : 1;

            args.shift();

            function addResult(item, path) {
                var ref = new JSONInstance(self, {
                        path: path,
                        value: item
                    });

                if (maxDepth !== Infinity && args.length > 1) {
                    ref = ref.walk.apply(ref, args.slice(0));
                }
                res.push(ref);
            }

            function walk(item, path, depth) {
                var type = GETTYPE(item);
                path = path.slice(0);

                if (depth > maxDepth) {
                    addResult(item, path);

                } else if (type === 'object') {
                    GETKEYS(item).forEach(function (key) {
                        var kpath = path.slice(0);
                        kpath.push(key);
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

        /* forValues(submembers...) */
        forValues: function () {
            var self = PARSED(this),
                args = Array.prototype.slice.call(arguments),
                res = [],
                type = self.type();

            function writeItem(value) {
                if (value !== null) {
                    binaryStream.writeText(value);
                }
                binaryStream.writeText('\0');
            }

            function addItem(value) {
                args.forEach(function (key, index) {
                    value = value[key];
                    if (value === undefined) {
                        binaryStreamReset();
                        throw new Error(index + 1 === args.length ? 'REFERENCE_NOT_FOUND' : 'ILLEGAL_REFERENCE');
                    }
                });

                var type = GETTYPE(value);

                // null
                if (type === 'null') {
                    writeItem(null);

                // boolean
                } else if (type === 'boolean') {
                    writeItem('$' + value);

                // numbers and strings:
                } else if (type === 'number' || type === 'string') {
                    value = '' + value;
                    if (value.length <= 8100) {
                        writeItem(value);

                    } else {
                        binaryStreamReset();
                        throw new Error('LINE_LENGTH_LIMIT');
                    }

                // other
                } else {
                    binaryStreamReset();
                    throw new Error('INVALID_VALUE');
                }
            }

            if (type === 'object') {
                GETKEYS(self._json.value).forEach(function (key) {
                    addItem(self._json.value[key]);
                });

            } else if (type === 'array') {
                self._json.value.forEach(addItem);

            } else {
                binaryStreamReset();
                throw new Error('ILLEGAL_REFERENCE');
            }

            // read stream as a VT_UI1 array the close the stream
            binaryStream.position = 0;
            binaryStream.type = 1;
            res = binaryStream.read();
            binaryStreamReset();

            // return VT_UI1 array
            return res;
        },

        type: function () {
            return GETTYPE(PARSED(this)._json.value);
        },

        isContainer: function () {
            return (this.type() === "object" || this.type() === "array");
        },

        pathLength: function () {
            return PARSED(this)._json.path.length;
        },

        pathAtIndex: function (index) {
            return PARSED(this)._json.path[index];
        },

        path: function () {
            var result = '';
            PARSED(this)._json.path.forEach(function (item) {
                result += (result ? ' ' : '') + String(item).replace(/([\\ ])/g, function (chr) {
                    return ' ' === chr ? '\s' : '\\';
                });
            });
            return result;
        },

        length: function () {
            var self = PARSED(this),
                type = self.type();
            if (type === 'string' || type === 'array') {
                return self._json.value.length;
            }
            if (type === 'object') {
                return GETKEYS(self._json.value).length;
            }
            throw new Error('INVALID_TYPE');
        },

        value: function () {
            PARSED(this);
            if (this.type() === 'number' && /./.test(String(this._json.value))) {
                return String(this._json.value);
            }
            return this._json.value;
        },

        string: function () {
            return STRINGIFY(PARSED(this)._json.value);
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
                    insecure: this._http.insecure,
                    data: this._http.data
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
            return STRINGIFY(result);
        }
    };

    root.JSONInstance = JSONInstance;

    root.JSONCreate = function(type, source, parse, insecure, redirects) {
        var self = new JSONInstance();
        self._state = 'init';
        self._type = (type || 'text').toLowerCase();
        self._parse = parse === false ? false : true;

        if (self._type === 'http') {
            if (!HTTPObject) {
                self._error = 'HTTP_NOT_FOUND';
                throw new Error('HTTP_NOT_FOUND');
            }
            self._state = 'http_pending';
            self._http.url = source;
            self._http.insecure = insecure;
            self._http.redirects = redirects;

        } else {
            self._state = 'parse_pending';
            self._input = source;
        }
        return self;
    };
}(this));