-- db/schema.sql
-- PostgreSQL schema for Airbnb-style booking system

-- Enable extension for exclusion constraints combining equality and ranges
-- Comment this line if your host disallows it, and rely on the trigger/function checks.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- USERS
CREATE TABLE IF NOT EXISTS users (
    user_id        BIGSERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    email          VARCHAR(150) UNIQUE NOT NULL,
    role           VARCHAR(20)  NOT NULL CHECK (role IN ('guest','host')),
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- PROPERTIES
CREATE TABLE IF NOT EXISTS properties (
    property_id     BIGSERIAL PRIMARY KEY,
    host_id         BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    location        VARCHAR(120) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL CHECK (price_per_night >= 0),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- BOOKINGS
CREATE TABLE IF NOT EXISTS bookings (
    booking_id  BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
    guest_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','cancelled')),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (start_date <= end_date)
);

-- PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
    payment_id   BIGSERIAL PRIMARY KEY,
    booking_id   BIGINT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    amount       NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    method       VARCHAR(30) NOT NULL CHECK (method IN ('card','paypal','upi'))
);

-- REVIEWS
CREATE TABLE IF NOT EXISTS reviews (
    review_id   BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
    guest_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_properties_host ON properties(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property_dates ON bookings(property_id, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_guest ON bookings(guest_id);
CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_property ON reviews(property_id);

-- Prevent overlapping CONFIRMED bookings for the same property (DB-level guarantee)
-- Requires btree_gist extension above.
ALTER TABLE bookings
    DROP CONSTRAINT IF EXISTS no_overlap_per_property;

ALTER TABLE bookings
    ADD CONSTRAINT no_overlap_per_property
    EXCLUDE USING gist (
        property_id WITH =,
        daterange(start_date, end_date, '[]') WITH &&
    )
    WHERE (status = 'confirmed');
