alias JSONTest {
  var %x = 1, %Res
  while ($isalias(jfm_test $+ %x)) {
    %res = $jfm_test [ $+ [ %x ] ]
    if (%res) {
      echo 04 [JFM Test $chr(35) $+ %x $+ ] Failed: %res
      break
    }
    echo 03 [JFM Test $chr(35) $+ %x $+ ] Passed: %jfm_test.title
    inc %x
  }
  if (!%res) {
    echo 12 [JFM Test] All tests passed
  }
}

alias -l jfm_test1 {
  set -u0 %jfm_test.title /JSONOpen input validation
  jsonopen
  if ($JSONError !== PARAMETER_MISSING) return No parameters check
  jsonopen -q jfm_test1a "a"
  if (SWITCH_INVALID:* !iswm $JSONError) return bad switch
  jsonopen -bf jfm_test1b "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return Conflicting switches: b, f
  jsonopen -bu jfm_test1c "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return Conflicting switches: b, u
  jsonopen -bU jfm_test1d "a" 
  if (SWITCH_CONFLICT:* !iswm $JSONError) return Conflicting switches: b, U
  jsonopen -fu jfm_test1e "a"
  if (SWITCH_CONFLICT:* !iswm $JSONError) return Conflicting switches: f, u
  jsonopen -fU jfm_test1f "a" 
  if (SWITCH_CONFLICT:* !iswm $JSONError) return Conflicting switches:f, U
  jsonopen -uU jfm_test1g "a" 
  if (SWITCH_CONFLICT:* !iswm $JSONError) return Conflicting switches: u, U
  jsonopen -w jfm_test1h "a"
  if (SWITCH_NOT_APPLICABLE:* !iswm $JSONError) return -w without -u
  jsonopen -b jfm_test1i
  if (PARAMETER_MISSING !== $JSONError) return -b without a bvar specified
  jsonopen -b jfm_test1j jfm_test1j
  if (PARAMETER_INVALID:NOT_BVAR !== $JSONError) return -b with invalid bvar
  jsonopen -b jfm_test1k &jfm_test1k b
  if (PARAMETER_INVALID:BVAR !== $JSONError) return -b switch space in bvar name
  jsonopen -b jfm_test1l &jfm_test1l
  if (PARAMETER_INVALID:BVAR_EMPTY !== $JSONError) return -b with empty/non-existant bvar
  jsonopen -f jfm_test1m
  if (PARAMETER_MISSING !== $JSONError) return -f without file
  jsonopen -f jfm_test1n jfm_test1n
  if (PARAMETER_INVALID:FILE_DOESNOT_EXIST !== $JSONError) return -f with file that doesn't exist
  jsonopen -u jfm_test1o
  if (PARAMETER_MISSING !== $JSONError) return -u without a url
  jsonopen -u jfm_test1p jfm test1p
  if (PARAMETER_INVALID:URL_SPACES !== $JSONError) return -u with url containing spaces
}
alias -l jfm_test2 {
  set -u0 %jfm_test.title /JSONOpen parsing text inputs
  JSONOpen jfm_test2a test2a
  if ($JSONError !== INVALID_JSON) return Did not indicate invalid json
  JSONOpen -d jfm_test2b null
  if ($JSONError) return Parsing 'null'
  JSONOpen -d jfm_test2c true
  if ($JSONError) return Parsing 'true'
  JSONOpen -d jfm_test2d false
  if ($JSONError) return Parsing 'false'
  JSONOpen -d jfm_test2e 1
  if ($JSONError) return Parsing '1'
  JSONOpen -d jfm_test2f 1.1
  if ($JSONError) return Parsing '1.1'
  JSONOpen -d jfm_test2g -1
  if ($JSONError) return Parsing '-1'
  JSONOpen -d jfm_test2h -1.1
  if ($JSONError) return Parsing '1.1'
  JSONOpen -d jfm_test2i ""
  if ($JSONError) return Parsing empty string
  JSONOpen -d jfm_test2j "jfm_test2j"
  if ($JSONError) return Parsing '"jfm_test2j"'
  JSONOpen -d jfm_test2k []
  if ($JSONError) return Parsing empty array
  JSONOpen -d jfm_test2l [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test2l"]
  if ($JSONError) return Parsing filled array
  JSONOpen -d jfm_test2m {}
  if ($JSONError) return Parsing empty object
  JSONOpen -d jfm_test2n {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test2n"}
  if ($JSONError) return Parsing filled object
  JSONOpen -d jfm_test2o {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test2n", "array":[["jfm_test2o"]]}
  if ($JSONError) return Parsing nested containers
}
alias -l jfm_test3 {
  set -u0 %jfm_test.title /JSONOpen parsing bvar input
  ;; todo
}
alias -l jfm_test4 {
  set -u0 %jfm_test.title /JSONOpen parsing file input
  ;; todo
}
alias -l jfm_test5 {
  set -u0 %jfm_test.title /JSONOpen parsing url input
  ;; todo
}

alias -l jfm_test6 {
  set -u0 %jfm_test.title $!JSON() processing

  noop $JSON
  if (MISSING_PARAMETERS !== $JSONError) return No parameters specified (#1)

  noop $JSON()
  if (MISSING_PARAMETERS !== $JSONError) return No parameters specified (#2)

  noop $json(0, jfm_test6c)
  if (INVALID_NAME !== $JSONError) return No error for $!JSON(0, members...)

  noop $JSON(0).prop
  if (PROP_NOT_APPLICABLE !== $JSONError) return No error for $!JSON(0).prop

  noop $JSON(jfm_test6e)
  if (HANDLER_NOT_FOUND !== $JSONError) return Unopened handler

  var %jfm_test6f = $JSON(0)
  if ($JSONError) return $v1
  if (%jfm_test6f !isnum) return $!JSON(0) Returned non-numerical value

  JSONOpen -d jfm_test6 {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test2n", "array":["jfm_test2o"], "object":{"key": "value"}}
  if ($JSON(jfm_test6).State !== done) return $!JSON(jfm_test6).State returned incorrectly: $v1
  if ($JSON(jfm_test6).InputType !== text) return $!JSON(jfm_test6).InputType returned incorrectly: $v1
  if ($JSON(jfm_test6).IsChild !== $false) return $!JSON(jfm_test6).IsChild returned incorrectly: $v1
  if ($JSON(jfm_test6).Error !== $Null) return $!JSON(jfm_test6).Error returned incorrectly: $v1
  if ($JSON(jfm_test6).Path !== $null) return $!JSON(jfm_test6).Path returned incorrectly: $v1
  if ($JSON(jfm_test6).Type !== object) return $!JSON(jfm_test6).Type returned incorrectly: $v1
  if ($JSON(jfm_test6).IsContainer !== $true) return $!JSON(jfm_test6).IsContainer returned incorrectly: $v1
  if ($JSON(jfm_test6).Length !== 7) return $!JSON(jfm_test6).Length returned incorrectly: $v1

  if ($JSON(jfm_test6).value !== $Null) return $!JSON().value should not return a value if the reference is a container
  if ($JSONError !== INVALID_TYPE) return $!JSON().value should raise an "INVALID_TYPE" error when referencing a container

  if (JSON:jfm_test6:?* !iswm $JSON(jfm_test6, array)) return $!JSON(name, @member) should return a reference: $v2
  if ($JSONError) return $!JSON(name, @member) should create a reference

}
