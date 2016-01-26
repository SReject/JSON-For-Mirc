/** $_JSON.Start()
***     Attempts to create required COM instances
***
***     Returns $true if successful, $false if not
**/
alias -l _JSON.Start {
  if (!$isid) {
    return
  }
  
  ;; debug message
  _JSON.Log Calling~$_JSON.Start()
  
  ;; variable declaration
  var %Error, %Close = $false, %Wrapper = $_JSON.Com(Wrapper), %Engine = $_JSON.Com(Engine), %Manager = $_JSON.Com(Manager), %JScript

  ;; COM interface lock check
  if ($lock(com)) {
    %Error = COM interface locked via mIRC options
  }

  ;; I all coms are open assume they are JSONForMirc's so return $true
  elseif ($com(%Wrapper) && $com(%Engine) && $com(%Manager)) {
    return $true
  }
  else {

    ;; cleanup from a previously failed start
    if ($com(%Manager)) {
      .comclose $v1
    }
    if ($com(%Engine)) {
      .comclose $v1
    }
    if ($com(%Wrapper)) {
      .comclose $v1
    }

    ;; Update 'close' variable so if an error occurs created coms are closed
    %Close = $true

    ;; Get the JScript to be executed
    %JScript = $_JSON.JScript($_JSON.TmpBVar)

    ;; Create the required MSScriptControl instance
    ;; set the language and timeout length
    .comopen %Wrapper MSScriptControl.ScriptControl
    if (!$com(%Wrapper) || $comerr) {
      %Error = Unable to create instance of MSScriptControl.ScriptControl
    }
    elseif (!$com(%Wrapper, language, 4, bstr, jscript) || $comerr) {
      %Error = Unable to set the ScriptControl's language to JScript
    }
    elseif (!$com(%Wrapper, timeout, 4, bstr, 60000) || $comerr) {
      %Error = Unable to set the ScriptControl's timeout to 60s
    }

    ;; Execute the JScript
    elseif (!$com(%Wrapper, ExecuteStatement, 1, &bstr, %JScript) || $comerr) {
      %Error = Unable to add JScript to the ScriptControl
    }

    ;; Verify that the execution was a success
    elseif (!$com(%Wrapper, Eval, 1, bstr, this, dispatch* %Engine) || $comerr) {
      %Error = JScript execution failed
    }
    elseif (!$com(%Engine)) {
      %Error = Unable to create a reference to the ScriptControl's JSEngine
    }

    ;; Attempt to get a reference to the JScript's Handle manager
    elseif (!$com(%Engine, Handle, 2, dispatch* %Manager) || $comerr) {
      %Error = Referencing the JScript's Handle manager failed
    }
    elseif (!$com(%Manager)) {
      %Error = Reference to the JScript's Handle manager failed
    }
  }

  ;; Cleanup and return $true if successful, $false otherwise
  :error
  %Error = $iif($error, $v1, %Error)
  if ($bvar(%JScript, 0)) {
    bunset %JScript
  }
  if (%Error) {
    set -u %_JSONForMirc:Error $v1
    reseterror
    if (%Close) {
      if ($com(%Manager)) {
        .comclose $v1
      }
      if ($com(%Engine)) {
        .comclose $v1
      }
      if ($com(%Wrapper)) {
        .comclose $v1
      }
    }
    _JSON.Log error $!_JSON.Start~ $+ %Error
    return $false
  }
  _JSON.Log ok $!_JSON.Start~Call Successful
  return $true
}