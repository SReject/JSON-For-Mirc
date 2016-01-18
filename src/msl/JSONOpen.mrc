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

  var %Error, %Switches, %BVar, %UnsetBVar
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

      ;; HTTP request handle
      if (u isincs %Switches) {
        if (!$_JSON.Create($1, $2).url [ $+ [ $iif(w isin %Switches, wait) ] ]) {
          %Error = %_JSONForMirc:Error
        }
      }

      ;; local handle
      else {

        ;; store input in a bvar if need be
        if (b isincs %Switches) {
          %BVar = $2
        }
        else {
          %BVar = $_JSON.TmpBVar
          %UnsetBVar = $true
          if (f isincs %switches) {
            bread $qt($file($2-)) 0 $file($2-).size %BVar
          }
          else {
            bset -t %BVar 1 $2-
          }
        }

        ;; attempt to create the handle
        if (!$_JSON.Create($1, %BVar)) {
          %Error = %_JSONForMirc:Error
        }
      }

      ;; If handle creation succeeded, and the d switch is specified, start a timer to close the handle
      if (!%Error && d isincs %Switches) {
        $+(.timerJSONForMircClose:, $1) 1 0 JSONClose $1
      }
    }
  }

  ;; Error handling
  :error
  %Error = $iif($error, $v1, %Error)
  if (%UnsetBVar) bunset %BVar
  if (%Error) {
    set -u %JSONForMirc:Error $v1
    reseterror
  }
}