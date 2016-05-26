alias JSONList {
  var %Error, %Result, %RefCom, %Index = 0, %Length

  ;; initial checks
  if ($isid) {
    return
  }
  elseif (!$_JSON.Start) {
    %Error = $v1
  }

  ;; validate inputs
  elseif ($0) {
    %Error = Invalid parameters specified
  }
  else {

    ;; attempt to get a reference to the list of open handles
    %RefCom = $_JSON.Com
    if (!$_JSON.Call(Manager, list, 1, bstr, .*, dispatch* %RefCom)) {
      %Error = $JSONError
    }
    elseif (!$com(%RefCom)) {
      %Error = Unable to retrieve Handle List
    }
    elseif (!$com(%RefCom, length, 2) || $comerr) {
      %Error = Unable to retrieve length of Handle List
    }
    else {

      %Length = $com(%RefCom).result

      ;; Handle no open handles
      if (!%Length) {
        echo $color(info) -se * No open JSON handles
      }

      ;; loop over all open handles and echo their name to the status
      else {
        echo $color(info) -se Open JSON Handles:
        while (%Index < %Length) {
          if (!$com(%RefCom, %Index, 2) || $comerr) {
            %Error = Unable to reference index: %Index
            break
          }
          else {
            echo $color(info) $iif($calc(%index +1) == %Length, -se, -s) $com(%RefCom).result
          }
          inc %Index
        }
      }
    }
  }

  ;; Handle errors
  :error
  %Error = $iif($error, $v1, %Error)
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error /JSONClose $v1
  }
  else {
    _JSON.Log ok /JSONList~Listed without error
  }
}