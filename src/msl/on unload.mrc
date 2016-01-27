on *:UNLOAD:{
  var %x = 1, %com
  while ($com(%x)) {
    %com = $v1
    if (JSONForMirc:* iswm %com) {
      .comclose %com
    }
    inc %x
  }

  if ($window(@JSONForMircDebug)) {
    .close -@ @JSONForMircDebug
  }
  unset %_JSONForMirc:*
  bunset &JSONForMirc:*
  .timerJSONForMirc:* off
}