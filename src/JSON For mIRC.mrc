;; Cleanup debugging when the debug window closes
on *:CLOSE:@SReject/JSONForMirc/Log:{
  .jsondebug off
}



;; Free resources when mIRC exits
on *:EXIT:{
  .jsondebug off
  JSONShutDown
}



;; Free resources when the script is unloaded
on *:UNLOAD:{
  JSONShutDown
}



;; Menu for the debug window
menu @SReject/JSONForMirc/Log {
  .Clear: clear -@ @SReject/JSONForMirc/Log
  .-
  .$style(2) Save: noop
  .-
  .Toggle Debug: jsondebug
}



;; $JSONVersion(@Short)
;;     Returns script version information
;;
;;     @Short - Any text
;;         Returns the short version
alias JSONVersion {
  if ($isid) {
    var %ver = 1.0.0002
    if ($0) {
      return %ver
    }
    return SReject/JSONForMirc v $+ %ver
  }
}



;; $JSONError
;;     Returns any error the last call to /JSON* or $JSON() raised
alias JSONError {
  if ($isid) {
    return %SReject/JSONForMirc/Error
  }
}



;; /JSONOpen -dbfuw @Name @Input
;;     Creates a JSON handle instance
;;
;;     -d: Closes the handler after the script finishes
;;     -b: The input is a bvar
;;     -f: The input is a file
;;     -u: The input is from a url
;;     -w: Used with -u; The handle should wait for /JSONHttpGet to be called to perform the url request
;;
;;     @Name - String - Required
;;         The name to use to reference the JSON handler
;;             Cannot be a numerical value
;;             Disallowed Characters: ? * : and sapce
;;
;;    @Input - String - Required
;;        The input json to parse
;;        If -b is used, the input is contained in the specified bvar
;;        if -f is used, the input is contained in the specified file
;;        if -u is used, the input is a URL that returns the json to parse
alias JSONOpen {

  ;; Insure the alias was called as a command
  if ($isid) return
  
  ;; local variable declarations
  var %Switches = -, %Error, %Com = $false, %Type = text, %Wait = $false, %BVar, %BUnset = $true

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; log the /JSONOpen command is being called
  jfm_log -S /JSONOpen $1-

  ;; remove switches from other input parameters
  if (-* iswm $1) {
    %Switches = $mid($1, 2-)
    tokenize 32 $2-
  }

  ;; Call the com interface initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }

  ;; Basic switch validate
  elseif ($regex(%Switches, ([^dbfuw]))) {
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

  ;; validate handler name input
  elseif ($0 < 2) {
    %Error = Missing Parameters
  }
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = Invalid name
  }
  elseif ($com(JSON: $+ $1)) {
    %Error = Name in use
  }

  ;; Validate URL where appropriate
  elseif (u isin %Switches && $0 != 2) {
    %Error = Invalid parameters: URLs cannot contain spaces
  }

  ;; Validate bvar where appropriate
  elseif (b isin %Switches && $0 != 2) {
    %Error = Invalid parameter: Binary variable names cannot contain spaces
  }
  elseif (b isin %Switches && &* !iswm $2) {
    %Error = Invalid parameters: Binary variable names start with &
  }
  elseif (b isin %Switches && $bvar($2, 0) == $null) {
    %Error = Invalid parameters: Binary variable is empty
  }

  ;; Validate file where appropriate
  elseif (f isin %Switches && $isfile($2-) == $false) {
    %Error = Invalid parameters: File doesn't exist
  }
  elseif (f isin %Switches && !$file($2-).size) {
    %Error = Invalid parameters: File is empty
  }

  ;; all checks passed
  else {
    %Com = JSON: $+ $1
    %BVar = $jfm_TmpBVar

    ;; if input is a bvar indicate it is the bvar to read from and that it
    ;; should NOT be unset after processing
    if (b isincs %Switches) {
      %Bvar = $2
      %BUnset = $false
    }

    ;; If the input is a url store if the request should wait, and set the
    ;; bvar to the URL to request
    elseif (u isincs %Switches) {
      if (w isincs %Switches) {
        %Wait = $true
      }
      %Type = http
      bset -t %BVar 1 $2
    }

    ;; if the input is a file, read the file into a bvar
    elseif (f isincs %Switches) {
      bread $qt($file($2-).longfn) 1 $file($2-).size %BVar
    }

    ;; if the input is text, store the text in a bvar
    else {
      bset -t %BVar 1 $2-
    }

    ;; attempt to create the handler
    %Error = $jfm_Create(%Com, %Type, %BVar, %Wait)
  }

  ;; error handling
  :error

  ;; unset the bvar if it was temporary
  if (%BUnset) {
    bunset %BVar
  }

  ;; if an internal/mIRC error occured, store the error message and clear the
  ;; error state
  if ($error) {
    %Error = $v1
    reseterror
  }

  ;; if the error variable is filled:
  ;;     Store the error in a global variable
  ;;     Start a timer to close the handler script-execution finishes
  ;;     Log the error
  if (%Error) {
    set -eu0 %SReject/JSONForMirc/Error %Error
    if (%Com && $com(%Com)) {
      $+(.timer, %com) 1 0 jsonclose $unsafe($1)
    }
    jfm_log -De %Error
  }

  ;; Otherwise, if the -d switch was specified start a timer to close the com
  ;; and then log the successful handler creation
  else {
    if (d isincs %Switches) {
      $+(.timer, %Com) -o 1 0 JSONClose $unsafe($1)
    }
    jfm_log -Ds Created $1 (as com %Com $+ )
  }
}



;; /JSONHttpMethod @Name @Method
;;     Sets a json's pending HTTP method
;;
;;     @Name - string
;;         The name of the JSON handler
;;
;;     @Method - string
;;         The HTTP method to use
alias JSONHttpMethod {

  ;; Insure the alias was called as a command
  if ($isid) return
  
  ;; local variable declarations
  var %Error, %Com, %Method
  
  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error
  
  ;; Log the alias call
  jfm_log -S /JSONHttpMethod $1-

  ;; Call the com interface initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }
  
  ;; basic input validation
  elseif ($0 < 2) {
    %Error = Missing parameters
  }
  elseif ($0 > 2) {
    %Error = Excessive Parameters
  }
  
  ;; Validate @name parameter
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = Invalid Name
  }
  elseif (!$com(JSON: $+ $1))  {
    %Error = Handler Does Not Exist
  }
  else {
  
    ;; store the com name
    %Com = JSON: $+ $1
    
    ;; trim excess whitespace from the method parameter
    %Method = $regsubex($1, /(^\s+)|(\s*)$/g, )
    
    ;; validate the method parameter
    if (!$len(%Method)) {
      %Error = Invalid method
    }
    
    ;; store the method
    elseif ($jfm_Exec(%Com, httpSetMethod, %Method)) {
      %Error = $v1
    }
  }
  
  ;; Handle errors
  :error
  if ($error) {
    %Error = $v1
    reseterror
  }
  
  ;; if an error occured, store the error in a global variable then log the error
  if (%error) {
    set -u0 %SReject/JSONForMirc/Error %error
    jfm_log -De Failed to set method: %Error
  }
  
  ;; if no errors, log the success
  else {
    jfm_log -Ds Successfully set method to $+(', %Method, ')
  }
}

;; Depreciated; use /JSONHttpMethod
alias JSONUrlMethod {
  if ($isid) return
  JSONHttpMethod $1-
}



;; /JSONHttpHeader @Name @Header @Value
;;     Stores the specified HTTP request header
;;
;;     @Name - String - Required
;;         The open json handler name to store the header for
;;
;;     @Header - String - Required
;;         The header name to store
;;
;;     @Value - String - Required
;;         The value of the header
alias JSONHttpHeader {
  
  ;; Insure the alias was called as a command
  if ($isid) return
  
  ;; local variable declarations
  var %Error, %Com, %Header
  
  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error
  
  ;; Log the alias call
  jfm_log -S /JSONHttpHeader $1-
  
  
  ;; Call the Com interfave initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }
  
  ;; Basic input validation
  elseif ($0 < 3) {
    %Error = Missing parameters
  }
  
  ;; Validate @name parameter
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = Invalid Name
  }
  elseif (!$com(JSON: $+ $1)) {
    %Error = Handler Does Not Exist
  }
  else {
  
    ;; Store the json handler name
    %Com = JSON: $+ $1
    
    ;; Trim whitespace from the header name
    %Header = $regsubex($2, /(^\s+)|(\s*:\s*$)/g, )
    
    ;; Validate @Header
    if (!$len($2)) {
      %Error = Empty header
    }
    elseif ($regex($2, [\r:\n])) {
      %Error = Invalid header
    }
    
    ;; Attempt to store the header
    elseif ($jfm_Exec(%com, httpSetHeader, %Header, $3-)) {
      %Error = $v1
    }
  }
  
  ;; Error Handling
  :error
  if ($error) {
    %Error = $v1
    reseterror
  }
  
  ;; if an error occured, store the error in a global variable then log the error
  if (%Error) {
    set -eu0 %SReject/JSONForMirc/Error %Error
    jfm_log -De Failed to store header: %Error
  }
  
  ;; If no error, log the success
  else {
    jfm_log -Ds Successfully stored header $+(',%header,: $3-,')
  }
}

;; Depreciated; Use /JSONHttpHeader
alias JSONUrlHeader {
  if ($isid) {
    return
  }
  JSONHttpHeader $1-
}



;; /JSONHttpFetch -bf @Name @Data
;;     Performs a pending HTTP request
;;
;;     -b: Data is stored in the specified bvar
;;     -f: Data is stored in the specified file
;;
;;     @Name - string - Required
;;         The name of an open JSON handler with a pending HTTP request
;;
;;     @Data - Optional
;;         Data to send with the HTTP request
alias JSONHttpFetch {

  ;; Insure the alias is called as a command
  if ($isid) return

  ;; Local variable declarations  
  var %Switches = -, %Error, %Com, %BVar, %BUnset
  
  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error
  
  ;; Log the alias call
  jfm_log -S /JSONHttpFetch $1-
  
  ;; Remove switches from other input parameters
  if (-* iswm $1) {
    %Switches = $1
    tokenize 32 $2-
  }
  
  ;; Call the Com interface intializier
  if ($jfm_ComInit) {
    %Error = $v1
  }
  
  ;; Basic input validatition
  if ($0 == 0 || (%Switches != - && $0 < 2)) {
    %Error = Missing parameters
  }
  
  ;; validate switches
  elseif (!$regex(%Switches, ^-[bf]?$)) {
    %Error = Invalid switch
  }
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = Invalid Name
  }
  
  ;; validate @name
  elseif (!$com(JSON: $+ $1)) {
    %Error = Handler Does Not Exist
  }
  
  ;; Validate specified bvar when applicatable
  elseif (b isincs %Switches && (&* !iswm $2 || $0 > 2)) {
    %Error = Invalid Bvar
  }
  
  ;; validate specified file when applicatable
  elseif (f isincs %Switches && !$isfile($2-)) {
    %Error = File Does Not Exist
  }
  else {
  
    ;; Store the com handler name
    %Com = JSON: $+ $1
    
    ;; if @data was specified
    if ($0 > 1) {
    
      ;; Get a temp bvar name
      ;; Indicate the bvar should be unset when the alias finishes
      %BVar = $jfm_tmpbvar
      %BUnset = $true
      
      ;; if the -b switch is specified, use the @data's value as the bvar data to send
      ;; Indicate the bvar should NOT be unset when the alias finishes
      if (b isincs %Switches) {
        %BVar = $2
        %BUnset = $false
      }
      
      ;; if the -f switch is specified, read the file's contents into the temp bvar
      elseif (f isincs %Switches) {
        bread $qt($file($2-).longfn) 1 $file($2-).size %BVar
      }
      
      ;; if no switches were specified, store the @data in the temp bvar
      else {
        bset -t %BVar 1 $2-
      }
      
      ;; attempt to store the data with the handler instance
      %Error = $jfm_Exec(%com, httpSetData, %bvar)
    }
    
    ;; Call the js-side parse function for the handler
    if (!%Error) {
      %Error = $jfm_Exec(%com, parse)
    }
  }

  ;; Handle errors
  :error
  if ($error) {
    %Error = $error
    reseterror
  }
  
  ;; clear the bvar if indicated it should be unset
  if (%BUnset) {
    bunset %BVar
  }

  ;; if an error occured, store the error in a global variable then log the error
  if (%Error) {
    set -eu0 %SReject/JSONForMirc/Error %Error
    jfm_log -De Unable to retreive and parse HTTP data: %Error
  }
  
  ;; Otherwise log the success
  else {
    jfm_log -Ds HTTP data retrieved and parsed
  }
}

;; Depreciated, use /JSONHttpFetch
alias JSONUrlGet {
  if ($isid) return
  JSONHttpFetch $1-
}



;; /JSONClose -w @Name
;;     Closes an open JSON handler and all child handlers
;;
;;     -w: The name is a wildcard
;;
;;     @Name - string - Required
;;         The name of the JSON handler to close
alias JSONClose {

  ;; Insure the alias is called as a command
  if ($isid) return
  
  ;; Local variable declarations 
  var %Switches, %Error, %Match, %Com, %x = 1
  
  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error
  
  ;; Log the alias call
  jfm_log -S /JSONClose $1-
  
  ;; Remove switches from other input parameters
  if (-* iswm $1) {
    %Switches = $mid($1, 1-)
    tokenize 32 $2-
  }
  
  ;; Basic input validation
  if ($0 < 1) {
    %Error = Missing parameters
  }
  elseif ($0 > 1) {
    %Error = Too many parameters specified.
  }
  
  ;; validate switches
  elseif ($regex(%Switches, /([^w]))) {
    %error = Unknown switch specified: $regml(1)
  }
  
  ;; validate @Name
  elseif (: isin $1 && (w isincs %Switches || JSON:* !iswmcs $1)) {
    %Error = Invalid parameter
  }
  else {
  
    ;; Format @Name to match as a regex
    %Match = $1
    if (JSON:* iswmcs $1) {
      %Match = $gettok($1, 2-, 58)
    }
    %Match = $replacecs(%Match, \E, \E\\E\Q)
    if (w isincs $1) {
      %Match = $replacecs(%Match, ?, \E[^:]\Q, *,\E[^:]*\Q)
    }
    %Match = /^JSON:\Q $+ %Match $+ \E(?:$|:)/i
    
    ;; increase the indent for log lines
    jfm_log -i
    
    ;; loop over all comes
    while (%x <= $com(0)) {
      %Com = $com(%x)
      
      ;; check if the com name matches to formatted @name
      if ($regex(%Com, %Match)) {
      
        ;; close the com, turn off timers associated to the com and log the close
        .comclose %Com
        if ($timer(%Com)) {
          $+(.timer, %Com) off
        }
        jfm_log -s Closed %Com
      }
      
      ;; otherwise move on to the next com
      else {
        inc %x
      }
    }
  }
  
  ;; Handle Errors
  :error
  if ($error) {
    %Error = $error
    reseterror
  }
  
  ;; if an error occured, store the error in a global variable then log the error
  if (%error) {
    set -eu0 %SReject/JSONForMirc/Error %Error
    jfm_log -De /JSONClose %Error
  }
  
  ;; If no errors, decrease the indent for log lines
  else {
    jfm_log -D
  }
}



;; /JSONList
;;     Lists all open JSON handlers
alias JSONList {
  
  ;; Insure the alias was called as a command
  if ($isid) return
 
  ;; Local variable declarations
  var %x = 1, %i = 0
 
  ;; Log the alias call
  jfm_log -S /JSONList $1-
 
  ;; loop over all open coms
  while ($com(%x)) {
  
    ;; If the com is a json handler, output the name
    if (JSON:?* iswm $v1) {
      inc %i
      echo $color(info) -a * # $+ %i : $v1
    }
    inc %x
  }
  
  ;; If no json handlers were found, output such
  if (!%i) {
    echo $color(info) -a * No active JSON handlers
  }
  
  ;; decrease the indent for log lines
  jfm_log -D
}



;; /JSONShutDown
;;    Closes all JSON handler coms and unsets all global variables
alias JSONShutDown {

  ;; Insure the alias was called as a command
  if ($isid) return

  ;; close all json instances
  JSONClose -w *
  
  ;; Close the JSON engine and shell coms
  if ($com(SReject/JSONForMirc/JSONEngine)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell)) {
    .comclose $v1
  }
  
  ;; unset all related global variables
  unset %SReject/JSONForMirc/?*
}



;;
;;
;;
alias JSON {
  if (!$isid || !$0) {
    return
  }
  
  
  var %Args, %x = 1, %Error, %Com, %i = 0, %Prefix, %Prop, %Suffix, %Offset = $iif(*toFile iswm $prop,3,2), %Type, %Output, %Result, %ChildCom, %Params
  
  
  unset %SReject/JSONForMirc/Error
  

  while (%x <= $0) {
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %x, 2)
    if (%x >= %Offset) {
      %Params = %Params $+ ,bstr,$ $+ %x
    }
    inc %x
  }
  
  jfm_log -S $!JSON( $+ %args $+ ) $+ $iif($len($prop), . $+ $prop)
  %x = 1
  
  if ($0 == 1 && $1 == 0 && $len($prop)) {
    jfm_log -D
    return
  }
  
  if (: isin $1) || ($1 === 0 && $0 !== 1) {
    %Error = Invalid name
  }
  elseif (JSON:?* iswmcs $1) {
    %Com = $1
  }
  elseif (* isin $prop || ? isin $prop) {
    %Error = Invalid property
  }
  elseif ($regex($1, /^\d+$/)) {
    while ($com(%x)) {
      if (JSON:* iswmcs $v1) {
        inc %i
        if ($1 && %i === $1) {
          %Com = $com(%x)
          break
        }
      }
      inc %x
    }
    if ($1 === 0) {
      jfm_log -Ds %i
      return %i
    }
  }
  else {
    %Com = JSON: $+ $1
  }
  if (!%Error && !$com(%Com)) {
    %Error = No such json handler
  }
  if ($regex($prop, /^((?:fuzzy)?)(.*?)((?:to(?:bvar|file))?)?$/i)) {
    %Prefix = $regml(1)
    %Prop   = $regml(2)
    %Suffix = $regml(3)
  }
  %Prop = $regsubex(%Prop, /^url/i, http)
  if (%Prop == status) {
    %Prop = state
  }
  if (%Prop == data)   {
    %Prop = input
  }
  if (%Prop == isRef)  {
    %Prop = isChild
  }
  if (%Suffix, == tofile) {
    if ($0 < 2) {
      %Error = Invalid parameters
    }
    elseif (!$len($2) || $isfile($2) || (!$regex($2, /[\\\/]/) && " isin $2)) {
      %Error = Invalid file
    }
    else {
      %Output = $longfn($2)
    }
  }
  if (%Error) {
    goto error
  }
  elseif ($0 == 1 && !$prop) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 %Com
  }
  elseif (%prop == isChild) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 $iif(JSON:?*:?* iswm %Com, $true, $false)
  }
  elseif ($wildtok(state|inputType|input|error, %Prop, 1, 124)) {
    if ($jfm_Eval(%Com, $v1)) {
      %Error = $v1
    }
    else {
      %Result = %SReject/JSONForMirc/Eval
    }
  }
  elseif (%Prop == httpHeader) {
    if ($calc($0 - %Offset) < 0) {
      %Error = Invalid Parameters
    }
    elseif ($jfm_Exec(%Com, httpHeader, $($ $+ %Offset, 2))) {
      %Error = $v1
    }
    else {
      %Result = %SReject/JSONForMirc/Exec
    }
  }
  elseif ($wildtok(httpHead|httpStatus|httpStatusText|httpHeaders|httpBody|httpResponse|debugString, %Prop, 1, 124)) {
    if ($jfm_Exec(%Com, $v1)) {
      %Error = $v1
    }
    else {
      %Result = %SReject/JSONForMirc/Exec
    }
  }
  elseif (!%Prop || $wildtok(Type|Path|Value|Length|isParent|fuzzy|String, %Prop, 1, 124)) {
    %Prop = $v1
    if ($0 >= %Offset) {
      %x = $ticks
      while ($com(%Com $+ : $+ %x)) {
        inc %x
      }
      %ChildCom = $+(%Com, :, %x)
      var %call = $!com( $+ %com $+ ,walk,1,bool, $+ $iif(fuzzy == %Prefix, $true, $false) $+ %Params $+ ,dispatch* %ChildCom $+ )
      jfm_log -i %call
      %Params   = %call
      if (!$eval(%params, 2) || $comerr || !$com(%ChildCom)) {
        %Error = $jfm_GetError
        goto error
      }
      $+(.timer, %ChildCom) -o 1 0 JSONClose %ChildCom
      %Com = %ChildCom
      jfm_log -d
    }
    if (%Prop == Length || %Prop == Path || %Prop = String) {
      if ($jfm_Exec(%Com, json $+ %Prop)) {
        %Error = $v1
      }
      else {
        %Result = %SReject/JSONForMirc/Exec
      }
    }
    else {
      if ($jfm_Exec(%Com, jsonType)) {
        %Error = $v1
      }
      elseif (%Prop == type) {
        %Result = %SReject/JSONForMirc/Exec
      }
      else {
        %Type = $bvar(%SReject/JSONForMirc/Exec, 1-).text
        if (%Prop == isParent) {
          %Result = $jfm_TmpBvar
          bset -t %Result 1 $iif(%Type == object || %Type == array, $true, $false)
        }
        elseif (%Type == object || %Type == array) {
          if (%Prop === value) {
            %Error = INVALID TYPE
          }
          else {
            %Result = $jfm_TmpBvar
            bset -t %Result 1 %Com
          }
        }
        else {
          if ($jfm_Exec(%Com,  jsonValue)) {
            %Error = $v1
          }
          else {
            %Result = %SReject/JSONForMirc/Exec
          }
        }
      }
    }
  }
  else {
    %Error = Unknown Property
  }
  if (!%Error) {
    if (%Suffix == tofile) {
      bwrite %Output -1 -1 %Result
      bunset %Result
      jfm_log -Ds %Output
      return %Output
    }
    elseif (%Suffix == tobvar) {
      jfm_log -Ds %Result
      return %Result
    }
    else {
      jfm_log -Ds Result: $bvar(%Result, 1, 4000).text
      return $bvar(%Result, 1, 4000).text
    }
  }
  :error
  if (%BUnset) {
    bunset %BVar
  }
  if ($error) {
    %Error = $error
    reseterror
  }
  if (%Error) {
    jfm_log -De $!JSON %Error
    set -u0 %SReject/JSONForMirc/Error %Error
  }
}



;; /JSONDebug @State
;;     Changes the current debug state
;;
;; $JSONDebug
;;     Returns the current debug state
;;         $true for on
;;         $false for off
alias JSONDebug {
  var %State = $false
  if ($group(#SReject/JSONForMirc/Log) == on) {
    %State = $true
  }
  if ($isid) {
    return %State
  }
  elseif (!$0 || $1 == toggle) {
    if (%State) {
      tokenize 32 disable
    }
    else {
      tokenize 32 enable
    }
  }
  if ($1 == on || $1 == enable) {
    if (%State) {
      echo $color(info).dd -atng * /JSONDebug: debug already enabled
      return
    }
    .enable #SReject/JSONForMirc/Log
    %State = $true
  }
  elseif ($1 == off || $1 == disable) {
    if (!%State) {
      echo $color(info).dd -atng * /JSONDebug: debug already disabled
      return
    }
    .disable #SReject/JSONForMirc/Log
    %State = $false
  }
  else {
    echo $color(info).dd -atng * /JSONDebug: Unknown input
    return
  }
  if (%State) {
    if (!$window(@SReject/JSONForMirc/Log)) {
      window -zk0e @SReject/JSONForMirc/Log
    }
    echo $color(info2) @SReject/JSONForMirc/Log [JSONDebug] Debug now enabled
  }
  elseif ($Window(@SReject/JSONForMirc/Log)) {
    echo $color(info2) @SReject/JSONForMirc/Log [JSONDebug] Debug now disabled
  }
}



;; $jfm_TmpBVar
;;     Returns the name of a not-in-use temporarily bvar
alias -l jfm_TmpBVar {
  jfm_log -i $!jfm_TmpBVar
  var %n = $ticks
  :next
  if (!$bvar(&SReject/JSONForMirc/Tmp $+ %n)) {
    jfm_log -isd Returning: &SReject/JSONForMirc/Tmp $+ %n
    jfm_log -d
    return &SReject/JSONForMirc/Tmp $+ %n
  }
  inc %n
  goto next
}



;; /jfm_badd @bvar @Text
;;     Appends the specified text to a bvar
;;
;;     @Bvar - String - Required
;;         The bvar to append text to
;;
;;     @Text - String - Required
;;         The text to append to the bvar
alias -l jfm_badd {
  bset -t $1 $calc(1 + $bvar($1, 0)) $2-
}



;; $jfm_ComInit
;;     Creates the com instances required for the script to work
;;         Returns any errors that occured while initializing the coms
alias -l jfm_ComInit {
  jfm_log -i $!jfm_ComInit
  if ($com(SReject/JSONForMirc/JSONShell) && $com(SReject/JSONForMirc/JSONEngine)) {
    jfm_log -isd initialized
    jfm_log -d
    return
  }
  var %Error, %js = $jfm_tmpbvar, %s = jfm_badd %js, %f = $scriptdirJSON For Mirc.js

  bread $qt(%f) 0 $file(%f).size %js

  if ($com(SReject/JSONForMirc/JSONEngine)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell)) {
    .comclose $v1
  }

  if ($len($~adiircexe) && $appbits == 64) {
    .comopen SReject/JSONForMirc/JSONShell ScriptControl
  }
  else {
    .comopen SReject/JSONForMirc/JSONShell MSScriptControl.ScriptControl
  }
  var %Error
  if (!$com(SReject/JSONForMirc/JSONShell) || $comerr) {
    %Error = Unable to create ScriptControl
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell, language, 4, bstr, jscript) || $comerr) {
    %Error = Unable to set ScriptControl's language
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell, timeout, 4, bstr, 90000) || $comerr) {
    %Error = Unable to set ScriptControl's timeout to 90seconds
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell, ExecuteStatement, 1, &bstr, %js) || $comerr) {
    %Error = Unable to execute required jScript
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell, Eval, 1, bstr, this, dispatch* SReject/JSONForMirc/JSONEngine) || $comerr || !$com(SReject/JSONForMirc/JSONEngine)) {
    %Error = Unable to get jScript engine reference
  }
  else {
    jfm_log -isd Successfully initialized
    jfm_log -d
  }
  :error
  if ($error) {
    %Error = $v1
    reseterror
  }
  if (%Error) {
    if ($com(SReject/JSONForMirc/JSONEngine)) {
      .comclose $v1
    }
    if ($com(SReject/JSONForMirc/JSONShell)) {
      .comclose $v1
    }
    jfm_log -ied Error: %Error
    jfm_log -d
    return %Error
  }
}



;; $jfm_GetError
;;     Attempts to get the last error that occured in the JS handler
alias -l jfm_GetError {
  jfm_log -i !$jfm_GetError
  var %Error = UNKNOWN
  if ($com(SReject/JSONForMirc/JSONShell).errortext) {
    %Error = $v1
  }
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell, Error, 2, dispatch* SReject/JSONForMirc/JSONShellError) && !$comerr && $com(SReject/JSONForMirc/JSONShellError) && $com(SReject/JSONForMirc/JSONShellError, Description, 2) && !$comerr) {
    if ($com(SReject/JSONForMirc/JSONShellError).result) {
      %Error = $v1
    }
  }
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose $v1
  }
  jfm_log -isd %Error
  jfm_log -d
  return %Error
}



;; $jfm_Exec(@Name, @Method, [@Args])
;;     Executes the js method of the specified name
;;
;;     @Name - string - Required
;;         The name of the open JSON handler
;;
;;     @Method - string - Required
;;         The method of the open JSON handler to call
;;
;;     @Args - string - Optional
;;         The arguments to pass to the method
alias -l jfm_Exec {
  unset %SReject/JSONForMirc/Exec
  var %Args, %Index = 1, %Result, %Params
  :args
  if (%Index <= $0) {
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %Index, 2)
    if (%Index >= 3) {
      %Params = %Params $+ ,bstr,$ $+ %Index
    }
    inc %Index
    goto args
  }
  jfm_log -i $!jfm_Exec( $+ %Args $+ )
  %params = $!com($1,$2,1 $+ %Params $+ )
  if (!$(%Params, 2) || $comerr) {
    %Result = $jfm_GetError
    jfm_log -ed Error: %Result
    return %Result
  }
  set -u0 %SReject/JSONForMirc/Exec $jfm_tmpbvar
  noop $com($1, %SReject/JSONForMirc/Exec).result
  jfm_log -isd Result stored in %SReject/JSONForMirc/Exec
  jfm_log -d
}



;; $jfm_Eval(@Name, @Property, [@args])
;;     Evaluates the js method of the specified name
;;         Returns any errors that occured
;;         Or fills a bvar with the result
;;
;;     @Name - string - Required
;;         The name of the open JSON handler
;;
;;     @Method - string - Required
;;         The method of the open JSON handler to call
;;
;;     @Args - string - Optional
;;         The arguments to pass to the method
alias -l jfm_Eval {
  unset %SReject/JSONForMirc/Eval
  var %Args, %Index = 1, %Result, %Params
  :args
  if (%Index <= $0) {
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %Index, 2)
    if (%Index >= 3) {
      %Params = %Params $+ ,bstr,$ $+ %Index
    }
    inc %Index
    goto args
  }
  jfm_log -i $!jfm_Exec( $+ %Args $+ )
  %params = $!com($1,$2,2 $+ %Params $+ )
  if (!$(%Params, 2) || $comerr) {
    %Result = $jfm_GetError
    jfm_log -ed Error: %Result
    return %Result
  }
  set -u0 %SReject/JSONForMirc/Eval $jfm_tmpbvar
  noop $com($1, %SReject/JSONForMirc/Eval).result
  jfm_log -isd Result stored in %SReject/JSONForMirc/Eval
  jfm_log -d
}



;; $jfm_create(@Name, @type, @Source, @Wait)
;;    Attempts to create the JSON handler com instance
;;
;;    @Name - String - Required
;;        The name of the JSON handler to create
;;
;;    @Type - string - required
;;        The type of json handler
;;            text: the input is a bvar
;;            http: the input is a url
;;
;;    @Source - string - required
;;        The source of the input
;;
;;    @Wait - string - required
;;        Indicates if the HTTP request should wait for JSONHttpFetch to be called
alias -l jfm_Create {
  jfm_log -i $!jfm_create( $+ $1 $+ , $+ $2 $+ , $+ $3 $+ , $+ $4)
  var %result
  if (!$com(SReject/JSONForMirc/JSONEngine, JSONCreate, 1, bstr, $2, &bstr, $3, bool, $4, dispatch* $1) || $comerr || !$com($1)) {
    if ($com($1)) {
      .comclose $v1
    }
    %Result = $jfm_GetError
    jfm_log -ied %Result
    jfm_log -d
    return %Result
  }
}



#SReject/JSONForMirc/Log off
;; Logs debug messages
alias -l jfm_log {
  if (!$window(@SReject/JSONForMirc/Log)) {
    .JSONDebug off
    unset %SReject/JSONForMirc/LogIndent
  }
  else {
    var %switches = -, %Prefix = 03->
    if (-?* iswm $1) {
      %switches = $mid($1, 2-)
      tokenize 32 $2-
    }
    if (S isincs %Switches) {
      set -u0 %SReject/JSONForMirc/LogIndent 0
      %Prefix = 13->
    }
    if (D isincs %Switches) {
      set -u0 %SReject/JSONForMirc/LogIndent 1
    }
    if (i isincs %Switches) {
      inc -u0 %SReject/JSONForMirc/LogIndent
    }
    if ($0) {
      if (e isincs %Switches) {
        %Prefix = 04->
      }
      elseif (s isincs %Switches) {
        %Prefix = 12->
      }
      aline @SReject/JSONForMirc/Log $str($chr(32) $+ , $calc(%SReject/JSONForMirc/LogIndent *4)) $+ %Prefix $1-
    }
    if (D isincs %Switches) {
      unset %SReject/JSONForMirc/LogIndent
    }
    elseif (d isincs %Switches) {
      if (%SReject/JSONForMirc/LogIndent > 0) {
        dec -u0 %SReject/JSONForMirc/LogIndent
      }
      else {
        set -u0 %SReject/JSONForMirc/LogIndent 0
      }
    }
  }
}
#SReject/JSONForMirc/Log end
alias -l jfm_log noop
