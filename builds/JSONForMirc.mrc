alias -l _JSON.JScript {
  bunset $1
  bset -t $1 $calc($bvar($1,0)+1) (function(){ROOT=this;function trim(input){return String(input).replace(/(?:^\s+)|(\s+$)/g,"")}function hasProp(obj,prop){return Object.prototype.hasOwnProperty.call(obj,prop)}function getType(obj){return(Object.prototype.toString.call(obj)).replace(/\[\S+(.*)\]$/i,function(text,typeText){typeText=typeText.toLowerCase();if(typeText==="undefined"){return null}return typeText})}Object.prototype.keys=function(self){var key,keys=[];self=self||this;for(key in self){if(hasProp(self,key)&&self[key]!==undefined){keys.push(key)}}return keys};(function(){if(typeof ROOT.JSON==='object'){return}function f(n){return n<10?'0'+n:n}function q(s){return'"'+s.replace(/[\\\"\u0000-\u001f\u007f-\u009f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,function(a){return'\\u'+('0000'+a.charCodeAt(0).toString(16)).slice(-4)})+'"'}Date.prototype.toJSON=function(){return isFinite(this.valueOf())?[this.getUTCFullYear(),'-',f(this.getUTCMonth()+1),'-',f(this.getUTCDate()),'T',f(this.getUTCHours()),':',f(this.getUTCMinutes()),':',f(this.getUTCSeconds()),'Z'].join(""):null};Boolean.prototype.toJSON=function(){return String(this.valueOf())};Number.prototype.toJSON=function(){return isFinite(this.valueOf())?String(this.valueOf()):null};String.prototype.toJSON=function(){return q(this.valueOf())};Array.prototype.toJSON=function(){var r=[],i,v;for(i=0;i<this.length;i+=1){v=this[v];if(hasProp(v,"toJSON")&&typeof v.toJSON==="function"){r.push(v.toJSON())}else{r.push('null')}}return'['+r.join(',')+']'};Object.prototype.toJSON=function(){var s=this,r,k,v;for(k in s){if(hasProp(s,k)){v=s[k];if(hasProp(v,"toJSON")&&typeof v.toJSON==="function"){r.push(q(k)+":"+v.toJSON())}else{r.push(q(k)+":null")}}}return'{'+r.join(',')+'}'};ROOT.JSON={stringify:function(v){if(v){return v.toJSON()}return'null'},parse:function(t){t=String(t).replace(/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,function(a){return'\\u'+('0000'+a.charCodeAt(0).toString(16)).slice(-4)});if(/^[\],:{}\s]*$/.test(t.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,''))){return eval('('+t+')')}throw new SyntaxError('INVALID_JSON')}}}());Http=(function(httpObjs){function stateCheck(self){if(self.state==="PENDING"){throw new Error("FETCH_PENDING")}if(self.state!=="DONE"){throw new Error("FETCH_ERROR:"+self.state)}}var httpObj,httpTest,hasHttp=false;while(httpObjs.length){try{httpObj=httpObjs.shift();httpTest=new ActiveXObject(httpObj);hasHttp=true;break}catch(e){}}function Http(url,doFetch){if(!hasHttp){throw new Error("HTTP_NOT_FOUND")}if(typeof url!=="string"){throw new TypeError("URL_INVALID")}url=trim(url);if(url===""){throw new Error("URL_EMPTY")}this.url=url;this.method="GET";this.headers=[];this.state="PENDING";if(doFetch){this.fetch()}}Http.prototype={found:hasHttp,setRequestMethod:function(method){if(
  bset -t $1 $calc($bvar($1,0)+1) this.state!=="PENDING"){throw new Error("NOT_PENDING")}if(typeof method!=="string"){throw new TypeError("METHOD_INVALID")}if(/^(?:GET|POST|PUT|DEL)$/i.test(method=trim(method).toUpperCase())){throw new Error("METHOD_INVALID")}this.method=method},setRequestHeader:function(name,value){if(this.state!=="PENDING"){throw new Error("NOT_PENDING")}if(typeof name!=="string"){throw new TypeError("HEADER_NAME_INVALID")}if(typeof value!=="string"){throw new TypeError("HEADER_VALUE_INVALID")}name=trim(name).replace(/\s*:\s*$/,"");if(name===""){throw new Error("HEADER_NAME_EMPTY")}value=trim(value);if(value===""){throw new Error("HEADVER_VALUE_EMPTY")}this.headers.push({"name":name,"value":value})},fetch:function(data){if(this.state!=="PENDING"){throw new Error("NOT_PENDING")}var req,i;req=new ActiveXObject(httpObj);req.open(this.method,this.url,false);for(i=0;i<this.headers.length;i+=1){try{req.setRequestHeader(this.headers[i].name,this.header[i].value)}catch(e){this.state="BAD_HEADER";throw new Error(this.state)}}try{req.send(data);this.response=req;this.state="DONE"}catch(ee){this.state="FETCH_FAILED";throw new Error(this.state)}},getResponse:function(){stateCheck(this);return this.response.status+" "+this.response.statusText+"\r\n"+this.response.getAllResponseHeaders()+"\r\n\r\n"+this.response.responseText},getResponseHead:function(){stateCheck(this);return this.response.status+" "+this.response.statusText+"\r\n"+this.response.getAllResponseHeaders()},getResponseStatus:function(){stateCheck(this);return this.response.status},getResponseStatusText:function(){stateCheck(this);return this.response.statusText},getResponseHeaders:function(){stateCheck(this);return this.response.getAllResponseHeaders()},getResponseHeader:function(name){stateCheck(this);return this.response.getResponseHeader(name)},getResponseBody:function(){stateCheck(this);return this.response.responseText}};return Http}(['MSXML2.SERVERXMLHTTP.6.0','MSXML2.SERVERXMLHTTP.3.0','MSXML2.SERVERXMLHTTP','MSXML2.XMLHTTP.6.0','MSXML2.XMLHTTP.3.0','Microsoft.XMLHTTP']));Handle=(function(){function Handle(name,source,type,wait){if(typeof name!=="string"){throw new TypeError("'name' must be a string")}if(!/^[a-z][a-z\d_.\-]*$/.test(name=trim(name.toLowerCase()))){throw new TypeError("'name' must start with a letter(a-z)and contain only letters,numbers,_,.,or-")}if(typeof source!=="string"){throw new TypeError("'source' must be a string")}if(typeof type!=="string"){throw new TypeError("'type' must be a string")}if(!/^(?:text|http)$/i.test(type=trim(type.toLowerCase()))){throw new TypeError("'type' unknown")}if(type==="http"&&!Http.found){throw new Error("HTTP not found")}this.name=name;this.type=type;this.http=false;if(type==="http"){this.http=new Http(source);if(wait){this.state="HTTP_PENDING";return}try{this.http.fetch();source=this.http.responseBody()}catch(e){this.state="FATAL_ERROR";throw e}}try{this.json=JSON.parse(source);this.state="PARSED"}catch(ee){this.state="FATAL_ERROR";throw new Error("INVALI
  bset -t $1 $calc($bvar($1,0)+1) D_JSON")}}Handle.prototype={status:function(){return this.status},toString:function(){if(this.status!=="PARSED"){throw new Error("JSON_NOT_PARSED")}try{return JSON.stringify(this.json)}catch(e){throw new Error("STRINGIFY_FAILED")}},httpSetMethod:function(method){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}this.http.setRequestMethod(method);return true},httpSetHeader:function(name,value){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}this.http.setRequestHeader(name,value);return true},httpFetch:function(data){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}try{this.http.fetch(data);this.json=JSON.parse(this.http.responseBody());this.state="PARSED";return true}catch(e){this.state="FATAL_ERROR";throw e}},httpResponse:function(){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponse()},httpHead:function(){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponseHead()},httpStatus:function(){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponseStatus()},httpStatusText:function(){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponseStatusText()},httpHeaders:function(){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponseHeaders()},httpHeader:function(name){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponseHeader(name)},httpBody:function(){if(!this.http){throw new Error("HTTP_NOT_IN_USE")}return this.http.getResponseBody()}};return Handle}());ROOT.handles={};ROOT.handlesByIndex=[];function Result(name,parent,index,value){this.name=name;this.parent=parent;this.index=index;this.type=getType(value);this.value=value;this.isParent=/^(?:array|object)$/.test(this.type);if(this.type==="string"||this.type==="array"){this.length=value.length}else if(this.type==="object"){this.length=Object.keys(value).length}}Handle.create=function(name,source,type,wait){try{var handle=new Handle(name,source,type,true);if(hasProp(ROOT.handles,handle.name)&&ROOT.handles[handle.name]!==undefined){throw new Error("NAME_IN_USE")}if(type==="http"&&!wait){handle.httpFetch()}ROOT.handles[handle.name]=handle;ROOT.handlesByIndex.push(handle.name)}catch(e){throw new Error(e.message)}};Handle.get=function(index){try{if(typeof index==="number"){if(!isFinite(index)||index<1||String(index).indexOf(".")>-1||index>=ROOT.handlesByIndex.length){throw new Error("INVALID_INDEX")}index=ROOT.handlesByIndex[index]}if(typeof index!=="string"){throw new Error("INVALID_NAME")}if(!/^[a-z][a-z\d_.\-]*$/.test(index=index.toLowerCase())){throw new Error("INVALID_NAME")}if(!hasProp(ROOT.handles,index)||ROOT.handles[index]===undefined){throw new Error("REFERENCE_NOT_FOUND")}return ROOT.handles[index]}catch(e){throw new Error(e.message)}};Handle.getName=function(index){try{if(index===0){return ROOT.handlesByIndex.length}return Handle.get(index).name}catch(e){throw new Error(e.message)}};Handle.traverse=function(){try{var args=Array.prototype.slice.call(arg
  bset -t $1 $calc($bvar($1,0)+1) uments),ref=args.shift(),name,parent,index,type,child,keys;if(typeof ref==="string"||typeof ref==="number"){ref=Handle.get(ref)}if(ref instanceof Handle){if(ref.state!=="PARSED"){throw new Error("JSON_NOT_PARSED")}parent=ref;index="json";ref=ref.json}else if(ref instanceof Result){parent=ref.parent;index=ref.index;ref=ref.value}else{throw new Error("INVALID_REFERENCE")}name=ref.name;while(args.length){type=getType(ref);if(!/^(?:object|array)$/.test(type)){throw new Error("INVALID_REFERENCE")}child=args.shift();if(typeof child!=="string"&&(typeof child!=="number"||!isFinite(child))){throw new Error("INVALID_MEMBER")}if(type!=="array"){if(typeof child==="number"&&/^\d+$/.test(String(child))){keys=Object.keys(ref);if(child>=keys.length){ref=null;continue}child=keys[child]}else if(!hasProp(ref,child)){keys=Object.keys(ref);for(i=0;i<keys.length;i+=1){if(child.toLowerCase()==keys[i].toLowerCase()){child=keys[i];break}}}}child=String(child);parent=ref;index=child;ref=hasProp(ref,child)?(ref[child]||null):null}return new Result(name,parent,index,ref)}catch(e){throw new Error(e.message)}};Handle.set=function(){try{var args=Array.prototype.slice.call(arguments),value=args.pop(),ref;ref=Handle.traverse.apply(this,args);if(ref.parent===undefined||(!ref.index&&ref.index!==0)){throw new Error("INVALID_REFERENCE")}ref.parent[ref.index]=value;return true}catch(e){throw new Error(e.message)}};Handle.setFromJSON=function(){try{var args=Array.prototype.slice.call(arguments);args.push(JSON.parse(args.pop()));return Handle.set.apply(this,args)}catch(e){throw new Error(e.message)}};Handle.copyTo=function(){try{var args=Array.prototype.slice.call(arguments),ref=args.shift(),data;if(ref instanceof Handle){if(ref.status!=="PARSED"){throw new Error("JSON_NOT_PARSED")}data=JSON.Stringify(ref.json)}else if(ref instanceof Result){data=JSON.stringify(ref.value)}else{throw new Error("INVALID_REFERENCE")}Handle.set.apply(this,args,JSON.parse(data));return true}catch(e){throw new Error(e.message)}};Handle.remove=function(){try{var type,ref=Handle.traverse.call(this,Array.prototype.slice.call(arguments));if(!ref.parent||(!ref.index&&ref.index!==0)){throw new Error("INVALID_REFERENCE")}type=getType(ref.parent);if(ref.parent instanceof Handle){ref.parent.json=null}else if(type==="object"){delete ref.parent[ref.index]}else if(type==="array"){ref.parent.splice(ref.index,1)}else{throw new Error("INVALID_REFERENCE")}return true}catch(e){throw new Error(e.message)}};Handle.toString=function(index){try{var handle=Handle.get(index);if(handle.status!=="PARSED"){throw new Error("JSON_NOT_PARSED")}return JSON.stringify(Handle.get(index).json)}catch(e){throw new Error(e.message)}};Handle.list=function(matchtext,asArray){try{var i,handleList=ROOT.handlesByIndex,output=[];if(matchtext===undefined||matchtext===null){return handleList.join(" ")}if(typeof matchtext!=="string"){throw new Error("INVALID_MATCHTEXT")}if(switches!==undefined&&switches!==null&&typeof switches!=="string"){throw new Erro
  bset -t $1 $calc($bvar($1,0)+1) r("INVALID_SWITCHES")}try{matchtext=new RegExp(matchtext,"i")}catch(ee){throw new Error("INVALID_MATCHTEXT")}for(i=0;i<handleList.length;i+=1){if(matchtext.test(handleList[i])){output.push(handleList[i])}}if(asArray){return output}return output.join(" ")}catch(e){throw new Error(e.message)}};Handle.close=function(matchtext){try{if(matchtext===undefined||matchtext===null||matchtext===""){throw new Error("INVALID_MATCHTEXT")}var list=this.list(matchtext,switches,true),handles=ROOT.handles,count=0,index;for(index=0;index<list.length;index+=1){if(hasProp(handles,list[index])&&handles[list[index]]!==undefined){delete handles[list[index]];count+=1}}if(count>0){ROOT.handlesByIndex=Object.keys(ROOT.handles)}return count}catch(e){throw new Error(e.message)}}}())
  return $1
}

alias -l _JSON.Start {
  if (!$isid) {
    return
  }
  _JSON.Log Calling~$_JSON.Start()
  var %Error, %Close = $false, %Wrapper = $_JSON.Com(Wrapper), %Engine = $_JSON.Com(Engine), %Manager = $_JSON.Com(Manager), %JScript
  if ($lock(com)) {
    %Error = COM interface locked via mIRC options
  }
  elseif ($com(%Wrapper) && $com(%Engine) && $com(%Manager)) {
    return $true
  }
  else {
    if ($com(%Manager)) {
      .comclose $v1
    }
    if ($com(%Engine)) {
      .comclose $v1
    }
    if ($com(%Wrapper)) {
      .comclose $v1
    }
    %Close = $true
    %JScript = $_JSON.JScript($_JSON.TmpBVar)
    .comopen %Wrapper MSScriptControl.ScriptControl
    if (!$com(%Wrapper) || $comerr) {
      %Error = Unable to create instance of MSScriptControl.ScriptControl
    }
    elseif (!$com(%Wrapper, language, 4, bstr, jscript) || $comerr) {
      %Error = Unable to set the ScriptControl's language to JScript
    }
    elseif (!$com(%Wrapper, timeout, 4, bstr, 60000) || $comerr) {
      %Error = Unable to set the ScriptControl's timeout to 60s
    }
    elseif (!$com(%Wrapper, ExecuteStatement, 1, &bstr, %JScript) || $comerr) {
      %Error = Unable to add JScript to the ScriptControl
    }
    elseif (!$com(%Wrapper, Eval, 1, bstr, this, dispatch* %Engine) || $comerr) {
      %Error = JScript execution failed
    }
    elseif (!$com(%Engine)) {
      %Error = Unable to create a reference to the ScriptControl's JSEngine
    }
    elseif (!$com(%Engine, Handle, 2, dispatch* %Manager) || $comerr) {
      %Error = Referencing the JScript's Handle manager failed
    }
    elseif (!$com(%Manager)) {
      %Error = Reference to the JScript's Handle manager failed
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if ($bvar(%JScript, 0)) {
    bunset %JScript
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    if (%Close) {
      if ($com(%Manager)) {
        .comclose $v1
      }
      if ($com(%Engine)) {
        .comclose $v1
      }
      if ($com(%Wrapper)) {
        .comclose $v1
      }
    }
    _JSON.Log error $!_JSON.Start~ $+ %Error
    return $false
  }
  _JSON.Log ok $!_JSON.Start~Call Successful
  return $true
}
alias -l _JSON.Com {
  var %Result, %n
  if ($1 == Wrapper) {
    %Result = JSONForMirc:Wrapper
  }
  elseif ($1 == Engine) {
    %Result = JSONForMirc:Engine
  }
  elseif ($1 == Manager) {
    %Result = JSONForMirc:Manager
  }
  else {
    %n = $ticks * 1000
    while ($com(JSONForMirc:Tmp: $+ %n)) inc %n
    %Result = JSONForMirc:Tmp: $+ %n
  }
  _JSON.Log $!_JSON.Com~Returning %Result as com name
  return %Result
}
alias -l _JSON.TmpBVar {
  var %n = $ticks * 1000
  while ($bvar(JSONForMirc:Tmp: $+ %n, 0)) {
    inc %n
  }
  _JSON.Log $!_JSON.TmpBVar~Returning &JSONForMirc:Tmp: $+ %n as temporary binary variable
  return &JSONForMirc:Tmp: $+ %n
}
alias -l _JSON.TmpFile {
  var %dir = $nofile($mircini) $+ data\, %n = $ticks * 1000
  if (!$isdir(%dir)) {
    mkdir %dir
  }
  %dir = %dir $+ JSONForMirc\
  if (!$isdir(%dir)) {
    mkdir %dir $+ JSONForMirc\
  }
  while ($isfile(%dir $+ JSONForMirc $+ %n $+ .tmp)) {
    inc %n
  }
  _JSON.Log $!_JSON.TmpFile~Returning %dur $+ JSONForMirc $+ %n $+ .tmp as temporary file
  if ($prop == quote) {
    return $qt(%dur $+ JSONForMirc $+ %n $+ .tmp)
  }
  return %dur $+ JSONForMirc $+ %n $+ .tmp
}
alias -l _JSON.ParseInputs {
  set -u0 %_JSONForMirc:Tmp:InputCount $calc(%_JSONForMirc:Tmp:InputCount + 1)
  if ($1 && %_JSONForMirc:Tmp:InputCount < $1) {
    return
  }
  if ($2 isnum 0-) {
    return integer, $+ $1
  }
  var %BVar = $_JSON.TmpBVar
  bset -t %BVar 1 $_JSON.UnEscape($2)
  return &bstr, $+ %BVar
}
alias -l _JSON.UnEscape {
  if ("*" !iswm $1) {
    return $1
  }
  return $mid($1, 2-, -1)
}
alias -l $_JSON.WildcardToRegex {
  return $+(^, $regsubex($1-,/([\Q$^|[]{}()\/.+\E])|(&(?= |$))|([?*]+)/g, $_JSON.WildcardToRegexRep(\t)), $chr(36))
}
alias -l $_JSON.WildcardToRegexRep {
  if ($1 == &) {
    return \S+\b
  }
  if ($1 !isin *?) {
    return \ $+ $1
  }
  if (? !isin $1) {
    return .*
  }
  if ($count($1,?) < 5) {
    return $str(.,$v1) $+ $iif(* isin $1,+)
  }
  return $+(.,$chr(123),$count($1,?),$iif(* isin $1,$chr(44)),$chr(125))
}
alias -l _JSON.Call {
  var %Com, %Error, %ErrorCom, %param
  scid $cid var % $+ param = % $+ param $!+ $!chr(44) $!+ $*
  %Param = $mid(%Param, 2-)
  _JSON.Log Calling~$!_JSON.Call( $+ %Param $+ )
  _JSON.Log $!_JSON.Call~Attempting to get Com Name
  if ($istok(Wrapper Enginer Manager, $1, 32)) {
    %Com = $_JSON.Com($1)
  }
  else if (JSONForMirc:Tmp:* iswm $1 && $com($1)) {
    %Com = $1
  }
  else {
    set -u %_JSONForMirc:Error INVALID_COM_NAME
    _JSON.Log Error $!_JSON.Call~ $+ INVALID_COM_NAME
    return $false
  }
  _JSON.Log ok $!_JSON.Call~Using %com as com name
  _JSON.Log $!_JSON.Call~Making Com Call
  if (!$com(%Com, [ $gettok(%param, 2-, 44) ] ) || $comerr) {
    _JSON.Log $!_JSON.Call~Call ended with an error, attempting to get error
    %ErrorCom = $_JSON.Com
    if (!$com($_JSON.Com(Wrapper), Error, 2, dispatch* %ErrorCom) || $comerr || !$com(%ErrorCom)) {
      %Error = Call Error (Unable to retrieve Error state)
    }
    else {
      if (!$com(%ErrorCom, Description, 2) || $comerr) {
        %Error = Call Error (Unable to retrieve Error message)
      }
      elseif ($com(%ErrorCom).result) {
        %Error = Call Error ( $+ $v1 $+ )
      }
      else {
        %Error = Call Error (Unable to retrieve reason message)
      }
      noop $com(%ErrorCom, Clear, 1)
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%ErrorCom && $com(%ErrorCom)) {
    .comclose $v1
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    _JSON.Log Error $!_JSON.Call~ $+ %Error
    return $false
  }
  _JSON.Log ok $!_JSON.Call~Call Succeesful
  return $true
}
alias -l _JSON.CallHandle {
  var %Error, %CloseRef, %RefCom, %Param
  scid $cid var % $+ param = % $+ param $*
  %Param = $mid(%Param, 2-)
  _JSON.Log Calling~$!_JSON.CallHandle( $+ %Param $+ )
  if ($regex($1, /^JSONForMirc:Tmp:\d+$/i)) {
    if (!$com($1)) {
      %Error = Reference Com does not exist
    }
    else {
      %RefCom = $1
    }
  }
  else {
    %RefCom = $_JSON.Com
    if (!$_JSON.Call(Manager, get, 1, bstr, $1, dispatch* %RefCom)) {
      %Error = $JSONError
    }
    elseif (!$com(%RefCom)) {
      %Error = Retrieving reference failed
    }
  }
  if (!%Error && !$_JSON.CallFunct(%RefCom, [ %param ] )) {
    %Error = $JSONError
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if ($prop != KeepRef && $com(%RefCom)) {
    .comclose $v1
  }
  else {
    .timer 1 1 if ( $!com( %RefCom )) .comclose $!v1
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    _JSON.Log error $!_JSON.CallHandle~ $+ %Error
    return $false
  }
  return $true
}
alias JSONError {
  if ($isid) {
    return %_JSONForMirc:Error
  }
  if ($1- == -c) {
    _JSONLog /JSONError -c~Clearing Error $+ $iif(%_JSONForMirc:Error,: $v1)
    unset %_JSONForMirc:Error
  }
}
alias JSONVersion {
  if ($1 === short) {
    return 2000000.0001
  }
  return JSON for mIRC by SReject v2.0.0001 @ http://github.com/SReject/JSON-For-Mirc
}
alias JSONEscape {
  if ($1 !isnum) {
    return $1
  }
  return " $+ $1 $+ "
}
alias JSON {
  if (!$isid) {
    return
  }
  var %Param, %Error, %Result, %RefCom, %RefClose, %RefCom2, %ToBVar, %ToFile, %RemFile, %ApdCrlf, %FileSize, %Prop, %Type, %BVar, %Result, %Index
  scid $cid var % $+ param = % $+ param $!+ , $!+ $*
  %Param = $mid(%Param, 2-)
  _JSON.Log Calling~$JSON( $+ %Param $+ )
  if (!$0) {
    %Error = Missing Parameters
  }
  elseif ($1 === 0) {
    if ($0 != 1 || $len($prop)) {
      %Error = Invalid parameters: Invalid index(0) used to request members or properties
    }
    elseif (!$_JSON.Call(Manager, get, 1, integer, 0)) {
      %Error = $JSONError
    }
    elseif ($com($_JSON.Com(manager)).result isnum 0-) {
      %Result = $v1
    }
    else {
      %Error = Unable to retrieve handle count
    }
  }
  elseif ($prop == IsRef) {
    if ($0 != 1) {
      %Error = Invalid parameters: Cannot request members when using $!JSON().IsRef
    }
    else {
      %Result = $false
      if ($regex($1, /^JSONForMirc:Tmp:\d+$/i) && $com($1)) {
        %Result = $true
      }
    }
  }
  else {
    if ($regex($1, /^JSONForMirc:Tmp:\d+$/i)) {
      if (!$com($1)) {
        %Error = Reference does not exist
      }
      else {
        %RefCom = $1
      }
    }
    else {
      %RefCom = $_JSON.Com
      if (!$_JSON.Call(Manager, get, 1, bstr, $1, dispatch* %RefCom)) {
        %Error = $JSONError
      }
      elseif (!$com(%RefCom)) {
        %Error = Unable to retrieve reference to ` $+ $1`
      }
      else {
        %RefClose = $true
      }
    }
    if (!%Error && !$len(%Result) && $com(%RefCom)) {
      if ($0 > 1) && ($prop == HttpResponse || $prop == HttpHead || $prop == HttpHeaders || $prop == HttpBody || $prop == ValueTo) {
        if ($prop == ValueTo && $0 < 3) || ($prop != ValueTo && $0 !== 3) {
          %Error = Invalid parameters for $!JSON(). $+ $prop
        }
        elseif (!$regex($2,[bf])) {
          %Error = No 'output' switch specified
        }
        elseif ($regex($2, /([^bfan])/)) {
          %Error = Unknown Switch: $regml(1)
        }
        elseif ($regex($2, /([bf]).*\1/)) {
          %Error = Duplicate Switch: $regml(1)
        }
        elseif (b isincs $2 && f isincs $2) {
          %Error = Conflicting Switch: 'b' and 'f'
        }
        elseif (b isincs $2) {
          if ($2 !== b) {
            %Error = Invalid Switch: b cannot be used with other switches
          }
          elseif (&?* !iswm $3) {
            %Error = Invalid parameters: binary variables must start with &
          }
          elseif ($chr(32) isin $3) {
            %Error = Invalid parameters: binary variables cannot contain spaces
          }
          elseif ($len($3) == 1) {
            %Error = Invalid parameters: No bvar name given
          }
          else {
            %ToBvar = $3
          }
        }
        else {
          %ToFile = $longfn($3)
          %RemFile = $true
          %ApdCrlf = $false
          if ($count(%ToFile, :) > 1) {
            %Error = Illegal filename: Contains multiple ":" characters
          }
          elseif (a isincs $2 && $isfile(%ToFile) && $file(%ToFile).size) {
            %FileSize = $v1
            %RemFile = $false
            if (n isincs $2 && %fileSize > 1) {
              %BVar = $_JSON.TmpBVar
              bread $qt(%ToFile) $calc(%FileSize - 2) 2 %BVar
              if ($bvar(%BVar, 1, 2).text !== $crlf) {
                %ApdCrlf = $true
              }
              bunset %BVar
            }
          }
        }
      }
      if ($istok(Status HttpResponse HttpHead HttpStatus HttpStatusText HttpHeaders HttpHeader HttpBody, $prop, 32)) {
        if (!$_JSON.Call(%RefCom, name, 2)) {
          %Error = $JSONError
        }
        elseif ($com(%RefCom).result {
          %RefCom2 = $_JSON.Com
          if (!$_JSON.Call(Manager, get, 1, bstr, $v1, dispatch* %RefCom2)) {
            %Error = $JSONError
          }
          elseif (!$com(%RefCom2)) {
            %Error = Unable to get handle reference
          }
        }
        else {
          %Error = Unable to get handle reference.
        }
        if (!%Error) {
          if ($prop == HttpHeader) {
            if (!$_JSON.Call(%RefCom2, httpHeader, 1, bstr, $2)) {
              %Error = $JSONError
            }
            else {
              %Result = $com(%RefCom2).result
            }
          }
          else {
            %BVar = $_JSON.TmpBVar
            %Prop = $matchtok(status httpResponse httpHead httpStatus httpStatusText httpHeaders httpBody, $lower($prop), 1, 32)
            if (!$_JSON.Call(%RefCom2, %Prop, 1)) {
              %Error = $JSONError
            }
            elseif (!$com(%RefCom2, %BVar).result) {
              %Error = Unable to retrieve %prop (no data returned)
            }
          }
        }
      }
      elseif (!$prop || $istok(Type Length IsParent Value ValueTo, $prop, 32)) {
        %RefCom2 = $_JSON.Com
        %index = 2
        if ($prop == ValueTo) {
          %index = 4
        }
        %param = $null
        unset %_JSONForMirc:InputCount
        scid $cid % $+ param = $!addtok(% $+ param , $!_JSON.ParseInputs( %index , $* ) , 44)
        if (%param) {
          %param = $chr(44) $+ %param
        }
        if (!$_JSON.Call(manager, traverse, 1, dispatch, %RefCom, [ %param ] , dispatch* %RefCom2)) {
          %Error = $JSONError
        }
        elseif (!$com(%RefCom2)) {
          %Error = Traversing did not create a reference
        }
        elseif (!$prop) {
          %Result = %RefCom2
          %RefCom2 = $null
        }
        elseif ($prop == Type || $prop == Length || $prop == IsParent) {
          %Prop = $matchtok(type length isParent, $Prop, 1, 32)
          if (!$_JSON.Call(%RefCom2, %Prop, 2)) {
            %Error = $JSONError
          }
          else {
            %BVar = $_JSON.TmpBvar
            noop $com(%RefCom2, %BVar).result
          }
          .comclose %RefCom2
        }
        elseif ($prop == Value || $prop == ValueTo) {
          if (!$_JSON.Call(%RefCom2, type, 2)) {
            %Error = Unable to determine reference type
          }
          else {
            %Type = $com(%RefCom2).result
            if (%type == object || %type == array) {
              %Error = Cannot return a value for containers
            }
            elseif (!$_JSON.Call(%RefCom2, value, 2)) {
              %Error = Unable to get the value property
            }
            else {
              %BVar = $_JSON.TmpBvar
              noop $com(%RefCom2, %BVar).result
            }
          }
          .comclose %RefCom2
        }
      }
      else {
        %Error = Unknown property: $prop
      }
      if (!%Error && !%Result) {
        if (%ToBVar) {
          bunset %ToBVar
          bcopy -c %ToBVar 1 -1 %BVar
          %Result = %ToBVar
        }
        elseif (%ToFile) {
          if (%RemFile && $isfile(%ToFile)) {
            .remove $qt(%ToFile)
          }
          if (%ApdCrlf) {
            bcopy -c %BVar 3 -1 %BVar
            bset -t %BVar 1 $crlf
          }
          .bwrite $qt(%ToFile) $calc($file(%ToFile).size +1) -1 %BVar
          %Result = $file(%ToFile).size
        }
        elseif ($bvar(%BVar, 0) > 4000) {
          %Error = Line too long
        }
        else {
          %Result = $bvar(%BVar, 1-).text
        }
      }
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if ($com(%RefCom)) {
    if (%RefClose) {
      .comclose %RefCom
    }
    elseif (!$timer(%RefCom)) {
      $+(.timer,%RefCom) 1 0 if ($com( %RefCom )) .comclose $!v1
    }
  }
  if ($com(%RefCom2)) {
    .comclose %RefCom2
  }
  if (%Error) {
    set -u0 %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error $!JSON~ $+ %Error
  }
  else {
    _JSON.Log Ok $!JSON()~Call successful; returning: %Result
    return %Result
  }
}
alias JSONOpen {
  if ($isid) return
  var %Error, %Switches, %Name, %Type, %Source, %Wait, %Unset, %ErrorCom
  _JSON.Log Calling~/JSONOpen $1-
  if (!$_JSON.Start) {
    %Error =  $JSONError
  }
  else {
    if (-* iswm $1) {
      %Switches = $mid($1, 2-)
      tokenize 32 $2-
    }
    if ($0 < 2) {
      %Error = Missing Parameters
    }
    elseif ($regex(%Switches, ([^dbfuw\-]))) {
      %Error = Invalid switches specified: $regml(1)
    }
    elseif ($regex(%Switches, ([dbfuw]).*?\1)) {
      %Error = Duplicate switch specified: $regml(1)
    }
    elseif ($regex(%Switches, /([bfu])/g) > 1) {
      %Error = Conflicting switches: $regml(1) $+ , $regml(2)
    }
    elseif (u !isin %Switches && w isin %Switches) {
      %Error = -w switch can only be used with -u
    }
    elseif (!$regex($1, /^[a-z][a-z\d_.:\-]+$/i)) {
      %Error = Invalid handler name: Must start with a letter and contain only letters numbers _ . : and -
    }
    elseif (b isincs %Switches && $0 != 2) {
      %Error = Invalid parameter: Binary variable names cannot contain spaces
    }
    elseif (b isincs %Switches && &* !iswm $2) {
      %Error = Invalid parameters: Binary variable names start with &
    }
    elseif (b isincs %Switches && !$bvar($2, 0)) {
      %Error = Invalid parameters: Binary variable is empty
    }
    elseif (u isincs %Switches && $0 != 2) {
      %Error = Invalid parameters: URLs cannot contain spaces
    }
    elseif (f isincs %Switches && !$isfile($2-)) {
      %Error = Invalid parameters: File doesn't exist
    }
    elseif (f isincs %Switches && !$file($2-).size) {
      %Error = Invalid parameters: File is empty
    }
    else {
      %Name = $1
      %Source = $_JSON.TmpBVar
      %Type = text
      %Wait = $false
      %Unset = $true
      if (u isincs %Switches) {
        bset -t %Source 1 $2
        %Type = url
        if (w isincs %Switches) {
          %Wait = $true
        }
      }
      elseif (b isincs %Switches) {
        %Source = $2
        %Unset = $false
      }
      elseif (f isincs %Switches) {
        bread $qt($file($2-)) 0 $file($2-).size %Source
      }
      else {
        bset -t %source 1 $2-
      }
      if (!$_JSON.Call(Manager, create, 1, bstr, %Name, &bstr, %Source, bstr, %Type, bool, %Wait) || $comerr) {
        %Error = $JSONError
      }
      elseif (d isincs %Switches) {
        $+(.timerJSONForMirc:Close, $1) 1 0 JSONClose $1
      }
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%Unset) bunset %Source
  if (%ErrorCom && $com(%ErrorCom)) {
    .comclose $v1
  }
  if (%Error) {
    set -u %JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error /JSONOpen~ $+ %error
  }
  else {
    _JSON.Log ok /JSONOpen~ Successfully created %Name
  }
}
alias JSONHttpMethod {
  if ($isid) {
    return
  }
  _JSON.Log Calling~/JSONHttpMethod $1-
  var %Error
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  elseif ($0 !== 2) {
    %Error = Invalid parameters
  }
  elseif (!$istok(GET POST PUT DEL, $2, 32)) {
    %Error = Invalid method
  }
  elseif (!$_JSON.CallHandle($1, httpSetMethod, bstr, $upper($2)) {
    %Error = $JSONError
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error /JSONHttpMethod~ $+ %Error
  }
  else {
    _JSON.Log Ok /JSONHttpMethod~Call Successful
  }
}
alias JSONHttpHeader {
  if ($isid) {
    return
  }
  _JSON.Log Calling~/JSONHttpHeader $1-
  var %Error, %Header
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  elseif ($0 < 3) {
    %Error = Invalid parameters
  }
  else {
    %Header = $regsubex($2, /(?:^\s+)|(?:\s*:\s*$)/g, )
    if (: isin %header) {
      %Error = Header name invalid(contains ':')
    }
    elseif (!$_JSON.CallHandle($1, httpSetHeader, bstr, %Header, bstr, $3-)) {
      %Error = $JSONError
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error /JSONHttpHeader~ $+ %Error
  }
  else {
    _JSON.Log Ok /JSONHttpHeader~Call Successful
  }
}
alias JSONHttpFetch {
  if ($isid) {
    return
  }
  _JSON.Log Calling~/JSONHttpFetch $1-
  var %Error, %Switches, %BVar, %UnsetBVar
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  else {
    if (-* iswm $1) {
      %Switches = $mid($1, 2-)
      tokenize 32 $2-
    }
    if ($0 < 1) {
      %Error = Missing Parameters
    }
    elseif ($regex(%Switches, ([^bf]))) {
      %Error = Invalid switches specified: $regml(1)
    }
    elseif ($regex(%Switches, ([bf]).*?\1)) {
      %Error = Duplicate switch specified: $regml(1)
    }
    elseif ($regex(%Switches, /([bf])/g) > 1) {
      %Error = Conflicting switches: $regml(1) $+ , $regml(2)
    }
    elseif (%Switches && $0 < 2) {
      %Error = Missing parameters
    }
    elseif (b isincs %Switches && $0 !== 2) {
      %Error = Invalid bvar: Cannot contain spaces
    }
    elseif (b isincs %Switches && $left($2, 1) !== &) {
      %Error = Invalid bvar: Must start with &
    }
    elseif (b isincs %Switches && !$bvar($2,0)) {
      %Error = Invalid bvar: Contains no data
    }
    elseif (f isincs %Switches && !$isfile($2-)) {
      %Error = File does not exist
    }
    elseif (!%Switches) {
      if (!$_JSON.CallHandle($1, httpFetch)) {
        %Error = $JSONError
      }
    }
    else {
      if (b isincs %Switches) {
        %BVar = $2
      }
      else {
        %BVar = $_JSON.TmpBVar
        %Unset%BVar = $true
        if (f isincs %Switches) {
          bread $qt($file($2-).longfn) 0 $file($2-).size %BVar
        }
        else {
          bset -t %BVar 1 $2-
        }
      }
      if (!$_JSON.CallHandle($1, httpFetch, &bstr, %BVar)) {
        %Error = $JSONError
      }
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%UnsetBVar) {
    bunset %BVar
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error /JSONHttpFetch~ $+ %Error
  }
  else {
    _JSON.Log Ok /JSONHttpFetch~Call successful
  }
}
alias JSONClose {
  if ($isid) {
    return
  }
  _JSON.Log Calling~/JSONClose $1-
  var %Error, %Result, %Switches, %Matchtext
  if (!$_JSON.Start) {
    %Error = $v1
  }
  else {
    if (-* iswm $1) {
      %Switches = $mid($1, 2-)
      tokenize 32 $2-
    }
    if ($0 < 1) {
      %Error = Missing parameters
    }
    elseif ($regex(%Switches, ([^sw]))) {
      %Error = Unknown Switch: $regml(1)
    }
    elseif ($regex(%Switches, ([sw]).*\1)) {
      %Error = Duplicate Switch: $regml(1)
    }
    elseif ($regex(%Switchs, /([sw])/g) > 1) {
      %Error = Conflicting Switch: s & w
    }
    else {
      if (s isincs %switches) {
        JSONSave $1-
        if ($JSONError) {
          %Error = $v1
        }
        else {
          %Matchtext = $_JSON.WildcardToRegex($1);
        }
      }
      elseif ($0 !== 1) {
        %Error = Matchtext cannot contain spaces
      }
      else {
        %Matchtext = $_JSON.WildcardToRegex($1);
      }
      if (!%Error && !$_JSON.Call(Manager, close, 1, bstr, %Matchtext)) {
        %Error = $JSONError
      }
      else {
        Result = $com($_JSON.Com(Manager)).result
      }
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error /JSONClose $v1
  }
  else {
    _JSON.Log Ok /JSONClose~Closed %Result handles
  }
}
#JSONForMirc:Debug off
alias -l _JSON.Log {
  if (!$window(@JSONForMircDebug)) {
    JSONDebug off
  }
  else {
    var %color, %prefix, %msg
    if ($1 == Error) {
      %color = 04
    }
    elseif ($1 == Info) {
      %color = 03
    }
    elseif ($1 == Warn) {
      %color = 07
    }
    elseif ($1 == Ok) {
      %color = 12
    }
    if (%color) {
      tokenize 32 $2-
    }
    else {
      %color = 03
    }
    if ($1 == ~) {
      %prefix = JSONForMirc
      %msg = $2-
    }
    elseif ($left($1, 1) == ~) {
      %prefix = JSONForMirc
      %msg = $mid($1-, 2-)
    }
    else {
      %prefix = $gettok($1-, 1, 126)
      %msg = $gettok($1-, 2-, 126)
    }
    aline @JSONForMircDebug $+($chr(3), %color, [, %prefix ,]) %msg
  }
}
#JSONForMirc:Debug end
alias -l _JSON.Log noop
alias JSONDebug {
  if ($isid) {
    if ($group(#JSONForMirc:Debug) == on) {
      return $true
    }
    return $false
  }
  elseif ($1 == on || $1 == enable) {
    if (!$window(@JSONForMircDebug)) {
      window @JSONForMircDebug
    }
    .enable #JSONForMirc:Debug
  }
  elseif ($1 == off || $1 == disable) {
    .disable #JSONForMirc:Debug
  }
  elseif (!$0) {
    if ($group(#JSONForMirc:Debug) != on || !$window(@JSONForMircDebg)) {
      if (!$window(@JSONForMircDebug)) {
        window @JSONForMircDebug
      }
      .enable #JSONForMirc:Debug
    }
    else {
      .disable #JSONForMirc:Debug
    }
  }
}
on *:CLOSE:@JSONForMircDebug:{
  JSONDebug off
}
menu @JSONForMircDebug {
  .Save: if ($window(@JSONForMircDebug) && $line(@JSONForMircDebug, 0) && $sfile($nofile($mircini) $+ JSONForMirc.log, Save As, Save)) { savebuf -a @JSONForMircDebug $qt($v1) }
  .-
  .Clear: clear -@ @JSONForMircDebug
  .Disable: JSONDebug off
  .-
  .Close: close -@ @JSONForMircDebug
}
on *:UNLOAD:{
  var %x = 1, %com
  while ($com(%x)) {
    %com = $v1
    if (JSONForMirc:* iswm %com) {
      .comclose %com
    }
    inc %x
  }
  if ($window(@JSONForMircDebug)) {
    .close -@ @JSONForMircDebug
  }
  unset %_JSONForMirc:*
  bunset &JSONForMirc:*
  .timerJSONForMirc:* off
}
