CREATE TABLE hotel.audi_detail_reservation (
    consecutivo SERIAL PRIMARY KEY,
    rsv_id INTEGER,
    line_item_id INTEGER,
    room_id INTEGER,
    price NUMERIC(10,2),
    quantity INTEGER,
    check_in DATE,
    check_out DATE,
    discount NUMERIC(10,2),
    discount_value NUMERIC(10,2),
    subtotal NUMERIC(10,2),
    fecha_registro TIMESTAMP,
    usuario VARCHAR(50),
    accion CHAR(1)
);

CREATE OR REPLACE FUNCTION hotel.audi_detail_reservation_func() RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO hotel.audi_detail_reservation (
            rsv_id, line_item_id, room_id, price, quantity,
            check_in, check_out, discount, discount_value, subtotal,
            fecha_registro, usuario, accion
        )
        VALUES (
            OLD.rsv_id, OLD.line_item_id, OLD.room_id, OLD.price, OLD.quantity,
            OLD.check_in, OLD.check_out, OLD.discount, OLD.discount_value, OLD.subtotal,
            current_timestamp(0), current_user, 'U'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO hotel.audi_detail_reservation (
            rsv_id, line_item_id, room_id, price, quantity,
            check_in, check_out, discount, discount_value, subtotal,
            fecha_registro, usuario, accion
        )
        VALUES (
            OLD.rsv_id, OLD.line_item_id, OLD.room_id, OLD.price, OLD.quantity,
            OLD.check_in, OLD.check_out, OLD.discount, OLD.discount_value, OLD.subtotal,
            current_timestamp(0), current_user, 'D'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audi_detail_reservation
BEFORE UPDATE OR DELETE ON hotel.detail_reservation
FOR EACH ROW EXECUTE FUNCTION hotel.audi_detail_reservation_func();
