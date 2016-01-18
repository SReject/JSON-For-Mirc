/** /JSONOpen -dbfuw @Handle @Source
***     Sets a pending Handle's HTTP request method
***
***     -d: Destroys the handle after the calling script finishes
***     -b: @Source is a bvar
***     -f: @Source is a file
***     -u: @Source is a url
***     -w: Specified with -u; The HTTP request will wait to fetch data so method and headers can be so
*** 
***     @Handle - (required):
***         Name to be used to reference the JSON handle
***
***     @Source:
***         The JSON source
***         Dependant on switches it can be plain text, a bvar, a file or a url
**/ 
alias JSONOpen {
  if ($isid) return

  var %Error, %Switches, %Name, %Type, %Source, %Unset, %ErrorCom
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

    ;; Validate switches
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

    ;; Validate name parameter
    elseif (!$regex($1, /^[a-z][a-z\d_.:\-]+$/i)) {
      %Error = Invalid handler name: Must start with a letter and contain only letters numbers _ . : and -
    }
    elseif ($_JSON.Exists($1)) {
      %Error = Name in use    
    }

    ;; Validate parameters
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

    ;; Checks passed, attempt to create handle
    else {
      %Name = $1
      %Source = $_JSON.TmpBVar
      %Type = text
      %Wait = $false
      %Unset = $true

      ;; Variable setup
      if (u isincs %Switches) {
        bset -t %Source 1 $2
        %Type = url
        %Wait = $iif(w isin %Switches, $true)
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

      ;; Call the JS function to create a handle:
      ;;   Handle.create(name, source, type, wait)
      if (!$_JSON.CallFunct(Handle, create, 1, bstr, %Name, &bstr, %Source, bstr, %Type, bool, %Wait) || $comerr) {
        %Error = $JSONError
      }

      ;; If the d switch is specified, start a timer to close the handle
      elseif (d isincs %Switches) {
        $+(.timerJSONForMirc:Close, $1) 1 0 JSONClose $1
      }
    }
  }

  ;; Error handling
  :error
  %Error = $iif($error, $v1, %Error)
  if (%Unset) bunset %Source
  if (%ErrorCom && $com(%ErrorCom)) .comclose $v1
  if (%Error) {
    set -u %JSONForMirc:Error $v1
    reseterror
  }
}