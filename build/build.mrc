alias -l jsEsc return $replace($1-, \, \\, ", \")

alias JSONForMircBuild {
  if ($lock(com)) { 
    $bEcho(Error, Unable to continue due an COM lock into the mIRC Options).error
    return
  }
  var %close = $false, %dir   = $gettok($scriptdir, 1--2, $asc(\)) $+ \, %src   = %dir $+ src\, %out   = %dir $+ builds\, %error, %bvar  = 1, %com   = JSONForMircBuild, %com2  = JSONForMircBuildResult
  $bEcho(Init, Setting build resource location to: $scriptdir).info
  $bEcho(Init, Setting source directory to: %src).info
  $bEcho(Init, Setting output directory to: %out).info
  while ($bvar(& $+ buildjs $+ %bvar, 0)) inc %bvar
  %bvar = &buildjs $+ %bvar
  $bEcho(Init, Setting build.js bvar to %bvar).info
  $bEcho(Init, Looking for build.js)
  if (!$isfile($scriptdirbuild.js)) {
    %Error = build.js not found
  }
  else {
    $bEcho(init, build.js located).ok
    $bEcho(init, Looking for build.json)
    if (!$isfile($scriptdirbuild.json)) {
      %Error = build.json not found
    }
    else {
      $bEcho(Init, build.json located).ok
      $bEcho(Setup, Reading contents of build.js).info
      %Error = Unable to read the contents of build.js
      bread $qt($scriptdirbuild.js) 0 $file($scriptdirbuild.js).size %bvar
      %Error = $null
      if (!$bvar(%bvar, 0)) {
        %Error = No data read from build.js
      }
      else {
        $bEcho(Setup, Successfully read the contents of build.js).ok
        $bEcho(Setup, Supplying parameters to build.js).info
        if ($bfind(%bvar, 1, __PARAMETERS__) < 1) {
          %Error = Unable to locate parameter placement in build.js
        }
        else {
          bcopy -c %bvar 1 %bvar 1 $calc($v1 - 1)
          bset -t %bvar $calc($bvar(%bvar, 0) +1) $qt($jsEsc($scriptdirbuild.json)) , $qt($jsEsc(%src)) , $qt($jsEsc(%out)) ));
          %close = $true
          if ($com(%com)) .comclose $v1
          if ($com(%com2)) .comclose $v1
          $bEcho(Start, Creating MSScriptControl.ScriptControl instance).info
          .comopen %com MSScriptControl.ScriptControl
          if (!$com(%com) || $comerr) {
            %Error = Unable to create MSScriptControl.ScriptControl instance
          }
          else {
            $bEcho(Start, MSScriptControl.ScriptControl instance created).ok

            $bEcho(Start, Setting language to JScript).info
            if (!$com(%com, language, 4, bstr, jscript) || $comerr) {
              %Error = Unable to set language
            }
            else {
              $bEcho(Start, Language set to JScript).ok
              $bEcho(Start, Running build.js)
              if (!$com(%com, ExecuteStatement, 1, &bstr, %bvar) || $comerr) {
                %Error = Unable to run build.js
              }
              else {
                $bEcho(Finalizing, Retrieving reference to result variable).info

                if (!$com(%com, Eval, 3, bstr, result, dispatch* %com2) || $comerr) {
                  %Error = Unable to access build result variable
                }
                elseif (!$com(%com2)) {
                  %Error = Reference to result variable not created
                }
                else {
                  $bEcho(Finalizing, Reference to result variable created).ok
                  $bEcho(Finalizing, Retrieving error status from result variable).info
                  if (!$com(%com2, error, 2) || $comerr) {
                    %Error = Unable to retrieve error status
                  }
                  elseif ($com(%com2).result) {
                    %Error = $v1
                  }
                  else {
                    $bEcho(Finalizing, Retrieving result response from result variable).info
                    if (!$com(%com2, result, 2) || $comerr) {
                      %Error = Unable to retrieve result response from result variable
                    }
                    elseif ($com(%com2).result) {
                      $bEcho(DONE, Build Successful: $v1).done
                    }
                    else {
                      $bEcho(DONE, Build Successful).done
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  :error
  %Error = $iif($error && !%Error, $error, %Error)
  reseterror
  if (%close) {
    if ($com(%com)) .comclose $v1
    if ($com(%com2)) .comclose $v1
  }
  if (%Error) {
    $bEcho(Error, %Error).error
  }
}

alias -l bEcho {
  var %c = 12
  if ($prop == error) {
    %c = 04
  }
  if ($prop == warn) {
    %c = 07
  }
  if ($prop == ok) {
    %c = 03
  }
  if ($prop == done) {
    %c = 13
  }
  echo -a $+(,%c,[JSONForMirc Build: $1,,%c,]) $2-
}
