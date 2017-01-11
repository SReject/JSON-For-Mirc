alias JSONTest {
  var %x = 1, %fail, %debug = $JSONDebug
  JSONShutDown
  if (%debug) {
    JSONDebug on
    window -n @SReject/JSONForMirc/log
  }
  while ($isalias(jfm_test $+ %x)) {
    tokenize 32 $jfm_test [ $+ [ %x ] ]
    if (!$1) {
      %fail = $true
      echo 04 -si6 [# $+ $base(%x,10,10,2) $+ ] $2-
      break
    }
    echo 03 -si6 [# $+ $base(%x,10,10,2) $+ ] $2-
    inc %x
  }
  JSONClose -w *
  if (!%fail) {
    echo 12 -s All tests passed
  }
}
alias -l jfm_test1 {
  JSONOpen
  if ($JSONError !== PARAMETER_MISSING) return $false /JSONOpen
  return $true /JSONOpen
}
alias -l jfm_test2 {
  JSONOpen -q jfm_test2 "a"
  if (SWITCH_INVALID:* !iswm $JSONError) return $false /JSONOpen -q jfm_test2 "a"
  return $true /JSONOpen -q jfm_test2 "a"
}
alias -l jfm_test3 {
  JSONOpen -bf jfm_test3 "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return $false /JSONOpen -bf jfm_test3 "a"
  return $true /JSONOpen -bf jfm_test3 "a"
}
alias -l jfm_test4 {
  JSONOpen -bu jfm_test4 "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return $false /JSONOpen -bu jfm_test4 "a"
  return $true /JSONOpen -bu jfm_test4 "a"
}
alias -l jfm_test5 {
  JSONOpen -bU jfm_test5 "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return $false /JSONOpen -bU jfm_test5 "a"
  return $true /JSONOpen -bU jfm_test5 "a"
}
alias -l jfm_test6 {
  JSONOpen -fu jfm_test6 "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return $false /JSONOpen -fu jfm_test6 "a"
  return $true /JSONOpen -fu jfm_test6 "a"
}
alias -l jfm_test7 {
  JSONOpen -fU jfm_test7 "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return $false /JSONOpen -fU jfm_test7 "a"
  return $true /JSONOpen -fU jfm_test7 "a"
}
alias -l jfm_test8 {
  JSONOpen -uU jfm_test8 "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return $false /JSONOpen -uU jfm_test8 "a"
  return $true /JSONOpen -uU jfm_test8 "a"
}
alias -l jfm_test9 {
  JSONOpen -w jfm_test1h "a"
  if (SWITCH_NOT_APPLICABLE:* !iswm $JSONError) return $false /JSONOpen -w /jfm_test9 "a"
  return $true /JSONOpen -w jfm_test9 "a"
}
alias -l jfm_test10 {
  JSONOpen -b jfm_test10
  if (PARAMETER_MISSING !== $JSONError) return $false /JSONOpen -b jfm_test10
  return $true /JSONOpen -b jfm_test10
}
alias -l jfm_test11 {
  JSONOpen -b jfm_test11 jfm_test11
  if (PARAMETER_INVALID:NOT_BVAR !== $JSONError) return $false /JSONOpen -b jfm_test11 jfm_test11
  return $true /JSONOpen -b jfm_test11 jfm_test11
}
alias -l jfm_test12 {
  JSONOpen -b jfm_test12 &jfm_test12 b
  if (PARAMETER_INVALID:BVAR !== $JSONError) return $false /JSONOpen -b jfm_test12 &jfm_test12 b
  return $true /JSONOpen -b jfm_test12 &jfm_test12 b
}
alias -l jfm_test13 {
  JSONOpen -b jfm_test13 &jfm_test13
  if (PARAMETER_INVALID:BVAR_EMPTY !== $JSONError) return $false /JSONOpen -b jfm_test13 &jfm_test13
  return $true /JSONOpen -b jfm_test13 &jfm_test13
}
alias -l jfm_test14 {
  JSONOpen -f jfm_test14
  if (PARAMETER_MISSING !== $JSONError) return $false /JSONOpen -f jfm_test14
  return $true /JSONOpen -f jfm_test14
}
alias -l jfm_test15 {
  JSONOpen -f jfm_test15 jfm_test15
  if (PARAMETER_INVALID:FILE_DOESNOT_EXIST !== $JSONError) return $false /JSONOpen -f jfm_test15 jfm_test15
  return $true /JSONOpen -f jfm_test15 jfm_test15
}
alias -l jfm_test16 {
  JSONOpen -u jfm_test16
  if (PARAMETER_MISSING !== $JSONError) return $false /JSONOpen -u jfm_test16
  return $true /JSONOpen -u jfm_test16
}
alias -l jfm_test17 {
  JSONOpen -u jfm_test17 jfm test17
  if (PARAMETER_INVALID:URL_SPACES !== $JSONError) return $false /JSONOpen -u jfm_test17 jfm test17
  return $true /JSONOpen -u jfm_test17 jfm test17
}
alias -l jfm_test18 {
  JSONOpen jfm_test18 test18
  if ($JSONError !== INVALID_JSON) return $false /JSONOpen jfm_test18 test18
  return $true /JSONOpen jfm_test18 test18
}
alias -l jfm_test19 {
  JSONOpen -d jfm_test19 null
  if ($JSONError) return $false /JSONOpen -d jfm_test19 null
  return $true /JSONOpen -d jfm_test19 null
}
alias -l jfm_test20 {
  JSONOpen -d jfm_test20 true
  if ($JSONError) return $false /JSONOpen -d jfm_test20 true
  return $true /JSONOpen -d jfm_test20 true
}
alias -l jfm_test21 {
  JSONOpen -d jfm_test21 false
  if ($JSONError) return $false /JSONOpen -d jfm_test21 false
  return $true /JSONOpen -d jfm_test21 false
}
alias -l jfm_test22 {
  JSONOpen -d jfm_test22 1
  if ($JSONError) return $false /JSONOpen -d jfm_test22 1
  return $true /JSONOpen -d jfm_test22 1
}
alias -l jfm_test23 {
  JSONOpen -d jfm_test23 1.1
  if ($JSONError) return $false /JSONOpen -d jfm_test23 1.1
  return $true /JSONOpen -d jfm_test23 1.1
}
alias -l jfm_test24 {
  JSONOpen -d jfm_test24 -1
  if ($JSONError) return $false /JSONOpen -d jfm_test24 -1
  return $true /JSONOpen -d jfm_test24 -1
}
alias -l jfm_test25 {
  JSONOpen -d jfm_test25 -1.1
  if ($JSONError) return $false /JSONOpen -d jfm_test25 -1.1
  return $true /JSONOpen -d jfm_test25 -1.1
}
alias -l jfm_test26 {
  JSONOpen -d jfm_test26 ""
  if ($JSONError) return $false /JSONOpen -d jfm_test26 ""
  return $true /JSONOpen -d jfm_test26 ""
}
alias -l jfm_test27 {
  JSONOpen -d jfm_test27 "jfm_test27"
  if ($JSONError) return $false /JSONOpen -d jfm_test27 "jfm_test27"
  return $true /JSONOpen -d jfm_test27 "jfm_test27"
}
alias -l jfm_test28 {
  JSONOpen -d jfm_test28 []
  if ($JSONError) return $false /JSONOpen -d jfm_test28 []
  return $true /JSONOpen -d jfm_test28 []
}
alias -l jfm_test29 {
  JSONOpen -d jfm_test29 [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test29"]
  if ($JSONError) return $false /JSONOpen -d jfm_test29 [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test29"]
  return $true /JSONOpen -d jfm_test29 [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test29"]
}
alias -l jfm_test30 {
  JSONOpen -d jfm_test30 {}
  if ($JSONError) return $false /JSONOpen -d jfm_test30 {}
  return $true /JSONOpen -d jfm_test30 {}
}
alias -l jfm_test31 {
  JSONOpen -d jfm_test31 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test31"}
  if ($JSONError) return $false /JSONOpen -d jfm_test31 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test31"}
  return $true /JSONOpen -d jfm_test31 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test31"}
}
alias -l jfm_test32 {
  JSONOpen -d jfm_test32 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test32", "array":["jfm_test32"], "object":{"key": "jfm_test32"}}
  if ($JSONError) return $false /JSONOpen -d jfm_test32 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test32", "array":["jfm_test32"], "object":{"key": "jfm_test32"}}
  return $true /JSONOpen -d jfm_test32 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test32", "array":["jfm_test32"], "object":{"key": "jfm_test32"}}
}
alias -l jfm_test33 {
  bunset &jfm_test
  bset -t &jfm_test 1 "jfm_test"
  JSONOpen -bd jfm_test74 &jfm_test
  if ($JSONError) return $false /JSONOpen -bd jfm_test74 &jfm_test
  return $true /JSONOpen -bd jfm_test74 &jfm_test
}
alias -l jfm_test34 {
  var %file = $scriptdirjfm_test75.json
  write $qt(%file) "jfm_test"
  JSONOpen -fd jfm_test75 %file
  .remove $qt(%file)
  if ($JSONError) return $false /JSONOpen -fd jfm_test75 %file -> $v1
  return $true /JSONOpen -fd jfm_test75 %file
}




alias -l jfm_test35 {
  noop $JSON
  if (MISSING_PARAMETERS !== $JSONError) return $false $!JSON
  return $true $!JSON
}
alias -l jfm_test36 {
  noop $JSON()
  if (MISSING_PARAMETERS !== $JSONError) return $false $!JSON()
  return $true $!JSON()
}
alias -l jfm_test37 {
  noop $JSON(0, jfm_test35)
  if (INVALID_NAME !== $JSONError) return $false $!JSON(0, jfm_test35)
  return $true $!JSON(0, jfm_test35)
}
alias -l jfm_test38 {
  noop $JSON(0).jfm_test36
  if (PROP_NOT_APPLICABLE !== $JSONError) return $false $!JSON(0).jfm_test36
  return $true $!JSON(0).jfm_test36
}
alias -l jfm_test39 {
  var %jfm_test37 = $JSON(0)
  if ($JSONError) return $false $!JSON(0) $+([,$v1,])
  if (%jfm_test37 !isnum) return $false $!JSON(0) $+([,no-numerical,])
  return $true $!JSON(0)
}
alias -l jfm_test40 {
  noop $JSON(jfm_test38)
  if (HANDLER_NOT_FOUND !== $JSONError) return $false $!JSON(jfm_test38)
  return $true $!JSON(jfm_test38)
}
alias -l jfm_test41 {
  JSONOpen -d jfm_testprops {"key":"value"}
  if ($JSONError) return $false /JSONOpen -d jfm_testprops {"key":"value"}
  return $true /JSONOpen -d jfm_testprops {"key":"value"}
}
alias -l jfm_test42 {
  if (done !== $JSON(jfm_testprops).State) return $false $!JSON(jfm_testprops).State == $v2
  return $true $!JSON(jfm_testprops).State
}
alias -l jfm_test43 {
  if (text !== $JSON(jfm_testprops).InputType) return $false $!JSON(jfm_testprops).InputType == $v2
  return $true $!JSON(jfm_testprops).InputType
}
alias -l jfm_test44 {
  if ({"key":"value"} !== $JSON(jfm_testprops).Input) return $false $!JSON(jfm_testprops).Input == $v2
  return $true $!JSON(jfm_testprops).Input
}
alias -l jfm_test45 {
  if ($false !== $JSON(jfm_testprops).IsChild) return $false $!JSON(jfm_testprops).IsChild == $v2
  return $true $!JSON(jfm_testprops).IsChild
}
alias -l jfm_test46 {
  if ($null !== $JSON(jfm_testprops).Error) return $false $!JSON(jfm_testprops).Error == $v2
  return $true $!JSON(jfm_testprops).Error
}
alias -l jfm_test47 {
  if ($null !== $JSON(jfm_testprops).Path) return $false $!JSON(jfm_testprops).Path == $v2
  return $true $!JSON(jfm_testprops).Path
}
alias -l jfm_test48 {
  if (object !== $JSON(jfm_testprops).Type) return $false $!JSON(jfm_testprops).Type == $v2
  return $true $!JSON(jfm_testprops).Type
}
alias -l jfm_test49 {
  if ($true !== $JSON(jfm_testprops).IsContainer) return $false $!JSON(jfm_testprops).IsContainer == $v2
  return $true $!JSON(jfm_testprops).IsContainer
}
alias -l jfm_test50 {
  if (1 !== $JSON(jfm_testprops).Length) return $false $!JSON(jfm_testprops).Length == $v2
  return $true $!JSON(jfm_testprops).Length
}
alias -l jfm_test51 {
  if ({"key":"value"} !== $JSON(jfm_testprops).String) return $false $!JSON(jfm_testprops).String == $v2
  return $true $!JSON(jfm_testprops).String
}
alias -l jfm_test52 {
  var %debug = {"state":"done","input":"{\"key\":\"value\"}","type":"text","error":false,"parse":true,"http":{"url":"","method":"GET","headers":[],"data":null},"isChild":false,"json":{"path":[],"value":{"key":"value"}}}
  if (%debug !== $JSON(jfm_testprops).Debug) return $false $!JSON(jfm_testprops).Debug == $v2
  return $true $!JSON(jfm_testprops).Debug
}
alias -l jfm_test53 {
  var %input = {"null":null,"true":true,"false":false,"int":1,"dec":1.1,"negint":-1,"negdec":-1.1,"string":"jfm_testvalues","array":["item0","item1","item2"],"object":{"key0":"item0","key1":"item1","key2":"item2"}}
  JSONOpen -d jfm_testvalues %input
  if ($JSONError) return $false /JSONOpen -d jfm_testvalues %input
  return $true /JSONOpen -d jfm_testvalues %input
}
alias -l jfm_test54 {
  var %res = $JSON(jfm_testvalues, true)
  if ($JSONError) return $false $!JSON(jfm_testvalues, true) $+([,$v1,])
  if (JSON:jfm_testvalues:?* !iswm %res) return $false $!JSON(jfm_testvalues, true) == $v2
  return $true $!JSON(jfm_testvalues, true)
}
alias -l jfm_test55 {
  var %res = $JSON(jfm_testvalues, null).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, null).value $+([,$v1,])
  if ($null !== %res) return $false $!JSON(jfm_testvalues, null).value == $v2
  return $true $!JSON(jfm_testvalues, null).value
}
alias -l jfm_test56 {
  var %res = $JSON(jfm_testvalues, true).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, true).value $+([,$v1,])
  if ($true !== %res) return $false $!JSON(jfm_testvalues, true).value == $v2
  return $true $!JSON(jfm_testvalues, true).value
}
alias -l jfm_test57 {
  var %res = $JSON(jfm_testvalues, false).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, false).value $+([,$v1,])
  if ($false !== %res) return $false $!JSON(jfm_testvalues, false).value == $v2
  return $true $!JSON(jfm_testvalues, false).value
}
alias -l jfm_test58 {
  var %res = $JSON(jfm_testvalues, int).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, int).value $+([,$v1,])
  if (1 !== %res) return $false $!JSON(jfm_testvalues, int).value == $v2
  return $true $!JSON(jfm_testvalues, int).value
}
alias -l jfm_test59 {
  var %res = $JSON(jfm_testvalues, dec).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, dec).value $+([,$v1,])
  if (1.1 !== %res) return $false $!JSON(jfm_testvalues, dec).value == $v2
  return $true $!JSON(jfm_testvalues, dec).value
}
alias -l jfm_test60 {
  var %res = $JSON(jfm_testvalues, negint).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, negint).value $+([,$v1,])
  if (-1 !== %res) return $false $!JSON(jfm_testvalues, negint).value == $v2
  return $true $!JSON(jfm_testvalues, negint).value
}
alias -l jfm_test61 {
  var %res = $JSON(jfm_testvalues, negdec).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, negdec).value $+([,$v1,])
  if (-1.1 !== %res) return $false $!JSON(jfm_testvalues, negdec).value == $v2
  return $true $!JSON(jfm_testvalues, negdec).value
}
alias -l jfm_test62 {
  var %res = $JSON(jfm_testvalues, string).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, string).value $+([,$v1,])
  if (jfm_testvalues !== %res) return $false $!JSON(jfm_testvalues, string).value == $v2
  return $true $!JSON(jfm_testvalues, string).value
}
alias -l jfm_test63 {
  var %res = $JSON(jfm_testvalues, string).length
  if ($JSONError) return $false $!JSON(jfm_testvalues, string).length $+([,$v1,])
  if (14 !== %res) return $false $!JSON(jfm_testvalues, string).length == $v2
  return $true $!JSON(jfm_testvalues, string).length
}
alias -l jfm_test64 {
  var %res = $JSON(jfm_testvalues, array).value
  if ($null !== %res) return $false $!JSON(jfm_testvalues, array).value == $v1
  if (INVALID_TYPE !== $JSONError) return $false $!JSON(jfm_testvalues, array).value $+([,$v2,])
  return $true $!JSON(jfm_testvalues, array).value
}
alias -l jfm_test65 {
  var %res = $JSON(jfm_testvalues, array).length
  if ($JSONError) return $false $!JSON(jfm_testvalues, array).length $+([,$v1,])
  if (3 !== %res) return $false $!JSON(jfm_testvalues, array).length == $v2
  return $true $!JSON(jfm_testvalues, array).length
}
alias -l jfm_test66 {
  var %res = $JSON(jfm_testvalues, array, 0).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, array, 0).value $+([,$v1,])
  if (item0 !== %res) return $false $!JSON(jfm_testvalues, array, 0).value == $v2
  return $true $!JSON(jfm_testvalues, array, 0).value
}
alias -l jfm_test67 {
  var %res = $JSON(jfm_testvalues, array, 1).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, array, 1).value $+([,$v1,])
  if (item1 !== %res) return $false $!JSON(jfm_testvalues, array, 1).value == $v2
  return $true $!JSON(jfm_testvalues, array, 1).value
}
alias -l jfm_test68 {
  var %res = $JSON(jfm_testvalues, array, 2).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, array, 2).value $+([,$v1,])
  if (item2 !== %res) return $false $!JSON(jfm_testvalues, array, 2).value == $v2
  return $true $!JSON(jfm_testvalues, array, 2).value
}
alias -l jfm_test69 {
  var %res = $JSON(jfm_testvalues, object).value
  if ($null !== %res) return $false $!JSON(jfm_testvalues, object).value == $v1
  if (INVALID_TYPE !== $JSONError) return $false $!JSON(jfm_testvalues, object).value $+([,$v2,])
  return $true $!JSON(jfm_testvalues, object).value
}
alias -l jfm_test70 {
  var %res = $JSON(jfm_testvalues, object).length
  if ($JSONError) return $false $!JSON(jfm_testvalues, object).length $+([,$v1,])
  if (3 !== %res) return $false $!JSON(jfm_testvalues, object).length == $v2
  return $true $!JSON(jfm_testvalues, object).length
}
alias -l jfm_test71 {
  var %res = $JSON(jfm_testvalues, object, key0).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, object, key0).value $+([,$v1,])
  if (item0 !== %res) return $false $!JSON(jfm_testvalues, object, key0).value == $v2
  return $true $!JSON(jfm_testvalues, object, key0).value
}
alias -l jfm_test72 {
  var %res = $JSON(jfm_testvalues, object, key1).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, object, key1).value $+([,$v1,])
  if (item1 !== %res) return $false $!JSON(jfm_testvalues, object, key1).value == $v2
  return $true $!JSON(jfm_testvalues, object, key1).value
}
alias -l jfm_test73 {
  var %res = $JSON(jfm_testvalues, object, key2).value
  if ($JSONError) return $false $!JSON(jfm_testvalues, object, key2).value $+([,$v1,])
  if (item2 !== %res) return $false $!JSON(jfm_testvalues, object, key2).value == $v2
  return $true $!JSON(jfm_testvalues, object, key2).value
}
alias -l jfm_test74 {
  var %res = $JSON(jfm_testvalues, ~ TRUE).fuzzyValue
  if ($JSONError) return $false $!JSON(jfm_testvalues, ~ TRUE).fuzzyValue $+([,$v1,])
  if ($true !== %res) return $false $!JSON(jfm_testvalues, ~ TRUE).fuzzyValue == $v2
  return $true $!JSON(jfm_testvalues, ~ TRUE).fuzzyValue
}
alias -l jfm_test75 {
  var %res = $JSON(jfm_testvalues, ~ 1).fuzzyValue
  if ($JSONError) return $false $!JSON(jfm_testvalues, ~ 1).fuzzyValue $+([,$v1,])
  if ($true !== %res) return $false $!JSON(jfm_testvalues, ~ 1).fuzzyValue == $v2
  return $true $!JSON(jfm_testvalues, ~ 1).fuzzyValue
}
alias -l jfm_test76 {
  set -u0 %_jfm_test76_forEachTest $false
  var %res = $JSONForEach($JSON(jfm_testvalues, array), _jfm_test76_forEachTest)
  if ($JSONError) return $false $!JSONForEach($JSON(jfm_testvalues, array), _jfm_test76_forEachTest)
  if (%_jfm_test76_forEachTest) return $false $v1
  if (3 !== %res) return $false $!JSONForEach($JSON(jfm_testvalues, array), _jfm_test76_forEachTest) == $v2
  unset %_jfm_test76_forEachTest
  return $true $!JSONForEach($JSON(jfm_testvalues, array), _jfm_test76_forEachTest)
}
alias _jfm_test76_forEachTest {
  if (!%_jfm_test76_forEachTest) {
    if ($0 !== 1) {
      set -u0 %_jfm_test76_forEachTest INVALID_PARAMETERS
    }
    elseif (!$com($1)) {
      set -u0 %_jfm_test76_forEachTest COM_DOESNOT_EXIST
    }
    else {
      var %res = $JSON($1).value
      if ($jsonerror) {
        set -u0 %_jfm_test76_forEachTest $v1
      }
      elseif (item* !iswm %Res) {
        set -u0 %_jfm_test76_forEachTest $!JSON( $+ $1 $+ ).value == %Res
      }
    }
  }
}

;; TODO: HTTP request validation