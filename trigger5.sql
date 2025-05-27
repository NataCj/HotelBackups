-- Función que asigna el precio de la habitación y calcula discount_value y subtotal
CREATE OR REPLACE FUNCTION hotel.set_price_and_calc_subtotal() RETURNS trigger AS $$
DECLARE
    tipo_id VARCHAR(3);
    precio NUMERIC(10,2);
    subtotal_base NUMERIC;
    descuento_valor NUMERIC;
BEGIN
    -- Obtener el tipo de habitación desde la tabla room
    SELECT rom_typ_id INTO tipo_id
    FROM hotel.room
    WHERE id = NEW.room_id;

    IF tipo_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró tipo de habitación para room_id %', NEW.room_id;
    END IF;

    -- Obtener el precio desde la tabla room_type
    SELECT price_per_night INTO precio
    FROM hotel.room_type
    WHERE id = tipo_id;

    IF precio IS NULL THEN
        RAISE EXCEPTION 'No se encontró precio para el tipo de habitación %', tipo_id;
    END IF;

    -- Asignar el precio
    NEW.price := precio;

    -- Verificación de cantidad
    IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'Cantidad inválida para room_id %', NEW.room_id;
    END IF;

    -- Calcular subtotal base
    subtotal_base := precio * NEW.quantity;

    -- Calcular descuento (como porcentaje)
    descuento_valor := ROUND(subtotal_base * (NEW.discount / 100.0), 2);

    -- Asignar valores calculados
    NEW.discount_value := descuento_valor;
    NEW.subtotal := subtotal_base - descuento_valor;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trg_set_price_and_calc_subtotal
BEFORE INSERT OR UPDATE ON hotel.detail_reservation
FOR EACH ROW EXECUTE FUNCTION hotel.set_price_and_calc_subtotal();
