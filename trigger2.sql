-- Función para copiar el price desde la tabla hotel.service
CREATE OR REPLACE FUNCTION hotel.set_service_price() RETURNS trigger AS $$
DECLARE
    svc_price NUMERIC;
BEGIN
    -- Obtener el precio del servicio desde la tabla service
    SELECT price INTO svc_price
    FROM hotel.service
    WHERE id = NEW.srv_id;

    -- Validar que se encontró el servicio
    IF svc_price IS NULL THEN
        RAISE EXCEPTION 'Servicio con ID % no encontrado.', NEW.srv_id;
    END IF;

    -- Asignar el precio al registro de detail_service
    NEW.price := svc_price;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que ejecuta la función antes de insertar o actualizar
CREATE TRIGGER trg_set_service_price
BEFORE INSERT OR UPDATE ON hotel.detail_service
FOR EACH ROW EXECUTE FUNCTION hotel.set_service_price();
