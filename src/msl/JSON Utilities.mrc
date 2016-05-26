/** $_JSON.Com
***     Returns either the wrapper com name, the JS Engine com name, Handle Manager com name, or a com name thats not in use
**/
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


/** $_JSON.TmpBVar
***     Returns the name of a new bvar
**/
alias -l _JSON.TmpBVar {
  var %n = $ticks * 1000
  while ($bvar(&JSONForMirc:Tmp: $+ %n, 0)) {
    inc %n
  }
  _JSON.Log $!_JSON.TmpBVar~Returning &JSONForMirc:Tmp: $+ %n as temporary binary variable
  return &JSONForMirc:Tmp: $+ %n
}


/** $_JSON.TmpFile
***     Returns a new temp file path
**/
alias -l _JSON.TmpFile {
  var %dir = $nofile($mircini) $+ data\, %n = $ticks * 1000

  ;; create the directory ..\data\JSONForMirc\
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


/** $_JSON.ParseInputs
***    Parse inputs so they can be safely passed to the com
**/
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


/** $_JSON.UnEscape
***     Handles the unescaping of inputs prior to com calls
**/
alias -l _JSON.UnEscape {
  if ("*" !iswm $1) {
    return $1
  }
  return $mid($1, 2-, -1)
}


/** $_JSON.WildcardToRegex(@input)
***     Converts the input wildcard matchtext to a regex pattern
**/
alias -l _JSON.WildcardToRegex {
  return $+(^, $regsubex($1-,/([\Q$^|[]{}()\/.+\E])|(&(?= |$))|([?*]+)/g, $_JSON.WildcardToRegexRep(\t)), $chr(36))
}
alias -l _JSON.WildcardToRegexRep {
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


/** $_JSON.Call(COMName|GlobalCOM, params...)
***     Attempts to make a call against the specified com
**/
alias -l _JSON.Call {
  ;; Variable setup
  var %Com, %Error, %ErrorCom, %param

  ;; Output debug message
  scid $cid var % $+ param = % $+ param $!+ $!chr(44) $!+ $*
  %Param = $mid(%Param, 2-)
  _JSON.Log Calling~$_JSON.Call( $+ %Param $+ )


  _JSON.Log $!_JSON.Call~Attempting to get Com Name

  ;; Figure out which com to use
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

  ;; Output to log
  _JSON.Log ok $!_JSON.Call~Using %com as com name
  _JSON.Log $!_JSON.Call~Making Com Call

  ;; Perform the com call
  if (!$com(%Com, [ $gettok(%param, 2-, 44) ] ) || $comerr) {

    _JSON.Log $!_JSON.Call~Call ended with an error, attempting to get error

    %ErrorCom = $_JSON.Com

    ;; Attempt to retrieve the error message
    if (!$com($_JSON.Com(Wrapper), Error, 2, dispatch* %ErrorCom) || $comerr || !$com(%ErrorCom)) {
      %Error = Call Error (Unable to retrieve Error state)
    }
    else {

      ;; Get the error message
      if (!$com(%ErrorCom, Description, 2) || $comerr) {
        %Error = Call Error (Unable to retrieve Error message)
      }
      elseif ($com(%ErrorCom).result) {
        %Error = Call Error ( $+ $v1 $+ )
      }
      else {
        %Error = Call Error (Unable to retrieve reason message)
      }

      ;; Clear the error
      noop $com(%ErrorCom, Clear, 1)
    }
  }

  ;; Error handling
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


/** $_JSON.CallHandle(Handle, params...)
***     Attempts to make a call against the specified handle
**/
alias -l _JSON.CallHandle {
   var %Error, %CloseRef, %RefCom, %Param

  ;; Debug message
  scid $cid var % $+ param = % $+ param $*
  %Param = $mid(%Param, 2-)
  _JSON.Log Calling~$_JSON.CallHandle( $+ %Param $+ )


  ;; Validate passed Reference Com handling
  if ($regex($1, /^JSONForMirc:Tmp:\d+$/i)) {
    if (!$com($1)) {
      %Error = Reference Com does not exist
    }
    else {
      %RefCom = $1
    }
  }

  ;; Attempt to get the handle ref
  else {
    %RefCom = $_JSON.Com
    if (!$_JSON.Call(Manager, get, 1, bstr, $1, dispatch* %RefCom)) {
      %Error = $JSONError
    }
    elseif (!$com(%RefCom)) {
      %Error = Retrieving reference failed
    }
  }

  ;; Make the call against the reference
  if (!%Error && !$_JSON.CallFunct(%RefCom, [ %param ] )) {
    %Error = $JSONError
  }

  ;; Error handling
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


/** /JSONError -c
***     Clears the JSONError variable
***
*** $JSONError
***     Returns the last error to occur from a JSONForMirc call
**/
alias JSONError {
  if ($isid) {
    return %_JSONForMirc:Error
  }
  if ($1- == -c) {
    _JSONLog /JSONError -c~Clearing Error $+ $iif(%_JSONForMirc:Error,: $v1)
    unset %_JSONForMirc:Error
  }
}


/** $JSONVersion
***     Returns the current JSONForMirc version
***
*** $JSONVersion(short)
***     Returns the numerical representation of the current JSONForMirc version
**/
alias JSONVersion {
  if ($1 === short) {
    return 2000000.0001
  }
  return JSON for mIRC by SReject v2.0.0001 @ http://github.com/SReject/JSON-For-Mirc
}


/** $JSONEscape()
***     Escapes inputs so they are assumed as keys
**/
alias JSONEscape {
  if ($1 !isnum) {
    return $1
  }
  return " $+ $1 $+ "
}