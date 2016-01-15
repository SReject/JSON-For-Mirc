alias -l _JSON.Start {
  if ($lock(com)) {
    set -u %_JSONForMirc:Error COM interface locked via mIRC options
    return $false
  }
  var %Error, %com1 = $_JSON.Com(Wrapper), %com2 = $_JSON.Com(JSEngine)
  if ($com(%com1) && $com(%com2)) {
    return $true
  }
  if ($com(%com2)) {
    .comclose $v1
  }
  if ($com(%com1)) {
    .comclose $v1
  }
  .comopen %com1 MSScriptControl.ScriptControl
  if (!$com(%com1) || $comerr) {
    %Error = Unable to create instance of MSScriptControl.ScriptControl
  }
  elseif (!$com(%com1, language, 4, bstr, jscript) || $comerr) {
    %Error = Unable to set the ScriptControl's language to JScript
  }
  elseif (!$com(%com1, timeout, 4, bstr, 60000) || $comerr) {
    %Error = Unable to set the ScriptControl's timeout to 60s
  }
  elseif (!$com(%com1, ExecuteStatement, 1, &bstr, $jscript) || $comerr) {
    %Error = Unable to add JScript to the ScriptControl
  }
  elseif (!$com(%com1, eval, 1, bstr, this, dispatch* %com2) || $comerr) {
    %Error = Unable to create a reference to the ScriptControl's JSEngine
  }
  elseif (!$com(%com2)) {
    %Error = Reference to JSEngine not created
  }
  else {
    return $true
  }
  :error
  %Error = $iif($error, $v1, %Error)
  if (%Error) {
    reseterror
    if ($com(%com2)) {
      .comclose $v1
    }
    if ($com(%com1)) {
      .comclose $v1
    }
    set -u %_JSONForMirc:Error $v1
    return $false
  }
}
