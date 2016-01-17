/*jslint sloppy:true, windows:true, evil:true, regexp:true, nomen:true*/
/*global __PARAMETERS__:true*/
(function (buildjson, source, output) {
    var fso = new ActiveXObject("Scripting.FileSystemObject"), files, file, i, js = [], msl = [], out = [];

    function fileRead(file) {
        if (!fso.FileExists(file)) {
            throw new Error("File does not Exist");
        }
        var ado = new ActiveXObject("ADODB.Stream"), data = "";
        ado.Open();
        ado.Charset = "utf-8";
        try {
            ado.LoadFromFile(file);
            data = ado.ReadText();
        } catch (e) {
            ado.close();
            throw new Error("Unable to read file");
        }
        ado.close();
        return data;
    }
    function fileWrite(file, data) {
        if (fso.FileExists(file)) {
            throw new Error("File already exists");
        }
        var ado = new ActiveXObject("ADODB.Stream");
        ado.Open();
        ado.WriteText(data);
        try {
            ado.SaveToFile(file);
        } catch (e) {
            ado.close();
            throw new Error("Unable to write to file");
        }
        ado.close();
    }
    function shrinkJS(data) {
        function replacer(match, chr) {
            return chr;
        }
        var i, line, isBlockComment = false;
        data = data.replace(/(?:\s|^)\/\/.*/g, "").split(/\s*[\r\n]\s*/g);
        for (i = 0; i < data.length; i += 1) {
            line = String(data[i]);
            if (isBlockComment) {
                if (line.indexOf("*/") > -1) {
                    isBlockComment = false;
                }
                data[i] = "";
            } else if (line.indexOf("/*") > -1) {
                if (line.indexOf("*/") === -1) {
                    isBlockComment = true;
                } else {
                    isBlockComment = false;
                }
                data[i] = "";
            } else {
                data[i] = line.replace(/\s*([\&\|\:\?\;\(\)\{\}\[\]\=\+\-<\>\!\,])\s*/g, replacer).replace(/^\s+$/g, "");
            }
        }
        return data.join("").replace(/\;\s*\}/g, "}").replace(/return (["'])/g, function (m, c) {
            return "return" + c;
        });
    }
    function shrinkMSL(data) {
        var i, line, isBlockComment = false;
        data = data.replace(/^\s*;/g, "").split(/\s*[\r\n]\s*/g);
        for (i = 0; i < data.length; i += 1) {
            line = String(data[i]);
            if (isBlockComment) {
                if (line.indexOf("*/") > -1) {
                    isBlockComment = false;
                }
                data[i] = "";
            } else if (line.indexOf("/*") > -1) {
                if (line.indexOf("*/") === -1) {
                    isBlockComment = true;
                } else {
                    isBlockComment = false;
                }
                data[i] = "";
            } else if (/^\s*;/g.test(line)) {
                data[i] = "";
            }
        }
        return data.join("\r\n").replace(/\s*\r\n/g, "\r\n");
    }

    if (!fso.FileExists(buildjson)) {
        throw new Error("build.json does not exist");
    }
    if (!fso.FolderExists(source)) {
        throw new Error("Source directory does not exist");
    }
    if (!fso.FolderExists(output)) {
        throw new Error("Output directory does not exists");
    }
    files = fileRead(buildjson);
    try {
        files = eval('(' + files + ')');
    } catch (e) {
        throw new Error("Invalid build.json");
    }
    if (!files.hasOwnProperty("js")) {
        throw new Error("build.json does not have js files specified");
    }
    if (Object.prototype.toString.call(files.js) !== "[object Array]") {
        throw new Error("build.json's js property is not an array");
    }
    if (!files.hasOwnProperty("msl")) {
        throw new Error("build.json does not have mirc files specified");
    }
    if (Object.prototype.toString.call(files.msl) !== "[object Array]") {
        throw new Error("build.json's msl property is not an array");
    }

    js = ["(function () {"];
    for (i = 0; i < files.js.length; i += 1) {
        file = source + "js\\" + files.js[i];
        if (!fso.FileExists(file)) {
            throw new Error("build.json contains a file that does not exist: " + file);
        }
        js.push(fileRead(file));
    }
    js.push("}())");

    fileWrite(output + "built.js", js.join("\r\n"));


    js = shrinkJS(js.join("\r\n"));
    for (i = 0; i < js.length; i += 3500) {
        out.push("  bset -t $1 $calc($bvar($1,0)+1) " + js.substr(i, 3500));
    }
    js = "alias -l _JSON.JScript {\r\n  bunset $1\r\n" + out.join("\r\n") + "\r\n  return $1\r\n}";


    for (i = 0; i < files.msl.length; i += 1) {
        file = source + "msl\\" + files.msl[i];
        if (!fso.FileExists(file)) {
            throw new Error("build.json contains a file that does not exist: " + file);
        }
        msl.push(fileRead(file));
    }
    msl = shrinkMSL(msl.join("\r\n"));
    fileWrite(output + "test.txt", js + "\r\n" + msl);
    return "OK";
}(__PARAMETERS__));