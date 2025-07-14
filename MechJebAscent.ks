declare function show {
  parameter text.
  hudtext(text, 5, 2, 30, green, true).
  }.

declare function getUllageLists {
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

declare function doMechJebAscentCoast {
  show("Coasting...").
  getUllageLists().
  if needsUllage {
    set rcsStarted to time:seconds.
    for rcs in ullage {
      set rcs:enabled to true. }.
    wait until throttle = 1.
    show("Stabilising fuel...").
    set allstable to false.
    until allstable {
      set allstable to true.
      for e in engines {
        if e:fuelstability < 1 { set allstable to false. }.
      }.
      wait 0.01.
      }.
    // troubleshoot a weirdly large value for elapsed.
    set now to time:seconds.
    set rcsElapsed to now - rcsStarted.
    print rcsStarted.
    print now.
    print "RCS stabilised fuel in " + (engines:length - 1) + " engine(s) after " + round(rcsElapsed * 100)/100 + " seconds".
    }
  else {
    wait until throttle = 1.
    }.
  stage.
  show("Ignition!").
  if needsUllage {
    for rcs in ullage {
      set rcs:enabled to false.
      }.
    }.
  show("Hopefully inserting to orbit?").
  wait until throttle = 0.
  }.

declare function doOrbitFinals {
  set deployables to list().
  for part in ship:parts {
    if part:hasmodule("ModuleRealAntenna") and part:getmodule("ModuleRealAntenna"):hasfield("RF BAND"){
      set RABand to part:getmodule("ModuleRealAntenna"):getfield("rf band").
      if part:hasmodule("ModuleDeployableAntenna") and (RABand = "VHF" or RABand = "UHF") {
        // Not a flip-out dish antenna, probably an omni.
        deployables:add(part).
        }.
    } else if part:hasmodule("ModuleROSolar") {
      deployables:add(part).
//    } else if part:hasmodule("ModuleCommand") {
//      if part:getmodule("ModuleCommand"):hasfield("command state") {
//        print part:getmodule("ModuleCommand"):getfield("command state").
//        if part:getmodule("ModuleCommand"):getfield("command state") = "Hibernating" {
//          deployables:add(part).
//          }.
//        }.
      }.
    }.
  print deployables.
  until deployables:length = 0 {
    set stutter to (random() * (deployables:length)).
    set instance to floor(random() * deployables:length).
    print "Deploying " + deployables[instance] + " after " + round(stutter * 100)/100 + "s, " + (deployables:length - 1) + " to go".
    wait stutter.
    if deployables[instance]:hasmodule("ModuleDeployableAntenna") {
      deployables[instance]:getmodule("ModuleDeployableAntenna"):doaction("extend antenna",true).
   } else if deployables[instance]:hasmodule("ModuleROSolar") {
      deployables[instance]:getModule("ModuleROSolar"):doaction("extend solar panel",true).
      }.
    deployables:remove(instance).
    }.
  }.

declare function doMechJebAscent {
  on ag9 { set abort to true. toggle ag9.}.
  show("Ascent Automation waiting for launch. (AG0 to abort)").
  wait until (ship:status <> "PRELAUNCH" and throttle = 1) or abort.
  if abort { return. }.
  show("Up we go!").
  wait until throttle = 0.
  if ship:orbit:periapsis > 140000 {
    show("We appear to be in an orbit.").
    }
  else {
    doMechJebAscentCoast().
    for e in engines { e:shutdown. }.
    show("Everything shut down. Hope that worked!").
    doOrbitFinals().
    }.
  }.


set abort to false.

set statusList to list(ship:status).
on ship:status { statuslist:add(ship:status). return true. }.

print "Ascent Automation v0.1".
if ship:status = "LANDED" or ship:status = "PRELAUNCH"{
  wait 3. }.
print statusList.
if ship:status <> "PRELAUNCH" {
  print "It seems we are " + ship:status.
} else {
  doMechJebAscent().
  if abort { show("Aborted Ascent Assistance"). }.
  }.

