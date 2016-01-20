alias -l _JSON.CallFunct {
  ;; Output debug message
  scid $cid var % $+ param = % $+ param $!+ $!chr(44) $!+ $*
  %param = $mid(%param, 2-)
  _JSON.Log Calling~$!_JSON.CallFunct( $+ $mid(%param, 2-) $+ )

  ;; Variable setup
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
    _JSON.Log Error $!_JSON.CallFunct~ $+ INVALID_COM_NAME
    return $false
  }

  ;; Perform the com call
  if (!$com(%Com, [ $gettok(%param, 2-, 44) ] ) || $comerr) {

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
     _JSON.Log Error $!_JSON.CallFunct~ $+ %error
    return $false
  }
  _JSON.Log ok $!_JSON.CallFunct~Call Succeesful
  return $true
}


alias -l _JSON.CallHandleFunct {

  ;; Debug message
  scid $cid var % $+ param = % $+ param $*
  %param = $mid(%param, 2-)
  _JSON.Log Calling~$!_JSON.CallFunct( $+ %param $+ )

  var %Error, %CloseRef, %RefCom

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
    if (!$_JSON.CallFunct(Manager, get, 1, bstr, $1, dispatch* %RefCom)) {
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
    return $false
  }
  return $true
}
