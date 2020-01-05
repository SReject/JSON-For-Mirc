;; /JSONTest
alias JSONTest {
  _cleanup
  tokenize 32 $jfm_test($1)
  if ($0) {
    echo 04 -sgei6 [# $+ $base($1,10,10,2) $+ ] $2-
  }
  else {
    echo 12 -sgei6 All tests passed
  }
  _cleanup
}


alias -l jfm_test {
  ;; variables that will be needed within testing
  var %jsondata = {"null":null,"true":true,"false":false,"int":1,"dec":1.1,"negint":-1,"negdec":-1.1,"string":"string","array":["item0","item1","item2"],"object":{"key0":"item0","key1":"item1","key2":"item2"}}
  var %debugdata = {"state":"done","input":"{\"null\":null,\"true\":true,\"false\":false,\"int\":1,\"dec\":1.1,\"negint\":-1,\"negdec\":-1.1,\"string\":\"string\",\"array\":[\"item0\",\"item1\",\"item2\"],\"object\":{\"key0\":\"item0\",\"key1\":\"item1\",\"key2\":\"item2\"}}","type":"text","error":false,"parse":true,"http":{"url":"","method":"GET","headers":[]},"isChild":false,"json":{"path":[],"value":{"null":null,"true":true,"false":false,"int":1,"dec":1.1,"negint":-1,"negdec":-1.1,"string":"string","array":["item0","item1","item2"],"object":{"key0":"item0","key1":"item1","key2":"item2"}}}}

  ;; state variables
  var %testnum = 0
  var %err
  var %res
  var %cert_url
  var %cert_re
  var %echo = echo 03 -sgi6 $!+([#,$base(%testNum,10,10,3),])

  jsonshutdown
  jsondebug on
  window -n @SReject/JSONForMirc/Log

  ;;============================;;
  ;;                            ;;
  ;;     $JSONVersion tests     ;;
  ;;                            ;;
  ;;============================;;



  ;; Check $JSONVersion
  :1
  inc %testnum
  %res = $JSONVersion
  if (!$regex(%res, /^(?:SReject\/JSONForMirc v\d{1,4}\.\d{1,4}\.\d{1,4})$/)) {
    return %testnum $!JSONVersion : Returned incorrect value: %res
  }
  $(%echo,2) $!JSONVersion : Passed Check


  ;; Check $JSONVersion(short)
  :2
  inc %testnum
  %res = $JSONVersion(short)
  if (!$regex(%res, /^(?:\d{1,4}\.\d{1,4}\.\d{1,4})$/)) {
    return %testnum $!JSONVersion(short) : Returned incorrect value: %res
  }
  $(%echo,2) $!JSONVersion(short) : Passed Check


  ;;=========================;;
  ;;                         ;;
  ;;     /JSONOPEN tests     ;;
  ;;                         ;;
  ;;=========================;;

  ;; Tests to make sure "/JSONOpen" raises "PARAMETER_MISSING" error
  :3
  inc %testnum
  JSONOpen
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum /JSONOpen : Reported incorrect error: $v1
  }
  $(%echo,2) /JSONOpen : Passed Check: PARAMETER_MISSING


  ;; tests to make sure /JSONOpen raises "SWITCH_INVALID" when an unknown switch is specified
  :4
  inc %testnum
  JSONOpen -q jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -q : Failed to report error (SWITCH_INVALID)
  }
  if (SWITCH_INVALID !iswm %err) {
    return %testnum /JSONOpen -q : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -q : Passed Check: SWITCH_INVALID


  ;; tests to make sure /JSONOpen raises "SWITCH_CONFLICT" when conflicting switches -bf are specified
  :5
  inc %testnum
  JSONOpen -bf jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -bf : Failed to report error (SWITCH_CONFLICT)
  }
  if (SWITCH_CONFLICT:* !iswm %err) {
    return %testnum /JSONOpen -bf : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -bf : Passed Check: SWITCH_CONFLICT


  ;; tests to make sure /JSONOpen raises "SWITCH_CONFLICT" when conflicting switches -bu are specified
  inc %testnum
  JSONOpen -bu jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -bu : Failed to report error (SWITCH_CONFLICT)
  }
  if (SWITCH_CONFLICT:* !iswm %err) {
    return %testnum /JSONOpen -bu : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -bu : Passed Check: SWITCH_CONFLICT


  ;; tests to make sure /JSONOpen raises "SWITCH_CONFLICT" when conflicting switches -bU are specified
  inc %testnum
  JSONOpen -bU jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -bU : Failed to report error (SWITCH_CONFLICT)
  }
  if (SWITCH_CONFLICT:* !iswm %err) {
    return %testnum /JSONOpen -bU : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -bU : Passed Check: SWITCH_CONFLICT


  ;; tests to make sure /JSONOpen raises "SWITCH_CONFLICT" when conflicting switches -fu are specified
  inc %testnum
  JSONOpen -fu jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -fu : Failed to report error (SWITCH_CONFLICT)
  }
  if (SWITCH_CONFLICT:* !iswm %err) {
    return %testnum /JSONOpen -fu : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -fu : Passed Check: SWITCH_CONFLICT


  ;; tests to make sure /JSONOpen raises "SWITCH_CONFLICT" when conflicting switches -fU are specified
  inc %testnum
  JSONOpen -fU jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -fU : Failed to report error (SWITCH_CONFLICT)
  }
  if (SWITCH_CONFLICT:* !iswm %err) {
    return %testnum /JSONOpen -fU : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -fU : Passed Check: SWITCH_CONFLICT


  ;; tests to make sure /JSONOpen raises "SWITCH_CONFLICT" when conflicting switches -uU are specified
  inc %testnum
  JSONOpen -uU jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -uU : Failed to report error (SWITCH_CONFLICT)
  }
  if (SWITCH_CONFLICT:* !iswm %err) {
    return %testnum /JSONOpen -uU : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -uU : Passed Check: SWITCH_CONFLICT


  ;; test to make sure /JSONOpen raises "SWITCH_NOT_APPLICABLE" when -w is specified without -u/-U
  inc %testnum
  JSONOpen -w jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -uU : Failed to report error (SWITCH_NOT_APPLICABLE)
  }
  if (SWITCH_NOT_APPLICABLE:* !iswm %err) {
    return %testnum /JSONOpen -uU : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -w : Passed Check: SWITCH_NOT_APPLICABLE

  ; (slv) Added i switch
  ;; test to make sure /JSONOpen raises "SWITCH_NOT_APPLICABLE" when -i is specified without -u/-U
  inc %testnum
  JSONOpen -i jfm_test "a"
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -uU : Failed to report error (SWITCH_NOT_APPLICABLE)
  }
  if (SWITCH_NOT_APPLICABLE:* !iswm %err) {
    return %testnum /JSONOpen -uU : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -i : Passed Check: SWITCH_NOT_APPLICABLE


  ;; test to make sure /JSONOpen raises "PARAMETER_MISSING" if -b is specified
  inc %testnum
  JSONOpen -b jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -b : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum /JSONOpen -b : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -b : Passed Check: PARAMETER_MISSING


  ;; test to make sure /JSONOpen raises "PARAMETER_INVALID:NOT_BVAR" if -b is specified without a valid bvar
  inc %testnum
  JSONOpen -b jfm_test nope
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -b : Failed to report error (PARAMETER_INVALID:NOT_BVAR)
  }
  if (PARAMETER_INVALID:NOT_BVAR !== %err) {
    return %testnum /JSONOpen -b : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -b : Passed Check: PARAMETER_INVALID:NOT_BVAR


  ;; test to make sure /JSONOpen raises "PARAMETER_INVALID:NOT_BVAR" if -b is specified without a valid bvar
  inc %testnum
  JSONOpen -b jfm_test &jfm_test nope
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -b : Failed to report error (PARAMETER_INVALID:BVAR)
  }
  if (PARAMETER_INVALID:BVAR !== %err) {
    return %testnum /JSONOpen -b : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -b : Passed Check: PARAMETER_INVALID:BVAR


  ;; test to make sure /JSONOpen raises "PARAMETER_INVALID:BVAR_EMPTY" if -b is specified and the bvar is empty or doesn't exist
  inc %testnum
  JSONOpen -b jfm_test &jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -b : Failed to report error (PARAMETER_INVALID:BVAR_EMPTY)
  }
  if (PARAMETER_INVALID:BVAR_EMPTY !== %err) {
    return %testnum /JSONOpen -b : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -b : Passed Check: PARAMETER_INVALID:BVAR_EMPTY


  ;; test to make sure /JSONOpen raises "PARAMETER_MISSING" if -f is specified
  inc %testnum
  JSONOpen -f jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -f : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum /JSONOpen -f : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -f : Passed Check: PARAMETER_MISSING


  ;; test to make sure /JSONOpen raises "PARAMETER_INVALID:FILE_DOESNOT_EXIST" if -f is specified but the file does not exist
  inc %testnum
  JSONOpen -f jfm_test jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -f : Failed to report error (PARAMETER_INVALID:FILE_DOESNOT_EXIST)
  }
  if (PARAMETER_INVALID:FILE_DOESNOT_EXIST !== %err) {
    return %testnum /JSONOpen -f : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -f : Passed Check: PARAMETER_INVALID:FILE_DOESNOT_EXIST


  ;; test to make sure /JSONOpen raises "PARAMETER_MISSING" if -u is specified but no url parameter is specified
  inc %testnum
  JSONOpen -u jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -u : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum /JSONOpen -u : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -u : Passed Check: PARAMETER_MISSING


  ;; test to make sure /JSONOpen raises "PARAMETER_INVALID:URL_SPACES" if -u is specified but the url parameter contains spaces
  inc %testnum
  JSONOpen -u jfm_test jfm test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -u : Failed to report error (PARAMETER_INVALID:URL_SPACES)
  }
  if (PARAMETER_INVALID:URL_SPACES !== %err) {
    return %testnum /JSONOpen -u : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -u : Passed Check: PARAMETER_INVALID:URL_SPACES


  ;; test to make sure /JSONOpen raises "PARAMETER_MISSING" if -u is specified but no url parameter is specified
  inc %testnum
  JSONOpen -U jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -U : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum /JSONOpen -U : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -U : Passed Check: PARAMETER_MISSING


  ;; test to make sure /JSONOpen raises "PARAMETER_INVALID:URL_SPACES" if -U is specified but the url parameter contains spaces
  inc %testnum
  JSONOpen -U jfm_test jfm test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen -U : Failed to report error (PARAMETER_INVALID:URL_SPACES)
  }
  if (PARAMETER_INVALID:URL_SPACES !== %err) {
    return %testnum /JSONOpen -U : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen -U : Passed Check: PARAMETER_INVALID:URL_SPACES


  ;; test to make sure /JSONOpen raises "INVALID_JSON" when applicable
  inc %testnum
  JSONOpen jfm_test jfm_test
  %err = $JSONError
  if (%err == $null) {
    return %testnum /JSONOpen : Failed to report error (INVALID_JSON)
  }
  if (INVALID_JSON !== %err) {
    return %testnum /JSONOpen : Reported incorrect error: $v2
  }
  $(%echo,2) /JSONOpen : Passed Check: INVALID_JSON


  ;; test to make sure /JSONClose closes the json handle
  inc %testnum
  JSONClose jfm_test
  if ($com(JSON:jfm_test)) {
    return %testnum /JSONClose : Failed to close handle
  }
  $(%echo,2) /JSONClose : Passed Check: Close


  ;;=======================;;
  ;;                       ;;
  ;;     Parsing tests     ;;
  ;;                       ;;
  ;;=======================;;

  ;; test to make sure null is properly parsed
  inc %testnum
  JSONOpen jfm_test null
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse null : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: null
  JSONClose jfm_test


  ;; test to make sure true is properly parsed
  inc %testnum
  JSONOpen jfm_test true
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse true : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: true
  JSONClose jfm_test


  ;; test to make sure false is properly parsed
  inc %testnum
  JSONOpen jfm_test false
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse false : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: false
  JSONClose jfm_test


  ;; test to make sure 1 is properly parsed
  inc %testnum
  JSONOpen jfm_test 1
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse 1 : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: 1
  JSONClose jfm_test


  ;; test to make sure 1.1 is properly parsed
  inc %testnum
  JSONOpen jfm_test 1.1
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse 1.1 : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: 1.1
  JSONClose jfm_test


  ;; test to make sure -1 is properly parsed
  inc %testnum
  JSONOpen jfm_test -1
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse -1 : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: -1
  JSONClose jfm_test


  ;; test to make sure -1.1 is properly parsed
  inc %testnum
  JSONOpen jfm_test -1.1
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse -1.1 : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: -1.1
  JSONClose jfm_test


  ;; test to make sure "" is properly parsed
  inc %testnum
  JSONOpen jfm_test ""
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse "" : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: ""
  JSONClose jfm_test


  ;; test to make sure strings is properly parsed
  inc %testnum
  JSONOpen jfm_test "jfm_test"
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse "jfm_test" : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: "jfm_test"
  JSONClose jfm_test


  ;; test to make sure empty arrays is properly parsed
  inc %testnum
  JSONOpen jfm_test []
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse [] : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: []
  JSONClose jfm_test


  ;; test to make sure primitive-filled arrays are properly parsed
  inc %testnum
  JSONOpen jfm_test [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test"]
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test29"] : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: [null, true, false, 1, 1.1, -1, -1.1, "", "jfm_test29"]
  JSONClose jfm_test


  ;; test to make sure empty objects are properly parsed
  inc %testnum
  JSONOpen jfm_test {}
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse {} : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: {}
  JSONClose jfm_test


  ;; test to make sure primitive-filled objects are properly parsed
  inc %testnum
  JSONOpen jfm_test {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test31"}
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test31"} : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: {"null": null, "true": true, "false": false, "number": 1, "string": "jfm_test31"}
  JSONClose jfm_test


  ;; test to make sure complex arrays are properly parsed
  inc %testnum
  JSONOpen jfm_test [{"key":"value"}]
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse [{"key":"value"}] : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: [{"key":"value"}]
  JSONClose jfm_test


  ;; test to make sure complex objects are properly parsed
  inc %testnum
  JSONOpen jfm_test {"key":["value"]}
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse {"key":["value"]} : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: {"key":["value"]}
  JSONClose jfm_test


  ;; test to make sure data from bvars is properly parsed
  inc %testnum
  bunset &jfm_test
  bset -t &jfm_test 1 {"key":["value"]}
  JSONOpen -b jfm_test &jfm_test
  bunset &jfm_test
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse input from bvar : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: input from bvar
  JSONClose jfm_test


  ;; test to make sure data from files is properly parsed
  inc %testnum
  var %file = $scriptdirjfm_test.json
  write $qt(%file) {"key":["value"]}
  JSONOpen -f jfm_test %file
  .remove $qt(%file)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum /JSONOpen : failed to parse input from file : $v2
  }
  $(%echo,2) /JSONOpen : Passed Parse: input from file
  JSONClose jfm_test


  ;;=====================;;
  ;;                     ;;
  ;;     $JSON tests     ;;
  ;;                     ;;
  ;;=====================;;

  ;; Check to make sure $JSON reports PARAMETER_MISSING
  inc %testnum
  noop $JSON
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum $!JSON : Reported incorrect error: $v2
  }
  $(%echo,2) $!JSON : Passed Check: PARAMETER_MISSING


  ;; Check to make sure $JSON() reports PARAMETER_MISSING
  inc %testnum
  noop $JSON()
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON() : Failed to report error (PARAMETER_MISSING)
  }
  if (PARAMETER_MISSING !== %err) {
    return %testnum $!JSON() : Reported incorrect error: $v2
  }
  $(%echo,2) $!JSON() : Passed Check: PARAMETER_MISSING


  ;; Check to make sure $JSON(0, ...) reports INVALID_NAME
  inc %testnum
  noop $JSON(0, jfm_test)
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON(0, jfm_test) : Failed to report error (INVALID_NAME)
  }
  if (INVALID_NAME !== %err) {
    return %testnum $!JSON(0, jfm_test) : Reported incorrect error: $v2
  }
  $(%echo,2) $!JSON(0, jfm_test) : Passed Check: INVALID_NAME


  ;; Check to make sure $JSON(0).prop reports PROP_NOT_APPLICABLE
  inc %testnum
  noop $JSON(0).jfm_test
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON(0).jfm_test : Failed to report error (PROP_NOT_APPLICABLE)
  }
  if (PROP_NOT_APPLICABLE !== %err) {
    return %testnum $!JSON(0).jfm_test : Reported incorrect error: $v2
  }
  $(%echo,2) $!JSON(0).jfm_test : Passed Check: PROP_NOT_APPLICABLE


  ;; Check to make sure $JSON(0) returns a numerical value
  inc %testnum
  %res = $JSON(0)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(0) : Report error: $v2
  }
  if (%res !isnum) {
    return %testnum $!JSON(0) : Returned non-numerical value: %res
  }
  if (0 !== %res) {
    return %testnum $!JSON(0) : Returned a value other than 0: $v2
  }
  $(%echo,2) $!JSON(0) : Passed Check


  ;; Check to make sure $JSON(_nonhandler_) reports the correct error
  inc %testnum
  %res = $JSON(jfm_test)
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON(jfm_test) : Failed to report error (HANDLER_NOT_FOUND)
  }
  if (HANDLER_NOT_FOUND !== %err) {
    return %testnum $!JSON(jfm_test) : Reported incorrect error: $v2
  }
  if ($null !== %res) {
    return %testnum $!JSON(jfm_test) : Returned a value after an error occured: $v2
  }
  $(%echo,2) $!JSON(jfm_test) : Passed Check: HANDLER_NOT_FOUND


  ;; Open a valid json handler for the following tests
  JSONOpen jfm_test %jsondata
  if ($JSONError) {
    return --- Failed to open json handle for valid json data, tests cannot continue: $v1
  }


  ;; Test to make sure $JSON(name) returns correct name
  inc %testnum
  %res = $JSON(jfm_test)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test) : Reported invalid error: $v2
  }
  if (JSON:jfm_test !== %res) {
    return %testnum $!JSON(jfm_test) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test) : Passed Check


  ;; Test $JSON().State
  inc %testnum
  %res = $JSON(jfm_test).State
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).State : Reported invalid error: $v2
  }
  if (done !== %res) {
    return %testnum $!JSON(jfm_test).State : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).State : Passed Check


  ;; Test $JSON().InputType
  inc %testnum
  %res = $JSON(jfm_test).InputType
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).InputType : Reported invalid error: $v2
  }
  if (text !== %res) {
    return %testnum $!JSON(jfm_test).InputType : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).InputType : Passed Check


  ;; Test $JSON().Input
  inc %testnum
  %res = $JSON(jfm_test).Input
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).Input : Reported invalid error: $v2
  }
  if (%jsondata !== %res) {
    return %testnum $!JSON(jfm_test).Input : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).Input : Passed Check


  ;; Test $JSON().IsChild
  inc %testnum
  %res = $JSON(jfm_test).IsChild
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).IsChild : Reported invalid error: $v2
  }
  if ($false !== %res) {
    return %testnum $!JSON(jfm_test).IsChild : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).IsChild : Passed Check


  ;; Test $JSON().Error
  inc %testnum
  %res = $JSON(jfm_test).Error
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).Error : Reported invalid error: $v2
  }
  if ($null !== %res) {
    return %testnum $!JSON(jfm_test).Error : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).Error : Passed Check


  ;; Test $JSON().Path
  inc %testnum
  %res = $JSON(jfm_test).Path
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).Path : Reported invalid error: $v2
  }
  if ($null !== %res) {
    return %testnum $!JSON(jfm_test).Path : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).Path : Passed Check


  ;; Test $JSON().Type
  inc %testnum
  %res = $JSON(jfm_test).Type
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).Type : Reported invalid error: $v2
  }
  if (object !== %res) {
    return %testnum $!JSON(jfm_test).Type : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).Type : Passed Check


  ;; Test $JSON().IsContainer
  inc %testnum
  %res = $JSON(jfm_test).IsContainer
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).IsContainer : Reported invalid error: $v2
  }
  if ($true !== %res) {
    return %testnum $!JSON(jfm_test).IsContainer : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).IsContainer : Passed Check


  ;; Test $JSON().Length
  inc %testnum
  %res = $JSON(jfm_test).Length
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).Length : Reported invalid error: $v2
  }
  if (10 !== %res) {
    return %testnum $!JSON(jfm_test).Length : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).length : Passed Check

  ;; Test $JSON().String
  inc %testnum
  %res = $JSON(jfm_test).String
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).String : Reported invalid error: $v2
  }
  if (%jsondata !== %res) {
    return %testnum $!JSON(jfm_test).String : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).String : Passed Check


  ;; Test $JSON().Debug
  inc %testnum
  %res = $JSON(jfm_test).Debug
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).Debug : Reported invalid error: $v2
  }
  if (%debugdata !== %res) {
    return %testnum $!JSON(jfm_test).Debug : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test).Debug : Passed Check


  ;; Check to make sure $JSON(name, members..) returns a reference
  inc %testnum
  %res = $JSON(jfm_test, true)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, true) : Reported invalid error: $v2
  }
  if (JSON:jfm_test:?* !iswm %res) {
    return %testnum $!JSON(jfm_test, true) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, true) : Passed Check


  ;; Check to make sure $JSON(name, <points to undefined>) reports error
  inc %testnum
  %res = $JSON(jfm_test, undefined)
  %err = $JSONError
  if (REFERENCE_NOT_FOUND !== %err) {
    return %testnum $!JSON(jfm_test, undefined) : reported invalid error: $v2
  }
  if ($null !== %res) {
    return %testnum $!JSON(jfm_test, undefined) : Returned value with error: $v2
  }
  $(%echo,2) $!JSON(jfm_test, undefined) : Passed Check


  ;; Check to make sure $JSON(name, <points to null>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, null).value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, null).Value : Reported invalid error: $v2
  }
  if ($null !== %res) {
    return %testnum $!JSON(jfm_test, null).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, null).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to true>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, true).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, true).Value : Reported invalid error: $v2
  }
  if ($true !== %res) {
    return %testnum $!JSON(jfm_test, true).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, true).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to false>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, false).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, false).Value : Reported invalid error: $v2
  }
  if ($false !== %res) {
    return %testnum $!JSON(jfm_test, false).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, false).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to uint>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, int).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, int).Value : Reported invalid error: $v2
  }
  if (1 !== %res) {
    return %testnum $!JSON(jfm_test, int).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, int).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to signed int>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, negint).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, negint).Value : Reported invalid error: $v2
  }
  if (-1 !== %res) {
    return %testnum $!JSON(jfm_test, negint).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, negint).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to decimal>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, dec).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, dec).Value : Reported invalid error: $v2
  }
  if (1.1 !== %res) {
    return %testnum $!JSON(jfm_test, dec).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, dec).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to signed decimal>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, negdec).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, negdec).Value : Reported invalid error: $v2
  }
  if (-1.1 !== %res) {
    return %testnum $!JSON(jfm_test, negdec).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, negdec).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to string>).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, string).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, string).Value : Reported invalid error: $v2
  }
  if (string !== %res) {
    return %testnum $!JSON(jfm_test, string).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, string).Value : Passed Check


  ;; Check to make sure $JSON(name, <path to string>).length returns correct value
  inc %testnum
  %res = $JSON(jfm_test, string).Length
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, string).Length : Reported invalid error: $v2
  }
  if (6 !== %res) {
    return %testnum $!JSON(jfm_test, string).Length : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, string).Length : Passed Check


  ;; Check to make sure $JSON(name, <points to array>).value returns correct error
  inc %testnum
  %res = $JSON(jfm_test, array).Value
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON(jfm_test, array).Value : Failed to report error (INVALID_TYPE)
  }
  if (INVALID_TYPE !== %err) {
    return %testnum $!JSON(jfm_test, array).Value : Reported invalid error: $v2
  }
  if (%res) {
    return %testnum $!JSON(jfm_test, array).Value : Returned value in error state: $v2
  }
  $(%echo,2) $!JSON(jfm_test, array).Value : Passed Check


  ;; Check to make sure $JSON(name, <path to array>).length returns correct value
  inc %testnum
  %res = $JSON(jfm_test, array).Length
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, array).Length : Reported invalid error: $v2
  }
  if (3 !== %res) {
    return %testnum $!JSON(jfm_test, array).Length : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, array).Length : Passed Check


  ;; Check to make sure $JSON(name, <points to array>, 0).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, array, 0).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, array, 0).Value : Reported invalid error: $v2
  }
  if (item0 !== %res) {
    return %testnum $!JSON(jfm_test, array, 0).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, array, 0).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to array>, 0).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, array, 2).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, array, 2).Value : Reported invalid error: $v2
  }
  if (item2 !== %res) {
    return %testnum $!JSON(jfm_test, array, 2).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, array, 2).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to object>).value returns correct error
  inc %testnum
  %res = $JSON(jfm_test, object).Value
  %err = $JSONError
  if ($null == %err) {
    return %testnum $!JSON(jfm_test, object).Value : Failed to report error (INVALID_TYPE)
  }
  if (INVALID_TYPE !== %err) {
    return %testnum $!JSON(jfm_test, object).Value : Reported invalid error: $v2
  }
  if (%res) {
    return %testnum $!JSON(jfm_test, object).Value : Returned value in error state: $v2
  }
  $(%echo,2) $!JSON(jfm_test, object).Value : Passed Check


  ;; Check to make sure $JSON(name, <path to object>).length returns correct value
  inc %testnum
  %res = $JSON(jfm_test, object).Length
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, object).Length : Reported invalid error: $v2
  }
  if (3 !== %res) {
    return %testnum $!JSON(jfm_test, object).Length : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, object).Length : Passed Check


  ;; Check to make sure $JSON(name, <points to object>, 0).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, object, key0).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, object, key0).Value : Reported invalid error: $v2
  }
  if (item0 !== %res) {
    return %testnum $!JSON(jfm_test, object, key0).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, object, key0).Value : Passed Check


  ;; Check to make sure $JSON(name, <points to object>, 0).value returns correct value
  inc %testnum
  %res = $JSON(jfm_test, object, key2).Value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, object, key2).Value : Reported invalid error: $v2
  }
  if (item2 !== %res) {
    return %testnum $!JSON(jfm_test, object, key2).Value : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, object, key2).Value : Passed Check


  ;; Check to make sure $JSON(name, fuzzy member).value returns correct value as case-insensitive
  inc %testnum
  %res = $JSON(jfm_test, ~ TRUE).FuzzyValue
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, ~ TRUE).FuzzyValue : Reported invalid error: $v2
  }
  if ($true !== %res) {
    return %testnum $!JSON(jfm_test, ~ TRUE).FuzzyValue : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, ~ TRUE).FuzzyValue : Passed Check


  ;; Check to make sure $JSON(name, fuzzy member).value returns correct value as index
  inc %testnum
  %res = $JSON(jfm_test, ~ 1).FuzzyValue
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, ~ 1).FuzzyValue : Reported invalid error: $v2
  }
  if ($true !== %res) {
    return %testnum $!JSON(jfm_test, ~ 1).FuzzyValue : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, ~ 1).FuzzyValue : Passed Check


  ;;=========================;;
  ;;                         ;;
  ;;     $JSONPath tests     ;;
  ;;                         ;;
  ;;=========================;;

  ;; Check to make sure $JSONPath(..., 0) returns correct amount of items in path variable
  inc %testnum
  %res = $JSONPath($JSON(jfm_test, array), 0)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSONPath(..., 0) : Reported invalid error: $v2
  }
  if (1 !== %res) {
    return %testnum $!JSONPath(..., 0) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSONPath(..., 0) : Passed Check


  ;; Check to make sure $JSONPath(..., 0) returns correct key name
  inc %testnum
  %res = $JSONPath($JSON(jfm_test, array), 1)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSONPath(..., 1) : Reported invalid error: $v2
  }
  if (array !== %res) {
    return %testnum $!JSONPath(..., 1) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSONPath(..., 1) : Passed Check


  ;;============================;;
  ;;                            ;;
  ;;     $JSONForEach Tests     ;;
  ;;                            ;;
  ;;============================;;

  ;; Test $JSONForEach() on arrays
  inc %testnum
  unset %_jfm_foreach
  %res = $JSONForEach($JSON(jfm_test, array), _jfm_ForEach)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSONForEach(<array>, ...) : Reported invalid error: $v2
  }
  if (%_jfm_foreach) {
    return %testnum $!JSONForEach(<array>, ...) /_jfm_ForEach : $v1
  }
  if (3 !== %res) {
    return %testnum $!JSONForEach(<array>, ...) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSONForEach(<array>, ...) : Passed Check


  ;; Test $JSONForEach() on objects
  inc %testnum
  unset %_jfm_foreach
  %res = $JSONForEach($JSON(jfm_test, object), _jfm_ForEach)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSONForEach(<object>, ...) : Reported invalid error: $v2
  }
  if (%_jfm_foreach) {
    return %testnum $!JSONForEach(<object>, ...) /_jfm_ForEach : $v1
  }
  if (3 !== %res) {
    return %testnum $!JSONForEach(<object>, ...) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSONForEach(<object>, ...) : Passed Check


  ;;==============================;;
  ;;                              ;;
  ;;     $JSONForValues Tests     ;;
  ;;                              ;;
  ;;==============================;;

  ;; Test $JSONForValues() on arrays
  inc %testnum
  unset %_jfm_foreach
  %res = $JSONForValues($JSON(jfm_test, array), _jfm_ForValues)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSONForValues(<array>, ...) : Reported invalid error: $v2
  }
  if (%_jfm_foreach) {
    return %testnum $!JSONForValues(<array>, ...) /_jfm_ForEach : $v1
  }
  if (3 !== %res) {
    return %testnum $!JSONForValues(<array>, ...) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSONForValues(<array>, ...) : Passed Check

  ;; Test $JSONForValues() on objects
  inc %testnum
  unset %_jfm_foreach
  %res = $JSONForValues($JSON(jfm_test, object), _jfm_ForValues)
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSONForValues(<object>, ...) : Reported invalid error: $v2
  }
  if (%_jfm_foreach) {
    return %testnum $!JSONForValues(<object>, ...) /_jfm_ForEach : $v1
  }
  if (3 !== %res) {
    return %testnum $!JSONForValues(<object>, ...) : Returned incorrect value: $v2
  }
  $(%echo,2) $!JSONForValues(<object>, ...) : Passed Check


  ;; Close the JSON handle
  JSONClose jfm_test


  ;;==============================;;
  ;;                              ;;
  ;;     /JSONOpen HTTP tests     ;;
  ;;                              ;;
  ;;==============================;;

  ;; (slv) Added Test: Attempt to use invalid SSL cert with/without i switch
  %cert_url = https://self-signed.badssl.com
  %cert_re = /^The certificate authority is invalid or incorrect/
  inc %testnum
  JSONOpen -u jfm_test %cert_url
  if (!$regex($JSONError,%cert_re)) {
    return %testnum /JSONOpen -u %cert_url : Request reported unexpected error: $v2
  }
  $(%echo,2) /JSONOpen -u %cert_url : Passed Check
  JSONClose jfm_test
  inc %testnum
  JSONOpen -ui jfm_test %cert_url
  if ($regex($JSONError,%cert_re)) {
    return %testnum /JSONOpen -ui %cert_url : Request reported error: $v2
  }
  $(%echo,2) /JSONOpen -ui %cert_url : Request succeeded
  JSONClose jfm_test

  ;; Attempt to retrieve data from a remote source
  inc %testnum
  JSONOpen -u jfm_test http://echo.jsontest.com/key/value
  if ($null !== $JSONError) {
    if ($JSONError == INVALID_JSON) {
      return %testnum /JSONOpen -u : Request reported error: $v2 WARNING: possible issue with jsontest.com ('Over Quota')
    }
    return %testnum /JSONOpen -u : Request reported error: $v2
  }
  $(%echo,2) /JSONOpen -u : Request succeeded

  ;; Check to make sure the parsed json can be accessed
  inc %testnum
  %res = $JSON(jfm_test, key).value
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, key).value after request reported invalid error: $v2
  }
  if (value !== %res) {
    return %testnum $!JSON(jfm_test, key).value after request returned incorrect value: $v2
  }
  $(%echo,2) $!JSON(jfm_test, key).value after request: Passed Check


  ;; Check $JSON().HttpStatus
  inc %testnum
  %res = $JSON(jfm_test).HttpStatus  
  %err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpStatus : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpStatus : Returned incorrect value: $!null
  }
  if (%res !isnum) {
    return %testnum $!JSON(jfm_test).HttpStatus : Returned incorrect value: %res
  }
  $(%echo,2) $!JSON(jfm_test).HttpStatus : Passed Check


  ;; Check $JSON().HttpStatusText
  inc %testnum
  %res = $JSON(jfm_test).HttpStatusText 
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpStatusText : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpStatusText : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test).HttpStatusText : Passed Check


  ;; Check $JSON().HttpHeader
  inc %testnum
  %res = $JSON(jfm_test, Content-Length).HttpHeader
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test, Content-Length).HttpHeader : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test, Content-Length).HttpHeader : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test, Content-Length).HttpHeader : Passed Check


  ;; Check $JSON().HttpHeaders
  inc %testnum
  %res = $JSON(jfm_test).HttpHeaders
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpHeaders : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpHeaders : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test).HttpHeaders : Passed Check


  ;; Check $JSON().HttpHead
  inc %testnum
  %res = $JSON(jfm_test).HttpHead
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpHead : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpHead : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test).HttpHead : Passed Check


  ;; Check $JSON().HttpBody
  inc %testnum
  %res = $JSON(jfm_test).HttpBody
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpBody : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpBody : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test).HttpBody : Passed Check


  ;; Check $JSON().HttpResponse
  inc %testnum
  %res = $JSON(jfm_test).HttpResponse
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpResponse : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpResponse : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test).HttpResponse : Passed Check


  ;; Check $JSON().HttpParse
  inc %testnum
  %res = $JSON(jfm_test).HttpParse
  %Err = $JSONError
  if ($null !== %err) {
    return %testnum $!JSON(jfm_test).HttpParse : Reported invalid error: $v2
  }
  if ($null == %res) {
    return %testnum $!JSON(jfm_test).HttpParse : Returned incorrect value: $!null
  }
  $(%echo,2) $!JSON(jfm_test).HttpParse : Passed Check

  JSONClose jfm_test

}


;; Frees all json-related resources:
;;   Closes all json related coms
;;   frees the json hashtable
;;   turns off al related timers
alias -l _cleanup {
  unset %_jfm_ForEach
  var %x = $com(0)
  while (%x) {
    if (JSON:* iswm $com(%x)) .comclose $v2
    dec %x
  }
  if ($hget(SReject/JSONForMirc)) {
    hfree $v1
  }
  .timerJSON:* off
}


;; Verifies passed inputs from $JSONForEach()
alias _jfm_ForEach {
  if (!%_jfm_ForEach) {
    if ($0 !== 1) {
      set -u1 %_jfm_ForEach Too many parameters passed to alias
    }
    elseif ($null == $com($1)) {
      set -u1 %_jfm_ForEach Passed reference does not exist: $v2
    }
    else {
      var %res = $JSON($1).Value
      if ($null !== $JSONError) {
        set -u1 %_jfm_ForEach Attempting to retrieve item value reported invalid error: $v2
      }
      elseif (item? !iswm %res) {
        set -u1 %_jfm_ForEach Retrieved item value invalid: $v2
      }
    }
  }
}

;; Verifies passed inputs from $JSONForValues()
alias _jfm_ForValues {
  if (!%_jfm_ForEach) {
    if (item? !iswm $1) {
      set -u1 %_jfm_ForEach Retrieved item value invalid: $v2
    }
  }
}
