-- db/functions_and_triggers.sql
-- PL/pgSQL function + trigger logic

-- Function: attempt a booking; raises exception if conflict exists; returns new booking_id on success
CREATE OR REPLACE FUNCTION attempt_booking(
    property_id BIGINT,
    p_guest_id  BIGINT,
    p_start     DATE,
    p_end       DATE
) RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    new_id BIGINT;
BEGIN
    IF p_start > p_end THEN
        RAISE EXCEPTION 'start_date % cannot be after end_date %', p_start, p_end
            USING ERRCODE = '22007';  -- invalid_datetime_format
    END IF;

    -- Conflict check against confirmed bookings
    IF EXISTS (
        SELECT 1 FROM bookings
        WHERE bookings.property_id = attempt_booking.property_id
          AND status = 'confirmed'
          AND daterange(start_date, end_date, '[]') && daterange(p_start, p_end, '[]')
    ) THEN
        RAISE EXCEPTION 'Booking conflict detected for property % in % to %',
            attempt_booking.property_id, p_start, p_end
            USING ERRCODE = '23P01';  -- exclusion_violation-ish
    END IF;

    INSERT INTO bookings(property_id, guest_id, start_date, end_date, status)
    VALUES (attempt_booking.property_id, p_guest_id, p_start, p_end, 'confirmed')
    RETURNING booking_id INTO new_id;

    RETURN new_id;
END;
$$;

-- Trigger: when a booking is confirmed, auto-cancel overlapping pending ones for same property
CREATE OR REPLACE FUNCTION cancel_pending_overlaps() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'confirmed' THEN
        UPDATE bookings
        SET status = 'cancelled'
        WHERE property_id = NEW.property_id
          AND booking_id <> NEW.booking_id
          AND status = 'pending'
          AND daterange(start_date, end_date, '[]') && daterange(NEW.start_date, NEW.end_date, '[]');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cancel_pending_overlaps ON bookings;
CREATE TRIGGER trg_cancel_pending_overlaps
AFTER UPDATE OF status ON bookings
FOR EACH ROW
EXECUTE FUNCTION cancel_pending_overlaps();
