# Styling

## Modern `<style>` blocks (preferred)

Use CSS-like `<style>` blocks instead of legacy `skinparam`. Place the style block immediately after `@startuml`:

```plantuml
@startuml
title Styled Sequence Diagram

<style>
    sequenceDiagram {
        actor {
            BackgroundColor #E8F5E9
            BorderColor #2E7D32
        }
        participant {
            BackgroundColor #E3F2FD
            BorderColor #1565C0
        }
        arrow {
            LineColor #333333
        }
        note {
            BackgroundColor #FFF9C4
            BorderColor #F9A825
        }
    }
</style>

actor Customer
participant "Order Service" as OS
...
@enduml
```

## Built-in themes

PlantUML ships with themes. Use `!theme` to apply one:

```plantuml
@startuml
!theme cerulean
title Themed Diagram
...
@enduml
```

Common themes: `cerulean`, `plain`, `sketchy-outline`, `aws-orange`, `mars`, `minty`. Preview themes before committing to one.

## Color formats

- Named colors: `Red`, `LightBlue`, `DarkGreen`
- Hex: `#FF5733`, `#2196F3`
- Gradients: `#White/#LightBlue` (top to bottom)

## Layout direction

Default is top-to-bottom. For wide diagrams with many horizontal relationships:

```plantuml
left to right direction
```

Add this immediately after `@startuml` (before any elements).
