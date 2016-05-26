alias JSONTest {

  set -u %_JSONForMirc:Tmp:TestIndex 0

  ;; test null values
  ;noop $_JSON.TestOutput1(null, null $false, Null Input)

  ;; test boolean values
  noop $_JSON.TestOutput1(true,  boolean $false $true,  Boolean true Input)
  noop $_JSON.TestOutput1(false, boolean $false $false, Boolean false Input)

  ;; test numeric values
  noop $_JSON.TestOutput1(1,    number $false 1,    Positive Integer Input)
  noop $_JSON.TestOutput1(1.5,  number $false 1.5,  Positive Decimal Input)
  noop $_JSON.TestOutput1(-1,   number $false -1,   Negitive Integer Input)
  noop $_JSON.TestOutput1(-1.5, number $false -1.5, Negetive Decimal Input)

  ;; test string values
  noop $_JSON.TestOutput1("abc", string $false abc, String Input)
  noop $_JSON.TestOutput1("",    string $false,     Empty String Input)


  unset %_JSONForMirc:Tmp:TestIndex
}


alias _JSON.TestOutput1 {
  inc -u %_JSONForMirc:Tmp:TestIndex

  var %failed = $false, %name = test $+ %_JSONForMirc:Tmp:TestIndex, %type = $gettok($2, 1, 32), %isParent = $gettok($2, 2, 32), %value = $gettok($2, 3, 32), %resType, %resIsParent, %resValue

  ;; attempt to open handle
  JSONOpen %name $1
  if ($JSONError) {
    %failed = $v1
  }
  else {
    %resType = $json(%name).type
    if ($JSONError) {
      %failed = $v1
    }
    elseif (%resType !== %type) {
      %failed = Type does not match - Expected: $v2 - Returned: $v1
    }
    else {
      %resIsParent = $json(%name).isParent
      if ($JSONError) {
        %failed = $v1
      }
      elseif (%resIsParent !== %isParent) {
        %failed = isParent does not match - Expected: $v2 - Returned: $v1
      }
      else {
        %resValue = $json(%name).value
        if ($JSONError) {
          %failed = $v1
        }
        elseif (%resValue !== %value) {
          %failed = value does not match - Expected: $v2 - Returned $v1
        }
      }
    }
  }

  ;; close instance
  JSONClose %name

  ;; Cleanup variable, echo out failed message, and halt processing
  if (%failed) {
    unset %_JSONForMirc:Tmp:TestIndex
    echo 04 -s Test $qt($3) Failed: $v1
    halt
  }

  ;; echo out success message
  echo 03 -s Test $qt($3) successful
}
