# Other Diagram Types

## Use case diagram

Good for feature scope and actor interactions at a glance:

```plantuml
@startuml
title Customer Portal Features

left to right direction

actor Customer as C
actor "Support Agent" as SA

rectangle "Customer Portal" {
    usecase "View Orders" as UC1
    usecase "Track Shipment" as UC2
    usecase "Request Return" as UC3
    usecase "Chat with Support" as UC4
    usecase "Manage Returns" as UC5
}

C --> UC1
C --> UC2
C --> UC3
C --> UC4
SA --> UC4
SA --> UC5

@enduml
```

## Mindmap

Quick brainstorming or knowledge structure:

```plantuml
@startmindmap
title Project Architecture Decisions
* Architecture
** Frontend
*** React SPA
*** Server-Side Rendering
** Backend
*** Microservices
*** Monolith
** Data
*** PostgreSQL
*** Redis Cache
@endmindmap
```

## Gantt chart

Project timelines with dependencies:

```plantuml
@startgantt
title Q1 Release Plan
project starts 2026-01-05

[Design Phase] lasts 10 days
[Backend Development] lasts 15 days
[Frontend Development] lasts 15 days
[Testing] lasts 10 days
[Deployment] lasts 3 days

[Backend Development] starts at [Design Phase]'s end
[Frontend Development] starts at [Design Phase]'s end
[Testing] starts at [Backend Development]'s end
[Deployment] starts at [Testing]'s end

[Design Phase] is colored in LightBlue
[Deployment] is colored in LightGreen

@endgantt
```

## WBS (Work Breakdown Structure)

Hierarchical deliverable decomposition:

```plantuml
@startwbs
title Product Launch
* Product Launch
** Research
*** User Interviews
*** Competitive Analysis
** Development
*** Backend API
*** Frontend UI
*** Mobile App
** Launch
*** Marketing Campaign
*** Documentation
*** Training
@endwbs
```

## ER diagram (using class diagram syntax)

```plantuml
@startuml
title Database Schema

entity "users" {
    * id : UUID <<PK>>
    --
    * email : VARCHAR(255)
    * name : VARCHAR(100)
    created_at : TIMESTAMP
}

entity "orders" {
    * id : UUID <<PK>>
    --
    * user_id : UUID <<FK>>
    * status : VARCHAR(20)
    * total : DECIMAL(10,2)
    created_at : TIMESTAMP
}

users ||--o{ orders : places

@enduml
```

## JSON and YAML visualization

```plantuml
@startjson
title API Response Structure
{
    "order": {
        "id": "abc-123",
        "status": "confirmed",
        "items": [
            {"product": "Widget", "qty": 2},
            {"product": "Gadget", "qty": 1}
        ]
    }
}
@endjson
```
