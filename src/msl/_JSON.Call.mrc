alias -l _JSON.CallFunct {
  var %Com, %Error, %ErrorCom
  
  ;; Figure out which com to use
  if ($istok(Wrapper Enginer Manager, $1, 32)) {
    %Com = $_JSON.Com($1)
  }
  else if (JSONForMirc:Tmp:* iswm $1 && $com($1)) {
    %Com = $1
  }
  else {
    set -u %_JSONForMirc:Error INVALID_COM_NAME
    return $false
  }
  
  ;; Perform the com call
  if (!$com(%Com,  [ [ $2- ] ] ) || $comerr) {
  
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
  
  
  :error
  %Error = $iif($error, $v1, %Error)
  if (%ErrorCom && $com(%ErrorCom)) {
    .comclose $v1
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    return $false
  }
  return $true
}


alias -l _JSON.CallHandleFunct {
  var %Error, %CloseRef, %RefCom = $_JSON.Com
  /*
  Add support for passed ReferenceComs instead of just a handle name
  */
  
  
  if (!$_JSON.CallFunct(Manager, get, 1, bstr, $1, dispatch* %RefCom)) {
    %Error = $JSONError
  }
  elseif (!$com(%RefCom)) {
    %Error = Retrieving reference failed
  }
  elseif (!$_JSON.CallFunct(%RefCom, $2-)) {
    %Error = $JSONError
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if ($prop != KeepRef && $com(%RefCom)) {
    .comclose $v1
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    return $false
  }
  return $true
}
