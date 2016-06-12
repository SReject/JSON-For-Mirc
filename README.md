[![Join the chat at https://gitter.im/SReject/JSON-For-Mirc](https://badges.gitter.im/SReject/JSON-For-Mirc.svg)](https://gitter.im/SReject/JSON-For-Mirc?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Back Releases
=============
####JSONForMirc v0.2.4  

> [docs](https://github.com/SReject/JSON-For-Mirc/tree/v0.2.4) - [download](https://github.com/SReject/JSON-For-Mirc/releases/download/v0.2.4-beta/JSONForMirc.v0.2.4.mrc)  



Attention
===========
> This is a WIP repo. If you are looking for a previously released version please see `Back Releases` above.  

JSON For mIRC
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
>
> Windows 2000 or later (This will not work under wine due to lack of COM support)  
>
> If you are using AdiIRC 64bit, you will need to install the [tsc.dll](http://www.eonet.ne.jp/~gakana/tablacus/scriptcontrol_en.html) for this script to work  
