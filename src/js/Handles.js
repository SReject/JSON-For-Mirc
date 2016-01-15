/*jslint sloppy:true, windows:true, nomen:true, forin:true*/
/*globals GLOBAL:true, Handles: true, Handle:false, formatResult:false, hasProp:false*/

// Returns the object containing handles
Handles = function () {
    return GLOBAL._JSONRef;
};
Handles.prototype = {

    // Creates a new handle
    create: function (name, source, type, wait) {
        var handle = new Handle(name, source, type, true);
        if (hasProp(GLOBAL._JSONRef, handle.name) && GLOBAL._JSONRef[handle.name] !== undefined) {
            throw new Error("NAME_IN_USE");
        }
        if (type === "http" && !wait) {
            handle.httpFetch();
        }
        GLOBAL._JSONRef[handle.name] = handle;
        GLOBAL._JSONRefByIndex.push(handle.name);
        return true;
    },

    // Returns the handle name(or count) of the specified index
    get: function (index) {
        var handle;
        if (typeof index === "string") {
            index = index.toLowerCase();
            if (!hasProp(GLOBAL._JSONRef, index) || GLOBAL._JSONRef[index] === undefined) {
                throw new Error("HANDLE_NOT_FOUND");
            }
            handle = GLOBAL._JSONRef[index];
        } else if (typeof index === "number") {
            if (!/^\d+$/i.test(String(index)) || index > GLOBAL._JSONRefByIndex.length) {
                throw new Error("INVALID_INDEX");
            }
            if (index === 0) {
                return GLOBAL._JSONRefByIndex.length;
            }
            handle = GLOBAL._JSONRef[GLOBAL._JSONRefByIndex[index - 1]];
        } else {
            throw new Error("INVALID_HANDLE");
        }
        return handle.name;
    },

    // Returns a reference to the specified handle
    getRef: function (index) {
        if (index === 0) {
            throw new Error("INVALID_INDEX");
        }
        return GLOBAL._JSONRef[this.get(index)];
    },

    // Returns the stringified result of a handle's parsed JSON
    toString: function (index) {
        if (index === 0) {
            return formatResult(null, "INVALID_INDEX");
        }
        return (GLOBAL._JSONRef[this.get(index)]).toString();
    },

    // lists all matching open handles
    list: function (match, switches) {
        var i, output = [], idxRef = GLOBAL._JSONRefByIndex;
        if (match === undefined) {
            return idxRef.join(" ");
        }
        if (typeof match !== "string") {
            throw new Error("INVALID_MATCHTEXT");
        }
        if (switches !== undefined && typeof switches !== "string") {
            throw new Error("INVALID_SWITCHES");
        }
        try {
            match = new RegExp(match, switches || "");
        } catch (ee) {
            throw new Error("INVALID_MATCHTEXT");
        }
        for (i = 0; i < idxRef.length; i += 1) {
            if (match.test(idxRef[i])) {
                output.push(idxRef[i]);
            }
        }
        return output.join(" ");
    },


    // Closes all matching handles
    close: function (match, switches) {
        var list = this.list(match, switches), count = 0, i, ref = GLOBAL._JSONRef;
        if (typeof list === "string") {
            list = list.split(/\s*/g);
            for (i = 0; i < list.length; i += 1) {
                if (hasProp(ref, list[i])) {
                    delete ref[list[i]];
                    count += 1;
                }
            }
            if (count > 0) {
                GLOBAL._JSONRefByIndex = Object.keys(ref);
            }
        }
        return count;
    }
};