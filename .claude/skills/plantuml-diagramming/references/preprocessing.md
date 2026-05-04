# Preprocessing

## !include

Split large diagrams or share common definitions across files:

```plantuml
!include common/styles.puml
!include common/actors.puml
```

Use relative paths. Keep shared definitions (themes, common participants, standard styles) in a `common/` or `shared/` directory.

## !procedure

Reusable diagram fragments:

```plantuml
!procedure $service($name, $alias)
    participant "$name" as $alias
!endprocedure

$service("Order Service", OS)
$service("Payment Service", PS)
```

## !function

Reusable computed values:

```plantuml
!function $endpoint($service, $path)
    !return $service + " " + $path
!endfunction
```

## Variables

```plantuml
!$primary_color = "#1565C0"
!$secondary_color = "#2E7D32"
```

## Conditionals and loops

```plantuml
!if (%getenv("DETAIL_LEVEL") == "high")
    class Order {
        - id: UUID
        - status: OrderStatus
        + addItem(product: Product, qty: int)
    }
!else
    rectangle "Order Service"
!endif

!$i = 0
!while ($i < 3)
    node "Worker $i"
    !$i = $i + 1
!endwhile
```
