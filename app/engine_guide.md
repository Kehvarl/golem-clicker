# Engine Guide
## Overview
This engine is a lightweight, location-aware clicker framework built around:
- Resources
- Buttons
- Actors
- Locations
- A deterministic tick loop

It is convention-driven. Behavior is implemented via method naming.
The engine does not impose genre. It provides structure.

---
## Core Concepts
### 1. Locations

The engine supports multi-location gameplay.
Each button and actor may define:
- `location:` — Only ticks/renders when player is in this location
- `always_tick:` — Ticks regardless of location

The current location is stored in: `@location`

Changing location affects:
- What renders
- What ticks
- What can be interacted with

No additional game logic is required to enforce spatial rules.

---
### 2. Resources

Resources are numeric tracked values.

Register with:
```ruby
register_resource(:sanity, initial: 100)
```

Access with:
```ruby
resource(:sanity)
```

Modify with:
```ruby
modify_resource(:sanity, -1)
```

Resources render automatically unless explicitly hidden.

---
### 3. Buttons

Buttons represent player actions.

Register with:
```ruby
create_button(
  :explore,
  label: "Explore",
  location: :hall
)
```

Buttons dispatch by convention:
```ruby
explore_clicked
```

Optional:
```
explore_tick
```

Buttons may be:
- revealed
- hidden
- location-bound

Revealed state is preserved across location changes.

---
### 4. Actors

Actors are autonomous entities.

Register with:
```ruby
create_actor(
  :ghost,
  location: :room
)
```

Actors dispatch:
```ruby
ghost_tick
```

They respect:
- location
- always_tick

Actors are ideal for:
- passive decay
- timed events
- environmental behavior
- AI-like systems

---
## Tick Order

Each frame:
- Actors tick
- Buttons tick
- Input is processed

If @running == false, ticking is skipped.
Rendering occurs after the update phase and respects location visibility.
---

## Method Dispatch Model
Behavior is defined by naming convention.

If you register:
```ruby
create_button(:explore)
```

Then implement:
```
def explore_clicked
end
```

The engine will automatically dispatch it.

No manual wiring required.
---

## Philosophy

This engine is:
- Small
- Deterministic
- Explicit
- Location-aware

It avoids:
- Hidden magic
- Deep inheritance trees
- Callback hell
- Data-driven overengineering

The goal is clarity over abstraction.
---

## Example Minimal Game
```ruby
register_resource(:sanity, initial: 100)

create_button(:explore, label: "Explore", location: :hall)

def explore_clicked
  modify_resource(:sanity, -5)
  @location = :room
end
```

That is sufficient to create a spatial action.
---

## Extending the Engine

Future-friendly additions:
- Tick radius / adjacency graph
- Multi-location visibility lists
- Save/load serialization
- Content DSL layer
