-- db/seed.sql
-- Sample data for quick testing

-- Users (2 hosts, 2 guests)
INSERT INTO users (name, email, role) VALUES
('Alice',   'alice@example.com',   'host'),
('Charlie', 'charlie@example.com', 'host'),
('Bob',     'bob@example.com',     'guest'),
('Diana',   'diana@example.com',   'guest')
ON CONFLICT (email) DO NOTHING;

-- Properties
-- Need to map host IDs by email (portable across DBs)
WITH host_ids AS (
    SELECT user_id, email FROM users WHERE role = 'host'
)
INSERT INTO properties (host_id, title, location, price_per_night) VALUES
((SELECT user_id FROM host_ids WHERE email='alice@example.com'),   'Cozy Apartment',  'New York', 120.00),
((SELECT user_id FROM host_ids WHERE email='charlie@example.com'), 'Beach House',     'Miami',    250.00),
((SELECT user_id FROM host_ids WHERE email='alice@example.com'),   'Mountain Cabin',  'Denver',   150.00)
ON CONFLICT DO NOTHING;

-- Guests lookup CTE
WITH guest_ids AS (
    SELECT user_id, email FROM users WHERE role = 'guest'
)
-- Bookings: one confirmed, one pending
INSERT INTO bookings (property_id, guest_id, start_date, end_date, status) VALUES
((SELECT property_id FROM properties WHERE title='Cozy Apartment'),    (SELECT user_id FROM guest_ids WHERE email='bob@example.com'),   DATE '2025-09-01', DATE '2025-09-05', 'confirmed'),
((SELECT property_id FROM properties WHERE title='Beach House'),       (SELECT user_id FROM guest_ids WHERE email='diana@example.com'), DATE '2025-09-10', DATE '2025-09-15', 'pending')
RETURNING *;

-- Payments (for the confirmed booking above)
INSERT INTO payments (booking_id, amount, method)
SELECT b.booking_id, (b.end_date - b.start_date) * p.price_per_night, 'card'
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.status = 'confirmed'
ON CONFLICT DO NOTHING;

-- Reviews
INSERT INTO reviews (property_id, guest_id, rating, comment)
SELECT
    (SELECT property_id FROM properties WHERE title='Cozy Apartment'),
    (SELECT user_id FROM users WHERE email='bob@example.com'),
    5, 'Amazing stay, highly recommended!'
ON CONFLICT DO NOTHING;

INSERT INTO reviews (property_id, guest_id, rating, comment)
SELECT
    (SELECT property_id FROM properties WHERE title='Beach House'),
    (SELECT user_id FROM users WHERE email='diana@example.com'),
    4, 'Beautiful house, but a bit pricey.'
ON CONFLICT DO NOTHING;
