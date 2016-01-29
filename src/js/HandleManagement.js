/*jslint sloppy:true, windows:true, forin:true, continue:true*/
/*globals ROOT:false, hasProp:false, getType:true, Handle:false*/

// Store two global objects to be used to keep track of handles
ROOT.handles = {};
ROOT.handlesByIndex = [];

// Result Wrapper
function Result(name, parent, index, value) {
    this.name      = name;
    this.parent    = parent;
    this.index     = index;
    this.type      = getType(value);
    this.value     = value;
    this.isParent  = /^(?:array|object)$/.test(this.type) || false;

    if (this.type === "string" || this.type === "array") {
        this.length = value.length;
    } else if (this.type === "object") {
        this.length = Object.keys(value).length;
    }
}

// Attempts to create a new handle and store the instance
Handle.create = function (name, source, type, wait) {

    try {

        // attempt to create a new handle
        var handle = new Handle(name, source, type, true);

        // check to make sure the name is not already in use
        if (hasProp(ROOT.handles, handle.name) && ROOT.handles[handle.name] !== undefined) {
            throw new Error("NAME_IN_USE");
        }

        // if wait is not truthy, attempt to perform the httpFetch if required
        if (type === "http" && !wait) {
            handle.httpFetch();
        }

        // store the instance
        ROOT.handles[handle.name] = handle;
        ROOT.handlesByIndex.push(handle.name);

    } catch (e) {
        throw new Error(e.message);
    }
};
Handle.count = function () {
    return ROOT.handlesByIndex.length;
};

// Returns the Handle matching the specified index
Handle.get = function (index) {
    try {

        // if the index is numerical, get the nth handle name
        if (typeof index === "number") {
            if (!isFinite(index) || index < 1 || String(index).indexOf(".") > -1 || index >= ROOT.handlesByIndex.length) {
                throw new Error("INVALID_INDEX");
            }
            index = ROOT.handlesByIndex[index];
        }

        // verify the specified index as a string and matches the requied format
        if (typeof index !== "string") {
            throw new Error("INVALID_NAME");
        }
        if (!/^[a-z][a-z\d_.\-]*$/.test(index = index.toLowerCase())) {
            throw new Error("INVALID_NAME");
        }

        // make sure the reference exists
        if (!hasProp(ROOT.handles, index) || ROOT.handles[index] === undefined) {
            throw new Error("REFERENCE_NOT_FOUND");
        }

        // return the reference
        return ROOT.handles[index];
    } catch (e) {
        throw new Error(e.message);
    }
};

// Returns the name for the specified index
Handle.getName = function (index) {

    try {

        // if the specified index is '0' return the total number of handles
        if (index === 0) {
            return ROOT.handlesByIndex.length;
        }
        return Handle.get(index).name;

    } catch (e) {
        throw new Error(e.message);
    }
};

// traverses nested members of a specified reference
Handle.traverse = function () {

    try {

        var args = Array.prototype.slice.call(arguments),
            ref = args.shift(),
            name,
            parent,
            index,
            type,
            child,
            keys,
            i;

        // if the reference is a string or number attempt to get a handle matching the name(if string) or index(if number)
        if (typeof ref === "string" || typeof ref === "number") {
            ref = Handle.get(ref);
        }

        // if Handle instance, get the ref's json property
        if (ref instanceof Handle) {
            if (ref.state !== "PARSED") {
                throw new Error("JSON_NOT_PARSED");
            }
            parent = ref;
            index = "json";
            ref = ref.json;

        // if Result instance, get the ref's value property
        } else if (ref instanceof Result) {
            parent = ref.parent;
            index = ref.index;
            ref = ref.value;

        // throw an error for all other reference types
        } else {
            throw new Error("INVALID_REFERENCE");
        }

        // get the handle name from the reference
        name = ref.name;

        // begin looping over the arguments
        while (args.length) {

            // validate the type of the 'working' reference
            type = getType(ref);
            if (!/^(?:object|array)$/.test(type)) {
                throw new Error("INVALID_REFERENCE");
            }

            // validate the current(child) argument
            child = args.shift();
            if (typeof child !== "string" && (typeof child !== "number" || !isFinite(child))) {
                throw new Error("INVALID_MEMBER");
            }

            // if the reference is an object and the child is a valid index
            if (type !== "array") {
                if (typeof child === "number" && /^\d+$/.test(String(child))) {

                    // if the child is greater than the number of items in the object
                    // update the working reference to null and continue with the loop
                    keys = Object.keys(ref);
                    if (child >= keys.length) {
                        ref = null;
                        continue;
                    }

                    // get the nth item name from the reference to use as the child argument
                    child = keys[child];
                } else if (!hasProp(ref, child)) {
                    keys = Object.keys(ref);
                    for (i = 0; i < keys.length; i += 1) {
                        if (child.toLowerCase() === keys[i].toLowerCase()) {
                            child = keys[i];
                            break;
                        }
                    }
                }
            }

            // convert the child argument to a string
            child = String(child);

            // store a reference to that parent and index
            parent = ref;
            index = child;

            // update the 'working' reference to that of which the child points to
            ref = hasProp(ref, child) ? (ref[child] || null) : null;
        }

        // return a new TraverseResult instance
        return new Result(name, parent, index, ref);

    } catch (e) {
        throw new Error(e.message);
    }
};

// Sets the reference to the specified value
Handle.set = function () {

    try {

        var args = Array.prototype.slice.call(arguments),
            value = args.pop(),
            ref;

        // traverse to the specified nested member
        ref = Handle.traverse.apply(this, args);
        if (ref.parent === undefined || (!ref.index && ref.index !== 0)) {
            throw new Error("INVALID_REFERENCE");
        }

        // set the nested member's value
        // then return 'true' to indicate success
        ref.parent[ref.index] = value;
        return true;

    } catch (e) {
        throw new Error(e.message);
    }
};

// Parses input value as though its JSON before setting
Handle.setFromJSON = function () {

    try {

        var args = Array.prototype.slice.call(arguments);

        // parse the last argument from JSON string data into a js object
        args.push(JSON.parse(args.pop()));

        // call the set function with the updated set of arguments
        return Handle.set.apply(this, args);

    } catch (e) {
        throw new Error(e.message);
    }
};

// copies the data from one Handle reference into another
Handle.copyTo = function () {
    try {
        var args = Array.prototype.slice.call(arguments),
            ref = args.shift(),
            data;

        // if the reference is a Handle instance, use the parsed json
        if (ref instanceof Handle) {
            if (ref.status !== "PARSED") {
                throw new Error("JSON_NOT_PARSED");
            }
            data = JSON.Stringify(ref.json);

        // if the reference is a TraverseResult instance use the value property
        } else if (ref instanceof Result) {
            data = JSON.stringify(ref.value);

        // throw an error for any other input type of the copyFromReference
        } else {
            throw new Error("INVALID_REFERENCE");
        }

        Handle.set.apply(this, args, JSON.parse(data));
        return true;
    } catch (e) {
        throw new Error(e.message);
    }
};

// removes a nested item from an object or array
Handle.remove = function () {

    try {
        // get the reference to be removed
        var type, ref = Handle.traverse.call(this, Array.prototype.slice.call(arguments));
        if (!ref.parent || (!ref.index && ref.index !== 0)) {
            throw new Error("INVALID_REFERENCE");
        }

        // get the reference's parent's type
        type = getType(ref.parent);

        // if the reference points directly to a Handle's json property
        // set the json property to null
        if (ref.parent instanceof Handle) {
            ref.parent.json = null;

        // if the reference points to an object property
        // delete the property
        } else if (type === "object") {
            delete ref.parent[ref.index];

        // if the reference points to an array item
        // splice out the item
        } else if (type === "array") {
            ref.parent.splice(ref.index, 1);

        // if the reference points to a primitive(why?!?!)
        // throw an error
        } else {
            throw new Error("INVALID_REFERENCE");
        }

        // return true to indicate success
        return true;
    } catch (e) {
        throw new Error(e.message);
    }
};

// Returns the parsed json data as a string
Handle.toString = function (index) {
    try {
        // attempt to get the handle the specified index references
        var handle = Handle.get(index);

        // verify the handle has parsed its json
        if (handle.status !== "PARSED") {
            throw new Error("JSON_NOT_PARSED");
        }

        // return the stringified data
        return JSON.stringify(Handle.get(index).json);

    } catch (e) {
        throw new Error(e.message);
    }
};

// lists all matching handles formatted as string delimited by space
Handle.list = function (matchtext, asArray) {

    try {

        var i, handleList = ROOT.handlesByIndex, output = [];

        // If matchtext isn't specified, return all handle names
        if (matchtext === undefined || matchtext === null) {
            return handleList.join(" ");
        }

        // validate matchtext and switches
        if (typeof matchtext !== "string") {
            throw new Error("INVALID_MATCHTEXT");
        }

        // compile regex to be used for matching
        try {
            matchtext = new RegExp(matchtext, "i");
        } catch (ee) {
            throw new Error("INVALID_MATCHTEXT");
        }

        // loop over the handles list, storing matching handle names in the 'output' array
        for (i = 0; i < handleList.length; i += 1) {
            if (matchtext.test(handleList[i])) {
                output.push(handleList[i]);
            }
        }

        // if an array is desired, return the output array
        if (asArray) {
            return output;
        }

        // join the array so the output becomes a space delimited string and return it
        return output.join(" ");

    } catch (e) {
        throw new Error(e.message);
    }
};

// Closes all matching handles and returns the number of handles closed
Handle.close = function (matchtext) {

    try {

        // Require matchtext to be specified so a bad script won't close all handles
        if (matchtext === undefined || matchtext === null || matchtext === "") {
            throw new Error("INVALID_MATCHTEXT");
        }

        // get a list of matching handles
        var list = this.list(matchtext, true),
            handles = ROOT.handles,
            count = 0,
            index;

        // loop over each matching handle verify the handle exists then delete it
        for (index = 0; index < list.length; index += 1) {
            if (hasProp(handles, list[index]) && handles[list[index]] !== undefined) {
                delete handles[list[index]];
                count += 1;
            }
        }

        // if any handle was deleted, rebuild the handlesByIndex array
        if (count > 0) {
            ROOT.handlesByIndex = Object.keys(ROOT.handles);
        }

        // return the number of handles deleted
        return count;

    } catch (e) {
        throw new Error(e.message);
    }
};