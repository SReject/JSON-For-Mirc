/** $JSONDebug
***     Returns $true if JSONForMirc debugging is enabled, $false otherwise
***
*** /JSONDebug @Setting
***     Toggles the state of JSONForMirc Debugging
***
***     @Setting - (optional)
***         The setting; valid inputs are:
***
***         on OR enable:
***             Enables JSONForMirc debugging regardless of state
***
***         off OR disable:
***             Disables JSONForMirc debugging regardless of state
***
***         $null:
***             Toggles JSONForMirc debugging
**/
alias JSONDebug {

  ;; If id: return the state ($true if enabled, $false otherwise)
  if ($isid) {
    if ($group(#JSONForMirc:Debug) == on) return $true
    return $false
  }
  
  ;; As command: if $1 is "on" or "enable" then enable debugging
  elseif ($1 == on || $1 == enable) {
    if (!$window(@JSONForMircDebug)) {
      window @JSONForMircDebug
    }
    .enable #JSONForMirc:Debug
  }
  
  ;; As command: if $1 is "off" or "disable" then disable debugging
  elseif ($1 == off || $1 == disable) {
    .disable #JSONForMirc:Debug
  }
  
  ;; As command: if no parameter was specified toggle the debugging state
  elseif (!$0) {
    if ($group(#JSONForMirc:Debug) != on) {
      if (!$window(@JSONForMircDebug)) {
        window @JSONForMircDebug
      }
      .enable #JSONForMirc:Debug
    }
    else {
      .disable #JSONForMirc:Debug
    }
  }
}

;; Use a group so that the log alias is only active when debugging is enabled
#JSONForMirc:Debug on


/*
/_JSON.Log @Type [[@Prefix]~]@Msg
*/
alias -l _JSON.Log {
  if (!$window(@JSONForMircDebug)) {
    JSONDebug off
  }
  else {
    var %color, %prefix, %msg
    if ($1 == Error) {
      %color = 04
    }
    elseif ($1 == Info) {
      %color = 03
    }
    elseif ($1 == Warn) {
      %color = 07
    }
    elseif ($1 == Ok) {
      %color = 12
    }
    
    if (%color) {
      tokenize 32 $2-
    }
    else {
      %color = 03
    }

    if ($1 == ~) {
      %prefix = JSONForMirc
      %msg = $2-
    }
    elseif ($left($1, 1) == ~) {
      %prefix = JSONForMirc
      %msg = $mid($1-, 2-)
    }
    else {
      %prefix = $gettok($1-, 1, 126)
      %msg = $gettok($1-, 2-, 126)
    }
    
    aline @JSONForMircDebug $+($chr(3), %color, [, %prefix ,]) %msg
  }
}
#JSONForMirc:Debug end

;; if debug is disabled, mIRC will fall back to using this alias for logging
alias -l _JSON.Log noop

;; When the debug window closes, disable debugging
on *:CLOSE:@JSONForMircDebug:{
  JSONDebug off
}

;; Debug window menu
;;
;; TO DO: Save menu
menu @JSONForMircDebug {
  .Save: noop
  .-
  .Clear: clear -@ @JSONForMircDebug
  .Disable: JSONDebug off
  .-
  .Close: close -@ @JSONForMircDebug
}