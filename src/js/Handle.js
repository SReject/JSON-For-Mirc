/*jslint windows: true, sloppy: true */
/*globals Handle: true, Http: false, trim: false, formatResult: false*/
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
        if (/^(?:text|http)$/i.test(type = trim(type.toLowerCase()))) {
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
            return formatResult(this.status);
        },

        // sets a pending HTTP Requests' method
        httpSetMethod: function (method) {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                this.http.setRequestMethod(method);
                return formatResult();
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // Stores the specified header for a pending HTTP Request
        httpSetHeader: function (name, value) {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                this.http.setRequestHeader(name, value);
                return formatResult();
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // Performs a pending HTTP Request and attempts to parse the response
        httpFetch: function (data) {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                this.http.fetch(data);
                this.json = JSON.parse(this.http.responseBody());
                this.state = "PARSED";
                return formatResult();
            } catch (e) {
                this.state = "FATAL_ERROR";
                return formatResult(null, e.message);
            }
        },

        // Returns the full response(status + statusText + headers + body)
        httpResponse: function () {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponse());
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // returns the response head(status + statustext + headers)
        httpHead: function () {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponseHead());
            } catch (e) {
                return formatResult(null, e.message);
            }

        },

        // returns the response status code
        httpStatus: function () {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponseStatus());
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // returns the response status text
        httpStatusText: function () {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponseStatusText());
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // returns a list of response headers
        httpHeaders: function () {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponseHeaders());
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // returns the value of the specified response header
        httpHeader: function (name) {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponseHeader(name));
            } catch (e) {
                return formatResult(null, e.message);
            }
        },

        // returns the response body as text
        httpBody: function () {
            if (!this.http) {
                return formatResult(null, "HTTP_NOT_REQUEST");
            }
            try {
                return formatResult(this.http.getResponseBody());
            } catch (e) {
                return formatResult(null, e.message);
            }
        }
    };

    return Handle;
}());