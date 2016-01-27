alias JSON {
  if (!$isid) {
    return
  }

  ;; variable setup
  var %Param, %Error, %Result, %RefCom, %RefClose, %RefCom2, %ToBVar, %ToFile, %RemFile, %ApdCrlf, %FileSize, %Prop, %Type, %BVar, %Result, %Index

  ;; Create a list of parameters and output debug message
  scid $cid var % $+ param = % $+ param $!+ , $!+ $*
  %Param = $mid(%Param, 2-)
  _JSON.Log Calling~$JSON( $+ %Param $+ )

  if (!$0) {
    %Error = Missing Parameters
  }

  ;; if the first input is '0' return total number of open handles
  elseif ($1 === 0) {
    if ($0 != 1 || $len($prop)) {
      %Error = Invalid parameters: Invalid index(0) used to request members or properties
    }
    elseif (!$_JSON.Call(Manager, count, 1)) {
      %Error = $JSONError
    }
    elseif ($com($_JSON.Com(manager)).result isnum 0-) {
      %Result = $v1
    }
    else {
      %Error = Unable to retrieve handle count
    }
  }

  ;; if the prop is 'isref' return $true if the input is an open handle reference
  elseif ($prop == IsRef) {
    if ($0 != 1) {
      %Error = Invalid parameters: Cannot request members when using $!JSON().IsRef
    }
    else {
      %Result = $false
      if ($regex($1, /^JSONForMirc:Tmp:\d+$/i) && $com($1)) {
        %Result = $true
      }
    }
  }

  else {

    ;; Check if first input is a handle reference
    ;; use it instead of attempting to retrieve a handle reference
    if ($regex($1, /^JSONForMirc:Tmp:\d+$/i)) {
      if (!$com($1)) {
        %Error = Reference does not exist
      }
      else {
        %RefCom = $1
      }
    }

    ;; Attempt to get the reference that corrosponds with $1
    else {
      %RefCom = $_JSON.Com
      if (!$_JSON.Call(Manager, get, 1, bstr, $1, dispatch* %RefCom)) {
        %Error = $JSONError
      }
      elseif (!$com(%RefCom)) {
        %Error = Unable to retrieve reference to ` $+ $1`
      }
      else {
        %RefClose = $true
      }
    }

    if (!%Error && !$len(%Result) && $com(%RefCom)) {

      ;; handle output delegation for httpResponse httpHead httpHeaders httpBody and ValueTo
      if ($0 > 1) && ($prop == HttpResponse || $prop == HttpHead || $prop == HttpHeaders || $prop == HttpBody || $prop == ValueTo) {

        ;; parameter count check
        if ($prop == ValueTo && $0 < 3) || ($prop != ValueTo && $0 !== 3) {
          %Error = Invalid parameters for $!JSON(). $+ $prop
        }

        ;; Basic switch verification
        elseif (!$regex($2,[bf])) {
          %Error = No 'output' switch specified
        }
        elseif ($regex($2, /([^bfan])/)) {
          %Error = Unknown Switch: $regml(1)
        }
        elseif ($regex($2, /([bf]).*\1/)) {
          %Error = Duplicate Switch: $regml(1)
        }
        elseif (b isincs $2 && f isincs $2) {
          %Error = Conflicting Switch: 'b' and 'f'
        }

        ;; Handle the bvar switch
        elseif (b isincs $2) {
          if ($2 !== b) {
            %Error = Invalid Switch: b cannot be used with other switches
          }
          elseif (&?* !iswm $3) {
            %Error = Invalid parameters: binary variables must start with &
          }
          elseif ($chr(32) isin $3) {
            %Error = Invalid parameters: binary variables cannot contain spaces
          }
          elseif ($len($3) == 1) {
            %Error = Invalid parameters: No bvar name given
          }
          else {
            %ToBvar = $3
          }
        }

        ;; Handle file switch
        else {
          %ToFile = $longfn($3)
          %RemFile = $true
          %ApdCrlf = $false

          ;; basic file path validation
          if ($count(%ToFile, :) > 1) {
            %Error = Illegal filename: Contains multiple ":" characters
          }

          ;; if a is specified, check if the file exists
          elseif (a isincs $2 && $isfile(%ToFile) && $file(%ToFile).size) {
            %FileSize = $v1
            %RemFile = $false

            ;; if n specified, check if the file ends with $crlf
            if (n isincs $2 && %fileSize > 1) {
              %BVar = $_JSON.TmpBVar
              bread $qt(%ToFile) $calc(%FileSize - 2) 2 %BVar
              if ($bvar(%BVar, 1, 2).text !== $crlf) {
                %ApdCrlf = $true
              }
              bunset %BVar
            }
          }
        }
      }


      ;; Property handling for:
      ;;     Status HttpResponse HttpHead HttpStatus HttpStatusText HttpHeaders HttpHeader HttpBody
      if ($istok(Status HttpResponse HttpHead HttpStatus HttpStatusText HttpHeaders HttpHeader HttpBody, $prop, 32)) {

        ;; Attempt to get JSON Handle reference from RefCom
        if (!$_JSON.Call(%RefCom, name, 2)) {
          %Error = $JSONError
        }
        elseif ($com(%RefCom).result {
          %RefCom2 = $_JSON.Com
          if (!$_JSON.Call(Manager, get, 1, bstr, $v1, dispatch* %RefCom2)) {
            %Error = $JSONError
          }
          elseif (!$com(%RefCom2)) {
            %Error = Unable to get handle reference
          }
        }
        else {
          %Error = Unable to get handle reference.
        }

        if (!%Error) {

          ;; Handle HttpHeader requests
          if ($prop == HttpHeader) {
            if (!$_JSON.Call(%RefCom2, httpHeader, 1, bstr, $2)) {
              %Error = $JSONError
            }
            else {
              %Result = $com(%RefCom2).result
            }
          }

          ;; Retrieve all other handle-related properties by calling their js function
          else {
            %BVar = $_JSON.TmpBVar
            %Prop = $matchtok(status httpResponse httpHead httpStatus httpStatusText httpHeaders httpBody, $lower($prop), 1, 32)
            if (!$_JSON.Call(%RefCom2, %Prop, 1)) {
              %Error = $JSONError
            }
            elseif (!$com(%RefCom2, %BVar).result) {
              %Error = Unable to retrieve %prop (no data returned)
            }
          }
        }
      }

      ;; Traversal handling
      elseif (!$prop || $istok(Type Length IsParent Value ValueTo, $prop, 32)) {

        %RefCom2 = $_JSON.Com

        ;; Build parameter list
        %index = 2
        if ($prop == ValueTo) {
          %index = 4
        }
        %param = $null
        unset %_JSONForMirc:InputCount
        scid $cid % $+ param = $!addtok(% $+ param , $!_JSON.ParseInputs( %index , $* ) , 44)
        if (%param) {
          %param = $chr(44) $+ %param
        }

        ;; traverse the reference to the required index
        if (!$_JSON.Call(manager, traverse, 1, dispatch, %RefCom, [ %param ] , dispatch* %RefCom2)) {
          %Error = $JSONError
        }

        ;; make sure a result object was returned
        elseif (!$com(%RefCom2)) {
          %Error = Traversing did not create a reference
        }

        ;; If no prop, use the reference created as the result
        elseif (!$prop) {
          %Result = %RefCom2
          %RefCom2 = $null
        }

        ;; $JSON().Type $JSON().Length and $JSON().IsParent delegation
        elseif ($prop == Type || $prop == Length || $prop == IsParent) {

          ;; get prop name
          %Prop = $matchtok(type length isParent, $Prop, 1, 32)

          ;; attempt to get the property value
          if (!$_JSON.Call(%RefCom2, %Prop, 2)) {
            %Error = $JSONError
          }
          else {
            %BVar = $_JSON.TmpBvar
            noop $com(%RefCom2, %BVar).result
          }
          .comclose %RefCom2
        }

        ;; $JSON().Value and $JSON().ValueTo
        elseif ($prop == Value || $prop == ValueTo) {
          if (!$_JSON.Call(%RefCom2, type, 2)) {
            %Error = Unable to determine reference type
          }
          else {
            %Type = $com(%RefCom2).result
            if (%type == object || %type == array) {
              %Error = Cannot return a value for containers
            }
            elseif (!$_JSON.Call(%RefCom2, value, 2)) {
              %Error = Unable to get the value property
            }
            else {
              %BVar = $_JSON.TmpBvar
              noop $com(%RefCom2, %BVar).result
            }
          }
          .comclose %RefCom2
        }
      }
      else {
        %Error = Unknown property: $prop
      }

      if (!%Error && !%Result) {

        ;; If required, copy the temp bvar into the user specified bvar
        if (%ToBVar) {
          bunset %ToBVar
          bcopy -c %ToBVar 1 -1 %BVar
          %Result = %ToBVar
        }

        ;; If required, write the temp bvar to file
        elseif (%ToFile) {
          if (%RemFile && $isfile(%ToFile)) {
            .remove $qt(%ToFile)
          }
          if (%ApdCrlf) {
            bcopy -c %BVar 3 -1 %BVar
            bset -t %BVar 1 $crlf
          }
          .bwrite $qt(%ToFile) $calc($file(%ToFile).size +1) -1 %BVar
          %Result = $file(%ToFile).size
        }

        ;; Otherwise return the resulting text
        elseif ($bvar(%BVar, 0) > 4000) {
          %Error = Line too long
        }
        else {
          %Result = $bvar(%BVar, 1-).text
        }
      }
    }
  }


  :error
  %Error = $iif($error, $v1, %Error)

  ;; Handle closing the reference com
  if ($com(%RefCom)) {

    ;; if needed, close immediately
    if (%RefClose) {
      .comclose %RefCom
    }

    ;; otherwise close at the end of the script execution block
    elseif (!$timer(%RefCom)) {
      $+(.timer,%RefCom) 1 0 if ($com( %RefCom )) .comclose $!v1
    }
  }

  ;; close the result reference com
  if ($com(%RefCom2)) {
    .comclose %RefCom2
  }

  ;; handle errors
  if (%Error) {
    set -u0 %_JSONForMirc:Error $v1
    reseterror
    _JSON.Log Error $!JSON~ $+ %Error
  }
  else {
    _JSON.Log Ok $!JSON()~Call successful; returning: %Result
    return %Result
  }
}