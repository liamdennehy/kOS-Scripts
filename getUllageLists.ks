set burnStage to ship:stagenum - 1.
set ullage to list().
set engines to list().
set needsUllage to false.
for part in ship:parts {
  if part:typename = "RCS" and part:FOREBYTHROTTLE and (part:stage = burnstage or part:stage = burnstage - 1){
    ullage:add(part).
    }.
  if part:typename = "Engine" and part:stage = burnStage {
    engines:add(part).
    if part:ullage { set needsUllage to true. }.
    }.
  }.
}.
