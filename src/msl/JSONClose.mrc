alias JSONClose {
    if ($isid) return

    ;; Log the calling
    _JSON.Log Calling~/JSONClose $1-
    var %Error, %Result, %Switches, %Matchtext

    ;; check to make sure required coms are opened
    if (!$_JSON.Start) {
        %Error = $v1
    }
    else {

        ;; remove switches from parameters
        if (-* iswm $1) {
            %Switches = $mid($1, 2-)
            tokenize 32 $2-
        }

        ;; validate parameters
        if ($0 < 1) {
            %Error = Missing parameters
        }
        elseif ($regex(%Switches, ([^sw]))) {
            %Error = Unknown Switch: $regml(1)
        }
        elseif ($regex(%Switches, ([sw]).*\1)) {
            %Error = Duplicate Switch: $regml(1)
        }
        elseif ($regex(%Switchs, /([sw])/g) > 1) {
            %Error = Conflicting Switch: s & w
        }
        else {

            ;; attempt to save if requested
            if (s isincs %switches) {
                JSONSave $1-
                if ($JSONError) {
                    %Error = $v1
                }
                else {
                    %Matchtext = $_JSON.WildcardToRegex($1);
                }
            }

            ;; Convert match to regex
            elseif ($0 !== 1) {
                %Error = Matchtext cannot contain spaces
            }
            else {
                %Matchtext = $_JSON.WildcardToRegex($1);
            }

            ;; attempt to close handle
            if (!%Error && !$_JSON.Call(Manager, close, 1, bstr, %Matchtext)) {
                %Error = $JSONError
            }
            else {
                %Result = $com($_JSON.Com(Manager)).result
            }
        }
    }

    ;; Error Handling
    :error
    %Error = $iif($error, $v1, %Error)
    if (%Error) {
        set -u %_JSONForMirc:Error $v1
        reseterror
        _JSON.Log Error /JSONClose $v1
    }
    else {
        _JSON.Log Ok /JSONClose~Closed %Result handles
    }
}