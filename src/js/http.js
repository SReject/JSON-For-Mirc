/*jslint sloppy:true, windows:true*/
/*globals trim:false, Http:true*/

// create an Http variable in the global scope
Http = (function (httpObjs) {

    // function to check if a request finished without error
    function stateCheck(self) {
        if (self.state === "PENDING") {
            throw new Error("FETCH_PENDING");
        }
        if (self.state !== "DONE") {
            throw new Error("FETCH_ERROR: " + self.state);
        }
    }

    // loop over various windows-supply http request objects in an attempt to find one that is valid
    // store the first valid one found in httpObj and exit the loop
    var httpObj, httpTest, hasHttp = false;
    while (httpObjs.length) {
        try {
            httpObj = httpObjs.shift();
            httpTest = new ActiveXObject(httpObj);
            hasHttp = true;
            break;
        } catch (e) { }
    }

    // Constructor function to be returned later
    function Http(url, doFetch) {

        // check if an http request object was found
        if (!hasHttp) {
            throw new Error("HTTP_NOT_FOUND");
        }

        // validate input url
        if (typeof url !== "string") {
            throw new TypeError("URL_INVALID");
        }
        url = trim(url);
        if (url === "") {
            throw new Error("URL_EMPTY");
        }

        // store state variables
        this.url = url;
        this.method = "GET";
        this.headers = [];
        this.state = "PENDING";

        // call the fetch function if 'doFetch' was supplied
        if (doFetch) {
            this.fetch();
        }
    }

    // Constructor prototype
    Http.prototype = {

        // store hasHttp in the prototype for ease-of-use checking: Http.found
        found: hasHttp,

        // Stores a method for a pending HTTP request
        setRequestMethod: function (method) {
            if (this.state !== "PENDING") {
                throw new Error("NOT_PENDING");
            }

            // validate method
            if (typeof method !== "string") {
                throw new TypeError("METHOD_INVALID");
            }
            if (/^(?:GET|POST|PUT|DEL)$/i.test(method = trim(method).toUpperCase())) {
                throw new Error("METHOD_INVALID");
            }

            // store method
            this.method = method;
        },

        // stores headers for a pending HTTP request
        setRequestHeader: function (name, value) {
            if (this.state !== "PENDING") {
                throw new Error("NOT_PENDING");
            }

            // validate supplied name and value
            if (typeof name !== "string") {
                throw new TypeError("HEADER_NAME_INVALID");
            }
            if (typeof value !== "string") {
                throw new TypeError("HEADER_VALUE_INVALID");
            }
            name = trim(name).replace(/\s*:\s*$/, "");
            if (name === "") {
                throw new Error("HEADER_NAME_EMPTY");
            }
            value = trim(value);
            if (value === "") {
                throw new Error("HEADVER_VALUE_EMPTY");
            }

            // store the header
            this.headers.push({"name": name, "value": value});
        },

        // function to perform the HTTP request
        fetch: function (data) {
            if (this.state !== "PENDING") {
                throw new Error("NOT_PENDING");
            }

            // create a new HTTP request instance
            var req, i;
            req = new ActiveXObject(httpObj);
            req.open(this.method, this.url, false);

            // loop over each stored header and set them for the request object
            for (i = 0; i < this.headers.length; i += 1) {
                try {
                    req.setRequestHeader(this.headers[i].name, this.header[i].value);
                } catch (e) {
                    this.state = "BAD_HEADER";
                    throw new Error(this.state);
                }
            }

            // attempt to make the request
            try {
                req.send(data);
                this.response = req;
                this.state = "DONE";
            } catch (ee) {
                this.state = "FETCH_FAILED";
                throw new Error(this.state);
            }
        },

        // returns the full response including the full head(status, statustext and headers) and body
        getResponse: function () {
            stateCheck(this);
            return this.response.status + " " + this.response.statusText + "\r\n" + this.response.getAllResponseHeaders() + "\r\n\r\n" + this.response.responseText;
        },

        // returns the head(status, statustext and headers)
        getResponseHead: function () {
            stateCheck(this);
            return this.response.status + " " + this.response.statusText + "\r\n" + this.response.getAllResponseHeaders();
        },

        // returns the response status
        getResponseStatus: function () {
            stateCheck(this);
            return this.response.status;
        },

        // returns the response status text
        getResponseStatusText: function () {
            stateCheck(this);
            return this.response.statusText;
        },

        // returns all response headers seperatered by \r\n
        getResponseHeaders: function () {
            stateCheck(this);
            return this.response.getAllResponseHeaders();
        },

        // returns the value of the specified response header
        getResponseHeader: function (name) {
            stateCheck(this);
            return this.response.getResponseHeader(name);
        },

        // returns the response body
        getResponseBody: function () {
            stateCheck(this);
            return this.response.responseText;
        }
    };

    // return the constructor
    return Http;

// Supply a list of acceptable HTTP Request objects
}(['MSXML2.SERVERXMLHTTP.6.0', 'MSXML2.SERVERXMLHTTP.3.0', 'MSXML2.SERVERXMLHTTP', 'MSXML2.XMLHTTP.6.0', 'MSXML2.XMLHTTP.3.0', 'Microsoft.XMLHTTP']));