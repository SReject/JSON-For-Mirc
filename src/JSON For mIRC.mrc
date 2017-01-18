;; v0.2.41 compatibility mode public commands
#SReject/JSONForMirc/CompatMode off
alias JSONUrlMethod {
  if ($isid) return
  JSONHttpMethod $1-
}
alias JSONUrlHeader {
  if ($isid) return
  JSONHttpHeader $1-
}
alias JSONUrlGet {
  if ($isid) return
  JSONHttpFetch $1-
}
#SReject/JSONForMirc/CompatMode end


;; Check to make sure mIRC/AdiIRC is of an applicable version
on *:LOAD:{

  ;; adiirc check
  if ($~adiircexe) {
    if ($version < 2.6) {
      echo -ag [JSON For mIRC] AdiIRC v2.6 or later is required
      .unload -rs $qt($script)
    }
  }
  
  ;; mIRC check
  elseif ($version < 7.44) {
    echo -ag [JSON For mIRC] mIRC v7.44 or later is required
    .unload -rs $qt($script)
  }
  
  ;; if passed, call jsonshutdown so the JS engine from a previously loaded version gets shutdown
  else {
    JSONShutdown
  }
}


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
  .disable #SReject/JSONForMirc/CompatMode
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





;;===================================;;
;;                                   ;;
;;          PUBLIC COMMANDS          ;;
;;                                   ;;
;;===================================;;

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
;;             Disallowed Characters: ? * : and space
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
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; local variable declarations
  var %Switches, %Error, %Com = $false, %Type = text, %HttpOptions = 0, %BVar, %BUnset = $true

  ;; log the /JSONOpen command is being called
  jfm_log -I /JSONOpen $1-

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
  elseif (u !isin %Switches) && (w isincs %Switches) {
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
  elseif (u isin %Switches) && ($0 != 2) {
    %Error = PARAMETER_INVALID:URL_SPACES
  }

  ;; Validate bvar where appropriate
  elseif (b isincs %Switches) && ($0 != 2) {
    %Error = PARAMETER_INVALID:BVAR
  }
  elseif (b isincs %Switches) && (&* !iswm $2) {
    %Error = PARAMETER_INVALID:NOT_BVAR
  }
  elseif (b isincs %Switches) && (!$bvar($2, 0)) {
    %Error = PARAMETER_INVALID:BVAR_EMPTY
  }

  ;; Validate file where appropriate
  elseif (f isincs %Switches) && (!$isfile($2-)) {
    %Error = PARAMETER_INVALID:FILE_DOESNOT_EXIST
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
      if (w isincs %Switches) {
        inc %HttpOptions 1
      }
      if (U isincs %Switches) {
        inc %HttpOptions 2
      }
      %Type = http
      bset -t %BVar 1 $2
    }

    ;; if the input is a file, read the file into a bvar
    elseif (f isincs %Switches) {
      bread $qt($file($2-).longfn) 0 $file($file($2-).longfn).size %BVar
    }

    ;; if the input is text, store the text in a bvar
    else {
      bset -t %BVar 1 $2-
    }

    ;; attempt to create the handler
    %Error = $jfm_Create(%Com, %Type, %BVar, %HttpOptions)
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; unset the bvar if it was temporary
  if (%BUnset) {
    bunset %BVar
  }

  ;; if the error variable is filled:
  ;;     Store the error in a global variable
  ;;     Start a timer to close the handle when script-execution finishes
  ;;     Log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    if (%Com) && ($com(%Com)) {
      .timer $+ %Com -iom 1 0 JSONClose $unsafe($1)
    }
    jfm_log -EeD %Error
  }

  ;; Otherwise, if the -d switch was specified start a timer to close the com
  ;; and then log the successful handler creation
  else {
    if (d isincs %Switches) {
      .timer $+ %Com -iom 1 0 JSONClose $unsafe($1)
    }
    jfm_log -EsD Created $1 (as com %Com $+ )
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
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; local variable declarations
  var %Error, %Com, %Method

  ;; Log the alias call
  jfm_log -I /JSONHttpMethod $1-

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
    %Error = HANDLE_DOES_NOT_EXIST
  }
  else {

    ;; store the com name, trim excess whitespace from the method parameter then validate the method
    %Com = JSON: $+ $1
    %Method = $regsubex($2, /(^\s+)|(\s*)$/g, )
    if (!$len(%Method)) {
      %Error = INVALID_METHOD
    }

    ;; if the method is valid attemp to store it with the handle
    elseif ($jfm_Exec(%Com, httpSetMethod, %Method)) {
      %Error = $v1
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; if an error occured, store the error in a global variable then log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }

  ;; if no errors, log the success
  else {
    jfm_log -EsD Set Method to $+(', %Method, ')
  }
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
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; local variable declarations
  var %Error, %Com, %Header

  ;; Log the alias call
  jfm_log -I /JSONHttpHeader $1-

  ;; Call the Com interfave initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }

  ;; Basic input validation
  elseif ($0 < 3) {
    %Error = PARAMETER_MISSING
  }

  ;; Validate @name parameter
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = INVALID_NAME
  }
  elseif (!$com(JSON: $+ $1)) {
    %Error = HANDLE_DOES_NOT_EXIST
  }
  else {

    ;; Store the json handler name, trim whitespace from the header name, then validate the header
    %Com = JSON: $+ $1
    %Header = $regsubex($2, /(^\s+)|(\s*:\s*$)/g, )
    if (!$len($2)) {
      %Error = HEADER_EMPTY
    }
    elseif ($regex($2, [\r:\n])) {
      %Error = HEADER_INVALID
    }

    ;; If the header is valid, attempt to store the header with the handle
    elseif ($jfm_Exec(%Com, httpSetHeader, %Header, $3-)) {
      %Error = $v1
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; if an error occured, store the error in a global variable then log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }

  ;; If no error, log the success
  else {
    jfm_log -EsD Stored Header $+(',%Header,: $3-,')
  }
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
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; Local variable declarations
  var %Switches, %Error, %Com, %BVar, %BUnset

  ;; Log the alias call
  jfm_log -I /JSONHttpFetch $1-

  ;; Remove switches from other input parameters
  if (-* iswm $1) {
    %Switches = $mid($1, 2-)
    tokenize 32 $2-
  }

  ;; Call the Com interface intializier
  if ($jfm_ComInit) {
    %Error = $v1
  }

  ;; Basic input validatition
  if ($0 == 0) || (%Switches != $null && $0 < 2) {
    %Error = PARAMETER_MISSING
  }

  ;; validate switches
  elseif ($regex(%Switches, ([^bf]))) {
    %Error = SWITCH_INVALID: $+ $regml(1)
  }
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = NAME_INVALID
  }

  ;; validate @name
  elseif (!$com(JSON: $+ $1)) {
    %Error = HANDLE_DOES_NOT_EXIST
  }

  ;; Validate specified bvar when applicatable
  elseif (b isincs %Switches) && (&* !iswm $2 || $0 > 2) {
    %Error = BVAR_INVALID
  }

  ;; validate specified file when applicatable
  elseif (f isincs %Switches) && (!$isfile($2-)) {
    %Error = FILE_DOESNOT_EXIST
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
        bread $qt($file($2-).longfn) 0 $file($2-).size %BVar
      }

      ;; if no switches were specified, store the @data in the temp bvar
      else {
        bset -t %BVar 1 $2-
      }

      ;; Attempt to store the data with the handler instance
      %Error = $jfm_Exec(%Com, httpSetData, & %BVar).fromBvar
    }

    ;; Call the js-side parse function for the handler
    if (!%Error) {
      %Error = $jfm_Exec(%Com, parse)
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; Clear the bvar if indicated it should be unset
  if (%BUnset) {
    bunset %BVar
  }

  ;; if an error occured, store the error in a global variable then log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }

  ;; Otherwise log the success
  else {
    jfm_log -EsD Http Data retrieved
  }
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
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; Local variable declarations
  var %Switches, %Error, %Match, %Com, %X = 1

  ;; Log the alias call
  jfm_log -I /JSONClose $1-

  ;; Remove switches from other input parameters
  if (-* iswm $1) {
    %Switches = $mid($1, 2-)
    tokenize 32 $2-
  }

  ;; Basic input validation
  if ($0 < 1) {
    %Error = PARAMTER_MISSING
  }
  elseif ($0 > 1) {
    %Error = PARAMETER_INVALID
  }

  ;; Validate switches
  elseif ($regex(%Switches, /([^w])/)) {
    %Error = SWITCH_UNKNOWN: $+ $regml(1)
  }

  ;; Validate @Name
  elseif (: isin $1) && (w isincs %Switches || JSON:* !iswmcs $1) {
    %Error = PARAMETER_INVALID
  }
  else {

    ;; Format @Name to match as a regex
    %Match = $1
    if (JSON:* iswmcs $1) {
      %Match = $gettok($1, 2-, 58)
    }
    %Match = $replacecs(%Match, \E, \E\\E\Q)
    if (w isincs %Switches) {
      %Match = $replacecs(%Match, ?, \E[^:]\Q, *, \E[^:]*\Q)
    }
    %Match = /^JSON:\Q $+ %Match $+ \E(?::\d+)?$/i
    %Match = $replacecs(%Match,\Q\E,)

    ;; Loop over all comes
    while (%X <= $com(0)) {
      %Com = $com(%X)

      ;; Check if the com name matches to formatted @name
      if ($regex(%Com, %Match)) {

        ;; Close the com, turn off timers associated to the com and log the close
        .comclose %Com
        if ($timer(%Com)) {
          .timer $+ %Com off
        }
        jfm_log Closed %Com
      }

      ;; Otherwise move on to the next com
      else {
        inc %X
      }
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; if an error occured, store the error in a global variable then log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD /JSONClose %Error
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
  var %X = 1, %I = 0

  ;; Log the alias call
  jfm_log /JSONList $1-

  ;; loop over all open coms
  while ($com(%X)) {

    ;; If the com is a json handler, output the name
    if (JSON:?* iswm $v1) {
      inc %I
      echo $color(info) -ag * $chr(35) $+ %I : $v2
    }
    inc %X
  }

  ;; If no json handlers were found, output such
  if (!%I) {
    echo $color(info) -ag * No active JSON handlers
  }
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
  if ($hget(SReject/JSONForMirc)) { hfree $v1 }
}


;; /JSONCompat
;;     Toggles v0.2.42 compatability mode on
;;     To disable: //disable #SReject/JSONForMirc/CompatMode
;;
;; $JSONCompat
;;     Returns $true if the script is in v0.2.4x compatability mode
alias JSONCompat {
  if ($isid) {
    return $iif($group(#SReject/JSONForMirc/CompatMode) == on, $true, $false)
  }
  .enable #SReject/JSONForMirc/CompatMode
}





;;======================================;;
;;                                      ;;
;;          PUBLIC IDENTIFIERS          ;;
;;                                      ;;
;;======================================;;

;; $JSON(@Name|Ref|N, [@file,] [@Members...]).@Prop
;;     Returns information pretaining to an open JSON handler
alias JSON {

  ;; Insure the alias was called as an identifier and that atleast one parameter has been stored
  if (!$isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; Local variable declartions
  var %X = 1, %Args, %Params, %Error, %Com, %I = 0, %Prefix, %Prop, %Suffix, %Offset = $iif(*toFile iswm $prop,3,2), %Type, %Output, %Result, %ChildCom, %Call

  ;; Loop over all parameters
  while (%X <= $0) {

    ;; store each parameter in %Args delimited by a comma(,)
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %X, 2)

    ;; if the parameter is greater than the offset store it the parameter under %Params
    if (%X >= %Offset) {
      %Params = %Params $+ ,bstr,$ $+ %X
    }
    inc %X
  }
  %X = 1

  ;; Log the alias call
  jfm_log -I $!JSON( $+ %Args $+ ) $+ $iif($len($prop), . $+ $prop)

  ;; If the alias was called without any inputs
  if (!$0) || ($0 == 1 && $1 == $null) {
    %Error = MISSING_PARAMETERS
    goto error
  }

  ;; If the alias was called with the only parameter being 0 and a prop
  if ($0 == 1) && ($1 == 0) && ($prop !== $null) {
    %Error = PROP_NOT_APPLICABLE
    goto error
  }

  ;; If the @name parameter starts with JSON assume its the name of the JSON com
  if ($regex(name, $1, /^JSON:[^:?*]+(?::\d+)?$/i)) {
    %Com = $1
  }

  ;; Otherwise, do basic validation on the @Name parameter
  elseif (: isin $1 || * isin $1 || ? isin $1) || ($1 == 0 && $0 !== 1) {
    %Error = INVALID_NAME
  }

  ;; if @Name is a numerical value
  elseif ($regex($1, /^\d+$/)) {

    ;; loop over all coms
    while ($com(%X)) {

      ;; if the com is a json handler and
      ;;    the handler's index matches that of input
      ;;    assume the handler is the one requested and make use of it for further operations
      if ($regex($v1, /^JSON:[^:]+$/)) {
        inc %I
        if (%I === $1) {
          %Com = $com(%X)
          break
        }
      }
      inc %X
    }

    ;; if @Name is 0 return the total number of JSON handlers
    if ($1 === 0) {
      jfm_log -EsD %I
      return %I
    }
  }

  ;; Otherwise assume @Name is the name of a JSON handler, as-is
  else {
    %Com = JSON: $+ $1
  }

  ;; If the deduced com doesn't exist store the error
  if (!%Error) && (!$com(%Com)) {
    %Error = HANDLER_NOT_FOUND
  }

  ;; basic property validation
  elseif (* isin $prop) || (? isin $prop) {
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
    
    ;; v0.2.41 compatibility mode props:
    if ($JSONCompat) {

      ;; .status has been depreciated; use .state
      if (%Prop == status) {
        %Prop = state
      }

      ;; .data has been depreciated; use .input
      if (%Prop == data) {
        %Prop = input
      }

      ;; .isRef has been depreciated; use .isChild
      if (%Prop == isRef) {
        %Prop = isChild
      }

      ;; .isParent is depreciated; use .isContainer
      if (%Prop == isParent) {
        %Prop = isContainer
      }
    }

    ;; if the suffix is 'tofile', validate the 2nd parameter
    if (%Suffix == tofile) {
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
  elseif ($0 == 1) && (!$prop) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 %Com
  }

  ;; if the prop is isChild:
  ;;   create a new bvar for the result
  ;;   deduce if the specified handler is a child
  elseif (%Prop == isChild) {
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
      %Result = $hget(SReject/JSONForMirc,Exec)
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
      %Result = $hget(SReject/JSONForMirc,Exec)
    }
  }

  ;; These props require that the json handler be walked before processing the prop itself
  elseif (%Prop == $null) || ($wildtok(path|pathLength|type|isContainer|length|value|string|debug, %Prop, 1, 124)) {
    %Prop = $v1

    ;; if members have been specified then the JSON handler's json needs to be walked
    if ($0 >= %Offset) {

      %ChildCom = JSON: $+ $gettok(%Com, 2, 58) $+ :

      ;; get a unique com name for the handler
      %X = $ticks
      while ($com(%ChildCom $+ %X)) {
        inc %X
      }
      %ChildCom = %ChildCom $+ %X

      ;; Build the call 'string' to be evaluated
      %Call = $!com( $+ %Com $+ ,walk,1,bool, $+ $iif(fuzzy == %Prefix, $true, $false) $+ %Params $+ ,dispatch* %ChildCom $+ )

      ;; log the call
      jfm_log %Call

      ;; Attempt to call the js-side's walk function: walk(isFuzzy, member, ...)
      ;; if an error occurs, store the error and skip to error handling
      if (!$eval(%Call, 2)) || ($comerr) || (!$com(%ChildCom)) {
        %Error = $jfm_GetError
        goto error
      }

      ;; otherwise, close the child com after script execution, update the %Com variable to indicate the child com
      ;; and decrease the indent for log lines
      .timer $+ %ChildCom -iom 1 0 JSONClose %ChildCom
      %Com = %ChildCom
      jfm_log
    }

    ;; v0.2.41 compatbility mode - If no prop has been specified: 
    ;;     if the referenced item is a container, return a reference to that item
    ;;     if the reference is not a container, return the value
    if ($JSONCompat) && ($prop == $null) {
    
      ;; attempt to retrieve the reference type and if its an object or an array, the result is
      ;; a reference to that item.
      if ($jfm_exec(%Com, type)) {
        %Error = $v1
      }
      elseif ($bvar($hget(SReject/JSONForMirc,Exec), 1-).text == object) || ($v1 == array) {
        %Result = $jfm_TmpBvar
        bset -t %Result 1 %Com
      }
      
      ;; Attempt to retrieve the reference's value
      elseif ($jfm_Exec(%Com, value)) {
        %Error = $v1
      }
      else {
        %Result = $hget(SReject/JSONForMirc,Exec)
      }
    }
    
    ;; No Prop? then the result is the child com's name
    elseif (!%Prop) {
      %Result = $jfm_TmpBvar
      bset -t %Result 1 %Com
    }

    ;; if the prop isn't value, just call the js method to return data requested by the prop
    elseif (%Prop !== value) {
      if ($jfm_Exec(%Com, $v1)) {
        %Error = $v1
      }
      else {
        %Result = $hget(SReject/JSONForMirc,Exec)
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
    elseif ($bvar($hget(SReject/JSONForMirc,Exec), 1-).text == object) || ($v1 == array) {
      %Error = INVALID_TYPE
    }
    elseif ($jfm_Exec(%Com, value)) {
      %Error = $v1
    }
    else {
      %Result = $hget(SReject/JSONForMirc,Exec)
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
      bwrite $qt(%Output) -1 -1 %Result
      bunset %Result
      %Result = %Output
    }

    ;; if the tobvar suffix was specified, return the result bvar
    elseif (%Suffix !== tobvar) {
      %Result = $bvar(%Result, 1, 4000).text
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; If an error occured, store and log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else {
    jfm_log -EsD %Result
    return %Result
  }
}


;; $JSONForEach(@Name|Ref|N, @command, @Members)[.fuzzy]
;; $JSONForEach(@Name|Ref|N, @Command).walk
alias JSONForEach {

  ;; Insure the alias was called as an identifier
  if (!$isid) return

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; Local variable declarations
  var %Error, %Log, %Call, %X = 0, %JSON, %Com, %ChildCom, %Result = 0, %Name

  ;; build log message and call parameter portion:
  ;;   log: $JSONForEach(@Name, @Command, members...)[@Prop]
  ;;   call: ,forEach,1,bool,$true|$false,bool,$true|$false[,bstr,$N,...]
  %Log = $!JSONForEach(
  %Call = ,forEach,1,bool, $+ $iif(walk == $prop, $true, $false) $+ ,bool, $+ $iif(fuzzy == $prop, $true, $false)
  :next
  if (%X < $0) {
    inc %X
    %Log = %Log $+ $($ $+ %X, 2) $+ ,
    if (%X > 2) {
      %Call = %Call $+ ,bstr, $+ $ $+ %X
    }
    goto next
  }

  ;; Log the alias call
  jfm_log -I $left(%Log, -1) $+ $chr(41) $+ $iif($prop !== $null, . $+ $v1)

  ;; Basic input validation
  if ($0 < 2) {
    %Error = INVAID_PARAMETERS
  }
  elseif ($1 == 0) {
    %Error = INVALID_HANDLER
  }
  
  ;; Validate prop
  elseif ($prop !== $null) && ($prop !== walk) && ($prop !== fuzzy) {
    %Error = INVALID_PROPERTY
  }
  elseif ($0 > 2) && ($prop == walk) {
    %Error = PARAMETERS_NOT_APPLICABLE
  }

  ;; Validate @Handle|Ref|N
  elseif (!$1) || ($1 == 0) || (!$regex($1, /^((?:[^?:*]+)|(?:JSON:[^?:*]+(?::\d+)))$/)) {
    %Error = NAME_INVALID
  }
  else {

    ;; deduce json handle
    ;; this could be done by calling $JSON() but this way is much faster
    if (JSON:?* iswm $1) {
      %JSON = $com($1)
    }
    elseif ($regex($1, /^\d+$/i)) {
      %X = 1
      %JSON = 0
      while ($com(%X)) {
        if ($regex($1, /^JSON:[^?*:]+$/)) {
          inc %JSON
          if (%JSON == $1) {
            %JSON = $com(%X)
            break
          }
          elseif (%X == $com(0)) {
            %JSON = $null
          }
        }
        inc %X
      }
    }
    else {
      %JSON = $com(JSON: $+ $1)
    }


    if (!%JSON) {
      %Error = HANDLE_NOT_FOUND
    }
    else {

      ;; Get an available com name based on the input com's name
      %Com = $gettok(%JSON, 1-2, 58) $+ :
      %X = $ticks
      :next2
      if ($com(%Com $+ %X)) {
        inc %X
        goto next2
      }
      %Com = %Com $+ %X

      ;; Build com call: $com(com_name,forEach,1,[call_parameters],dispatch* new_com)
      %Call = $!com( $+ %JSON $+ %Call $+ ,dispatch* %Com $+ )

      ;; log the call
      jfm_log %Call

      ;; Make the com call and check for errors
      if (!$(%Call, 2)) || ($comerr) || (!$com(%Com)) {
        %Error = $jfm_GetError
      }

      ;; Successfully called
      else {

        ;; start a timer to close the com
        .timer $+ %Com -iom 1 0 JSONClose $unsafe(%Com)

        ;; check length
        if (!$com(%Com, length, 2)) || ($comerr) {
          %Error = $jfm_GetError
        }

        elseif ($com(%Com).result) {
          %Result = $v1
          %X = 0

          ;; Loop over each item in the returned list
          while (%X < %Result) {

            ;; get a name to use for the child com
            %ChildCom = $gettok(%Com, 1-2, 58) $+ :
            %Name = $ticks

            :next3
            if ($com(%ChildCom $+ %Name)) {
              inc %Name
              goto next3
            }
            %Name = %ChildCom $+ %Name

            ;; Attempt to get a reference to the nTH item and then check for errors
            if (!$com(%Com, %X, 2, dispatch* %Name)) || ($comerr) || (!$com(%Name)) {
              %Error = $jfm_GetError
              break
            }

            ;; if successful, start a timer to close the com and then call the specified command
            else {
              jfm_log -I Calling $iif(/ $+ * !iswm $2, /) $+ $2 %Name
              .timer $+ %Name -iom 1 0 JSONClose $unsafe(%Name)
              $2 %Name
              jfm_log -D
            }

            inc %X
          }
        }
      }
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; if an error occured, close the items com if its open, then store and log the error
  if (%Error) {
    if ($com(%Com)) {
      .comclose $v1
    }
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }

  ;; Successful, return the number of results looped over
  else {
    jfm_log -EsD %Result
    return %Result
  }
}


;; $JSONPath(@Name|ref|N, index)
;;    Returns information related to a handler's path
alias JSONPath {
  if (!$isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc,Error)) { hdel SReject/JSONForMirc Error }

  ;; Local variable declarations
  var %Error, %Param, %X = 0, %JSON, %Result

  while (%X < $0) {
    inc %X
    %Param = %Param $+ $($ $+ %X, 2) $+ ,
  }

  ;; log the call
  jfm_log -I $!JSONPath( $+ $left(%Param, -1) $+ )

  ;; validate inputs
  if ($0 !== 2) {
    %Error = INVALID_PARAMETERS
  }
  elseif ($prop !== $null) {
    %Error = PROP_NOT_APPLICABLE
  }
  elseif (!$1) || ($1 == 0) || (!$regex($1, /^(?:(?:JSON:[^?:*]+(?::\d+)*)?|([^?:*]+))$/i)) {
    %Error = NAME_INVALID
  }
  elseif ($2 !isnum 0-) || (. isin $2) {
    %Error = INVALID_INDEX
  }
  else {

    ;; Attempt to retrieve a handler for the @Name|Ref|N input
    %JSON = $JSON($1)
    if ($JSONError) {
      %Error = $v1
    }
    elseif (!%JSON) {
      %Error = HANDLER_NOT_FOUND
    }
    elseif ($JSON(%JSON).pathLength == $null) {
      %Error = $JSONError
    }
    else {

      ;; Store the result of the .pathLength call
      %Result = $v1

      ;; if $2 is 0 do nothing
      if (!$2) {
        noop
      }

      ;; if $2 is greater than the path length, %Result is nothing/null
      elseif ($2 > %Result) {
        unset %Result
      }

      ;; attempt to retrieve the path item at the specified index
      elseif (!$com(%JSON, pathAtIndex, 1, bstr, $calc($2 -1))) || ($comerr) {
        %Error = $jfm_GetError
      }

      ;; retrieve the result from the com
      else {
        %Result = $com(%JSON).result
      }
    }
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; If an error occured, store it then log the error
  if (%Error) {
    hadd -mu1 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }

  ;; otherwise, log the result and return it
  else {
    jfm_log -EsD %Result
    return %Result
  }
}


;; $JSONError
;;     Returns any error the last call to /JSON* or $JSON() raised
alias JSONError {
  if ($isid) {
    return $hget(SReject/JSONForMirc,Error)
  }
}


;; $JSONVersion(@Short)
;;     Returns script version information
;;
;;     @Short - Any text
;;         Returns the short version
alias JSONVersion {
  if ($isid) {
    var %Ver = 1.0.3003
    if ($0) {
      return %Ver
    }
    return SReject/JSONForMirc v $+ %Ver
  }
}





;;==============================================;;
;;                                              ;;
;;          PUBLIC COMMAND+IDENTIFIERS          ;;
;;                                              ;;
;;==============================================;;

;; /JSONDebug @State
;;     Changes the current debug state
;;
;; $JSONDebug
;;     Returns the current debug state
;;         $true for on
;;         $false for off
alias JSONDebug {

  ;; Local variable declartion
  var %State = $false, %aline = aline $color(info2) @SReject/JSONForMirc/Log

  ;; if the current debug state is on
  if ($group(#SReject/JSONForMirc/Log) == on) {

    ;; if the window was closed disable logging
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
  elseif (!$0) || ($1 == toggle) {

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
  if ($1 == on) || ($1 == enable) {

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
  elseif ($1 == off) || ($1 == disable) {

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
    %aline Debug now enabled
    if ($~adiircexe) {
      %aline AdiIRC v $+ $version $iif($beta, beta $builddate) $bits $+ bit
    }
    else {
      %aline mIRC v $+ $version $iif($beta, beta $v1) $bits $+ bit
    }
    %aline $JSONVersion $iif($JSONCompat, [CompatMode], [NormalMode])
    %aline -
  }

  ;; if debug state is disabled and the debug window is open, indicate that debug logging is disabled
  elseif ($Window(@SReject/JSONForMirc/Log)) {
    %aline [JSONDebug] Debug now disabled
  }
  window -b @SReject/JSONForMirc/Log
}





;;===================================;;
;;                                   ;;
;;          PRIVATE ALIASES          ;;
;;                                   ;;
;;===================================;;

;; $jfm_TmpBVar
;;     Returns the name of a not-in-use temporarily bvar
alias -l jfm_TmpBVar {

  ;; local variable declaration
  var %N = $ticks

  ;; Log the alias call
  jfm_log -I $!jfm_TmpBVar

  ;; loop until a bvar that isn't in use is found
  :next
  if (!$bvar(&SReject/JSONForMirc/Tmp $+ %N)) {
    jfm_log -EsD &SReject/JSONForMirc/Tmp $+ %N
    return &SReject/JSONForMirc/Tmp $+ %N
  }
  inc %N
  goto next
}


;; $jfm_ComInit
;;     Creates the com instances required for the script to work
;;         Returns any errors that occured while initializing the coms
alias -l jfm_ComInit {

  ;; Local variable declaration
  var %Error, %Js = $jfm_tmpbvar

  ;; Log the alias call
  jfm_log -I $!jfm_ComInit

  ;; If the JS Shell and engine are already open, log that the com is initialized and return
  if ($com(SReject/JSONForMirc/JSONShell) && $com(SReject/JSONForMirc/JSONEngine)) {
    jfm_log -EsD Already Initialized
    return
  }

  ;; Retrieve the javascript to execute
  jfm_jscript %Js

  ;; close the Engine and shell coms if either but not both are open
  if ($com(SReject/JSONForMirc/JSONEngine)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell)) {
    .comclose $v1
  }

  ;; If the script is being ran under adiirc 64bit
  ;; attemppt to create a ScriptControl object instance
  if ($~adiircexe !== $null) && ($bits == 64) {
    .comopen SReject/JSONForMirc/JSONShell ScriptControl
  }

  ;; Otherwise attempt to create a MSScriptControl.ScriptControl instance
  else {
    .comopen SReject/JSONForMirc/JSONShell MSScriptControl.ScriptControl
  }

  ;; Check to make sure the shell opened
  if (!$com(SReject/JSONForMirc/JSONShell)) || ($comerr) {
    %Error = SCRIPTCONTROL_INIT_FAIL
  }

  ;; attempt to set the com's language property
  elseif (!$com(SReject/JSONForMirc/JSONShell, language, 4, bstr, jscript)) || ($comerr) {
    %Error = LANGUAGE_SET_FAIL
  }

  ;; attempt to set the com's AllowUI property
  elseif (!$com(SReject/JSONForMirc/JSONShell, AllowUI, 4, bool, $false)) || ($comerr) {
    %Error = ALLOWIU_SET_FAIL
  }

  ;; attempt to set the com's timeout property
  elseif (!$com(SReject/JSONForMirc/JSONShell, timeout, 4, integer, -1)) || ($comerr) {
    %Error = TIMEOUT_SET_FAIL
  }

  ;; Execute the jscript
  elseif (!$com(SReject/JSONForMirc/JSONShell, ExecuteStatement, 1, &bstr, %Js)) || ($comerr) {
    %Error = JSCRIPT_EXEC_FAIL
  }

  ;; Attempt to get the JS Engine instance
  elseif (!$com(SReject/JSONForMirc/JSONShell, Eval, 1, bstr, this, dispatch* SReject/JSONForMirc/JSONEngine)) || ($comerr) || (!$com(SReject/JSONForMirc/JSONEngine)) {
    %Error = ENGINE_GET_FAIL
  }

  ;; Error handling: if an mIRC error occured, store the error message then clear the error state
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
    jfm_log -EeD %Error
    return %Error
  }
  else {
    jfm_log -EsD Successfully initialized
  }
}


;; $jfm_GetError
;;     Attempts to get the last error that occured in the JS handler
alias -l jfm_GetError {

  ;; Local variable declaration
  var %Error = UNKNOWN

  ;; log the alias call
  jfm_log -I $!jfm_GetError

  ;; retrieve the errortext property from the shell com
  if ($com(SReject/JSONForMirc/JSONShell).errortext) {
    %Error = $v1
  }

  ;; if the ShellError com is open, close it
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose $v1
  }

  ;; attempt to retrieve the shell com's last error and store the result in %Error
  if ($com(SReject/JSONForMirc/JSONShell, Error, 2, dispatch* SReject/JSONForMirc/JSONShellError)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError)) && ($com(SReject/JSONForMirc/JSONShellError, Description, 2)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError).result !== $null) {
    %Error = $v1
  }

  ;; close the ShellError com
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose $v1
  }

  ;; log and return the error
  jfm_log -EsD %Error
  return %Error
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

  ;; Local variable declaration
  var %Wait = $iif(1 & $4, $true, $false), %NoParse = $iif(2 & $4, $true, $false), %Error

  ;; Log the alias call
  jfm_log -I $!jfm_create( $+ $1 $+ , $+ $2 $+ , $+ $3 $+ , $+ $4)

  ;; Attempt to create the json handler and if an error occurs retrieve the error, log it and return it
  if (!$com(SReject/JSONForMirc/JSONEngine, JSONCreate, 1, bstr, $2, &bstr, $3, bool, %NoParse, dispatch* $1)) || ($comerr) || (!$com($1)) {
    %Error = $jfm_GetError
  }

  ;; Attempt to call the parse method if the handler should not wait for the http request
  elseif ($2 !== http || ($2 == http && !%Wait)) && (!$com($1, parse, 1)) {
    %Error = $jfm_GetError
  }

  if (%Error) {
    jfm_log -EeD %Error
    return %Error
  }
  jfm_log -EsD Created $1
}


;; $jfm_Exec(@Name, @Method, [@Args])
;;     Executes the js method of the specified name
;;         Stores the result in a tmp bvar and stores the name in 'SReject/JSONForMirc Exec' hash
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
  var %Args, %Index = 1, %Params, %Error

  ;; cleanup from previous call
  if ($hget(SReject/JSONForMirc,Exec)) { hdel SReject/JSONForMirc Exec }

  ;; Loop over inputs, storing them in %Args(for logging), and %Params(for com calling)
  :args
  if (%Index <= $0) {
    %Args = %Args $+ $iif($len(%Args), $chr(44)) $+ $($ $+ %Index, 2)
    if (%Index >= 3) {
      if ($prop == fromBvar) && ($regex($($ $+ %Index, 2), /^& (&\S+)$/)) {
        %Params = %Params $+ ,&bstr, $+ $regml(1)
      }
      else {
        %Params = %Params $+ ,bstr,$ $+ %Index
      }
    }
    inc %Index
    goto args
  }
  %Params = $!com($1,$2,1 $+ %Params $+ )

  ;; Log the call
  jfm_log -I $!jfm_Exec( $+ %Args $+ )

  ;; Attempt the com call and if an error occurs
  ;;   retrieve the error, log the error, and return it
  if (!$(%Params, 2)) || ($comerr) {
    %Error = $jfm_GetError
    jfm_log -EeD %Error

  }
  ;; otherwise create a temp bvar, store the result in the the bvar
  else {
    hadd -mu1 SReject/JSONForMirc Exec $jfm_tmpbvar
    noop $com($1, $hget(SReject/JSONForMirc,Exec)).result
    jfm_log -EsD Result stored in $hget(SReject/JSONForMirc,Exec)
  }
}


;; When debug is enabled
;;     the /jfm_log alias with this group gets called
;;
;; When debug is disabled
;;    the /jfm_log alias below this group is called
;;
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
#SReject/JSONForMirc/Log off
alias -l jfm_log {

  ;; Local variable declartion
  var %Switches, %Prefix ->, %Color = 03, %Indent

  ;; if the debug window is not open, disable logging and unset the log indent variable
  if (!$window(@SReject/JSONForMirc/Log)) {
    .JSONDebug off
    if ($hget(SReject/JSONForMirc,LogIndent)) { hdel SReject/JSONForMirc LogIndent }
  }
  else {

    ;; Seperate switches from message parameter
    if (-?* iswm $1) {
      %Switches = $mid($1, 2-)
      tokenize 32 $2-
    }

    if (i isincs %Switches) {
      hinc -mu1 SReject/JSONForMirc LogIndent
    }

    if ($0) {

      ;; Deduce the message prefix
      if (E isincs %Switches) {
        %Prefix = <-
      }

      ;; Deduce the prefix color
      if (e isincs %Switches) {
        %Color = 04
      }
      elseif (s isincs %Switches) {
        %Color = 12
      }
      elseif (l isincs %Switches) {
        %Color = 13
      }

      ;; Compile the prefix
      %Prefix = $chr(3) $+ %Color $+ %Prefix $+ $chr(15)

      ;; Compile the indent
      %Indent = $str($chr(15) $+ $chr(32), $calc($hget(SReject/JSONForMirc,LogIndent) *4))

      ;; Add the log message to the log window
      echo -gi $+ $calc(($hget(SReject/JSONForMirc,LogIndent) + 1) * 4 -1) @SReject/JSONForMirc/Log %Indent %Prefix $1-
    }

    if (I isincs %Switches) {
      hinc -mu1 SReject/JSONForMirc LogIndent 1
    }
    if (D isincs %Switches) && ($hget(SReject/JSONForMirc,LogIndent) > 0) {
      hdec -mu1 SReject/JSONForMirc LogIndent 1
    }
  }
}
#SReject/JSONForMirc/Log end
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
    if ($window(@SReject/JSONForMirc/Log)) && ($line(@SReject/JSONForMirc/Log, 0)) {
      return $true
    }

    ;; otherwise return false
    return $false
  }

  var %File = $sfile($envvar(USERPROFILE) $+ \Documents\JSONForMirc.log, Save, Save)

  ;; if a file was specified and it either doesn't exist or the user wants to overwrite the file
  ;;    save the debug buffer to the specified file
  if (%File) && (!$isfile(%File) || $input(Are you sure you want to overwrite $nopath(%File), qysa, @SReject/JSONForMirc/Log, Overwrite)) {
    savebuf @SReject/JSONForMirc/Log $qt(%File)
  }
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


;; /jfm_jscript @Bvar
;;     Fills the specified bvar with the required jscript
alias -l jfm_jscript {
  var %File = $scriptdirJSON For Mirc.js
  bread $qt(%File) 0 $file(%File).size $1
}
