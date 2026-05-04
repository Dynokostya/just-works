# Component and Deployment Diagrams

Use these for high-level system architecture. Focus on boundaries and data flow, not internals.

## Component diagram

```plantuml
@startuml
title E-Commerce Platform Overview

package "Frontend" {
    [Web Application] as Web
    [Mobile App] as Mobile
}

package "API Gateway" {
    [Gateway] as GW
}

package "Backend Services" {
    [Order Service] as Orders
    [Payment Service] as Payments
    [Inventory Service] as Inventory
}

package "Data Layer" {
    database "Orders DB" as ODB
    database "Products DB" as PDB
    queue "Event Bus" as Events
}

Web --> GW: REST/HTTPS
Mobile --> GW: REST/HTTPS
GW --> Orders
GW --> Payments
GW --> Inventory
Orders --> ODB
Inventory --> PDB
Orders --> Events: Publishes events
Payments --> Events: Publishes events

@enduml
```

## Deployment diagram

```plantuml
@startuml
title Production Deployment

cloud "CDN" as cdn

node "AWS Region us-east-1" {
    node "EKS Cluster" {
        [API Gateway] as gw
        [Order Service] as orders
        [Payment Service] as payments
    }
    database "RDS PostgreSQL" as db
    queue "SQS" as sqs
}

cloud "Stripe" as stripe

cdn --> gw: HTTPS
gw --> orders
gw --> payments
orders --> db
orders --> sqs
payments --> stripe: Payment processing

@enduml
```

**Container types:** `node` (server/VM/container), `cloud` (external/cloud provider), `database` (data store), `package` (logical grouping), `rectangle` (generic boundary), `frame` (subsystem boundary).

Use `interface` or `()` for exposed ports:

```plantuml
() "REST API" as api
[Order Service] - api
```
