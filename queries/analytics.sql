-- queries/analytics.sql
\echo '--- Available properties (2025-09-02 to 2025-09-04) ---'
WITH params AS (
  SELECT DATE '2025-09-02' AS start_date, DATE '2025-09-04' AS end_date
)
SELECT p.property_id, p.title, p.location, p.price_per_night
FROM properties p, params x
WHERE NOT EXISTS (
  SELECT 1
  FROM bookings b
  WHERE b.property_id = p.property_id
    AND b.status = 'confirmed'
    AND daterange(b.start_date, b.end_date, '[]') && daterange(x.start_date, x.end_date, '[]')
)
ORDER BY p.location, p.title;

\echo '--- Booking conflicts among confirmed bookings (should be none if exclusion constraint is active) ---'
SELECT b1.booking_id AS b_a, b2.booking_id AS b_b, p.title, b1.start_date AS a_start, b1.end_date AS a_end, b2.start_date AS b_start, b2.end_date AS b_end
FROM bookings b1
JOIN bookings b2
  ON b1.property_id = b2.property_id
 AND b1.booking_id < b2.booking_id
 AND b1.status = 'confirmed' AND b2.status = 'confirmed'
JOIN properties p ON p.property_id = b1.property_id
WHERE daterange(b1.start_date, b1.end_date, '[]') && daterange(b2.start_date, b2.end_date, '[]');

\echo '--- Revenue per property (confirmed bookings only) ---'
SELECT p.title, SUM(pay.amount) AS total_revenue
FROM payments pay
JOIN bookings b ON pay.booking_id = b.booking_id
JOIN properties p ON b.property_id = p.property_id
WHERE b.status = 'confirmed'
GROUP BY p.title
ORDER BY total_revenue DESC NULLS LAST;

\echo '--- Average rating per property ---'
SELECT p.title, ROUND(AVG(r.rating)::numeric, 2) AS avg_rating, COUNT(*) AS review_count
FROM reviews r
JOIN properties p ON p.property_id = r.property_id
GROUP BY p.title
ORDER BY avg_rating DESC, review_count DESC;

\echo '--- Occupancy days per property (sum of confirmed nights) ---'
SELECT p.title,
       SUM( (b.end_date - b.start_date) ) AS nights_booked
FROM properties p
LEFT JOIN bookings b
  ON b.property_id = p.property_id
 AND b.status = 'confirmed'
GROUP BY p.title
ORDER BY nights_booked DESC NULLS LAST;

\echo '--- Top hosts by revenue ---'
SELECT u.name AS host, SUM(pay.amount) AS revenue
FROM users u
JOIN properties p ON p.host_id = u.user_id
JOIN bookings b ON b.property_id = p.property_id AND b.status = 'confirmed'
JOIN payments pay ON pay.booking_id = b.booking_id
GROUP BY u.name
ORDER BY revenue DESC NULLS LAST;
