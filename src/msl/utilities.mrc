alias -l _JSON.Com {
  if ($1 == Wrapper) {
    return JSONForMirc:Wrapper
  }
  if ($1 == JSEngine) {
    return JSONForMirc:JSEngine
  }
  if ($1 == tmp) {
    var %x = 1
    while ($com(JSONForMirc:TmpCom $+ %x)) {
      inc %x
    }
    return JSONForMirc:TmpCom $+ %x
  }
}

alias -l _JSON.TmpBvar {
  var %x = 1
  while ($bvar(&JSONForMirc:Tmp $+ %x, 0)) {
    inc %x
  }
  return &JSONForMirc:Tmp $+ %x
}

alias -l _JSON.TmpFile {
  var %x = 1
  while ($isFile($scriptdir\JSONForMirc $+ %x $+  .tmp)) {
    inc %x
  }
  return $scriptdir\JSONForMirc $+ %x $+ .tmp
}

