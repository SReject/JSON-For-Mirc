;; Check to make sure mIRC/AdiIRC is of an applicable version
on *:LOAD:{

  ;; Adiirc check
  if ($~adiircexe) {
    if ($version < 3.0) {
      echo -ag [JSON For mIRC] AdiIRC v3.0 or later is required
      .unload -rs $qt($script)
    }

    ;; tsc64.dll check, this extra dll is required for adiirc 64bits version to work
    if ($bits == 64) && (!$jfm_64bitTest) {
      echo -ag [JSON For mIRC] tsc64.dll v1.1.0.0 or later is required - Download and install it (restart the client after the installation) from: https://tablacus.github.io/scriptcontrol_en.html
      .unload -rs $qt($script)
    }
  }

  ;; mIRC check
  elseif ($version < 7.53) {
    echo -ag [JSON For mIRC] mIRC v7.53 or later is required
    .unload -rs $qt($script)
  }
}

;; clean up incase mirc/adiirc closed due to a crash
on *:START:{
  JSONShutDown
}

;; Free resources when mIRC exits
on *:EXIT:{
  JSONShutDown
}

;; Free resources when the script is unloaded
on *:UNLOAD:{
  JSONShutDown
}


;;===================================;;
;;                                   ;;
;;          PUBLIC COMMANDS          ;;
;;                                   ;;
;;===================================;;

;; /JSONOpen -dbfuUwtN @Name @Input
;;     Creates a JSON handle instance
;;
;;     -d:  Closes the handler after the script finishes
;;     -b:  The input is a bvar
;;     -f:  The input is a file
;;     -i:  Used with -u; Ignore all certificate errors
;;     -u:  The input is from a url
;;     -U:  The input is from a url and its data should not be parsed
;;     -w:  Used with -u; The handle should wait for /JSONHttpGet to be called to perform the url request
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
  if ($isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Switches, %Error, %Com = $false, %Type = text, %Wait = $false, %Parse = $true, %Insecure = $false, %BVar, %BUnset = $true

  ;; Remove switches from other input parameters
  if (-* iswm $1) {
    %Switches = $mid($1, 2-)
    tokenize 32 $2-
  }

  ;; Call the com interface initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }

  ;; Basic switch validation
  elseif ($regex(%Switches, /([^dbfuUwi])/)) {
    %Error = SWITCH_INVALID: $+ $regml(1)
  }
  elseif ($regex(%Switches, /([dbfuUw]).*?\1/)) {
    %Error = SWITCH_DUPLICATE: $+ $regml(1)
  }
  elseif ($regex(%Switches, /([bfuU])/g) > 1) {
    %Error = SWITCH_CONFLICT: $+ $regml(1)
  }
  elseif (u !isin %Switches) && (w isincs %Switches) {
    %Error = SWITCH_NOT_APPLICABLE:w
  }
  elseif (u !isin %Switches) && (i isincs %Switches) {
    %Error = SWITCH_NOT_APPLICABLE:i
  }

  ;; Validate handler name input
  elseif ($0 < 2) {
    %Error = PARAMETER_MISSING
  }
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = NAME_INVALID
  }
  elseif ($com(JSON: $+ $1)) {
    %Error = NAME_IN_USE
  }

  ;; Validate URL where appropriate
  elseif (u isin %Switches) && ($0 != 2) {
    %Error = PARAMETER_INVALID:URL
  }

  ;; Validate bvar where appropriate
  elseif (b isincs %Switches) && ($0 != 2 || !$bvar($2, 0)) {
    %Error = PARAMETER_INVALID:BVAR
  }

  ;; Validate file where appropriate
  elseif (f isincs %Switches) && (!$file($2-).size) {
    %Error = PARAMETER_INVALID:FILE
  }

  ;; All checks passed
  else {
    %Com = JSON: $+ $1
    %BVar = $jfm_TmpBVar


    ;; If input is a bvar indicate it is the bvar to read from and that it
    ;; Should NOT be unset after processing
    if (b isincs %Switches) {
      %Bvar = $2
      %BUnset = $false
    }

    ;; If the input is a url store if the request should wait, and set the
    ;; bvar to the URL to request
    elseif (u isin %Switches) {
      if (w isincs %Switches) {
        %Wait = $true
      }
      if (U isincs %Switches) {
        %Parse = $false
      }
      if (i isincs %Switches) {
        %Insecure = $true
      }
      %Type = http
      bset -t %BVar 1 $2
    }

    ;; If the input is a file, read the file into a bvar
    elseif (f isincs %Switches) {
      bread $qt($file($2-).longfn) 0 $file($file($2-).longfn).size %BVar
    }

    ;; If the input is text, store the text in a bvar
    else {
      bset -t %BVar 1 $2-
    }

    ;; Attempt to create the json handler and if an error occurs retrieve the error
    if (!$com(SReject/JSONForMirc/JSONEngine, JSONCreate, 1, bstr, %Type, &bstr, %BVar, bool, %Parse, bool, %Insecure, dispatch* %Com)) || ($comerr) || (!$com(%Com)) {
      %Error = $jfm_GetError
    }

    ;; Attempt to call the parse method if the handler should not wait for the http request
    elseif (%Type !== http) || (%Type == http && !%Wait) {

      ;; Pause jfm related timers
      ;;   Work-around for mIRC's timers possibly activating while the com processes
      .timerSReject/JSON:?* -p

      %Error = $jfm_Exec(%Com, parse)

      ;; resume all jfm related timers
      .timerSReject/JSON:?* -r
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; Unset the bvar if it was temporary
  if (%BUnset) {
    bunset %BVar
  }

  ;; If the error variable is filled:
  ;;     Store the error in the hashtable
  ;;     Start a timer to close the handle when script-execution finishes
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    if (%Com) && ($com(%Com)) {
      .timerSReject/ $+ %Com -iom 1 0 JSONClose $unsafe($1)
    }
  }

  ;; Otherwise, if the -d switch was specified start a timer to close the com
  elseif (d isincs %Switches) {
    .timerSReject/ $+ %Com -iom 1 0 JSONClose $unsafe($1)
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
  if ($isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Error, %Com, %Method

  ;; Call the com interface initializer
  if ($jfm_ComInit) {
    %Error = $v1
  }

  ;; Basic input validation
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

    ;; Store the com name, trim excess whitespace from the method parameter then validate the method
    %Com = JSON: $+ $1
    %Method = $regsubex($2, /(^\s+)|(\s*)$/g, )
    if (!$len(%Method)) {
      %Error = INVALID_METHOD
    }

    ;; If the method is valid attemp to store it with the handle
    elseif ($jfm_Exec(%Com, httpSetMethod, %Method)) {
      %Error = $v1
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; If an error occured store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
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
  if ($isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Error, %Com, %Header

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

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; If an error occured store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
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
  if ($isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Switches, %Error, %Com, %BVar, %BUnset

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

  ;; Validate switches
  elseif ($regex(%Switches, ([^bf]))) {
    %Error = SWITCH_INVALID: $+ $regml(1)
  }
  elseif ($regex($1, /(?:^\d+$)|[*:? ]/i)) {
    %Error = NAME_INVALID
  }

  ;; Validate @name
  elseif (!$com(JSON: $+ $1)) {
    %Error = HANDLE_DOES_NOT_EXIST
  }

  ;; Validate specified bvar when applicatable
  elseif (b isincs %Switches) && (&* !iswm $2 || $0 > 2) {
    %Error = BVAR_INVALID
  }

  ;; Validate specified file when applicatable
  elseif (f isincs %Switches) && (!$isfile($2-)) {
    %Error = FILE_DOESNOT_EXIST
  }
  else {

    ;; Store the com handler name
    %Com = JSON: $+ $1

    ;; If @data was specified
    if ($0 > 1) {

      ;; Get a temp bvar name
      ;; Indicate the bvar should be unset when the alias finishes
      %BVar = $jfm_tmpbvar
      %BUnset = $true

      ;; If the -b switch is specified, use the @data's value as the bvar data to send
      ;; Indicate the bvar should NOT be unset when the alias finishes
      if (b isincs %Switches) {
        %BVar = $2
        %BUnset = $false
      }

      ;; If the -f switch is specified, read the file's contents into the temp bvar
      elseif (f isincs %Switches) {
        bread $qt($file($2-).longfn) 0 $file($2-).size %BVar
      }

      ;; If no switches were specified, store the @data in the temp bvar
      else {
        bset -t %BVar 1 $2-
      }

      ;; Attempt to store the data to send
      if (!$com(%Com, httpSetData, 1, array &ui1, %BVar, ui4, $bvar(%BVar, 0)) || $comerr) {
        %Error = $jfm_GetError
      }
    }

    ;; Call the js-side parse function for the handler
    if (!%Error) {
      .timerSReject/JSON:?* -p

      %Error = $jfm_Exec(%Com, parse)

      .timerSReject/JSON:?* -r
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; Clear the bvar if indicated it should be unset
  if (%BUnset) {
    bunset %BVar
  }

  ;; If an error occured store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
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
  if ($isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Switches, %Error, %Match, %Com, %X = 1

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

        ;; Close the com and turn off timers associated to the com
        .comclose %Com
        if ($timer(SReject/ $+ %Com)) {
          .timerSReject/ $+ %Com off
        }
      }

      ;; Otherwise move on to the next com
      else {
        inc %X
      }
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; If an error occured store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
  }
}

;; /JSONList
;;     Lists all open JSON handlers
alias JSONList {

  ;; Insure the alias was called as a command
  if ($isid) {
    return
  }

  ;; Local variable declarations
  var %X = 1, %I = 0

  ;; Loop over all open coms
  while ($com(%X)) {

    ;; If the com is a json handler, output the name
    if (JSON:?* iswm $v1) {
      inc %I
      echo $color(info) -age * $chr(35) $+ %I $+ : $v2
    }
    inc %X
  }

  ;; If no json handlers were found, output such
  if (!%I) {
    echo $color(info) -age * No active JSON handlers
  }
}

;; /JSONShutDown
;;    Closes all JSON handler coms and unsets all global variables
alias JSONShutDown {

  ;; Insure the alias was called as a command
  if ($isid) {
    return
  }

  ;; Close all json instances
  JSONClose -w *

  ;; Close the JSON engine and shell coms
  if ($com(SReject/JSONForMirc/JSONEngine)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell)) {
    .comclose $v1
  }

  ;; Free the hashtable
  if ($hget(SReject/JSONForMirc)) {
    hfree $v1
  }
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
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declartions
  var %X, %Params, %Error, %Com, %I = 0, %Prefix, %Prop, %Suffix, %Offset = 2, %Type, %Output, %Result, %ChildCom, %Call

  ;; If the tofile prop has been specified, the member offset is 3, not 2
  if (*ToFile iswm $prop) {
    %Offset = 3
  }

  ;; if there are members specified
  if ($0 >= %Offset) {

    ;; loop over members, building the parameters list
    %X = %Offset
    while (%x <= $0) {
      %Params = %Params $+ ,bstr,$ $+ %X
      inc %x
    }
  }

  ;; If the alias was called without any inputs
  if (!$0) || ($0 == 1 && $1 == $null) {
    %Error = PARAMETER_MISSING
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

  ;; If @Name is a numerical value
  elseif ($1 isnum 0- && . !isin $1) {

    ;; Loop over all coms
    %X = 1
    while ($com(%X)) {

      ;; If the com is a json handler and
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

    ;; If @Name is 0 return the total number of JSON handlers
    if ($1 === 0) {
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

  ;; Basic property validation
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

    ;; If the suffix is 'tofile', validate the 2nd parameter
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

  ;; If the prop is isChild:
  ;;   Create a new bvar for the result
  ;;   Deduce if the specified handler is a child
  elseif (%Prop == isChild) {
    %Result = $jfm_TmpBvar
    if (JSON:?*:?* iswm %com) {
      bset -t %Result 1 $true
    }
    else {
      bset -t %Result 1 $false
    }
  }

  ;; These props do not require the json data to be walked or an input to be specified:
  ;;   Attempt to call the respective js function
  ;;   Retrieve the result
  elseif ($wildtok(state|error|input|inputType|httpParse|httpHead|httpStatus|httpStatusText|httpHeaders|httpBody|httpResponse, %Prop, 1, 124)) {
    if ($jfm_Exec(%Com, $v1)) {
      %Error = $v1
    }
    else {
      %Result = $hget(SReject/JSONForMirc, Exec)
    }
  }

  ;; If the prop is httpheader:
  ;;   Validate input parameters
  ;;   Attempt to retrieve the specified header
  ;;   Retrieve the result
  elseif (%Prop == httpHeader) {
    if ($calc($0 - %Offset) < 0) {
      %Error = INVALID_PARAMETERS
    }
    elseif ($jfm_Exec(%Com, httpHeader, $eval($ $+ %Offset, 2))) {
      %Error = $v1
    }
    else {
      %Result = $hget(SReject/JSONForMirc, Exec)
    }
  }

  ;; These props require that the json handler be walked before processing the prop itself
  elseif (%Prop == $null) || ($wildtok(path|pathLength|type|isContainer|length|value|string|debug, %Prop, 1, 124)) {
    %Prop = $v1

    ;; If members have been specified then the JSON handler's json needs to be walked
    if ($0 >= %Offset) {

      %ChildCom = JSON: $+ $gettok(%Com, 2, 58) $+ :

      ;; Get a unique com name for the handler
      %X = $ticks $+ 000000
      while ($com(%ChildCom $+ %X)) {
        inc %X
      }
      %ChildCom = %ChildCom $+ %X

      ;; Build the call 'string' to be evaluated
      %Call = $!com( $+ %Com $+ ,walk,1,bool, $+ $iif(fuzzy == %Prefix, $true, $false) $+ %Params $+ ,dispatch* %ChildCom $+ )

      ;; Attempt to call the js-side's walk function: walk(isFuzzy, member, ...)
      ;; If an error occurs, store the error and skip to error handling
      if (!$eval(%Call, 2)) || ($comerr) || (!$com(%ChildCom)) {
        %Error = $jfm_GetError
        goto error
      }

      ;; Otherwise, close the child com after script execution, update the %Com variable to indicate the child com
      .timerSReject/ $+ %ChildCom -iom 1 0 JSONClose %ChildCom
      %Com = %ChildCom
    }

    ;; No Prop? then the result is the child com's name
    if (!%Prop) {
      %Result = $jfm_TmpBvar
      bset -t %Result 1 %Com
    }

    ;; If the prop isn't value, just call the js method to return data requested by the prop
    elseif (%Prop !== value) {
      if ($jfm_Exec(%Com, $v1)) {
        %Error = $v1
      }
      else {
        %Result = $hget(SReject/JSONForMirc, Exec)
      }
    }

    ;; If the prop is value:
    ;;   Attempt to get it's cast-type
    ;;   Check the value's cast type
    ;;   Attempt to retrieve the value
    ;;   Fill the result variable with its value
    elseif ($jfm_Exec(%Com, type)) {
      %Error = $v1
    }
    elseif ($bvar($hget(SReject/JSONForMirc, Exec), 1-).text == object) || ($v1 == array) {
      %Error = INVALID_TYPE
    }
    elseif ($jfm_Exec(%Com, value)) {
      %Error = $v1
    }
    else {
      %Result = $hget(SReject/JSONForMirc, Exec)
    }
  }

  ;; Otherwise, report the specified prop is invalid
  else {
    %Error = UNKNOWN_PROP
  }

  ;; If no error has occured up to this point
  if (!%Error) {

    ;; If the tofile suffix was specified, write the result to file
    if (%Suffix == tofile) {
      bwrite $qt(%Output) -1 -1 %Result
      bunset %Result
      %Result = %Output
    }

    ;; If the tobvar suffix was specified, return the result bvar
    elseif (%Suffix !== tobvar) {
      %Result = $bvar(%Result, 1, 4000).text
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; If an error occured store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
  }
  else {
    return %Result
  }
}

;; $JSONForValues(@Name|Ref|N, /callback[, sub-members])
alias JSONForValues {

  ;; Insure the alias was called as an identifier
  if (!$isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc,Error)) {
    hdel SReject/JSONForMirc Error
  }

  var %Error, %Call, %X = 2, %JSON, %BVar, %N, %Value, %Result = 0

  ;; Build call parameter portion:
  ;;   ,forValues,1[,bstr,$N,...]
  %Call = ,forValues,1

  while (%X < $0) {
    inc %X
    %Call = %Call $+ ,bstr, $+ $ $+ %X
  }

  ;; Basic input validation
  if ($0 < 2) {
    %Error = INVALID_PARAMETERS
  }
  elseif ($1 === 0) {
    %Error = INVALID_HANDLE
  }

  ;; Validate @Name|Ref|N
  elseif (!$1) || ($1 == 0) || (!$regex($1, /^((?:[^?:*]+)|(?:JSON:[^?:*]+(?::\d+)))$/)) {
    %Error = NAME_INVALID
  }
  else {

    ;; Deduce json handle
    ;; This could be done by calling $JSON() but this way is much faster
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

      ;; Finish building com call: $com(com_name,forValues,1,[call_parameters])
      %Call = $!com( $+ %JSON $+ %Call $+ )

      ;; Make the com call and check for errors
      if (!$eval(%Call, 2)) || ($comerr) {
        %Error = $jfm_GetError
      }

      ;; Com call is success
      else {

        ;; Get a bvar to store the result in
        %BVar = $jfm_TmpBVar

        ;; Retrieve the result
        noop $com(%JSON, %BVar).result

        ;; Loop over each \1 delimited 'string' in the result
        %X = 1
        while ($bfind(%BVar, %X, 0)) {

          ;; Get text for the value
          %N = $v1
          %Value = $bvar(%BVar, %X, $calc(%N - %X)).text

          ;; Call command
          $2 %Value

          ;; Increase number of items looped over
          inc %Result

          ;; Prep for next item
          %X = %N + 1
        }

        ;; One item not looped over
        if (%X <= $bvar(%BVar, 0)) {

          ;; Retrieve value
          %Value = $bvar(%BVar, %X $+ -).text

          ;; Call command
          $2 %Value

          ;; Increase number of items looped over
          inc %Result
        }
      }
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; If an error occured store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
  }

  ;; Successful, return the number of results looped over
  else {
    return %Result
  }
}

;; $JSONForEach(@Name|Ref|N, @command, @Members)[.fuzzy]
;; $JSONForEach(@Name|Ref|N, @Command).walk
alias JSONForEach {

  ;; Insure the alias was called as an identifier
  if (!$isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc,Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Error, %Call, %X = 2, %JSON, %Com, %ChildCom, %Result = 0, %Name

  ;; Build call parameter portion:
  ;;   ,forEach,1,bool,$true|$false,bool,$true|$false[,bstr,$N,...]
  if ($prop == walk) {
    %Call = ,forEach,1,bool,$true,bool,$false
  }
  elseif ($prop == fuzzy) {
    %Call = ,forEach,1,bool,$false,bool,$true
  }
  else {
    %Call = ,forEach,1,bool,$false,bool,$false
  }

  while (%X < $0) {
    inc %x
    %Call = %Call $+ ,bstr, $+ $ $+ %X
  }

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

    ;; Deduce json handle
    ;; This could be done by calling $JSON() but this way is much faster
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
      %X = $ticks $+ 000000
      while ($com(%Com $+ %X)) {
        inc %x
      }
      %Com = %Com $+ %X

      ;; Build com call: $com(com_name,forEach,1,[call_parameters],dispatch* new_com)
      %Call = $!com( $+ %JSON $+ %Call $+ ,dispatch* %Com $+ )

      ;; Make the com call and check for errors
      if (!$eval(%Call, 2)) || ($comerr) || (!$com(%Com)) {
        %Error = $jfm_GetError
      }

      ;; Successfully called
      else {

        ;; Start a timer to close the com
        .timerSReject/ $+ %Com -iom 1 0 JSONClose $unsafe(%Com)

        ;; Check length
        if (!$com(%Com, length, 2)) || ($comerr) {
          %Error = $jfm_GetError
        }

        elseif ($com(%Com).result) {
          %Result = $v1
          %X = 0

          ;; Get a name for the child com
          %ChildCom = $gettok(%Com, 1-2, 58) $+ :
          %Name = $ticks
          while ($com(%ChildCom $+ %Name)) {
            inc %Name
          }
          %Name = %ChildCom $+ %Name

          ;; increase the ForEach index and store it
          ;; This is to make access to the item's data via $JSONItem(Todo) faster
          hinc -m SReject/JSONForMirc ForEach/Index
          hadd -m SReject/JSONForMirc ForEach/ $+ $hget(SReject/JSONForMirc, ForEach/Index) %Name

          ;; Loop over each item in the returned list
          while (%X < %Result) {

            ;; Attempt to get a reference to the nTH item and then check for errors
            if (!$com(%Com, %X, 2, dispatch* %Name) || $comerr) {
              %Error = $jfm_GetError
              break
            }

            ;; Call the command then close the child com
            $2 %Name
            .comclose %Name

            ;; move to next result
            inc %X
          }

          ;; Remove the child com name from the hashtable
          ;; decrease the foreach index and if the index is 0 remove the hashtable item
          hdel SReject/JSONForMirc ForEach/ $+ $hget(SReject/JSONForMirc, ForEach/Index)
          hdec SReject/JSONForMirc ForEach/Index
          if ($hget(SReject/JSONForMirc, ForEach/Index) == 0) {
            hdel SReject/JsonForMirc ForEach/Index
          }
        }
      }
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $error
  }
  reseterror

  ;; If an error occured close the items com if its open then store then error
  if (%Error) {
    if ($com(%Com)) {
      .comclose $v1
    }
    if (JSON:* iswm %Name && $com(%Name)) {
      .comclose %Name
    }
    hadd -mu0 SReject/JSONForMirc Error %Error
  }

  ;; Successful, return the number of results looped over
  else {
    return %Result
  }
}

;; $JSONItem(@Property)
;;   Returns information related to the current item from a $JSONForEach loop
;;   This is a very slimmed down version of $JSON/accesing with no error checking and minimal input validation
;;   May add more items upon request
alias JSONItem {

  ;; retrieve the item's com name and validate it
  var %Com = $hget(SReject/JSONForMirc, ForEach/ $+ $hget(SReject/JSONForMirc, ForEach/Index)), %Type, %Bvar, %Text
  if (!$isid || !%Com || !$com(%Com)) {
    return
  }

  ;; returns the value of an item
  if ($1 == Value || $1 == Valuetobvar) {

    ;; get a temp bvar and then retrieve the items value into it
    %BVar = $jfm_TmpBVar
    noop $com(%Com, value, 1) $Com(%Com, %BVar).result

    ;; if the value is to be retrieved as a bvar, return the bvar
    if ($1 == valuetobvar) {
      return %Bvar
    }

    ;; Otherwise store the text from the bvar
    ;; unset the bvar(circumvents possible looping from next $JSONEach iteration)
    ;; and return the text
    %Text = $bvar(%BVar, 1, 4000).text
    bunset %BVar
    return %Text
  }

  ;; returns the length of the item
  elseif ($1 == Length) {
    noop $com(%com, length, 1)
    return $com(%com).result
  }

  elseif ($1 == Type || $1 == IsContainer) {

    ;; retrieve the item's type
    noop $com(%Com, type, 1)
    var %type = $com(%Com).result

    ;; if the type is requested, return it
    if ($1 == type) {
      return %Type
    }

    ;; if the input is "IsContainer" and is an object or arry
    ;; return $true
    if (%type == Object || %Type == Array) {
      return $true
    }

    ;; otherwise return false
    return $false
  }
}

;; $JSONPath(@Name|ref|N, index)
;;    Returns information related to a handler's path
alias JSONPath {
  if (!$isid) {
    return
  }

  ;; Unset the global error variable incase the last call ended in error
  if ($hget(SReject/JSONForMirc, Error)) {
    hdel SReject/JSONForMirc Error
  }

  ;; Local variable declarations
  var %Error, %JSON, %Result

  ;; Validate inputs
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

      ;; If $2 is 0 do nothing
      if (!$2) noop

      ;; If $2 is greater than the path length, %Result is nothing/null
      elseif ($2 > %Result) {
        unset %Result
      }

      ;; Attempt to retrieve the path item at the specified index
      elseif (!$com(%JSON, pathAtIndex, 1, bstr, $calc($2 -1))) || ($comerr) {
        %Error = $jfm_GetError
      }

      ;; Retrieve the result from the com
      else {
        %Result = $com(%JSON).result
      }
    }
  }

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
  }
  reseterror

  ;; If an error occured and store the error
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
  }

  ;; Otherwise return the result
  else {
    return %Result
  }
}

;; $JSONError
;;     Returns any error the last call to /JSON* or $JSON() raised
alias JSONError {
  if ($isid) {
    return $hget(SReject/JSONForMirc, Error)
  }
}

;; $JSONVersion(@Short)
;;     Returns script version information
;;
;;     @Short - Any text
;;         Returns the short version
alias JSONVersion {
  if ($isid) {
    var %Ver = 2.0.2006
    if ($0) {
      return %Ver
    }
    return SReject/JSONForMirc v $+ %Ver
  }
}


;;===================================;;
;;                                   ;;
;;          PRIVATE ALIASES          ;;
;;                                   ;;
;;===================================;;

;; $jfm_TmpBVar
;;     Returns the name of a not-in-use temporarily bvar
alias -l jfm_TmpBVar {

  ;; Local variable declaration
  var %N = $ticks $+ 00000

  ;; Loop until a bvar that isn't in use is found
  while ($bvar(&SReject/JSONForMirc/Tmp $+ %N)) {
    inc %N
  }
  return &SReject/JSONForMirc/Tmp $+ %N
}

;; $jfm_64bitTest
;;     Returns $true if tsc64.dll is com-registered
alias -l jfm_64bitTest {

  ;; Deduce a com name to use
  var %Com = SReject/JSONForMirc/64bitScriptControlTest, %X = 0, %Result = $false
  while ($com(%Com $+ %X)) {
    inc %X
  }

  ;; Attempt to open the com
  .comopen %Com ScriptControl

  ;; Com successfully opened
  if ($com(%Com) && !$comerr) {
    %Result = $true
  }

  ;; Clean up and return the result
  if ($com(%com)) {
    .comclose %Com
  }
  return %Result
}

;; $jfm_ComInit
;;     Creates the com instances required for the script to work
;;     Returns any errors that occured while initializing the coms
alias -l jfm_ComInit {

  ;; Local variable declaration
  var %Error, %Js = $jfm_tmpbvar, %File = $scriptdirJSON For Mirc.js

  ;; If the JS Shell and engine are already open return
  if ($com(SReject/JSONForMirc/JSONShell) && $com(SReject/JSONForMirc/JSONEngine)) {
    return
  }

  ;; Retrieve the javascript to execute
  bread $qt(%File) 0 $file(%File).size %Js

  ;; Close the Engine and shell coms if either but not both are open
  if ($com(SReject/JSONForMirc/JSONEngine)) {
    .comclose $v1
  }
  if ($com(SReject/JSONForMirc/JSONShell)) {
    .comclose $v1
  }

  ;; If the script is being ran under adiirc 64bit,
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

  ;; Attempt to set the com's language property
  elseif (!$com(SReject/JSONForMirc/JSONShell, language, 4, bstr, jscript)) || ($comerr) {
    %Error = LANGUAGE_SET_FAIL
  }

  ;; Attempt to set the com's AllowUI property
  elseif (!$com(SReject/JSONForMirc/JSONShell, AllowUI, 4, bool, $false)) || ($comerr) {
    %Error = ALLOWIU_SET_FAIL
  }

  ;; Attempt to set the com's timeout property
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

  ;; Error handling: if an client error occured, store the error message then clear the error state
  :error
  if ($error) {
    %Error = $v1
    reseterror
  }

  ;; If an error occured clean up and return the error
  if (%Error) {
    if ($com(SReject/JSONForMirc/JSONEngine)) {
      .comclose $v1
    }
    if ($com(SReject/JSONForMirc/JSONShell)) {
      .comclose $v1
    }
    return %Error
  }
}

;; $jfm_GetError
;;     Attempts to get the last error that occured in the JS handler
alias -l jfm_GetError {

  ;; Local variable declaration
  var %Error = UNKNOWN

  ;; Retrieve the errortext property from the shell com
  if ($com(SReject/JSONForMirc/JSONShell).errortext) {
    %Error = $v1
  }

  ;; If the ShellError com is open, close it
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose SReject/JSONForMirc/JSONShellError
  }

  ;; Attempt to retrieve the shell com's last error and store the result in %Error
  if ($com(SReject/JSONForMirc/JSONShell, Error, 2, dispatch* SReject/JSONForMirc/JSONShellError)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError)) && ($com(SReject/JSONForMirc/JSONShellError, Description, 2)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError).result !== $null) {
    %Error = $v1
  }

  ;; Close the ShellError com
  if ($com(SReject/JSONForMirc/JSONShellError)) {
    .comclose SReject/JSONForMirc/JSONShellError
  }

  ;; Return the error
  return %Error
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

  ;; Cleanup from previous call
  if ($hget(SReject/JSONForMirc, Exec)) {
    hdel SReject/JSONForMirc Exec
  }

  ;; Local variable declaration
  var %Index = 2, %Params

  ;; Loop over inputs, storing them in %Params(for com calling)
  while (%Index < $0) {
    inc %Index
    if ($prop == fromBvar) && ($regex($eval($ $+ %Index, 2), /^& (&\S+)$/)) {
      %Params = %Params $+ ,&bstr, $+ $regml(1)
    }
    else {
      %Params = %Params $+ ,bstr,$ $+ %Index
    }
  }
  %Params = $!com($1,$2, 1 $+ %Params $+ )

  ;; Attempt the com call and if an error occurs return the error
  if (!$eval(%Params, 2) || $comerr) {
    return $jfm_GetError
  }

  ;; Otherwise create a temp bvar, store the result in the the bvar
  else {
    hadd -mu0 SReject/JSONForMirc Exec $jfm_tmpbvar
    noop $com($1, $hget(SReject/JSONForMirc, Exec)).result
  }
}