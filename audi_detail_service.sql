CREATE TABLE hotel.audi_detail_service (
    consecutivo SERIAL PRIMARY KEY,
    srv_id INTEGER,
    line_item_id INTEGER,
    rsv_id INTEGER,
    price NUMERIC(10,2),
    quantity INTEGER,
    sub_total NUMERIC(10,2),
    fecha_registro TIMESTAMP,
    usuario VARCHAR(50),
    accion CHAR(1)
);

CREATE OR REPLACE FUNCTION hotel.audi_detail_service_func() RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO hotel.audi_detail_service (
            srv_id, line_item_id, rsv_id, price, quantity, sub_total,
            fecha_registro, usuario, accion
        )
        VALUES (
            OLD.srv_id, OLD.line_item_id, OLD.rsv_id, OLD.price, OLD.quantity, OLD.sub_total,
            current_timestamp(0), current_user, 'U'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO hotel.audi_detail_service (
            srv_id, line_item_id, rsv_id, price, quantity, sub_total,
            fecha_registro, usuario, accion
        )
        VALUES (
            OLD.srv_id, OLD.line_item_id, OLD.rsv_id, OLD.price, OLD.quantity, OLD.sub_total,
            current_timestamp(0), current_user, 'D'
        );
        RETURN OLD;
    END IF;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audi_detail_service
BEFORE UPDATE OR DELETE ON hotel.detail_service
FOR EACH ROW EXECUTE FUNCTION hotel.audi_detail_service_func();
