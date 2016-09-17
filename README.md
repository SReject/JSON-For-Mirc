Donate:  
======  
> If you appreciate the work done, consider donating via paypal @ [StreamJar](https://streamjar.tv/tip/SReject)
  
  
About:  
======  
> A script to parse and then access JSON from within mIRC.  
>  
> "But Mr. Reject, there's plenty of these scripts! Why create another?" Well, little one, I find that most of those scripts trade in efficiency for simplicity. Generally speaking most JSON scripts for mIRC reparse the json data each time that data needs to be accessed.  
>  
> My version, though a bit more complex to understand, only requires the parsing of JSON data once per JSON handler instance, making it quite a bit faster, and less resource intensive to use. Along with being a bit more efficient handling JSON, the script can retrieve data from remote sources for parsing. Allowing for the request method and headers to be set as needed.  
>  
> "But why a JSON parser? Why not spend your time coding something that the typical user would make use of?". Its simple, to make those fancy GUI-intensive scripts, scripters need/use tools to simplify the tasks. This is one such tool.  
>  
> The reason for a JSON parser vs. some other 'tool', is because of its overwhelming use around the web. Now-a-days, when you want data from a website, they may package it as an API, generally returning results in JSON format. Examples include: Google.com, Youtube.com, Pastebin.com, and Weather.com  
  
Requirements:  
=============  
> Mirc: 7.32 or later, or AdiIRC 2.2 or later  
> Windows 2000 or later (This will not work under wine due to lack of COM support)  
> If you are using AdiIRC 64bit, you will need to install the [tsc.dll](http://www.eonet.ne.jp/~gakana/tablacus/scriptcontrol_en.html) for this script to work  
  
Installation:  
=============  
> Download the [JSONForMirc.v.0.2.4.mrc](https://github.com/SReject/JSON-For-Mirc/releases/download/v0.2.4-beta/JSONForMirc.v0.2.4.mrc) file  
> Move the file to a directory of your choice  
> In mirc enter the following: `//load -rs $qt($$sfile($mircdir, Load JSONFormIRC, Load))`  
  
Notes:  
======  
> If you release a snippet that depends on this script, link to this page instead of including it within your scripts. Doing so ensures users do not have conflicting copies of this code as well as ensuring credit is given where due.  
  
Usage:  
======  
#### /JSONOpen -dbfuw {name} {text|bvar|file|url}  
> Creates a json handler  
>  
> `-d`: Closes the JSON handler at the end of the script's execution  
> `-b`: Parses JSON stored in the specified bvar  
> `-f`: Parses JSON stored in the specified file  
> `-u`: Parses JSON stored at the specified URL  
> `-w`: Used with `-u`, to make the URL request wait until `/JSONUrlGet` is called. This is to allow the usage of `/JSONUrlMethod` and `/JSONUrlHeader` prior to retrieving data from a url.  
>  
> `{name}`: Unique name of the json handler to use to reference the handler. Must start with a letter(a-z) and contain only letters, numbers, _ or -  
>  
> `{text|bvar|file|url}`: JSON data source  
>  
> `$JSONError` will be filled if parameters are invalid or JSON Handler could not be created  
  
#### /JSONUrlMethod {name} {method}  
> Sets the request method for the JSON handler (for use with url requests only).  
>  
> `{name}`: JSON handler name  
>  
> `{method}`: Request method. Must be `GET`, `POST`, `PUT`, `DEL`, `HEAD`  
>  
> `$JSONError` will be filled if parameters are invalid  
> `$JSON().Error` will be filled the method could not be set  
  
#### /JSONUrlHeader {name} {header} {value}  
> Sets the specified request header for the JSON handler (for use with url requests only).  
>  
> `{name}`: JSON handler name  
>  
> `{header} {value}`: Sets the specified `{header}` to `{value}`  
> Multiple values for the same header will be appended to each other  
>  
> `$JSONError` will be filled if parameters are invalid  
> `$JSON().Error` will be filled if header could not be set  
  
#### /JSONUrlGet -bf {name} [text|bvar|file]  
> Retrieves data from a URL for the JSON handler (for use with url request only).  
>  
> `-b`: sends data contained in the specified bvar with the request  
> `-f`: sends data contained in the specified file with the request  
>  
> `{name}`: JSON handler name  
>  
> `[text|bvar|file]`: Data to send with the request.  
>  
> `$JSON().UrlResponse` can be used to access information about the response such as status code and recieved headers  
>  
> `$JSONError` will be filled if parameters are invalid  
> `$JSON().Error` will be filled if an error making the request results in an error  
  
#### /JSONClose [-w] {name}  
> Closes the specified JSON handler  
>  
> `-w`: the name is a wildcard match of JSON handlers  
>  
> `{name}`: JSON handler to close  
  
#### /JSONList  
> Lists all currently open JSON handlers  
  
#### /JSONDebug on|off  
> Enables or disables JSON debugging  
  
#### $JSON({name|n})  
> If the specified JSON handler exists, its name is returned  
> If `n` is 0, the total number of open JSON handlers is returned  
> if `n` is greater than 0, the Nth json handler's name is returned  
  
#### $JSON({name}).status  
> Returns the current status for the specified JSON handlers  
> Possible values are: init, waiting, parsed, error  
  
#### $JSON({name}).isRef  
> Returns `$true` if the specified name is an alias for a nested member  
  
#### $JSON({name}).error  
> Returns the error if the last call to the json handler resulted in an error  
  
#### $JSON({name}).UrlStatus  
> Retrieves the url request's response status code  
>  
> `$JSON().error` is filled if a response has not been made  
  
#### $JSON({name}).UrlStatusText  
> Returns the url request's response status code text, E.g.: "200 OK"  
>  
> `$JSON().error` is filled if a response has not been made  
  
#### $JSON({name}, {header_name}).UrlHeader  
> Returns the specified header from the url request's response  
>  
> `$JSON().error` is filled if a response has not been made  
  
#### $JSON({name}, {index|item[, ...]})  
> Returns the data at the specified reference.  
> If the reference points to an array or object an alias of the reference is returned  
> This alias can be used with `$json({alias})` to access its nested members  
>  
> `$JSON().error` is filled if the reference points to an undefined value  
  
#### $JSON({name}, {index|item[, ...]}).type  
> Returns the type of the item referenced.  
> Possible values are: null, boolean, number, string, array, object  
>  
> `$JSON().error` will be filled if the reference doesn't exist  
  
#### $JSON({name}, {index|item[, ...]}).isParent  
> Returns $true if the reference points to an object or array  
>  
> `$JSON().error` will be filled if the reference doesn't exist  
  
#### $JSON({name}, {index|item[, ...]}).length  
> Returns the length of the item referenced.  
>  
> `$JSON().error` will be filled if the reference is not a string or array or doesn't exist  
  
#### $JSON({name}, {bvar}, {index|item[, ...]}).toBvar  
> Retrieves the referenced data and stores it in the specified bvar.  
>  
> `$JSON().error` will be filled if the reference points to an array, object or doesn't exist  
  
#### $JSON({name}, {index|item[, ...]}).fuzzy  
> Attempts to find a matching reference and returns its value.  
> Character-case is ignored.  
> If a numeric value is specified the nTH item value is returned(0-indexed)  
>  
> `$JSON().error` is filled if no matching reference is found.  
  
#### $JSON({name}, {index|item[, ...]}).fuzzypath  
> Attempts to find a matching reference and returns its path formated as `["item|index"]["item|index"][....]`  
> Character-case is ignored.  
> If a numeric value is specified the nTh item value is returned (0th indexed)  
>  
> `$JSON().error` is filled if no matching reference is found.  
  
#### $JSONDebug  
> Returns $true of debugging is enabled  
  
#### $JSONError  
> Returns the the error message if the last JSON call resulted in an error  
  
#### $JSONVersion([short])  
> Returns the Script version  
> If short is specified, only the numerical value of the version is returned (x.x.x)  
