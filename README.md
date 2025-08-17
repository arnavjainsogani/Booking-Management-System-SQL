# Booking Management Database System


## Highlights
- Normalized schema: users, properties, bookings, payments, reviews
- **Exclusion constraint** (with `btree_gist`) prevents double bookings at the DB level
- Availability search, revenue analytics, and host/guest leaderboards
- PL/pgSQL function to attempt bookings + trigger to auto-cancel overlapping *pending* requests
- Ready-to-run scripts: `schema.sql`, `seed.sql`, `functions_and_triggers.sql`, `queries/analytics.sql`

---

## Requirements
- PostgreSQL 13+
- `psql` CLI
- Ability to create extensions (`btree_gist`)
---

## Quickstart

```bash
# 1) Create a database (local example)
createdb airbnb_sql_db

# 2) Load schema and functions
psql -d airbnb_sql_db -f db/schema.sql
psql -d airbnb_sql_db -f db/functions_and_triggers.sql

# 3) Load sample data
psql -d airbnb_sql_db -f db/seed.sql

# 4) Run analytics queries
psql -d airbnb_sql_db -f queries/analytics.sql

# 5) Try booking via function (in psql)
-- Example:
-- SELECT attempt_booking( property_id := 1, p_guest_id := 2, p_start := DATE '2025-09-03', p_end := DATE '2025-09-06' );
```
If a conflicting confirmed booking exists, the function raises an error; otherwise it inserts and returns the new `booking_id`.

---

## 📂 Files

```
db/
  schema.sql                  
  seed.sql                  
  functions_and_triggers.sql   
queries/
  analytics.sql                
README.md
```
