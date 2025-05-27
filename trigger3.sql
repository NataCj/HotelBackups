-- Función para establecer el precio desde room_type según el room_id
CREATE OR REPLACE FUNCTION hotel.set_room_price() RETURNS trigger AS $$
DECLARE
    tipo_id VARCHAR(3);
    precio NUMERIC(10,2);
BEGIN
    -- Obtener el tipo de habitación (rom_typ_id) desde hotel.room
    SELECT rom_typ_id INTO tipo_id
    FROM hotel.room
    WHERE id = NEW.room_id;

    IF tipo_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró tipo de habitación para room_id %', NEW.room_id;
    END IF;

    -- Obtener el precio del tipo de habitación
    SELECT price_per_night INTO precio
    FROM hotel.room_type
    WHERE id = tipo_id;

    IF precio IS NULL THEN
        RAISE EXCEPTION 'No se encontró precio para room_type_id %', tipo_id;
    END IF;

    -- Asignar el precio al campo price
    NEW.price := precio;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger para antes de insertar o actualizar
CREATE TRIGGER trg_set_room_price
BEFORE INSERT OR UPDATE ON hotel.detail_reservation
FOR EACH ROW EXECUTE FUNCTION hotel.set_room_price();
