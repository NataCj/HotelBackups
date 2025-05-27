CREATE OR REPLACE FUNCTION hotel.calc_detail_reservation() RETURNS trigger AS $$
DECLARE
    d_percent NUMERIC;
    subtotal_base NUMERIC;
    discount_val NUMERIC;
BEGIN
    IF NEW.quantity IS NULL THEN
        RAISE EXCEPTION 'Cantidad no puede ser nula';
    END IF;

    d_percent := NEW.discount / 100.0;
    subtotal_base := NEW.price * NEW.quantity;
    discount_val := ROUND(subtotal_base * d_percent, 2);

    NEW.discount_value := discount_val;
    NEW.subtotal := subtotal_base - discount_val;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para BEFORE INSERT o UPDATE en detail_reservation
CREATE TRIGGER trg_calc_detail_reservation
BEFORE INSERT OR UPDATE ON hotel.detail_reservation
FOR EACH ROW EXECUTE FUNCTION hotel.calc_detail_reservation();

-- 2. Calcular subtotal en detail_service
CREATE OR REPLACE FUNCTION hotel.calc_detail_service() RETURNS trigger AS $$
BEGIN
    IF NEW.quantity IS NULL THEN
        RAISE EXCEPTION 'Cantidad no puede ser nula';
    END IF;

    NEW.sub_total := NEW.price * NEW.quantity;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para BEFORE INSERT o UPDATE en detail_service
CREATE TRIGGER trg_calc_detail_service
BEFORE INSERT OR UPDATE ON hotel.detail_service
FOR EACH ROW EXECUTE FUNCTION hotel.calc_detail_service();

-- Parte 3: Actualizar total en reservation con los subtotales de detail_reservation y detail_service
CREATE OR REPLACE FUNCTION hotel.update_reservation_total() RETURNS trigger AS $$
DECLARE
    total_rsv NUMERIC := 0;
    total_srv NUMERIC := 0;
BEGIN
    SELECT COALESCE(SUM(subtotal), 0) INTO total_rsv FROM hotel.detail_reservation WHERE rsv_id = NEW.rsv_id;
    SELECT COALESCE(SUM(sub_total), 0) INTO total_srv FROM hotel.detail_service WHERE rsv_id = NEW.rsv_id;

    UPDATE hotel.reservation
    SET total = total_rsv + total_srv
    WHERE id = NEW.rsv_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar el total en reservation luego de cambios en detail_reservation
CREATE TRIGGER trg_update_total_from_detail_reservation
AFTER INSERT OR UPDATE ON hotel.detail_reservation
FOR EACH ROW EXECUTE FUNCTION hotel.update_reservation_total();

-- Trigger para actualizar el total en reservation luego de cambios en detail_service
CREATE TRIGGER trg_update_total_from_detail_service
AFTER INSERT OR UPDATE ON hotel.detail_service
FOR EACH ROW EXECUTE FUNCTION hotel.update_reservation_total();
