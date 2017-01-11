;; Cleanup debugging when the debug window closes
on *:CLOSE:@SReject/JSONForMirc/Log:{
  if ($jsondebug) {
    jsondebug off
  }
}



;; Free resources when mIRC exits
on *:EXIT:{
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
  .$iif(!$jfm_SaveDebug, $style(2)) Save: jfm_SaveDebug
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
    var %ver = 1.0.1003
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
;;     -U: The input is from a url and its data should not be parsed
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

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; local variable declarations
  var %Switches, %Error, %Com = $false, %Type = text, %httpOptions = 0, %BVar, %BUnset = $true

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
  elseif ($regex(%Switches, ([^dbfuUw]))) {
    %Error = SWITCH_INVALID: $+ $regml(1)
  }
  elseif ($regex(%Switches, ([dbfuUw]).*?\1)) {
    %Error = SWITCH_DUPLICATE: $+ $regml(1)
  }
  elseif ($regex(%Switches, /([bfuU])/g) > 1) {
    %Error = SWITCH_CONFLICT: $+ $regml(1)
  }
  elseif (u !isin %Switches && w isincs %Switches) {
    %Error = SWITCH_NOT_APPLICABLE:w
  }

  ;; validate handler name input
  elseif ($0 < 2) {
    %Error = PARAMETER_MISSING
  }
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = NAME_INVALID
  }
  elseif ($com(JSON: $+ $1)) {
    %Error = NAME_INUSE
  }

  ;; Validate URL where appropriate
  elseif (u isin %Switches && $0 != 2) {
    %Error = PARAMETER_INVALID:URL_SPACES
  }

  ;; Validate bvar where appropriate
  elseif (b isincs %Switches && $0 != 2) {
    %Error = PARAMETER_INVALID:BVAR
  }
  elseif (b isincs %Switches && &* !iswm $2) {
    %Error = PARAMETER_INVALID:NOT_BVAR
  }
  elseif (b isincs %Switches && $bvar($2, 0) == $null) {
    %Error = PARAMETER_INVALID:BVAR_INUSE
  }

  ;; Validate file where appropriate
  elseif (f isincs %Switches && $isfile($2-)) {
    %Error = PARAMETER_INVALID:FILE_INUSE
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
    elseif (u isin %Switches) {
      if (U isincs %Switches) {
        inc %httpOptions 2
      }
      if (w isincs %Switches) {
        inc %httpOptions 1
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
    %Error = $jfm_Create(%Com, %Type, %BVar, %httpOptions)
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
      $+(.timer, %com) 1 0 JSONClose $unsafe($1)
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

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; local variable declarations
  var %Error, %Com, %Method

  ;; Log the alias call
  jfm_log -S /JSONHttpMethod $1-

  ;; Call the com interface initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }

  ;; basic input validation
  elseif ($0 < 2) {
    %Error = PARAMETER_MISSING
  }
  elseif ($0 > 2) {
    %Error = PARAMETER_INVALID
  }

  ;; Validate @name parameter
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = NAME_INVALID
  }
  elseif (!$com(JSON: $+ $1))  {
    %Error = NAME_DOES_NOT_EXIST
  }
  else {

    ;; store the com name
    %Com = JSON: $+ $1

    ;; trim excess whitespace from the method parameter
    %Method = $regsubex($2, /(^\s+)|(\s*)$/g, )

    ;; validate the method parameter
    if (!$len(%Method)) {
      %Error = INVALID_METHOD
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

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; local variable declarations
  var %Error, %Com, %Header

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

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; Local variable declarations
  var %Switches = -, %Error, %Com, %BVar, %BUnset

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
      %Error = $jfm_Exec(%com, httpSetData, & %bvar).fromBvar
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

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; Local variable declarations
  var %Switches, %Error, %Match, %Com, %x = 1

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

  ;; Validate switches
  elseif ($regex(%Switches, /([^w]))) {
    %error = Unknown switch specified: $regml(1)
  }

  ;; Validate @Name
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

    ;; Increase the indent for log lines
    jfm_log -i

    ;; Loop over all comes
    while (%x <= $com(0)) {
      %Com = $com(%x)

      ;; Check if the com name matches to formatted @name
      if ($regex(%Com, %Match)) {

        ;; Close the com, turn off timers associated to the com and log the close
        .comclose %Com
        if ($timer(%Com)) {
          $+(.timer, %Com) off
        }
        jfm_log -s Closed %Com
      }

      ;; Otherwise move on to the next com
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

  ;; Decrease the indent for log lines
  jfm_log -D
}



;; /JSONShutDown
;;    Closes all JSON handler coms and unsets all global variables
alias JSONShutDown {

  ;; Insure the alias was called as a command
  if ($isid) return

  ;; Close all json instances
  JSONClose -w *

  if ($JSONDebug) {
    JSONDebug off
  }

  if ($window(@SReject/JSONForMirc/Log)) {
    close -@ $v1
  }

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



;; $JSON(@Name|Ref|N, [@file,] [@Members...]).@Prop
;;     Returns information pretaining to an open JSON handler
;;
alias JSON {

  ;; Insure the alias was called as an identifier and that atleast one parameter has been stored
  if (!$isid || !$0) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; Local variable declartions
  var %x = 1, %Args, %Params, %Error, %Com, %i = 0, %Prefix, %Prop, %Suffix, %Offset = $iif(*toFile iswm $prop,3,2), %Type, %Output, %Result, %ChildCom, %Call

  ;; Loop over all parameters
  while (%x <= $0) {

    ;; store each parameter in %args delimited by a comma(,)
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %x, 2)

    ;; if the parameter is greater than the offset store it the parameter under %Params
    if (%x >= %Offset) {
      %Params = %Params $+ ,bstr,$ $+ %x
    }
    inc %x
  }
  %x = 1

  ;; Log the alias call
  jfm_log -S $!JSON( $+ %args $+ ) $+ $iif($len($prop), . $+ $prop)

  ;; If the alias was called with with a single input of 0 and a prop
  ;;     silently fail the call
  if ($0 == 1 && $1 == 0 && $len($prop)) {
    jfm_log -D
    return
  }

  ;; If the @name parameter starts with JSON assume its the name of the JSON com
  if (JSON:?* iswmcs $1) {
    %Com = $1
  }

  ;; Otherwise, do basic validation on the @Name parameter
  elseif (: isin $1 || * isin $1 || ? isin $1) || ($1 == 0 && $0 !== 1) {
    %Error = INVALID_NAME
  }

  ;; if @Name is a numerical value
  elseif ($regex($1, /^\d+$/)) {

    ;; loop over all coms
    while ($com(%x)) {

      ;; if the com is a json handler and
      ;;    The handler's index matches that of input
      ;;    assume the handler is the one requested and make use of it for further operations
      if ($regex($v1, /^JSON:[^:]+$/)) {
        inc %i
        if (%i === $1) {
          %Com = $com(%x)
          break
        }
      }
      inc %x
    }

    ;; if @Name is 0 return the total number of JSON handlers
    if ($1 === 0) {
      jfm_log -Ds %i
      return %i
    }
  }

  ;; Otherwise assume @Name is the name of a JSON handler, as-is
  else {
    %Com = JSON: $+ $1
  }

  ;; If the deduced com doesn't exist store the error
  if (!%Error && !$com(%Com)) {
    %Error = HANDLER_NOT_FOUND
  }

  ;; basic property validation
  elseif (* isin $prop || ? isin $prop) {
    %Error = INVALID_PROP
  }
  else {

    ;; Divide up the prop as needed, following the format of [fuzzy][prop_name][tobvar|tofile]
    if ($regex($prop, /^((?:fuzzy)?)(.*?)((?:to(?:bvar|file))?)?$/i)) {
      %Prefix = $regml(1)
      %Prop   = $regml(2)
      %Suffix = $regml(3)
    }

    ;; URL props have been depreciated, switch the prop to the HTTP equivulant
    %Prop = $regsubex(%Prop, /^url/i, http)

    ;; .status has been depreciated; use .state
    if (%Prop == status) {
      %Prop = state
    }

    ;; .data has been depreciated; use .input
    if (%Prop == data)   {
      %Prop = input
    }

    ;; .isRef has been depreciated; use .isChild
    if (%Prop == isRef)  {
      %Prop = isChild
    }

    ;; .isParent is depreciated; use .isContainer
    if (%Prop == isParent) {
      %Prop = isContainer
    }

    ;; if the suffix is 'tofile', validate the 2nd parameter
    if (%Suffix, == tofile) {
      if ($0 < 2) {
        %Error = INVALID_PARAMETERS
      }
      elseif (!$len($2) || $isfile($2) || (!$regex($2, /[\\\/]/) && " isin $2)) {
        %Error = INVALID_FILE
      }
      else {
        %Output = $longfn($2)
      }
    }
  }

  ;; If an error has occured, skip to error handling
  if (%Error) {
    goto error
  }

  ;; If @Name is an index and no prop has been specified the result is the com name
  ;; So create a new bvar for the result and store the com name in it
  elseif ($0 == 1 && !$prop) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 %Com
  }

  ;; if the prop is isChild:
  ;;   create a new bvar for the result
  ;;   deduce if the specified handler is a child
  elseif (%prop == isChild) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 $iif(JSON:?*:?* iswm %Com, $true, $false)
  }

  ;; These props do not require the json data to be walked or an input to be specified:
  ;;   Attempt to call the respective js function
  ;;   Retrieve the result
  elseif ($wildtok(state|error|input|inputType|httpParse|httpHead|httpStatus|httpStatusText|httpHeaders|httpBody|httpResponse, %Prop, 1, 124)) {
    if ($jfm_Exec(%Com, $v1)) {
      %Error = $v1
    }
    else {
      %Result = %SReject/JSONForMirc/Exec
    }
  }

  ;; if the prop is httpheader:
  ;;   Validate input parameters
  ;;   Attempt to retrieve the specified header
  ;;   Retrieve the result
  elseif (%Prop == httpHeader) {
    if ($calc($0 - %Offset) < 0) {
      %Error = INVALID_PARAMETERS
    }
    elseif ($jfm_Exec(%Com, httpHeader, $($ $+ %Offset, 2))) {
      %Error = $v1
    }
    else {
      %Result = %SReject/JSONForMirc/Exec
    }
  }

  ;; These props require that the json handler be walked before processing the prop itself
  elseif (%Prop == $null || $wildtok(path|type|isContainer|length|value|string|debug, %prop, 1, 124)) {
    %Prop = $v1

    ;; if members have been specified then the JSON handler's json needs to be walked
    if ($0 >= %Offset) {

      ;; get a unique com name for the handler
      %x = $ticks
      while ($com(%Com $+ : $+ %x)) {
        inc %x
      }
      %ChildCom = $+(%Com, :, %x)

      ;; Build the call 'string' to be evaluated
      %Call = $!com( $+ %com $+ ,walk,1,bool, $+ $iif(fuzzy == %Prefix, $true, $false) $+ %Params $+ ,dispatch* %ChildCom $+ )

      ;; log the call
      jfm_log -i %call

      ;; Attempt to call the js-side's walk function: walk(isFuzzy, member, ...)
      ;; if an error occurs, store the error and skip to error handling
      if (!$eval(%call, 2) || $comerr || !$com(%ChildCom)) {
        %Error = $jfm_GetError
        goto error
      }

      ;; otherwise, close the child com after script execution, update the %Com variable to indicate the child com
      ;; and decrease the indent for log lines
      $+(.timer, %ChildCom) -o 1 0 JSONClose %ChildCom
      %Com = %ChildCom
      jfm_log -d
    }

    ;; No Prop? then the result is the child com's name
    if (!%Prop) {
      %Result = $jfm_TmpBvar
      bset -t %Result 1 %Com
    }

    ;; if the prop isn't value, just call the js method to return data requested by the prop
    elseif (%prop !== value) {
      if ($jfm_Exec(%Com, $v1)) {
        %Error = $v1
      }
      else {
        %Result = %SReject/JSONForMirc/Exec
      }
    }

    ;; if the prop is value:
    ;;   Attempt to get it's cast-type
    ;;   Check the value's cast type
    ;;   Attempt to retrieve the value
    ;;   Fill the result variable with its value
    elseif ($jfm_Exec(%Com, type)) {
      %Error = $v1
    }
    elseif ($bvar(%SReject/JSONForMirc/Exec, 1-).text == object || $v1 == array) {
      %Error = INVALID_TYPE
    }
    elseif ($jfm_Exec(%Com, value)) {
      %Error = $v1
    }
    else {
      %Result = %SReject/JSONForMirc/Exec
    }
  }

  ;; Otherwise, report the specified prop is invalid
  else {
    %Error = UNKNOWN_PROP
  }

  ;; If no error has occured up to this point
  if (!%Error) {

    ;; if the tofile suffix was specified, write the result to file
    if (%Suffix == tofile) {
      bwrite %Output -1 -1 %Result
      bunset %Result
      jfm_log -Ds %Output
      return %Output
    }

    ;; if the tobvar suffix was specified, return the result bvar
    elseif (%Suffix == tobvar) {
      jfm_log -Ds %Result
      return %Result
    }

    ;; otherwise return the result text, chopped to 4000 bytes
    else {
      jfm_log -Ds $bvar(%Result, 1, 4000).text
      return $bvar(%Result, 1, 4000).text
    }
  }

  ;; Handle errors
  :error
  if ($error) {
    %Error = $error
    reseterror
  }

  ;; If an error occured, store and log the error
  if (%Error) {
    set -u0 %SReject/JSONForMirc/Error %Error
    jfm_log -De $!JSON %Error
  }
}




;; $JSONForEach(@Name|Ref|N, command, @Members).fuzzy
;;
alias JSONForEach {

  ;; Insure the alias was called as an identifier
  if (!$isid) return

  ;; Unset the global error variable incase the last call ended in error
  unset %SReject/JSONForMirc/Error

  ;; Local variable declarations
  var %Error, %Log, %Call, %x = 0, %JSON, %Com, %Result = 0, %Child, %Name

  ;; build log message and call parameter portion:
  ;;   log: $JSONForEach(@Name, @Command, members...)[@Prop]
  ;;   call: ,forEach,1[,bool,$true|$false,bstr,$N,...]
  %Log = $!JSONForEach(
  %Call = ,forEach,1
  if ($0 > 2) {
    %Call = %Call $+ ,bool, $+ $iif($prop == fuzzy, $true, $false)
  }
  :next
  if (%x < $0) {
    inc %x
    %log = %log $+ $($ $+ %x, 2) $+ ,
    if (%x > 2) {
      %Call = %Call $+ ,bstr, $+ $ $+ %x
    }
    goto next
  }

  ;; Log the alias call
  jfm_log -S $left(%Log, -1) $+ $chr(41) $+ $iif($prop !== $null, . $+ $v1)

  ;; Validate inputs
  if ($0 < 2) {
    %Error = INVAID_PARAMETERS
  }
  elseif ($1 == 0) {
    %Error = INVALID_HANDLER
  }
  elseif ($prop && $prop !== fuzzy) {
    %Error = INVALID_PROPERTY
  }
  elseif ($JSON($1)) {
    %JSON = $v1

    ;; Get an available com name based on the input com's name
    %x = $ticks
    :next2
    if ($com(%JSON $+ : $+ %x)) {
      inc %x
      goto next2
    }
    %Com = %JSON $+ : $+ %x

    ;; Build comcall: $com(com_name,forEach,1,[call_parameters],dispatch* new_com)
    %Call = $!com( $+ %JSON $+ %Call $+ ,dispatch* %Com $+ )

    ;; Make the com call and check for errors
    if (!$(%Call, 2) || $comerr || !$com(%com)) {
      %Error = $jfm_GetError
    }

    ;; Successfully called
    else {

      ;; start a timer to close the com
      .timer -m 1 0 JSONClose $unsafe(%com)

      ;; check length
      if (!$com(%Com, length, 2) || $comerr) {
        %Error = $jfm_GetError
      }

      elseif ($com(%com).result) {
        %Result = $v1
        %Child = $ticks
        %x = 0

        ;; Loop over each item in the returned list
        while (%x < %Result) {

          ;; get a name to use for the child com
          :next3
          if ($com(%Com $+ : $+ %Child)) {
            inc %child
            goto next3
          }
          %Name = %Com $+ : $+ %Child

          ;; Attempt to get a reference to the nTH item and then check for errors
          if (!$com(%Com, %x, 2, dispatch* %Name) || $comerr || !$com(%Name)) {
            %Error = $jfm_GetError
            break
          }

          ;; if successful, start a timer to close the com and then call the specified command
          else {
            $+(.timer, %Name) -m 1 0 JSONClose $unsafe(%Name)
            $2 %Name
          }

          inc %x
        }
      }
    }
  }
  else {
    %Error = INVALID_HANDLER
  }

  ;; Handle Errors
  :error
  if ($error) {
    %Error = $error
    reseterror
  }

  ;; if an error occured, close the items com if its open, then store and log the error
  if (%Error) {
    if ($com(%Com)) {
      .comclose $v1
    }
    set -u0 %SReject/JSONForMirc/Error %Error
    jfm_log -De Error: %Error
  }

  ;; Successful, return the number of results looped over
  else {
    jfm_log -Ds Result: %Result
    return %Result
  }
}



;; Todo: $JSONPath(@Name, N)
;;    Returns information related to a handler's path result



;; /JSONDebug @State
;;     Changes the current debug state
;;
;; $JSONDebug
;;     Returns the current debug state
;;         $true for on
;;         $false for off
alias JSONDebug {

  ;; Local variable declartion
  var %State = $false

  ;; if the current debug state is on
  if ($group(#SReject/JSONForMirc/Log) == on) {

    ;; if the window was closed, disable logging
    if (!$window(@SReject/JSONForMirc/Log)) {
      .disable #SReject/JSONForMirc/log
    }

    ;; otherwise update the state variable
    else {
      %State = $true
    }
  }

  ;; if the alias was called as an ID return the state
  if ($isid) {
    return %State
  }

  ;; if no parameter was specified, or the parameter was "toggle"
  elseif (!$0 || $1 == toggle) {

    ;; if the state is current disabled, update the parameter to disable debug logging
    if (%State) {
      tokenize 32 disable
    }

    ;; otherwise update the parameter to enable debug logging
    else {
      tokenize 32 enable
    }
  }

  ;; if the input was on|enable
  if ($1 == on || $1 == enable) {

    ;; if logging is already enabled
    if (%State) {
      echo $color(info).dd -atngq * /JSONDebug: debug already enabled
      return
    }

    ;; otherwise enable logging
    .enable #SReject/JSONForMirc/Log
    %State = $true
  }

  ;; if the input was off|disable
  elseif ($1 == off || $1 == disable) {

    ;; if logging is already disabled
    if (!%State) {
      echo $color(info).dd -atngq * /JSONDebug: debug already disabled
      return
    }

    ;; otherwise disable logging
    .disable #SReject/JSONForMirc/Log
    %State = $false
  }

  ;; bad input
  else {
    echo $color(info).dd -atng * /JSONDebug: Unknown input
    return
  }

  ;; if debug state is enabled
  ;; create the log window if need be and indicate that logging is enabled
  if (%State) {
    if (!$window(@SReject/JSONForMirc/Log)) {
      window -zk0e @SReject/JSONForMirc/Log
    }
    echo $color(info2) @SReject/JSONForMirc/Log Debug now enabled
    if ($~adiirc) {
      echo $color(info2) @SReject/JSONForMirc/Log AdiIRC v $+ $version $iif($beta, beta $v1) $bits $+ bit
    }
    else {
      echo $color(info2) @SReject/JSONForMirc/Log mIRC v $+ $version $iif($beta, beta $v1) $bits $+ bit
    }
    echo $color(info2) @SReject/JSONForMirc/Log $JSONVersion
    echo $color(info2) @SReject/JSONForMirc/Log -
  }

  ;; if debug state is disabled and the debug window is open, indicate that debug logging is disabled
  elseif ($Window(@SReject/JSONForMirc/Log)) {
    echo $color(info2) -q @SReject/JSONForMirc/Log [JSONDebug] Debug now disabled
  }
}



;; $jfm_TmpBVar
;;     Returns the name of a not-in-use temporarily bvar
alias -l jfm_TmpBVar {

  ;; local variable declaration
  var %n = $ticks

  ;; Log the alias call
  jfm_log -i $!jfm_TmpBVar

  ;; loop until a bvar that isn't in use is found
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

  ;; Insure the alias was called as an identifier
  if (!$isid) return

  ;; Local variable declaration
  var %Error, %js = $jfm_tmpbvar, %s = jfm_badd %js

  ;; Log the alias call
  jfm_log -i $!jfm_ComInit

  ;; If the JS Shell and engine are already open, log that the com is initialized and return
  if ($com(SReject/JSONForMirc/JSONShell) && $com(SReject/JSONForMirc/JSONEngine)) {
    jfm_log -isd initialized
    jfm_log -d
    return
  }

  ;; Retrieve the javascript to execute
  ;;> FILE:jscript:START file="json for mirc.min.js" prefix="jfm_badd %js"
  jfm_jscript %js
  ;;> FILE:jscript:END

  ;; close the Engine and shell coms if either but not both are open
  if ($com(SReject/JSONForMirc/JSONEngine)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell)) {
    .comclose $v1
  }

  ;; If the script is being ran under adiirc 64bit
  ;; attemppt to create a ScriptControl object instance
  if ($len($~adiircexe) && $appbits == 64) {
    .comopen SReject/JSONForMirc/JSONShell ScriptControl
  }

  ;; Otherwise attempt to create a MSScriptControl.ScriptControl instance
  else {
    .comopen SReject/JSONForMirc/JSONShell MSScriptControl.ScriptControl
  }

  ;; Check to make sure the shell opened
  if (!$com(SReject/JSONForMirc/JSONShell) || $comerr) {
    %Error = Unable to create ScriptControl
  }

  ;; attempt to set the com's language property
  elseif (!$com(SReject/JSONForMirc/JSONShell, language, 4, bstr, jscript) || $comerr) {
    %Error = Unable to set ScriptControl's language
  }

  ;; attempt to set the com's timeout property
  elseif (!$com(SReject/JSONForMirc/JSONShell, timeout, 4, bstr, 90000) || $comerr) {
    %Error = Unable to set ScriptControl's timeout to 90seconds
  }

  ;; Execute the jscript
  elseif (!$com(SReject/JSONForMirc/JSONShell, ExecuteStatement, 1, &bstr, %js) || $comerr) {
    %Error = Unable to execute required jScript
  }

  ;; Attempt to get the JS Engine instance
  elseif (!$com(SReject/JSONForMirc/JSONShell, Eval, 1, bstr, this, dispatch* SReject/JSONForMirc/JSONEngine) || $comerr || !$com(SReject/JSONForMirc/JSONEngine)) {
    %Error = Unable to get jScript engine reference
  }

  ;; If all attempts succeeded, log the success
  else {
    jfm_log -isd Successfully initialized
    jfm_log -d
  }

  ;; Handle errors
  :error
  if ($error) {
    %Error = $v1
    reseterror
  }

  ;; If an error occured clean up, log the error, and then return the error
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

  ;; Insure the alias is called as an identifier
  if (!$isid) return

  ;; Local variable declaration
  var %Error = UNKNOWN

  ;; log the alias call
  jfm_log -i $!jfm_GetError

  ;; retrieve the errortext property from the shell com
  if ($com(SReject/JSONForMirc/JSONShell).errortext) {
    %Error = $v1
  }

  ;; if the ShellError com is open, close it
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose $v1
  }

  ;; attempt to retrieve the shell com's last error
  if ($com(SReject/JSONForMirc/JSONShell, Error, 2, dispatch* SReject/JSONForMirc/JSONShellError) && !$comerr && $com(SReject/JSONForMirc/JSONShellError) && $com(SReject/JSONForMirc/JSONShellError, Description, 2) && !$comerr) {

    ;; retrieve the result and store it in %error
    if ($com(SReject/JSONForMirc/JSONShellError).result) {
      %Error = $v1
    }
  }

  ;; close the ShellError com
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose $v1
  }

  ;; log and return the error
  jfm_log -isd %Error
  jfm_log -d
  return %Error
}



;; $jfm_Exec(@Name, @Method, [@Args])
;;     Executes the js method of the specified name
;;         Stores the result in a tmp bvar and stores the name in %SReject/JSONForMirc/Exec
;;         If an error occurs, returns the error
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

  ;; local variable declaration
  var %Args, %Index = 1, %value, %Result, %Params

  ;; cleanup from previous call
  unset %SReject/JSONForMirc/Exec

  ;; Loop over inputs, storing them in %args(for logging), and %params(for com calling)
  :args
  if (%Index <= $0) {
    %value = $($ $+ %index, 2)
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %Index, 2)
    if (%Index >= 3) {
      if ($prop == fromBvar && $regex(%value, /^& (&\S+)$/)) {
        %Params = %Params $+ ,&bstr, $+ $regml(1)
      }
      else {
        %Params = %Params $+ ,bstr,$ $+ %Index
      }
    }
    inc %Index
    goto args
  }
  jfm_log -i $!jfm_Exec( $+ %Args $+ )

  ;; Build the com call
  %params = $!com($1,$2,1 $+ %Params $+ )

  ;; Attempt the com call and if an error occurs
  if (!$(%Params, 2) || $comerr) {

    ;; retrieve the error, store it in result, log the error, and return it
    %Result = $jfm_GetError
    jfm_log -ed Error: %Result
    return %Result
  }

  ;; otherwise create a temp bvar, store the result in the the bvar
  set -u0 %SReject/JSONForMirc/Exec $jfm_tmpbvar
  noop $com($1, %SReject/JSONForMirc/Exec).result

  ;; log the result
  jfm_log -isd Result stored in %SReject/JSONForMirc/Exec
  jfm_log -d
}



;; $jfm_Eval(@Name, @Property, [@args])
;;     Evaluates the js method of the specified name
;;         Stores the result in a tmp bvar and stores that bvar name in %SReject/JSONForMirc/Eval
;;         If an error occur, returns the error
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

  ;; Local variable declaration
  var %Args, %Index = 1, %Result, %Params

  ;; cleanup from previous call
  unset %SReject/JSONForMirc/Eval

  ;; Loop over inputs, storing them in %args(for logging), and %params(for com calling)
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

  ;; Build the com call
  %Params = $!com($1,$2,2 $+ %Params $+ )

  ;; Attempt to make the com call and if an error occurs
  if (!$(%Params, 2) || $comerr) {

    ;; retrieve the error, store it in %result, and return it
    %Result = $jfm_GetError
    jfm_log -ed Error: %Result
    return %Result
  }

  ;; otherwise create a tmp bvar, store the bvar name in the result, and log the success
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
;;    @httpOption - Number - Optional
;;        Indicates how the http request should be handled, as a bitwise comparison(add values to toggle options)
;;          1: wait for /JSONHttpFetch to be called
;;          2: Do not parse the result of the HTTP request
alias -l jfm_Create {

  ;; Insure the alias is called as an identifier
  if (!$isid) return

  ;; Local variable declaration
  var %wait = $iif(1 & $4, $true, $false), %noParse = $iif(2 & $4, $true, $false), %result

  ;; Log the alias call
  jfm_log -i $!jfm_create( $+ $1 $+ , $+ $2 $+ , $+ $3 $+ , $+ $4)

  ;; Attempt to create the json handler and if an error occurs retrieve the error, log it and return it
  if (!$com(SReject/JSONForMirc/JSONEngine, JSONCreate, 1, bstr, $2, &bstr, $3, bool, %noParse, dispatch* $1) || $comerr || !$com($1)) {
    %Result = $jfm_GetError
    jfm_log -ied %Result
  }

  ;; Attempt to call the parse method if the handler should not wait for the http request
  elseif ($2 !== http || ($2 == http && !%wait)) && (!$com($1, parse, 1)) {
    %Result = $jfm_GetError
    jfm_log -ied %Result
  }

  if (%error) {
    jfm_log -d
  }
  return %Result
}



;; When debug is enabled
;;     the /jfm_log alias with this group gets called
;;
;; When debug is disabled
;;    the /jfm_log alias below this group is called
#SReject/JSONForMirc/Log on



;; /jfm_log -dDeisS @message
;;     Logs debug messages
;;
;;     -e: Indicates the message is an error
;;     -s: indicates the message is a success
;;
;;     -i: Increases the indent count before logging
;;     -d: decreases the indent count before logging
;;
;;     -D: resets the indent before logging
;;     -S: resets the indent and indicates the start of a new log stack
;;
;;     @Message - optional
;;         The message to be logged
alias -l jfm_log {

  ;; Insure the alias was called as a command
  if ($isid) return

  ;; Local variable declartion
  var %switches = -, %Prefix

  ;; if the debug window is not open, disable logging and unset the log indent variable
  if (!$window(@SReject/JSONForMirc/Log)) {
    .JSONDebug off
    unset %SReject/JSONForMirc/LogIndent
  }
  else {

    ;; Seperate switches from message parameter
    if (-?* iswm $1) {
      %switches = $mid($1, 2-)
      tokenize 32 $2-
    }

    ;; if the -S switch was specified, reset the indent count and indicate the message is a success message
    if (S isincs %Switches) {
      set -u0 %SReject/JSONForMirc/LogIndent 0
      %Prefix = 13->
    }

    ;; If the -D switche was specified, reset the indent count
    if (D isincs %Switches) {
      set -u0 %SReject/JSONForMirc/LogIndent 1
    }

    ;; if the -i switch was specified, increase the indent count
    if (i isincs %Switches) {
      inc -u0 %SReject/JSONForMirc/LogIndent
    }

    ;; if a log message has been specified
    if ($0) {

      ;; if the -e switch has been specified, the message is an error
      if (e isincs %Switches) {
        %Prefix = 04->
      }

      ;; if the -s switch has been specified, the message is a success
      elseif (s isincs %Switches) {
        %Prefix = 12->
      }

      ;; otherwise the message is info
      else {
        %Prefix = 03->
      }

      ;; Log the line to the debug window
      aline @SReject/JSONForMirc/Log $str($chr(32) $+ , $calc(%SReject/JSONForMirc/LogIndent *4)) $+ %Prefix $1-
    }

    ;; if the -D switch was specified, unset the indent count variable
    if (D isincs %Switches) {
      unset %SReject/JSONForMirc/LogIndent
    }

    ;; if the -d switch was specified, decrease the indent count variable
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

;; called when debugging is disabled
alias -l jfm_log noop



;; $jfm_SaveDebug
;;     Returns $true if the debug window is open and there is content in the buffer to save
;;
;; /jfm_SaveDebug
;;     Attempts to save the contents of the debug window to file
alias -l jfm_SaveDebug {

  ;; if called as an identifier
  if ($isid) {

    ;; if the debug window is open and has content to save return true
    if ($window(@SReject/JSONForMirc/Log) && $line(@SReject/JSONForMirc/Log, 0)) {
      return $true
    }

    ;; otherwise return false
    return $false
  }

  var %file = $sfile($envvar(USERPROFILE) $+ \Documents\JFM.log, Save, Save)

  ;; if no file was selected to store the log under
  ;; halt processing
  if (!%file) {
    return
  }

  ;; if the file exists ask the user if they are sure they want to overwrite it
  if ($isfile(%file) && !$input(Are you sure you want to overwrite $nopath(%file), ysa, @SReject/JSONForMirc/Log, Overwrite)) {
    return
  }

  ;; save the debug buffer to file
  savebuf @SReject/JSONForMirc/Log $qt(%file)
}



;;> REMOVE:helper_alias:START
;; /jfm_jscript @Bvar
;;     reads the "JSON For Mirc.js" file and outputs the contents to the specified bvar
alias -l jfm_jscript {
  var %file = $qt($scriptdirJSON For Mirc.js)
  bread $qt(%file) 0 $file(%file).size $1
}
;;> REMOVE:helper_alias:END
