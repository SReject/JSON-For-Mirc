/*jslint sloppy:true, windows:true */
/*globals trim:false, Http:false, Handle:true*/
Handle = (function () {

    // Handle constructor to be returned later
    function Handle(name, source, type, wait) {

        // validate inputs
        if (typeof name !== "string") {
            throw new TypeError("'name' must be a string");
        }
        if (!/^[a-z][a-z\d_.\-]*$/.test(name = trim(name.toLowerCase()))) {
            throw new TypeError("'name' must start with a letter(a-z) and contain only letters, numbers, _, ., or -");
        }
        if (typeof source !== "string") {
            throw new TypeError("'source' must be a string");
        }
        if (typeof type !== "string") {
            throw new TypeError("'type' must be a string");
        }
        if (!/^(?:text|http)$/i.test(type = trim(type.toLowerCase()))) {
            throw new TypeError("'type' unknown");
        }
        if (type === "http" && !Http.found) {
            throw new Error("HTTP not found");
        }

        // store state variables
        this.name = name;
        this.type = type;
        this.http = false;

        // if type is 'http' create a new instance of the Http wrapper
        // if wait is specified, update state variable and exit processing
        // otherwise, attempt the Http fetch
        if (type === "http") {
            this.http = new Http(source);
            if (wait) {
                this.state = "HTTP_PENDING";
                return;
            }
            try {
                this.http.fetch();
                source = this.http.responseBody();
            } catch (e) {
                this.state = "FATAL_ERROR";
                throw e;
            }
        }

        // Attempt to parse the source JSON data
        try {
            this.json = JSON.parse(source);
            this.state = "PARSED";
        } catch (ee) {
            this.state = "FATAL_ERROR";
            throw new Error("INVALID_JSON");
        }
    }

    // Handle constructor prototype
    Handle.prototype = {

        // return handle status: "FATAL_ERROR", "HTTP_PENDING", or "PARSED"
        status: function () {
            return this.status;
        },

        // returns the stringified value of parsed json
        toString: function () {
            if (this.status !== "PARSED") {
                throw new Error("JSON_NOT_PARSED");
            }
            try {
                return JSON.stringify(this.json);
            } catch (e) {
                throw new Error("STRINGIFY_FAILED");
            }
        },

        // sets a pending HTTP Requests' method
        httpSetMethod: function (method) {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            this.http.setRequestMethod(method);
            return true;
        },

        // Stores the specified header for a pending HTTP Request
        httpSetHeader: function (name, value) {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            this.http.setRequestHeader(name, value);
            return true;
        },

        // Performs a pending HTTP Request and attempts to parse the response
        httpFetch: function (data) {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            try {
                this.http.fetch(data);
                this.json = JSON.parse(this.http.responseBody());
                this.state = "PARSED";
                return true;
            } catch (e) {
                this.state = "FATAL_ERROR";
                throw e;
            }
        },

        // Returns the full response(status + statusText + headers + body)
        httpResponse: function () {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponse();
        },

        // returns the response head(status + statustext + headers)
        httpHead: function () {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponseHead();
        },

        // returns the response status code
        httpStatus: function () {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponseStatus();
        },

        // returns the response status text
        httpStatusText: function () {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponseStatusText();
        },

        // returns a list of response headers
        httpHeaders: function () {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponseHeaders();
        },

        // returns the value of the specified response header
        httpHeader: function (name) {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponseHeader(name);
        },

        // returns the response body as text
        httpBody: function () {
            if (!this.http) {
                throw new Error("HTTP_NOT_IN_USE");
            }
            return this.http.getResponseBody();
        }
    };

    return Handle;
}());