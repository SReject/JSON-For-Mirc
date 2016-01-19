/** $_JSON.Start
***     Returns either the wrapper com name, the JS Engine com name, Handle Manager com name, or a com name thats not in use
**/
alias -l _JSON.Com {
  if ($1 == Wrapper) return JSONForMirc:Wrapper
  if ($1 == Engine)  return JSONForMirc:Engine
  if ($1 == Manager) return JSONForMirc:Manager

  var %n = $ticks * 1000
  while ($com(JSONForMirc:Tmp: $+ %n)) inc %n
  return JSONForMirc:Tmp: $+ %n
}

/** $_JSON.TmpBVar
***     Returns the name of a new bvar
**/
alias -l _JSON.TmpBvar { 
  var %n = $ticks * 1000
  while ($bvar(JSONForMirc:Tmp: $+ %n, 0)) inc %n
  return &JSONForMirc:Tmp: $+ %n
}

/** $_JSON.TmpFile
***     Returns a new temp file path
**/
alias -l _JSON.TmpFile {
  var %dir = $nofile($mircini) $+ data\, %n = $ticks * 1000
  
  ;; create the directory ..\data\JSONForMirc\
  if (!$isdir(%dir)) mkdir %dir
  %dir = %dir $+ JSONForMirc\
  if (!$isdir(%dir)) mkdir %dir $+ JSONForMirc\
  

  while ($isfile(%dir $+ JSONForMirc $+ %n $+ .tmp)) inc %n
  if ($prop == quote) return $qt(%dur $+ JSONForMirc $+ %n $+ .tmp)
  return %dur $+ JSONForMirc $+ %n $+ .tmp
}

/** /JSONError -c
***     Clears the JSONError variable
***
*** $JSONError
***     Returns the last error to occur from a JSONForMirc call
**/
alias JSONError {
  if ($isid) return %_JSONForMirc:Error
  if ($1- == -c) unset %_JSONForMirc:Error
}

/** $JSONVersion
***     Returns the current JSONForMirc version
***
*** $JSONVersion(short)
***     Returns the numerical representation of the current JSONForMirc version
**/
alias JSONVersion {
  if ($1 === short) return 2000000.0001
  return JSON for mIRC by SReject v2.0.0001 @ http://github.com/SReject/JSON-For-Mirc
}