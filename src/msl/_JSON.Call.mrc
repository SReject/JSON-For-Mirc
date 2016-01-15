alias -l _JSON.Call {
  if (!$isid) {
    return 
  }

  var %com, %com2, %com3, %Error, %Result, %i, %tok, %call, %bvar, %bvars
  if (!$_JSON.Start) {
    %Error = $JSONError
  }
  else {
    %com  = $_JSON.Com(Wrapper)
    %com2 = $_JSON.Com(JSEngine)
    %com3 = $_JSON.Com(Tmp)
    %i = 1
    while (%i < $0) {
      inc %i
      %tok = $($ $+ %i, 2)
      if (%tok isnum) {
        %call = $addtok(%call, integer $+ $chr(44) $+ %tok, 44)
      }
      else {
        if ("*" !iswm %tok) {
          %tok = $JSONEscape(%tok)
        }
        %bvar = &JSONForMirc:Call $+ %i
        %bvars = %bvar %bvar
        bunset %bvar
        bset -t %bvar 1 $mid(%tok, 2, -1)
        %Call = $addtok(%call, &bstr $+ $chr(44) $+ %bvar, 44)
      }
    }
    if ($prop == dispatch) {
      %call = $addtok(%call, dispatch* %com3, 44)
    }
    if (!$com(%com2, $1, 1, [ [ %call ] ] ) || $comerr) {
      if ($com(%com3)) {
        .comclose $v1
      }
      if (!$com(%com1, Error, 2, dispatch* %com3) || $comerr || !$com(%com3)) {
        %Error = Call Error - Unable to retrieve error reference
      }
      elseif (!$com(%com3, Description, 2) || $comerr) {
        %Error = Call Error - Unable to retrieve error message
      }
      elseif ($com(%com3).result) {
        %Error = $v1
      }
      else {
        %Error = Call Error - No message given
      }
      %Result = $null
    }
    elseif ($prop != dispatch) {
      %Result = $com(%com2).result
    }
    elseif (!$com(%com3)) {
      %Error = Result not dispatched
    }
    else {
      %Result = %com3
    }
  }
  :error
  %Error = $iif($error, $v1, %Error)
  bunset %bvars
  if ($com(%com3) && (!%dispatch || %error)) {
    .comclose %com3
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
  }
  else {
    return %Result
  }
}