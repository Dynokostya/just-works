# Activity Diagrams

Use for business processes, workflows, and decision flows. Swimlane partitions make it clear who is responsible for each step.

## Basic flow

```plantuml
@startuml
title Order Processing Workflow

start

:Customer submits order;

if (Payment valid?) then (yes)
    :Charge payment method;
    if (Inventory available?) then (yes)
        fork
            :Reserve inventory;
        fork again
            :Send confirmation email;
        end fork
        :Ship order;
    else (no)
        :Notify customer of backorder;
        :Add to waitlist;
    endif
else (no)
    :Reject order;
    :Notify customer;
    stop
endif

:Update order status to "Complete";

stop

@enduml
```

## Swimlanes with partitions

```plantuml
@startuml
title Support Ticket Resolution

|Customer|
start
:Submit support ticket;

|Support Agent|
:Review ticket;
if (Can resolve immediately?) then (yes)
    :Provide solution;
else (no)
    |Engineering|
    :Investigate issue;
    :Implement fix;
    |Support Agent|
    :Communicate resolution;
endif

|Customer|
:Confirm resolution;
stop

@enduml
```

**Key syntax:** `start`/`stop`, `:action;`, `if (condition?) then (yes) else (no) endif`, `fork`/`fork again`/`end fork`, `|Swimlane|`, floating notes with `floating note right: text`.

## Coloring activity steps with stereotypes

To highlight specific paths (e.g., desired flow, error paths, regeneration vs new), use **stereotypes with skinparam**. Do NOT use inline `#color` after `;` — it causes syntax errors in activity diagrams.

```plantuml
@startuml
skinparam activity {
  BackgroundColor #F5F5F5
  BorderColor #333333
}

skinparam activity {
  BackgroundColor<<desired>> #E3F2E7
  BorderColor<<desired>> #7BAA87
  FontColor<<desired>> #000000

  BackgroundColor<<error>> #FDE2E2
  BorderColor<<error>> #C77C7C
  FontColor<<error>> #000000
}

title Example Flow

start
:Normal step;
:Desired step; <<desired>>
:Error step; <<error>>
stop

legend right
  |= Color |= Meaning |
  |<#E3F2E7>| Desired flow |
  |<#FDE2E2>| Error path |
endlegend
@enduml
```

**Rules:**
- Define stereotype colors in a `skinparam activity {}` block at the top
- Apply with `<<stereotype>>` after the `;` on the activity line
- Use a color legend table to explain meanings
- Common stereotypes: `<<desired>>`, `<<error>>`, `<<regen>>`, `<<newgen>>`, `<<fallback>>`
- `elseif` always requires `then` — omitting it causes syntax errors downstream
