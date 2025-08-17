# Airbnb-Style Property Booking Database (PostgreSQL)

A resume-ready **SQL-only** project showcasing relational modeling, advanced constraints, analytics queries, and PL/pgSQL functions/triggers for an Airbnb-style booking system.

## ✨ Highlights
- Normalized schema: users, properties, bookings, payments, reviews
- **Exclusion constraint** (with `btree_gist`) prevents double bookings at the DB level
- Availability search, revenue analytics, and host/guest leaderboards
- PL/pgSQL function to attempt bookings + trigger to auto-cancel overlapping *pending* requests
- Ready-to-run scripts: `schema.sql`, `seed.sql`, `functions_and_triggers.sql`, `queries/analytics.sql`

---

## 🧰 Requirements
- PostgreSQL 13+
- `psql` CLI
- Ability to create extensions (`btree_gist`)

> If you're using a hosted Postgres (Supabase/Render), ensure `btree_gist` is allowed.
> If not, comment out the exclusion constraint in `schema.sql` (it's clearly marked).

---

## 🚀 Quickstart

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
  schema.sql                   # Tables, indexes, exclusion constraint
  seed.sql                     # Sample users, properties, bookings, payments, reviews
  functions_and_triggers.sql   # PL/pgSQL function + trigger to enforce rules
queries/
  analytics.sql                # Availability, revenue, occupancy, rating analytics
README.md
```

---

## 🧪 Tips for Demo / Resume
- Export an ERD (DBeaver / dbdiagram.io) and add to repo images.
- Screenshot query results (availability & revenue) and add to README.
- If your host disallows `btree_gist`, keep a branch with the exclusion constraint commented + extra trigger that checks conflicts.
