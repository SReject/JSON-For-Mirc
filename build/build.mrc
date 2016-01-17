alias -l jsEsc return $replace($1-, \, \\, ", \")

alias -l bError {
  if ($1) {
    if ($com(JSONForMircError)) .comclose $v1
    if ($com(JSONForMircBuild)) .comclose $v1
  }
  echo -a 04[ERROR] $2-
  halt
}
alias -l bEcho {
  var %c = 12
  if ($1 == -w) {
    %c = 07
  }
  if ($1 == -s) {
    %c = 03
  }
  if ($1 == -d) {
    %c = 13
  }
  echo -a $+(,%c,[,$2,]) $3-
}


alias JSONForMircBuild {
  if ($lock(com)) {
    bError 0 COM interface locked via mIRC options
  }

  var %close, %dir, %src, %out, %error, %bvar, %com, %com2

  %close = $false
  %dir = $gettok($scriptdir, 1--2, $asc(\)) $+ \
  %src = %dir $+ src\
  %out = %dir $+ builds\
  %error
  %bvar = 1
  %com = JSONForMircBuild
  %com2  = JSONForMircBuildError

  bEcho -i INIT Set build resource location to: $scriptdir
  bEcho -i INIT Set source directory to: %src
  bEcho -i INIT Set output directory to: %out

  while ($bvar(& $+ buildjs $+ %bvar, 0)) inc %bvar
  %bvar = &buildjs $+ %bvar
  bEcho -i INIT Set build.js bvar to: %bvar


  bEcho -i INIT Looking for build.js in $scriptdir
  if (!$isfile($scriptdirbuild.js)) {
    bError 0 build.js not found in $scriptdir
  }
  bEcho -s INIT build.js located


  bEcho -i INIT looking for build.json in $scriptdir
  if (!$isfile($scriptdirbuild.json)) {
    bError 0 build.json not found in $scriptdir
  }
  bEcho -s INIT build.json found


  bEcho -i SETUP Reading contents of build.js
  %Error = Unable to read the contents of build.js
  bread $qt($scriptdirbuild.js) 0 $file($scriptdirbuild.js).size %bvar
  if (!$bvar(%bvar, 0)) {
    bError 0 No data read from build.js
  }
  %Error = $null
  bEcho -s SETUP Successfully read the contents of build.js


  bEcho -i SETUP Supplying parameters to build.js
  if ($bfind(%bvar, 1, __PARAMETERS__) < 1) {
    bError 0 Unable to locate parameter placement in build.js
  }
  %Error = Unable to supply parameters to build.js
  bcopy -c %bvar 1 %bvar 1 $calc($v1 - 1)
  bset -t %bvar $calc($bvar(%bvar, 0) +1) $qt($jsEsc($scriptdirbuild.json)) , $qt($jsEsc(%src)) , $qt($jsEsc(%out)) ));
  %Error = $null
  bEcho -s SETUP Successfully supplied parameters to build.js


  %close = $true
  if ($com(%com)) .comclose $v1
  if ($com(%com2)) .comclose $v1


  bEcho -i START Creating MSScriptControl.ScriptControl instance
  .comopen %com MSScriptControl.ScriptControl
  if (!$com(%com) || $comerr) {
    bError 1 Unable to create MSScriptControl.ScriptControl instance
  }
  bEcho -s START MSScriptControl.ScriptControl instance created


  bEcho -i START Setting language to JScript
  if (!$com(%com, language, 4, bstr, jscript) || $comerr) {
    bError 1 Unable to set language
  }
  bEcho -s START Language set


  bEcho -i BUILD Running build.js
  if (!$com(%com, Eval, 1, &bstr, %bvar) || $comerr) {
    if ($com(%com, Error, 2, dispatch* %com2) && !$comerr && $com(%com2) && $com(%com2, Description, 2) && !$comerr && $com(%com2).result) {
      bError 1 build.js ended in error: $v1
    }
    bError 1 build.js ended in error (unknown reason)
  }
  bEcho -s BUILD build.js ran


  bEcho -i BUILD Retrieving build.js result
  if ($com(%com).result !== ok) {
    bError 1 $v1
  }
  bEcho -s DONE Build successful


  :error
  %Error = $iif($error && !%Error, $error, %Error)
  reseterror
  if (%close) {
    if ($com(%com2)) .comclose $v1
    if ($com(%com)) .comclose $v1
  }
  if (%Error) {
    bError $iif(%close, 1, 0) %Error
  }
}
