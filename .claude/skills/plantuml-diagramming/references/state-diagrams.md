# State Diagrams

Use for modeling the lifecycle of a single entity, such as an order, ticket, user account or deployment.

## Basic lifecycle

```plantuml
@startuml
title Order Lifecycle

[*] --> Pending: Order created
Pending --> Confirmed: Payment succeeds
Pending --> Cancelled: Payment fails
Confirmed --> Shipped: Carrier picks up
Shipped --> Delivered: Delivery confirmed
Delivered --> [*]
Cancelled --> [*]

@enduml
```

## Composite (nested) states

A state can contain its own sub-lifecycle:

```plantuml
state Pending {
    [*] --> AwaitingPayment
    AwaitingPayment --> PaymentReceived: Payment confirmed
    AwaitingPayment --> [*]: Payment timeout
}
```

## Key syntax

- `[*]` -- initial and final pseudo-states
- `state Name { }` -- composite/nested states
- `state "Long Name" as alias` -- aliasing for readability
- `state fork_point <<fork>>` / `<<join>>` -- concurrent region fork/join
- `state choice_point <<choice>>` -- decision point

## Concurrent regions

```plantuml
state Processing {
    state "Verify Payment" as vp
    state "Check Inventory" as ci
    [*] --> vp
    [*] --> ci
    vp --> [*]
    ci --> [*]
    --
    state "Send Notification" as sn
    [*] --> sn
    sn --> [*]
}
```
