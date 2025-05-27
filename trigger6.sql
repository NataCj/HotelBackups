-- Función que asigna el precio del servicio y calcula el sub_total
CREATE OR REPLACE FUNCTION hotel.set_service_price_and_subtotal() RETURNS trigger AS $$
DECLARE
    svc_price NUMERIC;
    svc_subtotal NUMERIC;
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

    -- Verificar cantidad válida
    IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'Cantidad inválida para servicio con ID %', NEW.srv_id;
    END IF;

    -- Calcular el subtotal
    svc_subtotal := svc_price * NEW.quantity;
    NEW.sub_total := svc_subtotal;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que ejecuta la función antes de insertar o actualizar
CREATE TRIGGER trg_set_service_price_and_subtotal
BEFORE INSERT OR UPDATE ON hotel.detail_service
FOR EACH ROW EXECUTE FUNCTION hotel.set_service_price_and_subtotal();
