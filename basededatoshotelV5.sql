toc.dat                                                                                             0000600 0004000 0002000 00000137565 15015342721 0014460 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP   4        	            }            Hotel    17.4    17.4 �    n           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false         o           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false         p           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false         q           1262    33272    Hotel    DATABASE     m   CREATE DATABASE "Hotel" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'es-MX';
    DROP DATABASE "Hotel";
                     postgres    false                     2615    33273    hotel    SCHEMA        CREATE SCHEMA hotel;
    DROP SCHEMA hotel;
                     postgres    false                    1255    49280    audi_detail_reservation_func()    FUNCTION     �  CREATE FUNCTION hotel.audi_detail_reservation_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 4   DROP FUNCTION hotel.audi_detail_reservation_func();
       hotel               postgres    false    6         �            1255    49271    audi_detail_service_func()    FUNCTION     �  CREATE FUNCTION hotel.audi_detail_service_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

$$;
 0   DROP FUNCTION hotel.audi_detail_service_func();
       hotel               postgres    false    6         �            1255    41242    calc_detail_reservation()    FUNCTION     !  CREATE FUNCTION hotel.calc_detail_reservation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 /   DROP FUNCTION hotel.calc_detail_reservation();
       hotel               postgres    false    6         �            1255    41244    calc_detail_service()    FUNCTION       CREATE FUNCTION hotel.calc_detail_service() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.quantity IS NULL THEN
        RAISE EXCEPTION 'Cantidad no puede ser nula';
    END IF;

    NEW.sub_total := NEW.price * NEW.quantity;
    RETURN NEW;
END;
$$;
 +   DROP FUNCTION hotel.calc_detail_service();
       hotel               postgres    false    6                    1255    41264    set_price_and_calc_subtotal()    FUNCTION     7  CREATE FUNCTION hotel.set_price_and_calc_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 3   DROP FUNCTION hotel.set_price_and_calc_subtotal();
       hotel               postgres    false    6         �            1255    41262    set_room_price()    FUNCTION       CREATE FUNCTION hotel.set_room_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 &   DROP FUNCTION hotel.set_room_price();
       hotel               postgres    false    6         �            1255    41260    set_service_price()    FUNCTION       CREATE FUNCTION hotel.set_service_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 )   DROP FUNCTION hotel.set_service_price();
       hotel               postgres    false    6         �            1255    41266     set_service_price_and_subtotal()    FUNCTION     e  CREATE FUNCTION hotel.set_service_price_and_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 6   DROP FUNCTION hotel.set_service_price_and_subtotal();
       hotel               postgres    false    6         �            1255    41246    update_reservation_total()    FUNCTION     �  CREATE FUNCTION hotel.update_reservation_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 0   DROP FUNCTION hotel.update_reservation_total();
       hotel               postgres    false    6         �            1259    41206 	   agreement    TABLE     �   CREATE TABLE hotel.agreement (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200),
    start_date date NOT NULL,
    end_date date NOT NULL
);
    DROP TABLE hotel.agreement;
       hotel         heap r       postgres    false    6         �            1259    41205    agreement_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.agreement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE hotel.agreement_id_seq;
       hotel               postgres    false    235    6         r           0    0    agreement_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE hotel.agreement_id_seq OWNED BY hotel.agreement.id;
          hotel               postgres    false    234         �            1259    49274    audi_detail_reservation    TABLE     �  CREATE TABLE hotel.audi_detail_reservation (
    consecutivo integer NOT NULL,
    rsv_id integer,
    line_item_id integer,
    room_id integer,
    price numeric(10,2),
    quantity integer,
    check_in date,
    check_out date,
    discount numeric(10,2),
    discount_value numeric(10,2),
    subtotal numeric(10,2),
    fecha_registro timestamp without time zone,
    usuario character varying(50),
    accion character(1)
);
 *   DROP TABLE hotel.audi_detail_reservation;
       hotel         heap r       postgres    false    6         �            1259    49273 '   audi_detail_reservation_consecutivo_seq    SEQUENCE     �   CREATE SEQUENCE hotel.audi_detail_reservation_consecutivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE hotel.audi_detail_reservation_consecutivo_seq;
       hotel               postgres    false    6    243         s           0    0 '   audi_detail_reservation_consecutivo_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE hotel.audi_detail_reservation_consecutivo_seq OWNED BY hotel.audi_detail_reservation.consecutivo;
          hotel               postgres    false    242         �            1259    49265    audi_detail_service    TABLE     G  CREATE TABLE hotel.audi_detail_service (
    consecutivo integer NOT NULL,
    srv_id integer,
    line_item_id integer,
    rsv_id integer,
    price numeric(10,2),
    quantity integer,
    sub_total numeric(10,2),
    fecha_registro timestamp without time zone,
    usuario character varying(50),
    accion character(1)
);
 &   DROP TABLE hotel.audi_detail_service;
       hotel         heap r       postgres    false    6         �            1259    49264 #   audi_detail_service_consecutivo_seq    SEQUENCE     �   CREATE SEQUENCE hotel.audi_detail_service_consecutivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE hotel.audi_detail_service_consecutivo_seq;
       hotel               postgres    false    6    241         t           0    0 #   audi_detail_service_consecutivo_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE hotel.audi_detail_service_consecutivo_seq OWNED BY hotel.audi_detail_service.consecutivo;
          hotel               postgres    false    240         �            1259    33301    city    TABLE     �   CREATE TABLE hotel.city (
    id character varying(3) NOT NULL,
    dpt_id character varying(3) NOT NULL,
    cty_id character varying(3) NOT NULL,
    name character varying(60) NOT NULL
);
    DROP TABLE hotel.city;
       hotel         heap r       postgres    false    6         �            1259    33286    country    TABLE     e   CREATE TABLE hotel.country (
    id character varying(3) NOT NULL,
    name character varying(60)
);
    DROP TABLE hotel.country;
       hotel         heap r       postgres    false    6         �            1259    41137    customer    TABLE     x  CREATE TABLE hotel.customer (
    id character varying(15) NOT NULL,
    dct_typ_id character varying(2),
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    second_last_name character varying(50),
    birth_date date NOT NULL,
    gender character(1) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    prf_id character varying(4) NOT NULL,
    city_id character varying(3) NOT NULL,
    departament_id character varying(3) NOT NULL,
    country_id character varying(3) NOT NULL,
    destination_city_id character varying(3) NOT NULL,
    destination_departament_id character varying(3) NOT NULL,
    destination_country_id character varying(3) NOT NULL,
    CONSTRAINT chk_cst_gender CHECK ((gender = ANY (ARRAY['M'::bpchar, 'F'::bpchar, 'O'::bpchar])))
);
    DROP TABLE hotel.customer;
       hotel         heap r       postgres    false    6         �            1259    33291 
   department    TABLE     �   CREATE TABLE hotel.department (
    id character varying(3) NOT NULL,
    cty_id character varying(3) NOT NULL,
    name character varying(60) NOT NULL
);
    DROP TABLE hotel.department;
       hotel         heap r       postgres    false    6         �            1259    41185    detail_reservation    TABLE     �  CREATE TABLE hotel.detail_reservation (
    rsv_id integer NOT NULL,
    line_item_id integer NOT NULL,
    room_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    check_in date NOT NULL,
    check_out date NOT NULL,
    discount numeric(10,2) DEFAULT 0,
    discount_value numeric(10,2) DEFAULT 0,
    subtotal numeric(10,2) NOT NULL,
    CONSTRAINT chk_dtl_rsv_quantity CHECK ((quantity > 0))
);
 %   DROP TABLE hotel.detail_reservation;
       hotel         heap r       postgres    false    6         �            1259    41184 #   detail_reservation_line_item_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.detail_reservation_line_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE hotel.detail_reservation_line_item_id_seq;
       hotel               postgres    false    6    233         u           0    0 #   detail_reservation_line_item_id_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE hotel.detail_reservation_line_item_id_seq OWNED BY hotel.detail_reservation.line_item_id;
          hotel               postgres    false    232         �            1259    41225    detail_service    TABLE     &  CREATE TABLE hotel.detail_service (
    srv_id integer NOT NULL,
    line_item_id integer NOT NULL,
    rsv_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    sub_total numeric(10,2) NOT NULL,
    CONSTRAINT chk_dtl_srv_quantity CHECK ((quantity > 0))
);
 !   DROP TABLE hotel.detail_service;
       hotel         heap r       postgres    false    6         �            1259    41224    detail_service_line_item_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.detail_service_line_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE hotel.detail_service_line_item_id_seq;
       hotel               postgres    false    239    6         v           0    0    detail_service_line_item_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE hotel.detail_service_line_item_id_seq OWNED BY hotel.detail_service.line_item_id;
          hotel               postgres    false    238         �            1259    33281    document_type    TABLE     t   CREATE TABLE hotel.document_type (
    id character varying(3) NOT NULL,
    name character varying(50) NOT NULL
);
     DROP TABLE hotel.document_type;
       hotel         heap r       postgres    false    6         �            1259    33342    hotel    TABLE     �   CREATE TABLE hotel.hotel (
    id character varying(4) NOT NULL,
    name character varying(50) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    total_rooms integer NOT NULL
);
    DROP TABLE hotel.hotel;
       hotel         heap r       postgres    false    6         �            1259    33274 
   profession    TABLE     �   CREATE TABLE hotel.profession (
    id character varying(4) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200)
);
    DROP TABLE hotel.profession;
       hotel         heap r       postgres    false    6         �            1259    41168    reservation    TABLE     $  CREATE TABLE hotel.reservation (
    id integer NOT NULL,
    status character varying(50) NOT NULL,
    reservation_source character varying(50) NOT NULL,
    date date NOT NULL,
    total numeric(10,2) NOT NULL,
    cst_id character varying(15) NOT NULL,
    stf_id character varying(5)
);
    DROP TABLE hotel.reservation;
       hotel         heap r       postgres    false    6         �            1259    41167    reservation_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE hotel.reservation_id_seq;
       hotel               postgres    false    6    231         w           0    0    reservation_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE hotel.reservation_id_seq OWNED BY hotel.reservation.id;
          hotel               postgres    false    230         �            1259    33348    room    TABLE     �   CREATE TABLE hotel.room (
    id integer NOT NULL,
    rom_typ_id character varying(3) NOT NULL,
    htl_id character varying(4) NOT NULL
);
    DROP TABLE hotel.room;
       hotel         heap r       postgres    false    6         �            1259    33347    room_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE hotel.room_id_seq;
       hotel               postgres    false    6    226         x           0    0    room_id_seq    SEQUENCE OWNED BY     9   ALTER SEQUENCE hotel.room_id_seq OWNED BY hotel.room.id;
          hotel               postgres    false    225         �            1259    33337 	   room_type    TABLE     �   CREATE TABLE hotel.room_type (
    id character varying(3) NOT NULL,
    name character varying(50) NOT NULL,
    price_per_night numeric(10,2) NOT NULL,
    description character varying(200)
);
    DROP TABLE hotel.room_type;
       hotel         heap r       postgres    false    6         �            1259    41213    service    TABLE     �   CREATE TABLE hotel.service (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    price numeric(10,2) NOT NULL,
    agr_id integer NOT NULL
);
    DROP TABLE hotel.service;
       hotel         heap r       postgres    false    6         �            1259    41212    service_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE hotel.service_id_seq;
       hotel               postgres    false    6    237         y           0    0    service_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE hotel.service_id_seq OWNED BY hotel.service.id;
          hotel               postgres    false    236         �            1259    33530    staff    TABLE     �  CREATE TABLE hotel.staff (
    id character varying(5) NOT NULL,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    second_last_name character varying(50),
    phone_number character varying(15),
    address character varying(100) NOT NULL,
    hire_date date NOT NULL,
    salary numeric(10,2) NOT NULL,
    dct_typ_id character varying(2) NOT NULL,
    identity_document character varying(15) NOT NULL,
    worker_type character varying(50) NOT NULL,
    employee_number integer,
    direct_reports character varying(200),
    work_shift character varying(50),
    htl_id character varying(4) NOT NULL,
    boss_id character varying(5)
);
    DROP TABLE hotel.staff;
       hotel         heap r       postgres    false    6         �            1259    33529    staff_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE hotel.staff_id_seq;
       hotel               postgres    false    6    228         z           0    0    staff_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE hotel.staff_id_seq OWNED BY hotel.staff.id;
          hotel               postgres    false    227         y           2604    41209    agreement id    DEFAULT     j   ALTER TABLE ONLY hotel.agreement ALTER COLUMN id SET DEFAULT nextval('hotel.agreement_id_seq'::regclass);
 :   ALTER TABLE hotel.agreement ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    235    234    235         }           2604    49277 #   audi_detail_reservation consecutivo    DEFAULT     �   ALTER TABLE ONLY hotel.audi_detail_reservation ALTER COLUMN consecutivo SET DEFAULT nextval('hotel.audi_detail_reservation_consecutivo_seq'::regclass);
 Q   ALTER TABLE hotel.audi_detail_reservation ALTER COLUMN consecutivo DROP DEFAULT;
       hotel               postgres    false    243    242    243         |           2604    49268    audi_detail_service consecutivo    DEFAULT     �   ALTER TABLE ONLY hotel.audi_detail_service ALTER COLUMN consecutivo SET DEFAULT nextval('hotel.audi_detail_service_consecutivo_seq'::regclass);
 M   ALTER TABLE hotel.audi_detail_service ALTER COLUMN consecutivo DROP DEFAULT;
       hotel               postgres    false    241    240    241         v           2604    41188    detail_reservation line_item_id    DEFAULT     �   ALTER TABLE ONLY hotel.detail_reservation ALTER COLUMN line_item_id SET DEFAULT nextval('hotel.detail_reservation_line_item_id_seq'::regclass);
 M   ALTER TABLE hotel.detail_reservation ALTER COLUMN line_item_id DROP DEFAULT;
       hotel               postgres    false    233    232    233         {           2604    41228    detail_service line_item_id    DEFAULT     �   ALTER TABLE ONLY hotel.detail_service ALTER COLUMN line_item_id SET DEFAULT nextval('hotel.detail_service_line_item_id_seq'::regclass);
 I   ALTER TABLE hotel.detail_service ALTER COLUMN line_item_id DROP DEFAULT;
       hotel               postgres    false    239    238    239         u           2604    41171    reservation id    DEFAULT     n   ALTER TABLE ONLY hotel.reservation ALTER COLUMN id SET DEFAULT nextval('hotel.reservation_id_seq'::regclass);
 <   ALTER TABLE hotel.reservation ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    231    230    231         s           2604    33351    room id    DEFAULT     `   ALTER TABLE ONLY hotel.room ALTER COLUMN id SET DEFAULT nextval('hotel.room_id_seq'::regclass);
 5   ALTER TABLE hotel.room ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    225    226    226         z           2604    41216 
   service id    DEFAULT     f   ALTER TABLE ONLY hotel.service ALTER COLUMN id SET DEFAULT nextval('hotel.service_id_seq'::regclass);
 8   ALTER TABLE hotel.service ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    236    237    237         t           2604    41087    staff id    DEFAULT     b   ALTER TABLE ONLY hotel.staff ALTER COLUMN id SET DEFAULT nextval('hotel.staff_id_seq'::regclass);
 6   ALTER TABLE hotel.staff ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    228    227    228         c          0    41206 	   agreement 
   TABLE DATA           O   COPY hotel.agreement (id, name, description, start_date, end_date) FROM stdin;
    hotel               postgres    false    235       4963.dat k          0    49274    audi_detail_reservation 
   TABLE DATA           �   COPY hotel.audi_detail_reservation (consecutivo, rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal, fecha_registro, usuario, accion) FROM stdin;
    hotel               postgres    false    243       4971.dat i          0    49265    audi_detail_service 
   TABLE DATA           �   COPY hotel.audi_detail_service (consecutivo, srv_id, line_item_id, rsv_id, price, quantity, sub_total, fecha_registro, usuario, accion) FROM stdin;
    hotel               postgres    false    241       4969.dat V          0    33301    city 
   TABLE DATA           7   COPY hotel.city (id, dpt_id, cty_id, name) FROM stdin;
    hotel               postgres    false    222       4950.dat T          0    33286    country 
   TABLE DATA           *   COPY hotel.country (id, name) FROM stdin;
    hotel               postgres    false    220       4948.dat ]          0    41137    customer 
   TABLE DATA             COPY hotel.customer (id, dct_typ_id, first_name, middle_name, last_name, second_last_name, birth_date, gender, phone_number, email, prf_id, city_id, departament_id, country_id, destination_city_id, destination_departament_id, destination_country_id) FROM stdin;
    hotel               postgres    false    229       4957.dat U          0    33291 
   department 
   TABLE DATA           5   COPY hotel.department (id, cty_id, name) FROM stdin;
    hotel               postgres    false    221       4949.dat a          0    41185    detail_reservation 
   TABLE DATA           �   COPY hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal) FROM stdin;
    hotel               postgres    false    233       4961.dat g          0    41225    detail_service 
   TABLE DATA           a   COPY hotel.detail_service (srv_id, line_item_id, rsv_id, price, quantity, sub_total) FROM stdin;
    hotel               postgres    false    239       4967.dat S          0    33281    document_type 
   TABLE DATA           0   COPY hotel.document_type (id, name) FROM stdin;
    hotel               postgres    false    219       4947.dat X          0    33342    hotel 
   TABLE DATA           J   COPY hotel.hotel (id, name, phone_number, email, total_rooms) FROM stdin;
    hotel               postgres    false    224       4952.dat R          0    33274 
   profession 
   TABLE DATA           :   COPY hotel.profession (id, name, description) FROM stdin;
    hotel               postgres    false    218       4946.dat _          0    41168    reservation 
   TABLE DATA           a   COPY hotel.reservation (id, status, reservation_source, date, total, cst_id, stf_id) FROM stdin;
    hotel               postgres    false    231       4959.dat Z          0    33348    room 
   TABLE DATA           5   COPY hotel.room (id, rom_typ_id, htl_id) FROM stdin;
    hotel               postgres    false    226       4954.dat W          0    33337 	   room_type 
   TABLE DATA           J   COPY hotel.room_type (id, name, price_per_night, description) FROM stdin;
    hotel               postgres    false    223       4951.dat e          0    41213    service 
   TABLE DATA           9   COPY hotel.service (id, name, price, agr_id) FROM stdin;
    hotel               postgres    false    237       4965.dat \          0    33530    staff 
   TABLE DATA           �   COPY hotel.staff (id, first_name, middle_name, last_name, second_last_name, phone_number, address, hire_date, salary, dct_typ_id, identity_document, worker_type, employee_number, direct_reports, work_shift, htl_id, boss_id) FROM stdin;
    hotel               postgres    false    228       4956.dat {           0    0    agreement_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('hotel.agreement_id_seq', 1, false);
          hotel               postgres    false    234         |           0    0 '   audi_detail_reservation_consecutivo_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('hotel.audi_detail_reservation_consecutivo_seq', 1, true);
          hotel               postgres    false    242         }           0    0 #   audi_detail_service_consecutivo_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('hotel.audi_detail_service_consecutivo_seq', 1, true);
          hotel               postgres    false    240         ~           0    0 #   detail_reservation_line_item_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('hotel.detail_reservation_line_item_id_seq', 1, false);
          hotel               postgres    false    232                    0    0    detail_service_line_item_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('hotel.detail_service_line_item_id_seq', 1, false);
          hotel               postgres    false    238         �           0    0    reservation_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('hotel.reservation_id_seq', 1, false);
          hotel               postgres    false    230         �           0    0    room_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('hotel.room_id_seq', 1, false);
          hotel               postgres    false    225         �           0    0    service_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('hotel.service_id_seq', 1, true);
          hotel               postgres    false    236         �           0    0    staff_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('hotel.staff_id_seq', 1, false);
          hotel               postgres    false    227         �           2606    41211    agreement agreement_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY hotel.agreement
    ADD CONSTRAINT agreement_pkey PRIMARY KEY (id);
 A   ALTER TABLE ONLY hotel.agreement DROP CONSTRAINT agreement_pkey;
       hotel                 postgres    false    235         �           2606    49279 4   audi_detail_reservation audi_detail_reservation_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY hotel.audi_detail_reservation
    ADD CONSTRAINT audi_detail_reservation_pkey PRIMARY KEY (consecutivo);
 ]   ALTER TABLE ONLY hotel.audi_detail_reservation DROP CONSTRAINT audi_detail_reservation_pkey;
       hotel                 postgres    false    243         �           2606    49270 ,   audi_detail_service audi_detail_service_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY hotel.audi_detail_service
    ADD CONSTRAINT audi_detail_service_pkey PRIMARY KEY (consecutivo);
 U   ALTER TABLE ONLY hotel.audi_detail_service DROP CONSTRAINT audi_detail_service_pkey;
       hotel                 postgres    false    241         �           2606    33290    country country_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY hotel.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY hotel.country DROP CONSTRAINT country_pkey;
       hotel                 postgres    false    220         �           2606    41142    customer customer_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT customer_pkey;
       hotel                 postgres    false    229         �           2606    33464     document_type document_type_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY hotel.document_type
    ADD CONSTRAINT document_type_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY hotel.document_type DROP CONSTRAINT document_type_pkey;
       hotel                 postgres    false    219         �           2606    33346    hotel hotel_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY hotel.hotel
    ADD CONSTRAINT hotel_pkey PRIMARY KEY (id);
 9   ALTER TABLE ONLY hotel.hotel DROP CONSTRAINT hotel_pkey;
       hotel                 postgres    false    224         �           2606    33305    city pk_cyy 
   CONSTRAINT     X   ALTER TABLE ONLY hotel.city
    ADD CONSTRAINT pk_cyy PRIMARY KEY (id, dpt_id, cty_id);
 4   ALTER TABLE ONLY hotel.city DROP CONSTRAINT pk_cyy;
       hotel                 postgres    false    222    222    222         �           2606    33295    department pk_dpt 
   CONSTRAINT     V   ALTER TABLE ONLY hotel.department
    ADD CONSTRAINT pk_dpt PRIMARY KEY (id, cty_id);
 :   ALTER TABLE ONLY hotel.department DROP CONSTRAINT pk_dpt;
       hotel                 postgres    false    221    221         �           2606    41193    detail_reservation pk_dtl_rsv 
   CONSTRAINT     l   ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT pk_dtl_rsv PRIMARY KEY (rsv_id, line_item_id);
 F   ALTER TABLE ONLY hotel.detail_reservation DROP CONSTRAINT pk_dtl_rsv;
       hotel                 postgres    false    233    233         �           2606    41231    detail_service pk_dtl_srv 
   CONSTRAINT     h   ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT pk_dtl_srv PRIMARY KEY (srv_id, line_item_id);
 B   ALTER TABLE ONLY hotel.detail_service DROP CONSTRAINT pk_dtl_srv;
       hotel                 postgres    false    239    239         �           2606    33278    profession profession_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY hotel.profession
    ADD CONSTRAINT profession_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY hotel.profession DROP CONSTRAINT profession_pkey;
       hotel                 postgres    false    218         �           2606    41173    reservation reservation_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY hotel.reservation DROP CONSTRAINT reservation_pkey;
       hotel                 postgres    false    231         �           2606    33353    room room_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY hotel.room DROP CONSTRAINT room_pkey;
       hotel                 postgres    false    226         �           2606    33341    room_type room_type_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY hotel.room_type
    ADD CONSTRAINT room_type_pkey PRIMARY KEY (id);
 A   ALTER TABLE ONLY hotel.room_type DROP CONSTRAINT room_type_pkey;
       hotel                 postgres    false    223         �           2606    41218    service service_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY hotel.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY hotel.service DROP CONSTRAINT service_pkey;
       hotel                 postgres    false    237         �           2606    41089    staff staff_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);
 9   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT staff_pkey;
       hotel                 postgres    false    228         �           2606    33280    profession uk_prf_name 
   CONSTRAINT     P   ALTER TABLE ONLY hotel.profession
    ADD CONSTRAINT uk_prf_name UNIQUE (name);
 ?   ALTER TABLE ONLY hotel.profession DROP CONSTRAINT uk_prf_name;
       hotel                 postgres    false    218         �           2620    49281 .   detail_reservation trg_audi_detail_reservation    TRIGGER     �   CREATE TRIGGER trg_audi_detail_reservation BEFORE DELETE OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.audi_detail_reservation_func();
 F   DROP TRIGGER trg_audi_detail_reservation ON hotel.detail_reservation;
       hotel               postgres    false    263    233         �           2620    49272 &   detail_service trg_audi_detail_service    TRIGGER     �   CREATE TRIGGER trg_audi_detail_service BEFORE DELETE OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.audi_detail_service_func();
 >   DROP TRIGGER trg_audi_detail_service ON hotel.detail_service;
       hotel               postgres    false    250    239         �           2620    41243 .   detail_reservation trg_calc_detail_reservation    TRIGGER     �   CREATE TRIGGER trg_calc_detail_reservation BEFORE INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.calc_detail_reservation();
 F   DROP TRIGGER trg_calc_detail_reservation ON hotel.detail_reservation;
       hotel               postgres    false    233    244         �           2620    41245 &   detail_service trg_calc_detail_service    TRIGGER     �   CREATE TRIGGER trg_calc_detail_service BEFORE INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.calc_detail_service();
 >   DROP TRIGGER trg_calc_detail_service ON hotel.detail_service;
       hotel               postgres    false    245    239         �           2620    41265 2   detail_reservation trg_set_price_and_calc_subtotal    TRIGGER     �   CREATE TRIGGER trg_set_price_and_calc_subtotal BEFORE INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.set_price_and_calc_subtotal();
 J   DROP TRIGGER trg_set_price_and_calc_subtotal ON hotel.detail_reservation;
       hotel               postgres    false    262    233         �           2620    41263 %   detail_reservation trg_set_room_price    TRIGGER     �   CREATE TRIGGER trg_set_room_price BEFORE INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.set_room_price();
 =   DROP TRIGGER trg_set_room_price ON hotel.detail_reservation;
       hotel               postgres    false    233    248         �           2620    41261 $   detail_service trg_set_service_price    TRIGGER     �   CREATE TRIGGER trg_set_service_price BEFORE INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.set_service_price();
 <   DROP TRIGGER trg_set_service_price ON hotel.detail_service;
       hotel               postgres    false    239    247         �           2620    41267 1   detail_service trg_set_service_price_and_subtotal    TRIGGER     �   CREATE TRIGGER trg_set_service_price_and_subtotal BEFORE INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.set_service_price_and_subtotal();
 I   DROP TRIGGER trg_set_service_price_and_subtotal ON hotel.detail_service;
       hotel               postgres    false    249    239         �           2620    41247 ;   detail_reservation trg_update_total_from_detail_reservation    TRIGGER     �   CREATE TRIGGER trg_update_total_from_detail_reservation AFTER INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.update_reservation_total();
 S   DROP TRIGGER trg_update_total_from_detail_reservation ON hotel.detail_reservation;
       hotel               postgres    false    246    233         �           2620    41248 3   detail_service trg_update_total_from_detail_service    TRIGGER     �   CREATE TRIGGER trg_update_total_from_detail_service AFTER INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.update_reservation_total();
 K   DROP TRIGGER trg_update_total_from_detail_service ON hotel.detail_service;
       hotel               postgres    false    239    246         �           2606    41153    customer fk_cst_city    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_city FOREIGN KEY (city_id, departament_id, country_id) REFERENCES hotel.city(id, dpt_id, cty_id);
 =   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_city;
       hotel               postgres    false    4748    229    229    222    222    222    229         �           2606    41143    customer fk_cst_dct_typ    FK CONSTRAINT        ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id);
 @   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_dct_typ;
       hotel               postgres    false    219    4742    229         �           2606    41158    customer fk_cst_dest_city    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_dest_city FOREIGN KEY (destination_city_id, destination_departament_id, destination_country_id) REFERENCES hotel.city(id, dpt_id, cty_id);
 B   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_dest_city;
       hotel               postgres    false    222    229    229    229    4748    222    222         �           2606    41148    customer fk_cst_prf    FK CONSTRAINT     t   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_prf FOREIGN KEY (prf_id) REFERENCES hotel.profession(id);
 <   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_prf;
       hotel               postgres    false    4738    218    229         �           2606    33306    city fk_cyy_dpt    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.city
    ADD CONSTRAINT fk_cyy_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES hotel.department(id, cty_id);
 8   ALTER TABLE ONLY hotel.city DROP CONSTRAINT fk_cyy_dpt;
       hotel               postgres    false    4746    222    221    221    222         �           2606    33296    department fk_dpt_cty    FK CONSTRAINT     s   ALTER TABLE ONLY hotel.department
    ADD CONSTRAINT fk_dpt_cty FOREIGN KEY (cty_id) REFERENCES hotel.country(id);
 >   ALTER TABLE ONLY hotel.department DROP CONSTRAINT fk_dpt_cty;
       hotel               postgres    false    221    220    4744         �           2606    41199 !   detail_reservation fk_dtl_rsv_rom    FK CONSTRAINT     }   ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT fk_dtl_rsv_rom FOREIGN KEY (room_id) REFERENCES hotel.room(id);
 J   ALTER TABLE ONLY hotel.detail_reservation DROP CONSTRAINT fk_dtl_rsv_rom;
       hotel               postgres    false    233    226    4754         �           2606    41194 !   detail_reservation fk_dtl_rsv_rsv    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT fk_dtl_rsv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id);
 J   ALTER TABLE ONLY hotel.detail_reservation DROP CONSTRAINT fk_dtl_rsv_rsv;
       hotel               postgres    false    233    231    4760         �           2606    41237    detail_service fk_dtl_srv_rsv    FK CONSTRAINT        ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT fk_dtl_srv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id);
 F   ALTER TABLE ONLY hotel.detail_service DROP CONSTRAINT fk_dtl_srv_rsv;
       hotel               postgres    false    239    231    4760         �           2606    41232    detail_service fk_dtl_srv_srv    FK CONSTRAINT     {   ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT fk_dtl_srv_srv FOREIGN KEY (srv_id) REFERENCES hotel.service(id);
 F   ALTER TABLE ONLY hotel.detail_service DROP CONSTRAINT fk_dtl_srv_srv;
       hotel               postgres    false    239    4766    237         �           2606    33359    room fk_rom_htl    FK CONSTRAINT     k   ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT fk_rom_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id);
 8   ALTER TABLE ONLY hotel.room DROP CONSTRAINT fk_rom_htl;
       hotel               postgres    false    224    226    4752         �           2606    33354    room fk_rom_typ    FK CONSTRAINT     s   ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT fk_rom_typ FOREIGN KEY (rom_typ_id) REFERENCES hotel.room_type(id);
 8   ALTER TABLE ONLY hotel.room DROP CONSTRAINT fk_rom_typ;
       hotel               postgres    false    226    223    4750         �           2606    41174    reservation fk_rsv_cst    FK CONSTRAINT     u   ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT fk_rsv_cst FOREIGN KEY (cst_id) REFERENCES hotel.customer(id);
 ?   ALTER TABLE ONLY hotel.reservation DROP CONSTRAINT fk_rsv_cst;
       hotel               postgres    false    4758    231    229         �           2606    41179    reservation fk_rsv_stf    FK CONSTRAINT     r   ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT fk_rsv_stf FOREIGN KEY (stf_id) REFERENCES hotel.staff(id);
 ?   ALTER TABLE ONLY hotel.reservation DROP CONSTRAINT fk_rsv_stf;
       hotel               postgres    false    4756    231    228         �           2606    41219    service fk_srv_agr    FK CONSTRAINT     r   ALTER TABLE ONLY hotel.service
    ADD CONSTRAINT fk_srv_agr FOREIGN KEY (agr_id) REFERENCES hotel.agreement(id);
 ;   ALTER TABLE ONLY hotel.service DROP CONSTRAINT fk_srv_agr;
       hotel               postgres    false    235    4764    237         �           2606    41090    staff fk_stf_boss    FK CONSTRAINT     n   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_boss FOREIGN KEY (boss_id) REFERENCES hotel.staff(id);
 :   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT fk_stf_boss;
       hotel               postgres    false    228    4756    228         �           2606    33538    staff fk_stf_dct_typ    FK CONSTRAINT     |   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id);
 =   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT fk_stf_dct_typ;
       hotel               postgres    false    228    4742    219         �           2606    33543    staff fk_stf_htl    FK CONSTRAINT     l   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id);
 9   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT fk_stf_htl;
       hotel               postgres    false    228    224    4752                                                                                                                                                   4963.dat                                                                                            0000600 0004000 0002000 00000503343 15015342721 0014267 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	Acuerdo de Lavanderia	Lavanderia para los clientes que deseen.	2020-03-05	2023-03-05
2	Convenio hotelero con Pozuelo PLC	Acuerdo entre el hotel y Pozuelo PLC para ofrecer servicios especiales a nuestros huéspedes.	2024-04-10	2028-04-09
3	Convenio hotelero con Pineda-Andres	Acuerdo entre el hotel y Pineda-Andres para ofrecer servicios especiales a nuestros huéspedes.	2023-12-31	2024-12-30
4	Convenio hotelero con Palacios and Ibañez	Acuerdo entre el hotel y Montalbán, Palacios and Ibañez para ofrecer servicios especiales a nuestros huéspedes.	2023-01-03	2025-01-02
5	Convenio hotelero con Batlle, Puente and Campos	Acuerdo entre el hotel y Batlle, Puente and Campos para ofrecer servicios especiales a nuestros huéspedes.	2020-10-01	2025-09-30
6	Convenio hotelero con Carvajal-Fonseca	Acuerdo entre el hotel y Carvajal-Fonseca para ofrecer servicios especiales a nuestros huéspedes.	2023-05-11	2024-05-10
7	Convenio hotelero con Anguita Inc	Acuerdo entre el hotel y Anguita Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-05-30	2027-05-29
8	Convenio hotelero con Iborra, Vazquez and Perera	Acuerdo entre el hotel y Iborra, Vazquez and Perera para ofrecer servicios especiales a nuestros huéspedes.	2023-05-30	2028-05-28
9	Convenio hotelero con Barberá PLC	Acuerdo entre el hotel y Barberá PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-06-16	2024-06-15
10	Convenio hotelero con Martinez Inc	Acuerdo entre el hotel y Martinez Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-10-22	2024-10-21
11	Convenio hotelero con Mayo, Olivera and Flores	Acuerdo entre el hotel y Mayo, Olivera and Flores para ofrecer servicios especiales a nuestros huéspedes.	2022-08-13	2023-08-13
12	Convenio hotelero con Diego, Esparza and Tirado	Acuerdo entre el hotel y Diego, Esparza and Tirado para ofrecer servicios especiales a nuestros huéspedes.	2021-07-13	2024-07-12
13	Convenio hotelero con Rodriguez, Arana and Parejo	Acuerdo entre el hotel y Rodriguez, Arana and Parejo para ofrecer servicios especiales a nuestros huéspedes.	2021-10-17	2026-10-16
14	Convenio hotelero con Nicolás-Dávila	Acuerdo entre el hotel y Nicolás-Dávila para ofrecer servicios especiales a nuestros huéspedes.	2022-10-03	2027-10-02
15	Convenio hotelero con Amigó-Aranda	Acuerdo entre el hotel y Amigó-Aranda para ofrecer servicios especiales a nuestros huéspedes.	2024-03-14	2025-03-14
16	Convenio hotelero con Sacristán-Lluch	Acuerdo entre el hotel y Sacristán-Lluch para ofrecer servicios especiales a nuestros huéspedes.	2021-06-27	2023-06-27
17	Convenio hotelero con Pont, Corominas and Valentín	Acuerdo entre el hotel y Pont, Corominas and Valentín para ofrecer servicios especiales a nuestros huéspedes.	2023-11-20	2027-11-19
18	Convenio hotelero con Luz Group	Acuerdo entre el hotel y Luz Group para ofrecer servicios especiales a nuestros huéspedes.	2020-09-26	2023-09-26
19	Convenio hotelero con Arcos, Márquez and Gárate	Acuerdo entre el hotel y Arcos, Márquez and Gárate para ofrecer servicios especiales a nuestros huéspedes.	2024-01-15	2028-01-14
20	Convenio hotelero con Girona-Alemany	Acuerdo entre el hotel y Girona-Alemany para ofrecer servicios especiales a nuestros huéspedes.	2020-08-28	2023-08-28
21	Convenio hotelero con Cañete Group	Acuerdo entre el hotel y Cañete Group para ofrecer servicios especiales a nuestros huéspedes.	2023-11-16	2028-11-14
22	Convenio hotelero con Gras, Piquer and Aparicio	Acuerdo entre el hotel y Gras, Piquer and Aparicio para ofrecer servicios especiales a nuestros huéspedes.	2022-06-10	2023-06-10
23	Convenio hotelero con Gaya Inc	Acuerdo entre el hotel y Gaya Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-11-20	2023-11-20
24	Convenio hotelero con Falcó LLC	Acuerdo entre el hotel y Falcó LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-09-16	2023-09-16
25	Convenio hotelero con Sosa Group	Acuerdo entre el hotel y Sosa Group para ofrecer servicios especiales a nuestros huéspedes.	2020-07-30	2022-07-30
26	Convenio hotelero con Urrutia-Juan	Acuerdo entre el hotel y Urrutia-Juan para ofrecer servicios especiales a nuestros huéspedes.	2024-02-09	2029-02-07
27	Convenio hotelero con Alberdi	Acuerdo entre el hotel y Alberdi, Morante and Cuadrado para ofrecer servicios especiales a nuestros huéspedes.	2022-05-09	2025-05-08
28	Convenio hotelero con Francisco Quintana	Acuerdo entre el hotel y Francisco, Godoy and Quintana para ofrecer servicios especiales a nuestros huéspedes.	2020-12-30	2022-12-30
29	Convenio hotelero con Expósito-Sales	Acuerdo entre el hotel y Expósito-Sales para ofrecer servicios especiales a nuestros huéspedes.	2024-02-23	2029-02-21
30	Convenio hotelero con Sanz, Garmendia and Luján	Acuerdo entre el hotel y Sanz, Garmendia and Luján para ofrecer servicios especiales a nuestros huéspedes.	2022-01-06	2026-01-05
31	Convenio hotelero con Cuadrado	Acuerdo entre el hotel y Cuadrado, Cuervo and Angulo para ofrecer servicios especiales a nuestros huéspedes.	2022-01-08	2026-01-07
32	Convenio hotelero con Aliaga Ltd	Acuerdo entre el hotel y Aliaga Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-07-12	2024-07-11
33	Convenio hotelero con Quero Inc	Acuerdo entre el hotel y Quero Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-01-17	2026-01-16
34	Convenio hotelero con Falcón Group	Acuerdo entre el hotel y Falcón Group para ofrecer servicios especiales a nuestros huéspedes.	2022-10-02	2023-10-02
35	Convenio hotelero con Molins LLC	Acuerdo entre el hotel y Molins LLC para ofrecer servicios especiales a nuestros huéspedes.	2021-12-15	2022-12-15
36	Convenio hotelero con Torrens, Sierra and Pardo	Acuerdo entre el hotel y Torrens, Sierra and Pardo para ofrecer servicios especiales a nuestros huéspedes.	2020-12-25	2022-12-25
37	Convenio hotelero con Vizcaíno and Sons	Acuerdo entre el hotel y Vizcaíno and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-09-25	2026-09-24
38	Convenio hotelero con Lasa-León	Acuerdo entre el hotel y Lasa-León para ofrecer servicios especiales a nuestros huéspedes.	2022-08-26	2025-08-25
39	Convenio hotelero con Castellanos	Acuerdo entre el hotel y Morcillo, Huertas and Castellanos para ofrecer servicios especiales a nuestros huéspedes.	2023-03-07	2026-03-06
40	Convenio hotelero con Iniesta, Arenas and Garriga	Acuerdo entre el hotel y Iniesta, Arenas and Garriga para ofrecer servicios especiales a nuestros huéspedes.	2020-08-03	2024-08-02
41	Convenio hotelero con Zurita	Acuerdo entre el hotel y Zurita, Acuña and Sarabia para ofrecer servicios especiales a nuestros huéspedes.	2023-11-04	2025-11-03
42	Convenio hotelero con Porta-Madrid	Acuerdo entre el hotel y Porta-Madrid para ofrecer servicios especiales a nuestros huéspedes.	2020-06-25	2023-06-25
43	Convenio hotelero con Marti Ltd	Acuerdo entre el hotel y Marti Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-10-19	2026-10-18
44	Convenio hotelero con Madrid and Sons	Acuerdo entre el hotel y Madrid and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-07-01	2023-07-01
45	Convenio hotelero con Lozano Inc	Acuerdo entre el hotel y Lozano Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-11-24	2027-11-23
46	Convenio hotelero con Plaza-Maza	Acuerdo entre el hotel y Plaza-Maza para ofrecer servicios especiales a nuestros huéspedes.	2020-08-24	2025-08-23
47	Convenio hotelero con Iglesia-Barba	Acuerdo entre el hotel y Iglesia-Barba para ofrecer servicios especiales a nuestros huéspedes.	2021-11-11	2023-11-11
48	Convenio hotelero con Cano, Rincón and Durán	Acuerdo entre el hotel y Cano, Rincón and Durán para ofrecer servicios especiales a nuestros huéspedes.	2023-12-19	2025-12-18
49	Convenio hotelero con Llopis, Segarra and Jiménez	Acuerdo entre el hotel y Llopis, Segarra and Jiménez para ofrecer servicios especiales a nuestros huéspedes.	2022-09-11	2025-09-10
50	Convenio hotelero con Coca-Ojeda	Acuerdo entre el hotel y Coca-Ojeda para ofrecer servicios especiales a nuestros huéspedes.	2021-07-21	2024-07-20
51	Convenio hotelero con Peinado, Puerta and Mayol	Acuerdo entre el hotel y Peinado, Puerta and Mayol para ofrecer servicios especiales a nuestros huéspedes.	2022-03-24	2026-03-23
52	Convenio hotelero con Valls, Carbó and Alegre	Acuerdo entre el hotel y Valls, Carbó and Alegre para ofrecer servicios especiales a nuestros huéspedes.	2023-07-26	2025-07-25
53	Convenio hotelero con Arce Ltd	Acuerdo entre el hotel y Arce Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-07-18	2025-07-17
54	Convenio hotelero con Tenorio-Tejera	Acuerdo entre el hotel y Tenorio-Tejera para ofrecer servicios especiales a nuestros huéspedes.	2022-07-11	2027-07-10
55	Convenio hotelero con Vélez Ltd	Acuerdo entre el hotel y Vélez Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-06-12	2026-06-11
56	Convenio hotelero con Quintanilla	Acuerdo entre el hotel y Romeu, Gálvez and Quintanilla para ofrecer servicios especiales a nuestros huéspedes.	2021-12-13	2022-12-13
57	Convenio hotelero con Maestre-Alegria	Acuerdo entre el hotel y Maestre-Alegria para ofrecer servicios especiales a nuestros huéspedes.	2024-02-29	2029-02-27
58	Convenio hotelero con Ramírez-Delgado	Acuerdo entre el hotel y Ramírez-Delgado para ofrecer servicios especiales a nuestros huéspedes.	2020-12-26	2022-12-26
59	Convenio hotelero con Luque, Infante and Figueroa	Acuerdo entre el hotel y Luque, Infante and Figueroa para ofrecer servicios especiales a nuestros huéspedes.	2020-11-02	2022-11-02
60	Convenio hotelero con Rius-Guerrero	Acuerdo entre el hotel y Rius-Guerrero para ofrecer servicios especiales a nuestros huéspedes.	2021-09-27	2023-09-27
61	Convenio hotelero con Yuste, Carballo and Zamorano	Acuerdo entre el hotel y Yuste, Carballo and Zamorano para ofrecer servicios especiales a nuestros huéspedes.	2020-10-27	2023-10-27
62	Convenio hotelero con Carlos PLC	Acuerdo entre el hotel y Carlos PLC para ofrecer servicios especiales a nuestros huéspedes.	2024-01-10	2025-01-09
63	Convenio hotelero con Manzano Ltd	Acuerdo entre el hotel y Manzano Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-03-24	2026-03-24
64	Convenio hotelero con Barceló PLC	Acuerdo entre el hotel y Barceló PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-08-02	2021-08-02
65	Convenio hotelero con Jara, Huertas and Murillo	Acuerdo entre el hotel y Jara, Huertas and Murillo para ofrecer servicios especiales a nuestros huéspedes.	2022-05-27	2023-05-27
66	Convenio hotelero con Barco PLC	Acuerdo entre el hotel y Barco PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-06-19	2028-06-17
67	Convenio hotelero con Noriega Group	Acuerdo entre el hotel y Noriega Group para ofrecer servicios especiales a nuestros huéspedes.	2023-01-05	2028-01-04
68	Convenio hotelero con Pardo LLC	Acuerdo entre el hotel y Pardo LLC para ofrecer servicios especiales a nuestros huéspedes.	2020-08-14	2021-08-14
69	Convenio hotelero con Alfonso-Ibañez	Acuerdo entre el hotel y Alfonso-Ibañez para ofrecer servicios especiales a nuestros huéspedes.	2023-06-25	2026-06-24
70	Convenio hotelero con Sarmiento Patiño	Acuerdo entre el hotel y Sarmiento, Cordero and Patiño para ofrecer servicios especiales a nuestros huéspedes.	2023-10-06	2028-10-04
71	Convenio hotelero con Salvà-Arranz	Acuerdo entre el hotel y Salvà-Arranz para ofrecer servicios especiales a nuestros huéspedes.	2023-01-04	2026-01-03
72	Convenio hotelero con Amor-Blanes	Acuerdo entre el hotel y Amor-Blanes para ofrecer servicios especiales a nuestros huéspedes.	2021-02-25	2026-02-24
73	Convenio hotelero con Clavero-Parejo	Acuerdo entre el hotel y Clavero-Parejo para ofrecer servicios especiales a nuestros huéspedes.	2022-01-31	2023-01-31
74	Convenio hotelero con Garriga, Cárdenas and Muro	Acuerdo entre el hotel y Garriga, Cárdenas and Muro para ofrecer servicios especiales a nuestros huéspedes.	2020-12-29	2021-12-29
75	Convenio hotelero con Caballero Ltd	Acuerdo entre el hotel y Caballero Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-12-27	2024-12-26
76	Convenio hotelero con Rosselló Group	Acuerdo entre el hotel y Rosselló Group para ofrecer servicios especiales a nuestros huéspedes.	2023-05-07	2025-05-06
77	Convenio hotelero con Bermudez Inc	Acuerdo entre el hotel y Bermudez Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-10-09	2022-10-09
78	Convenio hotelero con Mayol-Recio	Acuerdo entre el hotel y Mayol-Recio para ofrecer servicios especiales a nuestros huéspedes.	2022-07-11	2026-07-10
79	Convenio hotelero con Ayllón Ltd	Acuerdo entre el hotel y Ayllón Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-05-16	2025-05-15
80	Convenio hotelero con Cid, Tomas and Molins	Acuerdo entre el hotel y Cid, Tomas and Molins para ofrecer servicios especiales a nuestros huéspedes.	2021-08-25	2024-08-24
81	Convenio hotelero con Pastor-Rosado	Acuerdo entre el hotel y Pastor-Rosado para ofrecer servicios especiales a nuestros huéspedes.	2021-08-31	2023-08-31
82	Convenio hotelero con Cabrera Group	Acuerdo entre el hotel y Cabrera Group para ofrecer servicios especiales a nuestros huéspedes.	2022-09-17	2024-09-16
83	Convenio hotelero con Arnal Group	Acuerdo entre el hotel y Arnal Group para ofrecer servicios especiales a nuestros huéspedes.	2021-10-09	2025-10-08
84	Convenio hotelero con Palomo PLC	Acuerdo entre el hotel y Palomo PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-08-11	2024-08-10
85	Convenio hotelero con Sáez-Bartolomé	Acuerdo entre el hotel y Sáez-Bartolomé para ofrecer servicios especiales a nuestros huéspedes.	2021-12-22	2023-12-22
86	Convenio hotelero con Blazquez Group	Acuerdo entre el hotel y Blazquez Group para ofrecer servicios especiales a nuestros huéspedes.	2022-05-23	2027-05-22
87	Convenio hotelero con Alegria, Blanca and Prats	Acuerdo entre el hotel y Alegria, Blanca and Prats para ofrecer servicios especiales a nuestros huéspedes.	2024-04-01	2027-04-01
88	Convenio hotelero con Tomás, Gaya and Molins	Acuerdo entre el hotel y Tomás, Gaya and Molins para ofrecer servicios especiales a nuestros huéspedes.	2022-02-19	2026-02-18
89	Convenio hotelero con Gomis Ltd	Acuerdo entre el hotel y Gomis Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-11-05	2026-11-04
90	Convenio hotelero con Menéndez, Pulido and Herranz	Acuerdo entre el hotel y Menéndez, Pulido and Herranz para ofrecer servicios especiales a nuestros huéspedes.	2023-12-18	2028-12-16
91	Convenio hotelero con Reyes Ltd	Acuerdo entre el hotel y Reyes Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-02-08	2026-02-07
92	Convenio hotelero con Juárez-Caballero	Acuerdo entre el hotel y Juárez-Caballero para ofrecer servicios especiales a nuestros huéspedes.	2021-05-01	2025-04-30
93	Convenio hotelero con Lluch, Merino and Caro	Acuerdo entre el hotel y Lluch, Merino and Caro para ofrecer servicios especiales a nuestros huéspedes.	2021-02-16	2026-02-15
94	Convenio hotelero con Hoyos, Iborra and Lorenzo	Acuerdo entre el hotel y Hoyos, Iborra and Lorenzo para ofrecer servicios especiales a nuestros huéspedes.	2022-10-19	2027-10-18
95	Convenio hotelero con Villanueva Group	Acuerdo entre el hotel y Villanueva Group para ofrecer servicios especiales a nuestros huéspedes.	2023-07-14	2026-07-13
96	Convenio hotelero con Campo-Avilés	Acuerdo entre el hotel y Campo-Avilés para ofrecer servicios especiales a nuestros huéspedes.	2023-03-27	2028-03-25
97	Convenio hotelero con Morán and Sons	Acuerdo entre el hotel y Morán and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-06-08	2024-06-07
98	Convenio hotelero con Lopez-Barriga	Acuerdo entre el hotel y Lopez-Barriga para ofrecer servicios especiales a nuestros huéspedes.	2022-05-01	2024-04-30
99	Convenio hotelero Sarmiento and Sandoval	Acuerdo entre el hotel y Salmerón, Sarmiento and Sandoval para ofrecer servicios especiales a nuestros huéspedes.	2020-12-31	2025-12-30
100	Convenio hotelero con Guardia Ltd	Acuerdo entre el hotel y Guardia Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-01-07	2025-01-06
101	Convenio hotelero con Prat and Sons	Acuerdo entre el hotel y Prat and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-06-22	2024-06-21
102	Convenio hotelero con Delgado Inc	Acuerdo entre el hotel y Delgado Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-05-18	2028-05-16
103	Convenio hotelero con Jove, Goñi and Huguet	Acuerdo entre el hotel y Jove, Goñi and Huguet para ofrecer servicios especiales a nuestros huéspedes.	2022-07-30	2025-07-29
104	Convenio hotelero con Martínez-Arroyo	Acuerdo entre el hotel y Martínez-Arroyo para ofrecer servicios especiales a nuestros huéspedes.	2020-12-12	2025-12-11
105	Convenio hotelero con Peral Ltd	Acuerdo entre el hotel y Peral Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-03-04	2024-03-03
106	Convenio hotelero con Galvez, Agustí and Nogueira	Acuerdo entre el hotel y Galvez, Agustí and Nogueira para ofrecer servicios especiales a nuestros huéspedes.	2023-05-27	2025-05-26
107	Convenio hotelero con Pedrosa Inc	Acuerdo entre el hotel y Pedrosa Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-05-26	2025-05-25
108	Convenio hotelero Zabaleta	Acuerdo entre el hotel y Sobrino, Vilanova and Zabaleta para ofrecer servicios especiales a nuestros huéspedes.	2022-03-23	2023-03-23
109	Convenio hotelero con Ocaña Group	Acuerdo entre el hotel y Ocaña Group para ofrecer servicios especiales a nuestros huéspedes.	2020-12-30	2021-12-30
110	Convenio hotelero con Ferrán-Ruano	Acuerdo entre el hotel y Ferrán-Ruano para ofrecer servicios especiales a nuestros huéspedes.	2022-02-17	2026-02-16
111	Convenio hotelero con Gonzalo Group	Acuerdo entre el hotel y Gonzalo Group para ofrecer servicios especiales a nuestros huéspedes.	2023-12-17	2027-12-16
112	Convenio hotelero con Acevedo-Salmerón	Acuerdo entre el hotel y Acevedo-Salmerón para ofrecer servicios especiales a nuestros huéspedes.	2021-02-25	2023-02-25
113	Convenio hotelero con Orozco Group	Acuerdo entre el hotel y Orozco Group para ofrecer servicios especiales a nuestros huéspedes.	2022-04-13	2025-04-12
114	Convenio hotelero con Baquero Group	Acuerdo entre el hotel y Baquero Group para ofrecer servicios especiales a nuestros huéspedes.	2020-11-04	2024-11-03
115	Convenio hotelero con Haro-Palomo	Acuerdo entre el hotel y Haro-Palomo para ofrecer servicios especiales a nuestros huéspedes.	2023-10-21	2028-10-19
116	Convenio hotelero con Andrade and Sons	Acuerdo entre el hotel y Andrade and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-03-14	2026-03-13
117	Convenio hotelero con Montes-Villalonga	Acuerdo entre el hotel y Montes-Villalonga para ofrecer servicios especiales a nuestros huéspedes.	2021-04-28	2023-04-28
118	Convenio hotelero con Taboada-Cortés	Acuerdo entre el hotel y Taboada-Cortés para ofrecer servicios especiales a nuestros huéspedes.	2023-04-26	2027-04-25
119	Convenio hotelero con Izaguirre Ltd	Acuerdo entre el hotel y Izaguirre Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-04-29	2026-04-29
120	Convenio hotelero con Sacristán LLC	Acuerdo entre el hotel y Sacristán LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-11-04	2024-11-03
121	Convenio hotelero con Jimenez-Rueda	Acuerdo entre el hotel y Jimenez-Rueda para ofrecer servicios especiales a nuestros huéspedes.	2023-06-27	2025-06-26
122	Convenio hotelero con Cortés, Cañas and Medina	Acuerdo entre el hotel y Cortés, Cañas and Medina para ofrecer servicios especiales a nuestros huéspedes.	2021-06-25	2026-06-24
123	Convenio hotelero con Acero and Sons	Acuerdo entre el hotel y Acero and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-02-28	2022-02-28
124	Convenio hotelero con Mateo LLC	Acuerdo entre el hotel y Mateo LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-21	2025-12-20
125	Convenio hotelero con Escolano-Isern	Acuerdo entre el hotel y Escolano-Isern para ofrecer servicios especiales a nuestros huéspedes.	2020-09-17	2021-09-17
126	Convenio hotelero con Vidal, Priego and Lago	Acuerdo entre el hotel y Vidal, Priego and Lago para ofrecer servicios especiales a nuestros huéspedes.	2022-02-07	2024-02-07
127	Convenio hotelero con Vargas, Arribas and Carreras	Acuerdo entre el hotel y Vargas, Arribas and Carreras para ofrecer servicios especiales a nuestros huéspedes.	2020-08-22	2023-08-22
128	Convenio hotelero con Bernad Inc	Acuerdo entre el hotel y Bernad Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-02-23	2022-02-23
129	Convenio hotelero con Guerra-Garriga	Acuerdo entre el hotel y Guerra-Garriga para ofrecer servicios especiales a nuestros huéspedes.	2022-11-23	2023-11-23
130	Convenio hotelero con Mora-Reguera	Acuerdo entre el hotel y Mora-Reguera para ofrecer servicios especiales a nuestros huéspedes.	2020-07-27	2025-07-26
131	Convenio hotelero con Porras-Jove	Acuerdo entre el hotel y Porras-Jove para ofrecer servicios especiales a nuestros huéspedes.	2024-05-14	2025-05-14
132	Convenio hotelero con Guillén and Sons	Acuerdo entre el hotel y Guillén and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-11-06	2026-11-05
133	Convenio hotelero con Agudo-Cabello	Acuerdo entre el hotel y Agudo-Cabello para ofrecer servicios especiales a nuestros huéspedes.	2024-03-25	2028-03-24
134	Convenio hotelero con Cadenas-Valderrama	Acuerdo entre el hotel y Cadenas-Valderrama para ofrecer servicios especiales a nuestros huéspedes.	2023-05-10	2024-05-09
135	Convenio hotelero con Seco Inc	Acuerdo entre el hotel y Seco Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-12-01	2024-11-30
136	Convenio hotelero con Pedro	Acuerdo entre el hotel y Pedro, Echeverría and Madrigal para ofrecer servicios especiales a nuestros huéspedes.	2023-09-30	2024-09-29
137	Convenio hotelero con Pont and Sons	Acuerdo entre el hotel y Pont and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-03-19	2023-03-19
138	Convenio hotelero con Hoyos LLC	Acuerdo entre el hotel y Hoyos LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-05-01	2026-04-30
139	Convenio hotelero con Alcántara	Acuerdo entre el hotel y Arenas, Arteaga and Alcántara para ofrecer servicios especiales a nuestros huéspedes.	2023-08-29	2027-08-28
140	Convenio hotelero con Badía LLC	Acuerdo entre el hotel y Badía LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-09-20	2026-09-19
141	Convenio hotelero con Borrell-Pou	Acuerdo entre el hotel y Borrell-Pou para ofrecer servicios especiales a nuestros huéspedes.	2022-01-31	2025-01-30
142	Convenio hotelero con Ferrández-Rosado	Acuerdo entre el hotel y Ferrández-Rosado para ofrecer servicios especiales a nuestros huéspedes.	2023-11-01	2025-10-31
143	Convenio hotelero con Pol and Sons	Acuerdo entre el hotel y Pol and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-08-15	2023-08-15
144	Convenio hotelero con Cadenas-Nogués	Acuerdo entre el hotel y Cadenas-Nogués para ofrecer servicios especiales a nuestros huéspedes.	2022-08-05	2025-08-04
145	Convenio hotelero con Sainz-Recio	Acuerdo entre el hotel y Sainz-Recio para ofrecer servicios especiales a nuestros huéspedes.	2023-05-28	2024-05-27
146	Convenio hotelero con Soria and Sons	Acuerdo entre el hotel y Soria and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-05-31	2023-05-31
147	Convenio hotelero con Espada Ltd	Acuerdo entre el hotel y Espada Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-02-07	2024-02-07
148	Convenio hotelero Aguado	Acuerdo entre el hotel y Abril, Esteve and Aguado para ofrecer servicios especiales a nuestros huéspedes.	2023-09-15	2028-09-13
149	Convenio Revilla	Acuerdo entre el hotel y Grande, Guardiola and Revilla para ofrecer servicios especiales a nuestros huéspedes.	2022-10-06	2027-10-05
150	Convenio hotelero con Paz, Salazar and Múgica	Acuerdo entre el hotel y Paz, Salazar and Múgica para ofrecer servicios especiales a nuestros huéspedes.	2023-07-09	2025-07-08
151	Convenio hotelero con Arana Ltd	Acuerdo entre el hotel y Arana Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-11-19	2022-11-19
152	Convenio hotelero con Almansa and Sons	Acuerdo entre el hotel y Almansa and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-03-31	2026-03-30
153	Convenio hotelero con Tomé, Mir and Ibarra	Acuerdo entre el hotel y Tomé, Mir and Ibarra para ofrecer servicios especiales a nuestros huéspedes.	2023-12-08	2027-12-07
154	Convenio hotelero con Sancho, Hernando and Tolosa	Acuerdo entre el hotel y Sancho, Hernando and Tolosa para ofrecer servicios especiales a nuestros huéspedes.	2022-11-09	2026-11-08
155	Convenio hotelero con Figuerola, Puga and Boada	Acuerdo entre el hotel y Figuerola, Puga and Boada para ofrecer servicios especiales a nuestros huéspedes.	2023-02-25	2025-02-24
156	Convenio hotelero con Sáenz-Luján	Acuerdo entre el hotel y Sáenz-Luján para ofrecer servicios especiales a nuestros huéspedes.	2021-07-20	2026-07-19
157	Convenio hotelero con Mancebo PLC	Acuerdo entre el hotel y Mancebo PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-07-18	2024-07-17
158	Convenio hotelero con Bustamante and Sons	Acuerdo entre el hotel y Bustamante and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-09-16	2024-09-15
159	Convenio hotelero con Artigas-Pardo	Acuerdo entre el hotel y Artigas-Pardo para ofrecer servicios especiales a nuestros huéspedes.	2023-01-01	2024-12-31
160	Convenio hotelero con Mínguez-Tejera	Acuerdo entre el hotel y Mínguez-Tejera para ofrecer servicios especiales a nuestros huéspedes.	2024-04-04	2027-04-04
161	Convenio hotelero con Arcos, Simó and Escrivá	Acuerdo entre el hotel y Arcos, Simó and Escrivá para ofrecer servicios especiales a nuestros huéspedes.	2020-12-30	2023-12-30
162	Convenio hotelero con Diaz, Gimenez and Barral	Acuerdo entre el hotel y Diaz, Gimenez and Barral para ofrecer servicios especiales a nuestros huéspedes.	2021-12-28	2025-12-27
163	Convenio hotelero con Pombo Ltd	Acuerdo entre el hotel y Pombo Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-12-30	2023-12-30
164	Convenio hotelero con Ojeda PLC	Acuerdo entre el hotel y Ojeda PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-05-26	2027-05-25
165	Convenio hotelero con Jiménez-Adadia	Acuerdo entre el hotel y Jiménez-Adadia para ofrecer servicios especiales a nuestros huéspedes.	2021-10-28	2024-10-27
166	Convenio hotelero con Morillo, Sebastián and Perez	Acuerdo entre el hotel y Morillo, Sebastián and Perez para ofrecer servicios especiales a nuestros huéspedes.	2021-09-25	2022-09-25
167	Convenio hotelero con Frutos Inc	Acuerdo entre el hotel y Frutos Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-01-21	2023-01-21
168	Convenio hotelero con Cabo-Sobrino	Acuerdo entre el hotel y Cabo-Sobrino para ofrecer servicios especiales a nuestros huéspedes.	2023-06-11	2024-06-10
169	Convenio hotelero con Palomo-Crespo	Acuerdo entre el hotel y Palomo-Crespo para ofrecer servicios especiales a nuestros huéspedes.	2021-08-07	2022-08-07
170	Convenio hotelero con Valero, Bastida and Espinosa	Acuerdo entre el hotel y Valero, Bastida and Espinosa para ofrecer servicios especiales a nuestros huéspedes.	2021-11-02	2025-11-01
171	Convenio hotelero con Arcos PLC	Acuerdo entre el hotel y Arcos PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-08-18	2025-08-17
172	Convenio hotelero con Barranco LLC	Acuerdo entre el hotel y Barranco LLC para ofrecer servicios especiales a nuestros huéspedes.	2024-05-19	2026-05-19
173	Convenio hotelero con Mate-Arana	Acuerdo entre el hotel y Mate-Arana para ofrecer servicios especiales a nuestros huéspedes.	2021-02-17	2022-02-17
174	Convenio hotelero con Calzada-Tapia	Acuerdo entre el hotel y Calzada-Tapia para ofrecer servicios especiales a nuestros huéspedes.	2023-04-13	2025-04-12
175	Convenio hotelero con Cabañas Inc	Acuerdo entre el hotel y Cabañas Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-10-09	2023-10-09
176	Convenio hotelero con Ballester, Flores and Galán	Acuerdo entre el hotel y Ballester, Flores and Galán para ofrecer servicios especiales a nuestros huéspedes.	2022-10-14	2026-10-13
177	Convenio hotelero con Saldaña, Ureña and Aroca	Acuerdo entre el hotel y Saldaña, Ureña and Aroca para ofrecer servicios especiales a nuestros huéspedes.	2021-12-13	2023-12-13
178	Convenio hotelero con Pedraza, Codina and Varela	Acuerdo entre el hotel y Pedraza, Codina and Varela para ofrecer servicios especiales a nuestros huéspedes.	2020-11-23	2024-11-22
179	Convenio hotelero con León-Amigó	Acuerdo entre el hotel y León-Amigó para ofrecer servicios especiales a nuestros huéspedes.	2021-05-19	2025-05-18
180	Convenio hotelero con Lara, Criado and Reina	Acuerdo entre el hotel y Lara, Criado and Reina para ofrecer servicios especiales a nuestros huéspedes.	2020-10-30	2022-10-30
181	Convenio hotelero con Escamilla PLC	Acuerdo entre el hotel y Escamilla PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-22	2025-12-21
182	Convenio hotelero con Nieto, Tovar and Villalobos	Acuerdo entre el hotel y Nieto, Tovar and Villalobos para ofrecer servicios especiales a nuestros huéspedes.	2020-07-29	2023-07-29
183	Convenio hotelero con Lerma LLC	Acuerdo entre el hotel y Lerma LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-05-10	2024-05-09
184	Convenio hotelero con Lladó Group	Acuerdo entre el hotel y Lladó Group para ofrecer servicios especiales a nuestros huéspedes.	2023-05-29	2028-05-27
185	Convenio hotelero con Villegas and Sons	Acuerdo entre el hotel y Villegas and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-04-10	2024-04-09
186	Convenio hotelero con Fuster, Moraleda and Ariño	Acuerdo entre el hotel y Fuster, Moraleda and Ariño para ofrecer servicios especiales a nuestros huéspedes.	2022-12-14	2026-12-13
187	Convenio hotelero con Arregui, Pellicer and Pino	Acuerdo entre el hotel y Arregui, Pellicer and Pino para ofrecer servicios especiales a nuestros huéspedes.	2022-10-22	2023-10-22
188	Convenio hotelero con Olivares-Girón	Acuerdo entre el hotel y Olivares-Girón para ofrecer servicios especiales a nuestros huéspedes.	2022-06-03	2025-06-02
189	Convenio hotelero con Rozas-Briones	Acuerdo entre el hotel y Rozas-Briones para ofrecer servicios especiales a nuestros huéspedes.	2021-12-05	2025-12-04
190	Convenio hotelero con Peñalver and Sons	Acuerdo entre el hotel y Peñalver and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-08-17	2024-08-16
191	Convenio hotelero con Camino, Vicens and Bueno	Acuerdo entre el hotel y Camino, Vicens and Bueno para ofrecer servicios especiales a nuestros huéspedes.	2021-07-19	2022-07-19
192	Convenio hotelero con Rios Ltd	Acuerdo entre el hotel y Rios Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-09-20	2028-09-18
193	Convenio hotelero con Arjona, Moya and Núñez	Acuerdo entre el hotel y Arjona, Moya and Núñez para ofrecer servicios especiales a nuestros huéspedes.	2022-11-09	2025-11-08
194	Convenio hotelero con Pedraza Inc	Acuerdo entre el hotel y Pedraza Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-10-21	2021-10-21
195	Convenio hotelero con Rocha, Larrañaga and Padilla	Acuerdo entre el hotel y Rocha, Larrañaga and Padilla para ofrecer servicios especiales a nuestros huéspedes.	2022-07-10	2024-07-09
196	Convenio hotelero con Castrillo Ltd	Acuerdo entre el hotel y Castrillo Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-11-12	2024-11-11
197	Convenio hotelero con Morell LLC	Acuerdo entre el hotel y Morell LLC para ofrecer servicios especiales a nuestros huéspedes.	2020-08-29	2024-08-28
198	Convenio hotelero con Cobos, Mateo and Gelabert	Acuerdo entre el hotel y Cobos, Mateo and Gelabert para ofrecer servicios especiales a nuestros huéspedes.	2023-06-27	2025-06-26
199	Convenio hotelero con Bueno Inc	Acuerdo entre el hotel y Bueno Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-02-23	2027-02-22
200	Convenio hotelero con Esparza Group	Acuerdo entre el hotel y Esparza Group para ofrecer servicios especiales a nuestros huéspedes.	2022-04-06	2024-04-05
201	Convenio hotelero con Mendizábal-Calderón	Acuerdo entre el hotel y Mendizábal-Calderón para ofrecer servicios especiales a nuestros huéspedes.	2022-12-06	2024-12-05
202	Convenio hotelero con Aguiló, Alsina and Jurado	Acuerdo entre el hotel y Aguiló, Alsina and Jurado para ofrecer servicios especiales a nuestros huéspedes.	2022-05-31	2025-05-30
203	Convenio hotelero con Franch PLC	Acuerdo entre el hotel y Franch PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-05-03	2024-05-02
204	Convenio hotelero con Calleja PLC	Acuerdo entre el hotel y Calleja PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-10-30	2026-10-29
205	Convenio hotelero con Fuertes, Vendrell and Lasa	Acuerdo entre el hotel y Fuertes, Vendrell and Lasa para ofrecer servicios especiales a nuestros huéspedes.	2022-08-17	2025-08-16
206	Convenio hotelero con Mendoza Ltd	Acuerdo entre el hotel y Mendoza Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-05-20	2029-05-19
207	Convenio hotelero con Torres Ltd	Acuerdo entre el hotel y Torres Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-01-27	2027-01-26
208	Convenio hotelero con Barranco-Heredia	Acuerdo entre el hotel y Barranco-Heredia para ofrecer servicios especiales a nuestros huéspedes.	2020-11-08	2021-11-08
209	Convenio hotelero con Gomez-Ródenas	Acuerdo entre el hotel y Gomez-Ródenas para ofrecer servicios especiales a nuestros huéspedes.	2021-06-09	2025-06-08
210	Convenio hotelero con Garcés-Arranz	Acuerdo entre el hotel y Garcés-Arranz para ofrecer servicios especiales a nuestros huéspedes.	2022-04-30	2027-04-29
211	Convenio hotelero con Morán-Herrero	Acuerdo entre el hotel y Morán-Herrero para ofrecer servicios especiales a nuestros huéspedes.	2021-07-30	2023-07-30
212	Convenio hotelero con Alba Inc	Acuerdo entre el hotel y Alba Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-10-24	2026-10-23
213	Convenio hotelero con Arranz-Solís	Acuerdo entre el hotel y Arranz-Solís para ofrecer servicios especiales a nuestros huéspedes.	2022-01-07	2025-01-06
214	Convenio hotelero con Barreda, Cisneros and Simó	Acuerdo entre el hotel y Barreda, Cisneros and Simó para ofrecer servicios especiales a nuestros huéspedes.	2022-05-24	2026-05-23
215	Convenio hotelero con Fuente, Landa and Gargallo	Acuerdo entre el hotel y Fuente, Landa and Gargallo para ofrecer servicios especiales a nuestros huéspedes.	2020-08-09	2025-08-08
216	Convenio hotelero con Patiño, Gallego and Aliaga	Acuerdo entre el hotel y Patiño, Gallego and Aliaga para ofrecer servicios especiales a nuestros huéspedes.	2023-09-26	2027-09-25
217	Convenio Red Ocaña	Acuerdo entre el hotel y Moraleda, Barral and Gabaldón para ofrecer servicios especiales a nuestros huéspedes.	2023-01-27	2025-01-26
218	Convenio hotelero con Solano-Tolosa	Acuerdo entre el hotel y Solano-Tolosa para ofrecer servicios especiales a nuestros huéspedes.	2022-04-04	2023-04-04
219	Convenio hotelero con Pinedo, Poza and Gimenez	Acuerdo entre el hotel y Pinedo, Poza and Gimenez para ofrecer servicios especiales a nuestros huéspedes.	2022-07-30	2023-07-30
220	Convenio hotelero con Baños-Cornejo	Acuerdo entre el hotel y Baños-Cornejo para ofrecer servicios especiales a nuestros huéspedes.	2021-06-27	2026-06-26
221	Convenio hotelero con Asensio-Izquierdo	Acuerdo entre el hotel y Asensio-Izquierdo para ofrecer servicios especiales a nuestros huéspedes.	2022-02-21	2025-02-20
222	Convenio hotelero con Valcárcel Group	Acuerdo entre el hotel y Valcárcel Group para ofrecer servicios especiales a nuestros huéspedes.	2022-02-17	2027-02-16
223	Convenio hotelero con Aranda PLC	Acuerdo entre el hotel y Aranda PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-06-14	2024-06-13
224	Convenio hotelero con Manuel-Llanos	Acuerdo entre el hotel y Manuel-Llanos para ofrecer servicios especiales a nuestros huéspedes.	2024-02-22	2027-02-21
225	Convenio hotelero con Orozco Ltd	Acuerdo entre el hotel y Orozco Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-08-18	2027-08-17
226	Convenio hotelero con Cañete, Cabrera and Artigas	Acuerdo entre el hotel y Cañete, Cabrera and Artigas para ofrecer servicios especiales a nuestros huéspedes.	2020-09-15	2025-09-14
227	Convenio Martinez	Acuerdo entre el hotel y Manrique-Pacheco para ofrecer servicios especiales a nuestros huéspedes.	2022-11-04	2023-11-04
228	Convenio hotelero Fortuny	Acuerdo entre el hotel y Calderón, Borrego and Fortuny para ofrecer servicios especiales a nuestros huéspedes.	2020-09-25	2024-09-24
229	Convenio hotelero con Guzman-Bernat	Acuerdo entre el hotel y Guzman-Bernat para ofrecer servicios especiales a nuestros huéspedes.	2020-10-25	2022-10-25
230	Convenio hotelero con Español and Sons	Acuerdo entre el hotel y Español and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-12-31	2023-12-31
231	Convenio hotelero con Rebollo, Durán and Gonzalo	Acuerdo entre el hotel y Rebollo, Durán and Gonzalo para ofrecer servicios especiales a nuestros huéspedes.	2021-10-17	2026-10-16
232	Convenio hotelero con Quiroga, Hidalgo and Maestre	Acuerdo entre el hotel y Quiroga, Hidalgo and Maestre para ofrecer servicios especiales a nuestros huéspedes.	2022-02-20	2026-02-19
233	Convenio hotelero con Izquierdo-Pol	Acuerdo entre el hotel y Izquierdo-Pol para ofrecer servicios especiales a nuestros huéspedes.	2024-04-16	2025-04-16
234	Convenio hotelero con Aliaga-Valle	Acuerdo entre el hotel y Aliaga-Valle para ofrecer servicios especiales a nuestros huéspedes.	2020-10-08	2024-10-07
235	Convenio hotelero con Gálvez, Sevillano and Jurado	Acuerdo entre el hotel y Gálvez, Sevillano and Jurado para ofrecer servicios especiales a nuestros huéspedes.	2020-06-06	2021-06-06
236	Convenio hotelero con Valero-Casas	Acuerdo entre el hotel y Valero-Casas para ofrecer servicios especiales a nuestros huéspedes.	2022-10-16	2025-10-15
237	Convenio hotelero con Samper, Palacios and Río	Acuerdo entre el hotel y Samper, Palacios and Río para ofrecer servicios especiales a nuestros huéspedes.	2022-02-25	2027-02-24
238	Convenio hotelero con Herrera-Bueno	Acuerdo entre el hotel y Herrera-Bueno para ofrecer servicios especiales a nuestros huéspedes.	2024-01-17	2029-01-15
239	Convenio hotelero con Requena, Pacheco and Salinas	Acuerdo entre el hotel y Requena, Pacheco and Salinas para ofrecer servicios especiales a nuestros huéspedes.	2021-04-24	2024-04-23
240	Convenio hotelero con Carranza, Osorio and Recio	Acuerdo entre el hotel y Carranza, Osorio and Recio para ofrecer servicios especiales a nuestros huéspedes.	2020-11-23	2021-11-23
241	Convenio hotelero con Vázquez, Bernal and Valbuena	Acuerdo entre el hotel y Vázquez, Bernal and Valbuena para ofrecer servicios especiales a nuestros huéspedes.	2023-07-11	2024-07-10
242	Convenio hotelero con Reguera-Larrea	Acuerdo entre el hotel y Reguera-Larrea para ofrecer servicios especiales a nuestros huéspedes.	2020-12-05	2022-12-05
243	Convenio hotelero con Carreras-Caro	Acuerdo entre el hotel y Carreras-Caro para ofrecer servicios especiales a nuestros huéspedes.	2021-09-22	2022-09-22
244	Convenio hotelero con Río-Ferrán	Acuerdo entre el hotel y Río-Ferrán para ofrecer servicios especiales a nuestros huéspedes.	2022-02-27	2027-02-26
245	Convenio hotelero con Losada, Tirado and Llabrés	Acuerdo entre el hotel y Losada, Tirado and Llabrés para ofrecer servicios especiales a nuestros huéspedes.	2022-11-05	2024-11-04
246	Convenio hotelero con Lago, Uribe and Girón	Acuerdo entre el hotel y Lago, Uribe and Girón para ofrecer servicios especiales a nuestros huéspedes.	2023-11-22	2026-11-21
247	Convenio hotelero con Piquer Group	Acuerdo entre el hotel y Piquer Group para ofrecer servicios especiales a nuestros huéspedes.	2022-10-08	2024-10-07
248	Convenio hotelero con Heras-Garcia	Acuerdo entre el hotel y Heras-Garcia para ofrecer servicios especiales a nuestros huéspedes.	2022-01-13	2025-01-12
249	Convenio hotelero con Nevado Group	Acuerdo entre el hotel y Nevado Group para ofrecer servicios especiales a nuestros huéspedes.	2023-01-05	2027-01-04
250	Convenio hotelero con Chico, Sanabria and Aguilera	Acuerdo entre el hotel y Chico, Sanabria and Aguilera para ofrecer servicios especiales a nuestros huéspedes.	2021-02-21	2026-02-20
251	Convenio hotelero con Trillo PLC	Acuerdo entre el hotel y Trillo PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-05-13	2026-05-12
252	Convenio hotelero con Toro-Llamas	Acuerdo entre el hotel y Toro-Llamas para ofrecer servicios especiales a nuestros huéspedes.	2024-03-05	2028-03-04
253	Convenio hotelero con Talavera PLC	Acuerdo entre el hotel y Talavera PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-05-29	2023-05-29
254	Convenio hotelero con Marquez, Garcia and Castro	Acuerdo entre el hotel y Marquez, Garcia and Castro para ofrecer servicios especiales a nuestros huéspedes.	2020-10-17	2023-10-17
255	Convenio hotelero con Rosales-Barranco	Acuerdo entre el hotel y Rosales-Barranco para ofrecer servicios especiales a nuestros huéspedes.	2022-09-23	2026-09-22
256	Convenio hotelero con Álvaro-Uriarte	Acuerdo entre el hotel y Álvaro-Uriarte para ofrecer servicios especiales a nuestros huéspedes.	2022-03-10	2025-03-09
257	Convenio hotelero con Corominas, Pozuelo and Bosch	Acuerdo entre el hotel y Corominas, Pozuelo and Bosch para ofrecer servicios especiales a nuestros huéspedes.	2023-03-09	2024-03-08
258	Convenio hotelero con Ferrán, Lloret and Rosselló	Acuerdo entre el hotel y Ferrán, Lloret and Rosselló para ofrecer servicios especiales a nuestros huéspedes.	2024-01-24	2029-01-22
259	Convenio hotelero con Calderon-Pla	Acuerdo entre el hotel y Calderon-Pla para ofrecer servicios especiales a nuestros huéspedes.	2022-03-20	2023-03-20
260	Convenio hotelero con Suárez Inc	Acuerdo entre el hotel y Suárez Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-03-21	2024-03-20
261	Convenio hotelero con Menendez-Pozuelo	Acuerdo entre el hotel y Menendez-Pozuelo para ofrecer servicios especiales a nuestros huéspedes.	2022-02-22	2024-02-22
262	Convenio hotelero con Castelló, Gonzalo and Jordán	Acuerdo entre el hotel y Castelló, Gonzalo and Jordán para ofrecer servicios especiales a nuestros huéspedes.	2024-03-26	2029-03-25
263	Convenio hotelero con Luque, Prat and Calatayud	Acuerdo entre el hotel y Luque, Prat and Calatayud para ofrecer servicios especiales a nuestros huéspedes.	2024-05-23	2029-05-22
264	Convenio hotelero Pérez and Lumbreras	Acuerdo entre el hotel y Bustamante, Pérez and Lumbreras para ofrecer servicios especiales a nuestros huéspedes.	2023-10-10	2027-10-09
265	Convenio hotelero con Toro, Ribera and Tejedor	Acuerdo entre el hotel y Toro, Ribera and Tejedor para ofrecer servicios especiales a nuestros huéspedes.	2021-03-16	2025-03-15
266	Convenio hotelero con Lara-Coloma	Acuerdo entre el hotel y Lara-Coloma para ofrecer servicios especiales a nuestros huéspedes.	2021-10-27	2026-10-26
267	Convenio hotelero con Samper-Sáenz	Acuerdo entre el hotel y Samper-Sáenz para ofrecer servicios especiales a nuestros huéspedes.	2022-06-27	2025-06-26
268	Convenio hotelero con Feliu and Sons	Acuerdo entre el hotel y Feliu and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-08-26	2024-08-25
269	Convenio hotelero con Coronado-Cordero	Acuerdo entre el hotel y Coronado-Cordero para ofrecer servicios especiales a nuestros huéspedes.	2022-02-18	2025-02-17
270	Convenio hotelero con Suarez and Sons	Acuerdo entre el hotel y Suarez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-09-17	2026-09-16
271	Convenio hotelero con Porta Inc	Acuerdo entre el hotel y Porta Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-02-25	2024-02-25
272	Convenio hotelero con Moles-Cabrero	Acuerdo entre el hotel y Moles-Cabrero para ofrecer servicios especiales a nuestros huéspedes.	2022-04-29	2024-04-28
273	Convenio hotelero con Ocaña Ltd	Acuerdo entre el hotel y Ocaña Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-01-01	2026-12-31
274	Convenio hotelero con Hervia-Perez	Acuerdo entre el hotel y Hervia-Perez para ofrecer servicios especiales a nuestros huéspedes.	2021-09-05	2026-09-04
275	Convenio hotelero con Jaume-Vila	Acuerdo entre el hotel y Jaume-Vila para ofrecer servicios especiales a nuestros huéspedes.	2021-10-17	2023-10-17
276	Convenio hotelero con Ribes-Garmendia	Acuerdo entre el hotel y Ribes-Garmendia para ofrecer servicios especiales a nuestros huéspedes.	2023-01-04	2028-01-03
277	Convenio hotelero con Vives	Acuerdo entre el hotel y Vives, Sarmiento and Chaparro para ofrecer servicios especiales a nuestros huéspedes.	2021-10-16	2024-10-15
278	Convenio hotelero con Gual-Villaverde	Acuerdo entre el hotel y Gual-Villaverde para ofrecer servicios especiales a nuestros huéspedes.	2020-12-18	2023-12-18
279	Convenio hotelero con Cadenas, Otero and Roig	Acuerdo entre el hotel y Cadenas, Otero and Roig para ofrecer servicios especiales a nuestros huéspedes.	2020-08-24	2025-08-23
280	Convenio hotelero con Carreño, Lluch and Corbacho	Acuerdo entre el hotel y Carreño, Lluch and Corbacho para ofrecer servicios especiales a nuestros huéspedes.	2023-02-05	2024-02-05
281	Convenio hotelero con Canals, Alvarado and Morales	Acuerdo entre el hotel y Canals, Alvarado and Morales para ofrecer servicios especiales a nuestros huéspedes.	2022-04-25	2024-04-24
282	Convenio hotelero con Acuña, Torrent and Murcia	Acuerdo entre el hotel y Acuña, Torrent and Murcia para ofrecer servicios especiales a nuestros huéspedes.	2021-11-16	2023-11-16
283	Convenio hotelero con Machado Group	Acuerdo entre el hotel y Machado Group para ofrecer servicios especiales a nuestros huéspedes.	2024-02-14	2029-02-12
284	Convenio hotelero con Castejón-Arnal	Acuerdo entre el hotel y Castejón-Arnal para ofrecer servicios especiales a nuestros huéspedes.	2020-11-27	2023-11-27
285	Convenio hotelero con Fábregas Group	Acuerdo entre el hotel y Fábregas Group para ofrecer servicios especiales a nuestros huéspedes.	2023-08-17	2024-08-16
286	Convenio hotelero con Rincón, Guzmán and Mariscal	Acuerdo entre el hotel y Rincón, Guzmán and Mariscal para ofrecer servicios especiales a nuestros huéspedes.	2022-03-11	2024-03-10
287	Convenio hotelero con Vilar PLC	Acuerdo entre el hotel y Vilar PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-01-14	2024-01-14
288	Convenio hotelero con Pagès, Ayala and Palomino	Acuerdo entre el hotel y Pagès, Ayala and Palomino para ofrecer servicios especiales a nuestros huéspedes.	2021-11-02	2024-11-01
289	Convenio hotelero con Miranda Group	Acuerdo entre el hotel y Miranda Group para ofrecer servicios especiales a nuestros huéspedes.	2022-09-16	2025-09-15
290	Convenio hotelero con López-Matas	Acuerdo entre el hotel y López-Matas para ofrecer servicios especiales a nuestros huéspedes.	2022-12-29	2025-12-28
291	Convenio hotelero con Pomares, Toro and Peña	Acuerdo entre el hotel y Pomares, Toro and Peña para ofrecer servicios especiales a nuestros huéspedes.	2023-06-13	2025-06-12
292	Convenio hotelero con España-Sanmiguel	Acuerdo entre el hotel y España-Sanmiguel para ofrecer servicios especiales a nuestros huéspedes.	2022-07-23	2025-07-22
293	Convenio hotelero con Serna Group	Acuerdo entre el hotel y Serna Group para ofrecer servicios especiales a nuestros huéspedes.	2024-05-04	2027-05-04
294	Convenio hotelero con Vilalta, Bastida and Reig	Acuerdo entre el hotel y Vilalta, Bastida and Reig para ofrecer servicios especiales a nuestros huéspedes.	2023-04-16	2026-04-15
295	Convenio hotelero con Escobar, Peláez and Serra	Acuerdo entre el hotel y Escobar, Peláez and Serra para ofrecer servicios especiales a nuestros huéspedes.	2023-06-23	2026-06-22
296	Convenio hotelero con Romero, Atienza and Ramis	Acuerdo entre el hotel y Romero, Atienza and Ramis para ofrecer servicios especiales a nuestros huéspedes.	2024-05-08	2028-05-07
297	Convenio hotelero con Valcárcel PLC	Acuerdo entre el hotel y Valcárcel PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-11-27	2025-11-26
298	Convenio hotelero con Escalona, Martín and Cid	Acuerdo entre el hotel y Escalona, Martín and Cid para ofrecer servicios especiales a nuestros huéspedes.	2023-10-30	2027-10-29
299	Convenio hotelero con Comas, Medina and Abellán	Acuerdo entre el hotel y Comas, Medina and Abellán para ofrecer servicios especiales a nuestros huéspedes.	2022-05-02	2025-05-01
300	Convenio hotelero con Valls, Roselló and Velázquez	Acuerdo entre el hotel y Valls, Roselló and Velázquez para ofrecer servicios especiales a nuestros huéspedes.	2023-05-14	2025-05-13
301	Convenio hotelero con Jáuregui Ltd	Acuerdo entre el hotel y Jáuregui Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-07-20	2022-07-20
302	Convenio hotelero con Lloret, Sans and Meléndez	Acuerdo entre el hotel y Lloret, Sans and Meléndez para ofrecer servicios especiales a nuestros huéspedes.	2023-06-21	2026-06-20
303	Convenio hotelero con Viana PLC	Acuerdo entre el hotel y Viana PLC para ofrecer servicios especiales a nuestros huéspedes.	2024-03-30	2028-03-29
304	Convenio hotelero con Galvez, Seco and Oliveras	Acuerdo entre el hotel y Galvez, Seco and Oliveras para ofrecer servicios especiales a nuestros huéspedes.	2023-04-19	2025-04-18
305	Convenio hotelero con Acevedo, Redondo and Carreño	Acuerdo entre el hotel y Acevedo, Redondo and Carreño para ofrecer servicios especiales a nuestros huéspedes.	2024-04-18	2027-04-18
306	Convenio hotelero con Benito Ltd	Acuerdo entre el hotel y Benito Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-06-06	2026-06-05
307	Convenio hotelero con Clemente-Vall	Acuerdo entre el hotel y Clemente-Vall para ofrecer servicios especiales a nuestros huéspedes.	2021-01-23	2026-01-22
308	Convenio hotelero con Páez, Pereira and Montserrat	Acuerdo entre el hotel y Páez, Pereira and Montserrat para ofrecer servicios especiales a nuestros huéspedes.	2021-03-29	2023-03-29
309	Convenio hotelero con Esteban-Zaragoza	Acuerdo entre el hotel y Esteban-Zaragoza para ofrecer servicios especiales a nuestros huéspedes.	2022-09-01	2026-08-31
310	Convenio hotelero con Tello Ltd	Acuerdo entre el hotel y Tello Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-07-31	2023-07-31
311	Convenio hotelero con Rodrigo-Almazán	Acuerdo entre el hotel y Rodrigo-Almazán para ofrecer servicios especiales a nuestros huéspedes.	2022-02-23	2024-02-23
312	Convenio hotelero Escamilla	Acuerdo entre el hotel y Jara, Pol and Escamilla para ofrecer servicios especiales a nuestros huéspedes.	2022-07-15	2027-07-14
313	Convenio hotelero Villalobos	Acuerdo entre el hotel y Miralles, Reig and Villalobos para ofrecer servicios especiales a nuestros huéspedes.	2023-03-13	2025-03-12
314	Convenio hotelero con Crespi-Belmonte	Acuerdo entre el hotel y Crespi-Belmonte para ofrecer servicios especiales a nuestros huéspedes.	2021-10-05	2024-10-04
315	Convenio hotelero con Adadia-Valdés	Acuerdo entre el hotel y Adadia-Valdés para ofrecer servicios especiales a nuestros huéspedes.	2024-01-22	2027-01-21
316	Convenio hotelero con Leal-Dueñas	Acuerdo entre el hotel y Leal-Dueñas para ofrecer servicios especiales a nuestros huéspedes.	2022-12-31	2026-12-30
317	Convenio hotelero con Mayo PLC	Acuerdo entre el hotel y Mayo PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-03-26	2024-03-25
318	Convenio hotelero con Cuesta Inc	Acuerdo entre el hotel y Cuesta Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-11-28	2024-11-27
319	Convenio hotelero con Santana, Arteaga and Bárcena	Acuerdo entre el hotel y Santana, Arteaga and Bárcena para ofrecer servicios especiales a nuestros huéspedes.	2024-01-05	2025-01-04
320	Convenio hotelero con Villalonga-Anglada	Acuerdo entre el hotel y Villalonga-Anglada para ofrecer servicios especiales a nuestros huéspedes.	2021-07-05	2026-07-04
321	Convenio hotelero con Báez-Machado	Acuerdo entre el hotel y Báez-Machado para ofrecer servicios especiales a nuestros huéspedes.	2024-02-29	2026-02-28
322	Convenio hotelero con Moreno-Ariño	Acuerdo entre el hotel y Moreno-Ariño para ofrecer servicios especiales a nuestros huéspedes.	2023-05-24	2027-05-23
323	Convenio hotelero con Bru-Agustín	Acuerdo entre el hotel y Bru-Agustín para ofrecer servicios especiales a nuestros huéspedes.	2024-03-21	2025-03-21
324	Convenio hotelero con Cortina, Losada and Arellano	Acuerdo entre el hotel y Cortina, Losada and Arellano para ofrecer servicios especiales a nuestros huéspedes.	2023-08-05	2025-08-04
325	Convenio hotelero con Rosell Inc	Acuerdo entre el hotel y Rosell Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-12-03	2026-12-02
326	Convenio Bautista Roldan	Acuerdo entre el hotel y Bautista, Riquelme and Roldan para ofrecer servicios especiales a nuestros huéspedes.	2020-09-26	2022-09-26
327	Convenio hotelero con Mendizábal	Acuerdo entre el hotel y Mendizábal, Roselló and Sevilla para ofrecer servicios especiales a nuestros huéspedes.	2021-08-08	2024-08-07
328	Convenio hotelero con Landa-Miralles	Acuerdo entre el hotel y Landa-Miralles para ofrecer servicios especiales a nuestros huéspedes.	2020-12-31	2022-12-31
329	Convenio hotelero con Gabaldón Ltd	Acuerdo entre el hotel y Gabaldón Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-12-20	2026-12-19
330	Convenio hotelero con Giner, Solera and Coello	Acuerdo entre el hotel y Giner, Solera and Coello para ofrecer servicios especiales a nuestros huéspedes.	2021-09-02	2024-09-01
331	Convenio hotelero con Rios Group	Acuerdo entre el hotel y Rios Group para ofrecer servicios especiales a nuestros huéspedes.	2023-10-03	2028-10-01
332	Convenio hotelero con Niño and Sons	Acuerdo entre el hotel y Niño and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-06-04	2025-06-03
333	Convenio hotelero con Águila and Sons	Acuerdo entre el hotel y Águila and Sons para ofrecer servicios especiales a nuestros huéspedes.	2024-03-22	2025-03-22
334	Convenio hotelero con Andrés-Sáez	Acuerdo entre el hotel y Andrés-Sáez para ofrecer servicios especiales a nuestros huéspedes.	2023-01-02	2028-01-01
335	Convenio hotelero con Baquero-Simó	Acuerdo entre el hotel y Baquero-Simó para ofrecer servicios especiales a nuestros huéspedes.	2020-06-10	2022-06-10
336	Convenio hotelero con Pou, Doménech and Cerezo	Acuerdo entre el hotel y Pou, Doménech and Cerezo para ofrecer servicios especiales a nuestros huéspedes.	2020-12-25	2022-12-25
337	Convenio hotelero con Sainz Inc	Acuerdo entre el hotel y Sainz Inc para ofrecer servicios especiales a nuestros huéspedes.	2024-04-27	2025-04-27
338	Convenio hotelero con Río-Figueroa	Acuerdo entre el hotel y Río-Figueroa para ofrecer servicios especiales a nuestros huéspedes.	2022-05-08	2027-05-07
339	Convenio hotelero con Valcárcel-Ávila	Acuerdo entre el hotel y Valcárcel-Ávila para ofrecer servicios especiales a nuestros huéspedes.	2022-01-14	2027-01-13
340	Convenio hotelero con Escrivá and Sons	Acuerdo entre el hotel y Escrivá and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-06-01	2024-05-31
341	Convenio hotelero con Padilla, Dalmau and Catalán	Acuerdo entre el hotel y Padilla, Dalmau and Catalán para ofrecer servicios especiales a nuestros huéspedes.	2024-05-09	2027-05-09
342	Convenio hotelero con Ocaña and Sons	Acuerdo entre el hotel y Ocaña and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-02-12	2027-02-11
343	Convenio hotelero con Leal, Otero and Marcos	Acuerdo entre el hotel y Leal, Otero and Marcos para ofrecer servicios especiales a nuestros huéspedes.	2022-12-18	2023-12-18
344	Convenio hotelero con Boada-Morillo	Acuerdo entre el hotel y Boada-Morillo para ofrecer servicios especiales a nuestros huéspedes.	2022-12-23	2026-12-22
345	Convenio hotelero con Morante, Salazar and Anaya	Acuerdo entre el hotel y Morante, Salazar and Anaya para ofrecer servicios especiales a nuestros huéspedes.	2023-12-05	2028-12-03
346	Convenio hotelero con Lamas, Carrillo and Urrutia	Acuerdo entre el hotel y Lamas, Carrillo and Urrutia para ofrecer servicios especiales a nuestros huéspedes.	2020-11-27	2022-11-27
347	Convenio hotelero con Carreño, Alcaraz and Malo	Acuerdo entre el hotel y Carreño, Alcaraz and Malo para ofrecer servicios especiales a nuestros huéspedes.	2022-08-31	2023-08-31
348	Convenio hotelero con Rueda-Barceló	Acuerdo entre el hotel y Rueda-Barceló para ofrecer servicios especiales a nuestros huéspedes.	2023-07-01	2026-06-30
349	Convenio hotelero con Pont, Antúnez and Porras	Acuerdo entre el hotel y Pont, Antúnez and Porras para ofrecer servicios especiales a nuestros huéspedes.	2024-03-28	2029-03-27
350	Convenio hotelero con Rey, Fiol and Vives	Acuerdo entre el hotel y Rey, Fiol and Vives para ofrecer servicios especiales a nuestros huéspedes.	2021-04-09	2024-04-08
351	Convenio hotelero con Figueras Group	Acuerdo entre el hotel y Figueras Group para ofrecer servicios especiales a nuestros huéspedes.	2020-09-23	2021-09-23
352	Convenio hotelero con Laguna, Manrique and Guardia	Acuerdo entre el hotel y Laguna, Manrique and Guardia para ofrecer servicios especiales a nuestros huéspedes.	2021-01-10	2024-01-10
353	Convenio hotelero con Badía LLC	Acuerdo entre el hotel y Badía LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-24	2025-12-23
354	Convenio hotelero con Moliner Group	Acuerdo entre el hotel y Moliner Group para ofrecer servicios especiales a nuestros huéspedes.	2022-05-18	2023-05-18
355	Convenio hotelero con Fuentes, Ferrándiz and Lara	Acuerdo entre el hotel y Fuentes, Ferrándiz and Lara para ofrecer servicios especiales a nuestros huéspedes.	2023-04-05	2025-04-04
356	Convenio hotelero con Cepeda Group	Acuerdo entre el hotel y Cepeda Group para ofrecer servicios especiales a nuestros huéspedes.	2020-10-11	2024-10-10
357	Convenio hotelero con Sevilla-Santana	Acuerdo entre el hotel y Sevilla-Santana para ofrecer servicios especiales a nuestros huéspedes.	2023-06-30	2028-06-28
358	Convenio hotelero con España, Farré and Blasco	Acuerdo entre el hotel y España, Farré and Blasco para ofrecer servicios especiales a nuestros huéspedes.	2022-04-10	2027-04-09
359	Convenio hotelero con Tovar-Iglesias	Acuerdo entre el hotel y Tovar-Iglesias para ofrecer servicios especiales a nuestros huéspedes.	2023-11-02	2024-11-01
360	Convenio hotelero con Zamorano, Muro and Mayoral	Acuerdo entre el hotel y Zamorano, Muro and Mayoral para ofrecer servicios especiales a nuestros huéspedes.	2022-06-23	2026-06-22
361	Convenio hotelero con Cortes-Almagro	Acuerdo entre el hotel y Cortes-Almagro para ofrecer servicios especiales a nuestros huéspedes.	2023-07-18	2025-07-17
362	Convenio hotelero con Bonilla and Sons	Acuerdo entre el hotel y Bonilla and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-09-06	2023-09-06
363	Convenio hotelero con Mayol, Montaña and Serna	Acuerdo entre el hotel y Mayol, Montaña and Serna para ofrecer servicios especiales a nuestros huéspedes.	2021-10-24	2025-10-23
364	Convenio hotelero con Barranco-Murillo	Acuerdo entre el hotel y Barranco-Murillo para ofrecer servicios especiales a nuestros huéspedes.	2022-08-17	2024-08-16
365	Convenio hotelero con Oliver Acuña	Acuerdo entre el hotel y Oliveras, Villalonga and Acuña para ofrecer servicios especiales a nuestros huéspedes.	2020-09-06	2024-09-05
366	Convenio hotelero Almeida	Acuerdo entre el hotel y Cabezas, Caparrós and Almeida para ofrecer servicios especiales a nuestros huéspedes.	2020-07-29	2021-07-29
367	Convenio hotelero con Mendez-Montesinos	Acuerdo entre el hotel y Mendez-Montesinos para ofrecer servicios especiales a nuestros huéspedes.	2023-02-05	2027-02-04
368	Convenio hotelero con Jaume-Merino	Acuerdo entre el hotel y Jaume-Merino para ofrecer servicios especiales a nuestros huéspedes.	2022-08-31	2024-08-30
369	Convenio hotelero con Blasco LLC	Acuerdo entre el hotel y Blasco LLC para ofrecer servicios especiales a nuestros huéspedes.	2020-06-14	2023-06-14
370	Convenio hotelero con Palomares, Royo and Plaza	Acuerdo entre el hotel y Palomares, Royo and Plaza para ofrecer servicios especiales a nuestros huéspedes.	2024-02-09	2029-02-07
371	Convenio hotelero con Múñiz, Iriarte and Jaume	Acuerdo entre el hotel y Múñiz, Iriarte and Jaume para ofrecer servicios especiales a nuestros huéspedes.	2023-05-03	2026-05-02
372	Convenio hotelero con Gaya, Múgica and Jódar	Acuerdo entre el hotel y Gaya, Múgica and Jódar para ofrecer servicios especiales a nuestros huéspedes.	2023-02-14	2028-02-13
373	Convenio hotelero con Quintanilla PLC	Acuerdo entre el hotel y Quintanilla PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-10-11	2027-10-10
374	Convenio hotelero con Viñas-Tolosa	Acuerdo entre el hotel y Viñas-Tolosa para ofrecer servicios especiales a nuestros huéspedes.	2023-04-04	2027-04-03
375	Convenio hotelero Ferrándiz	Acuerdo entre el hotel y Pedraza, Suárez and Ferrándiz para ofrecer servicios especiales a nuestros huéspedes.	2024-01-02	2027-01-01
376	Convenio hotelero con Puerta-Araujo	Acuerdo entre el hotel y Puerta-Araujo para ofrecer servicios especiales a nuestros huéspedes.	2023-02-24	2024-02-24
377	Convenio hotelero con Marqués Group	Acuerdo entre el hotel y Marqués Group para ofrecer servicios especiales a nuestros huéspedes.	2023-06-08	2026-06-07
378	Convenio hotelero con Cañete-Cruz	Acuerdo entre el hotel y Cañete-Cruz para ofrecer servicios especiales a nuestros huéspedes.	2022-08-17	2025-08-16
379	Convenio hotelero con Ribera, Benítez and Viana	Acuerdo entre el hotel y Ribera, Benítez and Viana para ofrecer servicios especiales a nuestros huéspedes.	2021-08-22	2023-08-22
380	Convenio hotelero con Palmer and Sons	Acuerdo entre el hotel y Palmer and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-02-20	2024-02-20
381	Convenio hotelero con Esteve-Cobo	Acuerdo entre el hotel y Esteve-Cobo para ofrecer servicios especiales a nuestros huéspedes.	2023-07-14	2028-07-12
382	Convenio hotelero con Milla, Vila and Morillo	Acuerdo entre el hotel y Milla, Vila and Morillo para ofrecer servicios especiales a nuestros huéspedes.	2021-04-09	2024-04-08
383	Convenio hotelero con Mena, Blanch and Valera	Acuerdo entre el hotel y Mena, Blanch and Valera para ofrecer servicios especiales a nuestros huéspedes.	2022-07-12	2026-07-11
384	Convenio hotelero con Gárate, Morales and Prat	Acuerdo entre el hotel y Gárate, Morales and Prat para ofrecer servicios especiales a nuestros huéspedes.	2023-08-26	2024-08-25
385	Convenio hotelero con Tejada-Galván	Acuerdo entre el hotel y Tejada-Galván para ofrecer servicios especiales a nuestros huéspedes.	2023-05-23	2024-05-22
386	Convenio hotelero con Cantón-Pellicer	Acuerdo entre el hotel y Cantón-Pellicer para ofrecer servicios especiales a nuestros huéspedes.	2022-02-01	2027-01-31
387	Convenio hotelero con Ortiz, Jara and Herrero	Acuerdo entre el hotel y Ortiz, Jara and Herrero para ofrecer servicios especiales a nuestros huéspedes.	2022-05-16	2026-05-15
388	Convenio hotelero con Sedano LLC	Acuerdo entre el hotel y Sedano LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-01-04	2026-01-03
389	Convenio hotelero con Piquer-Jaén	Acuerdo entre el hotel y Piquer-Jaén para ofrecer servicios especiales a nuestros huéspedes.	2022-04-25	2024-04-24
390	Convenio hotelero con Araujo, Llopis and Mínguez	Acuerdo entre el hotel y Araujo, Llopis and Mínguez para ofrecer servicios especiales a nuestros huéspedes.	2024-04-04	2026-04-04
391	Convenio hotelero con Luís Inc	Acuerdo entre el hotel y Luís Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-10-21	2023-10-21
392	Convenio hotelero con Alberola Ltd	Acuerdo entre el hotel y Alberola Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-06-05	2026-06-04
393	Convenio hotelero con Sáez and Sons	Acuerdo entre el hotel y Sáez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-01-15	2023-01-15
394	Convenio hotelero con Portillo Group	Acuerdo entre el hotel y Portillo Group para ofrecer servicios especiales a nuestros huéspedes.	2022-08-13	2023-08-13
395	Convenio hotelero con Feliu and Sons	Acuerdo entre el hotel y Feliu and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-09-21	2024-09-20
396	Convenio hotelero con Sobrino-Bolaños	Acuerdo entre el hotel y Sobrino-Bolaños para ofrecer servicios especiales a nuestros huéspedes.	2020-10-12	2021-10-12
397	Convenio hotelero con Ródenas, Porras and Arco	Acuerdo entre el hotel y Ródenas, Porras and Arco para ofrecer servicios especiales a nuestros huéspedes.	2022-12-09	2026-12-08
398	Convenio hotelero con Soria PLC	Acuerdo entre el hotel y Soria PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-09-01	2025-08-31
399	Convenio hotelero con Agudo Group	Acuerdo entre el hotel y Agudo Group para ofrecer servicios especiales a nuestros huéspedes.	2020-12-07	2025-12-06
400	Convenio hotelero con Sánchez, Salom and Larrea	Acuerdo entre el hotel y Sánchez, Salom and Larrea para ofrecer servicios especiales a nuestros huéspedes.	2022-05-13	2024-05-12
401	Convenio hotelero con Artigas-Mármol	Acuerdo entre el hotel y Artigas-Mármol para ofrecer servicios especiales a nuestros huéspedes.	2021-01-28	2023-01-28
402	Convenio hotelero con Anguita-Coca	Acuerdo entre el hotel y Anguita-Coca para ofrecer servicios especiales a nuestros huéspedes.	2021-11-25	2026-11-24
403	Convenio hotelero con Ayuso, Jaume and Nogués	Acuerdo entre el hotel y Ayuso, Jaume and Nogués para ofrecer servicios especiales a nuestros huéspedes.	2021-04-05	2024-04-04
404	Convenio hotelero con López-Jordán	Acuerdo entre el hotel y López-Jordán para ofrecer servicios especiales a nuestros huéspedes.	2023-05-15	2027-05-14
405	Convenio hotelero con Cañizares-Borrás	Acuerdo entre el hotel y Cañizares-Borrás para ofrecer servicios especiales a nuestros huéspedes.	2022-02-19	2023-02-19
406	Convenio hotelero con Llopis LLC	Acuerdo entre el hotel y Llopis LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-09-09	2024-09-08
407	Convenio hotelero con España PLC	Acuerdo entre el hotel y España PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-28	2023-12-28
408	Convenio hotelero con Coloma Ltd	Acuerdo entre el hotel y Coloma Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-03-30	2028-03-29
409	Convenio hotelero con Zorrilla, Estevez and Lago	Acuerdo entre el hotel y Zorrilla, Estevez and Lago para ofrecer servicios especiales a nuestros huéspedes.	2023-07-08	2024-07-07
410	Convenio hotelero con Abad-Olmo	Acuerdo entre el hotel y Abad-Olmo para ofrecer servicios especiales a nuestros huéspedes.	2020-08-03	2025-08-02
411	Convenio hotelero con Cortina-Mosquera	Acuerdo entre el hotel y Cortina-Mosquera para ofrecer servicios especiales a nuestros huéspedes.	2022-02-17	2023-02-17
412	Convenio hotelero con Porta-Alcántara	Acuerdo entre el hotel y Porta-Alcántara para ofrecer servicios especiales a nuestros huéspedes.	2022-05-22	2024-05-21
413	Convenio hotelero con Palomo, Guzmán and Malo	Acuerdo entre el hotel y Palomo, Guzmán and Malo para ofrecer servicios especiales a nuestros huéspedes.	2024-04-12	2028-04-11
414	Convenio hotelero con Guardiola LLC	Acuerdo entre el hotel y Guardiola LLC para ofrecer servicios especiales a nuestros huéspedes.	2021-05-19	2026-05-18
415	Convenio hotelero con Amigó LLC	Acuerdo entre el hotel y Amigó LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-08-29	2023-08-29
416	Convenio hotelero con Oliveras PLC	Acuerdo entre el hotel y Oliveras PLC para ofrecer servicios especiales a nuestros huéspedes.	2024-03-25	2025-03-25
417	Convenio hotelero con Campo PLC	Acuerdo entre el hotel y Campo PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-02-09	2023-02-09
418	Convenio hotelero con Juan, Mir and Galan	Acuerdo entre el hotel y Juan, Mir and Galan para ofrecer servicios especiales a nuestros huéspedes.	2020-09-11	2023-09-11
419	Convenio hotelero con Ortuño Inc	Acuerdo entre el hotel y Ortuño Inc para ofrecer servicios especiales a nuestros huéspedes.	2024-03-30	2025-03-30
420	Convenio hotelero con Beltrán, Alonso and Rivero	Acuerdo entre el hotel y Beltrán, Alonso and Rivero para ofrecer servicios especiales a nuestros huéspedes.	2023-12-30	2027-12-29
421	Convenio hotelero con Zamora and Sons	Acuerdo entre el hotel y Zamora and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-11-08	2022-11-08
422	Convenio hotelero con Lloret, Posada and Lozano	Acuerdo entre el hotel y Lloret, Posada and Lozano para ofrecer servicios especiales a nuestros huéspedes.	2023-01-22	2024-01-22
423	Convenio hotelero con Andrés, Montero and Durán	Acuerdo entre el hotel y Andrés, Montero and Durán para ofrecer servicios especiales a nuestros huéspedes.	2023-10-04	2027-10-03
424	Convenio hotelero con Mínguez Group	Acuerdo entre el hotel y Mínguez Group para ofrecer servicios especiales a nuestros huéspedes.	2022-04-04	2023-04-04
425	Convenio hotelero con Anglada, Ojeda and Pavón	Acuerdo entre el hotel y Anglada, Ojeda and Pavón para ofrecer servicios especiales a nuestros huéspedes.	2020-06-05	2025-06-04
426	Convenio hotelero con Terrón-Pardo	Acuerdo entre el hotel y Terrón-Pardo para ofrecer servicios especiales a nuestros huéspedes.	2024-04-19	2027-04-19
427	Convenio hotelero con Conesa LLC	Acuerdo entre el hotel y Conesa LLC para ofrecer servicios especiales a nuestros huéspedes.	2020-12-22	2021-12-22
428	Convenio hotelero con Carreño, Rico and Rueda	Acuerdo entre el hotel y Carreño, Rico and Rueda para ofrecer servicios especiales a nuestros huéspedes.	2024-05-02	2025-05-02
429	Convenio hotelero con Bermejo-Marí	Acuerdo entre el hotel y Bermejo-Marí para ofrecer servicios especiales a nuestros huéspedes.	2022-02-18	2026-02-17
430	Convenio hotelero con Escribano-Galán	Acuerdo entre el hotel y Escribano-Galán para ofrecer servicios especiales a nuestros huéspedes.	2022-11-09	2023-11-09
431	Convenio hotelero con Jáuregui and Sons	Acuerdo entre el hotel y Jáuregui and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-08-04	2024-08-03
432	Convenio hotelero con Pombo-Mendizábal	Acuerdo entre el hotel y Pombo-Mendizábal para ofrecer servicios especiales a nuestros huéspedes.	2020-12-28	2022-12-28
433	Convenio Calatayud	Acuerdo entre el hotel y Suárez, Campillo and Calatayud para ofrecer servicios especiales a nuestros huéspedes.	2022-08-04	2023-08-04
434	Convenio hotelero con Santiago Ltd	Acuerdo entre el hotel y Santiago Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-07-21	2025-07-20
435	Convenio hotelero con Mateos, Segovia and Parejo	Acuerdo entre el hotel y Mateos, Segovia and Parejo para ofrecer servicios especiales a nuestros huéspedes.	2021-01-08	2024-01-08
436	Convenio hotelero con Valverde Inc	Acuerdo entre el hotel y Valverde Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-07-24	2026-07-23
437	Convenio hotelero con Blazquez, Saez and Tena	Acuerdo entre el hotel y Blazquez, Saez and Tena para ofrecer servicios especiales a nuestros huéspedes.	2020-10-27	2021-10-27
438	Convenio hotelero con Prado and Sons	Acuerdo entre el hotel y Prado and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-06-11	2022-06-11
439	Convenio hotelero con Meléndez, Vigil and Acedo	Acuerdo entre el hotel y Meléndez, Vigil and Acedo para ofrecer servicios especiales a nuestros huéspedes.	2022-02-22	2026-02-21
440	Convenio hotelero con Grande, Ruano and Sandoval	Acuerdo entre el hotel y Grande, Ruano and Sandoval para ofrecer servicios especiales a nuestros huéspedes.	2022-04-19	2027-04-18
441	Convenio hotelero con Diaz-Casado	Acuerdo entre el hotel y Diaz-Casado para ofrecer servicios especiales a nuestros huéspedes.	2024-04-29	2029-04-28
442	Convenio hotelero con Manuel-Pedraza	Acuerdo entre el hotel y Manuel-Pedraza para ofrecer servicios especiales a nuestros huéspedes.	2024-05-11	2025-05-11
443	Convenio Cuéllar	Acuerdo entre el hotel y Fernández, Mendizábal and Cuéllar para ofrecer servicios especiales a nuestros huéspedes.	2020-08-02	2025-08-01
444	Convenio hotelero con Díez Inc	Acuerdo entre el hotel y Díez Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-11-10	2024-11-09
445	Convenio hotelero con Cordero-Malo	Acuerdo entre el hotel y Cordero-Malo para ofrecer servicios especiales a nuestros huéspedes.	2020-11-25	2022-11-25
446	Convenio hotelero con Torres-Escamilla	Acuerdo entre el hotel y Torres-Escamilla para ofrecer servicios especiales a nuestros huéspedes.	2021-05-21	2025-05-20
447	Convenio hotelero con Dueñas Inc	Acuerdo entre el hotel y Dueñas Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-08-20	2026-08-19
448	Convenio hotelero con Coca-Salamanca	Acuerdo entre el hotel y Coca-Salamanca para ofrecer servicios especiales a nuestros huéspedes.	2022-06-11	2026-06-10
449	Convenio hotelero con Santamaría-Cuenca	Acuerdo entre el hotel y Santamaría-Cuenca para ofrecer servicios especiales a nuestros huéspedes.	2020-09-18	2023-09-18
450	Convenio hotelero con Maestre-Caballero	Acuerdo entre el hotel y Maestre-Caballero para ofrecer servicios especiales a nuestros huéspedes.	2023-01-07	2028-01-06
451	Convenio hotelero con Raya, Ledesma and Llanos	Acuerdo entre el hotel y Raya, Ledesma and Llanos para ofrecer servicios especiales a nuestros huéspedes.	2022-11-02	2026-11-01
452	Convenio hotelero con Salgado, Pereira and Artigas	Acuerdo entre el hotel y Salgado, Pereira and Artigas para ofrecer servicios especiales a nuestros huéspedes.	2021-12-14	2022-12-14
453	Convenio hotelero con Pina, Agullo and Arce	Acuerdo entre el hotel y Pina, Agullo and Arce para ofrecer servicios especiales a nuestros huéspedes.	2020-08-08	2023-08-08
454	Convenio hotelero con Beltran, Mariño and Mercader	Acuerdo entre el hotel y Beltran, Mariño and Mercader para ofrecer servicios especiales a nuestros huéspedes.	2024-04-17	2027-04-17
455	Convenio hotelero con Agustí, Tormo and Pizarro	Acuerdo entre el hotel y Agustí, Tormo and Pizarro para ofrecer servicios especiales a nuestros huéspedes.	2020-10-05	2025-10-04
456	Convenio hotelero con Figueras LLC	Acuerdo entre el hotel y Figueras LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-21	2026-12-20
457	Convenio hotelero con Rosa Ltd	Acuerdo entre el hotel y Rosa Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-10-03	2023-10-03
458	Convenio hotelero con Gonzalo and Sons	Acuerdo entre el hotel y Gonzalo and Sons para ofrecer servicios especiales a nuestros huéspedes.	2024-02-15	2028-02-14
459	Convenio hotelero con Simó-Real	Acuerdo entre el hotel y Simó-Real para ofrecer servicios especiales a nuestros huéspedes.	2023-01-03	2024-01-03
460	Convenio hotelero con Villalba PLC	Acuerdo entre el hotel y Villalba PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-08-08	2025-08-07
461	Convenio hotelero con Salazar Ltd	Acuerdo entre el hotel y Salazar Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-01-25	2028-01-24
462	Convenio hotelero con Rebollo and Sons	Acuerdo entre el hotel y Rebollo and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-08-28	2025-08-27
463	Convenio hotelero con Cañellas, Yáñez and Heredia	Acuerdo entre el hotel y Cañellas, Yáñez and Heredia para ofrecer servicios especiales a nuestros huéspedes.	2022-11-11	2024-11-10
464	Convenio hotelero con Lluch PLC	Acuerdo entre el hotel y Lluch PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-07-24	2027-07-23
465	Convenio hotelero con Valbuena PLC	Acuerdo entre el hotel y Valbuena PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-08-21	2025-08-20
466	Convenio hotelero con Garay Inc	Acuerdo entre el hotel y Garay Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-12-06	2025-12-05
467	Convenio hotelero con Bermudez Inc	Acuerdo entre el hotel y Bermudez Inc para ofrecer servicios especiales a nuestros huéspedes.	2024-04-08	2027-04-08
468	Convenio hotelero con Acuña and Sons	Acuerdo entre el hotel y Acuña and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-11-01	2021-11-01
469	Convenio hotelero con Ibáñez PLC	Acuerdo entre el hotel y Ibáñez PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-01-13	2023-01-13
470	Convenio hotelero con Cózar-Campillo	Acuerdo entre el hotel y Cózar-Campillo para ofrecer servicios especiales a nuestros huéspedes.	2023-09-29	2028-09-27
471	Convenio hotelero con Gual, Aramburu and Iñiguez	Acuerdo entre el hotel y Gual, Aramburu and Iñiguez para ofrecer servicios especiales a nuestros huéspedes.	2022-02-08	2026-02-07
472	Convenio hotelero con Sevilla-Fernández	Acuerdo entre el hotel y Sevilla-Fernández para ofrecer servicios especiales a nuestros huéspedes.	2024-05-07	2029-05-06
473	Convenio hotelero con Millán-Anaya	Acuerdo entre el hotel y Millán-Anaya para ofrecer servicios especiales a nuestros huéspedes.	2022-08-13	2025-08-12
474	Convenio hotelero con Hidalgo, Jordá and Barragán	Acuerdo entre el hotel y Hidalgo, Jordá and Barragán para ofrecer servicios especiales a nuestros huéspedes.	2022-11-21	2025-11-20
475	Convenio hotelero con Salvà-Castilla	Acuerdo entre el hotel y Salvà-Castilla para ofrecer servicios especiales a nuestros huéspedes.	2023-04-03	2025-04-02
476	Convenio hotelero con Mendez, Frías and Cadenas	Acuerdo entre el hotel y Mendez, Frías and Cadenas para ofrecer servicios especiales a nuestros huéspedes.	2021-02-11	2024-02-11
477	Convenio hotelero con Mariño-Ibáñez	Acuerdo entre el hotel y Mariño-Ibáñez para ofrecer servicios especiales a nuestros huéspedes.	2024-02-18	2027-02-17
478	Convenio hotelero con Medina-Pareja	Acuerdo entre el hotel y Medina-Pareja para ofrecer servicios especiales a nuestros huéspedes.	2022-08-18	2025-08-17
479	Convenio hotelero con Camino Inc	Acuerdo entre el hotel y Camino Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-09-02	2028-08-31
480	Convenio hotelero con Sáez-Jove	Acuerdo entre el hotel y Sáez-Jove para ofrecer servicios especiales a nuestros huéspedes.	2023-03-09	2027-03-08
481	Convenio hotelero con Nicolás, Ávila and Tamayo	Acuerdo entre el hotel y Nicolás, Ávila and Tamayo para ofrecer servicios especiales a nuestros huéspedes.	2022-01-24	2027-01-23
482	Convenio hotelero con Gracia, Cañas and Alemany	Acuerdo entre el hotel y Gracia, Cañas and Alemany para ofrecer servicios especiales a nuestros huéspedes.	2020-08-09	2021-08-09
483	Convenio hotelero con Verdugo PLC	Acuerdo entre el hotel y Verdugo PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-02-14	2025-02-13
484	Convenio hotelero con Anaya, Campo and Baquero	Acuerdo entre el hotel y Anaya, Campo and Baquero para ofrecer servicios especiales a nuestros huéspedes.	2022-10-03	2026-10-02
485	Convenio hotelero con Narváez and Sons	Acuerdo entre el hotel y Narváez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-09-09	2024-09-08
486	Convenio hotelero con Beltran-Ros	Acuerdo entre el hotel y Beltran-Ros para ofrecer servicios especiales a nuestros huéspedes.	2021-08-06	2026-08-05
487	Convenio hotelero con Briones Group	Acuerdo entre el hotel y Briones Group para ofrecer servicios especiales a nuestros huéspedes.	2020-11-06	2021-11-06
488	Convenio hotelero con Prieto, Vilalta and Calvo	Acuerdo entre el hotel y Prieto, Vilalta and Calvo para ofrecer servicios especiales a nuestros huéspedes.	2022-03-25	2024-03-24
489	Convenio hotelero con Pacheco, González and Bru	Acuerdo entre el hotel y Pacheco, González and Bru para ofrecer servicios especiales a nuestros huéspedes.	2022-03-29	2027-03-28
490	Convenio hotelero con Ariño Ltd	Acuerdo entre el hotel y Ariño Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-03-02	2028-03-01
491	Convenio hotelero con Olmo, Mayoral and Escolano	Acuerdo entre el hotel y Olmo, Mayoral and Escolano para ofrecer servicios especiales a nuestros huéspedes.	2024-02-15	2026-02-14
492	Convenio hotelero con Alegre-Neira	Acuerdo entre el hotel y Alegre-Neira para ofrecer servicios especiales a nuestros huéspedes.	2021-04-21	2022-04-21
493	Convenio hotelero con Benavente, Almagro and Saura	Acuerdo entre el hotel y Benavente, Almagro and Saura para ofrecer servicios especiales a nuestros huéspedes.	2020-09-12	2022-09-12
494	Convenio hotelero con Aliaga-Pascual	Acuerdo entre el hotel y Aliaga-Pascual para ofrecer servicios especiales a nuestros huéspedes.	2022-05-17	2023-05-17
495	Convenio hotelero con Caballero-Bermejo	Acuerdo entre el hotel y Caballero-Bermejo para ofrecer servicios especiales a nuestros huéspedes.	2020-09-02	2022-09-02
496	Convenio hotelero con Olivera-Villalobos	Acuerdo entre el hotel y Olivera-Villalobos para ofrecer servicios especiales a nuestros huéspedes.	2021-05-12	2026-05-11
497	Convenio hotelero con Cabo-Figueroa	Acuerdo entre el hotel y Cabo-Figueroa para ofrecer servicios especiales a nuestros huéspedes.	2023-05-17	2025-05-16
498	Convenio Oller	Acuerdo entre el hotel y Almazán, Bustamante and Oller para ofrecer servicios especiales a nuestros huéspedes.	2022-02-25	2024-02-25
499	Convenio hotelero con Tamayo-Raya	Acuerdo entre el hotel y Tamayo-Raya para ofrecer servicios especiales a nuestros huéspedes.	2020-07-27	2022-07-27
500	Convenio hotelero con Manzano, Barceló and Pascual	Acuerdo entre el hotel y Manzano, Barceló and Pascual para ofrecer servicios especiales a nuestros huéspedes.	2021-07-26	2025-07-25
501	Convenio hotelero con Gutierrez PLC	Acuerdo entre el hotel y Gutierrez PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-04-07	2024-04-06
502	Convenio hotelero con Sala, Olivares and Lerma	Acuerdo entre el hotel y Sala, Olivares and Lerma para ofrecer servicios especiales a nuestros huéspedes.	2023-08-12	2028-08-10
503	Convenio hotelero con Acevedo LLC	Acuerdo entre el hotel y Acevedo LLC para ofrecer servicios especiales a nuestros huéspedes.	2021-03-15	2026-03-14
504	Convenio hotelero con Cadenas, Iglesia and Báez	Acuerdo entre el hotel y Cadenas, Iglesia and Báez para ofrecer servicios especiales a nuestros huéspedes.	2022-12-26	2024-12-25
505	Convenio hotelero con Cerdá, Pedro and Villanueva	Acuerdo entre el hotel y Cerdá, Pedro and Villanueva para ofrecer servicios especiales a nuestros huéspedes.	2022-12-06	2024-12-05
506	Convenio hotelero con Ferrer, Prieto and Taboada	Acuerdo entre el hotel y Ferrer, Prieto and Taboada para ofrecer servicios especiales a nuestros huéspedes.	2021-10-27	2026-10-26
507	Convenio hotelero con Yuste-Rojas	Acuerdo entre el hotel y Yuste-Rojas para ofrecer servicios especiales a nuestros huéspedes.	2022-07-05	2024-07-04
508	Convenio hotelero con Salamanca-Calzada	Acuerdo entre el hotel y Salamanca-Calzada para ofrecer servicios especiales a nuestros huéspedes.	2021-07-09	2026-07-08
509	Convenio hotelero con Lorenzo and Sons	Acuerdo entre el hotel y Lorenzo and Sons para ofrecer servicios especiales a nuestros huéspedes.	2024-04-15	2027-04-15
510	Convenio hotelero con Ortuño, Dávila and Espada	Acuerdo entre el hotel y Ortuño, Dávila and Espada para ofrecer servicios especiales a nuestros huéspedes.	2020-10-11	2021-10-11
511	Convenio hotelero con Quirós-Álvarez	Acuerdo entre el hotel y Quirós-Álvarez para ofrecer servicios especiales a nuestros huéspedes.	2023-01-28	2025-01-27
512	Convenio hotelero con Aragón, Carro and Donoso	Acuerdo entre el hotel y Aragón, Carro and Donoso para ofrecer servicios especiales a nuestros huéspedes.	2021-06-21	2022-06-21
513	Convenio hotelero con Quiroga-Tejada	Acuerdo entre el hotel y Quiroga-Tejada para ofrecer servicios especiales a nuestros huéspedes.	2023-12-12	2026-12-11
514	Convenio hotelero con Gallart PLC	Acuerdo entre el hotel y Gallart PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-06-14	2027-06-13
515	Convenio hotelero con Alemany LLC	Acuerdo entre el hotel y Alemany LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-06-17	2024-06-16
516	Convenio hotelero con Arteaga-Bustos	Acuerdo entre el hotel y Arteaga-Bustos para ofrecer servicios especiales a nuestros huéspedes.	2020-05-28	2024-05-27
517	Convenio hotelero con Gimeno-Artigas	Acuerdo entre el hotel y Gimeno-Artigas para ofrecer servicios especiales a nuestros huéspedes.	2022-03-28	2024-03-27
518	Convenio hotelero con Perales-Colom	Acuerdo entre el hotel y Perales-Colom para ofrecer servicios especiales a nuestros huéspedes.	2023-08-19	2025-08-18
519	Convenio hotelero con Ferrán-Canals	Acuerdo entre el hotel y Ferrán-Canals para ofrecer servicios especiales a nuestros huéspedes.	2022-07-05	2025-07-04
520	Convenio hotelero con Chico PLC	Acuerdo entre el hotel y Chico PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-07-26	2026-07-25
521	Convenio hotelero con Lara LLC	Acuerdo entre el hotel y Lara LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-07-17	2025-07-16
522	Convenio hotelero con Pastor-Amador	Acuerdo entre el hotel y Pastor-Amador para ofrecer servicios especiales a nuestros huéspedes.	2021-02-16	2024-02-16
523	Convenio hotelero con Esteban-Nadal	Acuerdo entre el hotel y Esteban-Nadal para ofrecer servicios especiales a nuestros huéspedes.	2023-07-06	2025-07-05
524	Convenio hotelero con Martinez-Miralles	Acuerdo entre el hotel y Martinez-Miralles para ofrecer servicios especiales a nuestros huéspedes.	2024-02-11	2029-02-09
525	Convenio hotelero con Vizcaíno and Sons	Acuerdo entre el hotel y Vizcaíno and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-08-28	2028-08-26
526	Convenio hotelero con Fajardo-Mayoral	Acuerdo entre el hotel y Fajardo-Mayoral para ofrecer servicios especiales a nuestros huéspedes.	2020-10-15	2025-10-14
527	Convenio hotelero con Cases-Lucena	Acuerdo entre el hotel y Cases-Lucena para ofrecer servicios especiales a nuestros huéspedes.	2022-10-26	2027-10-25
528	Convenio hotelero con Exposito Inc	Acuerdo entre el hotel y Exposito Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-03-10	2024-03-09
529	Convenio hotelero con Jerez, Torre and Noguera	Acuerdo entre el hotel y Jerez, Torre and Noguera para ofrecer servicios especiales a nuestros huéspedes.	2022-03-07	2024-03-06
530	Convenio hotelero con Arroyo, Lerma and Royo	Acuerdo entre el hotel y Arroyo, Lerma and Royo para ofrecer servicios especiales a nuestros huéspedes.	2022-09-26	2027-09-25
531	Convenio hotelero con Contreras-Amorós	Acuerdo entre el hotel y Contreras-Amorós para ofrecer servicios especiales a nuestros huéspedes.	2022-06-07	2027-06-06
532	Convenio hotelero con Baños, Narváez and Miralles	Acuerdo entre el hotel y Baños, Narváez and Miralles para ofrecer servicios especiales a nuestros huéspedes.	2023-12-14	2024-12-13
533	Convenio hotelero con Peral, Ariño and Manzanares	Acuerdo entre el hotel y Peral, Ariño and Manzanares para ofrecer servicios especiales a nuestros huéspedes.	2024-04-02	2025-04-02
534	Convenio hotelero con Baeza, Benito and Vélez	Acuerdo entre el hotel y Baeza, Benito and Vélez para ofrecer servicios especiales a nuestros huéspedes.	2022-06-01	2027-05-31
535	Convenio hotelero con Escudero-Parra	Acuerdo entre el hotel y Escudero-Parra para ofrecer servicios especiales a nuestros huéspedes.	2021-10-22	2023-10-22
536	Convenio hotelero con Feijoo, Tenorio and Sureda	Acuerdo entre el hotel y Feijoo, Tenorio and Sureda para ofrecer servicios especiales a nuestros huéspedes.	2020-09-12	2021-09-12
537	Convenio hotelero con Lucas-Gil	Acuerdo entre el hotel y Lucas-Gil para ofrecer servicios especiales a nuestros huéspedes.	2022-11-15	2023-11-15
538	Convenio hotelero con Mendez and Sons	Acuerdo entre el hotel y Mendez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-02-24	2025-02-23
539	Convenio hotelero con Cuéllar-Fajardo	Acuerdo entre el hotel y Cuéllar-Fajardo para ofrecer servicios especiales a nuestros huéspedes.	2022-02-24	2027-02-23
540	Convenio hotelero con Cámara, Criado and Estrada	Acuerdo entre el hotel y Cámara, Criado and Estrada para ofrecer servicios especiales a nuestros huéspedes.	2021-06-06	2022-06-06
541	Convenio hotelero con Balaguer LLC	Acuerdo entre el hotel y Balaguer LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-03-19	2026-03-18
542	Convenio hotelero con Bonilla-Castilla	Acuerdo entre el hotel y Bonilla-Castilla para ofrecer servicios especiales a nuestros huéspedes.	2022-06-06	2025-06-05
543	Convenio hotelero con Ferreras-Tamarit	Acuerdo entre el hotel y Ferreras-Tamarit para ofrecer servicios especiales a nuestros huéspedes.	2021-03-09	2022-03-09
544	Convenio hotelero con Soto Group	Acuerdo entre el hotel y Soto Group para ofrecer servicios especiales a nuestros huéspedes.	2020-12-27	2023-12-27
545	Convenio hotelero con Piquer-Guzman	Acuerdo entre el hotel y Piquer-Guzman para ofrecer servicios especiales a nuestros huéspedes.	2020-08-25	2021-08-25
546	Convenio hotelero con Bernal, Coloma and Soto	Acuerdo entre el hotel y Bernal, Coloma and Soto para ofrecer servicios especiales a nuestros huéspedes.	2022-01-06	2026-01-05
547	Convenio Coloma	Acuerdo entre el hotel y Moraleda, Mendizábal and Coloma para ofrecer servicios especiales a nuestros huéspedes.	2021-08-05	2024-08-04
548	Convenio hotelero con Carbajo, Roldan and Marqués	Acuerdo entre el hotel y Carbajo, Roldan and Marqués para ofrecer servicios especiales a nuestros huéspedes.	2024-05-18	2025-05-18
549	Convenio hotelero con Ponce-Solsona	Acuerdo entre el hotel y Ponce-Solsona para ofrecer servicios especiales a nuestros huéspedes.	2023-10-09	2028-10-07
550	Convenio hotelero con Abril PLC	Acuerdo entre el hotel y Abril PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-05-30	2025-05-29
551	Convenio hotelero con Ferrándiz Ltd	Acuerdo entre el hotel y Ferrándiz Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-09-03	2023-09-03
552	Convenio hotelero con Milla-Amador	Acuerdo entre el hotel y Milla-Amador para ofrecer servicios especiales a nuestros huéspedes.	2022-03-31	2025-03-30
553	Convenio hotelero con Palomino Ltd	Acuerdo entre el hotel y Palomino Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-05-19	2025-05-18
554	Convenio hotelero con Valdés, Moreno and Águila	Acuerdo entre el hotel y Valdés, Moreno and Águila para ofrecer servicios especiales a nuestros huéspedes.	2024-03-16	2029-03-15
555	Convenio hotelero con Rozas Ltd	Acuerdo entre el hotel y Rozas Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-12-11	2024-12-10
556	Convenio hotelero con Carreras-Fuente	Acuerdo entre el hotel y Carreras-Fuente para ofrecer servicios especiales a nuestros huéspedes.	2023-10-09	2024-10-08
557	Convenio hotelero con Blazquez PLC	Acuerdo entre el hotel y Blazquez PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-20	2024-12-19
558	Convenio hotelero con Aparicio Ltd	Acuerdo entre el hotel y Aparicio Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-06-23	2024-06-22
559	Convenio hotelero con Nevado, Rueda and Rios	Acuerdo entre el hotel y Nevado, Rueda and Rios para ofrecer servicios especiales a nuestros huéspedes.	2022-03-09	2024-03-08
560	Convenio hotelero con Cerro, Barrera and Cano	Acuerdo entre el hotel y Cerro, Barrera and Cano para ofrecer servicios especiales a nuestros huéspedes.	2021-12-12	2025-12-11
561	Convenio hotelero con Tena LLC	Acuerdo entre el hotel y Tena LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-02-24	2023-02-24
562	Convenio hotelero con Mir Group	Acuerdo entre el hotel y Mir Group para ofrecer servicios especiales a nuestros huéspedes.	2022-03-08	2024-03-07
563	Convenio hotelero con Coca and Sons	Acuerdo entre el hotel y Coca and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-11-22	2022-11-22
564	Convenio hotelero con Castejón Ltd	Acuerdo entre el hotel y Castejón Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-06-06	2023-06-06
565	Convenio hotelero con Cañellas, Alcolea and Ríos	Acuerdo entre el hotel y Cañellas, Alcolea and Ríos para ofrecer servicios especiales a nuestros huéspedes.	2023-08-07	2026-08-06
566	Convenio hotelero con Lledó Inc	Acuerdo entre el hotel y Lledó Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-03-26	2026-03-25
567	Convenio hotelero con Galan-Tolosa	Acuerdo entre el hotel y Galan-Tolosa para ofrecer servicios especiales a nuestros huéspedes.	2020-06-30	2023-06-30
568	Convenio hotelero con Galan-Valderrama	Acuerdo entre el hotel y Galan-Valderrama para ofrecer servicios especiales a nuestros huéspedes.	2021-12-04	2026-12-03
569	Convenio hotelero con Cuadrado-Bastida	Acuerdo entre el hotel y Cuadrado-Bastida para ofrecer servicios especiales a nuestros huéspedes.	2021-06-30	2025-06-29
570	Convenio hotelero con Gimenez, González and Macias	Acuerdo entre el hotel y Gimenez, González and Macias para ofrecer servicios especiales a nuestros huéspedes.	2023-01-14	2027-01-13
571	Convenio hotelero con Fabregat-Sierra	Acuerdo entre el hotel y Fabregat-Sierra para ofrecer servicios especiales a nuestros huéspedes.	2023-05-18	2027-05-17
572	Convenio hotelero con Roma Inc	Acuerdo entre el hotel y Roma Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-06-22	2025-06-21
573	Convenio hotelero con Campoy, Pulido and Ponce	Acuerdo entre el hotel y Campoy, Pulido and Ponce para ofrecer servicios especiales a nuestros huéspedes.	2021-04-25	2026-04-24
574	Convenio hotelero con Ureña, Alfonso and Armengol	Acuerdo entre el hotel y Ureña, Alfonso and Armengol para ofrecer servicios especiales a nuestros huéspedes.	2021-07-03	2026-07-02
575	Convenio hotelero con Román-Reguera	Acuerdo entre el hotel y Román-Reguera para ofrecer servicios especiales a nuestros huéspedes.	2023-04-10	2025-04-09
576	Convenio hotelero con León and Sons	Acuerdo entre el hotel y León and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-08-31	2023-08-31
577	Convenio hotelero con Vall, Lucas and Iglesias	Acuerdo entre el hotel y Vall, Lucas and Iglesias para ofrecer servicios especiales a nuestros huéspedes.	2022-03-06	2025-03-05
578	Convenio hotelero con Paniagua-Serrano	Acuerdo entre el hotel y Paniagua-Serrano para ofrecer servicios especiales a nuestros huéspedes.	2022-06-23	2025-06-22
579	Convenio hotelero con Monreal-Iborra	Acuerdo entre el hotel y Monreal-Iborra para ofrecer servicios especiales a nuestros huéspedes.	2024-02-03	2025-02-02
580	Convenio hotelero con Ayala, Pastor and Quero	Acuerdo entre el hotel y Ayala, Pastor and Quero para ofrecer servicios especiales a nuestros huéspedes.	2023-04-14	2025-04-13
581	Convenio hotelero con Lluch Ltd	Acuerdo entre el hotel y Lluch Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-08-17	2026-08-16
582	Convenio hotelero con Cuevas, Cazorla and Vicente	Acuerdo entre el hotel y Cuevas, Cazorla and Vicente para ofrecer servicios especiales a nuestros huéspedes.	2022-05-03	2024-05-02
583	Convenio hotelero con Cabeza, Salvador and Vidal	Acuerdo entre el hotel y Cabeza, Salvador and Vidal para ofrecer servicios especiales a nuestros huéspedes.	2021-01-07	2023-01-07
584	Convenio hotelero con Pagès PLC	Acuerdo entre el hotel y Pagès PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-07-31	2026-07-30
585	Convenio hotelero con Río-Flor	Acuerdo entre el hotel y Río-Flor para ofrecer servicios especiales a nuestros huéspedes.	2022-09-22	2024-09-21
586	Convenio hotelero con Daza Inc	Acuerdo entre el hotel y Daza Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-04-20	2024-04-19
587	Convenio hotelero con Roselló, Batalla and Reguera	Acuerdo entre el hotel y Roselló, Batalla and Reguera para ofrecer servicios especiales a nuestros huéspedes.	2020-08-31	2022-08-31
588	Convenio hotelero con Marí Inc	Acuerdo entre el hotel y Marí Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-10-13	2027-10-12
589	Convenio hotelero con Montaña, Vives and Robledo	Acuerdo entre el hotel y Montaña, Vives and Robledo para ofrecer servicios especiales a nuestros huéspedes.	2022-11-17	2027-11-16
590	Convenio hotelero con Alberto-Tomé	Acuerdo entre el hotel y Alberto-Tomé para ofrecer servicios especiales a nuestros huéspedes.	2021-01-21	2022-01-21
591	Convenio hotelero con Rebollo-Amorós	Acuerdo entre el hotel y Rebollo-Amorós para ofrecer servicios especiales a nuestros huéspedes.	2023-03-24	2025-03-23
592	Convenio hotelero con Ballester-Manzanares	Acuerdo entre el hotel y Ballester-Manzanares para ofrecer servicios especiales a nuestros huéspedes.	2021-12-06	2026-12-05
593	Convenio hotelero con Varela-Delgado	Acuerdo entre el hotel y Varela-Delgado para ofrecer servicios especiales a nuestros huéspedes.	2023-07-29	2024-07-28
594	Convenio hotelero con Granados PLC	Acuerdo entre el hotel y Granados PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-04-25	2022-04-25
595	Convenio hotelero con Torrens Inc	Acuerdo entre el hotel y Torrens Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-12-03	2026-12-02
596	Convenio hotelero con Raya Group	Acuerdo entre el hotel y Raya Group para ofrecer servicios especiales a nuestros huéspedes.	2020-12-13	2025-12-12
597	Convenio hotelero con Sanz, Pedrosa and Tejera	Acuerdo entre el hotel y Sanz, Pedrosa and Tejera para ofrecer servicios especiales a nuestros huéspedes.	2020-07-06	2021-07-06
598	Convenio hotelero con Mercader, Maza and Alfonso	Acuerdo entre el hotel y Mercader, Maza and Alfonso para ofrecer servicios especiales a nuestros huéspedes.	2024-05-04	2025-05-04
599	Convenio Santamaria	Acuerdo entre el hotel y Santamaria, Gargallo and Ariza para ofrecer servicios especiales a nuestros huéspedes.	2023-11-28	2027-11-27
600	Convenio hotelero con Moreno, Reyes and Folch	Acuerdo entre el hotel y Moreno, Reyes and Folch para ofrecer servicios especiales a nuestros huéspedes.	2021-03-27	2026-03-26
601	Convenio hotelero con Bertrán LLC	Acuerdo entre el hotel y Bertrán LLC para ofrecer servicios especiales a nuestros huéspedes.	2024-01-10	2028-01-09
602	Convenio hotelero con Fuster-Cueto	Acuerdo entre el hotel y Fuster-Cueto para ofrecer servicios especiales a nuestros huéspedes.	2020-06-27	2023-06-27
603	Convenio hotelero con Saavedra Ltd	Acuerdo entre el hotel y Saavedra Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-11-16	2022-11-16
604	Convenio hotelero con Romeu Inc	Acuerdo entre el hotel y Romeu Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-08-23	2025-08-22
605	Convenio hotelero con Carreño, Amador and Adán	Acuerdo entre el hotel y Carreño, Amador and Adán para ofrecer servicios especiales a nuestros huéspedes.	2022-03-20	2024-03-19
606	Convenio hotelero con Verdejo-Vicente	Acuerdo entre el hotel y Verdejo-Vicente para ofrecer servicios especiales a nuestros huéspedes.	2023-05-06	2024-05-05
607	Convenio hotelero con Pulido, Díaz and Carballo	Acuerdo entre el hotel y Pulido, Díaz and Carballo para ofrecer servicios especiales a nuestros huéspedes.	2024-02-15	2025-02-14
608	Convenio hotelero con Páez Inc	Acuerdo entre el hotel y Páez Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-09-13	2022-09-13
609	Convenio hotelero con Bayo Group	Acuerdo entre el hotel y Bayo Group para ofrecer servicios especiales a nuestros huéspedes.	2024-03-24	2026-03-24
610	Convenio hotelero con Blanes, Font and Torre	Acuerdo entre el hotel y Blanes, Font and Torre para ofrecer servicios especiales a nuestros huéspedes.	2022-02-04	2026-02-03
611	Convenio hotelero con Estrada-Reina	Acuerdo entre el hotel y Estrada-Reina para ofrecer servicios especiales a nuestros huéspedes.	2023-01-15	2024-01-15
612	Convenio hotelero con Viña, Ramis and Briones	Acuerdo entre el hotel y Viña, Ramis and Briones para ofrecer servicios especiales a nuestros huéspedes.	2024-04-11	2028-04-10
613	Convenio hotelero con Gomez and Sons	Acuerdo entre el hotel y Gomez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-07-12	2027-07-11
614	Convenio hotelero con Marin Ltd	Acuerdo entre el hotel y Marin Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-11-04	2025-11-03
615	Convenio hotelero con Cruz-Bartolomé	Acuerdo entre el hotel y Cruz-Bartolomé para ofrecer servicios especiales a nuestros huéspedes.	2024-02-29	2028-02-28
616	Convenio hotelero Sons	Acuerdo entre el hotel y Polo and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-02-27	2024-02-27
617	Convenio hotelero con Mateo and Sons	Acuerdo entre el hotel y Mateo and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-06-07	2023-06-07
618	Convenio hotelero con Ugarte, Riba and Redondo	Acuerdo entre el hotel y Ugarte, Riba and Redondo para ofrecer servicios especiales a nuestros huéspedes.	2024-03-23	2025-03-23
619	Convenio hotelero Rius	Acuerdo entre el hotel y Echeverría, Bautista and Rius para ofrecer servicios especiales a nuestros huéspedes.	2022-07-23	2027-07-22
620	Convenio hotelero con Prats, Marín and Gálvez	Acuerdo entre el hotel y Prats, Marín and Gálvez para ofrecer servicios especiales a nuestros huéspedes.	2022-12-29	2026-12-28
621	Convenio hotelero con Castejón-Tudela	Acuerdo entre el hotel y Castejón-Tudela para ofrecer servicios especiales a nuestros huéspedes.	2024-02-29	2027-02-28
622	Convenio hotelero Bustamante	Acuerdo entre el hotel y Cisneros, Isern and Bustamante para ofrecer servicios especiales a nuestros huéspedes.	2022-06-05	2024-06-04
623	Convenio hotelero con Ferrández-Cañete	Acuerdo entre el hotel y Ferrández-Cañete para ofrecer servicios especiales a nuestros huéspedes.	2024-04-23	2025-04-23
624	Convenio hotelero con Becerra Inc	Acuerdo entre el hotel y Becerra Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-09-02	2021-09-02
625	Convenio hotelero con Espejo Inc	Acuerdo entre el hotel y Espejo Inc para ofrecer servicios especiales a nuestros huéspedes.	2024-04-10	2025-04-10
626	Convenio hotelero con Gil Group	Acuerdo entre el hotel y Gil Group para ofrecer servicios especiales a nuestros huéspedes.	2024-04-24	2026-04-24
627	Convenio hotelero con Escudero-Pulido	Acuerdo entre el hotel y Escudero-Pulido para ofrecer servicios especiales a nuestros huéspedes.	2023-06-12	2027-06-11
628	Convenio hotelero con Pedrosa Ltd	Acuerdo entre el hotel y Pedrosa Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-07-23	2021-07-23
629	Convenio hotelero con Chaves Group	Acuerdo entre el hotel y Chaves Group para ofrecer servicios especiales a nuestros huéspedes.	2023-12-17	2024-12-16
630	Convenio hotelero con Vara PLC	Acuerdo entre el hotel y Vara PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-02-11	2025-02-10
631	Convenio hotelero con Fabregat-Pujol	Acuerdo entre el hotel y Fabregat-Pujol para ofrecer servicios especiales a nuestros huéspedes.	2021-04-18	2025-04-17
632	Convenio hotelero con Bolaños-Cal	Acuerdo entre el hotel y Bolaños-Cal para ofrecer servicios especiales a nuestros huéspedes.	2023-12-05	2026-12-04
633	Convenio hotelero con Barón-Acedo	Acuerdo entre el hotel y Barón-Acedo para ofrecer servicios especiales a nuestros huéspedes.	2020-07-13	2023-07-13
634	Convenio hotelero con Tudela PLC	Acuerdo entre el hotel y Tudela PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-07-06	2023-07-06
635	Convenio hotelero con Barrio, Leon and Menéndez	Acuerdo entre el hotel y Barrio, Leon and Menéndez para ofrecer servicios especiales a nuestros huéspedes.	2023-05-31	2027-05-30
636	Convenio hotelero con Calvet-Martin	Acuerdo entre el hotel y Calvet-Martin para ofrecer servicios especiales a nuestros huéspedes.	2020-07-25	2023-07-25
637	Convenio hotelero con Alemán-Quesada	Acuerdo entre el hotel y Alemán-Quesada para ofrecer servicios especiales a nuestros huéspedes.	2023-02-02	2024-02-02
638	Convenio hotelero con Fajardo-Baró	Acuerdo entre el hotel y Fajardo-Baró para ofrecer servicios especiales a nuestros huéspedes.	2021-06-26	2023-06-26
639	Convenio hotelero con Barrio, Bayo and Márquez	Acuerdo entre el hotel y Barrio, Bayo and Márquez para ofrecer servicios especiales a nuestros huéspedes.	2024-01-05	2025-01-04
640	Convenio hotelero con Mariño LLC	Acuerdo entre el hotel y Mariño LLC para ofrecer servicios especiales a nuestros huéspedes.	2020-05-28	2024-05-27
641	Convenio hotelero con Piñeiro, Valdés and Lago	Acuerdo entre el hotel y Piñeiro, Valdés and Lago para ofrecer servicios especiales a nuestros huéspedes.	2021-11-27	2022-11-27
642	Convenio hotelero con Bayo, Bauzà and Mateos	Acuerdo entre el hotel y Bayo, Bauzà and Mateos para ofrecer servicios especiales a nuestros huéspedes.	2022-11-07	2023-11-07
643	Convenio hotelero con Farré and Sons	Acuerdo entre el hotel y Farré and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-07-19	2022-07-19
644	Convenio hotelero con Llorens-Zabaleta	Acuerdo entre el hotel y Llorens-Zabaleta para ofrecer servicios especiales a nuestros huéspedes.	2020-09-28	2025-09-27
645	Convenio hotelero con Neira PLC	Acuerdo entre el hotel y Neira PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-09-23	2022-09-23
646	Convenio hotelero con Río-Cervantes	Acuerdo entre el hotel y Río-Cervantes para ofrecer servicios especiales a nuestros huéspedes.	2024-01-31	2025-01-30
647	Convenio Benavides	Acuerdo entre el hotel y Alegria, Manzano and Benavides para ofrecer servicios especiales a nuestros huéspedes.	2024-05-15	2026-05-15
648	Convenio hotelero con Salinas-Bayo	Acuerdo entre el hotel y Salinas-Bayo para ofrecer servicios especiales a nuestros huéspedes.	2020-06-16	2021-06-16
649	Convenio hotelero con Carnero-Torrens	Acuerdo entre el hotel y Carnero-Torrens para ofrecer servicios especiales a nuestros huéspedes.	2020-12-09	2021-12-09
650	Convenio hotelero con Miralles-Barco	Acuerdo entre el hotel y Miralles-Barco para ofrecer servicios especiales a nuestros huéspedes.	2020-10-29	2023-10-29
651	Convenio con Francisco	Acuerdo entre el hotel y Riera, Francisco and Ferreras para ofrecer servicios especiales a nuestros huéspedes.	2021-06-23	2022-06-23
652	Convenio hotelero con Salamanca-Macias	Acuerdo entre el hotel y Salamanca-Macias para ofrecer servicios especiales a nuestros huéspedes.	2024-04-04	2029-04-03
653	Convenio hotelero con Rosales Inc	Acuerdo entre el hotel y Rosales Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-09-11	2026-09-10
654	Convenio hotelero con Cifuentes	Acuerdo entre el hotel y Blazquez, Castejón and Cifuentes para ofrecer servicios especiales a nuestros huéspedes.	2022-12-27	2025-12-26
655	Convenio hotelero con Seco, Almeida and Martín	Acuerdo entre el hotel y Seco, Almeida and Martín para ofrecer servicios especiales a nuestros huéspedes.	2022-07-07	2023-07-07
656	Convenio hotelero con Bayón-Sanmartín	Acuerdo entre el hotel y Bayón-Sanmartín para ofrecer servicios especiales a nuestros huéspedes.	2021-05-01	2024-04-30
657	Convenio hotelero con Naranjo, Polo and Caparrós	Acuerdo entre el hotel y Naranjo, Polo and Caparrós para ofrecer servicios especiales a nuestros huéspedes.	2020-08-26	2021-08-26
658	Convenio hotelero con Barrio, Taboada and Ramis	Acuerdo entre el hotel y Barrio, Taboada and Ramis para ofrecer servicios especiales a nuestros huéspedes.	2021-01-26	2023-01-26
659	Convenio hotelero con Castillo-Zaragoza	Acuerdo entre el hotel y Castillo-Zaragoza para ofrecer servicios especiales a nuestros huéspedes.	2024-02-25	2025-02-24
660	Convenio hotelero con Cerdán LLC	Acuerdo entre el hotel y Cerdán LLC para ofrecer servicios especiales a nuestros huéspedes.	2021-01-11	2023-01-11
661	Convenio hotelero con Botella-Arce	Acuerdo entre el hotel y Botella-Arce para ofrecer servicios especiales a nuestros huéspedes.	2023-09-27	2024-09-26
662	Convenio hotelero con Diaz PLC	Acuerdo entre el hotel y Diaz PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-08-08	2024-08-07
663	Convenio hotelero con Belmonte-Casanova	Acuerdo entre el hotel y Belmonte-Casanova para ofrecer servicios especiales a nuestros huéspedes.	2020-12-29	2025-12-28
664	Convenio hotelero con Múgica, Montes and Dueñas	Acuerdo entre el hotel y Múgica, Montes and Dueñas para ofrecer servicios especiales a nuestros huéspedes.	2020-05-28	2021-05-28
665	Convenio hotelero con Girón, Requena and Pla	Acuerdo entre el hotel y Girón, Requena and Pla para ofrecer servicios especiales a nuestros huéspedes.	2022-11-07	2023-11-07
666	Convenio hotelero con Costa-Guitart	Acuerdo entre el hotel y Costa-Guitart para ofrecer servicios especiales a nuestros huéspedes.	2022-07-23	2026-07-22
667	Convenio hotelero con Recio Inc	Acuerdo entre el hotel y Recio Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-12-11	2026-12-10
668	Convenio hotelero con Benet Group	Acuerdo entre el hotel y Benet Group para ofrecer servicios especiales a nuestros huéspedes.	2023-04-28	2026-04-27
669	Convenio hotelero con Sanchez PLC	Acuerdo entre el hotel y Sanchez PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-11-28	2022-11-28
670	Convenio hotelero con Zamora, Hernández and Pinedo	Acuerdo entre el hotel y Zamora, Hernández and Pinedo para ofrecer servicios especiales a nuestros huéspedes.	2023-07-11	2026-07-10
671	Convenio hotelero con Ángel-Reig	Acuerdo entre el hotel y Ángel-Reig para ofrecer servicios especiales a nuestros huéspedes.	2021-07-24	2023-07-24
672	Convenio hotelero con Robledo-Vilalta	Acuerdo entre el hotel y Robledo-Vilalta para ofrecer servicios especiales a nuestros huéspedes.	2021-11-30	2023-11-30
673	Convenio hotelero con Corbacho, Macías and Cortina	Acuerdo entre el hotel y Corbacho, Macías and Cortina para ofrecer servicios especiales a nuestros huéspedes.	2024-03-12	2029-03-11
674	Convenio hotelero con Olmo, Ribas and Barreda	Acuerdo entre el hotel y Olmo, Ribas and Barreda para ofrecer servicios especiales a nuestros huéspedes.	2021-11-17	2023-11-17
675	Convenio hotelero con Agudo-Macías	Acuerdo entre el hotel y Agudo-Macías para ofrecer servicios especiales a nuestros huéspedes.	2020-10-27	2025-10-26
676	Convenio hotelero con Fabra and Sons	Acuerdo entre el hotel y Fabra and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-07-18	2024-07-17
677	Convenio hotelero con Andreu-Cuadrado	Acuerdo entre el hotel y Andreu-Cuadrado para ofrecer servicios especiales a nuestros huéspedes.	2022-07-14	2023-07-14
678	Convenio hotelero con Cabanillas Group	Acuerdo entre el hotel y Cabanillas Group para ofrecer servicios especiales a nuestros huéspedes.	2020-10-13	2022-10-13
679	Convenio hotelero con Verdejo-Posada	Acuerdo entre el hotel y Verdejo-Posada para ofrecer servicios especiales a nuestros huéspedes.	2023-12-04	2025-12-03
680	Convenio hotelero con Bilbao, Alsina and Dávila	Acuerdo entre el hotel y Bilbao, Alsina and Dávila para ofrecer servicios especiales a nuestros huéspedes.	2024-03-29	2027-03-29
681	Convenio hotelero con Villalonga Inc	Acuerdo entre el hotel y Villalonga Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-08-11	2027-08-10
682	Convenio hotelero con Mulet-Ureña	Acuerdo entre el hotel y Mulet-Ureña para ofrecer servicios especiales a nuestros huéspedes.	2024-01-29	2026-01-28
683	Convenio hotelero con Catalán, Pastor and Vega	Acuerdo entre el hotel y Catalán, Pastor and Vega para ofrecer servicios especiales a nuestros huéspedes.	2024-03-03	2025-03-03
684	Convenio hotelero con Mora, Cánovas and Gimenez	Acuerdo entre el hotel y Mora, Cánovas and Gimenez para ofrecer servicios especiales a nuestros huéspedes.	2023-08-11	2026-08-10
685	Convenio hotelero con Reig-Gras	Acuerdo entre el hotel y Reig-Gras para ofrecer servicios especiales a nuestros huéspedes.	2021-05-13	2024-05-12
686	Convenio hotelero con Peinado, Sarmiento and Núñez	Acuerdo entre el hotel y Peinado, Sarmiento and Núñez para ofrecer servicios especiales a nuestros huéspedes.	2023-07-25	2027-07-24
687	Convenio hotelero con Barbero, Arcos and Ramos	Acuerdo entre el hotel y Barbero, Arcos and Ramos para ofrecer servicios especiales a nuestros huéspedes.	2024-01-21	2028-01-20
688	Convenio hotelero con Matas-Neira	Acuerdo entre el hotel y Matas-Neira para ofrecer servicios especiales a nuestros huéspedes.	2023-06-08	2027-06-07
689	Convenio hotelero con Quevedo-Catalá	Acuerdo entre el hotel y Quevedo-Catalá para ofrecer servicios especiales a nuestros huéspedes.	2020-10-03	2021-10-03
690	Convenio hotelero con Francisco LLC	Acuerdo entre el hotel y Francisco LLC para ofrecer servicios especiales a nuestros huéspedes.	2021-05-06	2022-05-06
691	Convenio hotelero con Jáuregui-Bueno	Acuerdo entre el hotel y Jáuregui-Bueno para ofrecer servicios especiales a nuestros huéspedes.	2023-03-03	2024-03-02
692	Convenio hotelero con Ayllón, Taboada and Ariño	Acuerdo entre el hotel y Ayllón, Taboada and Ariño para ofrecer servicios especiales a nuestros huéspedes.	2022-07-05	2023-07-05
693	Convenio hotelero con Gilabert-Carpio	Acuerdo entre el hotel y Gilabert-Carpio para ofrecer servicios especiales a nuestros huéspedes.	2023-09-09	2025-09-08
694	Convenio hotelero con Rueda-Cid	Acuerdo entre el hotel y Rueda-Cid para ofrecer servicios especiales a nuestros huéspedes.	2020-10-09	2021-10-09
695	Convenio hotelero con Conde Group	Acuerdo entre el hotel y Conde Group para ofrecer servicios especiales a nuestros huéspedes.	2020-12-14	2023-12-14
696	Convenio hotelero con Bonilla-Prat	Acuerdo entre el hotel y Bonilla-Prat para ofrecer servicios especiales a nuestros huéspedes.	2022-11-03	2027-11-02
697	Convenio hotelero con Amigó, Pintor and Espinosa	Acuerdo entre el hotel y Amigó, Pintor and Espinosa para ofrecer servicios especiales a nuestros huéspedes.	2022-01-18	2024-01-18
698	Convenio hotelero con Torrent PLC	Acuerdo entre el hotel y Torrent PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-06-17	2026-06-16
699	Convenio hotelero con Aller, Raya and Lerma	Acuerdo entre el hotel y Aller, Raya and Lerma para ofrecer servicios especiales a nuestros huéspedes.	2022-12-27	2026-12-26
700	Convenio hotelero con Cantero-Pujol	Acuerdo entre el hotel y Cantero-Pujol para ofrecer servicios especiales a nuestros huéspedes.	2024-04-10	2026-04-10
701	Convenio hotelero con Vazquez, Angulo and Carrión	Acuerdo entre el hotel y Vazquez, Angulo and Carrión para ofrecer servicios especiales a nuestros huéspedes.	2020-12-04	2024-12-03
702	Convenio hotelero con Camino-Montoya	Acuerdo entre el hotel y Camino-Montoya para ofrecer servicios especiales a nuestros huéspedes.	2022-08-26	2025-08-25
703	Convenio hotelero con Mesa PLC	Acuerdo entre el hotel y Mesa PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-10-08	2026-10-07
704	Convenio hotelero con Saez-Lladó	Acuerdo entre el hotel y Saez-Lladó para ofrecer servicios especiales a nuestros huéspedes.	2021-01-26	2022-01-26
705	Convenio hotelero con Bru LLC	Acuerdo entre el hotel y Bru LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-04-07	2026-04-06
706	Convenio hotelero con Gallardo Inc	Acuerdo entre el hotel y Gallardo Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-05-31	2027-05-30
707	Convenio hotelero con Navarro-Gárate	Acuerdo entre el hotel y Navarro-Gárate para ofrecer servicios especiales a nuestros huéspedes.	2022-07-17	2027-07-16
708	Convenio hotelero con Julián PLC	Acuerdo entre el hotel y Julián PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-08-07	2026-08-06
709	Convenio hotelero con Cámara-Sandoval	Acuerdo entre el hotel y Cámara-Sandoval para ofrecer servicios especiales a nuestros huéspedes.	2021-10-18	2022-10-18
710	Convenio hotelero con Cabello Ltd	Acuerdo entre el hotel y Cabello Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-02-21	2024-02-21
711	Convenio hotelero con Espada Group	Acuerdo entre el hotel y Espada Group para ofrecer servicios especiales a nuestros huéspedes.	2024-01-29	2029-01-27
712	Convenio hotelero con Montalbán LLC	Acuerdo entre el hotel y Montalbán LLC para ofrecer servicios especiales a nuestros huéspedes.	2021-05-09	2024-05-08
713	Convenio hotelero con Amat-Cabezas	Acuerdo entre el hotel y Amat-Cabezas para ofrecer servicios especiales a nuestros huéspedes.	2021-02-13	2025-02-12
714	Convenio hotelero con Carmona-Gisbert	Acuerdo entre el hotel y Carmona-Gisbert para ofrecer servicios especiales a nuestros huéspedes.	2023-07-15	2027-07-14
715	Convenio hotelero con Hernandez-Rodriguez	Acuerdo entre el hotel y Hernandez-Rodriguez para ofrecer servicios especiales a nuestros huéspedes.	2020-07-05	2023-07-05
716	Convenio hotelero con Jódar-Machado	Acuerdo entre el hotel y Jódar-Machado para ofrecer servicios especiales a nuestros huéspedes.	2022-11-13	2025-11-12
717	Convenio hotelero con Carbajo Ltd	Acuerdo entre el hotel y Carbajo Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-10-29	2025-10-28
718	Convenio hotelero con Cisneros Inc	Acuerdo entre el hotel y Cisneros Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-11-02	2023-11-02
719	Convenio hotelero con Boada-Alfaro	Acuerdo entre el hotel y Boada-Alfaro para ofrecer servicios especiales a nuestros huéspedes.	2021-02-24	2025-02-23
720	Convenio hotelero con Pons Inc	Acuerdo entre el hotel y Pons Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-07-09	2024-07-08
721	Convenio hotelero con Espada, Aguado and Morata	Acuerdo entre el hotel y Espada, Aguado and Morata para ofrecer servicios especiales a nuestros huéspedes.	2020-11-25	2025-11-24
722	Convenio hotelero con Cortés Inc	Acuerdo entre el hotel y Cortés Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-03-10	2024-03-09
723	Convenio hotelero con Morales-García	Acuerdo entre el hotel y Morales-García para ofrecer servicios especiales a nuestros huéspedes.	2020-09-17	2024-09-16
724	Convenio hotelero con Expósito	Acuerdo entre el hotel y Fábregas, Bernal and Expósito para ofrecer servicios especiales a nuestros huéspedes.	2021-12-20	2026-12-19
725	Convenio hotelero con Caro, Barrios and Marqués	Acuerdo entre el hotel y Caro, Barrios and Marqués para ofrecer servicios especiales a nuestros huéspedes.	2021-11-28	2023-11-28
726	Convenio hotelero con Casado Ltd	Acuerdo entre el hotel y Casado Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-02-26	2025-02-25
727	Convenio hotelero con Sánchez LLC	Acuerdo entre el hotel y Sánchez LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-07-13	2028-07-11
728	Convenio hotelero con Calderón and Sons	Acuerdo entre el hotel y Calderón and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-07-19	2025-07-18
729	Convenio hotelero con Quesada, Domingo and Burgos	Acuerdo entre el hotel y Quesada, Domingo and Burgos para ofrecer servicios especiales a nuestros huéspedes.	2020-12-07	2021-12-07
730	Convenio hotelero con Sanjuan Ltd	Acuerdo entre el hotel y Sanjuan Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-08-24	2025-08-23
731	Convenio hotelero con Padilla, Ávila and Uriarte	Acuerdo entre el hotel y Padilla, Ávila and Uriarte para ofrecer servicios especiales a nuestros huéspedes.	2022-07-23	2025-07-22
732	Convenio hotelero con Egea-Tovar	Acuerdo entre el hotel y Egea-Tovar para ofrecer servicios especiales a nuestros huéspedes.	2021-12-26	2023-12-26
733	Convenio hotelero con Tapia-Paredes	Acuerdo entre el hotel y Tapia-Paredes para ofrecer servicios especiales a nuestros huéspedes.	2024-04-14	2025-04-14
734	Convenio hotelero con Rosa-Cano	Acuerdo entre el hotel y Rosa-Cano para ofrecer servicios especiales a nuestros huéspedes.	2021-10-27	2025-10-26
735	Convenio hotelero con Llanos, Bárcena and Barriga	Acuerdo entre el hotel y Llanos, Bárcena and Barriga para ofrecer servicios especiales a nuestros huéspedes.	2021-07-04	2025-07-03
736	Convenio hotelero con Prado, Cáceres and Salmerón	Acuerdo entre el hotel y Prado, Cáceres and Salmerón para ofrecer servicios especiales a nuestros huéspedes.	2021-07-20	2025-07-19
737	Convenio hotelero con Agustín PLC	Acuerdo entre el hotel y Agustín PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-04-27	2022-04-27
738	Convenio hotelero con Martinez Ltd	Acuerdo entre el hotel y Martinez Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-07-30	2025-07-29
739	Convenio hotelero con Rios PLC	Acuerdo entre el hotel y Rios PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-01-29	2024-01-29
740	Convenio hotelero con Albero, Mármol and Murillo	Acuerdo entre el hotel y Albero, Mármol and Murillo para ofrecer servicios especiales a nuestros huéspedes.	2021-11-19	2023-11-19
741	Convenio hotelero con Pujadas Inc	Acuerdo entre el hotel y Pujadas Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-04-10	2024-04-09
742	Convenio hotelero con Valderrama, Gras and Flor	Acuerdo entre el hotel y Valderrama, Gras and Flor para ofrecer servicios especiales a nuestros huéspedes.	2021-03-20	2025-03-19
743	Convenio hotelero con Bayona Inc	Acuerdo entre el hotel y Bayona Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-08-28	2022-08-28
744	Convenio hotelero con Ferrández Inc	Acuerdo entre el hotel y Ferrández Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-09-09	2026-09-08
745	Convenio hotelero con Ferrán, Jódar and Gálvez	Acuerdo entre el hotel y Ferrán, Jódar and Gálvez para ofrecer servicios especiales a nuestros huéspedes.	2020-08-13	2021-08-13
746	Convenio hotelero con Fajardo, Arroyo and Puerta	Acuerdo entre el hotel y Fajardo, Arroyo and Puerta para ofrecer servicios especiales a nuestros huéspedes.	2021-08-21	2024-08-20
747	Convenio hotelero con Mendez and Sons	Acuerdo entre el hotel y Mendez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-07-07	2026-07-06
748	Convenio hotelero con Requena, Martorell and Pérez	Acuerdo entre el hotel y Requena, Martorell and Pérez para ofrecer servicios especiales a nuestros huéspedes.	2022-03-15	2027-03-14
749	Convenio hotelero con Acedo, Reina and Lladó	Acuerdo entre el hotel y Acedo, Reina and Lladó para ofrecer servicios especiales a nuestros huéspedes.	2021-11-29	2025-11-28
750	Convenio hotelero con Salvà-Jurado	Acuerdo entre el hotel y Salvà-Jurado para ofrecer servicios especiales a nuestros huéspedes.	2020-08-05	2022-08-05
751	Convenio hotelero con Gargallo, Bautista and Vega	Acuerdo entre el hotel y Gargallo, Bautista and Vega para ofrecer servicios especiales a nuestros huéspedes.	2023-09-12	2026-09-11
752	Convenio hotelero con Valenzuela and Sons	Acuerdo entre el hotel y Valenzuela and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-10-16	2023-10-16
753	Convenio hotelero con Rosado Group	Acuerdo entre el hotel y Rosado Group para ofrecer servicios especiales a nuestros huéspedes.	2023-10-29	2024-10-28
754	Convenio hotelero con Ureña Ltd	Acuerdo entre el hotel y Ureña Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-04-26	2027-04-25
755	Convenio hotelero con Lumbreras-Galan	Acuerdo entre el hotel y Lumbreras-Galan para ofrecer servicios especiales a nuestros huéspedes.	2021-08-21	2024-08-20
756	Convenio hotelero con Pavón, Alcalde and Rojas	Acuerdo entre el hotel y Pavón, Alcalde and Rojas para ofrecer servicios especiales a nuestros huéspedes.	2021-02-09	2024-02-09
757	Convenio hotelero con Peñas Ltd	Acuerdo entre el hotel y Peñas Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-05-17	2027-05-16
758	Convenio hotelero con Murcia, Viña and Blázquez	Acuerdo entre el hotel y Murcia, Viña and Blázquez para ofrecer servicios especiales a nuestros huéspedes.	2022-07-17	2027-07-16
759	Convenio hotelero con Lobo, Jimenez and Querol	Acuerdo entre el hotel y Lobo, Jimenez and Querol para ofrecer servicios especiales a nuestros huéspedes.	2023-04-06	2026-04-05
760	Convenio hotelero con Almazán-Sanjuan	Acuerdo entre el hotel y Almazán-Sanjuan para ofrecer servicios especiales a nuestros huéspedes.	2022-06-09	2027-06-08
761	Convenio hotelero con Rovira-Vilanova	Acuerdo entre el hotel y Rovira-Vilanova para ofrecer servicios especiales a nuestros huéspedes.	2023-01-12	2025-01-11
762	Convenio hotelero Sarmiento	Acuerdo entre el hotel y Sarmiento, Portero and Barceló para ofrecer servicios especiales a nuestros huéspedes.	2023-05-21	2027-05-20
763	Convenio hotelero con Andreu Ltd	Acuerdo entre el hotel y Andreu Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-12-18	2022-12-18
764	Convenio hotelero con Morante-Valentín	Acuerdo entre el hotel y Morante-Valentín para ofrecer servicios especiales a nuestros huéspedes.	2023-09-16	2024-09-15
765	Convenio hotelero con Lloret LLC	Acuerdo entre el hotel y Lloret LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-11-08	2024-11-07
766	Convenio hotelero con Sanjuan, Sánchez and Díez	Acuerdo entre el hotel y Sanjuan, Sánchez and Díez para ofrecer servicios especiales a nuestros huéspedes.	2023-06-11	2024-06-10
767	Convenio hotelero con Guardiola-Tena	Acuerdo entre el hotel y Guardiola-Tena para ofrecer servicios especiales a nuestros huéspedes.	2021-05-22	2024-05-21
768	Convenio hotelero con Crespi LLC	Acuerdo entre el hotel y Crespi LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-06-05	2027-06-04
769	Convenio hotelero con Moya-Nevado	Acuerdo entre el hotel y Moya-Nevado para ofrecer servicios especiales a nuestros huéspedes.	2023-07-17	2027-07-16
770	Convenio hotelero con Font, Girona and Castrillo	Acuerdo entre el hotel y Font, Girona and Castrillo para ofrecer servicios especiales a nuestros huéspedes.	2021-08-19	2022-08-19
771	Convenio hotelero con Cobo, Arribas and Bejarano	Acuerdo entre el hotel y Cobo, Arribas and Bejarano para ofrecer servicios especiales a nuestros huéspedes.	2022-03-30	2027-03-29
772	Convenio hotelero con Oliva-Gallo	Acuerdo entre el hotel y Oliva-Gallo para ofrecer servicios especiales a nuestros huéspedes.	2021-09-03	2024-09-02
773	Convenio hotelero con Corral-Sosa	Acuerdo entre el hotel y Corral-Sosa para ofrecer servicios especiales a nuestros huéspedes.	2020-11-23	2023-11-23
774	Convenio hotelero con Peña-Pinedo	Acuerdo entre el hotel y Peña-Pinedo para ofrecer servicios especiales a nuestros huéspedes.	2021-12-21	2024-12-20
775	Convenio hotelero con Marti PLC	Acuerdo entre el hotel y Marti PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-09-12	2022-09-12
776	Convenio hotelero con Bertrán-Ferrándiz	Acuerdo entre el hotel y Bertrán-Ferrándiz para ofrecer servicios especiales a nuestros huéspedes.	2021-02-13	2022-02-13
777	Convenio hotelero con Sanmartín	Acuerdo entre el hotel y Sanmartín, Hernández and Mariño para ofrecer servicios especiales a nuestros huéspedes.	2023-11-10	2025-11-09
778	Convenio hotelero con Antón-Quero	Acuerdo entre el hotel y Antón-Quero para ofrecer servicios especiales a nuestros huéspedes.	2021-03-19	2025-03-18
779	Convenio hotelero con Valenciano-Nicolau	Acuerdo entre el hotel y Valenciano-Nicolau para ofrecer servicios especiales a nuestros huéspedes.	2022-05-22	2024-05-21
780	Convenio hotelero con Armengol	Acuerdo entre el hotel y Armengol, Cánovas and Benitez para ofrecer servicios especiales a nuestros huéspedes.	2022-07-20	2025-07-19
781	Convenio hotelero con Querol, Salgado and Soria	Acuerdo entre el hotel y Querol, Salgado and Soria para ofrecer servicios especiales a nuestros huéspedes.	2022-02-08	2025-02-07
782	Convenio hotelero con Rodriguez-Rincón	Acuerdo entre el hotel y Rodriguez-Rincón para ofrecer servicios especiales a nuestros huéspedes.	2022-02-12	2026-02-11
783	Convenio hotelero con Parra Inc	Acuerdo entre el hotel y Parra Inc para ofrecer servicios especiales a nuestros huéspedes.	2023-10-30	2027-10-29
784	Convenio hotelero con Solano-Pizarro	Acuerdo entre el hotel y Solano-Pizarro para ofrecer servicios especiales a nuestros huéspedes.	2022-08-31	2024-08-30
785	Convenio hotelero con Folch-Criado	Acuerdo entre el hotel y Folch-Criado para ofrecer servicios especiales a nuestros huéspedes.	2020-08-01	2022-08-01
786	Convenio hotelero con Bonilla Inc	Acuerdo entre el hotel y Bonilla Inc para ofrecer servicios especiales a nuestros huéspedes.	2024-04-25	2025-04-25
787	Convenio hotelero con Zabala LLC	Acuerdo entre el hotel y Zabala LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-10-14	2024-10-13
788	Convenio hotelero con Ocaña, Posada and Coca	Acuerdo entre el hotel y Ocaña, Posada and Coca para ofrecer servicios especiales a nuestros huéspedes.	2020-09-14	2021-09-14
789	Convenio hotelero con Corbacho-Vara	Acuerdo entre el hotel y Corbacho-Vara para ofrecer servicios especiales a nuestros huéspedes.	2022-01-15	2023-01-15
790	Convenio hotelero con Ripoll-Carrasco	Acuerdo entre el hotel y Ripoll-Carrasco para ofrecer servicios especiales a nuestros huéspedes.	2020-12-19	2022-12-19
791	Convenio hotelero con Ibañez-Feliu	Acuerdo entre el hotel y Ibañez-Feliu para ofrecer servicios especiales a nuestros huéspedes.	2020-12-07	2024-12-06
792	Convenio hotelero con Gallart PLC	Acuerdo entre el hotel y Gallart PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-09-21	2022-09-21
793	Convenio hotelero con Perales-Mancebo	Acuerdo entre el hotel y Perales-Mancebo para ofrecer servicios especiales a nuestros huéspedes.	2023-06-11	2027-06-10
794	Convenio hotelero con Duque, Alemán and Verdugo	Acuerdo entre el hotel y Duque, Alemán and Verdugo para ofrecer servicios especiales a nuestros huéspedes.	2022-03-10	2027-03-09
795	Convenio hotelero con Franco-Monreal	Acuerdo entre el hotel y Franco-Monreal para ofrecer servicios especiales a nuestros huéspedes.	2023-02-04	2027-02-03
796	Convenio hotelero con Caballero PLC	Acuerdo entre el hotel y Caballero PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-05-01	2024-04-30
797	Convenio hotelero con Martorell PLC	Acuerdo entre el hotel y Martorell PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-02-13	2026-02-12
798	Convenio hotelero con Franco, Rocha and Mir	Acuerdo entre el hotel y Franco, Rocha and Mir para ofrecer servicios especiales a nuestros huéspedes.	2022-01-05	2027-01-04
799	Convenio hotelero con Abascal, Tamarit and Zamora	Acuerdo entre el hotel y Abascal, Tamarit and Zamora para ofrecer servicios especiales a nuestros huéspedes.	2021-10-01	2022-10-01
800	Convenio hotelero con Galindo-Carrasco	Acuerdo entre el hotel y Galindo-Carrasco para ofrecer servicios especiales a nuestros huéspedes.	2023-04-15	2028-04-13
801	Convenio hotelero con Folch, Corral and Peláez	Acuerdo entre el hotel y Folch, Corral and Peláez para ofrecer servicios especiales a nuestros huéspedes.	2020-11-13	2024-11-12
802	Convenio hotelero con Daza and Sons	Acuerdo entre el hotel y Daza and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-02-17	2025-02-16
803	Convenio hotelero con Uriarte, Casares and Elorza	Acuerdo entre el hotel y Uriarte, Casares and Elorza para ofrecer servicios especiales a nuestros huéspedes.	2021-04-27	2022-04-27
804	Convenio hotelero con Hervás, Jove and Daza	Acuerdo entre el hotel y Hervás, Jove and Daza para ofrecer servicios especiales a nuestros huéspedes.	2021-06-30	2026-06-29
805	Convenio hotelero con Padilla PLC	Acuerdo entre el hotel y Padilla PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-06-06	2025-06-05
806	Convenio hotelero con Huertas-Estevez	Acuerdo entre el hotel y Huertas-Estevez para ofrecer servicios especiales a nuestros huéspedes.	2021-04-19	2023-04-19
807	Convenio hotelero con Bermudez-Barrio	Acuerdo entre el hotel y Bermudez-Barrio para ofrecer servicios especiales a nuestros huéspedes.	2021-07-04	2023-07-04
808	Convenio hotelero con Vázquez, Mayo and Nevado	Acuerdo entre el hotel y Vázquez, Mayo and Nevado para ofrecer servicios especiales a nuestros huéspedes.	2021-07-21	2023-07-21
809	Convenio hotelero con Machado Inc	Acuerdo entre el hotel y Machado Inc para ofrecer servicios especiales a nuestros huéspedes.	2022-04-15	2024-04-14
810	Convenio hotelero con Barrios-Robles	Acuerdo entre el hotel y Barrios-Robles para ofrecer servicios especiales a nuestros huéspedes.	2021-12-27	2024-12-26
811	Convenio hotelero con Doménech Inc	Acuerdo entre el hotel y Doménech Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-07-17	2025-07-16
812	Convenio hotelero con Aparicio and Sons	Acuerdo entre el hotel y Aparicio and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-12-22	2025-12-21
813	Convenio hotelero con Pareja, Salazar and Piñeiro	Acuerdo entre el hotel y Pareja, Salazar and Piñeiro para ofrecer servicios especiales a nuestros huéspedes.	2022-06-27	2026-06-26
814	Convenio hotelero con Castelló, Sáez and Escalona	Acuerdo entre el hotel y Castelló, Sáez and Escalona para ofrecer servicios especiales a nuestros huéspedes.	2023-12-10	2026-12-09
815	Convenio hotelero con Gallardo LLC	Acuerdo entre el hotel y Gallardo LLC para ofrecer servicios especiales a nuestros huéspedes.	2024-05-25	2025-05-25
816	Convenio hotelero con Valencia, Taboada and Piñol	Acuerdo entre el hotel y Valencia, Taboada and Piñol para ofrecer servicios especiales a nuestros huéspedes.	2022-01-26	2027-01-25
817	Convenio hotelero con Valverde-Villaverde	Acuerdo entre el hotel y Valverde-Villaverde para ofrecer servicios especiales a nuestros huéspedes.	2020-08-21	2022-08-21
818	Convenio hotelero con Gálvez-Bejarano	Acuerdo entre el hotel y Gálvez-Bejarano para ofrecer servicios especiales a nuestros huéspedes.	2021-09-02	2025-09-01
819	Convenio hotelero con Sarmiento and Sons	Acuerdo entre el hotel y Sarmiento and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-10-26	2026-10-25
820	Convenio hotelero con Reguera, Pascual and Guardia	Acuerdo entre el hotel y Reguera, Pascual and Guardia para ofrecer servicios especiales a nuestros huéspedes.	2022-01-20	2023-01-20
821	Convenio hotelero con Vilalta-Landa	Acuerdo entre el hotel y Vilalta-Landa para ofrecer servicios especiales a nuestros huéspedes.	2023-12-20	2024-12-19
822	Convenio hotelero con Prieto Ltd	Acuerdo entre el hotel y Prieto Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-12-30	2027-12-29
823	Convenio hotelero con Gras, Martinez and Herrera	Acuerdo entre el hotel y Gras, Martinez and Herrera para ofrecer servicios especiales a nuestros huéspedes.	2020-09-12	2023-09-12
824	Convenio hotelero con Serrano-Puig	Acuerdo entre el hotel y Serrano-Puig para ofrecer servicios especiales a nuestros huéspedes.	2023-02-26	2024-02-26
825	Convenio hotelero con Aguiló, Pellicer and Rey	Acuerdo entre el hotel y Aguiló, Pellicer and Rey para ofrecer servicios especiales a nuestros huéspedes.	2024-02-13	2029-02-11
826	Convenio Capdevila	Acuerdo entre el hotel y Santamaría, Folch and Capdevila para ofrecer servicios especiales a nuestros huéspedes.	2022-12-24	2027-12-23
827	Convenio hotelero con Santiago-Batalla	Acuerdo entre el hotel y Santiago-Batalla para ofrecer servicios especiales a nuestros huéspedes.	2020-09-30	2025-09-29
828	Convenio hotelero con Moles-Valderrama	Acuerdo entre el hotel y Moles-Valderrama para ofrecer servicios especiales a nuestros huéspedes.	2022-05-14	2024-05-13
829	Convenio hotelero con Pintor-Contreras	Acuerdo entre el hotel y Pintor-Contreras para ofrecer servicios especiales a nuestros huéspedes.	2024-04-10	2027-04-10
830	Convenio hotelero con Montenegro-Arcos	Acuerdo entre el hotel y Montenegro-Arcos para ofrecer servicios especiales a nuestros huéspedes.	2020-10-17	2024-10-16
831	Convenio hotelero con Almeida Group	Acuerdo entre el hotel y Almeida Group para ofrecer servicios especiales a nuestros huéspedes.	2022-09-17	2026-09-16
832	Convenio hotelero con Berenguer-Sobrino	Acuerdo entre el hotel y Berenguer-Sobrino para ofrecer servicios especiales a nuestros huéspedes.	2022-12-10	2026-12-09
833	Convenio hotelero con Ricart LLC	Acuerdo entre el hotel y Ricart LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-11-27	2023-11-27
834	Convenio hotelero con Garmendia, Plana and Sanjuan	Acuerdo entre el hotel y Garmendia, Plana and Sanjuan para ofrecer servicios especiales a nuestros huéspedes.	2024-05-10	2028-05-09
835	Convenio hotelero con Ródenas LLC	Acuerdo entre el hotel y Ródenas LLC para ofrecer servicios especiales a nuestros huéspedes.	2020-07-24	2024-07-23
836	Convenio hotelero con Girona Ltd	Acuerdo entre el hotel y Girona Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-07-07	2027-07-06
837	Convenio hotelero con Ochoa-Bermejo	Acuerdo entre el hotel y Ochoa-Bermejo para ofrecer servicios especiales a nuestros huéspedes.	2020-10-07	2022-10-07
838	Convenio hotelero con Lladó-Gárate	Acuerdo entre el hotel y Lladó-Gárate para ofrecer servicios especiales a nuestros huéspedes.	2022-10-11	2027-10-10
839	Convenio hotelero con Badía PLC	Acuerdo entre el hotel y Badía PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-03-21	2024-03-20
840	Convenio Velázquez	Acuerdo entre el hotel y Dominguez, Villalba and Velázquez para ofrecer servicios especiales a nuestros huéspedes.	2020-05-26	2024-05-25
841	Convenio hotelero con Cuervo-Zapata	Acuerdo entre el hotel y Cuervo-Zapata para ofrecer servicios especiales a nuestros huéspedes.	2022-03-13	2027-03-12
842	Convenio hotelero con Sarabia-Royo	Acuerdo entre el hotel y Sarabia-Royo para ofrecer servicios especiales a nuestros huéspedes.	2021-02-07	2026-02-06
843	Convenio hotelero con Abril Group	Acuerdo entre el hotel y Abril Group para ofrecer servicios especiales a nuestros huéspedes.	2022-08-11	2027-08-10
844	Convenio Sacristán	Acuerdo entre el hotel y Ripoll, Carballo and Sacristán para ofrecer servicios especiales a nuestros huéspedes.	2020-11-05	2025-11-04
845	Convenio Hidalgo	Acuerdo entre el hotel y Machado, Corbacho and Hidalgo para ofrecer servicios especiales a nuestros huéspedes.	2024-03-20	2028-03-19
846	Convenio hotelero con Milla-Ariño	Acuerdo entre el hotel y Milla-Ariño para ofrecer servicios especiales a nuestros huéspedes.	2024-04-29	2027-04-29
847	Convenio hotelero con Solano-Gimeno	Acuerdo entre el hotel y Solano-Gimeno para ofrecer servicios especiales a nuestros huéspedes.	2021-06-13	2023-06-13
848	Convenio hotelero con Atienza, Castro and Suárez	Acuerdo entre el hotel y Atienza, Castro and Suárez para ofrecer servicios especiales a nuestros huéspedes.	2022-09-17	2023-09-17
849	Convenio hotelero con Portero-Olmo	Acuerdo entre el hotel y Portero-Olmo para ofrecer servicios especiales a nuestros huéspedes.	2024-03-01	2028-02-29
850	Convenio hotelero con Pomares Group	Acuerdo entre el hotel y Pomares Group para ofrecer servicios especiales a nuestros huéspedes.	2020-07-01	2022-07-01
851	Convenio hotelero con Blanch, Pomares and Mosquera	Acuerdo entre el hotel y Blanch, Pomares and Mosquera para ofrecer servicios especiales a nuestros huéspedes.	2022-09-17	2024-09-16
852	Convenio hotelero con Batlle-Jordán	Acuerdo entre el hotel y Batlle-Jordán para ofrecer servicios especiales a nuestros huéspedes.	2023-06-25	2025-06-24
853	Convenio hotelero con Rodriguez, Montero and Ochoa	Acuerdo entre el hotel y Rodriguez, Montero and Ochoa para ofrecer servicios especiales a nuestros huéspedes.	2020-06-25	2023-06-25
854	Convenio hotelero con Ángel, Medina and Amat	Acuerdo entre el hotel y Ángel, Medina and Amat para ofrecer servicios especiales a nuestros huéspedes.	2021-05-25	2022-05-25
855	Convenio hotelero con Manjón LLC	Acuerdo entre el hotel y Manjón LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-12-18	2025-12-17
856	Convenio hotelero con Salcedo-Múgica	Acuerdo entre el hotel y Salcedo-Múgica para ofrecer servicios especiales a nuestros huéspedes.	2021-01-26	2026-01-25
857	Convenio hotelero con Echevarría and Sons	Acuerdo entre el hotel y Echevarría and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-05-23	2025-05-22
858	Convenio hotelero con Almansa PLC	Acuerdo entre el hotel y Almansa PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-06-30	2026-06-29
859	Convenio hotelero con Valle and Sons	Acuerdo entre el hotel y Valle and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-09-26	2026-09-25
860	Convenio hotelero con Cortes, Julián and Gabaldón	Acuerdo entre el hotel y Cortes, Julián and Gabaldón para ofrecer servicios especiales a nuestros huéspedes.	2023-01-30	2024-01-30
861	Convenio hotelero con Durán	Acuerdo entre el hotel y Durán, Calderón and Benavides para ofrecer servicios especiales a nuestros huéspedes.	2022-03-02	2027-03-01
862	Convenio hotelero con Daza Ltd	Acuerdo entre el hotel y Daza Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-08-22	2025-08-21
863	Convenio hotelero con Iñiguez-Burgos	Acuerdo entre el hotel y Iñiguez-Burgos para ofrecer servicios especiales a nuestros huéspedes.	2023-06-07	2028-06-05
864	Convenio hotelero con Manuel, Ramos and Puente	Acuerdo entre el hotel y Manuel, Ramos and Puente para ofrecer servicios especiales a nuestros huéspedes.	2022-01-16	2026-01-15
865	Convenio hotelero con Cordero, Meléndez and Vara	Acuerdo entre el hotel y Cordero, Meléndez and Vara para ofrecer servicios especiales a nuestros huéspedes.	2020-12-11	2021-12-11
866	Convenio hotelero con Franch, Arellano and Herrero	Acuerdo entre el hotel y Franch, Arellano and Herrero para ofrecer servicios especiales a nuestros huéspedes.	2022-04-04	2024-04-03
867	Convenio hotelero con Galán Ltd	Acuerdo entre el hotel y Galán Ltd para ofrecer servicios especiales a nuestros huéspedes.	2022-07-15	2025-07-14
868	Convenio hotelero con Espejo-Arco	Acuerdo entre el hotel y Espejo-Arco para ofrecer servicios especiales a nuestros huéspedes.	2024-05-24	2029-05-23
869	Convenio hotelero con Parejo-Boada	Acuerdo entre el hotel y Parejo-Boada para ofrecer servicios especiales a nuestros huéspedes.	2022-08-18	2027-08-17
870	Convenio hotelero con Madrigal-Viana	Acuerdo entre el hotel y Madrigal-Viana para ofrecer servicios especiales a nuestros huéspedes.	2024-01-18	2028-01-17
871	Convenio hotelero con Morera, Piquer and Botella	Acuerdo entre el hotel y Morera, Piquer and Botella para ofrecer servicios especiales a nuestros huéspedes.	2021-01-17	2025-01-16
872	Convenio hotelero con Rubio, Expósito and Palau	Acuerdo entre el hotel y Rubio, Expósito and Palau para ofrecer servicios especiales a nuestros huéspedes.	2020-07-05	2025-07-04
873	Convenio hotelero con Alcalá-Linares	Acuerdo entre el hotel y Alcalá-Linares para ofrecer servicios especiales a nuestros huéspedes.	2021-12-27	2024-12-26
874	Convenio hotelero con Trujillo Ltd	Acuerdo entre el hotel y Trujillo Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-04-25	2022-04-25
875	Convenio hotelero con Roig, Sevillano and Montero	Acuerdo entre el hotel y Roig, Sevillano and Montero para ofrecer servicios especiales a nuestros huéspedes.	2020-08-27	2024-08-26
876	Convenio hotelero con Juárez, Tejada and Peral	Acuerdo entre el hotel y Juárez, Tejada and Peral para ofrecer servicios especiales a nuestros huéspedes.	2021-08-24	2025-08-23
877	Convenio hotelero con Carrasco LLC	Acuerdo entre el hotel y Carrasco LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-02-08	2023-02-08
878	Convenio hotelero con Cuenca-Gordillo	Acuerdo entre el hotel y Cuenca-Gordillo para ofrecer servicios especiales a nuestros huéspedes.	2022-05-04	2026-05-03
879	Convenio hotelero con Agustí Inc	Acuerdo entre el hotel y Agustí Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-08-23	2025-08-22
880	Convenio hotelero con Alvarado-Castillo	Acuerdo entre el hotel y Alvarado-Castillo para ofrecer servicios especiales a nuestros huéspedes.	2022-10-04	2024-10-03
881	Convenio hotelero con Rivera-Cánovas	Acuerdo entre el hotel y Rivera-Cánovas para ofrecer servicios especiales a nuestros huéspedes.	2023-08-15	2024-08-14
882	Convenio hotelero con Vicens Inc	Acuerdo entre el hotel y Vicens Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-09-29	2023-09-29
883	Convenio hotelero con Merino-Cerro	Acuerdo entre el hotel y Merino-Cerro para ofrecer servicios especiales a nuestros huéspedes.	2023-03-25	2027-03-24
884	Convenio hotelero con Rico-Sanmartín	Acuerdo entre el hotel y Rico-Sanmartín para ofrecer servicios especiales a nuestros huéspedes.	2021-12-08	2024-12-07
885	Convenio hotelero con Cáceres-Cervantes	Acuerdo entre el hotel y Cáceres-Cervantes para ofrecer servicios especiales a nuestros huéspedes.	2022-09-29	2026-09-28
886	Convenio hotelero con Pulido, Ibañez and Zurita	Acuerdo entre el hotel y Pulido, Ibañez and Zurita para ofrecer servicios especiales a nuestros huéspedes.	2023-06-22	2027-06-21
887	Convenio hotelero con Manuel, Lladó and Avilés	Acuerdo entre el hotel y Manuel, Lladó and Avilés para ofrecer servicios especiales a nuestros huéspedes.	2023-08-17	2027-08-16
888	Convenio hotelero con Escamilla-Izaguirre	Acuerdo entre el hotel y Escamilla-Izaguirre para ofrecer servicios especiales a nuestros huéspedes.	2022-01-10	2024-01-10
889	Convenio hotelero con Águila, Alcalá and Ricart	Acuerdo entre el hotel y Águila, Alcalá and Ricart para ofrecer servicios especiales a nuestros huéspedes.	2022-01-31	2026-01-30
890	Convenio hotelero con Carrillo Inc	Acuerdo entre el hotel y Carrillo Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-10-17	2022-10-17
891	Convenio hotelero con Belmonte, Manjón and Cid	Acuerdo entre el hotel y Belmonte, Manjón and Cid para ofrecer servicios especiales a nuestros huéspedes.	2021-11-06	2025-11-05
892	Convenio hotelero con Nuñez	Acuerdo entre el hotel y Nuñez and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-05-21	2025-05-20
893	Convenio hotelero con Campoy	Acuerdo entre el hotel y Campoy, Vilalta and Montalbán para ofrecer servicios especiales a nuestros huéspedes.	2020-08-16	2024-08-15
894	Convenio hotelero con Hernández	Acuerdo entre el hotel y Hernández, Bellido and Ferrero para ofrecer servicios especiales a nuestros huéspedes.	2024-02-22	2025-02-21
895	Convenio hotelero con Rueda-Rocha	Acuerdo entre el hotel y Rueda-Rocha para ofrecer servicios especiales a nuestros huéspedes.	2023-09-26	2028-09-24
896	Convenio hotelero con Valenzuela	Acuerdo entre el hotel y Valenzuela, Pomares and Alcázar para ofrecer servicios especiales a nuestros huéspedes.	2022-05-30	2027-05-29
897	Convenio hotelero con Barba, Cazorla and Ugarte	Acuerdo entre el hotel y Barba, Cazorla and Ugarte para ofrecer servicios especiales a nuestros huéspedes.	2023-12-02	2028-11-30
898	Convenio hotelero con Tejada, Ruano and Padilla	Acuerdo entre el hotel y Tejada, Ruano and Padilla para ofrecer servicios especiales a nuestros huéspedes.	2020-09-03	2023-09-03
899	Convenio hotelero con Seco-Acuña	Acuerdo entre el hotel y Seco-Acuña para ofrecer servicios especiales a nuestros huéspedes.	2022-04-30	2023-04-30
900	Convenio hotelero con Varela-Campo	Acuerdo entre el hotel y Varela-Campo para ofrecer servicios especiales a nuestros huéspedes.	2021-03-15	2022-03-15
901	Convenio hotelero con Vaquero Group	Acuerdo entre el hotel y Vaquero Group para ofrecer servicios especiales a nuestros huéspedes.	2022-12-22	2027-12-21
902	Convenio hotelero con Esteve-Castejón	Acuerdo entre el hotel y Esteve-Castejón para ofrecer servicios especiales a nuestros huéspedes.	2020-07-13	2023-07-13
903	Convenio hotelero con Menéndez-Guardiola	Acuerdo entre el hotel y Menéndez-Guardiola para ofrecer servicios especiales a nuestros huéspedes.	2021-02-16	2026-02-15
904	Convenio hotelero con Nogués, Chacón and Landa	Acuerdo entre el hotel y Nogués, Chacón and Landa para ofrecer servicios especiales a nuestros huéspedes.	2021-06-24	2022-06-24
905	Convenio hotelero con Duque, Cañas and Rubio	Acuerdo entre el hotel y Duque, Cañas and Rubio para ofrecer servicios especiales a nuestros huéspedes.	2022-03-15	2026-03-14
906	Convenio hotelero con Martin, Mateos and Salgado	Acuerdo entre el hotel y Martin, Mateos and Salgado para ofrecer servicios especiales a nuestros huéspedes.	2022-08-06	2025-08-05
907	Convenio hotelero con Abella and Sons	Acuerdo entre el hotel y Abella and Sons para ofrecer servicios especiales a nuestros huéspedes.	2020-11-13	2022-11-13
908	Convenio hotelero con Cañete Inc	Acuerdo entre el hotel y Cañete Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-08-07	2026-08-06
909	Convenio hotelero con Cañas, Lamas and Iborra	Acuerdo entre el hotel y Cañas, Lamas and Iborra para ofrecer servicios especiales a nuestros huéspedes.	2022-09-07	2025-09-06
910	Convenio hotelero con Mesa-Arco	Acuerdo entre el hotel y Mesa-Arco para ofrecer servicios especiales a nuestros huéspedes.	2022-12-21	2027-12-20
911	Convenio hotelero con Villegas-Trillo	Acuerdo entre el hotel y Villegas-Trillo para ofrecer servicios especiales a nuestros huéspedes.	2021-01-16	2026-01-15
912	Convenio hotelero con Suárez-Alcalde	Acuerdo entre el hotel y Suárez-Alcalde para ofrecer servicios especiales a nuestros huéspedes.	2021-09-21	2024-09-20
913	Convenio hotelero con Manzano-Calvet	Acuerdo entre el hotel y Manzano-Calvet para ofrecer servicios especiales a nuestros huéspedes.	2020-11-09	2021-11-09
914	Convenio hotelero con Alcántara, Viña and Pedrosa	Acuerdo entre el hotel y Alcántara, Viña and Pedrosa para ofrecer servicios especiales a nuestros huéspedes.	2023-02-18	2024-02-18
915	Convenio hotelero con Calvet, Viñas and Blazquez	Acuerdo entre el hotel y Calvet, Viñas and Blazquez para ofrecer servicios especiales a nuestros huéspedes.	2021-06-09	2023-06-09
916	Convenio hotelero con Villar, Priego and Conesa	Acuerdo entre el hotel y Villar, Priego and Conesa para ofrecer servicios especiales a nuestros huéspedes.	2023-11-18	2024-11-17
917	Convenio hotelero con Abascal-Isern	Acuerdo entre el hotel y Abascal-Isern para ofrecer servicios especiales a nuestros huéspedes.	2021-02-02	2023-02-02
918	Convenio hotelero con Marcos-Carro	Acuerdo entre el hotel y Marcos-Carro para ofrecer servicios especiales a nuestros huéspedes.	2023-07-04	2024-07-03
919	Convenio hotelero con Cabanillas and Sons	Acuerdo entre el hotel y Cabanillas and Sons para ofrecer servicios especiales a nuestros huéspedes.	2021-04-08	2026-04-07
920	Convenio hotelero con Taboada, Belda and Robles	Acuerdo entre el hotel y Taboada, Belda and Robles para ofrecer servicios especiales a nuestros huéspedes.	2021-07-02	2024-07-01
921	Convenio hotelero con Tejera, Soler and Iborra	Acuerdo entre el hotel y Tejera, Soler and Iborra para ofrecer servicios especiales a nuestros huéspedes.	2022-05-29	2026-05-28
922	Convenio hotelero con Mayo LLC	Acuerdo entre el hotel y Mayo LLC para ofrecer servicios especiales a nuestros huéspedes.	2024-05-17	2027-05-17
923	Convenio hotelero con Huertas-Lledó	Acuerdo entre el hotel y Huertas-Lledó para ofrecer servicios especiales a nuestros huéspedes.	2022-07-21	2024-07-20
924	Convenio hotelero con Pascual PLC	Acuerdo entre el hotel y Pascual PLC para ofrecer servicios especiales a nuestros huéspedes.	2021-01-23	2025-01-22
925	Convenio hotelero con Escolano-Melero	Acuerdo entre el hotel y Escolano-Melero para ofrecer servicios especiales a nuestros huéspedes.	2020-07-02	2023-07-02
926	Convenio hotelero con Barroso, Villar and Cabrero	Acuerdo entre el hotel y Barroso, Villar and Cabrero para ofrecer servicios especiales a nuestros huéspedes.	2022-11-01	2025-10-31
927	Convenio hotelero con Bosch, Bonilla and Corbacho	Acuerdo entre el hotel y Bosch, Bonilla and Corbacho para ofrecer servicios especiales a nuestros huéspedes.	2023-11-26	2028-11-24
928	Convenio hotelero con Bueno PLC	Acuerdo entre el hotel y Bueno PLC para ofrecer servicios especiales a nuestros huéspedes.	2020-10-01	2022-10-01
929	Convenio hotelero con Tomás, Linares and Taboada	Acuerdo entre el hotel y Tomás, Linares and Taboada para ofrecer servicios especiales a nuestros huéspedes.	2020-10-03	2021-10-03
930	Convenio hotelero con Cantón-Melero	Acuerdo entre el hotel y Cantón-Melero para ofrecer servicios especiales a nuestros huéspedes.	2022-01-02	2027-01-01
931	Convenio hotelero con Pascual, Reyes and Román	Acuerdo entre el hotel y Pascual, Reyes and Román para ofrecer servicios especiales a nuestros huéspedes.	2022-04-02	2026-04-01
932	Convenio hotelero con Pallarès LLC	Acuerdo entre el hotel y Pallarès LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-06-08	2027-06-07
933	Convenio hotelero con Cazorla Ltd	Acuerdo entre el hotel y Cazorla Ltd para ofrecer servicios especiales a nuestros huéspedes.	2021-02-13	2023-02-13
934	Convenio hotelero con Ferrán, Moll and Cisneros	Acuerdo entre el hotel y Ferrán, Moll and Cisneros para ofrecer servicios especiales a nuestros huéspedes.	2022-04-09	2026-04-08
935	Convenio hotelero con Blanco, Gascón and Linares	Acuerdo entre el hotel y Blanco, Gascón and Linares para ofrecer servicios especiales a nuestros huéspedes.	2022-09-22	2023-09-22
936	Convenio hotelero con Jerez Group	Acuerdo entre el hotel y Jerez Group para ofrecer servicios especiales a nuestros huéspedes.	2022-11-03	2026-11-02
937	Convenio hotelero con Lucena, Muro and Camacho	Acuerdo entre el hotel y Lucena, Muro and Camacho para ofrecer servicios especiales a nuestros huéspedes.	2024-01-26	2028-01-25
938	Convenio hotelero con Feliu, Cabeza and Zamorano	Acuerdo entre el hotel y Feliu, Cabeza and Zamorano para ofrecer servicios especiales a nuestros huéspedes.	2020-11-07	2021-11-07
939	Convenio hotelero con Galan Ltd	Acuerdo entre el hotel y Galan Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-08-31	2025-08-30
940	Convenio hotelero con Guillen, Mora and Bernad	Acuerdo entre el hotel y Guillen, Mora and Bernad para ofrecer servicios especiales a nuestros huéspedes.	2024-04-10	2028-04-09
941	Convenio hotelero con Ribera, Báez and Huerta	Acuerdo entre el hotel y Ribera, Báez and Huerta para ofrecer servicios especiales a nuestros huéspedes.	2022-08-21	2026-08-20
942	Convenio hotelero con Camacho and Sons	Acuerdo entre el hotel y Camacho and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-04-30	2028-04-28
943	Convenio hotelero con Luz Ltd	Acuerdo entre el hotel y Luz Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-06-08	2024-06-07
944	Convenio hotelero con Anguita and Sons	Acuerdo entre el hotel y Anguita and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-10-12	2027-10-11
945	Convenio hotelero con Manuel-Cuesta	Acuerdo entre el hotel y Manuel-Cuesta para ofrecer servicios especiales a nuestros huéspedes.	2024-02-25	2028-02-24
946	Convenio hotelero con Murcia, Bolaños and Blanes	Acuerdo entre el hotel y Murcia, Bolaños and Blanes para ofrecer servicios especiales a nuestros huéspedes.	2023-12-11	2026-12-10
947	Convenio hotelero con Pi-Mena	Acuerdo entre el hotel y Pi-Mena para ofrecer servicios especiales a nuestros huéspedes.	2020-09-18	2021-09-18
948	Convenio hotelero con Crespi, Otero and Baena	Acuerdo entre el hotel y Crespi, Otero and Baena para ofrecer servicios especiales a nuestros huéspedes.	2020-08-24	2021-08-24
949	Convenio hotelero con Arnau-Gabaldón	Acuerdo entre el hotel y Arnau-Gabaldón para ofrecer servicios especiales a nuestros huéspedes.	2023-07-31	2024-07-30
950	Convenio hotelero con Casanova, Alfaro and Ferrero	Acuerdo entre el hotel y Casanova, Alfaro and Ferrero para ofrecer servicios especiales a nuestros huéspedes.	2021-08-02	2024-08-01
951	Convenio hotelero con Perez-Neira	Acuerdo entre el hotel y Perez-Neira para ofrecer servicios especiales a nuestros huéspedes.	2022-03-17	2025-03-16
952	Convenio hotelero con Roura-Bernat	Acuerdo entre el hotel y Roura-Bernat para ofrecer servicios especiales a nuestros huéspedes.	2021-03-23	2025-03-22
953	Convenio hotelero con Machado-Baños	Acuerdo entre el hotel y Machado-Baños para ofrecer servicios especiales a nuestros huéspedes.	2023-05-08	2027-05-07
954	Convenio hotelero con Valenciano-Otero	Acuerdo entre el hotel y Valenciano-Otero para ofrecer servicios especiales a nuestros huéspedes.	2021-03-03	2024-03-02
955	Convenio hotelero con Ugarte, Montero and Montaña	Acuerdo entre el hotel y Ugarte, Montero and Montaña para ofrecer servicios especiales a nuestros huéspedes.	2020-10-06	2022-10-06
956	Convenio hotelero con Puente, Barón and Sanmiguel	Acuerdo entre el hotel y Puente, Barón and Sanmiguel para ofrecer servicios especiales a nuestros huéspedes.	2023-01-10	2025-01-09
957	Convenio hotelero con Amo-Riquelme	Acuerdo entre el hotel y Amo-Riquelme para ofrecer servicios especiales a nuestros huéspedes.	2023-08-29	2025-08-28
958	Convenio hotelero con Álamo, Andrés and Portillo	Acuerdo entre el hotel y Álamo, Andrés and Portillo para ofrecer servicios especiales a nuestros huéspedes.	2021-12-08	2024-12-07
959	Convenio hotelero con Olmedo, Jordán and Badía	Acuerdo entre el hotel y Olmedo, Jordán and Badía para ofrecer servicios especiales a nuestros huéspedes.	2022-11-23	2027-11-22
960	Convenio hotelero con Herranz-Peñas	Acuerdo entre el hotel y Herranz-Peñas para ofrecer servicios especiales a nuestros huéspedes.	2021-12-13	2022-12-13
961	Convenio hotelero con Valle, Uribe and Domingo	Acuerdo entre el hotel y Valle, Uribe and Domingo para ofrecer servicios especiales a nuestros huéspedes.	2023-04-02	2028-03-31
962	Convenio hotelero con Lopez, Pol and Aguiló	Acuerdo entre el hotel y Lopez, Pol and Aguiló para ofrecer servicios especiales a nuestros huéspedes.	2022-10-27	2027-10-26
963	Convenio hotelero con Salinas and Sons	Acuerdo entre el hotel y Salinas and Sons para ofrecer servicios especiales a nuestros huéspedes.	2022-07-30	2026-07-29
964	Convenio hotelero con Portillo, Prat and Medina	Acuerdo entre el hotel y Portillo, Prat and Medina para ofrecer servicios especiales a nuestros huéspedes.	2023-09-11	2027-09-10
965	Convenio hotelero con Francisco PLC	Acuerdo entre el hotel y Francisco PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-01-27	2027-01-26
966	Convenio hotelero con Oliva, Gomez and Juárez	Acuerdo entre el hotel y Oliva, Gomez and Juárez para ofrecer servicios especiales a nuestros huéspedes.	2021-05-29	2024-05-28
967	Convenio hotelero con Cárdenas Ltd	Acuerdo entre el hotel y Cárdenas Ltd para ofrecer servicios especiales a nuestros huéspedes.	2020-08-09	2024-08-08
968	Convenio hotelero con Flores Group	Acuerdo entre el hotel y Flores Group para ofrecer servicios especiales a nuestros huéspedes.	2023-07-14	2025-07-13
969	Convenio hotelero con Sebastián LLC	Acuerdo entre el hotel y Sebastián LLC para ofrecer servicios especiales a nuestros huéspedes.	2023-03-02	2027-03-01
970	Convenio hotelero con Bustamante, Vizcaíno and Pla	Acuerdo entre el hotel y Bustamante, Vizcaíno and Pla para ofrecer servicios especiales a nuestros huéspedes.	2021-01-19	2024-01-19
971	Convenio hotelero con Vilanova-Olivares	Acuerdo entre el hotel y Vilanova-Olivares para ofrecer servicios especiales a nuestros huéspedes.	2024-04-14	2025-04-14
972	Convenio hotelero con Colom, Aliaga and Almagro	Acuerdo entre el hotel y Colom, Aliaga and Almagro para ofrecer servicios especiales a nuestros huéspedes.	2020-07-09	2021-07-09
973	Convenio hotelero con Aramburu, Uriarte and Jara	Acuerdo entre el hotel y Aramburu, Uriarte and Jara para ofrecer servicios especiales a nuestros huéspedes.	2020-07-11	2024-07-10
974	Convenio hotelero con Morante Ltd	Acuerdo entre el hotel y Morante Ltd para ofrecer servicios especiales a nuestros huéspedes.	2024-01-20	2026-01-19
975	Convenio hotelero con Torrens, Polo and Sureda	Acuerdo entre el hotel y Torrens, Polo and Sureda para ofrecer servicios especiales a nuestros huéspedes.	2022-08-07	2025-08-06
976	Convenio hotelero con Isern-Dávila	Acuerdo entre el hotel y Isern-Dávila para ofrecer servicios especiales a nuestros huéspedes.	2022-06-06	2026-06-05
977	Convenio hotelero con Villegas, Lillo and Gómez	Acuerdo entre el hotel y Villegas, Lillo and Gómez para ofrecer servicios especiales a nuestros huéspedes.	2023-06-13	2028-06-11
978	Convenio hotelero con Castells Inc	Acuerdo entre el hotel y Castells Inc para ofrecer servicios especiales a nuestros huéspedes.	2020-10-17	2023-10-17
979	Convenio hotelero con Barrera PLC	Acuerdo entre el hotel y Barrera PLC para ofrecer servicios especiales a nuestros huéspedes.	2023-08-17	2026-08-16
980	Convenio hotelero con Palmer LLC	Acuerdo entre el hotel y Palmer LLC para ofrecer servicios especiales a nuestros huéspedes.	2022-04-12	2024-04-11
981	Convenio hotelero con Piquer, Jiménez and Ayllón	Acuerdo entre el hotel y Piquer, Jiménez and Ayllón para ofrecer servicios especiales a nuestros huéspedes.	2020-11-20	2023-11-20
982	Convenio hotelero con Toro, Porras and Carro	Acuerdo entre el hotel y Toro, Porras and Carro para ofrecer servicios especiales a nuestros huéspedes.	2024-02-05	2027-02-04
983	Convenio Echevarría	Acuerdo entre el hotel y Garriga, Echevarría and Verdejo para ofrecer servicios especiales a nuestros huéspedes.	2020-06-14	2023-06-14
984	Convenio hotelero con Noriega-Lucena	Acuerdo entre el hotel y Noriega-Lucena para ofrecer servicios especiales a nuestros huéspedes.	2021-06-12	2026-06-11
985	Convenio hotelero con Hoz PLC	Acuerdo entre el hotel y Hoz PLC para ofrecer servicios especiales a nuestros huéspedes.	2022-09-18	2027-09-17
986	Convenio hotelero con Heras, Somoza and Bernad	Acuerdo entre el hotel y Heras, Somoza and Bernad para ofrecer servicios especiales a nuestros huéspedes.	2021-11-06	2026-11-05
987	Convenio hotelero con Pont-Soler	Acuerdo entre el hotel y Pont-Soler para ofrecer servicios especiales a nuestros huéspedes.	2020-11-07	2022-11-07
988	Convenio hotelero con Pavón-Páez	Acuerdo entre el hotel y Pavón-Páez para ofrecer servicios especiales a nuestros huéspedes.	2022-11-07	2026-11-06
989	Convenio hotelero con Marin, Aliaga and Gallego	Acuerdo entre el hotel y Marin, Aliaga and Gallego para ofrecer servicios especiales a nuestros huéspedes.	2021-03-28	2026-03-27
990	Convenio hotelero con Bolaños-Salcedo	Acuerdo entre el hotel y Bolaños-Salcedo para ofrecer servicios especiales a nuestros huéspedes.	2021-11-26	2022-11-26
991	Convenio hotelero con Briones, Piñeiro and Escrivá	Acuerdo entre el hotel y Briones, Piñeiro and Escrivá para ofrecer servicios especiales a nuestros huéspedes.	2021-11-20	2022-11-20
992	Convenio hotelero con Prado and Sons	Acuerdo entre el hotel y Prado and Sons para ofrecer servicios especiales a nuestros huéspedes.	2023-01-13	2024-01-13
993	Convenio hotelero con Cánovas Inc	Acuerdo entre el hotel y Cánovas Inc para ofrecer servicios especiales a nuestros huéspedes.	2021-02-22	2024-02-22
994	Convenio hotelero con Bello-Expósito	Acuerdo entre el hotel y Bello-Expósito para ofrecer servicios especiales a nuestros huéspedes.	2020-08-07	2023-08-07
995	Convenio hotelero con Boix-Ibarra	Acuerdo entre el hotel y Boix-Ibarra para ofrecer servicios especiales a nuestros huéspedes.	2021-04-16	2022-04-16
996	Convenio hotelero con Torre-Galán	Acuerdo entre el hotel y Torre-Galán para ofrecer servicios especiales a nuestros huéspedes.	2021-09-28	2022-09-28
997	Convenio hotelero con Sobrino Ltd	Acuerdo entre el hotel y Sobrino Ltd para ofrecer servicios especiales a nuestros huéspedes.	2023-04-02	2026-04-01
998	Convenio hotelero con Mosquera-Amor	Acuerdo entre el hotel y Mosquera-Amor para ofrecer servicios especiales a nuestros huéspedes.	2022-02-15	2024-02-15
999	Convenio hotelero con Canales Group	Acuerdo entre el hotel y Canales Group para ofrecer servicios especiales a nuestros huéspedes.	2020-10-27	2021-10-27
1000	Convenio hotelero con Galán-Pallarès	Acuerdo entre el hotel y Galán-Pallarès para ofrecer servicios especiales a nuestros huéspedes.	2021-02-16	2026-02-15
\.


                                                                                                                                                                                                                                                                                             4971.dat                                                                                            0000600 0004000 0002000 00000000147 15015342721 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	277	94	110	25000.00	15	2019-01-31	2019-02-15	0.00	0.00	375000.00	2025-05-27 08:57:25	postgres	D
\.


                                                                                                                                                                                                                                                                                                                                                                                                                         4969.dat                                                                                            0000600 0004000 0002000 00000000100 15015342721 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	3	3	15000.00	1	15000.00	2025-05-27 08:45:54	postgres	D
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                4950.dat                                                                                            0000600 0004000 0002000 00000057031 15015342721 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	5	170	MEDELLIN
2	5	170	ABEJORRAL
4	5	170	ABRIAQUI
21	5	170	ALEJANDRIA
30	5	170	AMAGA
31	5	170	AMALFI
34	5	170	ANDES
36	5	170	ANGELOPOLIS
38	5	170	ANGOSTURA
40	5	170	ANORI
42	5	170	ANTIOQUIA
44	5	170	ANZA
45	5	170	APARTADO
51	5	170	ARBOLETES
55	5	170	ARGELIA
59	5	170	ARMENIA
79	5	170	BARBOSA
86	5	170	BELMIRA
88	5	170	BELLO
91	5	170	BETANIA
93	5	170	BETULIA
101	5	170	BOLIVAR
107	5	170	BRICEÑO
113	5	170	BURITICA
120	5	170	CACERES
125	5	170	CAICEDO
129	5	170	CALDAS
134	5	170	CAMPAMENTO
138	5	170	CAÑASGORDAS
142	5	170	CARACOLI
145	5	170	CARAMANTA
147	5	170	CAREPA
148	5	170	CARMEN DE VIBORAL
150	5	170	CAROLINA
154	5	170	CAUCASIA
172	5	170	CHIGORODO
190	5	170	CISNEROS
197	5	170	COCORNA
206	5	170	CONCEPCION
209	5	170	CONCORDIA
212	5	170	COPACABANA
234	5	170	DABEIBA
237	5	170	DON MATIAS
240	5	170	EBEJICO
250	5	170	EL BAGRE
264	5	170	ENTRERRIOS
266	5	170	ENVIGADO
282	5	170	FREDONIA
284	5	170	FRONTINO
306	5	170	GIRALDO
308	5	170	GIRARDOTA
310	5	170	GOMEZ PLATA
313	5	170	GRANADA
315	5	170	GUADALUPE
318	5	170	GUARNE
321	5	170	GUATAPE
347	5	170	HELICONIA
353	5	170	HISPANIA
360	5	170	ITAGUI
361	5	170	ITUANGO
364	5	170	JARDIN
368	5	170	JERICO
376	5	170	LA CEJA
380	5	170	LA ESTRELLA
390	5	170	LA PINTADA
400	5	170	LA UNION
411	5	170	LIBORINA
425	5	170	MACEO
440	5	170	MARINILLA
467	5	170	MONTEBELLO
475	5	170	MURINDO
480	5	170	MUTATA
483	5	170	NARIÑO
490	5	170	NECOCLI
495	5	170	NECHI
501	5	170	OLAYA
541	5	170	PEÑOL
543	5	170	PEQUE
576	5	170	PUEBLORRICO
579	5	170	PUERTO BERRIO
585	5	170	PUERTO NARE (LA\nMAGDALENA)
591	5	170	PUERTO TRIUNFO
604	5	170	REMEDIOS
607	5	170	RETIRO
615	5	170	RIONEGRO
628	5	170	SABANALARGA
631	5	170	SABANETA
642	5	170	SALGAR
647	5	170	SAN ANDRES
649	5	170	SAN CARLOS
652	5	170	SAN FRANCISCO
656	5	170	SAN JERONIMO
658	5	170	SAN JOSE DE LA MONTAÑA
659	5	170	SAN JUAN DE URABA
660	5	170	SAN LUIS
664	5	170	SAN PEDRO
665	5	170	SAN PEDRO DE URABA
667	5	170	SAN RAFAEL
670	5	170	SAN ROQUE
674	5	170	SAN VICENTE
679	5	170	SANTA BARBARA
686	5	170	SANTA ROSA DE OSOS
690	5	170	SANTO DOMINGO
697	5	170	SANTUARIO
736	5	170	SEGOVIA
756	5	170	SONSON
761	5	170	SOPETRAN
789	5	170	TAMESIS
790	5	170	TARAZA
792	5	170	TARSO
809	5	170	TITIRIBI
819	5	170	TOLEDO
837	5	170	TURBO
842	5	170	URAMITA
847	5	170	URRAO
854	5	170	VALDIVIA
856	5	170	VALPARAISO
858	5	170	VEGACHI
861	5	170	VENECIA
873	5	170	VIGIA DEL FUERTE
885	5	170	YALI
887	5	170	YARUMAL
890	5	170	YOLOMBO
893	5	170	YONDO
895	5	170	ZARAGOZA
1	8	170	BARRANQUILLA
78	8	170	BARANOA
137	8	170	CAMPO DE LA CRUZ
141	8	170	CANDELARIA
296	8	170	GALAPA
372	8	170	JUAN DE ACOSTA
421	8	170	LURUACO
433	8	170	MALAMBO
436	8	170	MANATI
520	8	170	PALMAR DE VARELA
549	8	170	PIOJO
558	8	170	POLO NUEVO
560	8	170	PONEDERA
573	8	170	PUERTO COLOMBIA
606	8	170	REPELON
634	8	170	SABANAGRANDE
638	8	170	SABANALARGA
675	8	170	SANTA LUCIA
685	8	170	SANTO TOMAS
758	8	170	SOLEDAD
770	8	170	SUAN
832	8	170	TUBARA
849	8	170	USIACURI
1	11	170	SANTAFE DE BOGOTA D.C.-\nUSAQUEN
2	11	170	SANTAFE DE BOGOTA D.C.-\nCHAPINERO
3	11	170	SANTAFE DE BOGOTA D.C.-\nSANTA FE
4	11	170	SANTAFE DE BOGOTA D.C.-\nSAN CRISTOBAL
5	11	170	SANTAFE DE BOGOTA D.C.-\nUSME
6	11	170	SANTAFE DE BOGOTA D.C.-\nTUNJUELITO
7	11	170	SANTAFE DE BOGOTA D.C.-\nBOSA
8	11	170	SANTAFE DE BOGOTA D.C.-\nKENNEDY
9	11	170	SANTAFE DE BOGOTA D.C.-\nFONTIBON
10	11	170	SANTAFE DE BOGOTA D.C.-\nENGATIVA
11	11	170	SANTAFE DE BOGOTA D.C.-\nSUBA
12	11	170	SANTAFE DE BOGOTA D.C.-\nBARRIOS UNIDOS
13	11	170	SANTAFE DE BOGOTA D.C.-\nTEUSAQUILLO
14	11	170	SANTAFE DE BOGOTA D.C.-\nMARTIRES
15	11	170	SANTAFE DE BOGOTA D.C.-\nANTONIO NARIÑO
16	11	170	SANTAFE DE BOGOTA D.C.-\nPUENTE ARANDA
17	11	170	SANTAFE DE BOGOTA D.C.-\nCANDELARIA
18	11	170	SANTAFE DE BOGOTA D.C.-\nRAFAEL URIBE
19	11	170	SANTAFE DE BOGOTA D.C.-\nCIUDAD BOLIVAR
20	11	170	SANTAFE DE BOGOTA D.C.-\nSUMAPAZ
1	13	170	CARTAGENA (DISTRITO TURISTICO Y CULTURAL DE\nCARTAGENA)
6	13	170	ACHI
30	13	170	ALTOS DEL ROSARIO
42	13	170	ARENAL
52	13	170	ARJONA
62	13	170	ARROYOHONDO
74	13	170	BARRANCO DE LOBA
140	13	170	CALAMAR
160	13	170	CANTAGALLO
188	13	170	CICUCO
212	13	170	CORDOBA
222	13	170	CLEMENCIA
244	13	170	EL CARMEN DE BOLIVAR
248	13	170	EL GUAMO
268	13	170	EL PEÑON
300	13	170	HATILLO DE LOBA
430	13	170	MAGANGUE
433	13	170	MAHATES
440	13	170	MARGARITA
442	13	170	MARIA LA BAJA
458	13	170	MONTECRISTO
468	13	170	MOMPOS
473	13	170	MORALES
549	13	170	PINILLOS
580	13	170	REGIDOR
600	13	170	RIO VIEJO
620	13	170	SAN CRISTOBAL
647	13	170	SAN ESTANISLAO
650	13	170	SAN FERNANDO
654	13	170	SAN JACINTO
655	13	170	SAN JACINTO DEL CAUCA
657	13	170	SAN JUAN NEPOMUCENO
667	13	170	SAN MARTIN DE LOBA
670	13	170	SAN PABLO
673	13	170	SANTA CATALINA
683	13	170	SANTA ROSA
688	13	170	SANTA ROSA DEL SUR
744	13	170	SIMITI
760	13	170	SOPLAVIENTO
780	13	170	TALAIGUA NUEVO
810	13	170	TIQUISIO (PUERTO RICO)
836	13	170	TURBACO
838	13	170	TURBANA
873	13	170	VILLANUEVA
894	13	170	ZAMBRANO
1	15	170	TUNJA
22	15	170	ALMEIDA
47	15	170	AQUITANIA
51	15	170	ARCABUCO
87	15	170	BELEN
90	15	170	BERBEO
92	15	170	BETEITIVA
97	15	170	BOAVITA
104	15	170	BOYACA
106	15	170	BRICEÑO
109	15	170	BUENAVISTA
114	15	170	BUSBANZA
131	15	170	CALDAS
135	15	170	CAMPOHERMOSO
162	15	170	CERINZA
172	15	170	CHINAVITA
176	15	170	CHIQUINQUIRA
180	15	170	CHISCAS
183	15	170	CHITA
185	15	170	CHITARAQUE
187	15	170	CHIVATA
189	15	170	CIENEGA
204	15	170	COMBITA
212	15	170	COPER
215	15	170	CORRALES
218	15	170	COVARACHIA
223	15	170	CUBARA
224	15	170	CUCAITA
226	15	170	CUITIVA
232	15	170	CHIQUIZA
236	15	170	CHIVOR
238	15	170	DUITAMA
244	15	170	EL COCUY
248	15	170	EL ESPINO
272	15	170	FIRAVITOBA
276	15	170	FLORESTA
293	15	170	GACHANTIVA
296	15	170	GAMEZA
299	15	170	GARAGOA
317	15	170	GUACAMAYAS
322	15	170	GUATEQUE
325	15	170	GUAYATA
332	15	170	GUICAN
362	15	170	IZA
367	15	170	JENESANO
368	15	170	JERICO
377	15	170	LABRANZAGRANDE
380	15	170	LA CAPILLA
401	15	170	LA VICTORIA
403	15	170	LA UVITA
407	15	170	VILLA DE LEIVA
425	15	170	MACANAL
442	15	170	MARIPI
455	15	170	MIRAFLORES
464	15	170	MONGUA
466	15	170	MONGUI
469	15	170	MONIQUIRA
476	15	170	MOTAVITA
480	15	170	MUZO
491	15	170	NOBSA
494	15	170	NUEVO COLON
500	15	170	OICATA
507	15	170	OTANCHE
511	15	170	PACHAVITA
514	15	170	PAEZ
516	15	170	PAIPA
518	15	170	PAJARITO
522	15	170	PANQUEBA
531	15	170	PAUNA
533	15	170	PAYA
537	15	170	PAZ DEL RIO
542	15	170	PESCA
550	15	170	PISBA
572	15	170	PUERTO BOYACA
580	15	170	QUIPAMA
599	15	170	RAMIRIQUI
600	15	170	RAQUIRA
621	15	170	RONDON
632	15	170	SABOYA
638	15	170	SACHICA
646	15	170	SAMACA
660	15	170	SAN EDUARDO
664	15	170	SAN JOSE DE PARE
667	15	170	SAN LUIS DE GACENO
673	15	170	SAN MATEO
676	15	170	SAN MIGUEL DE SEMA
681	15	170	SAN PABLO DE BORBUR
686	15	170	SANTANA
690	15	170	SANTA MARIA
693	15	170	SANTA ROSA DE VITERBO
696	15	170	SANTA SOFIA
720	15	170	SATIVANORTE
723	15	170	SATIVASUR
740	15	170	SIACHOQUE
753	15	170	SOATA
755	15	170	SOCOTA
757	15	170	SOCHA
759	15	170	SOGAMOSO
761	15	170	SOMONDOCO
762	15	170	SORA
763	15	170	SOTAQUIRA
764	15	170	SORACA
774	15	170	SUSACON
776	15	170	SUTAMARCHAN
778	15	170	SUTATENZA
790	15	170	TASCO
798	15	170	TENZA
804	15	170	TIBANA
806	15	170	TIBASOSA
808	15	170	TINJACA
810	15	170	TIPACOQUE
814	15	170	TOCA
816	15	170	TOGUI
820	15	170	TOPAGA
822	15	170	TOTA
832	15	170	TUNUNGUA
835	15	170	TURMEQUE
837	15	170	TUTA
839	15	170	TUTASA
842	15	170	UMBITA
861	15	170	VENTAQUEMADA
879	15	170	VIRACACHA
897	15	170	ZETAQUIRA
1	17	170	MANIZALES
13	17	170	AGUADAS
42	17	170	ANSERMA
50	17	170	ARANZAZU
88	17	170	BELALCAZAR
174	17	170	CHINCHINA
272	17	170	FILADELFIA
380	17	170	LA DORADA
388	17	170	LA MERCED
433	17	170	MANZANARES
442	17	170	MARMATO
444	17	170	MARQUETALIA
446	17	170	MARULANDA
486	17	170	NEIRA
495	17	170	NORCASIA
513	17	170	PACORA
524	17	170	PALESTINA
541	17	170	PENSILVANIA
614	17	170	RIOSUCIO
616	17	170	RISARALDA
653	17	170	SALAMINA
662	17	170	SAMANA
665	17	170	SAN JOSE
777	17	170	SUPIA
867	17	170	VICTORIA
873	17	170	VILLAMARIA
877	17	170	VITERBO
1	18	170	FLORENCIA
29	18	170	ALBANIA
94	18	170	BELEN DE LOS ANDAQUIES
150	18	170	CARTAGENA DEL CHAIRA
205	18	170	CURILLO
247	18	170	EL DONCELLO
256	18	170	EL PAUJIL
410	18	170	LA MONTAÑITA
460	18	170	MILAN
479	18	170	MORELIA
592	18	170	PUERTO RICO
610	18	170	SAN JOSE DE FRAGUA
753	18	170	SAN  VICENTE DEL CAGUAN
756	18	170	SOLANO
785	18	170	SOLITA
860	18	170	VALPARAISO
1	19	170	POPAYAN
22	19	170	ALMAGUER
50	19	170	ARGELIA
75	19	170	BALBOA
100	19	170	BOLIVAR
110	19	170	BUENOS AIRES
130	19	170	CAJIBIO
137	19	170	CALDONO
142	19	170	CALOTO
212	19	170	CORINTO
256	19	170	EL TAMBO
290	19	170	FLORENCIA
318	19	170	GUAPI
355	19	170	INZA
364	19	170	JAMBALO
392	19	170	LA SIERRA
397	19	170	LA VEGA
418	19	170	LOPEZ (MICAY)
450	19	170	MERCADERES
455	19	170	MIRANDA
473	19	170	MORALES
513	19	170	PADILLA
517	19	170	PAEZ (BELALCAZAR)
532	19	170	PATIA (EL BORDO)
533	19	170	PIAMONTE
548	19	170	PIENDAMO
573	19	170	PUERTO TEJADA
585	19	170	PURACE (COCONUCO)
622	19	170	ROSAS
693	19	170	SAN SEBASTIAN
698	19	170	SANTANDER DE QUILICHAO
701	19	170	SANTA ROSA
743	19	170	SILVIA
760	19	170	SOTARA (PAISPAMBA)
780	19	170	SUAREZ
807	19	170	TIMBIO
809	19	170	TIMBIQUI
821	19	170	TORIBIO
824	19	170	TOTORO
845	19	170	VILLARICA
1	20	170	VALLEDUPAR
11	20	170	AGUACHICA
13	20	170	AGUSTIN CODAZZI
32	20	170	ASTREA
45	20	170	BECERRIL
60	20	170	BOSCONIA
175	20	170	CHIMICHAGUA
178	20	170	CHIRIGUANA
228	20	170	CURUMANI
238	20	170	EL COPEY
250	20	170	EL PASO
295	20	170	GAMARRA
310	20	170	GONZALEZ
383	20	170	LA GLORIA
400	20	170	LA JAGUA IBIRICO
443	20	170	MANAURE (BALCON DEL\nCESAR)
517	20	170	PAILITAS
550	20	170	PELAYA
570	20	170	PUEBLO BELLO
614	20	170	RIO DE ORO
621	20	170	LA PAZ (ROBLES)
710	20	170	SAN ALBERTO
750	20	170	SAN DIEGO
770	20	170	SAN MARTIN
787	20	170	TAMALAMEQUE
1	23	170	MONTERIA
68	23	170	AYAPEL
79	23	170	BUENAVISTA
90	23	170	CANALETE
162	23	170	CERETE
168	23	170	CHIMA
182	23	170	CHINU
189	23	170	CIENAGA DE ORO
300	23	170	COTORRA
350	23	170	LA APARTADA
417	23	170	LORICA
419	23	170	LOS CORDOBAS
464	23	170	MOMIL
466	23	170	MONTELIBANO
500	23	170	MOÑITOS
555	23	170	PLANETA RICA
570	23	170	PUEBLO NUEVO
574	23	170	PUERTO ESCONDIDO
580	23	170	PUERTO LIBERTADOR
586	23	170	PURISIMA
660	23	170	SAHAGUN
670	23	170	SAN ANDRES SOTAVENTO
672	23	170	SAN ANTERO
675	23	170	SAN BERNARDO DEL\nVIENTO
678	23	170	SAN CARLOS
686	23	170	SAN PELAYO
807	23	170	TIERRALTA
855	23	170	VALENCIA
1	25	170	AGUA DE DIOS
19	25	170	ALBAN
35	25	170	ANAPOIMA
40	25	170	ANOLAIMA
53	25	170	ARBELAEZ
86	25	170	BELTRAN
95	25	170	BITUIMA
99	25	170	BOJACA
120	25	170	CABRERA
123	25	170	CACHIPAY
126	25	170	CAJICA
148	25	170	CAPARRAPI
151	25	170	CAQUEZA
154	25	170	CARMEN DE CARUPA
168	25	170	CHAGUANI
175	25	170	CHIA
178	25	170	CHIPAQUE
181	25	170	CHOACHI
183	25	170	CHOCONTA
200	25	170	COGUA
214	25	170	COTA
224	25	170	CUCUNUBA
245	25	170	EL COLEGIO
258	25	170	EL PEÑON
260	25	170	EL ROSAL
269	25	170	FACATATIVA
279	25	170	FOMEQUE
281	25	170	FOSCA
286	25	170	FUNZA
288	25	170	FUQUENE
290	25	170	FUSAGASUGA
293	25	170	GACHALA
295	25	170	GACHANCIPA
297	25	170	GACHETA
299	25	170	GAMA
307	25	170	GIRARDOT
312	25	170	GRANADA
317	25	170	GUACHETA
320	25	170	GUADUAS
322	25	170	GUASCA
324	25	170	GUATAQUI
326	25	170	GUATAVITA
328	25	170	GUAYABAL DE SIQUIMA
335	25	170	GUAYABETAL
339	25	170	GUTIERREZ
368	25	170	JERUSALEN
372	25	170	JUNIN
377	25	170	LA CALERA
386	25	170	LA MESA
394	25	170	LA PALMA
398	25	170	LA PEÑA
402	25	170	LA VEGA
407	25	170	LENGUAZAQUE
426	25	170	MACHETA
430	25	170	MADRID
436	25	170	MANTA
438	25	170	MEDINA
473	25	170	MOSQUERA
483	25	170	NARIÑO
486	25	170	NEMOCON
488	25	170	NILO
489	25	170	NIMAIMA
491	25	170	NOCAIMA
506	25	170	VENECIA (OSPINA PEREZ)
513	25	170	PACHO
518	25	170	PAIME
524	25	170	PANDI
530	25	170	PARATEBUENO
535	25	170	PASCA
572	25	170	PUERTO SALGAR
580	25	170	PULI
592	25	170	QUEBRADANEGRA
594	25	170	QUETAME
596	25	170	QUIPILE
599	25	170	APULO (RAFAEL REYES)
612	25	170	RICAURTE
645	25	170	SAN  ANTONIO DEL\nTEQUENDAMA
649	25	170	SAN BERNARDO
653	25	170	SAN CAYETANO
658	25	170	SAN FRANCISCO
662	25	170	SAN JUAN DE RIOSECO
718	25	170	SASAIMA
736	25	170	SESQUILE
740	25	170	SIBATE
743	25	170	SILVANIA
745	25	170	SIMIJACA
754	25	170	SOACHA
758	25	170	SOPO
769	25	170	SUBACHOQUE
772	25	170	SUESCA
777	25	170	SUPATA
779	25	170	SUSA
781	25	170	SUTATAUSA
785	25	170	TABIO
793	25	170	TAUSA
797	25	170	TENA
799	25	170	TENJO
805	25	170	TIBACUY
807	25	170	TIBIRITA
815	25	170	TOCAIMA
817	25	170	TOCANCIPA
823	25	170	TOPAIPI
839	25	170	UBALA
841	25	170	UBAQUE
843	25	170	UBATE
845	25	170	UNE
851	25	170	UTICA
862	25	170	VERGARA
867	25	170	VIANI
871	25	170	VILLAGOMEZ
873	25	170	VILLAPINZON
875	25	170	VILLETA
878	25	170	VIOTA
885	25	170	YACOPI
898	25	170	ZIPACON
899	25	170	ZIPAQUIRA
1	27	170	QUIBDO (SAN FRANCISCO\nDE QUIBDO)
6	27	170	ACANDI
25	27	170	ALTO BAUDO (PIE DE PATO)
50	27	170	ATRATO
73	27	170	BAGADO
75	27	170	BAHIA SOLANO (MUTIS)
77	27	170	BAJO BAUDO (PIZARRO)
99	27	170	BOJAYA (BELLAVISTA)
135	27	170	CANTON DE SAN PABLO\n(MANAGRU)
205	27	170	CONDOTO
245	27	170	EL CARMEN DE ATRATO
250	27	170	LITORAL DEL BAJO SAN JUAN (SANTA GENOVEVA DE\nDOCORDO)
361	27	170	ISTMINA
372	27	170	JURADO
413	27	170	LLORO
425	27	170	MEDIO ATRATO
430	27	170	MEDIO BAUDO
491	27	170	NOVITA
495	27	170	NUQUI
600	27	170	RIOQUITO
615	27	170	RIOSUCIO
660	27	170	SAN JOSE DEL PALMAR
745	27	170	SIPI
787	27	170	TADO
800	27	170	UNGUIA
810	27	170	UNION PANAMERICANA
1	41	170	NEIVA
6	41	170	ACEVEDO
13	41	170	AGRADO
16	41	170	AIPE
20	41	170	ALGECIRAS
26	41	170	ALTAMIRA
78	41	170	BARAYA
132	41	170	CAMPOALEGRE
206	41	170	COLOMBIA
244	41	170	ELIAS
298	41	170	GARZON
306	41	170	GIGANTE
319	41	170	GUADALUPE
349	41	170	HOBO
357	41	170	IQUIRA
359	41	170	ISNOS (SAN JOSE DE ISNOS)
378	41	170	LA ARGENTINA
396	41	170	LA PLATA
483	41	170	NATAGA
503	41	170	OPORAPA
518	41	170	PAICOL
524	41	170	PALERMO
530	41	170	PALESTINA
548	41	170	PITAL
551	41	170	PITALITO
615	41	170	RIVERA
660	41	170	SALADOBLANCO
668	41	170	SAN AGUSTIN
676	41	170	SANTA MARIA
770	41	170	SUAZA
791	41	170	TARQUI
797	41	170	TESALIA
799	41	170	TELLO
801	41	170	TERUEL
807	41	170	TIMANA
872	41	170	VILLAVIEJA
885	41	170	YAGUARA
1	44	170	RIOHACHA
78	44	170	BARRANCAS
90	44	170	DIBULLA
98	44	170	DISTRACCION
110	44	170	EL MOLINO
279	44	170	FONSECA
378	44	170	HATONUEVO
420	44	170	LA JAGUA DEL PILAR
430	44	170	MAICAO
560	44	170	MANAURE
650	44	170	SAN JUAN DEL CESAR
847	44	170	URIBIA
855	44	170	URUMITA
874	44	170	VILLANUEVA
1	47	170	SANTA MARTA
30	47	170	ALGARROBO
53	47	170	ARACATACA
58	47	170	ARIGUANI (EL DIFICIL)
161	47	170	CERRO SAN ANTONIO
170	47	170	CHIVOLO
189	47	170	CIENAGA
205	47	170	CONCORDIA
245	47	170	EL BANCO
258	47	170	EL PIÑON
268	47	170	EL RETEN
288	47	170	FUNDACION
318	47	170	GUAMAL
541	47	170	PEDRAZA
545	47	170	PIJIÑO DEL CARMEN\n(PIJIÑO)
551	47	170	PIVIJAY
555	47	170	PLATO
570	47	170	PUEBLOVIEJO
605	47	170	REMOLINO
660	47	170	SABANAS DE SAN ANGEL
675	47	170	SALAMINA
692	47	170	SAN SEBASTIAN DE\nBUENAVISTA
703	47	170	SAN ZENON
707	47	170	SANTA ANA
745	47	170	SITIONUEVO
798	47	170	TENERIFE
1	50	170	VILLAVICENCIO
6	50	170	ACACIAS
110	50	170	BARRANCA DE UPIA
124	50	170	CABUYARO
150	50	170	CASTILLA LA NUEVA
223	50	170	SAN LUIS DE CUBARRAL
226	50	170	CUMARAL
245	50	170	EL CALVARIO
251	50	170	EL CASTILLO
270	50	170	EL DORADO
287	50	170	FUENTE DE ORO
313	50	170	GRANADA
318	50	170	GUAMAL
325	50	170	MAPIRIPAN
330	50	170	MESETAS
350	50	170	LA MACARENA
370	50	170	LA URIBE
400	50	170	LEJANIAS
450	50	170	PUERTO CONCORDIA
568	50	170	PUERTO GAITAN
573	50	170	PUERTO LOPEZ
577	50	170	PUERTO LLERAS
590	50	170	PUERTO RICO
606	50	170	RESTREPO
680	50	170	SAN CARLOS DE GUAROA
683	50	170	SAN  JUAN DE ARAMA
686	50	170	SAN JUANITO
689	50	170	SAN MARTIN
711	50	170	VISTAHERMOSA
1	52	170	PASTO (SAN JUAN DE\nPASTO)
19	52	170	ALBAN (SAN JOSE)
22	52	170	ALDANA
36	52	170	ANCUYA
51	52	170	ARBOLEDA (BERRUECOS)
79	52	170	BARBACOAS
83	52	170	BELEN
110	52	170	BUESACO
203	52	170	COLON (GENOVA)
207	52	170	CONSACA
210	52	170	CONTADERO
215	52	170	CORDOBA
224	52	170	CUASPUD (CARLOSAMA)
227	52	170	CUMBAL
233	52	170	CUMBITARA
240	52	170	CHACHAGUI
250	52	170	EL CHARCO
254	52	170	EL PEÑOL
256	52	170	EL ROSARIO
258	52	170	EL TABLON
260	52	170	EL TAMBO
287	52	170	FUNES
317	52	170	GUACHUCAL
320	52	170	GUAITARILLA
323	52	170	GUALMATAN
352	52	170	ILES
354	52	170	IMUES
356	52	170	IPIALES
378	52	170	LA CRUZ
381	52	170	LA FLORIDA
385	52	170	LA LLANADA
390	52	170	LA TOLA
399	52	170	LA UNION
405	52	170	LEIVA
411	52	170	LINARES
418	52	170	LOS ANDES (SOTOMAYOR)
427	52	170	MAGUI (PAYAN)
435	52	170	MALLAMA (PIEDRANCHA)
473	52	170	MOSQUERA
490	52	170	OLAYA HERRERA (BOCAS\nDE SATINGA)
506	52	170	OSPINA
520	52	170	FRANCISCO PIZARRO\n(SALAHONDA)
540	52	170	POLICARPA
560	52	170	POTOSI
565	52	170	PROVIDENCIA
573	52	170	PUERRES
585	52	170	PUPIALES
612	52	170	RICAURTE
621	52	170	ROBERTO PAYAN (SAN\nJOSE)
678	52	170	SAMANIEGO
683	52	170	SANDONA
685	52	170	SAN BERNARDO
687	52	170	SAN LORENZO
693	52	170	SAN PABLO
694	52	170	SAN PEDRO DE CARTAGO
696	52	170	SANTA BARBARA\n(ISCUANDE)
699	52	170	SANTA CRUZ (GUACHAVES)
720	52	170	SAPUYES
786	52	170	TAMINANGO
788	52	170	TANGUA
835	52	170	TUMACO
838	52	170	TUQUERRES
885	52	170	YACUANQUER
1	54	170	CUCUTA
3	54	170	ABREGO
51	54	170	ARBOLEDAS
99	54	170	BOCHALEMA
109	54	170	BUCARASICA
125	54	170	CACOTA
128	54	170	CACHIRA
172	54	170	CHINACOTA
174	54	170	CHITAGA
206	54	170	CONVENCION
223	54	170	CUCUTILLA
239	54	170	DURANIA
245	54	170	EL CARMEN
250	54	170	EL TARRA
261	54	170	EL ZULIA
313	54	170	GRAMALOTE
344	54	170	HACARI
347	54	170	HERRAN
377	54	170	LABATECA
385	54	170	LA ESPERANZA
398	54	170	LA PLAYA
405	54	170	LOS PATIOS
418	54	170	LOURDES
480	54	170	MUTISCUA
498	54	170	OCAÑA
518	54	170	PAMPLONA
520	54	170	PAMPLONITA
553	54	170	PUERTO SANTANDER
599	54	170	RAGONVALIA
660	54	170	SALAZAR
670	54	170	SAN CALIXTO
673	54	170	SAN CAYETANO
680	54	170	SANTIAGO
720	54	170	SARDINATA
743	54	170	SILOS
800	54	170	TEORAMA
810	54	170	TIBU
820	54	170	TOLEDO
871	54	170	VILLACARO
874	54	170	VILLA DEL ROSARIO
1	63	170	ARMENIA
111	63	170	BUENAVISTA
130	63	170	CALARCA
190	63	170	CIRCASIA
212	63	170	CORDOBA
272	63	170	FILANDIA
302	63	170	GENOVA
401	63	170	LA TEBAIDA
470	63	170	MONTENEGRO
548	63	170	PIJAO
594	63	170	QUIMBAYA
690	63	170	SALENTO
1	66	170	PEREIRA
45	66	170	APIA
75	66	170	BALBOA
88	66	170	BELEN DE UMBRIA
170	66	170	DOS QUEBRADAS
318	66	170	GUATICA
383	66	170	LA CELIA
400	66	170	LA VIRGINIA
440	66	170	MARSELLA
456	66	170	MISTRATO
572	66	170	PUEBLO RICO
594	66	170	QUINCHIA
682	66	170	SANTA ROSA DE CABAL
687	66	170	SANTUARIO
1	68	170	BUCARAMANGA
13	68	170	AGUADA
20	68	170	ALBANIA
51	68	170	ARATOCA
77	68	170	BARBOSA
79	68	170	BARICHARA
81	68	170	BARRANCABERMEJA
92	68	170	BETULIA
101	68	170	BOLIVAR
121	68	170	CABRERA
132	68	170	CALIFORNIA
147	68	170	CAPITANEJO
152	68	170	CARCASI
160	68	170	CEPITA
162	68	170	CERRITO
167	68	170	CHARALA
169	68	170	CHARTA
176	68	170	CHIMA
179	68	170	CHIPATA
190	68	170	CIMITARRA
207	68	170	CONCEPCION
209	68	170	CONFINES
211	68	170	CONTRATACION
217	68	170	COROMORO
229	68	170	CURITI
235	68	170	EL CARMEN DE CHUCURY
245	68	170	EL GUACAMAYO
250	68	170	EL PEÑON
255	68	170	EL PLAYON
264	68	170	ENCINO
266	68	170	ENCISO
271	68	170	FLORIAN
276	68	170	FLORIDABLANCA
296	68	170	GALAN
298	68	170	GAMBITA
307	68	170	GIRON
318	68	170	GUACA
320	68	170	GUADALUPE
322	68	170	GUAPOTA
324	68	170	GUAVATA
327	68	170	GUEPSA
344	68	170	HATO
368	68	170	JESUS MARIA
370	68	170	JORDAN
377	68	170	LA BELLEZA
385	68	170	LANDAZURI
397	68	170	LA PAZ
406	68	170	LEBRIJA
418	68	170	LOS SANTOS
425	68	170	MACARAVITA
432	68	170	MALAGA
444	68	170	MATANZA
464	68	170	MOGOTES
468	68	170	MOLAGAVITA
498	68	170	OCAMONTE
500	68	170	OIBA
502	68	170	ONZAGA
522	68	170	PALMAR
524	68	170	PALMAS DEL SOCORRO
533	68	170	PARAMO
547	68	170	PIEDECUESTA
549	68	170	PINCHOTE
572	68	170	PUENTE NACIONAL
573	68	170	PUERTO PARRA
575	68	170	PUERTO WILCHES
615	68	170	RIONEGRO
655	68	170	SABANA DE TORRES
669	68	170	SAN ANDRES
673	68	170	SAN BENITO
679	68	170	SAN GIL
682	68	170	SAN JOAQUIN
684	68	170	SAN JOSE DE MIRANDA
686	68	170	SAN MIGUEL
689	68	170	SAN VICENTE DE CHUCURI
705	68	170	SANTA BARBARA
720	68	170	SANTA HELENA DEL OPON
745	68	170	SIMACOTA
755	68	170	SOCORRO
770	68	170	SUAITA
773	68	170	SUCRE
780	68	170	SURATA
820	68	170	TONA
855	68	170	VALLE SAN JOSE
861	68	170	VELEZ
867	68	170	VETAS
872	68	170	VILLANUEVA
895	68	170	ZAPATOCA
1	70	170	SINCELEJO
110	70	170	BUENAVISTA
124	70	170	CAIMITO
204	70	170	COLOSO (RICAURTE)
215	70	170	COROZAL
230	70	170	CHALAN
235	70	170	GALERAS (NUEVA\nGRANADA)
265	70	170	GUARANDA
400	70	170	LA UNION
418	70	170	LOS PALMITOS
429	70	170	MAJAGUAL
473	70	170	MORROA
508	70	170	OVEJAS
523	70	170	PALMITO
670	70	170	SAMPUES
678	70	170	SAN BENITO ABAD
702	70	170	SAN JUAN DE BETULIA
708	70	170	SAN MARCOS
713	70	170	SAN ONOFRE
717	70	170	SAN PEDRO
742	70	170	SINCE
771	70	170	SUCRE
820	70	170	TOLU
823	70	170	TOLUVIEJO
1	73	170	IBAGUE
24	73	170	ALPUJARRA
26	73	170	ALVARADO
30	73	170	AMBALEMA
43	73	170	ANZOATEGUI
55	73	170	ARMERO (GUAYABAL)
67	73	170	ATACO
124	73	170	CAJAMARCA
148	73	170	CARMEN APICALA
152	73	170	CASABIANCA
168	73	170	CHAPARRAL
200	73	170	COELLO
217	73	170	COYAIMA
226	73	170	CUNDAY
236	73	170	DOLORES
268	73	170	ESPINAL
270	73	170	FALAN
275	73	170	FLANDES
283	73	170	FRESNO
319	73	170	GUAMO
347	73	170	HERVEO
349	73	170	HONDA
352	73	170	ICONONZO
408	73	170	LERIDA
411	73	170	LIBANO
443	73	170	MARIQUITA
449	73	170	MELGAR
461	73	170	MURILLO
483	73	170	NATAGAIMA
504	73	170	ORTEGA
520	73	170	PALOCABILDO
547	73	170	PIEDRAS
555	73	170	PLANADAS
563	73	170	PRADO
585	73	170	PURIFICACION
616	73	170	RIOBLANCO
622	73	170	RONCESVALLES
624	73	170	ROVIRA
671	73	170	SALDAÑA
675	73	170	SAN ANTONIO
678	73	170	SAN LUIS
686	73	170	SANTA ISABEL
770	73	170	SUAREZ
854	73	170	VALLE DE SAN JUAN
861	73	170	VENADILLO
870	73	170	VILLAHERMOSA
873	73	170	VILLARRICA
1	76	170	CALI (SANTIAGO DE CALI)
20	76	170	ALCALA
36	76	170	ANDALUCIA
41	76	170	ANSERMANUEVO
54	76	170	ARGELIA
100	76	170	BOLIVAR
109	76	170	BUENAVENTURA
111	76	170	BUGA
113	76	170	BUGALAGRANDE
122	76	170	CAICEDONIA
126	76	170	CALIMA (DARIEN)
130	76	170	CANDELARIA
147	76	170	CARTAGO
233	76	170	DAGUA
243	76	170	EL AGUILA
246	76	170	EL CAIRO
248	76	170	EL CERRITO
250	76	170	EL DOVIO
275	76	170	FLORIDA
306	76	170	GINEBRA
318	76	170	GUACARI
364	76	170	JAMUNDI
377	76	170	LA CUMBRE
400	76	170	LA UNION
403	76	170	LA VICTORIA
497	76	170	OBANDO
520	76	170	PALMIRA
563	76	170	PRADERA
606	76	170	RESTREPO
616	76	170	RIOFRIO
622	76	170	ROLDANILLO
670	76	170	SAN PEDRO
736	76	170	SEVILLA
823	76	170	TORO
828	76	170	TRUJILLO
834	76	170	TULUA
845	76	170	ULLOA
863	76	170	VERSALLES
869	76	170	VIJES
890	76	170	YOTOCO
892	76	170	YUMBO
895	76	170	ZARZAL
1	81	170	ARAUCA
65	81	170	ARAUQUITA
220	81	170	CRAVO NORTE
300	81	170	FORTUL
591	81	170	PUERTO RONDON
736	81	170	SARAVENA
794	81	170	TAME
1	85	170	YOPAL
10	85	170	AGUAZUL
15	85	170	CHAMEZA
125	85	170	HATO COROZAL
136	85	170	LA SALINA
139	85	170	MANI
162	85	170	MONTERREY
225	85	170	NUNCHIA
230	85	170	OROCUE
250	85	170	PAZ DE ARIPORO
263	85	170	PORE
279	85	170	RECETOR
300	85	170	SABANALARGA
315	85	170	SACAMA
325	85	170	SAN LUIS DE PALENQUE
400	85	170	TAMARA
410	85	170	TAURAMENA
430	85	170	TRINIDAD
440	85	170	VILLANUEVA
1	86	170	MOCOA
219	86	170	COLON
320	86	170	ORITO
568	86	170	PUERTO ASIS
569	86	170	PUERTO CAICEDO
571	86	170	PUERTO GUZMAN
573	86	170	PUERTO LEGUIZAMO
749	86	170	SIBUNDOY
755	86	170	SAN FRANCISCO
757	86	170	SAN MIGUEL (LA DORADA)
760	86	170	SANTIAGO
865	86	170	LA HORMIGA (VALLE DEL\nGUAMUEZ)
885	86	170	VILLAGARZON
1	88	170	SAN ANDRES
564	88	170	PROVIDENCIA
1	91	170	LETICIA
263	91	170	EL ENCANTO
405	91	170	LA CHORRERA
407	91	170	LA PEDRERA
430	91	170	LA VICTORIA
460	91	170	MIRITI-PARANA
530	91	170	PUERTO ALEGRIA
536	91	170	PUERTO ARICA
540	91	170	PUERTO NARIÑO
669	91	170	PUERTO SANTANDER
798	91	170	TARAPACA
1	94	170	PUERTO INIRIDA
343	94	170	BARRANCO MINAS
883	94	170	SAN FELIPE
884	94	170	PUERTO COLOMBIA
885	94	170	LA GUADALUPE
886	94	170	CACAHUAL
887	94	170	PANA PANA (CAMPO\nALEGRE)
888	94	170	MORICHAL (MORICHAL\nNUEVO)
1	95	170	SAN JOSE DEL GUAVIARE
15	95	170	CALAMAR
25	95	170	EL RETORNO
200	95	170	MIRAFLORES
1	97	170	MITU
161	97	170	CARURU
511	97	170	PACOA
666	97	170	TARAIRA
777	97	170	PAPUNAUA (MORICHAL)
889	97	170	YAVARATE
1	99	170	PUERTO CARREÑO
524	99	170	LA PRIMAVERA
572	99	170	SANTA RITA
666	99	170	SANTA ROSALIA
760	99	170	SAN JOSE DE OCUNE
773	99	170	CUMARIBO
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       4948.dat                                                                                            0000600 0004000 0002000 00000005275 15015342721 0014273 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        ﻿4	AFGANISTAN
248	ALAND ISLANDS
8	ALBANIA
276	ALEMANIA
20	ANDORRA
24	ANGOLA
660	ANGUILA
10	ANTARTIDA
28	ANTIGUA Y BARBUDA
530	ANTILLAS NEERLANDESAS
682	ARABIA SAUDITA
12	ARGELIA
32	ARGENTINA
51	ARMENIA
533	ARUBA
36	AUSTRALIA
40	AUSTRIA
31	AZERBAIYAN
44	BAHAMAS
48	BAHREIN
50	BANGLADESH
52	BARBADOS
112	BELARUS
56	BELGICA
58	BELGICA-LUXEMBURGO
84	BELICE
204	BENIN
60	BERMUDAS
64	BHUTAN
68	BOLIVIA
535	BONAIRE
70	BOSNIA Y HERZEGOVINA
72	BOTSWANA
76	BRASIL
96	BRUNEI DARUSSALAM
100	BULGARIA
854	BURKINA FASO
108	BURUNDI
132	CABO VERDE
116	CAMBOYA
120	CAMERUN
124	CANADA
839	CATEGORIAS ESPECIALES
148	CHAD
200	CHECOSLOVAQUIA
152	CHILE
156	CHINA
196	CHIPRE
170	COLOMBIA
849	COMANDO I DEL PACIFICO DE ESTADOS UNIDOS
174	COMORAS
178	CONGO, REP. DEL
180	CONGO, REP. DEM. DEL
410	COREA, REP. DE
408	COREA, REP. DEM. DE
188	COSTA RICA
384	COTE D'IVOIRE
191	CROACIA
192	CUBA
531	CURACAO
208	DINAMARCA
262	DJIBOUTI
212	DOMINICA
218	ECUADOR
818	EGIPTO, REP. ARABE DE
222	EL SALVADOR
784	EMIRATOS ARABES UNIDOS
232	ERITREA
705	ESLOVENIA
724	ESPANA
840	ESTADOS UNIDOS
233	ESTONIA
231	ETIOPIA (EXCLUIDA ERITREA)
230	ETIOPIA (INCLUIDA ERITREA)
918	EUROPEAN UNION
736	EX SUDAN
643	FEDERACION DE RUSIA
242	FIJI
608	FILIPINAS
246	FINLANDIA
592	FM PANAMA CZ
717	FM RHOD NYAS
835	FM TANGANYIK
866	FM VIETNAM DR
868	FM VIETNAM RP
836	FM ZANZ-PEMB
250	FRANCIA
266	GABON
270	GAMBIA
274	GAZA STRIP
268	GEORGIA
288	GHANA
292	GIBRALTAR
308	GRANADA
300	GRECIA
304	GROENLANDIA
312	GUADALUPE
316	GUAM
320	GUATEMALA
254	GUAYANA FRANCESA
324	GUINEA
226	GUINEA ECUATORIAL
624	GUINEA-BISSAU
328	GUYANA
332	HAITI
340	HONDURAS
344	HONG KONG (CHINA)
348	HUNGRIA
356	INDIA
360	INDONESIA
364	IRAN, REP. ISLAMICA DEL
368	IRAQ
372	IRLANDA
74	ISLA BOUVET
837	ISLA BUNKER
162	ISLA DE NAVIDAD
574	ISLA NORFOLK
352	ISLANDIA
136	ISLAS CAIMAN
166	ISLAS COCOS (KEELING)
184	ISLAS COOK
582	ISLAS DEL PACIFICO
238	ISLAS FALKLAND
234	ISLAS FEROE
239	ISLAS GEORGIAS DEL SUR Y SANDWICH DEL SUR
334	ISLAS HEARD Y MCDONALD
584	ISLAS MARSHALL
90	ISLAS SALOMON
796	ISLAS TURCAS Y CAICOS
581	ISLAS ULTRAMARINAS MENORES DE ESTADOS UNIDOS
850	ISLAS VIRGENES (EE.UU.)
92	ISLAS VIRGENES BRITANICAS
876	ISLAS WALLIS Y FUTUNA
376	ISRAEL
380	ITALIA
388	JAMAICA
392	JAPON
396	JHONSTON ISLAND
400	JORDANIA
398	KAZAJSTAN
404	KENYA
417	KIRGUISTAN
296	KIRIBATI
412	KOSOVO
414	KUWAIT
426	LESOTHO
428	LETONIA
422	LIBANO
430	LIBERIA
434	LIBIA
438	LIECHTENSTEIN
440	LITUANIA
442	LUXEMBURGO
446	MACAO
807	MACEDONIA, EX REP. YUGOSLAVA DE
450	MADAGASCAR
458	MALASIA
454	MALAWI
462	MALDIVAS
466	MALI
470	MALTA
580	MARIANA
504	MARRUECOS
474	MARTINICA
480	MAURICIO
478	MAURITANIA
175	MAYOTTE
484	MEXICO
583	MICRONESIA, ESTADOS FED. DE
488	MIDWAY ISLANDS
492	MONACO
496	MONGOLIA
499	MONTENEGRO
500	MONTSERRAT
508	MOZAMBIQUE
\.


                                                                                                                                                                                                                                                                                                                                   4957.dat                                                                                            0000600 0004000 0002000 00000364161 15015342721 0014275 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1332432138	CC	Lidia	Custodio	Chacón	Poza	1965-08-16	F	3148806007	lidia.chacón391@email.com	P471	147	5	170	440	5	170
1136479329	CC	Cecilio	Clímaco	Giner	Caballero	1955-10-29	F	3034650794	cecilio.giner70@email.com	P472	148	5	170	467	5	170
1363048727	CC	Eleuterio	Cristian	Solís	Marquez	1981-04-25	F	3075320352	eleuterio.solís100@email.com	P473	150	5	170	475	5	170
1479660620	CC	Tania	Damián	Pont	Mur	2006-09-15	F	3292813562	tania.pont602@email.com	P474	154	5	170	480	5	170
1622431648	CC	Blas	Reyna	Acevedo	Redondo	1990-09-21	M	3075947715	blas.acevedo29@email.com	P475	172	5	170	483	5	170
1661547300	CC	Kike	Narcisa	Ureña	Romeu	1959-05-30	M	3036822604	kike.ureña237@email.com	P476	190	5	170	490	5	170
1056092391	CC	Celia	Reinaldo	Ramón	Alberola	1987-10-15	M	3144465811	celia.ramón649@email.com	P477	197	5	170	495	5	170
1401960054	CC	Reina	Belén	Villalonga	Ródenas	1964-12-05	F	3031806261	reina.villalonga315@email.com	P478	206	5	170	501	5	170
1053730012	CC	Cirino	Emiliana	Campo	Molins	1986-01-07	M	3162640729	cirino.campo498@email.com	P479	209	5	170	541	5	170
1890423139	CC	Trini	Lara	Ugarte	Galvez	1975-07-13	F	3242022241	trini.ugarte429@email.com	P480	212	5	170	543	5	170
1398864788	CC	César	Glauco	Vicens	Torralba	1988-11-08	M	3137726650	césar.vicens300@email.com	P481	234	5	170	576	5	170
1744721821	CC	Ildefonso	Hilario	Gomila	Perelló	1982-10-24	M	3124153083	ildefonso.gomila911@email.com	P482	237	5	170	579	5	170
1055521136	CC	Alfredo	Luna	Cepeda	Ropero	1962-01-08	F	3191933606	alfredo.cepeda831@email.com	P483	240	5	170	585	5	170
1955909915	CC	Mario	Martina	Pedro	Ávila	2006-08-23	M	3154907196	mario.pedro991@email.com	P484	250	5	170	591	5	170
1551224529	CC	Matilde	Julia	Múgica	Vicens	2001-02-15	M	3121329777	matilde.múgica193@email.com	P485	264	5	170	604	5	170
1392178722	CC	Perla	Cleto	Perales	Mateu	1994-10-19	M	3137393769	perla.perales589@email.com	P486	266	5	170	607	5	170
1647780569	CC	Brunilda	Calista	Solé	Beltrán	1990-07-13	F	3293040558	brunilda.solé423@email.com	P487	282	5	170	615	5	170
1340122823	CC	Brunilda	Tiburcio	Canet	Olmo	2002-01-10	M	3146638790	brunilda.canet245@email.com	P488	284	5	170	628	5	170
1090046754	CC	Rufino	Elpidio	Pintor	Arnau	1979-06-23	F	3198868800	rufino.pintor923@email.com	P489	306	5	170	631	5	170
1521229113	CC	Palmira	Miguela	Elías	Crespo	1970-04-11	F	3262699456	palmira.elías232@email.com	P490	308	5	170	642	5	170
1284756585	CC	Cruz	Leticia	Alemany	Fuente	1995-02-05	M	3088657561	cruz.alemany30@email.com	P491	310	5	170	647	5	170
1449607529	CC	Pepito	Tristán	Maza	Lloret	1970-08-21	M	3112243785	pepito.maza898@email.com	P492	313	5	170	649	5	170
1044589718	CC	María Fernanda	Melisa	Ramón	Martín	1977-06-03	M	3073140699	maría fernanda.ramón801@email.com	P493	315	5	170	652	5	170
1956831501	CC	Jesús	Viviana	Nogueira	Raya	1965-11-03	M	3050754022	jesús.nogueira2@email.com	P494	318	5	170	656	5	170
1707872849	CC	Camila	Agustín	Escalona	Fuente	1991-11-18	M	3022450846	camila.escalona28@email.com	P001	321	5	170	658	5	170
1446268163	CC	Donato	Gil	Abascal	Bravo	1963-01-10	F	3074514473	donato.abascal656@email.com	P001	347	5	170	659	5	170
1637596489	CC	Estrella	Elisabet	Peinado	Feijoo	1990-11-20	M	3183301650	estrella.peinado999@email.com	P001	353	5	170	660	5	170
1367696966	CC	Damián	Rosendo	Diez	Gual	2004-06-17	F	3090764552	damián.diez899@email.com	P001	360	5	170	664	5	170
1992433815	CC	Leandro	José María	Borja	Gallardo	1969-12-26	F	3133740407	leandro.borja817@email.com	P001	361	5	170	665	5	170
1718784953	CC	Abraham	Lidia	Saez	Múgica	1992-09-21	M	3097710910	abraham.saez42@email.com	P001	364	5	170	667	5	170
1474530598	CC	Elodia	Manolo	Olivares	Carmona	2007-03-10	F	3056747667	elodia.olivares237@email.com	P001	368	5	170	670	5	170
1244216697	CC	Eva	Albina	Rivas	Company	1962-01-20	M	3044914385	eva.rivas443@email.com	P001	376	5	170	674	5	170
1990963792	CC	Clotilde	Ramiro	Asensio	Muñoz	1996-03-20	F	3228283070	clotilde.asensio183@email.com	P495	380	5	170	679	5	170
1303891619	CC	Tomasa	Leocadia	Hernando	Burgos	2002-11-26	M	3128191618	tomasa.hernando407@email.com	P496	390	5	170	686	5	170
1145811702	CC	Marciano	Evaristo	Peralta	Marcos	1966-04-18	M	3290198858	marciano.peralta642@email.com	P497	400	5	170	690	5	170
1589215438	CC	Marta	Gastón	Jordá	Rodríguez	1981-11-09	F	3098266975	marta.jordá470@email.com	P498	411	5	170	697	5	170
1766090897	CC	Isabel	Rufina	Corral	Chamorro	2002-09-30	M	3151527744	isabel.corral54@email.com	P499	425	5	170	736	5	170
1356217036	CC	Valentina	Juanito	Vilar	Mesa	1992-03-21	F	3267436021	valentina.vilar12@email.com	P500	440	5	170	756	5	170
1723216646	CC	Eligia	Lucio	Gilabert	Alsina	1970-07-26	M	3095030692	eligia.gilabert611@email.com	P495	467	5	170	761	5	170
1193981668	CC	Jafet	Sofía	Manrique	Portero	1987-03-10	M	3285720167	jafet.manrique351@email.com	P496	475	5	170	789	5	170
1273882891	CC	Delfina	Judith	Casanovas	Uría	1973-11-06	F	3236331270	delfina.casanovas22@email.com	P497	480	5	170	790	5	170
1819666751	CC	Víctor	Roberta	Rocha	Matas	1965-03-21	F	3242429596	víctor.rocha576@email.com	P140	483	5	170	792	5	170
1824433229	CC	Emilio	Roxana	Terrón	Farré	1995-11-18	F	3194344022	emilio.terrón510@email.com	P141	490	5	170	809	5	170
1821775167	CC	Calisto	Adrián	Zabala	Lledó	1994-06-18	M	3265720944	calisto.zabala606@email.com	P142	495	5	170	819	5	170
1577956424	CC	Rebeca	Prudencio	Monreal	Dominguez	1999-04-18	F	3220787524	rebeca.monreal260@email.com	P143	501	5	170	837	5	170
1523234262	CC	María Ángeles	Iván	Llabrés	Castell	1960-10-26	M	3243160046	maría ángeles.llabrés296@email.com	P144	541	5	170	842	5	170
1485849759	CC	Rico	Patricia	Valdés	Revilla	1990-02-27	M	3265364556	rico.valdés946@email.com	P145	543	5	170	847	5	170
1190299525	CC	Petrona	Xavier	Expósito	Vallejo	2002-11-24	M	3146120368	petrona.expósito281@email.com	P146	576	5	170	854	5	170
1854987696	CC	Saturnina	Gisela	Marí	Gaya	2007-05-04	F	3263881408	saturnina.marí398@email.com	P147	579	5	170	856	5	170
1378631717	CC	Jennifer	Victor Manuel	Salas	Lozano	1978-04-10	M	3246885542	jennifer.salas383@email.com	P148	585	5	170	858	5	170
1554795422	CC	Nazaret	Melisa	Casanovas	Heras	2007-02-24	M	3080408803	nazaret.casanovas167@email.com	P149	591	5	170	861	5	170
1302974143	CC	Saturnino	Adora	Rincón	Acuña	1957-09-27	M	3150741930	saturnino.rincón470@email.com	P150	604	5	170	873	5	170
1163762368	CC	Socorro	Montserrat	Vargas	Valcárcel	1978-07-27	M	3096487561	socorro.vargas718@email.com	P151	607	5	170	885	5	170
1397614665	CC	Olga	Víctor	Huerta	Pozuelo	1981-07-05	F	3022180946	olga.huerta197@email.com	P152	615	5	170	887	5	170
1127465334	CC	Martín	Silvestre	González	Gutierrez	1968-08-21	F	3215524219	martín.gonzález150@email.com	P153	628	5	170	890	5	170
1346281475	CC	Clímaco	Maricruz	Palomares	Camps	1968-09-07	M	3239404296	clímaco.palomares892@email.com	P154	631	5	170	893	5	170
1837899866	CC	Lucas	Patricio	Cañas	Alegre	1955-08-18	M	3013711268	lucas.cañas228@email.com	P155	642	5	170	895	5	170
1054098297	CC	Joel	Eloísa	Gonzalo	Quiroga	1962-03-30	F	3143324977	joel.gonzalo59@email.com	P156	647	5	170	1	8	170
1318966854	CC	Maura	Eliana	Gárate	Rocamora	1980-01-01	F	3218895788	maura.gárate992@email.com	P157	649	5	170	78	8	170
1233256844	CC	Filomena	Macarena	Catalá	Arana	1977-09-23	M	3251089810	filomena.catalá326@email.com	P158	652	5	170	137	8	170
1725139428	CC	Eustaquio	Felipe	Otero	Elías	1967-06-09	M	3058338689	eustaquio.otero399@email.com	P159	656	5	170	141	8	170
1183328812	CC	Ruperta	Apolonia	Camps	Llanos	2001-11-29	F	3085144225	ruperta.camps694@email.com	P160	396	41	170	296	8	170
1929839528	CC	Adela	Emilia	Antúnez	Ortega	1984-10-29	M	3222830521	adela.antúnez759@email.com	P161	483	41	170	372	8	170
1312469894	CC	Gerardo	Dalila	Ferreras	Pozuelo	1990-09-21	M	3222448510	gerardo.ferreras631@email.com	P162	503	41	170	421	8	170
1230931647	CC	Isidora	Fátima	Cordero	Montes	1993-02-20	M	3237927088	isidora.cordero167@email.com	P163	518	41	170	433	8	170
1884331481	CC	Vanesa	Celia	Caparrós	Blanes	1967-04-29	F	3264126880	vanesa.caparrós57@email.com	P164	524	41	170	436	8	170
1935770226	CC	Candelario	Eulalia	Melero	Higueras	1958-03-18	M	3256150039	candelario.melero53@email.com	P165	530	41	170	520	8	170
1202533744	CC	Abril	Ruben	Perea	Gil	2006-10-28	F	3268356561	abril.perea874@email.com	P166	548	41	170	549	8	170
1785969923	CC	Miguel	Luisa	Duran	Sosa	1982-10-08	M	3299783922	miguel.duran226@email.com	P167	551	41	170	558	8	170
1478116328	CC	Jesusa	Adolfo	Mayol	Aparicio	1969-06-26	M	3097822901	jesusa.mayol505@email.com	P168	615	41	170	560	8	170
1959657063	CC	Marcio	Julián	Cortés	Ribes	2001-06-24	F	3044364495	marcio.cortés734@email.com	P169	660	41	170	573	8	170
1114508860	CC	Benita	Ruperta	Benavides	Baños	1976-07-22	M	3136560711	benita.benavides290@email.com	P170	668	41	170	606	8	170
1047475612	CC	Piedad	Berto	Canales	Llopis	1989-10-28	F	3026228647	piedad.canales112@email.com	P171	676	41	170	634	8	170
1464574808	CC	Isaac	Fabiana	Pozuelo	Feijoo	1968-05-23	M	3279723872	isaac.pozuelo771@email.com	P172	770	41	170	638	8	170
1242388377	CC	Bernabé	Jesusa	Canet	Oliva	1999-02-20	F	3077231810	bernabé.canet750@email.com	P173	791	41	170	675	8	170
1631956907	CC	Mayte	Silvestre	Samper	Zamora	1985-04-24	M	3241450185	mayte.samper476@email.com	P174	797	41	170	685	8	170
1787501891	CC	Iris	Hermenegildo	Burgos	Feliu	1959-03-31	M	3238698151	iris.burgos979@email.com	P175	799	41	170	758	8	170
1041975258	CC	Octavio	Lara	Rebollo	Peralta	1989-05-22	M	3278524332	octavio.rebollo411@email.com	P176	801	41	170	770	8	170
1778141926	CC	Melania	Adalberto	Goñi	Beltrán	1995-10-10	F	3179667290	melania.goñi930@email.com	P177	807	41	170	832	8	170
1417980671	CC	Chus	Aitor	Melero	Paz	1983-11-22	F	3292709838	chus.melero138@email.com	P178	872	41	170	849	8	170
1167386679	CC	Juan Manuel	Hilario	Torrijos	Pintor	1958-02-18	F	3195542758	juan manuel.torrijos717@email.com	P179	885	41	170	1	11	170
1422314667	CC	Vito	Bernabé	Casares	Arana	1964-03-08	M	3157378087	vito.casares91@email.com	P180	1	44	170	2	11	170
1490844569	CC	Herberto	Eliseo	Teruel	Gaya	1989-06-17	F	3029277106	herberto.teruel733@email.com	P181	78	44	170	3	11	170
1605295501	CC	Macario	Vito	Barón	Lucas	1967-07-14	F	3057119779	macario.barón594@email.com	P182	90	44	170	4	11	170
1666421753	CC	Jesusa	Dafne	Villalba	Carrera	1989-04-29	F	3111442134	jesusa.villalba944@email.com	P183	98	44	170	5	11	170
1510277087	CC	José Mari	Narciso	Ponce	Caro	1988-03-07	F	3118532123	josé mari.ponce207@email.com	P184	110	44	170	6	11	170
1193115306	CC	Marco	Fabio	Arenas	Santana	1997-06-09	M	3150032160	marco.arenas450@email.com	P185	279	44	170	7	11	170
1102820213	CC	Fabiana	Wálter	Alba	Arrieta	1981-10-29	F	3290647067	fabiana.alba543@email.com	P186	378	44	170	8	11	170
1675143007	CC	Miriam	Basilio	Infante	Frías	1984-01-24	F	3072341152	miriam.infante634@email.com	P187	420	44	170	9	11	170
1864093182	CC	Dulce	Enrique	Espada	Sala	1958-08-01	F	3060952602	dulce.espada528@email.com	P188	430	44	170	10	11	170
1416137157	CC	Gema	Florencio	Gárate	Gárate	1972-03-24	F	3053018044	gema.gárate901@email.com	P189	560	44	170	11	11	170
1083528498	CC	Paulino	Modesta	Ibarra	Soto	2002-06-27	F	3231863493	paulino.ibarra983@email.com	P190	650	44	170	12	11	170
1419417107	CC	Tito	Serafina	Figuerola	Giralt	1983-10-14	M	3256864968	tito.figuerola727@email.com	P191	847	44	170	13	11	170
1270386383	CC	Sandra	Teodosio	Pardo	Lladó	1962-07-28	M	3197357656	sandra.pardo36@email.com	P192	855	44	170	14	11	170
1842029766	CC	Feliciana	Marcelino	Alcalde	Portillo	1992-06-25	F	3250265443	feliciana.alcalde716@email.com	P193	874	44	170	15	11	170
1405864092	CC	Marianela	Ale	Malo	Solsona	2006-04-20	M	3021250960	marianela.malo911@email.com	P194	1	47	170	16	11	170
1343929963	CC	Roldán	Rafa	Andrés	Bosch	1988-05-16	F	3189008092	roldán.andrés243@email.com	P195	30	47	170	17	11	170
1045516867	CC	Julio César	Edelmiro	Escamilla	Guardiola	2007-01-10	F	3172719883	julio césar.escamilla852@email.com	P196	53	47	170	18	11	170
1918835899	CC	Encarnacion	Malena	Calderón	Sola	1980-06-29	M	3262628200	encarnacion.calderón913@email.com	P197	58	47	170	19	11	170
1127901676	CC	Lupita	Yago	Pujol	Guillen	1985-11-01	F	3065477881	lupita.pujol148@email.com	P198	161	47	170	20	11	170
1454657901	CC	Chucho	Casandra	Sabater	Pascual	1976-05-16	M	3059935682	chucho.sabater623@email.com	P199	170	47	170	1	13	170
1484247160	CC	Eutropio	Remigio	Bejarano	Revilla	1967-01-04	M	3042234296	eutropio.bejarano128@email.com	P200	189	47	170	6	13	170
1593506873	CC	Dionisio	Rafael	Ripoll	Santana	1960-09-29	F	3147445412	dionisio.ripoll515@email.com	P201	205	47	170	30	13	170
1682502627	CC	Marita	Soledad	Arcos	Estrada	1963-08-18	F	3154237969	marita.arcos413@email.com	P202	245	47	170	42	13	170
1680095673	CC	Ileana	Teo	Robles	Prats	1963-08-06	M	3236436944	ileana.robles82@email.com	P203	258	47	170	52	13	170
1542093722	CC	Agustina	Adoración	Rebollo	Pou	1956-06-29	F	3086466484	agustina.rebollo145@email.com	P204	268	47	170	62	13	170
1415109500	CC	Rosalina	Valero	Tomás	Río	1966-08-12	M	3213623393	rosalina.tomás157@email.com	P205	288	47	170	74	13	170
1605462995	CC	Antonia	Roberto	Escamilla	Giralt	1978-06-29	F	3274019601	antonia.escamilla330@email.com	P206	318	47	170	140	13	170
1089252687	CC	Sandra	Guiomar	Villena	Salinas	1967-11-03	F	3127504943	sandra.villena172@email.com	P207	541	47	170	160	13	170
1076374647	CC	Petrona	Claudio	Llobet	Sainz	1990-03-09	M	3172015123	petrona.llobet135@email.com	P208	545	47	170	188	13	170
1054216554	CC	Sancho	Pili	Rosales	Cuenca	1982-10-23	M	3138179547	sancho.rosales369@email.com	P209	551	47	170	212	13	170
1142491485	CC	Pacífica	Modesta	Salcedo	Lasa	1983-04-10	M	3292680151	pacífica.salcedo808@email.com	P210	555	47	170	222	13	170
1864383026	CC	Amada	Antonia	Alcántara	Andrés	1980-10-21	F	3170700365	amada.alcántara997@email.com	P211	570	47	170	244	13	170
1934510055	CC	César	Felipa	Barroso	Valls	1972-12-07	F	3223319625	césar.barroso989@email.com	P212	605	47	170	248	13	170
1263427561	CC	Ileana	Hermenegildo	Ortega	Tejera	1995-06-01	F	3073111725	ileana.ortega339@email.com	P213	660	47	170	268	13	170
1537584488	CC	Pascual	Fortunato	Gámez	Peñas	1982-01-02	M	3228887792	pascual.gámez107@email.com	P214	675	47	170	300	13	170
1344786348	CC	Pablo	Olga	Barco	Goñi	1997-08-02	M	3157039616	pablo.barco613@email.com	P215	692	47	170	430	13	170
1814404528	CC	Fidela	Atilio	Pujol	Amo	1997-12-26	M	3076585311	fidela.pujol45@email.com	P216	703	47	170	433	13	170
1203968909	CC	Ester	Eugenia	Cuevas	Niño	1976-09-16	M	3061840728	ester.cuevas666@email.com	P217	707	47	170	440	13	170
1045396340	CC	Salomé	Cebrián	Rozas	Sanchez	1984-07-28	F	3177080873	salomé.rozas919@email.com	P218	745	47	170	442	13	170
1030621593	CC	Florentino	Norberto	Ruano	Cortés	1954-12-17	M	3284030420	florentino.ruano595@email.com	P219	798	47	170	458	13	170
1218506523	CC	Danilo	Brígida	Gallego	Sureda	1965-12-30	M	3282900978	danilo.gallego763@email.com	P220	1	50	170	468	13	170
1111671499	CC	Tere	Asdrubal	Lastra	Reina	1998-03-26	M	3060203531	tere.lastra677@email.com	P221	6	50	170	473	13	170
1020921984	CC	Herberto	Cayetano	Ródenas	Morán	1995-04-25	M	3233623856	herberto.ródenas743@email.com	P222	110	50	170	549	13	170
1223998980	CC	Ignacia	Isaura	Iglesias	Rey	1964-03-16	M	3051362609	ignacia.iglesias5@email.com	P223	124	50	170	580	13	170
1576176978	CC	Eufemia	Evelia	Riba	Jove	1985-07-13	M	3088279107	eufemia.riba803@email.com	P224	150	50	170	600	13	170
1669253556	CC	Noa	Paloma	Montesinos	Luz	1996-08-01	F	3014413718	noa.montesinos321@email.com	P225	223	50	170	620	13	170
1892293961	CC	Florencia	Octavio	Tena	Mayo	1965-09-12	F	3241031800	florencia.tena332@email.com	P226	226	50	170	647	13	170
1022592522	CC	Adalberto	Angélica	Roselló	Ureña	1982-10-15	M	3099440706	adalberto.roselló557@email.com	P227	245	50	170	650	13	170
1757397091	CC	Nilda	Remedios	Duran	Bermudez	1997-02-24	F	3038909603	nilda.duran574@email.com	P228	251	50	170	654	13	170
1386018072	CC	Javier	Hipólito	Berenguer	Lerma	1961-02-06	M	3220892981	javier.berenguer387@email.com	P229	270	50	170	655	13	170
1917356957	CC	Máximo	Anselma	Piquer	Gracia	1963-03-31	F	3027784043	máximo.piquer823@email.com	P230	287	50	170	657	13	170
1091038072	CC	Luis	Cristóbal	Cámara	Vilalta	1997-11-19	M	3016227413	luis.cámara448@email.com	P231	313	50	170	667	13	170
1812553699	CC	Ovidio	Francisca	Angulo	Santamaría	1989-11-05	M	3037691418	ovidio.angulo747@email.com	P232	318	50	170	670	13	170
1399626520	CC	Leandro	Arsenio	Ferrández	Lladó	1959-11-10	M	3097890903	leandro.ferrández248@email.com	P233	325	50	170	673	13	170
1741759367	CC	Aránzazu	Consuelo	Manjón	Planas	1968-08-09	F	3221819059	aránzazu.manjón404@email.com	P234	330	50	170	683	13	170
1655318354	CC	Úrsula	Marcelino	Pons	Carro	1991-04-21	M	3222513076	úrsula.pons7@email.com	P235	350	50	170	688	13	170
1968889416	CC	Lucho	Gregorio	Belda	Benavente	1963-11-01	M	3224090701	lucho.belda697@email.com	P236	370	50	170	744	13	170
1538597770	CC	Ildefonso	Elpidio	Bonet	Arnal	1992-01-22	M	3237960957	ildefonso.bonet876@email.com	P237	400	50	170	760	13	170
1353558033	CC	Edu	Felipe	Moliner	Puig	1986-11-14	F	3235859520	edu.moliner431@email.com	P238	450	50	170	780	13	170
1755312066	CC	Iris	Amparo	Verdugo	Baños	1998-01-07	F	3048646259	iris.verdugo631@email.com	P239	568	50	170	810	13	170
1641274057	CC	Custodio	Francisco Javier	Solano	Sarmiento	1969-05-03	M	3035378503	custodio.solano741@email.com	P240	573	50	170	836	13	170
1236084614	CC	Fabiola	María Pilar	Burgos	Ponce	2006-12-25	F	3296723274	fabiola.burgos54@email.com	P241	577	50	170	838	13	170
1685381052	CC	Faustino	Emilio	Valls	Vazquez	1999-08-12	F	3010311980	faustino.valls849@email.com	P242	590	50	170	873	13	170
1039703861	CC	Cornelio	Emilia	Folch	Mayol	1971-05-05	M	3023551183	cornelio.folch893@email.com	P243	606	50	170	894	13	170
1253475646	CC	Reyna	Valerio	Alcalá	Contreras	1989-05-31	F	3143440913	reyna.alcalá817@email.com	P244	680	50	170	1	15	170
1259854800	CC	Montserrat	Marina	Páez	Domingo	1978-03-24	F	3225600568	montserrat.páez46@email.com	P245	683	50	170	22	15	170
1204561555	CC	Humberto	Bárbara	Espinosa	Rivero	1964-12-18	M	3274490286	humberto.espinosa417@email.com	P246	686	50	170	47	15	170
1100836481	CC	Mario	Débora	Alegre	Capdevila	1961-09-27	M	3140109251	mario.alegre25@email.com	P247	689	50	170	51	15	170
1138875185	CC	Quique	Rosenda	Sola	Castelló	1973-05-19	F	3057775560	quique.sola532@email.com	P240	711	50	170	87	15	170
1551707633	CC	Amanda	Palmira	Valenciano	Zamora	1980-07-28	F	3190842764	amanda.valenciano154@email.com	P241	1	52	170	90	15	170
1469092671	CC	Jacobo	Ramiro	Melero	Vázquez	1955-05-06	F	3064142613	jacobo.melero949@email.com	P242	19	52	170	92	15	170
1300931839	CC	Abril	Elba	Mur	Cuadrado	1995-06-22	F	3053528338	abril.mur892@email.com	P243	22	52	170	97	15	170
1123271973	CC	Fermín	Luis	Bellido	Benet	1992-06-27	F	3122103140	fermín.bellido26@email.com	P244	36	52	170	104	15	170
1683530870	CC	Áurea	Cristóbal	Ávila	Valls	1974-11-19	M	3273456780	áurea.ávila527@email.com	P245	51	52	170	106	15	170
1790967203	CC	Dani	Lucila	Mancebo	Iñiguez	1972-11-15	F	3070501037	dani.mancebo554@email.com	P246	79	52	170	109	15	170
1933729913	CC	Ofelia	Anna	Company	Sales	2002-08-10	F	3121884369	ofelia.company656@email.com	P247	83	52	170	114	15	170
1596399157	CC	Antonio	Jose Carlos	Aragonés	Luque	1997-04-03	M	3261606044	antonio.aragonés130@email.com	P248	110	52	170	131	15	170
1881638781	CC	Aitana	Álvaro	Alcalde	Valencia	1972-08-20	F	3210743179	aitana.alcalde964@email.com	P249	203	52	170	135	15	170
1356258550	CC	Carmela	Agapito	Molins	Adán	1956-09-29	M	3048905542	carmela.molins491@email.com	P250	207	52	170	162	15	170
1166861277	CC	Fabricio	Albert	Domingo	Mata	2001-01-07	M	3231456293	fabricio.domingo807@email.com	P251	210	52	170	172	15	170
1640749632	CC	Juan Carlos	Ramón	Pombo	Baró	1954-05-27	F	3133253033	juan carlos.pombo202@email.com	P252	215	52	170	176	15	170
1838819285	CC	Nicolás	Pancho	Aller	Palomar	2006-03-04	M	3161306816	nicolás.aller449@email.com	P253	224	52	170	180	15	170
1601928849	CC	Cruz	Dani	Acero	Flores	1980-04-25	F	3062964636	cruz.acero769@email.com	P254	227	52	170	183	15	170
1208622456	CC	Marianela	Crescencia	Rivero	Pallarès	1977-06-11	M	3264681518	marianela.rivero83@email.com	P255	233	52	170	185	15	170
1169722277	CC	Aarón	Sara	Montesinos	Gras	1962-07-09	M	3067789097	aarón.montesinos720@email.com	P256	240	52	170	187	15	170
1808469970	CC	Hilario	Tecla	Colom	Recio	1977-06-28	M	3018115571	hilario.colom675@email.com	P257	250	52	170	189	15	170
1897920692	CC	Zacarías	Alfredo	Marco	Bermúdez	1957-08-27	M	3091710865	zacarías.marco75@email.com	P258	254	52	170	204	15	170
1058108381	CC	Felicidad	Perlita	Mendoza	Prieto	1955-05-16	M	3156708575	felicidad.mendoza482@email.com	P259	256	52	170	212	15	170
1232317863	CC	Edelmira	Emperatriz	Montenegro	Gual	1975-11-18	F	3095649530	edelmira.montenegro714@email.com	P260	258	52	170	215	15	170
1725308984	CC	Bonifacio	Montserrat	Palma	Viñas	1970-12-12	F	3140508830	bonifacio.palma771@email.com	P261	260	52	170	218	15	170
1628870403	CC	Carmina	Curro	Carrera	Mosquera	1999-05-30	M	3085801621	carmina.carrera152@email.com	P262	287	52	170	223	15	170
1720359248	CC	Nidia	Sabas	Abad	Nicolás	1968-11-25	F	3170436747	nidia.abad415@email.com	P263	317	52	170	224	15	170
1371272857	CC	Nicanor	Jessica	Vilanova	Ruiz	1996-09-16	F	3242449316	nicanor.vilanova963@email.com	P264	320	52	170	226	15	170
1970406429	CC	Rufino	Segismundo	Pavón	Aramburu	1954-05-29	F	3122599914	rufino.pavón605@email.com	P265	323	52	170	232	15	170
1922128577	CC	Rómulo	Luís	Zorrilla	Bosch	1979-09-17	M	3270909328	rómulo.zorrilla238@email.com	P266	352	52	170	236	15	170
1580029091	CC	Julián	Ibán	Pinto	Rueda	1970-08-12	F	3222750293	julián.pinto250@email.com	P267	354	52	170	238	15	170
1405817763	CC	Rosa	Flavio	Rivero	Marqués	1958-04-23	M	3076732835	rosa.rivero244@email.com	P268	356	52	170	244	15	170
1517118152	CC	Gonzalo	Agustina	Cueto	Salamanca	2000-02-08	M	3088604445	gonzalo.cueto485@email.com	P269	378	52	170	248	15	170
1280389928	CC	Espiridión	Jose Miguel	Córdoba	Carmona	1990-12-28	M	3292310005	espiridión.córdoba209@email.com	P270	381	52	170	272	15	170
1471771788	CC	Telmo	Eric	Estrada	Romeu	1966-03-03	M	3083856728	telmo.estrada162@email.com	P271	385	52	170	276	15	170
1944698152	CC	Ángeles	Calixta	Cadenas	Redondo	1973-10-28	F	3052236519	ángeles.cadenas716@email.com	P272	390	52	170	293	15	170
1753463126	CC	Agustín	Tomás	Tejero	Verdú	2001-08-28	F	3257804129	agustín.tejero160@email.com	P273	399	52	170	296	15	170
1960618335	CC	Dora	Débora	Sarabia	Coronado	1985-10-31	M	3132825108	dora.sarabia979@email.com	P274	405	52	170	299	15	170
1065761959	CC	Nélida	Ofelia	Enríquez	Quiroga	1997-10-05	M	3135767955	nélida.enríquez746@email.com	P275	411	52	170	317	15	170
1481708505	CC	Chelo	Esperanza	Andres	Vega	1987-02-21	M	3121924621	chelo.andres479@email.com	P276	418	52	170	322	15	170
1802030577	CC	Jesús	Che	Elías	Guitart	2001-03-28	M	3127666120	jesús.elías396@email.com	P277	427	52	170	325	15	170
1929124097	CC	Amílcar	Julio	Barrena	Marín	1993-04-12	F	3026323574	amílcar.barrena204@email.com	P278	435	52	170	332	15	170
1996779429	CC	Susana	Gervasio	Zamorano	Bonet	1971-12-07	F	3081079238	susana.zamorano1@email.com	P279	473	52	170	362	15	170
1788276940	CC	Felix	Eusebia	Casal	Pomares	1981-02-02	M	3117176268	felix.casal179@email.com	P280	490	52	170	367	15	170
1683880178	CC	África	Amalia	Bárcena	Coll	2005-12-18	M	3276538704	áfrica.bárcena557@email.com	P281	506	52	170	368	15	170
1300201589	CC	Carolina	Ciríaco	Macias	Mariscal	2003-12-19	M	3219305719	carolina.macias344@email.com	P282	520	52	170	377	15	170
1638945776	CC	Sandalio	Fabio	Agustí	Hernando	1989-09-10	F	3051844563	sandalio.agustí612@email.com	P283	540	52	170	380	15	170
1125677966	CC	Esmeralda	África	Hernandez	Seguí	1971-06-03	F	3195516151	esmeralda.hernandez518@email.com	P284	560	52	170	401	15	170
1303756905	CC	Morena	Evelia	Lucena	Fernández	1979-08-23	M	3087214485	morena.lucena543@email.com	P285	565	52	170	403	15	170
1593822136	CC	Bartolomé	Marcia	Solé	Bonilla	1979-01-27	F	3086231886	bartolomé.solé829@email.com	P286	573	52	170	407	15	170
1873044318	CC	Mariano	Ainoa	Buendía	Cifuentes	1979-12-13	M	3198200526	mariano.buendía941@email.com	P287	585	52	170	425	15	170
1391572838	CC	Santos	Gala	Sotelo	Bayón	1999-11-01	M	3293405575	santos.sotelo411@email.com	P288	612	52	170	442	15	170
1283191065	CC	Evaristo	Ramona	Moliner	Torrens	2003-05-21	M	3173992825	evaristo.moliner690@email.com	P289	621	52	170	455	15	170
1508223094	CC	Juanita	Onofre	Ros	Tapia	1998-06-04	M	3263824410	juanita.ros114@email.com	P290	678	52	170	464	15	170
1270949634	CC	Agapito	Rufino	Nieto	Lluch	1975-10-28	M	3074953164	agapito.nieto48@email.com	P291	683	52	170	466	15	170
1248174096	CC	Rocío	Ángel	Montoya	Barriga	1977-07-28	F	3127844555	rocío.montoya276@email.com	P292	685	52	170	469	15	170
1548337558	CC	Nuria	Mireia	Esteban	Velázquez	1999-01-07	M	3240475766	nuria.esteban646@email.com	P293	687	52	170	476	15	170
1245989685	CC	Erasmo	Silvio	Fonseca	Guillen	1985-10-04	M	3214414135	erasmo.fonseca743@email.com	P294	693	52	170	480	15	170
1809933012	CC	Lupita	Ismael	Ramón	Lago	1968-04-18	M	3076513902	lupita.ramón917@email.com	P295	694	52	170	491	15	170
1269935678	CC	Rosalina	Paloma	Boix	Salas	1969-01-20	F	3082252028	rosalina.boix993@email.com	P296	696	52	170	494	15	170
1838247372	CC	Anselma	Amarilis	Iglesia	Borrell	1976-01-09	M	3130482236	anselma.iglesia768@email.com	P297	699	52	170	500	15	170
1679787577	CC	Chus	Eladio	Pelayo	Torrent	1976-12-27	M	3140531153	chus.pelayo6@email.com	P298	720	52	170	507	15	170
1371024237	CC	Pepe	Alfonso	Aragón	Canals	2002-04-04	F	3115090446	pepe.aragón512@email.com	P299	786	52	170	511	15	170
1234227944	CC	Yago	Isaac	Barreda	Bastida	1966-09-19	M	3189500713	yago.barreda994@email.com	P300	788	52	170	514	15	170
1314202958	CC	Gil	Manolo	Abascal	Bellido	1993-09-23	M	3293888709	gil.abascal453@email.com	P301	835	52	170	516	15	170
1251058824	CC	Selena	Esther	Landa	Galan	1963-09-24	F	3293015737	selena.landa110@email.com	P302	838	52	170	518	15	170
1193211969	CC	Aura	Isabel	Higueras	Malo	2001-05-07	F	3157173938	aura.higueras383@email.com	P303	885	52	170	522	15	170
1735671925	CC	Saturnina	Benigno	Pino	Reig	1999-07-07	F	3083918281	saturnina.pino322@email.com	P304	1	54	170	531	15	170
1355918173	CC	Lázaro	Guillermo	Valls	López	1972-06-01	F	3129264342	lázaro.valls344@email.com	P305	3	54	170	533	15	170
1507445443	CC	Nieves	Teófilo	Leon	Arteaga	1955-04-27	M	3140251899	nieves.leon644@email.com	P306	51	54	170	537	15	170
1124818705	CC	Arcelia	Dominga	Mancebo	Barragán	1995-11-22	F	3211949340	arcelia.mancebo107@email.com	P307	99	54	170	542	15	170
1352517204	CC	Mar	Cayetana	Camacho	Peláez	1969-09-08	M	3081582124	mar.camacho587@email.com	P308	109	54	170	550	15	170
1720509893	CC	Rufina	Raquel	Alfonso	Prats	1972-03-22	F	3218274806	rufina.alfonso494@email.com	P309	125	54	170	572	15	170
1656027058	CC	Clementina	Horacio	Sanjuan	Céspedes	1961-09-06	F	3093146818	clementina.sanjuan996@email.com	P310	128	54	170	580	15	170
1083932272	CC	Rafael	Bernardino	Pulido	Cabello	1990-06-05	M	3138009299	rafael.pulido918@email.com	P311	172	54	170	599	15	170
1291247389	CC	Nacho	Iván	Oliva	Rodriguez	1989-05-18	M	3266050931	nacho.oliva888@email.com	P312	174	54	170	600	15	170
1338848584	CC	Álvaro	Albino	Llopis	Bello	1981-01-04	M	3188425459	álvaro.llopis264@email.com	P313	206	54	170	621	15	170
1399301476	CC	Octavio	Teresa	Blanes	Olmedo	1995-05-14	F	3089640219	octavio.blanes639@email.com	P314	223	54	170	632	15	170
1443675929	CC	Silvio	Chus	Fabra	Feliu	1972-05-24	F	3297096081	silvio.fabra961@email.com	P315	239	54	170	638	15	170
1654588046	CC	Heraclio	Ana	Caro	Anglada	1979-08-11	M	3138181075	heraclio.caro266@email.com	P316	245	54	170	646	15	170
1423799052	CC	Faustino	Jose Luis	Cerdán	Arranz	1991-12-15	M	3240990549	faustino.cerdán314@email.com	P317	250	54	170	660	15	170
1003790393	CC	Josefa	Cecilio	Ávila	Parejo	1960-11-05	M	3278849487	josefa.ávila407@email.com	P318	261	54	170	664	15	170
1125599413	CC	Isaías	Marcelo	Agustín	Vall	1982-07-25	F	3211056766	isaías.agustín796@email.com	P319	313	54	170	667	15	170
1406210137	CC	Marina	Artemio	Nuñez	Galvez	1957-11-14	F	3228543319	marina.nuñez799@email.com	P320	344	54	170	673	15	170
1171457990	CC	Valero	Aura	Narváez	Marin	1991-09-06	M	3258276230	valero.narváez909@email.com	P321	347	54	170	676	15	170
1938753343	CC	Rafaela	Nazaret	Rodriguez	Mesa	1984-03-04	F	3130316461	rafaela.rodriguez967@email.com	P322	377	54	170	681	15	170
1331041751	CC	Nieves	Gastón	Carro	Camino	1985-08-24	F	3231729922	nieves.carro66@email.com	P323	385	54	170	686	15	170
1211167169	CC	Clarisa	Jordi	Cerdán	Dueñas	1990-04-27	M	3051058211	clarisa.cerdán397@email.com	P324	398	54	170	690	15	170
1753313643	CC	Rolando	Melania	Martínez	Francisco	1980-10-07	F	3028158152	rolando.martínez917@email.com	P325	405	54	170	693	15	170
1729810007	CC	Cruz	Loida	Sáenz	Amor	1985-02-19	M	3173225234	cruz.sáenz789@email.com	P326	418	54	170	696	15	170
1755776771	CC	Cándido	Nazaret	Borrás	Peralta	1955-12-05	M	3267717745	cándido.borrás730@email.com	P327	480	54	170	720	15	170
1076570978	CC	Pablo	René	Viñas	Villalba	1966-08-07	M	3066693780	pablo.viñas447@email.com	P328	498	54	170	723	15	170
1746164254	CC	Cristian	Selena	Enríquez	Cifuentes	1960-10-25	F	3267957228	cristian.enríquez829@email.com	P329	518	54	170	740	15	170
1625602835	CC	Josefina	Glauco	Salas	Costa	1965-04-26	F	3162202570	josefina.salas659@email.com	P330	520	54	170	753	15	170
1224498048	CC	Borja	Piedad	Ortiz	Ferreras	1956-04-08	F	3012211065	borja.ortiz594@email.com	P331	553	54	170	755	15	170
1833508236	CC	Urbano	Chelo	Madrid	Manuel	1998-07-10	M	3111552693	urbano.madrid657@email.com	P332	599	54	170	757	15	170
1866149035	CC	Cecilia	Benigno	Cortes	Trujillo	1987-02-16	F	3287101576	cecilia.cortes163@email.com	P333	660	54	170	759	15	170
1667427647	CC	Elisabet	Adolfo	Cabello	Guitart	1979-01-17	M	3063605660	elisabet.cabello319@email.com	P334	670	54	170	761	15	170
1853233955	CC	Yéssica	Anastasia	Lasa	Zaragoza	1962-05-11	M	3132469081	yéssica.lasa17@email.com	P335	673	54	170	762	15	170
1438677097	CC	Jenny	Isidora	Trujillo	Marcos	1996-11-06	F	3120485825	jenny.trujillo242@email.com	P336	680	54	170	763	15	170
1383916991	CC	Joan	Zacarías	Delgado	Calvo	1999-02-28	F	3171940879	joan.delgado973@email.com	P337	720	54	170	764	15	170
1263203026	CC	Rafa	Ileana	Alvarez	Amo	1956-04-29	M	3131454022	rafa.alvarez96@email.com	P338	743	54	170	774	15	170
1165956354	CC	Eufemia	Onofre	Tovar	Garmendia	1960-01-01	F	3082464121	eufemia.tovar593@email.com	P339	800	54	170	776	15	170
1136740472	CC	Eustaquio	Maricruz	Canals	Vara	1985-07-27	M	3110786616	eustaquio.canals928@email.com	P340	810	54	170	778	15	170
1945386662	CC	Isidora	Nazaret	Villegas	Coronado	1972-05-10	M	3144973388	isidora.villegas137@email.com	P341	820	54	170	790	15	170
1796116097	CC	Tomás	Adriana	Goñi	Cortés	2000-03-14	M	3276718591	tomás.goñi623@email.com	P342	871	54	170	798	15	170
1067635015	CC	Aarón	Feliciana	Calleja	Carretero	2004-01-29	M	3294538104	aarón.calleja286@email.com	P343	874	54	170	804	15	170
1231108263	CC	Caridad	Julián	Recio	Sáez	1985-08-03	M	3234107252	caridad.recio591@email.com	P344	1	63	170	806	15	170
1146134107	CC	Noé	Eduardo	Toro	Ibañez	1968-07-09	F	3263202044	noé.toro641@email.com	P345	111	63	170	808	15	170
1837224001	CC	Yago	Adán	Alberdi	Blázquez	1987-04-09	M	3091483175	yago.alberdi903@email.com	P346	130	63	170	810	15	170
1885795495	CC	Felicia	Mauricio	Aliaga	Garcia	1978-10-11	F	3118932873	felicia.aliaga378@email.com	P347	190	63	170	814	15	170
1115673167	CC	Tristán	Aurelia	Lago	Pou	1964-07-02	M	3233931375	tristán.lago835@email.com	P348	212	63	170	816	15	170
1020310398	CC	Rufina	Belén	Garzón	Durán	1980-04-18	F	3260173457	rufina.garzón965@email.com	P349	272	63	170	820	15	170
1815004195	CC	Iván	Gonzalo	Palomar	Palomares	1994-12-17	M	3292228706	iván.palomar423@email.com	P350	302	63	170	822	15	170
1380111989	CC	Pablo	Víctor	Cámara	Pina	1977-01-26	F	3216239214	pablo.cámara747@email.com	P351	401	63	170	832	15	170
1654465547	CC	Encarnacion	Concha	Peral	Ángel	1998-02-17	F	3038124475	encarnacion.peral205@email.com	P352	470	63	170	835	15	170
1180598299	CC	Abril	Alfonso	Casals	Sanabria	1976-03-14	M	3294368826	abril.casals758@email.com	P353	548	63	170	837	15	170
1222220742	CC	Albina	Rocío	Guitart	Crespo	1984-12-06	F	3028659167	albina.guitart181@email.com	P354	594	63	170	839	15	170
1373161364	CC	Gracia	Esther	Quintero	Pera	2005-04-02	F	3122072679	gracia.quintero524@email.com	P355	690	63	170	842	15	170
1943030030	CC	Nazario	África	Mur	Planas	1957-06-25	F	3077030243	nazario.mur285@email.com	P356	1	66	170	861	15	170
1300538656	CC	Dolores	Vanesa	Jaume	Bravo	1981-06-14	F	3227488800	dolores.jaume803@email.com	P357	45	66	170	879	15	170
1480316666	CC	África	Angélica	Cortes	Cazorla	1997-03-31	M	3110532931	áfrica.cortes77@email.com	P358	75	66	170	897	15	170
1681289427	CC	Ramona	Edmundo	Grau	Macías	1990-05-05	M	3139758609	ramona.grau211@email.com	P359	88	66	170	1	17	170
1035179304	CC	Amanda	Rufino	Berenguer	Alegria	1971-03-29	F	3195908236	amanda.berenguer19@email.com	P360	170	66	170	13	17	170
1554798202	CC	Alcides	Pablo	Vega	Santos	1971-01-08	M	3159983246	alcides.vega343@email.com	P361	318	66	170	42	17	170
1177638502	CC	Marcelino	Domingo	Montenegro	Ribes	1988-07-20	M	3290022691	marcelino.montenegro47@email.com	P362	383	66	170	50	17	170
1382835172	CC	Miguel Ángel	María	Anaya	Álvaro	1984-10-15	F	3257422388	miguel ángel.anaya52@email.com	P363	400	66	170	88	17	170
1768778021	CC	Corona	Herberto	Tejedor	Arribas	2006-06-13	F	3175688149	corona.tejedor629@email.com	P364	440	66	170	174	17	170
1465448275	CC	Eligio	María Teresa	Perera	Garrido	1993-12-14	F	3138578401	eligio.perera834@email.com	P365	456	66	170	272	17	170
1329515246	CC	Albina	Jesusa	Orozco	Bautista	1979-07-19	F	3190077051	albina.orozco473@email.com	P366	572	66	170	380	17	170
1388901812	CC	Emigdio	Camilo	Castañeda	Perales	2000-09-13	M	3161293469	emigdio.castañeda952@email.com	P367	594	66	170	388	17	170
1381026101	CC	Pepe	Celia	Prado	Vilanova	1975-08-19	M	3233182897	pepe.prado922@email.com	P368	682	66	170	433	17	170
1687593244	CC	Ignacio	Teodosio	Vall	Viña	1983-02-08	M	3036693556	ignacio.vall433@email.com	P369	687	66	170	442	17	170
1054122280	CC	Pepita	Poncio	Amorós	Álamo	1983-01-09	M	3140094449	pepita.amorós523@email.com	P370	1	68	170	444	17	170
1441138039	CC	Lázaro	Salud	Lluch	Sanmartín	1957-11-21	M	3074804221	lázaro.lluch471@email.com	P371	13	68	170	446	17	170
1749163283	CC	Pancho	Hipólito	Pozuelo	Soria	1989-05-14	M	3022275916	pancho.pozuelo50@email.com	P372	20	68	170	486	17	170
1038861012	CC	Roque	Virgilio	Alcalá	Pareja	1980-06-20	F	3036954044	roque.alcalá97@email.com	P001	51	68	170	495	17	170
1441937555	CC	Bernardo	Josefina	Gallo	Fernandez	1978-06-04	F	3255193788	bernardo.gallo363@email.com	P002	77	68	170	513	17	170
1634289995	CC	Nereida	Artemio	Tamarit	Buendía	1988-01-07	M	3233385239	nereida.tamarit862@email.com	P003	79	68	170	524	17	170
1659896058	CC	Consuelo	Miguel Ángel	Izquierdo	Pastor	1979-09-12	M	3058204384	consuelo.izquierdo757@email.com	P004	81	68	170	541	17	170
1962244664	CC	Severiano	Rafa	Vila	Ortega	1966-03-19	F	3050096560	severiano.vila724@email.com	P005	92	68	170	614	17	170
1728689252	CC	Macaria	Saturnina	Cuadrado	Mata	1987-02-13	M	3113319062	macaria.cuadrado86@email.com	P006	101	68	170	616	17	170
1602720554	CC	Rufina	Rocío	Río	Borrell	1988-07-22	M	3261812154	rufina.río395@email.com	P007	121	68	170	653	17	170
1382037266	CC	Eustaquio	Jesusa	Reina	Coca	2005-02-27	M	3162249554	eustaquio.reina231@email.com	P008	132	68	170	662	17	170
1012802155	CC	Adoración	Luis	Morillo	Planas	1994-02-17	M	3112443308	adoración.morillo139@email.com	P009	147	68	170	665	17	170
1194704269	CC	Emilio	Octavia	Peñalver	Sosa	2002-07-05	F	3185564083	emilio.peñalver46@email.com	P010	152	68	170	777	17	170
1341234686	CC	Rafaela	Nacio	Cid	Serra	1955-11-03	F	3181491910	rafaela.cid88@email.com	P011	160	68	170	867	17	170
1094981158	CC	Gertrudis	Isaías	Álvarez	Nevado	1998-12-07	F	3032578046	gertrudis.álvarez705@email.com	P012	162	68	170	873	17	170
1752062831	CC	Lisandro	Inocencio	Romeu	Hervia	1960-04-10	M	3021822211	lisandro.romeu994@email.com	P013	167	68	170	877	17	170
1464211798	CC	Chucho	Luis Miguel	Serra	Huguet	1958-01-22	M	3264618158	chucho.serra333@email.com	P014	169	68	170	1	18	170
1115439806	CC	Sebastian	Montserrat	Piquer	Pinto	1962-08-25	M	3294428196	sebastian.piquer301@email.com	P015	327	68	170	29	18	170
1499945977	CC	Eliana	Dalila	Herrera	Pelayo	2006-05-29	M	3230524320	eliana.herrera745@email.com	P016	344	68	170	94	18	170
1572760719	CC	Victorino	Victorino	Colom	Jiménez	2007-03-20	M	3092445780	victorino.colom731@email.com	P017	368	68	170	150	18	170
1102314457	CC	Visitación	Pastora	Vara	Blanes	1985-08-09	F	3151611196	visitación.vara254@email.com	P018	370	68	170	205	18	170
1820597500	CC	Herberto	Chus	Cañas	Castañeda	1993-05-23	M	3180490604	herberto.cañas873@email.com	P019	377	68	170	247	18	170
1946415469	CC	Ibán	Quirino	Ruiz	Palomares	1973-10-30	M	3153532211	ibán.ruiz766@email.com	P020	385	68	170	256	18	170
1937598799	CC	Gerónimo	Armida	Ochoa	Priego	1968-09-22	F	3125965517	gerónimo.ochoa569@email.com	P021	397	68	170	410	18	170
1629949814	CC	Verónica	Ismael	Ripoll	Esteban	1990-09-02	M	3020279660	verónica.ripoll833@email.com	P022	406	68	170	460	18	170
1400891038	CC	Victor	Jordán	Jiménez	Ojeda	1994-12-20	M	3140456545	victor.jiménez60@email.com	P023	418	68	170	479	18	170
1673715337	CC	Ruy	José Mari	Tamarit	Ramón	1992-03-10	M	3277264874	ruy.tamarit570@email.com	P024	425	68	170	592	18	170
1659843290	CC	Chus	Tomasa	Pinto	Mateo	1973-05-17	M	3117830609	chus.pinto621@email.com	P025	432	68	170	610	18	170
1373516410	CC	Nico	Genoveva	Prat	Gutierrez	1959-05-14	F	3252836377	nico.prat592@email.com	P026	444	68	170	753	18	170
1084967541	CC	Josefina	Ernesto	Pallarès	Cervantes	1971-06-07	F	3287927529	josefina.pallarès169@email.com	P027	464	68	170	756	18	170
1635418500	CC	Carmelita	Salvador	Piñeiro	Planas	1959-02-05	M	3190040485	carmelita.piñeiro470@email.com	P028	468	68	170	785	18	170
1848162045	CC	Mateo	Américo	Seguí	Bou	1989-03-03	M	3115670134	mateo.seguí774@email.com	P029	498	68	170	860	18	170
1721355935	CC	Chuy	Eligia	Perez	Peláez	1968-11-20	F	3055654598	chuy.perez582@email.com	P030	500	68	170	1	19	170
1458299989	CC	Abraham	Ceferino	Ortuño	Escribano	1960-12-15	F	3228126277	abraham.ortuño802@email.com	P031	502	68	170	22	19	170
1419876028	CC	Buenaventura	Débora	Castejón	Malo	1983-06-04	M	3221781860	buenaventura.castejón879@email.com	P032	522	68	170	50	19	170
1359118468	CC	Jose Antonio	Manu	Alonso	Maestre	1978-03-17	M	3292504699	jose antonio.alonso426@email.com	P033	524	68	170	75	19	170
1407630662	CC	Fortunata	Anastasia	Alvarado	Padilla	1980-01-17	F	3241460113	fortunata.alvarado584@email.com	P034	533	68	170	100	19	170
1640553597	CC	Jerónimo	Viviana	Valdés	Jove	1977-04-20	M	3146420056	jerónimo.valdés282@email.com	P035	547	68	170	110	19	170
1072141457	CC	Pía	Beatriz	Lobo	Herranz	1977-02-22	M	3097230324	pía.lobo808@email.com	P036	549	68	170	130	19	170
1079475888	CC	Jerónimo	Eduardo	Tur	Pereira	1957-02-08	M	3299367993	jerónimo.tur973@email.com	P037	572	68	170	137	19	170
1128207000	CC	Alberto	Valeria	Estevez	Pombo	1980-03-29	M	3152423285	alberto.estevez338@email.com	P038	573	68	170	142	19	170
1322328432	CC	Ana Belén	Daniel	Baró	Sandoval	1959-12-14	F	3215079801	ana belén.baró785@email.com	P039	575	68	170	212	19	170
1256118477	CC	Sandalio	Ruth	Cobo	Ordóñez	1964-10-04	F	3120630001	sandalio.cobo893@email.com	P040	615	68	170	256	19	170
1237760486	CC	Benjamín	Benigna	Briones	Plaza	2000-03-08	M	3260151750	benjamín.briones756@email.com	P041	655	68	170	290	19	170
1075687940	CC	Omar	Edgardo	Sarmiento	Cornejo	1982-09-28	F	3223585058	omar.sarmiento770@email.com	P042	669	68	170	318	19	170
1412482120	CC	Roberto	Angélica	Delgado	Godoy	1984-04-06	M	3269449579	roberto.delgado922@email.com	P043	673	68	170	355	19	170
1052927625	CC	Almudena	Inmaculada	Torre	Serna	2004-09-24	M	3074423320	almudena.torre416@email.com	P044	679	68	170	364	19	170
1447963719	CC	Atilio	Eli	Fiol	Abellán	1982-11-04	M	3168576448	atilio.fiol579@email.com	P045	682	68	170	392	19	170
1110482985	CC	Quique	Victorino	Mosquera	Mendizábal	1996-04-27	M	3095415251	quique.mosquera424@email.com	P046	684	68	170	397	19	170
1922901468	CC	Maxi	Anselmo	Hervia	Barrera	1965-01-11	F	3013235192	maxi.hervia440@email.com	P047	686	68	170	418	19	170
1968483081	CC	Pastora	Joel	Riera	Alberdi	1956-04-27	F	3232713359	pastora.riera389@email.com	P048	689	68	170	450	19	170
1258990415	CC	Sol	Albino	Fonseca	Izquierdo	1998-02-25	M	3019137470	sol.fonseca642@email.com	P049	705	68	170	455	19	170
1843022085	CC	Alfredo	Herminia	Jáuregui	Mariño	2004-02-10	F	3136754843	alfredo.jáuregui51@email.com	P050	720	68	170	473	19	170
1708081174	CC	Jose Carlos	Sol	Izaguirre	Padilla	1978-10-28	M	3086295427	jose carlos.izaguirre541@email.com	P051	745	68	170	513	19	170
1876816557	CC	Anselmo	Donato	Briones	Rosell	1985-05-31	F	3149321344	anselmo.briones997@email.com	P052	755	68	170	517	19	170
1437424175	CC	Eugenia	Jose Luis	Villalba	Herranz	1966-03-27	F	3146857410	eugenia.villalba727@email.com	P053	770	68	170	532	19	170
1088643075	CC	Priscila	Rodrigo	Toledo	Ortiz	1983-01-18	M	3220787461	priscila.toledo499@email.com	P054	773	68	170	533	19	170
1119413734	CC	Emigdio	Amando	Nadal	Cantón	1991-07-07	F	3071234273	emigdio.nadal821@email.com	P055	780	68	170	548	19	170
1710773466	CC	Jovita	Anunciación	Alcolea	Rueda	2005-04-01	M	3139210879	jovita.alcolea200@email.com	P056	820	68	170	573	19	170
1933857688	CC	Moisés	Rufina	Espejo	Sedano	2003-12-14	F	3175147006	moisés.espejo990@email.com	P057	855	68	170	585	19	170
1195221307	CC	Gloria	Aránzazu	Garcés	Donaire	1967-09-17	F	3071531730	gloria.garcés996@email.com	P058	861	68	170	622	19	170
1442612148	CC	Cruz	Faustino	Valbuena	Clemente	1997-03-20	F	3075669952	cruz.valbuena82@email.com	P059	867	68	170	693	19	170
1380446558	CC	Dalila	Azahar	Ríos	Coronado	1986-05-21	F	3279125202	dalila.ríos501@email.com	P060	872	68	170	698	19	170
1111278013	CC	Luisina	Marc	Pineda	Ledesma	1954-06-25	F	3290015899	luisina.pineda962@email.com	P061	895	68	170	701	19	170
1442474058	CC	Prudencia	Beatriz	Lucena	Rey	1958-09-17	M	3144341128	prudencia.lucena423@email.com	P062	1	70	170	743	19	170
1967534109	CC	Amarilis	Gertrudis	Caballero	Ayuso	1997-04-30	F	3050928937	amarilis.caballero773@email.com	P063	110	70	170	760	19	170
1861779775	CC	Rómulo	Mónica	Miralles	Iriarte	1976-12-29	M	3255682887	rómulo.miralles399@email.com	P064	124	70	170	780	19	170
1299000007	CC	Demetrio	Perlita	Cuéllar	Mur	1987-10-06	F	3269290122	demetrio.cuéllar863@email.com	P065	204	70	170	807	19	170
1462746917	CC	Zaira	Sebastián	Gelabert	Torrents	1995-12-13	F	3228576049	zaira.gelabert387@email.com	P066	215	70	170	809	19	170
1541562641	CC	Manuel	Natanael	Matas	Vilar	1968-08-19	M	3299216260	manuel.matas201@email.com	P067	230	70	170	821	19	170
1555400495	CC	Loreto	Ainara	Vera	Alarcón	1957-05-12	M	3158707545	loreto.vera578@email.com	P068	235	70	170	824	19	170
1359659846	CC	Marino	Clímaco	Español	Alegria	1957-06-27	F	3113429753	marino.español970@email.com	P069	265	70	170	845	19	170
1687572908	CC	Osvaldo	Salvador	Sanjuan	Meléndez	1987-10-31	M	3262335218	osvaldo.sanjuan838@email.com	P070	400	70	170	1	20	170
1719082056	CC	Baudelio	Jacinto	Asenjo	Ibañez	1957-06-01	F	3069724346	baudelio.asenjo54@email.com	P071	418	70	170	11	20	170
1143369868	CC	Jose Ramón	Amando	Morata	Solera	1981-02-04	F	3284347328	jose ramón.morata587@email.com	P072	429	70	170	13	20	170
1864988543	CC	Esperanza	Manuela	Bonet	Villalobos	1989-12-29	M	3059562063	esperanza.bonet25@email.com	P073	473	70	170	32	20	170
1011656806	CC	Curro	Jenaro	Lozano	Pina	1961-06-16	M	3165234181	curro.lozano774@email.com	P074	508	70	170	45	20	170
1655144467	CC	Edelmira	Armida	Pomares	Pons	1955-12-22	M	3197240041	edelmira.pomares814@email.com	P075	523	70	170	60	20	170
1986654680	CC	Valentina	Amor	Sánchez	Suarez	1993-06-17	F	3136191558	valentina.sánchez992@email.com	P076	670	70	170	175	20	170
1239326720	CC	Isaías	Odalis	Almansa	Soria	1966-03-23	F	3046202920	isaías.almansa356@email.com	P077	678	70	170	178	20	170
1366112668	CC	Cándida	Ainara	Elorza	Gaya	1999-05-20	M	3281705539	cándida.elorza115@email.com	P078	702	70	170	228	20	170
1856696231	CC	Jacinta	Celia	Arenas	Haro	1986-04-13	M	3248250508	jacinta.arenas599@email.com	P079	708	70	170	238	20	170
1571598297	CC	Chuy	María Belén	Alcántara	Ripoll	1960-12-21	M	3277111685	chuy.alcántara521@email.com	P080	713	70	170	250	20	170
1376862852	CC	Amaro	Toni	Sacristán	Bejarano	1993-10-01	M	3239475453	amaro.sacristán971@email.com	P081	717	70	170	295	20	170
1820095877	CC	Angelita	Elodia	Jódar	Camacho	1964-08-14	M	3266325143	angelita.jódar923@email.com	P082	742	70	170	310	20	170
1442376546	CC	Ester	Ainara	Tolosa	Garmendia	2000-08-25	F	3138041447	ester.tolosa182@email.com	P083	771	70	170	383	20	170
1874478079	CC	Abigaíl	Adela	Gomis	Heredia	2002-03-17	F	3150679661	abigaíl.gomis115@email.com	P084	820	70	170	400	20	170
1621614691	CC	Cándido	Inocencio	Iglesias	Canals	1955-01-15	M	3018708982	cándido.iglesias220@email.com	P085	823	70	170	443	20	170
1139897521	CC	Caridad	Alejandro	Rosell	Gibert	1975-11-05	M	3185383931	caridad.rosell885@email.com	P086	1	73	170	517	20	170
1821927871	CC	Damián	Rogelio	Carbonell	Campoy	1983-07-06	F	3020198495	damián.carbonell469@email.com	P087	24	73	170	550	20	170
1363730596	CC	Mateo	Albano	Baeza	Arnal	1978-01-15	F	3047107281	mateo.baeza802@email.com	P088	26	73	170	570	20	170
1591086503	CC	Quirino	Rosendo	Tejedor	Gual	2005-12-03	M	3120047811	quirino.tejedor512@email.com	P089	30	73	170	614	20	170
1695781733	CC	Vasco	Godofredo	Casanova	Peláez	1970-07-26	F	3266448697	vasco.casanova2@email.com	P090	43	73	170	621	20	170
1122105706	CC	Celestino	Anita	Nicolau	Ramos	1975-08-24	F	3230294762	celestino.nicolau639@email.com	P091	55	73	170	710	20	170
1975658460	CC	Alba	Felipa	Manuel	Cabo	1971-12-24	F	3116041179	alba.manuel699@email.com	P092	67	73	170	750	20	170
1571228573	CC	Brunilda	Felicidad	Aragón	Mateos	2006-07-03	F	3277574191	brunilda.aragón612@email.com	P093	124	73	170	770	20	170
1621840263	CC	Ciriaco	Ema	Bou	Posada	1960-03-12	F	3146420310	ciriaco.bou576@email.com	P094	148	73	170	787	20	170
1964949787	CC	Loreto	Jordi	Fuertes	Contreras	1989-02-08	F	3017241790	loreto.fuertes32@email.com	P095	152	73	170	1	23	170
1199987525	CC	Blanca	Ani	Elorza	Santamaría	1960-06-08	M	3064448739	blanca.elorza468@email.com	P096	168	73	170	68	23	170
1813214662	CC	Juan	Jose Francisco	Alfaro	Díaz	1954-08-30	M	3294715594	juan.alfaro141@email.com	P097	200	73	170	79	23	170
1436847990	CC	Vera	Francisco Jose	Ponce	Gascón	1997-03-01	M	3161292418	vera.ponce201@email.com	P098	217	73	170	90	23	170
1294516891	CC	Encarna	Lope	Hierro	Mascaró	1996-04-03	M	3146577497	encarna.hierro830@email.com	P099	226	73	170	162	23	170
1088805626	CC	Ciríaco	Belén	Falcó	Rueda	1960-11-07	M	3033752319	ciríaco.falcó641@email.com	P100	236	73	170	168	23	170
1701051181	CC	Santiago	Salomé	Barbero	Rodrigo	1975-01-16	F	3048902742	santiago.barbero34@email.com	P101	268	73	170	182	23	170
1830887168	CC	Adelia	Nilo	Medina	Roura	1969-11-07	F	3213752748	adelia.medina580@email.com	P102	270	73	170	189	23	170
1510700549	CC	Gonzalo	Gala	Aguiló	Carro	1999-02-17	M	3031706093	gonzalo.aguiló56@email.com	P103	275	73	170	300	23	170
1199456789	CC	Alejandra	Teo	Ferrera	Dueñas	1987-09-11	F	3036620913	alejandra.ferrera680@email.com	P104	283	73	170	350	23	170
1509714482	CC	Borja	Buenaventura	Guardia	Piña	1955-11-21	M	3158266939	borja.guardia311@email.com	P105	319	73	170	417	23	170
1510894978	CC	Jorge	Amador	Hernández	Iglesia	1997-03-13	F	3120081896	jorge.hernández92@email.com	P106	347	73	170	419	23	170
1980881760	CC	Erasmo	Ana	Iñiguez	Alemán	1986-08-15	F	3094757794	erasmo.iñiguez733@email.com	P107	349	73	170	464	23	170
1943259251	CC	Zaira	Natalio	Arrieta	Vilanova	1999-11-20	F	3017051948	zaira.arrieta141@email.com	P108	352	73	170	466	23	170
1870834253	CC	Eulalia	Aurora	Juan	Avilés	1983-08-10	F	3046985818	eulalia.juan633@email.com	P109	408	73	170	500	23	170
1699925762	CC	Ruperto	Aroa	Jaume	Barrera	2006-07-21	M	3173609964	ruperto.jaume596@email.com	P110	411	73	170	555	23	170
1267264779	CC	Nicolás	Azeneth	Borrell	Pombo	1989-05-14	F	3271294634	nicolás.borrell699@email.com	P111	443	73	170	570	23	170
1495117847	CC	Jennifer	Victoriano	Torrent	Roura	1972-05-16	M	3238004177	jennifer.torrent169@email.com	P112	449	73	170	574	23	170
1231972965	CC	Pepe	Jose Carlos	Sotelo	Adadia	1964-08-01	M	3161333164	pepe.sotelo875@email.com	P113	461	73	170	580	23	170
1237908809	CC	Fabián	Fito	Molins	Ordóñez	1973-10-14	M	3262396306	fabián.molins353@email.com	P114	483	73	170	586	23	170
1522154916	CC	Bautista	Felisa	Teruel	Arrieta	1981-03-25	M	3222346994	bautista.teruel984@email.com	P115	504	73	170	660	23	170
1432197728	CC	Adora	Jose Ignacio	Barba	Cuenca	1979-05-05	M	3030253722	adora.barba920@email.com	P116	520	73	170	670	23	170
1083365529	CC	Sara	Carmina	Mata	López	1980-03-25	M	3211397587	sara.mata781@email.com	P117	547	73	170	672	23	170
1507109036	CC	Jeremías	Edu	Puente	Aragón	2005-03-13	M	3048701564	jeremías.puente851@email.com	P118	555	73	170	675	23	170
1279268739	CC	Regina	Miguel	Lozano	Gargallo	1986-04-25	M	3073081052	regina.lozano659@email.com	P119	563	73	170	678	23	170
1545358425	CC	Angelino	Nuria	Caro	Correa	1962-11-15	M	3217255211	angelino.caro92@email.com	P120	585	73	170	686	23	170
1413715354	CC	Alicia	Clímaco	Frutos	Escamilla	1983-12-12	F	3235123358	alicia.frutos670@email.com	P121	616	73	170	807	23	170
1823172520	CC	Liliana	Dominga	Montero	Mínguez	1958-08-16	F	3183510597	liliana.montero789@email.com	P122	622	73	170	855	23	170
1052844712	CC	Máximo	Saturnina	Torres	Escudero	1961-07-02	M	3057521448	máximo.torres15@email.com	P123	624	73	170	1	25	170
1794112238	CC	Isaac	Reynaldo	Canales	Plaza	1954-09-19	M	3025379639	isaac.canales938@email.com	P124	671	73	170	19	25	170
1000870160	CC	Isabel	Benigna	Montalbán	Ramos	1983-03-02	F	3023274046	isabel.montalbán638@email.com	P125	675	73	170	35	25	170
1096896535	CC	Josefina	Jacinta	Jiménez	Aragonés	1960-09-29	F	3026613315	josefina.jiménez577@email.com	P126	678	73	170	40	25	170
1321337758	CC	Paca	Adoración	Bertrán	Sainz	1990-01-28	F	3243238229	paca.bertrán446@email.com	P127	686	73	170	53	25	170
1239906441	CC	Pepito	Susanita	Villalobos	Chaves	1998-06-06	F	3119002558	pepito.villalobos204@email.com	P128	770	73	170	86	25	170
1950694293	CC	Eligia	Elías	Murcia	Sáenz	1965-03-17	F	3183085915	eligia.murcia943@email.com	P129	854	73	170	95	25	170
1399315913	CC	Jose Antonio	Natalia	Baños	Granados	1982-01-26	M	3097494496	jose antonio.baños507@email.com	P130	861	73	170	99	25	170
1984555983	CC	Lilia	Paulino	Viñas	Fuentes	1955-11-23	F	3067249579	lilia.viñas712@email.com	P131	870	73	170	120	25	170
1439304843	CC	Rafa	Odalys	Sanjuan	Miralles	1989-01-04	F	3038527207	rafa.sanjuan30@email.com	P132	873	73	170	123	25	170
1645531860	CC	Eleuterio	Ruperta	Ordóñez	Viñas	1959-06-04	M	3035905831	eleuterio.ordóñez985@email.com	P133	1	76	170	126	25	170
1714708006	CC	Poncio	Filomena	Bravo	Llabrés	1961-03-04	F	3151627104	poncio.bravo989@email.com	P134	20	76	170	148	25	170
1613350223	CC	Reynaldo	Carina	Bautista	Plana	1977-06-14	M	3174981135	reynaldo.bautista966@email.com	P135	36	76	170	151	25	170
1613706477	CC	Alexandra	Ramona	Vidal	Escobar	1994-04-12	M	3056417037	alexandra.vidal861@email.com	P136	41	76	170	154	25	170
1805573048	CC	María Ángeles	Alfredo	Exposito	Toro	1998-07-30	F	3187644104	maría ángeles.exposito154@email.com	P137	54	76	170	168	25	170
1670827695	CC	Alicia	Gil	Zaragoza	Murcia	1984-07-27	M	3246406471	alicia.zaragoza458@email.com	P138	100	76	170	175	25	170
1995987692	CC	Alondra	Baudelio	Llopis	Martinez	1973-03-12	M	3161644520	alondra.llopis281@email.com	P139	109	76	170	178	25	170
1139054937	CC	Jennifer	Juan Luis	Llano	Pont	1969-04-26	F	3078032963	jennifer.llano421@email.com	P140	111	76	170	181	25	170
1502718213	CC	Jonatan	Andrés	Escobar	Bueno	1988-12-11	M	3272852276	jonatan.escobar569@email.com	P141	113	76	170	183	25	170
1686665736	CC	Natividad	Plinio	Simó	Moya	1961-08-18	M	3283158784	natividad.simó299@email.com	P142	122	76	170	200	25	170
1491339221	CC	Begoña	Cayetano	Roig	Olivé	1967-03-06	F	3073542067	begoña.roig155@email.com	P143	126	76	170	214	25	170
1210490966	CC	Bartolomé	Pepita	Baeza	Márquez	2005-10-02	F	3271061297	bartolomé.baeza443@email.com	P144	130	76	170	224	25	170
1018400501	CC	Teodora	Judith	Arana	Hernandez	1962-06-29	M	3194586345	teodora.arana259@email.com	P145	147	76	170	245	25	170
1663261054	CC	Eugenio	Ignacia	Alsina	Talavera	1962-10-03	F	3230254390	eugenio.alsina657@email.com	P146	233	76	170	258	25	170
1198065331	CC	Dionisio	Marc	Jáuregui	Marquez	2006-08-31	M	3253485809	dionisio.jáuregui959@email.com	P147	243	76	170	260	25	170
1050706327	CC	Juanito	Paulino	Ureña	Gimenez	1957-07-20	M	3133197064	juanito.ureña628@email.com	P148	246	76	170	269	25	170
1937718540	CC	Sancho	Melania	Lozano	Carreño	1969-02-14	F	3215138907	sancho.lozano958@email.com	P149	248	76	170	279	25	170
1647327136	CC	Luna	Fortunato	Cadenas	Conesa	1998-06-05	M	3045680203	luna.cadenas530@email.com	P150	250	76	170	281	25	170
1281847534	CC	Cayetana	Wálter	Ripoll	Pou	1975-06-15	M	3126329377	cayetana.ripoll182@email.com	P151	275	76	170	286	25	170
1755175228	CC	Joaquín	René	Palomino	Nicolau	1978-07-12	M	3181505796	joaquín.palomino566@email.com	P152	306	76	170	288	25	170
1072335027	CC	Inés	Fausto	Tormo	Salmerón	2001-04-23	M	3270498460	inés.tormo722@email.com	P153	318	76	170	290	25	170
1760848681	CC	Alma	Alcides	Solsona	Gimenez	1976-01-09	M	3299688699	alma.solsona522@email.com	P154	364	76	170	293	25	170
1353645829	CC	Marcelo	Dimas	Rey	Egea	1988-06-16	M	3196158934	marcelo.rey421@email.com	P155	377	76	170	295	25	170
1694607361	CC	Fortunata	Vinicio	Coloma	Pedro	1982-01-29	F	3120513243	fortunata.coloma713@email.com	P156	400	76	170	297	25	170
1986355273	CC	Josefina	Godofredo	Tirado	Alberola	1982-08-16	F	3159049063	josefina.tirado196@email.com	P157	403	76	170	299	25	170
1211053734	CC	Luis Miguel	Rebeca	Mur	Alvarez	1957-08-30	M	3281778703	luis miguel.mur913@email.com	P158	497	76	170	307	25	170
1002146231	CC	Gerónimo	Aitor	Canet	Manzanares	1979-11-25	F	3076821843	gerónimo.canet788@email.com	P159	520	76	170	312	25	170
1911255137	CC	Evangelina	José Manuel	León	Salcedo	1978-06-08	M	3235271072	evangelina.león415@email.com	P160	563	76	170	317	25	170
1978685872	CC	Santos	Marianela	Alberdi	Cuadrado	1977-11-12	F	3025171221	santos.alberdi26@email.com	P161	606	76	170	320	25	170
1368803170	CC	Moreno	Isidoro	Adán	Galvez	1967-04-18	M	3170617554	moreno.adán448@email.com	P162	616	76	170	322	25	170
1609159942	CC	Filomena	Fabián	Redondo	Rios	1986-12-24	M	3048253865	filomena.redondo809@email.com	P163	622	76	170	324	25	170
1568768145	CC	Nicodemo	Roxana	Jordá	Miguel	2007-02-28	F	3197061919	nicodemo.jordá589@email.com	P164	670	76	170	326	25	170
1950949916	CC	Josefina	Carina	Antúnez	Pozuelo	1983-07-27	M	3125769044	josefina.antúnez231@email.com	P165	736	76	170	328	25	170
1308282366	CC	Clementina	Poncio	Roca	Oller	1999-07-05	F	3257330176	clementina.roca894@email.com	P166	823	76	170	335	25	170
1474943875	CC	Melchor	Nacio	Corral	Simó	1969-11-22	M	3018363392	melchor.corral685@email.com	P167	828	76	170	339	25	170
1612265195	CC	Guiomar	Gonzalo	Sevilla	Quintero	1960-10-27	M	3068425563	guiomar.sevilla531@email.com	P168	834	76	170	368	25	170
1023592004	CC	Haydée	Maxi	Fuente	Gonzalo	2001-07-15	M	3062649485	haydée.fuente406@email.com	P169	845	76	170	372	25	170
1358806381	CC	Cecilia	Nazaret	Pastor	Tamayo	1986-03-19	F	3118442841	cecilia.pastor245@email.com	P170	863	76	170	377	25	170
1657995847	CC	Candela	Palmira	Briones	Pedrero	1971-03-02	F	3045685191	candela.briones387@email.com	P001	869	76	170	386	25	170
1157874199	CC	Fito	Severiano	Mayo	Morcillo	1970-07-15	F	3281724267	fito.mayo110@email.com	P001	890	76	170	394	25	170
1325587681	CC	Jeremías	Coral	Gámez	Expósito	1968-09-07	F	3179749943	jeremías.gámez825@email.com	P001	892	76	170	398	25	170
1587199660	CC	Bruno	Anselmo	Soler	Laguna	1987-08-19	M	3060940425	bruno.soler639@email.com	P001	895	76	170	402	25	170
1753307746	CC	José Ángel	Raquel	Amador	Garriga	1976-09-04	M	3286082661	josé ángel.amador889@email.com	P001	1	81	170	407	25	170
1761625456	CC	Goyo	Sebastian	Lozano	Cazorla	2003-06-16	F	3287497400	goyo.lozano340@email.com	P001	65	81	170	426	25	170
1562541291	CC	Fabio	Ovidio	Bejarano	Meléndez	1962-02-24	F	3241796657	fabio.bejarano879@email.com	P001	220	81	170	430	25	170
1990881817	CC	José María	Aureliano	Baquero	Iborra	1966-08-02	F	3135244833	josé maría.baquero118@email.com	P001	300	81	170	436	25	170
1388347562	CC	Porfirio	Natividad	Pérez	Mata	1985-10-10	M	3013023612	porfirio.pérez911@email.com	P001	591	81	170	438	25	170
1396202298	CC	José Luis	Che	Clemente	Viana	1986-05-21	F	3276136350	josé luis.clemente845@email.com	P001	736	81	170	473	25	170
1648465711	CC	Eligia	Zacarías	Macías	Guerra	1954-07-02	F	3253027694	eligia.macías558@email.com	P001	794	81	170	483	25	170
1424594860	CC	Juan Francisco	Adoración	Monreal	Viña	1956-01-06	M	3116685727	juan francisco.monreal943@email.com	P001	1	85	170	486	25	170
1467647935	CC	Esmeralda	Casemiro	Carreño	Gálvez	1960-09-12	M	3043992273	esmeralda.carreño336@email.com	P001	10	85	170	488	25	170
1236639572	CC	Eligio	Valentín	Tejera	Meléndez	2006-02-08	F	3230839810	eligio.tejera455@email.com	P001	15	85	170	489	25	170
1166464562	CC	Herminia	Timoteo	Berenguer	Bernal	1965-08-29	F	3113982936	herminia.berenguer627@email.com	P001	125	85	170	491	25	170
1536886603	CC	Heriberto	Andrés Felipe	Talavera	Elorza	2005-10-19	F	3060149282	heriberto.talavera139@email.com	P001	136	85	170	506	25	170
1803622436	CC	Leonardo	Geraldo	Vicente	Espada	1989-11-17	F	3284199856	leonardo.vicente300@email.com	P001	139	85	170	513	25	170
1305715290	CC	Fortunata	Valeria	Colom	Barral	1969-05-31	M	3052633274	fortunata.colom703@email.com	P001	162	85	170	518	25	170
1192106508	CC	Bárbara	Almudena	Zaragoza	Jódar	1977-07-20	M	3273008035	bárbara.zaragoza519@email.com	P001	225	85	170	524	25	170
1185322026	CC	María Del Carmen	Graciela	Somoza	Cerdán	1970-12-16	M	3124815135	maría del carmen.somoza171@email.com	P001	230	85	170	530	25	170
1998351390	CC	Isidro	Ruperta	Landa	Gabaldón	1981-05-02	F	3140092056	isidro.landa567@email.com	P001	250	85	170	535	25	170
1328061359	CC	Leonardo	Lupita	Heras	Enríquez	1994-03-04	M	3288599864	leonardo.heras703@email.com	P001	263	85	170	572	25	170
1878391263	CC	Adela	Norberto	Prieto	Cabrero	1958-01-29	M	3186576276	adela.prieto419@email.com	P001	279	85	170	580	25	170
1488105904	CC	Diego	Herminio	Yáñez	Granados	1962-01-09	F	3141350420	diego.yáñez733@email.com	P001	300	85	170	592	25	170
1784761824	CC	Clementina	Luisina	Garay	Artigas	1968-07-14	F	3113430288	clementina.garay603@email.com	P001	315	85	170	594	25	170
1578850193	CC	Moreno	María José	Valencia	Giralt	1998-12-19	F	3025566223	moreno.valencia553@email.com	P001	325	85	170	596	25	170
1992120364	CC	Fernanda	Rubén	Carmona	Correa	1983-09-29	F	3257973029	fernanda.carmona966@email.com	P001	400	85	170	599	25	170
1483661870	CC	Custodia	Eustaquio	Herrera	Godoy	1955-02-27	F	3188727844	custodia.herrera373@email.com	P001	410	85	170	612	25	170
1578483551	CC	Eli	Dalila	Mayoral	Salazar	2004-03-16	F	3191582450	eli.mayoral224@email.com	P001	430	85	170	645	25	170
1551264605	CC	Guadalupe	Úrsula	Rocha	Roman	1968-04-13	F	3254932363	guadalupe.rocha757@email.com	P001	440	85	170	649	25	170
1031020990	CC	Salomé	Blanca	Jimenez	Carvajal	1977-12-26	M	3229819678	salomé.jimenez904@email.com	P001	1	86	170	653	25	170
1277610916	CC	Mariana	Miguel	Alberdi	Calatayud	1982-06-06	F	3095415118	mariana.alberdi942@email.com	P001	219	86	170	658	25	170
1474494048	CC	Cruz	Ale	Bautista	Bejarano	1987-08-03	F	3151649846	cruz.bautista505@email.com	P001	320	86	170	662	25	170
1168963198	CC	José Antonio	Inocencio	Vallés	Barroso	1983-06-06	M	3196750899	josé antonio.vallés390@email.com	P001	568	86	170	718	25	170
1571693843	CC	Fortunata	Marino	Verdú	Miralles	1979-05-22	F	3243478749	fortunata.verdú173@email.com	P001	569	86	170	736	25	170
1578626266	CC	Quirino	Fabiana	Elorza	Torralba	1956-12-09	F	3194340387	quirino.elorza469@email.com	P001	571	86	170	740	25	170
1062857078	CC	Victor Manuel	Marciano	Berrocal	Bautista	1991-09-19	F	3292423067	victor manuel.berrocal991@email.com	P001	573	86	170	743	25	170
1440305191	CC	Elodia	Albino	Ricart	Martinez	1993-09-22	F	3079054993	elodia.ricart687@email.com	P001	749	86	170	745	25	170
1899856893	CC	Jose Carlos	Juan Pablo	Batlle	Guerra	1968-06-27	M	3155566757	jose carlos.batlle102@email.com	P001	755	86	170	754	25	170
1252084894	CC	Pedro	Paloma	Ribes	Benítez	1971-01-20	M	3060436420	pedro.ribes454@email.com	P001	757	86	170	758	25	170
1414197673	CC	Prudencia	Adelia	Zapata	Isern	1982-11-25	F	3040044918	prudencia.zapata645@email.com	P001	760	86	170	769	25	170
1470422413	CC	Ruperto	Nazario	Fuster	Morales	1996-02-22	F	3177942432	ruperto.fuster479@email.com	P001	865	86	170	772	25	170
1082191878	CC	Reinaldo	Adelia	Guerrero	Castells	2006-02-22	F	3031778733	reinaldo.guerrero341@email.com	P001	885	86	170	777	25	170
1732657002	CC	Flavio	Eric	Velázquez	Mateu	1976-03-07	F	3283798481	flavio.velázquez360@email.com	P001	1	88	170	779	25	170
1574427027	CC	Dora	Jafet	Valcárcel	Paz	1993-01-20	F	3231826621	dora.valcárcel569@email.com	P001	564	88	170	781	25	170
1658984624	CC	Zacarías	Lucio	Sevilla	Cuesta	1954-12-17	M	3133095827	zacarías.sevilla375@email.com	P001	1	91	170	785	25	170
1544010276	CC	Daniel	Roberto	Iniesta	Aller	2000-06-04	M	3065002460	daniel.iniesta67@email.com	P001	263	91	170	793	25	170
1626056800	CC	Débora	Dominga	Hervia	Asenjo	1958-03-02	M	3284920565	débora.hervia451@email.com	P001	405	91	170	797	25	170
1956766836	CC	Natalia	Soraya	Delgado	Mir	1957-01-04	F	3011861483	natalia.delgado671@email.com	P001	407	91	170	799	25	170
1176079127	CC	Benigna	Verónica	Peñas	Llabrés	1985-05-11	M	3191112246	benigna.peñas635@email.com	P001	430	91	170	805	25	170
1495543809	CC	Rubén	Albina	Carreño	Neira	1973-06-21	F	3195267447	rubén.carreño475@email.com	P001	460	91	170	807	25	170
1605202931	CC	Salomé	Rico	Cózar	Téllez	1987-07-15	F	3055056386	salomé.cózar229@email.com	P001	530	91	170	815	25	170
1640774548	CC	Delia	Aníbal	Viña	Escobar	1983-06-03	M	3042564179	delia.viña128@email.com	P001	536	91	170	817	25	170
1201551582	CC	Soledad	Chus	Calzada	Ayuso	1989-02-04	M	3183717145	soledad.calzada878@email.com	P001	540	91	170	823	25	170
1452286373	CC	Vicente	Lázaro	Nuñez	Coll	1955-08-04	F	3083694973	vicente.nuñez677@email.com	P001	669	91	170	839	25	170
1313771754	CC	Toño	Nadia	Lobo	Sanz	1990-08-31	M	3016964385	toño.lobo198@email.com	P001	798	91	170	841	25	170
1992281317	CC	Jacobo	Celso	Espada	Nicolau	1960-04-26	M	3072621068	jacobo.espada883@email.com	P001	1	94	170	843	25	170
1886735014	CC	Florencio	Natalio	Porta	Atienza	1994-06-07	M	3118645593	florencio.porta15@email.com	P001	343	94	170	845	25	170
1248512341	CC	Mohamed	Luciano	Iriarte	Porcel	1994-01-27	F	3183575655	mohamed.iriarte42@email.com	P001	883	94	170	851	25	170
1332502644	CC	Yago	Blanca	Prat	Ariño	1978-01-08	F	3286667891	yago.prat244@email.com	P001	884	94	170	862	25	170
1455765827	CC	Eulalia	Jorge	Medina	Cano	1965-01-14	F	3137298808	eulalia.medina953@email.com	P001	885	94	170	867	25	170
1174606746	CC	Lorenza	Sosimo	Rios	Tomé	1995-09-13	F	3029423361	lorenza.rios222@email.com	P001	886	94	170	871	25	170
1494316518	CC	Albert	Efraín	Pons	Vazquez	1960-12-07	F	3125146196	albert.pons953@email.com	P001	887	94	170	873	25	170
1245472987	CC	Néstor	Manuelita	Segovia	Ayala	1991-06-13	M	3040818109	néstor.segovia874@email.com	P001	888	94	170	875	25	170
1071395953	CC	Adolfo	Graciano	Garzón	Peiró	1991-01-22	F	3027112674	adolfo.garzón692@email.com	P001	1	95	170	878	25	170
1551932827	CC	Cintia	Damián	Soriano	Casals	1977-04-18	F	3237017640	cintia.soriano982@email.com	P001	15	95	170	885	25	170
1642667246	CC	Olalla	Milagros	Jover	Girona	1998-07-25	M	3180177885	olalla.jover568@email.com	P001	25	95	170	898	25	170
1727393899	CC	Sabas	Javier	Galiano	Guitart	1965-01-11	F	3090826773	sabas.galiano96@email.com	P001	200	95	170	899	25	170
1307883935	CC	María Luisa	Trinidad	Huertas	Montserrat	2001-02-03	F	3117743750	maría luisa.huertas250@email.com	P001	1	97	170	1	27	170
1789385552	CC	Marc	Jordán	Abellán	Ferreras	2000-11-25	M	3126767395	marc.abellán663@email.com	P001	161	97	170	6	27	170
1415507074	CC	Carmelo	Rodrigo	Aragón	Casal	1968-12-14	M	3099335781	carmelo.aragón652@email.com	P001	511	97	170	25	27	170
1413632459	CC	Pepe	Carina	Cervera	Gimeno	1977-01-06	F	3167905456	pepe.cervera8@email.com	P001	666	97	170	50	27	170
1194798718	CC	Ildefonso	Jonatan	Iborra	Águila	1964-09-07	M	3018852564	ildefonso.iborra589@email.com	P001	777	97	170	73	27	170
1277045134	CC	Vera	Macaria	Ramirez	Bustamante	1984-12-01	F	3126570776	vera.ramirez484@email.com	P001	889	97	170	75	27	170
1415015727	CC	Florentino	María Luisa	Barragán	Abella	1954-05-28	M	3219418717	florentino.barragán603@email.com	P001	1	99	170	77	27	170
1642289215	CC	Paula	Sandalio	Frutos	Gomis	1973-06-12	M	3156071389	paula.frutos607@email.com	P001	524	99	170	99	27	170
1205412033	CC	Felipe	Eva	Linares	Chaparro	1974-08-07	M	3062429855	felipe.linares613@email.com	P001	572	99	170	135	27	170
1810818755	CC	Elpidio	Eladio	Ramos	Arnaiz	1975-08-27	M	3157284908	elpidio.ramos121@email.com	P240	666	99	170	205	27	170
1426236851	CC	Zaida	Ricardo	Palomo	Ballester	1983-02-27	M	3166628788	zaida.palomo804@email.com	P241	760	99	170	245	27	170
1601897389	CC	Eli	Olivia	Tudela	Soto	1965-12-24	M	3010753357	eli.tudela848@email.com	P242	773	99	170	250	27	170
1234585411	CC	Máximo	María Teresa	Estévez	Carro	2000-02-09	F	3054410777	máximo.estévez505@email.com	P243	1	5	170	361	27	170
1046624326	CC	Paola	Jose	Monreal	Tamayo	1990-09-05	M	3250456989	paola.monreal468@email.com	P244	2	5	170	372	27	170
1236849408	CC	Victoriano	Quirino	Antón	Morante	1993-07-24	F	3282796148	victoriano.antón665@email.com	P245	4	5	170	413	27	170
1337266878	CC	Ildefonso	Cebrián	Montserrat	Guardia	1983-07-24	F	3161874349	ildefonso.montserrat668@email.com	P246	21	5	170	425	27	170
1731720996	CC	Rosario	Mohamed	Checa	Sotelo	1973-05-24	F	3192370759	rosario.checa294@email.com	P247	30	5	170	430	27	170
1914639997	CC	Teo	Maite	Iriarte	Doménech	1981-01-30	M	3088536539	teo.iriarte151@email.com	P248	31	5	170	491	27	170
1041590655	CC	Emilio	Elvira	Martinez	Lobo	1987-06-30	F	3191986447	emilio.martinez609@email.com	P249	34	5	170	495	27	170
1701288521	CC	Alfonso	Eliseo	Girón	Capdevila	1961-10-28	M	3037093552	alfonso.girón242@email.com	P250	36	5	170	600	27	170
1235249346	CC	Julia	Zoraida	Abad	Acosta	1997-03-28	F	3128800013	julia.abad978@email.com	P251	38	5	170	615	27	170
1584108407	CC	León	Galo	Prieto	Verdejo	1957-07-02	F	3164177054	león.prieto553@email.com	P252	40	5	170	660	27	170
1209332177	CC	Bienvenida	Valentín	Cabo	Sancho	1983-10-15	M	3190963959	bienvenida.cabo652@email.com	P253	42	5	170	745	27	170
1557437446	CC	Apolonia	Cebrián	Ripoll	Ferreras	1997-05-19	F	3163834955	apolonia.ripoll772@email.com	P254	44	5	170	787	27	170
1703765726	CC	Luis Miguel	María Luisa	Torrens	Martí	2002-11-29	F	3240381121	luis miguel.torrens160@email.com	P255	45	5	170	800	27	170
1831045870	CC	Ruperta	Isabel	Herrera	Rivero	2005-10-29	M	3155003796	ruperta.herrera947@email.com	P256	51	5	170	810	27	170
1235064700	CC	Cruz	Otilia	Pareja	Galvez	1969-05-04	M	3111680161	cruz.pareja94@email.com	P257	55	5	170	1	41	170
1213890114	CC	Emiliana	Almudena	Riba	Giralt	1993-09-29	M	3061901586	emiliana.riba169@email.com	P258	59	5	170	6	41	170
1059671117	CC	Tomasa	Verónica	Cuervo	Villaverde	1972-10-29	M	3181833873	tomasa.cuervo500@email.com	P259	79	5	170	13	41	170
1850255796	CC	Amancio	Cruz	Gascón	Elías	1982-06-08	M	3035288706	amancio.gascón907@email.com	P260	86	5	170	16	41	170
1785079246	CC	Alcides	Ariel	Barranco	Jimenez	1974-09-03	F	3278438338	alcides.barranco81@email.com	P261	88	5	170	20	41	170
1180495136	CC	Luis Miguel	Marc	Morata	Lladó	1969-07-16	F	3197399179	luis miguel.morata509@email.com	P262	91	5	170	26	41	170
1543182694	CC	Demetrio	Micaela	Niño	Gimenez	1958-12-18	F	3091141163	demetrio.niño11@email.com	P263	93	5	170	78	41	170
1405958340	CC	Herminia	Ascensión	Araujo	Niño	1988-02-28	F	3289825087	herminia.araujo753@email.com	P264	101	5	170	132	41	170
1119908493	CC	Celestina	Florencia	Barco	Arce	2000-08-27	F	3272466266	celestina.barco681@email.com	P265	107	5	170	206	41	170
1916170511	CC	Tecla	José Luis	Moll	Pla	1987-08-14	M	3060844707	tecla.moll19@email.com	P266	113	5	170	244	41	170
1883834787	CC	Adelaida	Cristian	Vizcaíno	Egea	1998-02-05	M	3060217375	adelaida.vizcaíno268@email.com	P267	120	5	170	298	41	170
1945227339	CC	José Manuel	Áurea	Juliá	Azorin	1961-08-02	M	3161691677	josé manuel.juliá475@email.com	P268	125	5	170	306	41	170
1006573515	CC	Alejo	Leoncio	Pol	Ortega	1960-08-30	M	3113070849	alejo.pol77@email.com	P269	129	5	170	319	41	170
1699800407	CC	Gaspar	Ale	Varela	Rincón	1960-09-10	F	3244119505	gaspar.varela720@email.com	P270	134	5	170	349	41	170
1994086444	CC	Néstor	Isaura	Dominguez	Ocaña	1987-09-15	F	3232457354	néstor.dominguez75@email.com	P271	138	5	170	357	41	170
1832600762	CC	Ruperta	Marisela	Sans	Cabezas	1961-02-06	M	3068205410	ruperta.sans224@email.com	P272	142	5	170	359	41	170
1971155573	CC	Eusebio	Heraclio	Rocamora	Galan	1973-09-06	M	3092074284	eusebio.rocamora878@email.com	P273	145	5	170	378	41	170
1142970563	CC	Onofre	Nico	Salvador	Tapia	1972-03-03	M	3151382461	onofre.salvador82@email.com	P274	147	5	170	396	41	170
1269151177	CC	Augusto	Áurea	Moreno	Miralles	1975-09-01	F	3139936410	augusto.moreno949@email.com	P275	148	5	170	483	41	170
1137602991	CC	Ligia	Emelina	Baró	Folch	2000-05-28	F	3137863653	ligia.baró616@email.com	P276	150	5	170	503	41	170
1822716682	CC	Dulce	Emiliano	Roma	Galindo	1954-09-08	M	3038225734	dulce.roma647@email.com	P277	154	5	170	518	41	170
1402823531	CC	Ofelia	Epifanio	Revilla	Cordero	1965-10-22	M	3268384368	ofelia.revilla855@email.com	P278	172	5	170	524	41	170
1547276501	CC	Carlota	Amílcar	Pardo	Duarte	1969-11-28	F	3171659621	carlota.pardo597@email.com	P279	190	5	170	530	41	170
1761736523	CC	Dionisio	Clarisa	Jódar	Villar	1988-04-29	F	3132080446	dionisio.jódar240@email.com	P280	197	5	170	548	41	170
1398048968	CC	Ruperta	Norberto	Aller	Alcalde	1992-08-04	F	3124532334	ruperta.aller338@email.com	P281	206	5	170	551	41	170
1002570395	CC	María Luisa	María Teresa	Mateu	Gomis	1975-12-09	M	3033915940	maría luisa.mateu14@email.com	P282	209	5	170	615	41	170
1329678904	CC	Fermín	Fátima	Catalán	Badía	1985-11-25	F	3085795790	fermín.catalán729@email.com	P283	212	5	170	660	41	170
1046591647	CC	Ángeles	Inocencio	Gascón	Gibert	1997-11-08	M	3051125211	ángeles.gascón773@email.com	P284	234	5	170	668	41	170
1300790681	CC	Daniela	Máximo	Serra	Cañas	1966-03-18	M	3132557750	daniela.serra975@email.com	P285	237	5	170	676	41	170
1367062459	CC	Emilio	Melisa	Albero	Román	1966-01-06	M	3049537459	emilio.albero741@email.com	P286	240	5	170	770	41	170
1374009268	CC	Bernardo	Gisela	Barros	Garcia	1978-03-25	F	3058920347	bernardo.barros642@email.com	P287	250	5	170	791	41	170
1184589313	CC	Baltasar	Jordán	Aragón	Ugarte	1967-05-15	M	3085305485	baltasar.aragón563@email.com	P288	264	5	170	797	41	170
1909722646	CC	Angelina	María Cristina	Carlos	Marí	1960-01-12	M	3081230464	angelina.carlos163@email.com	P289	266	5	170	799	41	170
1376934989	CC	Elvira	José Manuel	Mesa	Aroca	2004-09-08	F	3071182978	elvira.mesa609@email.com	P290	282	5	170	801	41	170
1369433003	CC	Macaria	Dani	Goicoechea	Gimenez	1976-06-03	M	3233463673	macaria.goicoechea964@email.com	P291	284	5	170	807	41	170
1089432721	CC	Eusebio	Eduardo	Manzano	Isern	1980-02-08	F	3166007608	eusebio.manzano83@email.com	P292	306	5	170	872	41	170
1696397094	CC	Tomasa	Chema	Costa	Paredes	1954-09-06	M	3150195573	tomasa.costa385@email.com	P293	308	5	170	885	41	170
1936626624	CC	Anastasio	Eusebio	Escamilla	Tirado	1966-02-03	F	3095407051	anastasio.escamilla362@email.com	P294	310	5	170	1	44	170
1946800849	CC	Adolfo	Onofre	Ropero	Cortes	2001-12-11	M	3295325298	adolfo.ropero828@email.com	P295	313	5	170	78	44	170
1165787048	CC	Emma	Camilo	Pelayo	Correa	1973-04-14	M	3099041960	emma.pelayo210@email.com	P296	315	5	170	90	44	170
1700786634	CC	Haydée	Salomé	Ibáñez	Rocha	1981-04-15	M	3189942888	haydée.ibáñez400@email.com	P297	318	5	170	98	44	170
1708460523	CC	Maximino	Jose Francisco	Abella	Frutos	1968-10-30	F	3266401527	maximino.abella11@email.com	P298	321	5	170	110	44	170
1679008766	CC	Isaac	Rosenda	Meléndez	Luque	1965-12-02	F	3092131432	isaac.meléndez557@email.com	P299	347	5	170	279	44	170
1275680457	CC	Armando	Cipriano	Baeza	Bayo	1999-11-10	M	3087278420	armando.baeza154@email.com	P300	353	5	170	378	44	170
1511373862	CC	Tomasa	Dimas	Heredia	Cabezas	1969-09-07	F	3297818453	tomasa.heredia522@email.com	P301	360	5	170	420	44	170
1977242909	CC	Elisabet	Graciana	Heredia	Porcel	1972-03-18	M	3148380685	elisabet.heredia506@email.com	P302	361	5	170	430	44	170
1953721018	CC	Josué	Jafet	Iglesia	Barceló	1968-10-01	F	3238000100	josué.iglesia691@email.com	P303	364	5	170	560	44	170
1457724885	CC	Loreto	Coral	Cornejo	Noguera	1963-11-10	F	3264625091	loreto.cornejo352@email.com	P304	368	5	170	650	44	170
1114594387	CC	Bernardo	Florencia	Fabregat	Saez	1995-03-02	M	3270689304	bernardo.fabregat136@email.com	P305	376	5	170	847	44	170
1493999934	CC	Segismundo	Tecla	Tur	Campillo	2005-09-08	M	3069969419	segismundo.tur964@email.com	P306	380	5	170	855	44	170
1441127179	CC	Marcelino	Encarnación	Gelabert	Iñiguez	1968-05-24	F	3285718000	marcelino.gelabert22@email.com	P307	390	5	170	874	44	170
1512151944	CC	Rosario	Lupe	Llorente	Cabañas	1957-09-14	M	3294648958	rosario.llorente56@email.com	P308	400	5	170	1	47	170
1085335655	CC	Maura	Josep	Río	Bernad	1988-02-19	M	3210441407	maura.río982@email.com	P309	411	5	170	30	47	170
1710884377	CC	Rómulo	Ciríaco	Recio	Menéndez	1982-05-29	F	3019806856	rómulo.recio967@email.com	P310	425	5	170	53	47	170
1037544920	CC	Karen	Lorena	cordoba	Rodriguez	1985-03-15	F	3175849203	Kareniaba@email.com	P001	498	54	170	1	5	170
1024756381	CC	Carlos	Andres	Martinez	Lopez	1990-07-22	M	3012458976	carlos.martinez@email.com	P045	1	5	170	307	25	170
1098765432	CC	Ana	Lucia	Rodriguez	\N	1978-11-12	F	3158742569	ana.rodriguez@email.com	P023	88	5	170	1	11	170
1065432187	CC	Luis	Fernando	Gonzalez	Morales	1982-05-08	M	3209876543	luis.gonzalez@email.com	P156	307	25	170	1	5	170
1032145698	CC	Sandra	\N	Perez	Castro	1987-09-19	F	3174582639	sandra.perez@email.com	P078	1	11	170	1	76	170
1087452963	CC	Miguel	Angel	Vargas	Silva	1975-12-03	M	3145896327	miguel.vargas@email.com	P234	1	76	170	1	8	170
1054789632	CC	Patricia	Elena	Jimenez	\N	1992-06-27	F	3186549872	patricia.jimenez@email.com	P089	1	8	170	88	5	170
1076543219	CC	Roberto	Carlos	Herrera	Diaz	1980-02-14	M	3128754963	roberto.herrera@email.com	P145	1	54	170	1	63	170
1041258963	CC	Carmen	Rosa	Torres	Mendez	1989-08-31	F	3197856423	carmen.torres@email.com	P067	1	63	170	1	68	170
1089634521	CC	Diego	Alejandro	Ramirez	\N	1984-01-05	M	3165847293	diego.ramirez@email.com	P198	1	68	170	1	50	170
1025874136	CC	Esperanza	\N	Moreno	Gutierrez	1991-04-18	F	3178529634	esperanza.moreno@email.com	P112	1	50	170	1	19	170
1073658924	CC	Javier	Esteban	Castillo	Parra	1977-10-09	M	3142587496	javier.castillo@email.com	P287	1	19	170	1	52	170
1048529637	CC	Gloria	Maria	Ortiz	\N	1986-07-26	F	3189745623	gloria.ortiz@email.com	P034	1	52	170	1	20	170
1096325874	CC	Fernando	Jose	Ruiz	Salazar	1983-03-13	M	3156982174	fernando.ruiz@email.com	P178	1	20	170	1	17	170
1036741892	CC	Rosa	Elena	Delgado	Romero	1988-12-21	F	3175486392	rosa.delgado@email.com	P098	1	17	170	1	23	170
1081479632	CC	Andres	Felipe	Vega	Cruz	1979-08-07	M	3124587639	andres.vega@email.com	P256	1	23	170	1	15	170
1057896143	CC	Claudia	\N	Morales	Rivera	1993-05-02	F	3196587412	claudia.morales@email.com	P165	1	15	170	1	18	170
1092583741	CC	Alberto	Mauricio	Contreras	\N	1981-11-16	M	3148529637	alberto.contreras@email.com	P289	1	18	170	1	27	170
1029637485	CC	Luz	Marina	Aguilar	Pineda	1985-09-24	F	3187539624	luz.aguilar@email.com	P076	1	27	170	1	41	170
1074185296	CC	Ricardo	Enrique	Soto	Vargas	1976-06-11	M	3132587419	ricardo.soto@email.com	P198	1	41	170	1	44	170
1045827396	CC	Martha	\N	Guerrero	Sandoval	1990-01-28	F	3174859632	martha.guerrero@email.com	P123	1	44	170	1	47	170
1087419635	CC	Sergio	Camilo	Nunez	Herrera	1984-07-04	M	3158739624	sergio.nunez@email.com	P234	1	47	170	1	70	170
1051963847	CC	Beatriz	Isabel	Medina	\N	1987-02-17	F	3196847253	beatriz.medina@email.com	P087	1	70	170	1	73	170
1098374625	CC	Gustavo	Adolfo	Ramos	Leon	1982-10-25	M	3127458963	gustavo.ramos@email.com	P176	1	73	170	1	66	170
1033741852	CC	Amparo	Cecilia	Flores	Torres	1989-04-12	F	3185974632	amparo.flores@email.com	P145	1	66	170	1	81	170
1086295174	CC	Hector	Manuel	Silva	Mejia	1978-12-29	M	3149637258	hector.silva@email.com	P298	1	81	170	1	85	170
1058149637	CC	Victoria	\N	Cortes	Ospina	1991-08-06	F	3178529641	victoria.cortes@email.com	P067	1	85	170	1	86	170
1091483627	CC	Orlando	Javier	Cardenas	Restrepo	1983-05-23	M	3156847392	orlando.cardenas@email.com	P189	1	86	170	1	88	170
1027395841	CC	Esperanza	Consuelo	Ospina	\N	1986-03-19	F	3192847563	esperanza.ospina@email.com	P134	1	88	170	1	91	170
1075962843	CC	Mauricio	Alejandro	Restrepo	Duarte	1980-09-01	M	3141758439	mauricio.restrepo@email.com	P267	1	91	170	1	94	170
1052847396	CC	Blanca	Stella	Duarte	Pena	1988-11-14	F	3187459632	blanca.duarte@email.com	P098	1	94	170	1	95	170
1084736291	CC	Jairo	Antonio	Pena	Munoz	1977-07-08	M	3123758496	jairo.pena@email.com	P245	1	95	170	1	97	170
1039627485	CC	Cecilia	\N	Munoz	Beltran	1992-06-26	F	3174859637	cecilia.munoz@email.com	P156	1	97	170	1	99	170
1087529641	CC	Eduardo	Ricardo	Beltran	Franco	1985-01-15	M	3158374629	eduardo.beltran@email.com	P234	1	99	170	88	5	170
1007529441	CC	Camila	Andrea	Lopez	Martinez	2005-08-20	F	3195827364	camila.lopez@email.com	P023	88	5	170	1	11	170
1063847291	CC	Wilson	Armando	Franco	Giraldo	1979-04-03	M	3129486375	wilson.franco@email.com	P178	307	25	170	1	5	170
1074295863	CC	Miriam	Esperanza	Giraldo	\N	1984-12-11	F	3186529374	miriam.giraldo@email.com	P089	1	76	170	1	8	170
1046829537	CC	Gabriel	Emilio	Rios	Cardona	1981-02-28	M	3174836291	gabriel.rios@email.com	P267	1	8	170	1	68	170
1089374625	CC	Pilar	Soledad	Cardona	Montoya	1987-10-07	F	3152746389	pilar.cardona@email.com	P134	1	68	170	1	63	170
1024759638	CC	Rafael	Humberto	Montoya	\N	1983-07-18	M	3198374625	rafael.montoya@email.com	P245	1	63	170	1	66	170
1078364925	CC	Teresa	Mariela	Quintero	Arango	1990-03-05	F	3137485962	teresa.quintero@email.com	P078	1	66	170	1	54	170
1053826794	CC	Ivan	Dario	Arango	Valencia	1976-11-21	M	3176294837	ivan.arango@email.com	P189	1	54	170	1	50	170
1092746835	CC	Gladys	\N	Valencia	Henao	1989-05-09	F	3149627384	gladys.valencia@email.com	P098	1	50	170	1	19	170
1037485962	CC	Alvaro	Jesus	Henao	Bedoya	1982-08-16	M	3184759632	alvaro.henao@email.com	P156	1	19	170	1	52	170
1085372941	CC	Flor	Maria	Bedoya	\N	1988-01-04	F	3125948376	flor.bedoya@email.com	P067	1	52	170	1	20	170
1049638527	CC	Julian	Esteban	Tamayo	Correa	1985-09-22	M	3197384625	julian.tamayo@email.com	P234	1	20	170	1	17	170
1076294853	CC	Ofelia	Carmen	Correa	Zapata	1979-06-13	F	3146829374	ofelia.correa@email.com	P123	1	17	170	1	23	170
1042857396	CC	Gilberto	\N	Zapata	Uribe	1991-04-30	M	3185729463	gilberto.zapata@email.com	P178	1	23	170	1	15	170
1088249637	CC	Norma	Elena	Uribe	Galvis	1984-12-17	F	3158396472	norma.uribe@email.com	P289	1	15	170	1	18	170
1034759628	CC	Hernando	Alberto	Galvis	\N	1987-02-08	M	3127485963	hernando.galvis@email.com	P045	1	18	170	1	27	170
1081637425	CC	Marta	Lucia	Escobar	Bermudez	1980-07-25	F	3194627385	marta.escobar@email.com	P156	1	27	170	1	41	170
1056382947	CC	Octavio	Rafael	Bermudez	Patiño	1986-11-02	M	3173849627	octavio.bermudez@email.com	P198	1	41	170	1	44	170
1095174862	CC	Consuelo	\N	Patiño	Marin	1983-03-19	F	3148627394	consuelo.patino@email.com	P067	1	44	170	1	47	170
1038462759	CC	Arturo	German	Marin	Salinas	1988-08-06	M	3185749362	arturo.marin@email.com	P234	1	47	170	1	70	170
1082749635	CC	Esperanza	Rocio	Salinas	\N	1975-05-24	F	3129374856	esperanza.salinas@email.com	P089	1	70	170	1	73	170
1047385926	CC	Rodrigo	Bernardo	Castaño	Mejia	1992-09-11	M	3174629385	rodrigo.castano@email.com	P178	1	73	170	1	66	170
1089472635	CC	Aura	Stella	Mejia	Gaviria	1981-01-28	F	3156847293	aura.mejia@email.com	P245	1	66	170	1	81	170
1025847396	CC	Ernesto	\N	Gaviria	Piedrahita	1987-06-15	M	3193847625	ernesto.gaviria@email.com	P123	1	81	170	1	85	170
1074628395	CC	Magnolia	Teresa	Piedrahita	Villa	1984-12-03	F	3142758496	magnolia.piedrahita@email.com	P156	1	85	170	1	86	170
1051394827	CC	Alejandro	Dario	Villa	\N	1989-04-20	M	3187394625	alejandro.villa@email.com	P289	1	86	170	1	88	170
1086274935	CC	Nelly	Carmen	Caballero	Montoya	1978-07-07	F	3124857396	nelly.caballero@email.com	P078	1	88	170	1	91	170
1043758296	CC	Armando	Jose	Montoya	Betancur	1985-10-14	M	3195748362	armando.montoya@email.com	P198	1	91	170	1	94	170
1091638527	CC	Marlene	\N	Betancur	Giraldo	1983-02-01	F	3168374925	marlene.betancur@email.com	P067	1	94	170	1	95	170
1036829475	CC	Jaime	Orlando	Giraldo	Ospina	1990-08-18	M	3147285963	jaime.giraldo@email.com	P234	1	95	170	1	97	170
1079485362	CC	Zoila	Maria	Ospina	\N	1977-05-05	F	3183947625	zoila.ospina@email.com	P145	1	97	170	1	99	170
1048273659	CC	Edgar	Guillermo	Restrepo	Correa	1986-11-22	M	3129584736	edgar.restrepo@email.com	P178	1	99	170	88	5	170
37331882	CC	Elena	Sofia	Petrov	\N	1984-03-10	F	3174829365	elena.petrov@email.com	P089	88	5	170	1	11	170
1087394625	CC	Winston	Alexander	Correa	Duque	1982-06-29	M	3156748392	winston.correa@email.com	P256	307	25	170	1	5	170
1054827396	CC	Yolanda	Patricia	Duque	Ramirez	1988-01-16	F	3192847365	yolanda.duque@email.com	P098	1	76	170	1	8	170
1093847625	CC	Nelson	Alberto	Ramirez	\N	1981-09-09	M	3148273659	nelson.ramirez@email.com	P167	1	8	170	1	68	170
1029473658	CC	Rosaura	Amparo	Sanchez	Velasquez	1987-04-26	F	3185947362	rosaura.sanchez@email.com	P134	1	68	170	1	63	170
1076384925	CC	Gonzalo	Enrique	Velasquez	Gutierrez	1983-07-13	M	3127485963	gonzalo.velasquez@email.com	P245	1	63	170	1	66	170
1052947296	CC	Ines	Esperanza	Gutierrez	\N	1985-12-31	F	3174839627	ines.gutierrez@email.com	P089	1	66	170	1	54	170
1089374115	CC	Ruben	Dario	Acosta	Lopez	1980-02-08	M	3149627384	ruben.acosta@email.com	P178	1	54	170	1	50	170
1035829473	CC	Delia	Carmen	Lopez	Martinez	1991-08-25	F	3186394725	delia.lopez@email.com	P067	1	50	170	1	19	170
1084729635	CC	Crisanto	\N	Martinez	Rojas	1979-05-02	M	3125847396	crisanto.martinez@email.com	P234	1	19	170	1	52	170
1048293657	CC	Berenice	Gloria	Rojas	Castro	1986-10-19	F	3194738265	berenice.rojas@email.com	P156	1	52	170	1	20	170
1092847365	CC	Anibal	Felipe	Castro	\N	1984-03-06	M	3156847392	anibal.castro@email.com	P289	1	20	170	1	17	170
1927485962	CC	Margarita	Elena	Herrera	Silva	1988-11-23	F	3183947625	margarita.herrera@email.com	P078	1	17	170	1	23	170
1085729463	CC	Leonidas	Jose	Silva	Vargas	1982-06-10	M	3147285936	leonidas.silva@email.com	P198	1	23	170	1	15	170
1053847296	CC	Leticia	\N	Vargas	Morales	1987-01-27	F	3172849365	leticia.vargas@email.com	P123	1	15	170	1	18	170
1098373335	CC	Reinaldo	Carlos	Morales	Perez	1981-09-14	M	3158394726	reinaldo.morales@email.com	P167	1	18	170	1	27	170
1034729888	CC	Eulalia	Rosa	Perez	\N	1985-04-01	F	3194738526	eulalia.perez@email.com	P145	1	27	170	1	41	170
1087399925	CC	Primitivo	Angel	Jimenez	Torres	1983-07-18	M	3126847395	primitivo.jimenez@email.com	P234	1	41	170	1	44	170
1052822396	CC	Edelmira	Carmen	Torres	Mendez	1989-12-05	F	3185729463	edelmira.torres@email.com	P089	1	44	170	1	47	170
1094738526	CC	Teodoro	\N	Mendez	Gonzalez	1978-02-22	M	3147385962	teodoro.mendez@email.com	P178	1	47	170	1	70	170
1038495762	CC	Pastora	Elena	Gonzalez	Rodriguez	1990-08-09	F	3193847625	pastora.gonzalez@email.com	P067	1	70	170	1	73	170
1083749625	CC	Evaristo	Manuel	Rodriguez	\N	1982-05-26	M	3156847392	evaristo.rodriguez@email.com	P256	1	73	170	1	66	170
1047312346	CC	Eduviges	Maria	Garcia	Ruiz	1987-10-13	F	3184729635	eduviges.garcia@email.com	P134	1	66	170	1	81	170
1092842265	CC	Leopoldo	Antonio	Ruiz	Delgado	1984-03-30	M	3127485963	leopoldo.ruiz@email.com	P245	1	81	170	1	85	170
1035729463	CC	Genoveva	\N	Delgado	Contreras	1988-11-17	F	3195847362	genoveva.delgado@email.com	P098	1	85	170	1	86	170
1087312925	CC	Nicanor	Rafael	Contreras	Aguilar	1981-06-04	M	3148372659	nicanor.contreras@email.com	P178	1	86	170	1	88	170
1052839475	CC	Purificacion	Isabel	Aguilar	\N	1985-09-21	F	3173849627	purificacion.aguilar@email.com	P156	1	88	170	1	91	170
1096384725	CC	Fidencio	Julio	Guerrero	Medina	1980-01-08	M	3156847392	fidencio.guerrero@email.com	P289	1	91	170	1	94	170
1041738526	CC	Domitila	Carmen	Medina	Ramos	1987-07-25	F	3184729635	domitila.medina@email.com	P078	1	94	170	1	95	170
1080914625	CC	Crescencio	\N	Ramos	Flores	1983-04-12	M	3127485963	crescencio.ramos@email.com	P198	1	95	170	1	97	170
1036729485	CC	Filomena	Rosa	Flores	Cortes	1986-12-29	F	3195847362	filomena.flores@email.com	P067	1	97	170	1	99	170
1084739625	CC	Epifanio	Miguel	Cortes	\N	1982-02-16	M	3148372659	epifanio.cortes@email.com	P234	1	99	170	88	5	170
1084123625	CC	Daniela	Camila	Ospina	Restrepo	2002-11-14	F	3173849627	daniela.ospina@email.com	P045	88	5	170	1	11	170
1058392746	CC	Apolinar	German	Restrepo	Duarte	1979-08-03	M	3156847392	apolinar.restrepo@email.com	P178	307	25	170	1	5	170
1091237625	CC	Clotilde	Elena	Duarte	\N	1988-05-20	F	3184729635	clotilde.duarte@email.com	P134	1	76	170	1	8	170
1037481212	CC	Macedonio	Carlos	Pena	Munoz	1984-10-07	M	3127485963	macedonio.pena@email.com	P245	1	8	170	1	68	170
1083249635	CC	Filomenia	Rosa	Munoz	Beltran	1987-03-24	F	3195847362	filomenia.munoz@email.com	P089	1	68	170	1	63	170
1112232659	CC	Bonifacio	\N	Beltran	Franco	1981-11-11	M	3148372659	bonifacio.beltran@email.com	P167	1	63	170	1	66	170
1096843725	CC	Auristela	Carmen	Franco	Giraldo	1985-06-28	F	3173849627	auristela.franco@email.com	P098	1	66	170	1	54	170
1032749658	CC	Hermenegildo	Jose	Giraldo	\N	1983-01-15	M	3156847392	hermenegildo.giraldo@email.com	P234	1	54	170	1	50	170
1089234625	CC	Maximina	Elena	Rios	Cardona	1990-09-02	F	3184729635	maximina.rios@email.com	P156	1	50	170	1	19	170
1047389026	CC	Pancracio	Manuel	Cardona	Montoya	1978-04-19	M	3127485963	pancracio.cardona@email.com	P178	1	19	170	1	52	170
1094123526	CC	Escolastica	\N	Montoya	Quintero	1986-12-06	F	3195847362	escolastica.montoya@email.com	P067	1	52	170	1	20	170
1138495762	CC	Melquiades	Antonio	Quintero	Arango	1982-07-23	M	3148372659	melquiades.quintero@email.com	P289	1	20	170	1	17	170
1385739624	CC	Remedios	Rosa	Arango	\N	1988-02-10	F	3173849627	remedios.arango@email.com	P145	1	17	170	1	23	170
1092847296	CC	Saturnino	Rafael	Valencia	Henao	1984-08-27	M	3156847392	saturnino.valencia@email.com	P234	1	23	170	1	15	170
1098373325	CC	Generosa	Carmen	Henao	Bedoya	1987-05-14	F	3184729635	generosa.henao@email.com	P078	1	15	170	1	18	170
88142897	CC	John	Michael	Smith	\N	1985-09-22	M	3127485963	john.smith@email.com	P198	1	18	170	1	27	170
1043384925	CC	Librada	Elena	Bedoya	Tamayo	1981-11-09	F	3195847362	librada.bedoya@email.com	P123	1	27	170	1	41	170
1045758396	CC	Florentino	\N	Tamayo	Correa	1983-06-26	M	3148372659	florentino.tamayo@email.com	P167	1	41	170	1	44	170
1089564625	CC	Serafina	Rosa	Correa	Zapata	1889-01-13	F	3173849627	serafina.correa@email.com	P156	1	44	170	1	47	170
1035134463	CC	Anacleto	Jose	Zapata	\N	1985-09-30	M	3156847392	anacleto.zapata@email.com	P289	1	47	170	1	70	170
1082394625	CC	Sinforosa	Carmen	Uribe	Galvis	1988-04-17	F	3184729635	sinforosa.uribe@email.com	P078	1	70	170	1	73	170
1012349637	CC	Policarpo	Manuel	Galvis	Escobar	1982-12-04	M	3127485963	policarpo.galvis@email.com	P198	1	73	170	1	66	170
1096374825	CC	Emerenciana	\N	Escobar	Bermudez	1987-07-21	F	3195847362	emerenciana.escobar@email.com	P067	1	66	170	1	81	170
1038982762	CC	Arquimedes	Antonio	Bermudez	Patino	1984-03-08	M	3148372659	arquimedes.bermudez@email.com	P234	1	81	170	1	85	170
1084719625	CC	Visitacion	Rosa	Patino	\N	1986-10-25	F	3173849627	visitacion.patino@email.com	P145	1	85	170	1	86	170
1047312926	CC	Hermogenes	Rafael	Marin	Salinas	1981-05-12	M	3156847392	hermogenes.marin@email.com	P178	1	86	170	1	88	170
1092347625	CC	Aniceta	Carmen	Salinas	Castano	1888-11-29	F	3184729635	aniceta.salinas@email.com	P134	1	88	170	1	91	170
1033329485	CC	Eustaquio	\N	Castano	Mejia	1983-08-16	M	3127485963	eustaquio.castano@email.com	P245	1	91	170	1	94	170
1082748536	CC	Plácida	Elena	Mejia	Gaviria	1987-02-03	F	3195847362	placida.mejia@email.com	P089	1	94	170	1	95	170
1049384726	CC	Tranquilino	Jose	Gaviria	\N	1985-09-20	M	3148372659	tranquilino.gaviria@email.com	P167	1	95	170	1	97	170
1095847362	CC	Nemesia	Rosa	Piedrahita	Villa	1982-06-07	F	3173849627	nemesia.piedrahita@email.com	P098	1	97	170	1	99	170
1034829475	CC	Casimiro	Manuel	Villa	Caballero	1986-01-24	M	3156847392	casimiro.villa@email.com	P234	1	99	170	88	5	170
1086391225	CC	Sebastian	Andres	Caballero	\N	2007-07-18	M	3184729635	sebastian.caballero@email.com	P078	88	5	170	1	11	170
107294625	CC	Candelaria	Carmen	Montoya	Betancur	1884-04-05	F	3127485963	candelaria.montoya@email.com	P156	307	25	170	1	5	170
1007847296	CC	Remigio	\N	Betancur	Giraldo	1987-12-22	M	3195847362	remigio.betancur@email.com	P289	1	76	170	1	8	170
1098234625	CC	Presentacion	Elena	Giraldo	Ospina	1883-03-09	F	3148372659	presentacion.giraldo@email.com	P067	1	8	170	1	68	170
1042758396	CC	Epifanio	Antonio	Ospina	Restrepo	1885-08-26	M	3173849627	epifanio.ospina@email.com	P198	1	68	170	1	63	170
1007584920	CC	Maria	Jose	Garcia	Rodriguez	1985-03-15	F	3175849203	mariajose.garcia@email.com	P001	498	54	170	1	5	170
1040238657	CC	Carlos	Andres	Martinez	Lopez	1990-07-23	M	3008765432	carlos.martinez@gmail.com	P045	1	5	170	307	25	170
1025697841	CC	Ana	Sofia	Rodriguez	Hernandez	1988-12-08	F	3124567890	ana.rodriguez@hotmail.com	P120	88	5	170	1	11	170
1032456789	CC	Luis	Fernando	Gonzalez	Perez	1975-09-17	M	3156789012	luis.gonzalez@yahoo.com	P078	1	11	170	1	76	170
1048765123	CC	Patricia	\N	Morales	Silva	1992-04-05	F	3209876543	patricia.morales@gmail.com	P156	307	25	170	88	5	170
1051234567	CC	Jorge	Alejandro	Ramirez	Castro	1983-11-12	M	3187654321	jorge.ramirez@outlook.com	P234	1	76	170	1	8	170
1039876542	CC	Sandra	Milena	Torres	Vargas	1987-06-28	F	3145678901	sandra.torres@email.com	P089	1	8	170	1	20	170
1047896321	CC	Ricardo	David	Jimenez	Moreno	1979-01-03	M	3167890123	ricardo.jimenez@gmail.com	P167	1	20	170	1	68	170
1028564973	CC	Claudia	\N	Herrera	Ruiz	1991-05-19	F	3178901234	claudia.herrera@hotmail.com	P298	1	68	170	1	13	170
1041759638	CC	Fernando	Augusto	Castillo	Diaz	1986-08-14	M	3189012345	fernando.castillo@yahoo.com	P345	1	13	170	1	47	170
1036524789	CC	Gloria	Elena	Mendoza	Aguilar	1984-02-07	F	3190123456	gloria.mendoza@gmail.com	P412	1	47	170	1	50	170
1044587123	CC	Jaime	Mauricio	Ospina	Cardenas	1981-10-25	M	3201234567	jaime.ospina@outlook.com	P098	1	50	170	1	52	170
1029843756	CC	Esperanza	\N	Rojas	Montoya	1993-03-11	F	3212345678	esperanza.rojas@email.com	P187	1	52	170	1	63	170
1038765412	CC	Alberto	Enrique	Velasquez	Salazar	1988-07-16	M	3223456789	alberto.velasquez@gmail.com	P276	1	63	170	1	66	170
1045123698	CC	Beatriz	Andrea	Munoz	Guerrero	1985-09-30	F	3234567890	beatriz.munoz@hotmail.com	P365	1	66	170	1	70	170
1031678954	CC	Miguel	Angel	Pena	Cortes	1982-12-04	M	3245678901	miguel.pena@yahoo.com	P087	1	70	170	1	73	170
1046789125	CC	Rosa	Maria	Acosta	Medina	1990-04-21	F	3256789012	rosa.acosta@gmail.com	P198	1	73	170	1	17	170
1033456782	CC	Hector	Julio	Vega	Restrepo	1977-06-13	M	3267890123	hector.vega@outlook.com	P321	1	17	170	1	18	170
1027895641	CC	Liliana	\N	Suarez	Giraldo	1989-01-08	F	3278901234	liliana.suarez@email.com	P154	1	18	170	1	19	170
1042357896	CC	Oscar	Fabian	Delgado	Arango	1986-11-26	M	3289012345	oscar.delgado@gmail.com	P287	1	19	170	1	23	170
1039654783	CE	Valentina	Isabella	Romero	Sandoval	1994-08-15	F	3290123456	valentina.romero@hotmail.com	P098	1	23	170	1	41	170
1035789126	CC	Andres	Felipe	Cruz	Cardona	1980-05-02	M	3301234567	andres.cruz@yahoo.com	P176	1	41	170	1	44	170
1048521369	CC	Margarita	\N	Soto	Bedoya	1987-09-18	F	3312345678	margarita.soto@gmail.com	P245	1	44	170	1	25	170
1026874591	CC	Rodrigo	Antonio	Cano	Uribe	1983-07-09	M	3323456789	rodrigo.cano@outlook.com	P334	1	25	170	1	27	170
1041236587	CC	Isabel	Cristina	Leon	Ossa	1991-02-24	F	3334567890	isabel.leon@email.com	P098	1	27	170	88	5	170
1037458926	CC	Gabriel	Eduardo	Parra	Zuluaga	1978-10-06	M	3345678901	gabriel.parra@gmail.com	P187	307	25	170	1	76	170
1043785642	CC	Carmen	Sofia	Duarte	Marin	1992-12-12	F	3356789012	carmen.duarte@hotmail.com	P276	1	76	170	1	8	170
1030159874	CC	Sergio	Armando	Lozano	Villa	1985-03-29	M	3367890123	sergio.lozano@yahoo.com	P365	1	8	170	1	11	170
1045692837	CC	Pilar	\N	Vargas	Escobar	1989-01-17	F	3378901234	pilar.vargas@gmail.com	P154	1	11	170	1	13	170
1032874569	CC	Rafael	Guillermo	Bautista	Mejia	1984-06-05	M	3389012345	rafael.bautista@outlook.com	P243	1	13	170	1	15	170
1028459367	CC	Amparo	Teresa	Franco	Valencia	1990-04-22	F	3390123456	amparo.franco@email.com	P332	1	15	170	1	17	170
1044176325	CC	Gonzalo	Mauricio	Ayala	Palacio	1986-11-14	M	3401234567	gonzalo.ayala@gmail.com	P098	1	17	170	1	18	170
1031697854	CC	Diana	Marcela	Gutierrez	Posada	1988-08-07	F	3412345678	diana.gutierrez@hotmail.com	P176	1	18	170	1	19	170
1046283759	CC	Esteban	\N	Cardona	Henao	1981-05-25	M	3423456789	esteban.cardona@yahoo.com	P265	1	19	170	1	20	170
1033587462	CC	Nora	Alejandra	Herrera	Tabares	1987-09-10	F	3434567890	nora.herrera@gmail.com	P354	1	20	170	1	23	170
1029756841	CC	Fabio	Ignacio	Castaño	Galeano	1983-07-02	M	3445678901	fabio.castano@outlook.com	P143	1	23	170	1	25	170
1041582736	CC	Olga	Patricia	Molina	Quintero	1992-02-19	F	3456789012	olga.molina@email.com	P232	1	25	170	1	27	170
1038467592	CC	Leonardo	Carlos	Rivas	Zapata	1989-10-13	M	3467890123	leonardo.rivas@gmail.com	P321	1	27	170	1	41	170
1045728361	CC	Teresa	\N	Calle	Velez	1985-01-28	F	3478901234	teresa.calle@hotmail.com	P410	1	41	170	1	44	170
1032659874	CC	Mauricio	Ivan	Salinas	Londono	1990-12-06	M	3489012345	mauricio.salinas@yahoo.com	P199	1	44	170	1	47	170
1027841596	CC	Ines	Esperanza	Botero	Ocampo	1978-06-23	F	3490123456	ines.botero@gmail.com	P288	1	47	170	1	50	170
1043527896	CC	Enrique	Alejandro	Mesa	Correa	1987-04-11	M	3501234567	enrique.mesa@outlook.com	P377	1	50	170	1	52	170
1040896327	CC	Luz	Marina	Restrepo	Alvarez	1984-08-16	F	3512345678	luz.restrepo@email.com	P166	1	52	170	1	54	170
1036745892	CC	Camilo	Andres	Jaramillo	Hurtado	1991-03-04	M	3523456789	camilo.jaramillo@gmail.com	P255	1	54	170	1	63	170
1028596374	CC	Gladys	\N	Arbelaez	Ramirez	1989-07-21	F	3534567890	gladys.arbelaez@hotmail.com	P344	1	63	170	1	66	170
1044728159	CC	Alejandro	Jose	Montoya	Gonzalez	1986-11-09	M	3545678901	alejandro.montoya@yahoo.com	P133	1	66	170	1	68	170
1031457896	CC	Martha	Cecilia	Ospina	Martinez	1983-05-27	F	3556789012	martha.ospina@gmail.com	P222	1	68	170	1	70	170
1037859641	CC	Edison	Fernando	Giraldo	Rodriguez	1988-09-14	M	3567890123	edison.giraldo@outlook.com	P311	1	70	170	1	73	170
1043682597	CC	Soledad	\N	Valencia	Hernandez	1992-01-01	F	3578901234	soledad.valencia@email.com	P400	1	73	170	1	76	170
1029374856	CC	Alvaro	Gustavo	Londono	Perez	1985-08-18	M	3589012345	alvaro.londono@gmail.com	P189	1	76	170	1	81	170
1045896327	CC	Dora	Amparo	Zapata	Lopez	1990-12-03	F	3590123456	dora.zapata@hotmail.com	P278	1	81	170	1	85	170
1032741856	CC	Cesar	Augusto	Marin	Silva	1981-06-20	M	3601234567	cesar.marin@yahoo.com	P367	1	85	170	1	86	170
1038567423	CC	Blanca	Stella	Cadavid	Castro	1987-02-07	F	3612345678	blanca.cadavid@gmail.com	P156	1	86	170	1	88	170
1026849537	CC	Ruben	Dario	Henao	Vargas	1989-10-24	M	3623456789	ruben.henao@outlook.com	P245	1	88	170	1	91	170
1042185736	CC	Angela	\N	Correa	Moreno	1984-04-12	F	3634567890	angela.correa@email.com	P334	1	91	170	1	94	170
1039756842	CC	Hernan	Eduardo	Velez	Ruiz	1986-07-29	M	3645678901	hernan.velez@gmail.com	P123	1	94	170	1	95	170
1035428697	CC	Graciela	Maria	Quintero	Diaz	1988-11-15	F	3656789012	graciela.quintero@hotmail.com	P212	1	95	170	1	97	170
1041697825	CC	Arturo	\N	Aguilar	Aguilar	1982-05-05	M	3667890123	arturo.aguilar@yahoo.com	P301	1	97	170	1	99	170
1028563794	CC	Esperanza	Luz	Cardenas	Cardenas	1991-09-22	F	3678901234	esperanza.cardenas@gmail.com	P390	1	99	170	88	5	170
1044859672	CC	German	Alonso	Salazar	Montoya	1987-01-08	M	3689012345	german.salazar@outlook.com	P179	88	5	170	307	25	170
1031687452	CC	Rosario	\N	Guerrero	Giraldo	1983-06-26	F	3690123456	rosario.guerrero@email.com	P268	307	25	170	1	76	170
1037452896	CC	Jairo	Antonio	Medina	Arango	1990-08-13	M	3701234567	jairo.medina@gmail.com	P357	1	76	170	1	8	170
1043758962	CC	Isabella	Valentina	Cardona	Posada	2005-12-19	F	3712345678	isabella.cardona@hotmail.com	P146	1	8	170	1	11	170
1029637854	CC	Rubiela	Teresa	Tabares	Henao	1985-04-04	F	3723456789	rubiela.tabares@yahoo.com	P235	1	11	170	1	13	170
1045896321	CC	Nelson	Hernan	Galeano	Tabares	1988-02-21	M	3734567890	nelson.galeano@gmail.com	P324	1	13	170	1	15	170
1032574896	CC	Magnolia	\N	Quintero	Zapata	1989-10-09	F	3745678901	magnolia.quintero@outlook.com	P413	1	15	170	1	17	170
1038695741	CC	Bernardo	Luis	Zapata	Velez	1984-07-27	M	3756789012	bernardo.zapata@email.com	P102	1	17	170	1	18	170
1026745893	CC	Fabiola	Elena	Velez	Londono	1991-03-14	F	3767890123	fabiola.velez@gmail.com	P191	1	18	170	1	19	170
1041528367	CC	Orlando	Jose	Londono	Ocampo	1986-12-02	M	3778901234	orlando.londono@hotmail.com	P280	1	19	170	1	20	170
1037896524	CC	Esperanza	\N	Ocampo	Correa	1982-05-18	F	3789012345	esperanza.ocampo@yahoo.com	P369	1	20	170	1	23	170
1043257896	CC	Emilio	Rafael	Correa	Alvarez	1987-09-06	M	3790123456	emilio.correa@gmail.com	P158	1	23	170	1	25	170
1030485762	CC	Araceli	Patricia	Alvarez	Hurtado	1990-01-23	F	3801234567	araceli.alvarez@outlook.com	P247	1	25	170	1	27	170
1046785932	CC	Ramiro	\N	Hurtado	Ramirez	1983-08-11	M	3812345678	ramiro.hurtado@email.com	P336	1	27	170	1	41	170
1033658947	CC	Amparo	Stella	Ramirez	Gonzalez	1988-06-28	F	3823456789	amparo.ramirez@gmail.com	P125	1	41	170	1	44	170
1029745862	CC	Rodrigo	Fernando	Gonzalez	Martinez	1985-11-15	M	3834567890	rodrigo.gonzalez@hotmail.com	P214	1	44	170	1	47	170
1045239687	CC	Mercedes	\N	Martinez	Rodriguez	1989-07-01	F	3845678901	mercedes.martinez@yahoo.com	P303	1	47	170	1	50	170
1032874695	CC	Julian	Andres	Rodriguez	Hernandez	1984-04-19	M	3856789012	julian.rodriguez@gmail.com	P392	1	50	170	1	52	170
1038675429	CC	Marleny	Teresa	Hernandez	Perez	1991-02-05	F	3867890123	marleny.hernandez@outlook.com	P181	1	52	170	1	54	170
1026598734	CC	Hermes	Eduardo	Perez	Lopez	1987-10-22	M	3878901234	hermes.perez@email.com	P270	1	54	170	1	63	170
1042741856	CC	Esperanza	\N	Lopez	Silva	1982-12-08	F	3889012345	esperanza.lopez@gmail.com	P359	1	63	170	1	66	170
1039527841	CC	Jaime	Mauricio	Silva	Castro	1990-08-26	M	3890123456	jaime.silva@hotmail.com	P148	1	66	170	1	68	170
1035896742	CC	Clemencia	Maria	Castro	Vargas	1985-05-13	F	3901234567	clemencia.castro@yahoo.com	P237	1	68	170	1	70	170
1041758362	CC	Dario	\N	Vargas	Moreno	1988-09-30	M	3912345678	dario.vargas@gmail.com	P326	1	70	170	1	73	170
1028647593	CC	Carmenza	Elena	Moreno	Ruiz	1986-01-17	F	3923456789	carmenza.moreno@outlook.com	P415	1	73	170	1	76	170
1044526897	CC	Alvaro	Jose	Ruiz	Diaz	1983-11-04	M	3934567890	alvaro.ruiz@email.com	P104	1	76	170	1	81	170
1031852796	CC	Gloria	Patricia	Diaz	Aguilar	1989-06-21	F	3945678901	gloria.diaz@gmail.com	P193	1	81	170	1	85	170
1037698524	CC	Armando	\N	Aguilar	Cardenas	1987-03-09	M	3956789012	armando.aguilar@hotmail.com	P282	1	85	170	1	86	170
1043785629	CC	Leticia	Esperanza	Cardenas	Montoya	1984-07-26	F	3967890123	leticia.cardenas@yahoo.com	P371	1	86	170	1	88	170
1030596387	CC	Guillermo	Antonio	Montoya	Giraldo	1991-12-12	M	3978901234	guillermo.montoya@gmail.com	P160	1	88	170	1	91	170
1046258973	CC	Miriam	\N	Giraldo	Arango	1988-04-29	F	3989012345	miriam.giraldo@outlook.com	P249	1	91	170	1	94	170
1033587426	CC	Antonio	Rafael	Arango	Posada	1985-10-16	M	3990123456	antonio.arango@email.com	P338	1	94	170	1	95	170
1029847651	CC	Nubia	Teresa	Posada	Henao	1982-08-03	F	4001234567	nubia.posada@gmail.com	P127	1	95	170	1	97	170
1045697382	CC	Vicente	\N	Henao	Tabares	1990-01-20	M	4012345678	vicente.henao@hotmail.com	P216	1	97	170	1	99	170
1032568749	CC	Claudia	Elena	Tabares	Zapata	1987-05-07	F	4023456789	claudia.tabares@yahoo.com	P305	1	99	170	88	5	170
1038457296	CC	Ernesto	Fernando	Zapata	Velez	1984-09-24	M	4034567890	ernesto.zapata@gmail.com	P394	88	5	170	307	25	170
1026745832	CC	Lucila	\N	Velez	Londono	1991-02-11	F	4045678901	lucila.velez@outlook.com	P183	307	25	170	1	76	170
1041856739	CC	Alvaro	Eduardo	Londono	Ocampo	1986-11-28	M	4056789012	alvaro.londono@email.com	P272	1	76	170	1	8	170
1037952684	CE	Alejandra	Sofia	Ocampo	Correa	1988-06-15	F	4067890123	alejandra.ocampo@gmail.com	P361	1	8	170	1	11	170
1043687524	PP	Santiago	\N	Correa	Alvarez	1989-10-02	M	4078901234	santiago.correa@hotmail.com	P150	1	11	170	1	13	170
1030482597	CC	Judith	Patricia	Alvarez	Hurtado	1983-03-19	F	4089012345	judith.alvarez@yahoo.com	P239	1	13	170	1	15	170
1046785923	CC	Hernando	Jose	Hurtado	Ramirez	1987-12-06	M	4090123456	hernando.hurtado@gmail.com	P328	1	15	170	1	17	170
1033576842	CC	Myriam	\N	Ramirez	Gonzalez	1985-07-23	F	4101234567	myriam.ramirez@outlook.com	P417	1	17	170	1	18	170
1029485736	CC	Efrain	Antonio	Gonzalez	Martinez	1990-04-10	M	4112345678	efrain.gonzalez@email.com	P106	1	18	170	1	19	170
1092692837	CC	Mariela	Elena	Martinez	Rodriguez	1984-08-27	F	4123456789	mariela.martinez@gmail.com	P195	1	19	170	1	20	170
1040876543	CC	Leticia	Rosa	Torres	Mendez	1986-08-22	F	3790123456	leticia.torres@gmail.com	P106	1	76	170	1	68	170
1081321098	CC	Reinaldo	Antonio	Mendez	\N	1989-05-09	M	3801234567	reinaldo.mendez@hotmail.com	P195	1	68	170	1	63	170
1049654321	CC	Eulalia	Carmen	Gonzalez	Rodriguez	1987-10-26	F	3812345678	eulalia.gonzalez@yahoo.com	P284	1	63	170	1	50	170
1078210987	CC	Primitivo	Angel	Rodriguez	\N	1983-03-14	M	3823456789	primitivo.rodriguez@email.com	P373	1	50	170	1	19	170
1046543210	CC	Edelmira	Elena	Garcia	Ruiz	1991-12-01	F	3834567890	edelmira.garcia@gmail.com	P162	1	19	170	1	52	170
1085098765	CC	Teodoro	Manuel	Ruiz	Delgado	1985-07-18	M	3845678901	teodoro.ruiz@hotmail.com	P251	1	52	170	1	20	170
1053321654	CC	Pastora	Maria	Delgado	\N	1988-02-05	F	3856789012	pastora.delgado@yahoo.com	P340	1	20	170	1	17	170
1074876543	CC	Evaristo	Rafael	Contreras	Aguilar	1987-09-23	M	3867890123	evaristo.contreras@email.com	P129	1	17	170	1	23	170
1042210987	CC	Eduviges	Isabel	Aguilar	\N	1984-04-10	F	3878901234	eduviges.aguilar@gmail.com	P218	1	23	170	1	15	170
1083543210	CC	Leopoldo	Julio	Guerrero	Medina	1990-11-28	M	3889012345	leopoldo.guerrero@hotmail.com	P307	1	15	170	1	18	170
1051876543	CC	Genoveva	Carmen	Medina	Ramos	1986-06-15	F	3890123456	genoveva.medina@yahoo.com	P396	1	18	170	1	27	170
1072654321	CC	Nicanor	Antonio	Ramos	\N	1989-01-02	M	3901234567	nicanor.ramos@email.com	P185	1	27	170	1	41	170
1040321098	CC	Purificacion	Rosa	Flores	Cortes	1987-08-20	F	3912345678	purificacion.flores@gmail.com	P274	1	41	170	1	44	170
108138765	CC	Fidencio	Miguel	Cortes	\N	1983-05-07	M	3923456789	fidencio.cortes@hotmail.com	P363	1	44	170	1	47	170
1049543210	CC	Domitila	Elena	Cardenas	Ospina	1991-10-24	F	3934567890	domitila.cardenas@yahoo.com	P152	1	47	170	1	70	170
1078876543	CC	Crescencio	Carlos	Ospina	\N	1985-03-12	M	3945678901	crescencio.ospina@email.com	P241	1	70	170	1	73	170
1046210987	CC	Filomena	Maria	Duarte	Pena	1988-12-29	F	3956789012	filomena.duarte@gmail.com	P330	1	73	170	1	66	170
37654321	CC	Epifanio	Rafael	Pena	Munoz	1987-07-16	M	3967890123	epifanio.pena@hotmail.com	P419	1	66	170	1	81	170
1085321654	CC	Daniela	Camila	Munoz	\N	1992-04-03	F	3978901234	daniela.munoz@yahoo.com	P108	1	81	170	1	85	170
16345678	CC	Apolinar	German	Beltran	Franco	2007-11-21	M	3989012345	apolinar.beltran@email.com	P197	1	85	170	1	86	170
1053987654	CC	Clotilde	Elena	Franco	\N	1986-06-08	F	3990123456	clotilde.franco@gmail.com	P286	1	86	170	1	88	170
1074543210	CC	Macedonio	Jose	Giraldo	Rios	1990-01-25	M	4001234567	macedonio.giraldo@hotmail.com	P375	1	88	170	1	91	170
1042876543	CC	Filomenia	Rosa	Rios	\N	1984-09-13	F	4012345678	filomenia.rios@yahoo.com	P164	1	91	170	1	94	170
1083210654	CC	Bonifacio	Carlos	Cardona	Montoya	1988-05-30	M	4023456789	bonifacio.cardona@email.com	P253	1	94	170	1	95	170
1051543210	CC	Auristela	Carmen	Montoya	\N	1987-10-17	F	4034567890	auristela.montoya@gmail.com	P342	1	95	170	1	97	170
1072098765	CC	Hermenegildo	Antonio	Quintero	Arango	1983-02-04	M	4045678901	hermenegildo.quintero@hotmail.com	P131	1	97	170	1	99	170
1040654987	CC	Maximina	Elena	Arango	\N	1991-11-22	F	4056789012	maximina.arango@yahoo.com	P220	1	99	170	88	5	170
1081432109	CC	Pancracio	Manuel	Valencia	\N	1985-06-09	M	4067890123	pancracio.valencia@email.com	P309	88	5	170	1	11	170
1049876210	CC	Escolastica	Rosa	Henao	Bedoya	1989-12-26	F	4078901234	escolastica.henao@gmail.com	P398	1	11	170	307	25	170
1078543210	CC	Melquiades	Rafael	Bedoya	\N	1987-07-14	M	4089012345	melquiades.bedoya@hotmail.com	P187	307	25	170	1	5	170
1046321098	CC	Remedios	Carmen	Tamayo	Correa	1984-04-01	F	4090123456	remedios.tamayo@yahoo.com	P276	1	5	170	1	8	170
1085098432	CC	Saturnino	Jose	Correa	\N	1990-11-19	M	4101234567	saturnino.correa@email.com	P365	1	8	170	1	76	170
88145756	CC	John	Michael	Smith	Johnson	1985-09-22	M	3127485963	john.smith@email.com	P198	1	76	170	1	68	170
1053654321	CC	Generosa	Elena	Zapata	Uribe	1988-03-06	F	4112345678	generosa.zapata@gmail.com	P143	1	68	170	1	63	170
1074210987	CC	Librada	Rosa	Uribe	\N	1986-10-24	F	4123456789	librada.uribe@hotmail.com	P232	1	63	170	1	50	170
1042543210	CC	Florentino	Carlos	Galvis	Escobar	1989-05-11	M	4134567890	florentino.galvis@yahoo.com	P321	1	50	170	1	19	170
1037588220	CC	Maria	Jose	Garcia	Lopez	1985-03-15	F	3175849203	mariajose.garcia@email.com	P001	1	5	170	4	5	170
1025678432	CC	Carlos	Andres	Rodriguez	Martinez	1990-07-22	M	3142567890	carlos.rodriguez@email.com	P045	360	5	170	1	11	170
1098762232	CC	Ana	Maria	Gonzalez	Perez	1988-12-08	F	3201234567	ana.gonzalez@email.com	P023	1	8	170	1	76	170
1054321098	CC	Juan	Carlos	Ramirez	Torres	1992-05-30	M	3156789012	juan.ramirez@email.com	P067	1	11	170	1	68	170
1076543210	CC	Laura	Patricia	Hernandez	Silva	1987-09-14	F	3187654321	laura.hernandez@email.com	P089	1	25	170	1	19	170
1032109876	CC	Diego	Fernando	Lopez	Vargas	1991-11-03	M	3123456789	diego.lopez@email.com	P156	1	13	170	1	52	170
1087654321	CC	Sandra	Milena	Martinez	Ruiz	1989-02-27	F	3198765432	sandra.martinez@email.com	P234	88	5	170	1	25	170
1043210987	CC	Alejandro	\N	Gutierrez	Morales	1993-06-19	M	3165432109	alejandro.gutierrez@email.com	P098	1	76	170	360	5	170
1065432109	CC	Monica	Andrea	Jimenez	Castro	1986-01-11	F	3176543210	monica.jimenez@email.com	P178	1	68	170	1	15	170
1076549873	CC	Ricardo	Javier	Vargas	Ortiz	1994-08-05	M	3187659873	ricardo.vargas@email.com	P267	1	19	170	1	54	170
1098765123	CC	Claudia	Elena	Moreno	Diaz	1985-04-23	F	3201236789	claudia.moreno@email.com	P345	1	54	170	1	41	170
1032165498	CC	Fernando	\N	Cruz	Sanchez	1990-10-16	M	3123216549	fernando.cruz@email.com	P123	1	41	170	1	8	170
1087659321	CC	Patricia	Alejandra	Rojas	Gil	1988-03-29	F	3198659321	patricia.rojas@email.com	P289	1	52	170	1	73	170
1054987654	CC	Andres	Camilo	Soto	Mendez	1992-07-12	M	3154987654	andres.soto@email.com	P367	1	15	170	88	5	170
1076321098	CC	Beatriz	\N	Pena	Rivera	1987-12-04	F	3176321098	beatriz.pena@email.com	P445	1	73	170	1	68	170
1098123456	CC	Miguel	Angel	Castillo	Flores	1991-05-21	M	3201234567	miguel.castillo@email.com	P167	1	17	170	1	66	170
1043659871	CC	Gloria	Patricia	Delgado	Aguilar	1989-09-07	F	3163659871	gloria.delgado@email.com	P234	1	66	170	1	63	170
1065987412	CC	Jaime	Eduardo	Vega	Herrera	1994-01-25	M	3175987412	jaime.vega@email.com	P356	1	63	170	1	76	170
1087321654	CC	Carmen	Rosa	Molina	Cardenas	1986-11-18	F	3198321654	carmen.molina@email.com	P478	1	20	170	1	17	170
1098654789	CC	Pablo	Esteban	Guerrero	Romero	1993-06-02	M	3201654789	pablo.guerrero@email.com	P189	1	23	170	1	70	170
1054123987	CC	Liliana	\N	Medina	Acosta	1988-08-13	F	3154123987	liliana.medina@email.com	P267	1	70	170	1	23	170
1076987654	CC	Daniel	Santiago	Paredes	Navarro	1990-02-09	M	3176987654	daniel.paredes@email.com	P345	1	27	170	1	44	170
1032453389	CC	Isabel	Cristina	Restrepo	Gomez	1992-04-26	F	3123456789	isabel.restrepo@email.com	P423	1	44	170	1	47	170
1087456123	CC	Oscar	Mauricio	Velasco	Pinzon	1985-07-14	M	3198456123	oscar.velasco@email.com	P156	1	47	170	1	50	170
1043789654	CC	Amparo	\N	Salamanca	Correa	1991-10-31	F	3163789654	amparo.salamanca@email.com	P278	1	50	170	1	27	170
1065456987	CC	Sergio	Armando	Escobar	Lozano	1987-03-17	M	3175456987	sergio.escobar@email.com	P398	1	81	170	1	85	170
1076234567	CC	Margarita	Elena	Cano	Blanco	1989-12-06	F	3176234567	margarita.cano@email.com	P167	1	85	170	1	86	170
1098789123	CC	Hector	David	Quintero	Rubio	1994-05-24	M	3201789123	hector.quintero@email.com	P289	1	86	170	1	88	170
1054876543	CC	Esperanza	\N	Bonilla	Mejia	1986-01-11	F	3154876543	esperanza.bonilla@email.com	P367	564	88	170	1	91	170
1087123654	CC	Roberto	Luis	Fuentes	Vasquez	1993-08-28	M	3198123654	roberto.fuentes@email.com	P445	1	91	170	1	94	170
1043654987	CC	Nelly	Amparo	Duarte	Cedeno	1988-11-15	F	3163654987	nelly.duarte@email.com	P178	1	94	170	1	95	170
1065321456	CC	Guillermo	\N	Bautista	Espinoza	1990-07-03	M	3175321456	guillermo.bautista@email.com	P256	1	95	170	1	97	170
1076456789	CC	Rosa	Maria	Caballero	Prieto	1992-02-20	F	3176456789	rosa.caballero@email.com	P334	1	97	170	1	99	170
1098321456	CC	Raul	Enrique	Sandoval	Mercado	1985-09-08	M	3201321456	raul.sandoval@email.com	P412	1	99	170	88	5	170
1054789012	CC	Stella	\N	Galvis	Zambrano	1991-12-25	F	3154789012	stella.galvis@email.com	P123	360	5	170	1	76	170
1087987654	CC	Alberto	Jose	Montes	Parra	1987-04-12	M	3198987654	alberto.montes@email.com	P201	1	8	170	1	68	170
1043567890	CC	Adriana	Lucia	Ayala	Duran	1994-06-29	F	3163567890	adriana.ayala@email.com	P289	1	68	170	1	25	170
1065654321	CC	Mauricio	Alejandro	Alarcon	Pacheco	1989-10-16	M	3175654321	mauricio.alarcon@email.com	P367	1	25	170	1	19	170
1076789012	CC	Yolanda	\N	Cabrera	Garzon	1986-01-04	F	3176789012	yolanda.cabrera@email.com	P445	1	19	170	1	13	170
1098456789	CC	Arturo	Felipe	Marin	Ospina	1993-08-21	M	3201456789	arturo.marin@email.com	P178	1	13	170	1	52	170
1009125678	CC	Sofia	Valentina	Perez	Morales	2005-05-10	F	3125678901	sofia.perez@email.com	P234	1	52	170	1	54	170
1054567890	CC	German	\N	Ariza	Bernal	1988-11-07	M	3154567890	german.ariza@email.com	P312	1	54	170	1	41	170
1087654098	CC	Rocio	Teresa	Luna	Figueroa	1990-03-24	F	3198654098	rocio.luna@email.com	P389	1	41	170	1	44	170
1043890765	CC	Cesar	Augusto	Villegas	Rey	1992-07-13	M	3163890765	cesar.villegas@email.com	P456	1	44	170	1	47	170
1065789123	CC	Olga	\N	Suarez	Coronado	1985-09-30	F	3175789123	olga.suarez@email.com	P167	1	47	170	1	50	170
1076567432	CC	Hugo	Orlando	Campos	Varela	1991-12-17	M	3176567432	hugo.campos@email.com	P245	1	50	170	1	70	170
1098789456	CC	Blanca	Nieve	Guerrero	Leon	1987-06-05	F	3201789456	blanca.guerrero@email.com	P323	1	70	170	1	23	170
1054321567	CC	Rodrigo	\N	Arias	Contreras	1994-01-22	M	3154321567	rodrigo.arias@email.com	P401	1	23	170	1	17	170
1087456789	CC	Consuelo	Esperanza	Ibarra	Molano	1989-08-08	F	3198456789	consuelo.ibarra@email.com	P178	1	17	170	1	66	170
1043123456	CC	Edison	Fabian	Castro	Zuniga	1986-04-26	M	3163123456	edison.castro@email.com	P256	1	66	170	1	63	170
1091234567	CC	Maria	Elena	Rodriguez	Silva	1990-02-15	F	3201234567	maria.rodriguez@email.com	P334	1	63	170	1	76	170
1065432876	CC	Luz	Marina	Acevedo	Patino	1993-10-03	F	3175432876	luz.acevedo@email.com	P412	1	76	170	1	81	170
1076890123	CC	Javier	\N	Montoya	Betancur	1988-07-20	M	3176890123	javier.montoya@email.com	P189	1	81	170	1	85	170
1098567321	CC	Dora	Ines	Salazar	Giraldo	1991-11-07	F	3201567321	dora.salazar@email.com	P267	1	85	170	1	86	170
1054678954	CC	Camilo	Andres	Henao	Botero	1985-05-24	M	3154678954	camilo.henao@email.com	P345	1	86	170	88	5	170
1087789654	CC	Martha	Cecilia	Upegui	Uribe	1992-09-12	F	3198789654	martha.upegui@email.com	P423	88	5	170	1	88	170
1043456123	CC	Nelson	\N	Ochoa	Cardona	1987-12-29	M	3163456123	nelson.ochoa@email.com	P156	564	88	170	1	91	170
1065123789	CC	Angela	Victoria	Velez	Posada	1994-06-16	F	3175123789	angela.velez@email.com	P234	1	91	170	1	94	170
1076321654	CC	Alvaro	Hernan	Zapata	Jaramillo	1989-01-04	M	3176321654	alvaro.zapata@email.com	P312	1	94	170	1	95	170
1098654123	CC	Miriam	\N	Correa	Arbelaez	1986-08-21	F	3201654123	miriam.correa@email.com	P389	1	95	170	1	97	170
1054987324	CC	Orlando	de Jesus	Morales	Agudelo	1993-03-09	M	3154987321	orlando.morales@email.com	P456	1	97	170	1	99	170
1087321987	CC	Stella	Maris	Villa	Hincapie	1990-11-25	F	3198321987	stella.villa@email.com	P167	1	99	170	360	5	170
1043789321	CC	Eduardo	\N	Gallego	Londono	1988-04-13	M	3163789321	eduardo.gallego@email.com	P245	360	5	170	1	8	170
1065456123	CC	Graciela	del Carmen	Alzate	Arango	1991-07-30	F	3175456123	graciela.alzate@email.com	P323	1	8	170	1	25	170
1076123987	CC	William	de Jesus	Ramirez	Munoz	1985-10-17	M	3176123987	william.ramirez@email.com	P401	1	25	170	1	68	170
1098321789	CC	Carmen	Alicia	Giraldo	Castrillon	1994-12-05	F	3201321789	carmen.giraldo@email.com	P178	1	68	170	1	76	170
AB1234567	PP	Carlos	Eduardo	Perez	Johnson	1987-03-22	M	3156789012	carlos.perez@email.com	P256	1	76	170	1	19	170
1054456789	CC	Elizabeth	\N	Cardenas	Mejia	1992-06-08	F	3154456789	elizabeth.cardenas@email.com	P334	1	19	170	1	52	170
1087123987	CC	Guillermo	Antonio	Herrera	Ospina	1989-01-26	M	3198123987	guillermo.herrera@email.com	P412	1	52	170	1	15	170
1043654321	CC	Marta	Lucia	Aguilar	Quintero	1986-09-14	F	3163654321	marta.aguilar@email.com	P189	1	15	170	1	73	170
1065789456	CC	Jorge	Luis	Mendoza	Carvajal	1993-05-02	M	3175789456	jorge.mendoza@email.com	P267	1	73	170	1	54	170
1076654987	CC	Gladys	\N	Franco	Henao	1990-08-19	F	3176654987	gladys.franco@email.com	P345	1	54	170	1	41	170
1098456321	CC	Hernan	Alberto	Zapata	Mejia	1988-11-06	M	3201456321	hernan.zapata@email.com	P423	1	41	170	1	44	170
1054123654	CC	Ofelia	Esperanza	Rios	Valencia	1991-02-23	F	3154123654	ofelia.rios@email.com	P156	1	44	170	1	47	170
1087987321	CC	Armando	\N	Gonzalez	Aristizabal	1985-07-11	M	3198987321	armando.gonzalez@email.com	P234	1	47	170	1	50	170
1043567321	CC	Esperanza	del Pilar	Munoz	Restrepo	1994-12-28	F	3163567321	esperanza.munoz@email.com	P312	1	50	170	1	27	170
1065321987	CC	Alvaro	de Jesus	Bedoya	Cardona	1987-04-15	M	3175321987	alvaro.bedoya@email.com	P389	1	27	170	1	70	170
1076789456	CC	Rosa	Elena	Atehortua	Mesa	1992-09-03	F	3176789456	rosa.atehortua@email.com	P456	1	70	170	1	23	170
1098123987	CC	Mario	\N	Velez	Arias	1989-01-20	M	3201123987	mario.velez@email.com	P167	1	23	170	1	17	170
1054789456	CC	Lucila	Maria	Castano	Giraldo	1986-06-08	F	3154789456	lucila.castano@email.com	P245	1	17	170	1	66	170
12345678	CC	Juan	Pablo	Martinez	Smith	1993-11-25	M	3187654321	juan.martinez@email.com	P323	1	66	170	1	63	170
1087456987	CC	Alba	Nury	Saldarriaga	Velez	1990-03-12	F	3198456987	alba.saldarriaga@email.com	P401	1	63	170	1	76	170
1043321654	CC	Humberto	\N	Pelaez	Moreno	1988-08-29	M	3163321654	humberto.pelaez@email.com	P178	1	76	170	88	5	170
1065654987	CC	Blanca	Rosa	Castaneda	Lopez	1991-12-16	F	3175654987	blanca.castaneda@email.com	P256	88	5	170	1	8	170
1076456321	CC	Aurelio	\N	Mesa	Garcia	1985-05-04	M	3176456321	aurelio.mesa@email.com	P334	1	8	170	1	25	170
1098789654	CC	Gloria	Ines	Tamayo	Rodriguez	1994-10-21	F	3201789654	gloria.tamayo@email.com	P412	1	25	170	1	68	170
1054321789	CC	Ignacio	Maria	Piedrahita	Martinez	1987-01-09	M	3154321789	ignacio.piedrahita@email.com	P189	1	68	170	1	76	170
1087654456	CC	Teresa	\N	Duque	Gonzalez	1092-07-26	F	3198654456	teresa.duque@email.com	P267	1	76	170	1	19	170
1043987654	CC	Reinaldo	de Jesus	Acosta	Ramirez	1989-11-14	M	3163987654	reinaldo.acosta@email.com	P345	1	19	170	1	52	170
1065123456	CC	Amparo	del Socorro	Betancur	Hernandez	1992-04-01	F	3175123456	amparo.betancur@email.com	P423	1	52	170	1	15	170
1076987123	CC	Jairo	\N	Cardenas	Lopez	1986-09-18	M	3176987123	jairo.cardenas@email.com	P156	1	15	170	1	73	170
1098456987	CC	Cecilia	Elena	Grajales	Vargas	1993-02-06	F	3201456987	cecilia.grajales@email.com	P234	1	73	170	1	54	170
1054654321	CC	Fabio	Andres	Marin	Silva	1988-06-23	M	3154654321	fabio.marin@email.com	P312	1	54	170	1	41	170
1087321456	CC	Myriam	\N	Ospina	Torres	1990-12-11	F	3198321456	myriam.ospina@email.com	P389	1	41	170	1	44	170
1043456987	CC	Albeiro	de Jesus	Ruiz	Morales	1985-05-28	M	3163456987	albeiro.ruiz@email.com	P456	1	44	170	1	47	170
1065987654	CC	Amparo	Stella	Cordoba	Gutierrez	1994-10-15	F	3175987654	amparo.cordoba@email.com	P167	1	47	170	1	50	170
1234521341	CC	Luis	Carlos	Vargas	Medina	1991-03-03	M	3201234567	luis.vargas@email.com	P245	1	50	170	1	27	170
1076123654	CC	Maritza	\N	Escobar	Jimenez	1987-08-20	F	3176123654	maritza.escobar@email.com	P323	1	27	170	1	70	170
1098652289	CC	Edgar	Alberto	Valencia	Castro	1992-01-07	M	3201654789	edgar.valencia@email.com	P401	1	70	170	1	23	170
1054987123	CC	Nubia	del Carmen	Giraldo	Diaz	1989-07-24	F	3154987123	nubia.giraldo@email.com	P178	1	23	170	1	17	170
1087789123	CC	Alirio	\N	Montoya	Sanchez	1986-11-12	M	3198789123	alirio.montoya@email.com	P256	1	17	170	1	66	170
1043123789	CC	Ligia	Maria	Arboleda	Gil	1993-04-30	F	3163123789	ligia.arboleda@email.com	P334	1	66	170	1	63	170
1087234569	CC	Andrea	Sofia	Lopez	Martinez	1992-05-12	F	3198765432	andrea.lopez@email.com	P156	1	5	170	40	5	170
1045678912	CC	Carlos	Eduardo	Rodriguez	Gonzalez	1987-09-28	M	3134567890	carlos.rodriguez@gmail.com	P234	55	5	170	1	25	170
1023456789	CC	Maria	Elena	Garcia	\N	1985-03-15	F	3176543210	maria.garcia@hotmail.com	P078	307	25	170	1	5	170
1056789123	CC	Juan	Carlos	Martinez	Silva	1990-11-07	M	3145678901	juan.martinez@yahoo.com	P345	1	8	170	498	54	170
1034567891	CC	Ana	Patricia	Hernandez	Castro	1988-04-22	F	3189012345	ana.hernandez@email.com	P167	498	54	170	1	76	170
1067891234	CC	Miguel	Angel	Vargas	Moreno	1983-12-03	M	3156789012	miguel.vargas@gmail.com	P289	1	76	170	1	68	170
1045123456	CC	Laura	\N	Jimenez	Ruiz	1991-07-19	F	3167890123	laura.jimenez@hotmail.com	P412	1	68	170	1	63	170
1078912345	CC	Pedro	Alfonso	Torres	Diaz	1986-02-14	M	3178901234	pedro.torres@yahoo.com	P098	1	63	170	1	50	170
1034512789	CC	Carmen	Rosa	Mendez	Aguilar	1989-06-08	F	3189012347	carmen.mendez@email.com	P187	1	50	170	1	19	170
1067834512	CC	Andres	Felipe	Gutierrez	\N	1984-10-25	M	3190123456	andres.gutierrez@gmail.com	P276	1	19	170	1	52	170
1045678234	CC	Sandra	Milena	Morales	Guerrero	1993-01-11	F	3201234567	sandra.morales@hotmail.com	P365	1	52	170	1	20	170
1076543218	CC	Roberto	Javier	Perez	Medina	1982-08-29	M	3212345678	roberto.perez@yahoo.com	P154	1	20	170	1	17	170
1034569871	CC	Gloria	Patricia	Ramirez	\N	1987-05-16	F	3223456789	gloria.ramirez@email.com	P243	1	17	170	1	23	170
1065432178	CC	Fernando	Luis	Castillo	Ramos	1985-09-04	M	3234567890	fernando.castillo@gmail.com	P332	1	23	170	1	15	170
1043216789	CC	Esperanza	Teresa	Flores	Cortes	1990-12-21	F	3245678901	esperanza.flores@hotmail.com	P121	1	15	170	1	18	170
1076523519	CC	Javier	Antonio	Silva	Ospina	1979-03-13	M	3256789012	javier.silva@yahoo.com	P210	1	18	170	1	27	170
1034578912	CC	Patricia	Elena	Cardenas	\N	1988-07-30	F	3267890123	patricia.cardenas@email.com	P389	1	27	170	1	41	170
1065879123	CC	Mauricio	Alejandro	Restrepo	Duarte	1986-11-18	M	3278901234	mauricio.restrepo@gmail.com	P178	1	41	170	1	44	170
1043567891	CC	Blanca	Stella	Duarte	Pena	1984-04-05	F	3289012345	blanca.duarte@hotmail.com	P267	1	44	170	1	47	170
1074321987	CC	Jairo	Ricardo	Pena	\N	1991-06-27	M	3290123456	jairo.pena@yahoo.com	P356	1	47	170	1	70	170
1042187659	CC	Cecilia	Maria	Munoz	Beltran	1987-02-14	F	3301234567	cecilia.munoz@email.com	P145	1	70	170	1	73	170
1083654927	CC	Eduardo	Fernando	Beltran	Franco	1983-10-01	M	3312345678	eduardo.beltran@gmail.com	P234	1	73	170	1	66	170
1051234876	CC	Camila	Andrea	Franco	\N	1992-05-19	F	3323456789	camila.franco@hotmail.com	P323	1	66	170	1	81	170
1072345689	CC	Wilson	Armando	Giraldo	Rios	1985-09-06	M	3334567890	wilson.giraldo@yahoo.com	P412	1	81	170	1	85	170
1040987654	CC	Miriam	Esperanza	Rios	Cardona	1989-01-23	F	3345678901	miriam.rios@email.com	P201	1	85	170	1	86	170
1081234567	CC	Gabriel	Emilio	Cardona	\N	1981-08-11	M	3356789012	gabriel.cardona@gmail.com	P290	1	86	170	1	88	170
1049876543	CC	Pilar	Soledad	Montoya	Quintero	1988-12-28	F	3367890123	pilar.montoya@hotmail.com	P379	1	88	170	1	91	170
1078901234	CC	Rafael	Humberto	Quintero	Arango	1984-04-15	M	3378901234	rafael.quintero@yahoo.com	P168	1	91	170	1	94	170
1046789012	CC	Teresa	Mariela	Arango	\N	1990-11-02	F	3389012345	teresa.arango@email.com	P257	1	94	170	1	95	170
1085432167	CC	Ivan	Dario	Valencia	Henao	1986-07-20	M	3390123456	ivan.valencia@gmail.com	P346	1	95	170	1	97	170
1043223487	CC	Gladys	Carmen	Henao	Bedoya	1987-03-07	F	3401234567	gladys.henao@hotmail.com	P135	1	97	170	1	99	170
1074567890	CC	Alvaro	Jesus	Bedoya	\N	1983-09-24	M	3412345678	alvaro.bedoya@yahoo.com	P224	1	99	170	88	5	170
1052341876	CC	Flor	Maria	Tamayo	Correa	1991-06-12	F	3423456789	flor.tamayo@email.com	P313	88	5	170	1	11	170
1081098765	CC	Julian	Esteban	Correa	Zapata	1982-01-29	M	3434567890	julian.correa@gmail.com	P402	1	11	170	307	25	170
1048765432	CC	Ofelia	Rosa	Zapata	\N	1989-08-16	F	3445678901	ofelia.zapata@hotmail.com	P191	307	25	170	1	5	170
1076543310	CC	Gilberto	Andres	Uribe	Galvis	1985-05-03	M	3456789012	gilberto.uribe@yahoo.com	P280	1	5	170	1	8	170
1045678901	CC	Norma	Elena	Galvis	\N	1988-10-21	F	3467890123	norma.galvis@email.com	P369	1	8	170	1	76	170
1083456789	CC	Hernando	Alberto	Escobar	Bermudez	1987-02-08	M	3478901234	hernando.escobar@gmail.com	P158	1	76	170	1	68	170
1052109876	CC	Marta	Lucia	Bermudez	\N	1990-11-25	F	3489012345	marta.bermudez@hotmail.com	P247	1	68	170	1	63	170
1074321098	CC	Octavio	Rafael	Patino	Marin	1984-04-13	M	3490123456	octavio.patino@yahoo.com	P336	1	63	170	1	50	170
1043876521	CC	Consuelo	Teresa	Marin	Salinas	1986-07-30	F	3501234567	consuelo.marin@email.com	P125	1	50	170	1	19	170
1081234098	CC	Arturo	German	Salinas	\N	1983-12-17	M	3512345678	arturo.salinas@gmail.com	P214	1	19	170	1	52	170
1049567834	CC	Esperanza	Rocio	Castano	Mejia	1991-09-04	F	3523456789	esperanza.castano@hotmail.com	P303	1	52	170	1	20	170
1076893323	CC	Rodrigo	Bernardo	Mejia	Gaviria	1987-03-22	M	3534567890	rodrigo.mejia@yahoo.com	P392	1	20	170	1	17	170
1045321876	CC	Aura	Stella	Gaviria	\N	1985-08-09	F	3545678901	aura.gaviria@email.com	P181	1	17	170	1	23	170
1083654210	CC	Ernesto	Carlos	Piedrahita	Villa	1989-01-26	M	3556789012	ernesto.piedrahita@gmail.com	P270	1	23	170	1	15	170
1051987654	CC	Magnolia	Elena	Villa	Caballero	1988-06-14	F	3567890123	magnolia.villa@hotmail.com	P359	1	15	170	1	18	170
1072345876	CC	Alejandro	Dario	Caballero	\N	1984-11-01	M	3578901234	alejandro.caballero@yahoo.com	P148	1	18	170	1	27	170
1040654321	CC	Nelly	Carmen	Montoya	Betancur	1990-05-19	F	3589012345	nelly.montoya@email.com	P237	1	27	170	1	41	170
1081098432	CC	Armando	Jose	Betancur	Giraldo	1986-10-06	M	3590123456	armando.betancur@gmail.com	P326	1	41	170	1	44	170
1049765123	CC	Marlene	Patricia	Giraldo	\N	1987-02-23	F	3601234567	marlene.giraldo@hotmail.com	P415	1	44	170	1	47	170
1078432109	CC	Jaime	Orlando	Ospina	Restrepo	1983-07-11	M	3612345678	jaime.ospina@yahoo.com	P104	1	47	170	1	70	170
1046521098	CC	Zoila	Maria	Restrepo	\N	1991-12-28	F	3623456789	zoila.restrepo@email.com	P193	1	70	170	1	73	170
1523456733	CC	Valeria	Sofia	Duque	Ramirez	2008-11-15	F	3634567890	valeria.duque@gmail.com	P282	1	73	170	1	66	170
1083210765	CC	Edgar	Guillermo	Ramirez	Sanchez	1985-04-02	M	3645678901	edgar.ramirez@hotmail.com	P371	1	66	170	1	81	170
1051654321	CC	Elena	Rosa	Sanchez	\N	1988-09-20	F	3656789012	elena.sanchez@yahoo.com	P160	1	81	170	1	85	170
1072109876	CC	Winston	Alexander	Velasquez	Gutierrez	1987-01-07	M	3667890123	winston.velasquez@email.com	P249	1	85	170	1	86	170
1040987321	CC	Yolanda	Patricia	Gutierrez	\N	1984-08-24	F	3678901234	yolanda.gutierrez@gmail.com	P338	1	86	170	1	88	170
1081543210	CC	Nelson	Alberto	Acosta	Lopez	1990-05-12	M	3689012345	nelson.acosta@hotmail.com	P127	1	88	170	1	91	170
1049321876	CC	Rosaura	Amparo	Lopez	\N	1986-10-29	F	3690123456	rosaura.lopez@yahoo.com	P216	1	91	170	1	94	170
1078654321	CC	Gonzalo	Enrique	Martinez	Rojas	1989-03-16	M	3701234567	gonzalo.martinez@email.com	P305	1	94	170	1	95	170
1046789321	CC	Ines	Esperanza	Rojas	Castro	1987-12-03	F	3712345678	ines.rojas@gmail.com	P394	1	95	170	1	97	170
1008200987	CC	Ruben	Dario	Castro	\N	1983-07-21	M	3723456789	ruben.castro@hotmail.com	P183	1	97	170	1	99	170
1053456789	CC	Delia	Carmen	Herrera	Silva	1991-02-08	F	3734567890	delia.herrera@yahoo.com	P272	1	99	170	88	5	170
1074321654	CC	Crisanto	Felipe	Silva	Vargas	1985-09-25	M	3745678901	crisanto.silva@email.com	P361	88	5	170	1	11	170
1042987654	CC	Berenice	Gloria	Vargas	\N	1988-04-13	F	3756789012	berenice.vargas@gmail.com	P150	1	11	170	307	25	170
1083456210	CC	Anibal	Carlos	Morales	Perez	1987-11-30	M	3767890123	anibal.morales@hotmail.com	P239	307	25	170	1	5	170
1051789654	CC	Margarita	Elena	Perez	\N	1984-06-17	F	3778901234	margarita.perez@yahoo.com	P328	1	5	170	1	8	170
1072543210	CC	Leonidas	Jose	Jimenez	Torres	1990-01-04	M	3789012345	leonidas.jimenez@email.com	P417	1	8	170	1	76	170
\.


                                                                                                                                                                                                                                                                                                                                                                                                               4949.dat                                                                                            0000600 0004000 0002000 00000000776 15015342721 0014275 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        5	170	ANTIOQUIA
8	170	ATLANTICO
11	170	BOGOTA
13	170	BOLIVAR
15	170	BOYACA
17	170	CALDAS
18	170	CAQUETA
19	170	CAUCA
20	170	CESAR
23	170	CORDOBA
25	170	CUNDINAMARCA
27	170	CHOCO
41	170	HUILA
44	170	LA GUAJIRA
47	170	MAGDALENA
50	170	META
52	170	NARIÑO
54	170	NORTE SANTANDER
63	170	QUINDIO
66	170	RISARALDA
68	170	SANTANDER
70	170	SUCRE
73	170	TOLIMA
76	170	VALLE
81	170	ARAUCA
85	170	CASANARE
86	170	PUTUMAYO
88	170	SAN ANDRES
91	170	AMAZONAS
94	170	GUAINIA
95	170	GUAVIARE
97	170	VAUPES
99	170	VICHADA
\.


  4961.dat                                                                                            0000600 0004000 0002000 00000204616 15015342721 0014266 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	101	25000.00	2	2019-02-13	2019-02-15	10.00	5000.00	45000.00
2	2	111	35000.00	1	2019-08-20	2019-08-21	0.00	0.00	35000.00
2	3	109	35000.00	1	2019-08-21	2019-08-22	0.00	0.00	0.00
2	4	109	35000.00	1	2019-08-21	2019-08-22	5.00	1750.00	33250.00
3	5	109	35000.00	5	2024-11-15	2024-11-20	0.00	0.00	175000.00
8	6	118	25000.00	13	2025-02-02	2025-02-15	0.00	0.00	325000.00
11	7	107	35000.00	8	2023-08-13	2023-08-21	0.00	0.00	280000.00
12	8	103	35000.00	15	2023-10-19	2023-11-03	0.00	0.00	525000.00
15	9	126	25000.00	3	2021-06-03	2021-06-06	0.00	0.00	75000.00
16	10	101	35000.00	2	2020-06-26	2020-06-28	0.00	0.00	70000.00
17	11	109	35000.00	10	2019-11-19	2019-11-29	10.00	35000.00	315000.00
21	12	107	35000.00	5	2021-07-21	2021-07-26	0.00	0.00	175000.00
22	13	120	25000.00	6	2019-12-07	2019-12-13	0.00	0.00	150000.00
24	14	119	35000.00	12	2023-07-04	2023-07-16	0.00	0.00	420000.00
28	15	116	25000.00	12	2021-12-25	2022-01-06	0.00	0.00	300000.00
29	16	106	25000.00	5	2022-06-30	2022-07-05	0.00	0.00	125000.00
31	17	114	25000.00	9	2024-11-19	2024-11-28	0.00	0.00	225000.00
35	18	101	35000.00	11	2025-01-04	2025-01-15	0.00	0.00	385000.00
36	19	127	25000.00	3	2019-08-08	2019-08-11	3.00	2250.00	72750.00
40	20	103	35000.00	4	2020-01-11	2020-01-15	4.00	5600.00	134400.00
43	21	110	25000.00	3	2020-02-06	2020-02-09	3.00	2250.00	72750.00
44	22	116	25000.00	3	2022-11-13	2022-11-16	3.00	2250.00	72750.00
45	23	115	35000.00	11	2021-03-05	2021-03-16	11.00	42350.00	342650.00
46	24	101	35000.00	9	2022-02-16	2022-02-25	9.00	28350.00	286650.00
47	25	113	35000.00	15	2019-07-24	2019-08-08	15.00	78750.00	446250.00
48	26	115	35000.00	4	2019-11-20	2019-11-24	5.00	7000.00	133000.00
49	27	127	25000.00	7	2022-12-14	2022-12-21	5.00	8750.00	166250.00
51	28	117	35000.00	11	2021-04-14	2021-04-25	5.00	19250.00	365750.00
53	29	115	35000.00	10	2021-12-17	2021-12-27	0.00	0.00	350000.00
56	30	109	35000.00	6	2023-05-05	2023-05-11	0.00	0.00	210000.00
58	31	115	35000.00	11	2023-07-25	2023-08-05	0.00	0.00	385000.00
59	32	111	35000.00	14	2025-02-07	2025-02-21	0.00	0.00	490000.00
61	33	107	35000.00	15	2020-06-11	2020-06-26	0.00	0.00	525000.00
63	34	113	35000.00	4	2020-05-14	2020-05-18	0.00	0.00	140000.00
65	35	115	35000.00	14	2023-09-14	2023-09-28	0.00	0.00	490000.00
70	36	123	25000.00	12	2023-02-07	2023-02-19	0.00	0.00	300000.00
72	37	105	35000.00	5	2023-02-05	2023-02-10	0.00	0.00	175000.00
79	38	111	35000.00	11	2025-02-24	2025-03-07	0.00	0.00	385000.00
92	39	108	25000.00	4	2024-08-29	2024-09-02	0.00	0.00	100000.00
93	40	126	25000.00	3	2023-07-01	2023-07-04	0.00	0.00	75000.00
95	41	120	25000.00	8	2019-11-08	2019-11-16	0.00	0.00	200000.00
103	42	112	25000.00	11	2024-07-16	2024-07-27	0.00	0.00	275000.00
104	43	123	25000.00	2	2024-02-05	2024-02-07	0.00	0.00	50000.00
110	44	105	35000.00	6	2020-03-30	2020-04-05	0.00	0.00	210000.00
115	45	101	35000.00	4	2022-12-17	2022-12-21	0.00	0.00	140000.00
118	46	101	35000.00	6	2023-04-12	2023-04-18	0.00	0.00	210000.00
119	47	103	35000.00	6	2025-02-10	2025-02-16	0.00	0.00	210000.00
123	48	117	35000.00	2	2024-01-13	2024-01-15	10.00	7000.00	63000.00
125	49	107	35000.00	8	2021-02-27	2021-03-07	15.00	42000.00	238000.00
130	50	124	25000.00	4	2023-11-07	2023-11-11	0.00	0.00	100000.00
131	51	121	25000.00	6	2023-02-18	2023-02-24	6.00	9000.00	141000.00
132	52	120	25000.00	8	2022-04-02	2022-04-10	0.00	0.00	200000.00
134	53	109	35000.00	2	2024-12-20	2024-12-22	0.00	0.00	70000.00
136	54	101	35000.00	11	2024-12-14	2024-12-25	0.00	0.00	385000.00
137	55	101	35000.00	7	2021-01-21	2021-01-28	0.00	0.00	245000.00
138	56	104	25000.00	11	2021-06-15	2021-06-26	0.00	0.00	275000.00
143	57	103	35000.00	9	2020-11-11	2020-11-20	0.00	0.00	315000.00
144	58	127	25000.00	13	2019-01-30	2019-02-12	0.00	0.00	325000.00
148	59	108	25000.00	12	2025-01-02	2025-01-14	0.00	0.00	300000.00
150	60	101	35000.00	8	2024-01-27	2024-02-04	0.00	0.00	280000.00
162	61	117	35000.00	3	2019-06-17	2019-06-20	0.00	0.00	105000.00
166	62	102	25000.00	2	2019-02-15	2019-02-17	0.00	0.00	50000.00
168	63	120	25000.00	2	2020-04-19	2020-04-21	0.00	0.00	50000.00
170	64	119	35000.00	6	2023-11-25	2023-12-01	0.00	0.00	210000.00
174	65	107	35000.00	11	2023-09-16	2023-09-27	0.00	0.00	385000.00
178	66	126	25000.00	2	2023-01-23	2023-01-25	0.00	0.00	50000.00
182	67	103	35000.00	14	2021-12-09	2021-12-23	0.00	0.00	490000.00
187	68	107	35000.00	13	2020-05-29	2020-06-11	0.00	0.00	455000.00
189	69	109	35000.00	4	2023-04-27	2023-05-01	0.00	0.00	140000.00
191	70	106	25000.00	10	2023-03-23	2023-04-02	0.00	0.00	250000.00
192	71	107	35000.00	14	2024-04-13	2024-04-27	0.00	0.00	490000.00
199	72	127	25000.00	13	2023-03-31	2023-04-13	0.00	0.00	325000.00
201	73	114	25000.00	9	2024-02-22	2024-03-02	0.00	0.00	225000.00
202	74	109	35000.00	11	2024-07-12	2024-07-23	0.00	0.00	385000.00
207	75	104	25000.00	7	2021-01-21	2021-01-28	0.00	0.00	175000.00
209	76	126	25000.00	14	2023-09-03	2023-09-17	0.00	0.00	350000.00
211	77	122	25000.00	7	2024-02-25	2024-03-03	0.00	0.00	175000.00
213	78	117	35000.00	2	2024-03-28	2024-03-30	0.00	0.00	70000.00
225	79	107	35000.00	14	2022-07-10	2022-07-24	0.00	0.00	490000.00
229	80	115	35000.00	13	2021-02-03	2021-02-16	0.00	0.00	455000.00
230	81	116	25000.00	11	2023-06-21	2023-07-02	0.00	0.00	275000.00
252	82	120	25000.00	15	2019-08-01	2019-08-16	0.00	0.00	375000.00
254	83	112	25000.00	10	2019-12-30	2020-01-09	0.00	0.00	250000.00
259	84	125	25000.00	14	2021-07-27	2021-08-10	0.00	0.00	350000.00
260	85	113	35000.00	9	2023-03-03	2023-03-12	0.00	0.00	315000.00
261	86	126	25000.00	8	2019-08-20	2019-08-28	0.00	0.00	200000.00
262	87	109	35000.00	10	2019-04-27	2019-05-07	0.00	0.00	350000.00
263	88	107	35000.00	6	2022-07-16	2022-07-22	0.00	0.00	210000.00
268	89	111	35000.00	13	2023-07-09	2023-07-22	0.00	0.00	455000.00
270	90	102	25000.00	9	2020-01-24	2020-02-02	0.00	0.00	225000.00
271	91	124	25000.00	5	2024-06-30	2024-07-05	0.00	0.00	125000.00
272	92	111	35000.00	12	2025-04-21	2025-05-03	0.00	0.00	420000.00
273	93	101	35000.00	11	2020-08-02	2020-08-13	0.00	0.00	385000.00
278	95	109	35000.00	6	2025-03-18	2025-03-24	0.00	0.00	210000.00
279	96	103	35000.00	13	2023-10-20	2023-11-02	0.00	0.00	455000.00
284	97	126	25000.00	6	2020-05-19	2020-05-25	0.00	0.00	150000.00
286	98	107	35000.00	3	2024-10-25	2024-10-28	0.00	0.00	105000.00
288	99	116	25000.00	7	2020-09-23	2020-09-30	0.00	0.00	175000.00
290	100	103	35000.00	14	2024-11-29	2024-12-13	0.00	0.00	490000.00
293	101	108	25000.00	13	2023-09-26	2023-10-09	0.00	0.00	325000.00
295	102	124	25000.00	11	2023-11-13	2023-11-24	0.00	0.00	275000.00
300	103	103	35000.00	9	2024-04-14	2024-04-23	0.00	0.00	315000.00
307	104	108	25000.00	11	2024-09-26	2024-10-07	0.00	0.00	275000.00
308	105	116	25000.00	14	2023-11-08	2023-11-22	0.00	0.00	350000.00
312	106	111	35000.00	13	2024-10-31	2024-11-13	0.00	0.00	455000.00
314	107	106	25000.00	12	2019-05-31	2019-06-12	0.00	0.00	300000.00
315	108	124	25000.00	10	2020-02-01	2020-02-11	0.00	0.00	250000.00
329	109	119	35000.00	10	2019-07-21	2019-07-31	0.00	0.00	350000.00
331	110	123	25000.00	15	2024-03-12	2024-03-27	0.00	0.00	375000.00
336	111	109	35000.00	14	2021-08-31	2021-09-14	0.00	0.00	490000.00
344	112	117	35000.00	7	2023-02-10	2023-02-17	0.00	0.00	245000.00
349	113	110	25000.00	10	2024-08-10	2024-08-20	0.00	0.00	250000.00
351	114	103	35000.00	7	2023-08-28	2023-09-04	0.00	0.00	245000.00
353	115	104	25000.00	2	2020-01-07	2020-01-09	0.00	0.00	50000.00
357	116	103	35000.00	14	2024-01-16	2024-01-30	0.00	0.00	490000.00
359	117	127	25000.00	8	2024-05-27	2024-06-04	0.00	0.00	200000.00
363	118	117	35000.00	3	2025-03-18	2025-03-21	0.00	0.00	105000.00
364	119	112	25000.00	8	2025-05-22	2025-05-30	0.00	0.00	200000.00
367	120	105	35000.00	1	2022-05-04	2022-05-05	0.00	0.00	35000.00
368	121	105	35000.00	12	2025-01-12	2025-01-24	0.00	0.00	420000.00
374	122	113	35000.00	6	2019-06-16	2019-06-22	0.00	0.00	210000.00
378	123	119	35000.00	2	2019-04-16	2019-04-18	0.00	0.00	70000.00
380	124	103	35000.00	15	2022-09-14	2022-09-29	0.00	0.00	525000.00
384	125	118	25000.00	9	2020-11-17	2020-11-26	0.00	0.00	225000.00
389	126	118	25000.00	11	2020-05-14	2020-05-25	0.00	0.00	275000.00
390	127	105	35000.00	11	2021-05-01	2021-05-12	0.00	0.00	385000.00
397	128	106	25000.00	8	2023-07-12	2023-07-20	0.00	0.00	200000.00
398	129	117	35000.00	6	2023-06-22	2023-06-28	0.00	0.00	210000.00
399	130	118	25000.00	8	2023-10-18	2023-10-26	0.00	0.00	200000.00
401	131	111	35000.00	1	2024-09-11	2024-09-12	0.00	0.00	35000.00
403	132	116	25000.00	7	2023-10-06	2023-10-13	0.00	0.00	175000.00
404	133	106	25000.00	10	2022-10-12	2022-10-22	0.00	0.00	250000.00
408	134	115	35000.00	13	2023-02-01	2023-02-14	0.00	0.00	455000.00
412	135	119	35000.00	6	2024-03-27	2024-04-02	0.00	0.00	210000.00
416	136	111	35000.00	14	2024-11-26	2024-12-10	0.00	0.00	490000.00
423	137	115	35000.00	1	2021-07-10	2021-07-11	0.00	0.00	35000.00
425	138	116	25000.00	14	2019-12-27	2020-01-10	0.00	0.00	350000.00
426	139	122	25000.00	7	2019-10-19	2019-10-26	0.00	0.00	175000.00
427	140	118	25000.00	3	2022-03-30	2022-04-02	0.00	0.00	75000.00
429	141	113	35000.00	6	2023-05-12	2023-05-18	0.00	0.00	210000.00
430	142	103	35000.00	13	2024-04-26	2024-05-09	0.00	0.00	455000.00
435	143	101	35000.00	4	2023-03-13	2023-03-17	0.00	0.00	140000.00
437	144	126	25000.00	5	2021-09-10	2021-09-15	0.00	0.00	125000.00
439	145	123	25000.00	11	2019-12-24	2020-01-04	0.00	0.00	275000.00
440	146	119	35000.00	2	2019-05-27	2019-05-29	0.00	0.00	70000.00
442	147	119	35000.00	6	2022-04-30	2022-05-06	0.00	0.00	210000.00
443	148	103	35000.00	4	2021-06-22	2021-06-26	0.00	0.00	140000.00
446	149	109	35000.00	1	2020-07-03	2020-07-04	0.00	0.00	35000.00
447	150	117	35000.00	9	2023-04-24	2023-05-03	0.00	0.00	315000.00
450	151	125	25000.00	8	2021-05-10	2021-05-18	0.00	0.00	200000.00
451	152	108	25000.00	15	2024-12-24	2025-01-08	0.00	0.00	375000.00
466	153	116	25000.00	13	2020-03-07	2020-03-20	0.00	0.00	325000.00
467	154	112	25000.00	2	2024-06-14	2024-06-16	0.00	0.00	50000.00
469	155	101	35000.00	5	2021-01-07	2021-01-12	0.00	0.00	175000.00
471	156	102	25000.00	15	2021-08-08	2021-08-23	0.00	0.00	375000.00
472	157	123	25000.00	8	2022-11-24	2022-12-02	0.00	0.00	200000.00
482	158	114	25000.00	3	2023-06-23	2023-06-26	0.00	0.00	75000.00
487	159	120	25000.00	9	2021-06-25	2021-07-04	0.00	0.00	225000.00
492	160	120	25000.00	3	2020-04-09	2020-04-12	0.00	0.00	75000.00
496	161	107	35000.00	6	2023-02-28	2023-03-06	0.00	0.00	210000.00
497	162	108	25000.00	13	2022-02-06	2022-02-19	0.00	0.00	325000.00
498	163	122	25000.00	4	2024-09-23	2024-09-27	0.00	0.00	100000.00
502	164	111	35000.00	15	2023-05-27	2023-06-11	0.00	0.00	525000.00
503	165	122	25000.00	13	2025-03-03	2025-03-16	0.00	0.00	325000.00
510	166	124	25000.00	6	2022-10-02	2022-10-08	0.00	0.00	150000.00
511	167	103	35000.00	9	2022-11-15	2022-11-24	0.00	0.00	315000.00
512	168	108	25000.00	1	2022-04-27	2022-04-28	0.00	0.00	25000.00
514	169	123	25000.00	4	2023-05-12	2023-05-16	0.00	0.00	100000.00
518	170	115	35000.00	9	2023-01-04	2023-01-13	0.00	0.00	315000.00
519	171	107	35000.00	8	2023-06-10	2023-06-18	0.00	0.00	280000.00
522	172	127	25000.00	2	2019-04-08	2019-04-10	0.00	0.00	50000.00
525	173	126	25000.00	4	2021-10-19	2021-10-23	0.00	0.00	100000.00
527	174	106	25000.00	15	2022-03-01	2022-03-16	0.00	0.00	375000.00
529	175	103	35000.00	4	2024-03-19	2024-03-23	0.00	0.00	140000.00
534	176	103	35000.00	7	2021-03-20	2021-03-27	0.00	0.00	245000.00
536	177	124	25000.00	10	2022-08-16	2022-08-26	0.00	0.00	250000.00
537	178	105	35000.00	8	2019-11-04	2019-11-12	0.00	0.00	280000.00
553	179	105	35000.00	5	2020-09-15	2020-09-20	0.00	0.00	175000.00
554	180	118	25000.00	4	2019-01-13	2019-01-17	0.00	0.00	100000.00
555	181	101	35000.00	10	2025-01-07	2025-01-17	0.00	0.00	350000.00
568	182	103	35000.00	14	2021-09-21	2021-10-05	0.00	0.00	490000.00
577	183	109	35000.00	2	2019-07-25	2019-07-27	0.00	0.00	70000.00
579	184	124	25000.00	8	2021-06-03	2021-06-11	0.00	0.00	200000.00
583	185	119	35000.00	2	2019-02-19	2019-02-21	0.00	0.00	70000.00
584	186	116	25000.00	1	2020-03-11	2020-03-12	0.00	0.00	25000.00
586	187	117	35000.00	4	2024-02-16	2024-02-20	0.00	0.00	140000.00
588	188	111	35000.00	4	2021-08-06	2021-08-10	0.00	0.00	140000.00
591	189	121	25000.00	11	2022-08-08	2022-08-19	0.00	0.00	275000.00
600	190	113	35000.00	8	2019-06-18	2019-06-26	0.00	0.00	280000.00
604	191	123	25000.00	14	2024-01-25	2024-02-08	0.00	0.00	350000.00
605	192	118	25000.00	4	2024-12-22	2024-12-26	0.00	0.00	100000.00
606	193	113	35000.00	12	2023-11-21	2023-12-03	0.00	0.00	420000.00
607	194	107	35000.00	7	2024-02-11	2024-02-18	0.00	0.00	245000.00
613	195	112	25000.00	6	2023-12-16	2023-12-22	0.00	0.00	150000.00
620	196	101	35000.00	15	2022-02-19	2022-03-06	0.00	0.00	525000.00
621	197	103	35000.00	7	2022-12-11	2022-12-18	0.00	0.00	245000.00
623	198	102	25000.00	9	2023-03-10	2023-03-19	0.00	0.00	225000.00
624	199	116	25000.00	6	2025-04-10	2025-04-16	0.00	0.00	150000.00
627	200	124	25000.00	11	2021-02-17	2021-02-28	0.00	0.00	275000.00
631	201	112	25000.00	1	2022-03-28	2022-03-29	0.00	0.00	25000.00
632	202	104	25000.00	15	2024-02-18	2024-03-04	0.00	0.00	375000.00
642	203	127	25000.00	13	2024-09-22	2024-10-05	0.00	0.00	325000.00
643	204	102	25000.00	2	2025-01-14	2025-01-16	0.00	0.00	50000.00
644	205	124	25000.00	2	2024-02-22	2024-02-24	0.00	0.00	50000.00
649	206	101	35000.00	15	2021-08-18	2021-09-02	0.00	0.00	525000.00
651	207	118	25000.00	14	2022-12-30	2023-01-13	0.00	0.00	350000.00
659	208	107	35000.00	14	2021-02-15	2021-03-01	0.00	0.00	490000.00
663	209	124	25000.00	4	2021-01-12	2021-01-16	0.00	0.00	100000.00
668	210	121	25000.00	14	2021-12-18	2022-01-01	0.00	0.00	350000.00
678	211	118	25000.00	2	2019-03-08	2019-03-10	0.00	0.00	50000.00
679	212	103	35000.00	2	2023-10-31	2023-11-02	0.00	0.00	70000.00
682	213	124	25000.00	2	2020-04-08	2020-04-10	0.00	0.00	50000.00
683	214	126	25000.00	8	2020-11-17	2020-11-25	0.00	0.00	200000.00
684	215	125	25000.00	13	2023-10-02	2023-10-15	0.00	0.00	325000.00
687	216	111	35000.00	7	2019-10-14	2019-10-21	0.00	0.00	245000.00
688	217	115	35000.00	13	2020-06-20	2020-07-03	0.00	0.00	455000.00
690	218	104	25000.00	1	2022-01-16	2022-01-17	0.00	0.00	25000.00
691	219	107	35000.00	6	2024-02-20	2024-02-26	0.00	0.00	210000.00
693	220	118	25000.00	2	2019-10-14	2019-10-16	0.00	0.00	50000.00
695	221	116	25000.00	6	2021-05-31	2021-06-06	0.00	0.00	150000.00
696	222	117	35000.00	9	2022-09-30	2022-10-09	0.00	0.00	315000.00
697	223	109	35000.00	14	2019-04-23	2019-05-07	0.00	0.00	490000.00
700	224	103	35000.00	1	2019-09-22	2019-09-23	0.00	0.00	35000.00
703	225	126	25000.00	5	2021-04-05	2021-04-10	0.00	0.00	125000.00
708	226	113	35000.00	11	2021-10-06	2021-10-17	0.00	0.00	385000.00
710	227	126	25000.00	10	2024-01-09	2024-01-19	0.00	0.00	250000.00
712	228	102	25000.00	3	2025-01-20	2025-01-23	0.00	0.00	75000.00
715	229	101	35000.00	8	2022-02-12	2022-02-20	0.00	0.00	280000.00
716	230	105	35000.00	11	2019-08-25	2019-09-05	0.00	0.00	385000.00
717	231	118	25000.00	10	2024-05-26	2024-06-05	0.00	0.00	250000.00
720	232	104	25000.00	1	2019-08-30	2019-08-31	0.00	0.00	25000.00
723	233	124	25000.00	1	2024-04-26	2024-04-27	0.00	0.00	25000.00
726	234	115	35000.00	15	2019-08-14	2019-08-29	0.00	0.00	525000.00
727	235	108	25000.00	14	2021-02-11	2021-02-25	0.00	0.00	350000.00
728	236	109	35000.00	13	2020-09-30	2020-10-13	0.00	0.00	455000.00
733	237	121	25000.00	1	2024-05-17	2024-05-18	0.00	0.00	25000.00
735	238	119	35000.00	10	2021-05-04	2021-05-14	0.00	0.00	350000.00
738	239	109	35000.00	2	2020-12-03	2020-12-05	0.00	0.00	70000.00
743	240	125	25000.00	15	2023-05-22	2023-06-06	0.00	0.00	375000.00
748	241	106	25000.00	13	2023-01-15	2023-01-28	0.00	0.00	325000.00
750	242	101	35000.00	3	2021-04-25	2021-04-28	0.00	0.00	105000.00
751	243	118	25000.00	1	2023-10-26	2023-10-27	0.00	0.00	25000.00
754	244	113	35000.00	3	2024-07-25	2024-07-28	0.00	0.00	105000.00
759	245	109	35000.00	2	2020-11-20	2020-11-22	0.00	0.00	70000.00
763	246	117	35000.00	12	2024-10-29	2024-11-10	0.00	0.00	420000.00
765	247	102	25000.00	11	2020-04-12	2020-04-23	0.00	0.00	275000.00
767	248	121	25000.00	10	2021-04-09	2021-04-19	0.00	0.00	250000.00
768	249	115	35000.00	7	2021-09-02	2021-09-09	0.00	0.00	245000.00
774	250	111	35000.00	14	2023-10-18	2023-11-01	0.00	0.00	490000.00
781	251	102	25000.00	7	2020-12-31	2021-01-07	0.00	0.00	175000.00
785	252	101	35000.00	15	2022-07-10	2022-07-25	0.00	0.00	525000.00
791	253	120	25000.00	10	2021-03-04	2021-03-14	0.00	0.00	250000.00
793	254	116	25000.00	3	2023-06-06	2023-06-09	0.00	0.00	75000.00
797	255	107	35000.00	15	2023-02-15	2023-03-02	0.00	0.00	525000.00
799	256	106	25000.00	3	2021-02-15	2021-02-18	0.00	0.00	75000.00
800	257	121	25000.00	12	2024-05-06	2024-05-18	0.00	0.00	300000.00
805	258	114	25000.00	11	2023-06-23	2023-07-04	0.00	0.00	275000.00
807	259	101	35000.00	7	2023-07-19	2023-07-26	0.00	0.00	245000.00
819	260	106	25000.00	3	2022-03-21	2022-03-24	0.00	0.00	75000.00
820	261	104	25000.00	7	2020-11-03	2020-11-10	0.00	0.00	175000.00
829	262	101	35000.00	15	2021-03-20	2021-04-04	0.00	0.00	525000.00
831	263	112	25000.00	10	2020-07-17	2020-07-27	0.00	0.00	250000.00
833	264	113	35000.00	15	2020-04-26	2020-05-11	0.00	0.00	525000.00
834	265	112	25000.00	3	2025-01-22	2025-01-25	0.00	0.00	75000.00
835	266	125	25000.00	10	2025-01-12	2025-01-22	0.00	0.00	250000.00
839	267	117	35000.00	9	2023-04-27	2023-05-06	0.00	0.00	315000.00
843	268	123	25000.00	11	2021-08-04	2021-08-15	0.00	0.00	275000.00
844	269	116	25000.00	3	2020-01-02	2020-01-05	0.00	0.00	75000.00
845	270	121	25000.00	8	2019-02-17	2019-02-25	0.00	0.00	200000.00
853	271	101	35000.00	12	2021-07-13	2021-07-25	0.00	0.00	420000.00
854	272	124	25000.00	2	2020-03-20	2020-03-22	0.00	0.00	50000.00
858	273	119	35000.00	15	2019-07-02	2019-07-17	0.00	0.00	525000.00
861	274	107	35000.00	3	2025-01-31	2025-02-03	0.00	0.00	105000.00
866	275	105	35000.00	2	2023-06-17	2023-06-19	0.00	0.00	70000.00
876	276	111	35000.00	8	2022-11-17	2022-11-25	0.00	0.00	280000.00
877	277	116	25000.00	15	2025-02-16	2025-03-03	0.00	0.00	375000.00
881	278	124	25000.00	5	2023-04-18	2023-04-23	0.00	0.00	125000.00
883	279	119	35000.00	13	2019-05-30	2019-06-12	0.00	0.00	455000.00
884	280	101	35000.00	3	2021-03-24	2021-03-27	0.00	0.00	105000.00
885	281	123	25000.00	7	2023-07-10	2023-07-17	0.00	0.00	175000.00
888	282	111	35000.00	10	2022-01-28	2022-02-07	10.00	35000.00	315000.00
896	283	123	25000.00	7	2022-09-11	2022-09-18	0.00	0.00	175000.00
902	284	122	25000.00	15	2024-08-22	2024-09-06	15.00	56250.00	318750.00
909	285	115	35000.00	3	2025-04-20	2025-04-23	0.00	0.00	105000.00
917	286	122	25000.00	8	2025-03-11	2025-03-19	0.00	0.00	200000.00
923	287	103	35000.00	3	2023-09-17	2023-09-20	0.00	0.00	105000.00
926	288	103	35000.00	6	2022-02-05	2022-02-11	0.00	0.00	210000.00
929	289	109	35000.00	1	2024-04-29	2024-04-30	0.00	0.00	35000.00
936	290	116	25000.00	13	2021-08-08	2021-08-21	0.00	0.00	325000.00
940	291	121	25000.00	3	2023-01-01	2023-01-04	0.00	0.00	75000.00
941	292	107	35000.00	14	2021-03-06	2021-03-20	0.00	0.00	490000.00
944	293	107	35000.00	12	2022-06-24	2022-07-06	0.00	0.00	420000.00
945	294	105	35000.00	9	2024-03-11	2024-03-20	0.00	0.00	315000.00
947	295	112	25000.00	1	2025-05-17	2025-05-18	0.00	0.00	25000.00
949	296	117	35000.00	8	2020-05-07	2020-05-15	0.00	0.00	280000.00
954	297	103	35000.00	7	2025-01-01	2025-01-08	0.00	0.00	245000.00
956	298	117	35000.00	2	2020-03-14	2020-03-16	0.00	0.00	70000.00
958	299	127	25000.00	10	2021-02-08	2021-02-18	0.00	0.00	250000.00
960	300	113	35000.00	14	2020-12-26	2021-01-09	0.00	0.00	490000.00
963	301	120	25000.00	7	2021-01-23	2021-01-30	0.00	0.00	175000.00
969	302	104	25000.00	14	2025-04-01	2025-04-15	0.00	0.00	350000.00
973	303	125	25000.00	8	2024-09-25	2024-10-03	0.00	0.00	200000.00
975	304	110	25000.00	7	2022-08-03	2022-08-10	0.00	0.00	175000.00
977	305	124	25000.00	13	2022-04-25	2022-05-08	0.00	0.00	325000.00
980	306	125	25000.00	11	2020-06-08	2020-06-19	0.00	0.00	275000.00
984	307	117	35000.00	14	2019-12-19	2020-01-02	0.00	0.00	490000.00
985	308	114	25000.00	9	2023-10-05	2023-10-14	0.00	0.00	225000.00
988	309	122	25000.00	4	2022-02-05	2022-02-09	0.00	0.00	100000.00
990	310	105	35000.00	1	2021-10-17	2021-10-18	0.00	0.00	35000.00
992	311	115	35000.00	6	2019-07-25	2019-07-31	0.00	0.00	210000.00
999	312	127	25000.00	14	2019-05-06	2019-05-20	0.00	0.00	350000.00
1000	313	119	35000.00	15	2019-02-01	2019-02-16	0.00	0.00	525000.00
1001	314	125	25000.00	11	2019-11-15	2019-11-26	0.00	0.00	275000.00
1002	315	118	25000.00	12	2023-06-25	2023-07-07	0.00	0.00	300000.00
1003	316	113	35000.00	11	2021-12-02	2021-12-13	0.00	0.00	385000.00
1004	317	126	25000.00	5	2022-09-19	2022-09-24	0.00	0.00	125000.00
1005	318	116	25000.00	9	2023-07-18	2023-07-27	0.00	0.00	225000.00
1006	319	122	25000.00	13	2025-02-04	2025-02-17	0.00	0.00	325000.00
1007	320	126	25000.00	3	2019-01-09	2019-01-12	0.00	0.00	75000.00
1008	321	101	35000.00	9	2022-01-03	2022-01-12	0.00	0.00	315000.00
1009	322	104	25000.00	14	2021-10-01	2021-10-15	0.00	0.00	350000.00
1010	323	125	25000.00	15	2022-07-18	2022-08-02	15.00	56250.00	318750.00
1011	324	109	35000.00	3	2022-03-20	2022-03-23	0.00	0.00	105000.00
1012	325	113	35000.00	3	2023-04-15	2023-04-18	0.00	0.00	105000.00
1013	326	108	25000.00	9	2022-10-27	2022-11-05	0.00	0.00	225000.00
1014	327	107	35000.00	13	2021-03-02	2021-03-15	13.00	59150.00	395850.00
1015	328	110	25000.00	1	2019-12-08	2019-12-09	0.00	0.00	25000.00
1016	329	107	35000.00	14	2025-04-14	2025-04-28	0.00	0.00	490000.00
1017	330	118	25000.00	9	2020-09-25	2020-10-04	0.00	0.00	225000.00
1018	331	107	35000.00	7	2020-04-09	2020-04-16	0.00	0.00	245000.00
1019	332	119	35000.00	10	2023-04-30	2023-05-10	0.00	0.00	350000.00
1020	333	124	25000.00	13	2022-11-23	2022-12-06	0.00	0.00	325000.00
1021	334	116	25000.00	12	2020-12-06	2020-12-18	0.00	0.00	300000.00
1022	335	103	35000.00	4	2022-07-02	2022-07-06	0.00	0.00	140000.00
1023	336	103	35000.00	5	2022-03-04	2022-03-09	0.00	0.00	175000.00
1024	337	127	25000.00	3	2019-10-13	2019-10-16	0.00	0.00	75000.00
1025	338	108	25000.00	12	2021-08-29	2021-09-10	0.00	0.00	300000.00
1026	339	112	25000.00	10	2021-06-21	2021-07-01	0.00	0.00	250000.00
1027	340	114	25000.00	10	2022-12-24	2023-01-03	0.00	0.00	250000.00
1028	341	123	25000.00	1	2023-12-25	2023-12-26	0.00	0.00	25000.00
1029	342	111	35000.00	8	2023-06-05	2023-06-13	0.00	0.00	280000.00
1030	343	106	25000.00	4	2020-11-20	2020-11-24	0.00	0.00	100000.00
1031	344	113	35000.00	7	2023-06-15	2023-06-22	0.00	0.00	245000.00
1032	345	115	35000.00	10	2022-01-31	2022-02-10	0.00	0.00	350000.00
1033	346	101	35000.00	3	2019-04-15	2019-04-18	0.00	0.00	105000.00
1034	347	103	35000.00	15	2019-10-21	2019-11-05	0.00	0.00	525000.00
1035	348	114	25000.00	5	2021-11-06	2021-11-11	0.00	0.00	125000.00
1036	349	112	25000.00	14	2022-01-21	2022-02-04	0.00	0.00	350000.00
1037	350	101	35000.00	1	2020-07-25	2020-07-26	0.00	0.00	35000.00
1038	351	106	25000.00	15	2022-11-26	2022-12-11	0.00	0.00	375000.00
1039	352	101	35000.00	12	2021-03-28	2021-04-09	0.00	0.00	420000.00
1040	353	108	25000.00	2	2024-11-02	2024-11-04	0.00	0.00	50000.00
1041	354	101	35000.00	6	2019-01-10	2019-01-16	0.00	0.00	210000.00
1042	355	101	35000.00	6	2024-08-23	2024-08-29	0.00	0.00	210000.00
1043	356	126	25000.00	13	2024-07-08	2024-07-21	0.00	0.00	325000.00
1044	357	122	25000.00	2	2022-11-23	2022-11-25	0.00	0.00	50000.00
1045	358	106	25000.00	5	2021-08-18	2021-08-23	0.00	0.00	125000.00
1046	359	101	35000.00	5	2023-01-12	2023-01-17	0.00	0.00	175000.00
1047	360	104	25000.00	4	2022-06-06	2022-06-10	0.00	0.00	100000.00
1048	361	119	35000.00	15	2019-05-17	2019-06-01	0.00	0.00	525000.00
1049	362	107	35000.00	14	2019-06-03	2019-06-17	0.00	0.00	490000.00
1050	363	117	35000.00	11	2024-02-04	2024-02-15	0.00	0.00	385000.00
1051	364	117	35000.00	6	2020-02-01	2020-02-07	0.00	0.00	210000.00
1052	365	104	25000.00	3	2020-11-07	2020-11-10	0.00	0.00	75000.00
1053	366	103	35000.00	2	2024-01-29	2024-01-31	0.00	0.00	70000.00
1054	367	102	25000.00	8	2025-04-24	2025-05-02	0.00	0.00	200000.00
1055	368	118	25000.00	11	2025-05-08	2025-05-19	0.00	0.00	275000.00
1056	369	117	35000.00	1	2022-03-06	2022-03-07	0.00	0.00	35000.00
1057	370	104	25000.00	7	2021-10-22	2021-10-29	0.00	0.00	175000.00
1058	371	102	25000.00	5	2019-01-15	2019-01-20	0.00	0.00	125000.00
1059	372	107	35000.00	3	2022-12-13	2022-12-16	0.00	0.00	105000.00
1060	373	111	35000.00	4	2019-09-07	2019-09-11	0.00	0.00	140000.00
1061	374	105	35000.00	4	2024-08-03	2024-08-07	0.00	0.00	140000.00
1062	375	101	35000.00	11	2022-07-31	2022-08-11	0.00	0.00	385000.00
1063	376	113	35000.00	8	2020-06-02	2020-06-10	0.00	0.00	280000.00
1064	377	102	25000.00	6	2020-11-25	2020-12-01	0.00	0.00	150000.00
1065	378	126	25000.00	10	2025-01-18	2025-01-28	0.00	0.00	250000.00
1066	379	126	25000.00	9	2019-02-15	2019-02-24	0.00	0.00	225000.00
1067	380	104	25000.00	3	2019-02-22	2019-02-25	0.00	0.00	75000.00
1068	381	106	25000.00	10	2021-12-11	2021-12-21	0.00	0.00	250000.00
1069	382	103	35000.00	3	2021-07-06	2021-07-09	0.00	0.00	105000.00
1070	383	115	35000.00	3	2023-01-31	2023-02-03	0.00	0.00	105000.00
1071	384	117	35000.00	9	2021-11-30	2021-12-09	0.00	0.00	315000.00
1072	385	118	25000.00	15	2020-05-30	2020-06-14	0.00	0.00	375000.00
1073	386	122	25000.00	5	2022-12-05	2022-12-10	0.00	0.00	125000.00
1074	387	106	25000.00	4	2022-11-22	2022-11-26	0.00	0.00	100000.00
1075	388	106	25000.00	8	2025-01-12	2025-01-20	10.00	20000.00	180000.00
1076	389	109	35000.00	8	2021-07-31	2021-08-08	0.00	0.00	280000.00
1077	390	109	35000.00	14	2020-06-21	2020-07-05	0.00	0.00	490000.00
1078	391	113	35000.00	10	2019-08-27	2019-09-06	0.00	0.00	350000.00
1079	392	113	35000.00	13	2023-12-06	2023-12-19	0.00	0.00	455000.00
1080	393	110	25000.00	12	2019-09-20	2019-10-02	0.00	0.00	300000.00
1081	394	119	35000.00	14	2020-12-15	2020-12-29	0.00	0.00	490000.00
1082	395	123	25000.00	5	2020-03-16	2020-03-21	0.00	0.00	125000.00
1083	396	113	35000.00	10	2022-08-31	2022-09-10	0.00	0.00	350000.00
1084	397	108	25000.00	13	2022-04-17	2022-04-30	0.00	0.00	325000.00
1085	398	104	25000.00	13	2021-07-27	2021-08-09	0.00	0.00	325000.00
1086	399	105	35000.00	7	2021-11-30	2021-12-07	0.00	0.00	245000.00
1087	400	114	25000.00	15	2023-05-08	2023-05-23	0.00	0.00	375000.00
1088	401	101	35000.00	8	2020-10-21	2020-10-29	0.00	0.00	280000.00
1089	402	111	35000.00	13	2023-05-02	2023-05-15	0.00	0.00	455000.00
1090	403	105	35000.00	3	2021-08-06	2021-08-09	10.00	10500.00	94500.00
1091	404	101	35000.00	5	2022-04-22	2022-04-27	10.00	17500.00	157500.00
1092	405	126	25000.00	8	2023-09-18	2023-09-26	10.00	20000.00	180000.00
1093	406	116	25000.00	15	2021-04-15	2021-04-30	10.00	37500.00	337500.00
1094	407	121	25000.00	5	2020-10-08	2020-10-13	10.00	12500.00	112500.00
1095	408	106	25000.00	3	2020-10-10	2020-10-13	10.00	7500.00	67500.00
1096	409	103	35000.00	11	2024-04-17	2024-04-28	10.00	38500.00	346500.00
1097	410	115	35000.00	6	2023-01-05	2023-01-11	10.00	21000.00	189000.00
1098	411	109	35000.00	2	2019-08-27	2019-08-29	10.00	7000.00	63000.00
1099	412	109	35000.00	7	2023-09-16	2023-09-23	10.00	24500.00	220500.00
1100	413	118	25000.00	12	2023-09-09	2023-09-21	10.00	30000.00	270000.00
1101	414	107	35000.00	2	2021-03-09	2021-03-11	10.00	7000.00	63000.00
1102	415	101	35000.00	14	2021-11-10	2021-11-24	10.00	49000.00	441000.00
1103	416	122	25000.00	1	2022-10-10	2022-10-11	1.00	250.00	24750.00
1104	417	123	25000.00	5	2020-11-03	2020-11-08	5.00	6250.00	118750.00
1105	418	108	25000.00	15	2022-02-07	2022-02-22	15.00	56250.00	318750.00
1106	419	122	25000.00	11	2021-04-23	2021-05-04	11.00	30250.00	244750.00
1107	420	109	35000.00	13	2019-05-19	2019-06-01	13.00	59150.00	395850.00
1108	421	127	25000.00	12	2023-02-20	2023-03-04	12.00	36000.00	264000.00
1109	422	120	25000.00	5	2019-01-28	2019-02-02	5.00	6250.00	118750.00
1110	423	113	35000.00	10	2025-05-05	2025-05-15	10.00	35000.00	315000.00
1111	424	111	35000.00	4	2024-05-26	2024-05-30	4.00	5600.00	134400.00
1112	425	123	25000.00	1	2020-11-14	2020-11-15	1.00	250.00	24750.00
1113	426	125	25000.00	8	2019-10-01	2019-10-09	8.00	16000.00	184000.00
1114	427	107	35000.00	15	2023-12-03	2023-12-18	15.00	78750.00	446250.00
1115	428	114	25000.00	1	2019-12-20	2019-12-21	1.00	250.00	24750.00
1116	429	127	25000.00	13	2024-12-25	2025-01-07	13.00	42250.00	282750.00
1117	430	111	35000.00	14	2020-07-27	2020-08-10	14.00	68600.00	421400.00
1118	431	119	35000.00	7	2021-03-09	2021-03-16	7.00	17150.00	227850.00
1119	432	111	35000.00	15	2021-03-28	2021-04-12	15.00	78750.00	446250.00
1120	433	106	25000.00	10	2020-08-01	2020-08-11	10.00	25000.00	225000.00
1121	434	102	25000.00	10	2020-09-16	2020-09-26	10.00	25000.00	225000.00
1122	435	122	25000.00	11	2023-04-23	2023-05-04	11.00	30250.00	244750.00
1123	436	111	35000.00	2	2019-10-08	2019-10-10	2.00	1400.00	68600.00
1124	437	101	35000.00	14	2020-12-18	2021-01-01	14.00	68600.00	421400.00
1125	438	105	35000.00	4	2020-11-21	2020-11-25	4.00	5600.00	134400.00
1126	439	116	25000.00	1	2023-06-12	2023-06-13	1.00	250.00	24750.00
1127	440	107	35000.00	1	2022-02-13	2022-02-14	1.00	350.00	34650.00
1128	441	127	25000.00	11	2019-09-03	2019-09-14	11.00	30250.00	244750.00
1129	442	124	25000.00	9	2024-03-07	2024-03-16	9.00	20250.00	204750.00
1130	443	111	35000.00	11	2019-12-25	2020-01-05	11.00	42350.00	342650.00
1131	444	112	25000.00	9	2024-07-12	2024-07-21	9.00	20250.00	204750.00
1132	445	104	25000.00	10	2024-10-20	2024-10-30	10.00	25000.00	225000.00
1133	446	116	25000.00	11	2023-02-06	2023-02-17	11.00	30250.00	244750.00
1134	447	108	25000.00	12	2023-06-14	2023-06-26	12.00	36000.00	264000.00
1135	448	121	25000.00	7	2023-08-13	2023-08-20	7.00	12250.00	162750.00
1136	449	121	25000.00	6	2024-01-19	2024-01-25	6.00	9000.00	141000.00
1137	450	119	35000.00	11	2025-01-21	2025-02-01	11.00	42350.00	342650.00
1138	451	115	35000.00	12	2023-10-27	2023-11-08	12.00	50400.00	369600.00
1139	452	123	25000.00	6	2021-11-09	2021-11-15	6.00	9000.00	141000.00
1140	453	115	35000.00	2	2022-12-13	2022-12-15	2.00	1400.00	68600.00
1141	454	104	25000.00	12	2023-06-02	2023-06-14	12.00	36000.00	264000.00
1142	455	116	25000.00	4	2020-07-01	2020-07-05	4.00	4000.00	96000.00
1143	456	113	35000.00	12	2020-02-24	2020-03-07	12.00	50400.00	369600.00
1144	457	113	35000.00	2	2019-09-15	2019-09-17	2.00	1400.00	68600.00
1145	458	114	25000.00	10	2019-11-10	2019-11-20	10.00	25000.00	225000.00
1146	459	115	35000.00	10	2024-07-25	2024-08-04	10.00	35000.00	315000.00
1147	460	117	35000.00	8	2023-10-04	2023-10-12	8.00	22400.00	257600.00
1148	461	120	25000.00	10	2021-11-21	2021-12-01	10.00	25000.00	225000.00
1149	462	115	35000.00	2	2024-05-28	2024-05-30	2.00	1400.00	68600.00
1150	463	113	35000.00	12	2020-12-16	2020-12-28	12.00	50400.00	369600.00
1151	464	102	25000.00	13	2022-09-18	2022-10-01	13.00	42250.00	282750.00
1152	465	103	35000.00	13	2019-12-30	2020-01-12	13.00	59150.00	395850.00
1153	466	113	35000.00	1	2024-06-13	2024-06-14	1.00	350.00	34650.00
1154	467	120	25000.00	1	2022-10-23	2022-10-24	1.00	250.00	24750.00
1155	468	117	35000.00	11	2020-02-18	2020-02-29	11.00	42350.00	342650.00
1156	469	112	25000.00	8	2021-01-07	2021-01-15	8.00	16000.00	184000.00
1157	470	117	35000.00	12	2021-03-23	2021-04-04	12.00	50400.00	369600.00
1158	471	115	35000.00	1	2019-02-09	2019-02-10	1.00	350.00	34650.00
1159	472	107	35000.00	2	2020-06-13	2020-06-15	2.00	1400.00	68600.00
1160	473	103	35000.00	11	2023-06-02	2023-06-13	11.00	42350.00	342650.00
1161	474	124	25000.00	8	2024-06-10	2024-06-18	8.00	16000.00	184000.00
1162	475	125	25000.00	5	2025-04-26	2025-05-01	5.00	6250.00	118750.00
1163	476	109	35000.00	2	2021-01-11	2021-01-13	2.00	1400.00	68600.00
1164	477	101	35000.00	3	2019-01-07	2019-01-10	3.00	3150.00	101850.00
1165	478	123	25000.00	11	2021-05-29	2021-06-09	11.00	30250.00	244750.00
1166	479	111	35000.00	11	2023-05-05	2023-05-16	11.00	42350.00	342650.00
1167	480	101	35000.00	2	2020-04-12	2020-04-14	2.00	1400.00	68600.00
1168	481	113	35000.00	8	2020-09-28	2020-10-06	8.00	22400.00	257600.00
1169	482	124	25000.00	1	2019-02-04	2019-02-05	1.00	250.00	24750.00
1170	483	101	35000.00	9	2023-02-24	2023-03-05	9.00	28350.00	286650.00
1171	484	124	25000.00	11	2023-12-03	2023-12-14	11.00	30250.00	244750.00
1172	485	107	35000.00	2	2021-02-20	2021-02-22	2.00	1400.00	68600.00
1173	486	118	25000.00	13	2020-10-04	2020-10-17	13.00	42250.00	282750.00
1174	487	104	25000.00	4	2022-09-09	2022-09-13	4.00	4000.00	96000.00
1175	488	117	35000.00	14	2021-04-28	2021-05-12	14.00	68600.00	421400.00
1176	489	107	35000.00	7	2021-01-12	2021-01-19	7.00	17150.00	227850.00
1177	490	111	35000.00	10	2022-07-16	2022-07-26	10.00	35000.00	315000.00
1178	491	116	25000.00	5	2019-07-07	2019-07-12	5.00	6250.00	118750.00
1179	492	125	25000.00	5	2020-08-05	2020-08-10	5.00	6250.00	118750.00
1180	493	108	25000.00	8	2019-12-06	2019-12-14	8.00	16000.00	184000.00
1181	494	120	25000.00	15	2024-06-30	2024-07-15	15.00	56250.00	318750.00
1182	495	118	25000.00	4	2021-07-13	2021-07-17	4.00	4000.00	96000.00
1183	496	105	35000.00	13	2023-10-12	2023-10-25	13.00	59150.00	395850.00
1184	497	119	35000.00	13	2023-06-23	2023-07-06	13.00	59150.00	395850.00
1185	498	109	35000.00	1	2022-12-03	2022-12-04	1.00	350.00	34650.00
1186	499	101	35000.00	4	2021-01-20	2021-01-24	4.00	5600.00	134400.00
1187	500	124	25000.00	1	2021-01-16	2021-01-17	1.00	250.00	24750.00
1188	501	110	25000.00	11	2021-06-01	2021-06-12	11.00	30250.00	244750.00
1189	502	115	35000.00	10	2022-09-17	2022-09-27	10.00	35000.00	315000.00
1190	503	116	25000.00	6	2021-02-25	2021-03-03	6.00	9000.00	141000.00
1191	504	105	35000.00	4	2021-09-17	2021-09-21	4.00	5600.00	134400.00
1192	505	107	35000.00	13	2021-11-21	2021-12-04	13.00	59150.00	395850.00
1193	506	107	35000.00	6	2020-02-13	2020-02-19	6.00	12600.00	197400.00
1194	507	125	25000.00	1	2023-02-16	2023-02-17	1.00	250.00	24750.00
1195	508	101	35000.00	5	2020-03-09	2020-03-14	5.00	8750.00	166250.00
1196	509	113	35000.00	5	2019-08-21	2019-08-26	5.00	8750.00	166250.00
1197	510	114	25000.00	6	2024-12-19	2024-12-25	6.00	9000.00	141000.00
1198	511	103	35000.00	5	2022-12-18	2022-12-23	5.00	8750.00	166250.00
1199	512	105	35000.00	4	2022-03-13	2022-03-17	4.00	5600.00	134400.00
1200	513	125	25000.00	7	2025-04-10	2025-04-17	7.00	12250.00	162750.00
1201	514	124	25000.00	4	2024-04-21	2024-04-25	4.00	4000.00	96000.00
1202	515	125	25000.00	4	2021-10-23	2021-10-27	4.00	4000.00	96000.00
1203	516	123	25000.00	9	2024-01-02	2024-01-11	9.00	20250.00	204750.00
1204	517	113	35000.00	3	2021-04-12	2021-04-15	3.00	3150.00	101850.00
1205	518	107	35000.00	11	2023-04-25	2023-05-06	11.00	42350.00	342650.00
1206	519	108	25000.00	6	2020-02-01	2020-02-07	6.00	9000.00	141000.00
1207	520	124	25000.00	14	2022-03-20	2022-04-03	14.00	49000.00	301000.00
1208	521	106	25000.00	10	2019-05-08	2019-05-18	10.00	25000.00	225000.00
1209	522	121	25000.00	7	2021-05-31	2021-06-07	7.00	12250.00	162750.00
1210	523	103	35000.00	11	2019-10-21	2019-11-01	11.00	42350.00	342650.00
1211	524	113	35000.00	15	2020-07-26	2020-08-10	15.00	78750.00	446250.00
1212	525	122	25000.00	11	2019-03-31	2019-04-11	11.00	30250.00	244750.00
1213	526	123	25000.00	5	2021-09-25	2021-09-30	5.00	6250.00	118750.00
1214	527	107	35000.00	6	2025-05-27	2025-06-02	6.00	12600.00	197400.00
1215	528	103	35000.00	7	2023-03-04	2023-03-11	7.00	17150.00	227850.00
1216	529	112	25000.00	1	2023-08-01	2023-08-02	1.00	250.00	24750.00
1217	530	111	35000.00	8	2023-09-30	2023-10-08	8.00	22400.00	257600.00
1218	531	123	25000.00	5	2024-01-21	2024-01-26	5.00	6250.00	118750.00
1219	532	121	25000.00	15	2023-06-12	2023-06-27	15.00	56250.00	318750.00
1220	533	107	35000.00	1	2024-10-02	2024-10-03	1.00	350.00	34650.00
1221	534	115	35000.00	10	2019-01-30	2019-02-09	10.00	35000.00	315000.00
1222	535	110	25000.00	5	2025-01-04	2025-01-09	5.00	6250.00	118750.00
1223	536	106	25000.00	4	2024-06-20	2024-06-24	4.00	4000.00	96000.00
1224	537	107	35000.00	11	2019-09-05	2019-09-16	11.00	42350.00	342650.00
1225	538	114	25000.00	14	2023-08-28	2023-09-11	14.00	49000.00	301000.00
1226	539	105	35000.00	12	2022-08-16	2022-08-28	12.00	50400.00	369600.00
1227	540	111	35000.00	2	2022-06-19	2022-06-21	2.00	1400.00	68600.00
1228	541	113	35000.00	1	2019-09-26	2019-09-27	1.00	350.00	34650.00
1229	542	127	25000.00	9	2021-11-08	2021-11-17	9.00	20250.00	204750.00
1230	543	106	25000.00	15	2020-11-07	2020-11-22	15.00	56250.00	318750.00
1231	544	106	25000.00	12	2022-04-02	2022-04-14	12.00	36000.00	264000.00
1232	545	114	25000.00	13	2023-10-05	2023-10-18	13.00	42250.00	282750.00
1233	546	117	35000.00	12	2021-02-06	2021-02-18	12.00	50400.00	369600.00
1234	547	122	25000.00	2	2019-03-28	2019-03-30	2.00	1000.00	49000.00
1235	548	126	25000.00	8	2020-04-14	2020-04-22	8.00	16000.00	184000.00
1236	549	119	35000.00	11	2023-03-06	2023-03-17	11.00	42350.00	342650.00
1237	550	105	35000.00	10	2019-08-20	2019-08-30	10.00	35000.00	315000.00
1238	551	115	35000.00	10	2019-07-03	2019-07-13	10.00	35000.00	315000.00
1239	552	121	25000.00	15	2019-05-18	2019-06-02	15.00	56250.00	318750.00
1240	553	113	35000.00	1	2019-01-30	2019-01-31	1.00	350.00	34650.00
1241	554	103	35000.00	15	2019-02-12	2019-02-27	15.00	78750.00	446250.00
1242	555	103	35000.00	12	2019-01-29	2019-02-10	12.00	50400.00	369600.00
1243	556	113	35000.00	7	2019-01-20	2019-01-27	7.00	17150.00	227850.00
1244	557	102	25000.00	8	2020-09-18	2020-09-26	8.00	16000.00	184000.00
1245	558	106	25000.00	12	2021-08-02	2021-08-14	12.00	36000.00	264000.00
1246	559	123	25000.00	14	2019-09-30	2019-10-14	14.00	49000.00	301000.00
1247	560	103	35000.00	14	2021-01-02	2021-01-16	14.00	68600.00	421400.00
1248	561	102	25000.00	6	2022-12-01	2022-12-07	6.00	9000.00	141000.00
1249	562	111	35000.00	14	2022-03-24	2022-04-07	14.00	68600.00	421400.00
1250	563	124	25000.00	4	2021-03-31	2021-04-04	4.00	4000.00	96000.00
1251	564	125	25000.00	9	2021-02-07	2021-02-16	9.00	20250.00	204750.00
1252	565	123	25000.00	1	2024-09-18	2024-09-19	1.00	250.00	24750.00
1253	566	109	35000.00	10	2024-01-21	2024-01-31	10.00	35000.00	315000.00
1254	567	124	25000.00	1	2023-01-20	2023-01-21	1.00	250.00	24750.00
1255	568	123	25000.00	15	2024-09-14	2024-09-29	15.00	56250.00	318750.00
1256	569	107	35000.00	2	2019-02-14	2019-02-16	2.00	1400.00	68600.00
1257	570	114	25000.00	4	2019-05-28	2019-06-01	4.00	4000.00	96000.00
1258	571	122	25000.00	4	2023-06-16	2023-06-20	4.00	4000.00	96000.00
1259	572	105	35000.00	1	2021-04-30	2021-05-01	1.00	350.00	34650.00
1260	573	118	25000.00	5	2022-11-22	2022-11-27	5.00	6250.00	118750.00
1261	574	125	25000.00	13	2019-07-17	2019-07-30	13.00	42250.00	282750.00
1262	575	120	25000.00	4	2024-01-21	2024-01-25	4.00	4000.00	96000.00
1263	576	108	25000.00	6	2023-05-18	2023-05-24	6.00	9000.00	141000.00
1264	577	112	25000.00	3	2023-08-30	2023-09-02	3.00	2250.00	72750.00
1265	578	103	35000.00	10	2024-04-29	2024-05-09	10.00	35000.00	315000.00
1266	579	118	25000.00	12	2021-02-28	2021-03-12	12.00	36000.00	264000.00
1267	580	122	25000.00	15	2024-01-13	2024-01-28	15.00	56250.00	318750.00
1268	581	119	35000.00	15	2023-09-17	2023-10-02	15.00	78750.00	446250.00
1269	582	126	25000.00	3	2020-11-24	2020-11-27	3.00	2250.00	72750.00
1270	583	117	35000.00	7	2022-03-21	2022-03-28	7.00	17150.00	227850.00
1271	584	111	35000.00	5	2025-02-05	2025-02-10	5.00	8750.00	166250.00
1272	585	117	35000.00	7	2023-06-14	2023-06-21	7.00	17150.00	227850.00
1273	586	103	35000.00	14	2019-01-23	2019-02-06	14.00	68600.00	421400.00
1274	587	123	25000.00	4	2024-07-15	2024-07-19	4.00	4000.00	96000.00
1275	588	119	35000.00	2	2024-08-01	2024-08-03	2.00	1400.00	68600.00
1276	589	110	25000.00	6	2023-03-10	2023-03-16	6.00	9000.00	141000.00
1277	590	109	35000.00	10	2020-06-05	2020-06-15	10.00	35000.00	315000.00
1278	591	107	35000.00	5	2023-07-04	2023-07-09	5.00	8750.00	166250.00
1279	592	108	25000.00	4	2019-05-04	2019-05-08	4.00	4000.00	96000.00
1280	593	125	25000.00	14	2021-05-07	2021-05-21	14.00	49000.00	301000.00
1281	594	121	25000.00	1	2025-01-19	2025-01-20	1.00	250.00	24750.00
1282	595	105	35000.00	1	2024-06-26	2024-06-27	1.00	350.00	34650.00
1283	596	126	25000.00	9	2021-10-20	2021-10-29	9.00	20250.00	204750.00
1284	597	116	25000.00	2	2021-01-08	2021-01-10	2.00	1000.00	49000.00
1285	598	105	35000.00	12	2024-06-11	2024-06-23	12.00	50400.00	369600.00
1286	599	104	25000.00	1	2024-09-11	2024-09-12	1.00	250.00	24750.00
1287	600	119	35000.00	14	2023-11-18	2023-12-02	14.00	68600.00	421400.00
1288	601	109	35000.00	5	2021-05-17	2021-05-22	5.00	8750.00	166250.00
1289	602	111	35000.00	10	2021-06-06	2021-06-16	10.00	35000.00	315000.00
1290	603	118	25000.00	15	2023-03-03	2023-03-18	15.00	56250.00	318750.00
1291	604	126	25000.00	13	2025-04-19	2025-05-02	13.00	42250.00	282750.00
1292	605	123	25000.00	1	2019-07-31	2019-08-01	1.00	250.00	24750.00
1293	606	120	25000.00	8	2025-04-17	2025-04-25	8.00	16000.00	184000.00
1294	607	113	35000.00	3	2021-01-13	2021-01-16	3.00	3150.00	101850.00
1295	608	111	35000.00	8	2019-06-29	2019-07-07	8.00	22400.00	257600.00
1296	609	119	35000.00	5	2023-01-24	2023-01-29	5.00	8750.00	166250.00
1297	610	109	35000.00	4	2019-09-09	2019-09-13	4.00	5600.00	134400.00
1298	611	110	25000.00	12	2021-08-19	2021-08-31	12.00	36000.00	264000.00
1299	612	106	25000.00	3	2025-02-21	2025-02-24	3.00	2250.00	72750.00
1300	613	122	25000.00	6	2019-01-05	2019-01-11	6.00	9000.00	141000.00
1301	614	117	35000.00	8	2023-03-27	2023-04-04	8.00	22400.00	257600.00
1302	615	126	25000.00	6	2025-05-15	2025-05-21	6.00	9000.00	141000.00
1303	616	115	35000.00	9	2022-10-28	2022-11-06	9.00	28350.00	286650.00
1304	617	108	25000.00	9	2020-09-29	2020-10-08	9.00	20250.00	204750.00
1305	618	109	35000.00	8	2024-11-05	2024-11-13	8.00	22400.00	257600.00
1306	619	111	35000.00	14	2025-05-24	2025-06-07	14.00	68600.00	421400.00
1307	620	108	25000.00	9	2023-06-07	2023-06-16	9.00	20250.00	204750.00
1308	621	113	35000.00	4	2025-02-01	2025-02-05	4.00	5600.00	134400.00
1309	622	105	35000.00	1	2023-01-11	2023-01-12	1.00	350.00	34650.00
1310	623	108	25000.00	10	2020-11-04	2020-11-14	10.00	25000.00	225000.00
1311	624	106	25000.00	6	2024-01-07	2024-01-13	6.00	9000.00	141000.00
1312	625	109	35000.00	8	2020-08-25	2020-09-02	8.00	22400.00	257600.00
1313	626	104	25000.00	6	2020-10-30	2020-11-05	6.00	9000.00	141000.00
1314	627	127	25000.00	12	2025-05-10	2025-05-22	12.00	36000.00	264000.00
1315	628	123	25000.00	15	2020-12-12	2020-12-27	15.00	56250.00	318750.00
1316	629	119	35000.00	15	2023-02-21	2023-03-08	15.00	78750.00	446250.00
1317	630	115	35000.00	4	2021-07-31	2021-08-04	4.00	5600.00	134400.00
1318	631	110	25000.00	7	2021-09-26	2021-10-03	7.00	12250.00	162750.00
1319	632	120	25000.00	2	2021-06-15	2021-06-17	2.00	1000.00	49000.00
1320	633	119	35000.00	13	2025-01-22	2025-02-04	13.00	59150.00	395850.00
1321	634	109	35000.00	13	2023-12-27	2024-01-09	13.00	59150.00	395850.00
1322	635	110	25000.00	10	2021-03-22	2021-04-01	10.00	25000.00	225000.00
1323	636	124	25000.00	3	2021-05-26	2021-05-29	3.00	2250.00	72750.00
1324	637	119	35000.00	15	2022-10-08	2022-10-23	15.00	78750.00	446250.00
1325	638	109	35000.00	4	2019-06-02	2019-06-06	4.00	5600.00	134400.00
1326	639	127	25000.00	5	2025-05-23	2025-05-28	5.00	6250.00	118750.00
1327	640	109	35000.00	13	2025-03-20	2025-04-02	13.00	59150.00	395850.00
1328	641	107	35000.00	8	2024-08-14	2024-08-22	8.00	22400.00	257600.00
1329	642	101	35000.00	8	2022-07-05	2022-07-13	8.00	22400.00	257600.00
1330	643	126	25000.00	14	2024-01-26	2024-02-09	14.00	49000.00	301000.00
1331	644	110	25000.00	4	2023-04-14	2023-04-18	4.00	4000.00	96000.00
1332	645	110	25000.00	8	2021-03-18	2021-03-26	8.00	16000.00	184000.00
1333	646	105	35000.00	9	2024-02-23	2024-03-03	9.00	28350.00	286650.00
1334	647	107	35000.00	14	2025-01-29	2025-02-12	14.00	68600.00	421400.00
1335	648	113	35000.00	6	2024-10-07	2024-10-13	6.00	12600.00	197400.00
1336	649	101	35000.00	3	2019-03-14	2019-03-17	3.00	3150.00	101850.00
1337	650	111	35000.00	7	2025-05-15	2025-05-22	7.00	17150.00	227850.00
1338	651	121	25000.00	5	2021-09-29	2021-10-04	5.00	6250.00	118750.00
1339	652	109	35000.00	11	2019-12-04	2019-12-15	11.00	42350.00	342650.00
1340	653	119	35000.00	8	2023-11-07	2023-11-15	8.00	22400.00	257600.00
1341	654	122	25000.00	4	2023-06-06	2023-06-10	4.00	4000.00	96000.00
1342	655	114	25000.00	8	2019-03-12	2019-03-20	8.00	16000.00	184000.00
1343	656	122	25000.00	4	2025-04-03	2025-04-07	4.00	4000.00	96000.00
1344	657	111	35000.00	3	2022-02-21	2022-02-24	3.00	3150.00	101850.00
1345	658	110	25000.00	7	2019-05-27	2019-06-03	7.00	12250.00	162750.00
1346	659	113	35000.00	2	2021-06-07	2021-06-09	2.00	1400.00	68600.00
1347	660	108	25000.00	13	2022-02-01	2022-02-14	13.00	42250.00	282750.00
1348	661	123	25000.00	2	2023-02-15	2023-02-17	2.00	1000.00	49000.00
1349	662	115	35000.00	3	2024-10-31	2024-11-03	3.00	3150.00	101850.00
1350	663	107	35000.00	11	2021-10-27	2021-11-07	11.00	42350.00	342650.00
1351	664	107	35000.00	12	2020-11-15	2020-11-27	12.00	50400.00	369600.00
1352	665	116	25000.00	4	2021-06-05	2021-06-09	4.00	4000.00	96000.00
1353	666	127	25000.00	3	2020-08-29	2020-09-01	3.00	2250.00	72750.00
1354	667	123	25000.00	3	2022-10-02	2022-10-05	3.00	2250.00	72750.00
1355	668	126	25000.00	13	2020-06-06	2020-06-19	13.00	42250.00	282750.00
1356	669	106	25000.00	6	2024-07-01	2024-07-07	6.00	9000.00	141000.00
1357	670	103	35000.00	12	2019-04-06	2019-04-18	12.00	50400.00	369600.00
1358	671	114	25000.00	9	2023-08-08	2023-08-17	9.00	20250.00	204750.00
1359	672	108	25000.00	14	2024-09-14	2024-09-28	14.00	49000.00	301000.00
1360	673	117	35000.00	2	2022-10-28	2022-10-30	2.00	1400.00	68600.00
1361	674	103	35000.00	15	2023-11-01	2023-11-16	15.00	78750.00	446250.00
1362	675	105	35000.00	6	2020-07-20	2020-07-26	6.00	12600.00	197400.00
1363	676	119	35000.00	8	2021-11-23	2021-12-01	8.00	22400.00	257600.00
1364	677	113	35000.00	13	2020-03-07	2020-03-20	13.00	59150.00	395850.00
1365	678	103	35000.00	4	2022-02-28	2022-03-04	4.00	5600.00	134400.00
1366	679	107	35000.00	3	2022-11-01	2022-11-04	3.00	3150.00	101850.00
1367	680	122	25000.00	7	2020-09-18	2020-09-25	7.00	12250.00	162750.00
1368	681	119	35000.00	8	2025-01-27	2025-02-04	8.00	22400.00	257600.00
1369	682	107	35000.00	14	2020-02-03	2020-02-17	14.00	68600.00	421400.00
1370	683	103	35000.00	9	2020-04-17	2020-04-26	9.00	28350.00	286650.00
1371	684	115	35000.00	10	2021-01-12	2021-01-22	10.00	35000.00	315000.00
1372	685	119	35000.00	6	2023-11-22	2023-11-28	6.00	12600.00	197400.00
1373	686	109	35000.00	7	2021-06-01	2021-06-08	7.00	17150.00	227850.00
1374	687	105	35000.00	9	2019-10-25	2019-11-03	9.00	28350.00	286650.00
1375	688	123	25000.00	8	2023-08-20	2023-08-28	8.00	16000.00	184000.00
1376	689	116	25000.00	10	2020-04-08	2020-04-18	10.00	25000.00	225000.00
1377	690	101	35000.00	15	2025-01-01	2025-01-16	15.00	78750.00	446250.00
1378	691	126	25000.00	6	2020-09-19	2020-09-25	6.00	9000.00	141000.00
1379	692	107	35000.00	1	2023-06-18	2023-06-19	1.00	350.00	34650.00
1380	693	103	35000.00	1	2021-10-12	2021-10-13	1.00	350.00	34650.00
1381	694	107	35000.00	14	2019-04-12	2019-04-26	14.00	68600.00	421400.00
1382	695	111	35000.00	3	2023-05-12	2023-05-15	3.00	3150.00	101850.00
1383	696	118	25000.00	4	2023-06-19	2023-06-23	4.00	4000.00	96000.00
1384	697	117	35000.00	15	2019-06-10	2019-06-25	15.00	78750.00	446250.00
1385	698	126	25000.00	7	2024-11-20	2024-11-27	7.00	12250.00	162750.00
1386	699	111	35000.00	10	2020-07-07	2020-07-17	10.00	35000.00	315000.00
1387	700	119	35000.00	8	2024-05-22	2024-05-30	8.00	22400.00	257600.00
1388	701	107	35000.00	12	2022-03-19	2022-03-31	12.00	50400.00	369600.00
1389	702	103	35000.00	14	2020-09-19	2020-10-03	14.00	68600.00	421400.00
1390	703	109	35000.00	5	2024-09-09	2024-09-14	5.00	8750.00	166250.00
1391	704	105	35000.00	4	2023-11-03	2023-11-07	4.00	5600.00	134400.00
1392	705	101	35000.00	8	2020-07-05	2020-07-13	8.00	22400.00	257600.00
1393	706	108	25000.00	11	2024-04-02	2024-04-13	11.00	30250.00	244750.00
1394	707	121	25000.00	2	2019-11-07	2019-11-09	2.00	1000.00	49000.00
1395	708	101	35000.00	11	2023-08-10	2023-08-21	11.00	42350.00	342650.00
1396	709	118	25000.00	4	2019-10-14	2019-10-18	4.00	4000.00	96000.00
1397	710	109	35000.00	11	2020-12-30	2021-01-10	11.00	42350.00	342650.00
1398	711	124	25000.00	3	2025-01-07	2025-01-10	3.00	2250.00	72750.00
1399	712	127	25000.00	6	2021-11-10	2021-11-16	6.00	9000.00	141000.00
1400	713	115	35000.00	3	2022-05-06	2022-05-09	3.00	3150.00	101850.00
1401	714	116	25000.00	7	2020-05-25	2020-06-01	7.00	12250.00	162750.00
1402	715	117	35000.00	13	2024-06-01	2024-06-14	13.00	59150.00	395850.00
1403	716	111	35000.00	11	2024-03-10	2024-03-21	11.00	42350.00	342650.00
1404	717	104	25000.00	15	2022-09-07	2022-09-22	15.00	56250.00	318750.00
1405	718	121	25000.00	5	2019-09-21	2019-09-26	5.00	6250.00	118750.00
1406	719	117	35000.00	1	2023-12-18	2023-12-19	1.00	350.00	34650.00
1407	720	127	25000.00	4	2019-11-14	2019-11-18	4.00	4000.00	96000.00
1408	721	116	25000.00	10	2022-03-23	2022-04-02	10.00	25000.00	225000.00
1409	722	103	35000.00	9	2024-08-09	2024-08-18	9.00	28350.00	286650.00
1410	723	113	35000.00	6	2020-11-14	2020-11-20	6.00	12600.00	197400.00
1411	724	102	25000.00	8	2019-05-06	2019-05-14	8.00	16000.00	184000.00
1412	725	110	25000.00	11	2021-05-22	2021-06-02	11.00	30250.00	244750.00
1413	726	113	35000.00	3	2021-03-30	2021-04-02	3.00	3150.00	101850.00
1414	727	118	25000.00	12	2024-10-11	2024-10-23	12.00	36000.00	264000.00
1415	728	121	25000.00	15	2025-01-27	2025-02-11	15.00	56250.00	318750.00
1416	729	107	35000.00	4	2019-10-21	2019-10-25	4.00	5600.00	134400.00
1417	730	127	25000.00	7	2022-08-26	2022-09-02	7.00	12250.00	162750.00
1418	731	120	25000.00	12	2022-07-28	2022-08-09	12.00	36000.00	264000.00
1419	732	115	35000.00	1	2024-06-05	2024-06-06	1.00	350.00	34650.00
1420	733	102	25000.00	10	2020-05-11	2020-05-21	10.00	25000.00	225000.00
1421	734	112	25000.00	13	2022-12-23	2023-01-05	13.00	42250.00	282750.00
1422	735	101	35000.00	11	2019-04-29	2019-05-10	11.00	42350.00	342650.00
1423	736	120	25000.00	1	2020-02-17	2020-02-18	1.00	250.00	24750.00
1424	737	109	35000.00	10	2024-07-13	2024-07-23	10.00	35000.00	315000.00
1425	738	107	35000.00	12	2024-09-20	2024-10-02	12.00	50400.00	369600.00
1426	739	109	35000.00	3	2022-10-20	2022-10-23	3.00	3150.00	101850.00
1427	740	103	35000.00	10	2024-01-14	2024-01-24	10.00	35000.00	315000.00
1428	741	116	25000.00	3	2020-10-15	2020-10-18	3.00	2250.00	72750.00
1429	742	106	25000.00	11	2024-11-19	2024-11-30	11.00	30250.00	244750.00
1430	743	124	25000.00	6	2020-04-21	2020-04-27	6.00	9000.00	141000.00
1431	744	109	35000.00	3	2020-08-21	2020-08-24	3.00	3150.00	101850.00
1432	745	126	25000.00	11	2024-12-05	2024-12-16	11.00	30250.00	244750.00
1433	746	104	25000.00	4	2023-08-27	2023-08-31	4.00	4000.00	96000.00
1434	747	104	25000.00	1	2021-04-10	2021-04-11	1.00	250.00	24750.00
1435	748	122	25000.00	3	2019-04-27	2019-04-30	3.00	2250.00	72750.00
1436	749	109	35000.00	11	2021-04-13	2021-04-24	0.00	0.00	385000.00
1437	750	112	25000.00	3	2024-08-09	2024-08-12	0.00	0.00	75000.00
1438	751	119	35000.00	8	2019-07-08	2019-07-16	0.00	0.00	280000.00
1439	752	122	25000.00	7	2019-03-08	2019-03-15	0.00	0.00	175000.00
1440	753	102	25000.00	8	2023-01-06	2023-01-14	0.00	0.00	200000.00
1441	754	113	35000.00	9	2025-01-12	2025-01-21	0.00	0.00	315000.00
1442	755	124	25000.00	6	2019-08-25	2019-08-31	0.00	0.00	150000.00
1443	756	117	35000.00	9	2024-11-22	2024-12-01	0.00	0.00	315000.00
1444	757	116	25000.00	6	2020-12-12	2020-12-18	0.00	0.00	150000.00
1445	758	109	35000.00	7	2019-07-18	2019-07-25	0.00	0.00	245000.00
1446	759	101	35000.00	15	2024-08-04	2024-08-19	0.00	0.00	525000.00
1447	760	118	25000.00	15	2022-09-08	2022-09-23	0.00	0.00	375000.00
1448	761	116	25000.00	8	2019-08-31	2019-09-08	0.00	0.00	200000.00
1449	762	105	35000.00	10	2024-11-17	2024-11-27	0.00	0.00	350000.00
1450	763	104	25000.00	11	2024-02-06	2024-02-17	0.00	0.00	275000.00
1451	764	120	25000.00	13	2021-01-08	2021-01-21	0.00	0.00	325000.00
1452	765	127	25000.00	3	2025-03-27	2025-03-30	0.00	0.00	75000.00
1453	766	107	35000.00	11	2021-06-16	2021-06-27	0.00	0.00	385000.00
1454	767	107	35000.00	8	2022-01-23	2022-01-31	0.00	0.00	280000.00
1455	768	121	25000.00	1	2024-01-05	2024-01-06	0.00	0.00	25000.00
1456	769	125	25000.00	15	2020-06-29	2020-07-14	0.00	0.00	375000.00
1457	770	124	25000.00	3	2022-02-26	2022-03-01	0.00	0.00	75000.00
1458	771	102	25000.00	6	2019-07-30	2019-08-05	0.00	0.00	150000.00
1459	772	123	25000.00	5	2021-04-25	2021-04-30	0.00	0.00	125000.00
1460	773	118	25000.00	5	2024-12-06	2024-12-11	0.00	0.00	125000.00
1461	774	121	25000.00	7	2020-01-26	2020-02-02	0.00	0.00	175000.00
1462	775	125	25000.00	7	2022-12-09	2022-12-16	0.00	0.00	175000.00
1463	776	115	35000.00	11	2020-11-14	2020-11-25	11.00	42350.00	342650.00
1464	777	120	25000.00	1	2024-03-29	2024-03-30	1.00	250.00	24750.00
1465	778	101	35000.00	11	2021-01-23	2021-02-03	11.00	42350.00	342650.00
1466	779	111	35000.00	13	2021-07-16	2021-07-29	13.00	59150.00	395850.00
1467	780	123	25000.00	11	2022-11-19	2022-11-30	11.00	30250.00	244750.00
1468	781	113	35000.00	1	2023-04-14	2023-04-15	1.00	350.00	34650.00
1469	782	116	25000.00	11	2020-01-19	2020-01-30	11.00	30250.00	244750.00
1470	783	103	35000.00	10	2022-02-18	2022-02-28	10.00	35000.00	315000.00
1471	784	107	35000.00	5	2021-07-28	2021-08-02	5.00	8750.00	166250.00
1472	785	125	25000.00	3	2024-11-25	2024-11-28	3.00	2250.00	72750.00
1473	786	113	35000.00	5	2019-06-12	2019-06-17	5.00	8750.00	166250.00
1474	787	115	35000.00	10	2024-03-01	2024-03-11	10.00	35000.00	315000.00
1475	788	107	35000.00	7	2022-08-30	2022-09-06	7.00	17150.00	227850.00
1476	789	118	25000.00	3	2022-01-28	2022-01-31	3.00	2250.00	72750.00
1477	790	109	35000.00	6	2024-12-25	2024-12-31	6.00	12600.00	197400.00
1478	791	101	35000.00	2	2020-02-26	2020-02-28	2.00	1400.00	68600.00
1479	792	103	35000.00	11	2023-01-09	2023-01-20	11.00	42350.00	342650.00
1480	793	109	35000.00	8	2020-04-07	2020-04-15	8.00	22400.00	257600.00
1481	794	126	25000.00	11	2021-04-26	2021-05-07	11.00	30250.00	244750.00
1482	795	111	35000.00	6	2024-07-05	2024-07-11	6.00	12600.00	197400.00
1483	796	119	35000.00	2	2022-04-18	2022-04-20	2.00	1400.00	68600.00
1484	797	111	35000.00	4	2025-01-25	2025-01-29	4.00	5600.00	134400.00
1485	798	113	35000.00	1	2023-07-17	2023-07-18	1.00	350.00	34650.00
1486	799	126	25000.00	14	2023-11-30	2023-12-14	14.00	49000.00	301000.00
1487	800	102	25000.00	10	2024-02-14	2024-02-24	10.00	25000.00	225000.00
1488	801	124	25000.00	10	2023-05-23	2023-06-02	10.00	25000.00	225000.00
1489	802	118	25000.00	7	2025-02-02	2025-02-09	7.00	12250.00	162750.00
1490	803	125	25000.00	2	2019-05-26	2019-05-28	2.00	1000.00	49000.00
1491	804	104	25000.00	2	2021-09-29	2021-10-01	2.00	1000.00	49000.00
1492	805	123	25000.00	10	2019-07-24	2019-08-03	10.00	25000.00	225000.00
1493	806	124	25000.00	13	2020-04-08	2020-04-21	13.00	42250.00	282750.00
1494	807	117	35000.00	9	2023-08-23	2023-09-01	9.00	28350.00	286650.00
1495	808	109	35000.00	10	2021-12-10	2021-12-20	10.00	35000.00	315000.00
1496	809	108	25000.00	12	2025-05-19	2025-05-31	12.00	36000.00	264000.00
1497	810	122	25000.00	11	2020-03-06	2020-03-17	11.00	30250.00	244750.00
1498	811	105	35000.00	10	2019-07-18	2019-07-28	10.00	35000.00	315000.00
1499	812	121	25000.00	10	2024-10-23	2024-11-02	10.00	25000.00	225000.00
1500	813	119	35000.00	4	2020-07-23	2020-07-27	4.00	5600.00	134400.00
1501	814	127	25000.00	5	2020-12-29	2021-01-03	5.00	6250.00	118750.00
1502	815	109	35000.00	2	2024-12-14	2024-12-16	2.00	1400.00	68600.00
1503	816	110	25000.00	15	2020-03-17	2020-04-01	15.00	56250.00	318750.00
1504	817	118	25000.00	11	2022-06-28	2022-07-09	11.00	30250.00	244750.00
1505	818	123	25000.00	1	2019-04-23	2019-04-24	1.00	250.00	24750.00
1506	819	125	25000.00	7	2022-03-21	2022-03-28	7.00	12250.00	162750.00
1507	820	117	35000.00	7	2024-01-07	2024-01-14	7.00	17150.00	227850.00
1508	821	116	25000.00	8	2025-04-21	2025-04-29	8.00	16000.00	184000.00
1509	822	107	35000.00	3	2020-03-19	2020-03-22	3.00	3150.00	101850.00
1510	823	106	25000.00	7	2021-10-18	2021-10-25	7.00	12250.00	162750.00
1511	824	118	25000.00	11	2022-05-01	2022-05-12	11.00	30250.00	244750.00
1512	825	103	35000.00	6	2019-01-22	2019-01-28	6.00	12600.00	197400.00
1513	826	113	35000.00	7	2023-01-04	2023-01-11	7.00	17150.00	227850.00
1514	827	102	25000.00	12	2022-09-12	2022-09-24	12.00	36000.00	264000.00
1515	828	107	35000.00	10	2020-02-24	2020-03-05	10.00	35000.00	315000.00
1516	829	119	35000.00	9	2019-08-14	2019-08-23	9.00	28350.00	286650.00
1517	830	109	35000.00	12	2022-08-11	2022-08-23	12.00	50400.00	369600.00
1518	831	105	35000.00	6	2021-04-26	2021-05-02	6.00	12600.00	197400.00
1519	832	107	35000.00	8	2019-10-09	2019-10-17	8.00	22400.00	257600.00
1520	833	117	35000.00	4	2022-08-22	2022-08-26	4.00	5600.00	134400.00
1521	834	102	25000.00	6	2019-06-12	2019-06-18	6.00	9000.00	141000.00
1522	835	115	35000.00	12	2020-12-21	2021-01-02	12.00	50400.00	369600.00
1523	836	105	35000.00	10	2019-06-16	2019-06-26	10.00	35000.00	315000.00
1524	837	105	35000.00	7	2024-10-04	2024-10-11	7.00	17150.00	227850.00
1525	838	120	25000.00	6	2022-09-29	2022-10-05	6.00	9000.00	141000.00
1526	839	108	25000.00	14	2019-09-21	2019-10-05	14.00	49000.00	301000.00
1527	840	111	35000.00	11	2024-04-12	2024-04-23	11.00	42350.00	342650.00
1528	841	109	35000.00	2	2022-06-23	2022-06-25	2.00	1400.00	68600.00
1529	842	105	35000.00	12	2024-05-08	2024-05-20	12.00	50400.00	369600.00
1530	843	117	35000.00	3	2023-10-19	2023-10-22	3.00	3150.00	101850.00
1531	844	125	25000.00	8	2020-12-30	2021-01-07	8.00	16000.00	184000.00
1532	845	102	25000.00	3	2019-12-24	2019-12-27	3.00	2250.00	72750.00
1533	846	102	25000.00	11	2023-06-12	2023-06-23	11.00	30250.00	244750.00
1534	847	115	35000.00	9	2022-02-13	2022-02-22	9.00	28350.00	286650.00
1535	848	127	25000.00	15	2025-01-26	2025-02-10	15.00	56250.00	318750.00
1536	849	101	35000.00	15	2022-03-13	2022-03-28	15.00	78750.00	446250.00
1537	850	110	25000.00	6	2024-06-13	2024-06-19	6.00	9000.00	141000.00
1538	851	114	25000.00	10	2023-07-28	2023-08-07	10.00	25000.00	225000.00
1539	852	119	35000.00	11	2023-03-23	2023-04-03	11.00	42350.00	342650.00
1540	853	103	35000.00	15	2019-09-02	2019-09-17	15.00	78750.00	446250.00
1541	854	120	25000.00	4	2019-04-21	2019-04-25	4.00	4000.00	96000.00
1542	855	116	25000.00	7	2025-01-28	2025-02-04	7.00	12250.00	162750.00
1543	856	124	25000.00	14	2019-03-16	2019-03-30	14.00	49000.00	301000.00
1544	857	123	25000.00	3	2020-02-05	2020-02-08	3.00	2250.00	72750.00
1545	858	107	35000.00	10	2019-12-09	2019-12-19	10.00	35000.00	315000.00
1546	859	121	25000.00	10	2023-10-10	2023-10-20	10.00	25000.00	225000.00
1547	860	123	25000.00	3	2020-05-25	2020-05-28	3.00	2250.00	72750.00
1548	861	123	25000.00	10	2021-09-26	2021-10-06	10.00	25000.00	225000.00
1549	862	122	25000.00	10	2021-02-09	2021-02-19	10.00	25000.00	225000.00
1550	863	114	25000.00	14	2020-08-16	2020-08-30	14.00	49000.00	301000.00
1551	864	101	35000.00	14	2024-08-29	2024-09-12	14.00	68600.00	421400.00
1552	865	117	35000.00	12	2020-02-18	2020-03-01	12.00	50400.00	369600.00
1553	866	107	35000.00	10	2024-04-07	2024-04-17	10.00	35000.00	315000.00
1554	867	102	25000.00	3	2021-02-17	2021-02-20	3.00	2250.00	72750.00
1555	868	101	35000.00	1	2023-10-28	2023-10-29	1.00	350.00	34650.00
1556	869	105	35000.00	11	2019-03-13	2019-03-24	11.00	42350.00	342650.00
1557	870	103	35000.00	8	2021-04-15	2021-04-23	8.00	22400.00	257600.00
1558	871	116	25000.00	4	2020-05-18	2020-05-22	4.00	4000.00	96000.00
1559	872	103	35000.00	13	2020-07-27	2020-08-09	13.00	59150.00	395850.00
1560	873	112	25000.00	14	2023-04-19	2023-05-03	14.00	49000.00	301000.00
1561	874	103	35000.00	4	2024-08-23	2024-08-27	4.00	5600.00	134400.00
1562	875	104	25000.00	1	2021-12-24	2021-12-25	1.00	250.00	24750.00
1563	876	118	25000.00	7	2021-08-14	2021-08-21	7.00	12250.00	162750.00
1564	877	115	35000.00	6	2020-08-18	2020-08-24	6.00	12600.00	197400.00
1565	878	123	25000.00	6	2021-11-23	2021-11-29	6.00	9000.00	141000.00
1566	879	108	25000.00	10	2022-12-14	2022-12-24	10.00	25000.00	225000.00
1567	880	120	25000.00	8	2021-10-08	2021-10-16	8.00	16000.00	184000.00
1568	881	109	35000.00	6	2019-10-08	2019-10-14	6.00	12600.00	197400.00
1569	882	123	25000.00	10	2020-02-16	2020-02-26	10.00	25000.00	225000.00
1570	883	101	35000.00	1	2022-02-20	2022-02-21	1.00	350.00	34650.00
1571	884	112	25000.00	1	2019-02-15	2019-02-16	1.00	250.00	24750.00
1572	885	125	25000.00	1	2019-07-05	2019-07-06	1.00	250.00	24750.00
1573	886	115	35000.00	1	2022-07-30	2022-07-31	1.00	350.00	34650.00
1574	887	113	35000.00	12	2023-12-14	2023-12-26	12.00	50400.00	369600.00
1575	888	117	35000.00	7	2019-07-16	2019-07-23	7.00	17150.00	227850.00
1576	889	106	25000.00	5	2020-04-07	2020-04-12	5.00	6250.00	118750.00
1577	890	107	35000.00	6	2020-08-12	2020-08-18	6.00	12600.00	197400.00
1578	891	121	25000.00	4	2021-07-28	2021-08-01	4.00	4000.00	96000.00
1579	892	101	35000.00	11	2022-01-19	2022-01-30	11.00	42350.00	342650.00
1580	893	122	25000.00	14	2019-12-16	2019-12-30	14.00	49000.00	301000.00
1581	894	117	35000.00	2	2023-07-06	2023-07-08	2.00	1400.00	68600.00
1582	895	127	25000.00	7	2022-05-31	2022-06-07	7.00	12250.00	162750.00
1583	896	104	25000.00	5	2023-01-31	2023-02-05	5.00	6250.00	118750.00
1584	897	110	25000.00	14	2021-04-24	2021-05-08	14.00	49000.00	301000.00
1585	898	124	25000.00	11	2024-12-22	2025-01-02	11.00	30250.00	244750.00
1586	899	107	35000.00	8	2020-07-17	2020-07-25	8.00	22400.00	257600.00
1587	900	124	25000.00	6	2021-02-19	2021-02-25	6.00	9000.00	141000.00
1588	901	119	35000.00	7	2023-12-21	2023-12-28	7.00	17150.00	227850.00
1589	902	103	35000.00	7	2024-11-17	2024-11-24	7.00	17150.00	227850.00
1590	903	107	35000.00	14	2024-06-16	2024-06-30	14.00	68600.00	421400.00
1591	904	105	35000.00	11	2019-03-31	2019-04-11	11.00	42350.00	342650.00
1592	905	126	25000.00	9	2023-07-05	2023-07-14	9.00	20250.00	204750.00
1593	906	104	25000.00	1	2019-04-06	2019-04-07	1.00	250.00	24750.00
1594	907	105	35000.00	1	2025-05-10	2025-05-11	1.00	350.00	34650.00
1595	908	103	35000.00	12	2022-02-26	2022-03-10	12.00	50400.00	369600.00
1596	909	112	25000.00	8	2022-02-02	2022-02-10	8.00	16000.00	184000.00
1597	910	105	35000.00	7	2022-08-14	2022-08-21	7.00	17150.00	227850.00
1598	911	106	25000.00	5	2025-01-13	2025-01-18	5.00	6250.00	118750.00
1599	912	116	25000.00	13	2021-08-04	2021-08-17	13.00	42250.00	282750.00
1600	913	127	25000.00	15	2020-03-23	2020-04-07	15.00	56250.00	318750.00
1601	914	114	25000.00	3	2024-11-09	2024-11-12	3.00	2250.00	72750.00
1602	915	113	35000.00	1	2020-07-16	2020-07-17	1.00	350.00	34650.00
1603	916	116	25000.00	8	2021-02-25	2021-03-05	8.00	16000.00	184000.00
1604	917	102	25000.00	15	2023-10-04	2023-10-19	15.00	56250.00	318750.00
1605	918	121	25000.00	1	2024-11-27	2024-11-28	1.00	250.00	24750.00
1606	919	124	25000.00	11	2021-11-30	2021-12-11	11.00	30250.00	244750.00
1607	920	123	25000.00	4	2019-10-11	2019-10-15	4.00	4000.00	96000.00
1608	921	126	25000.00	11	2022-09-30	2022-10-11	11.00	30250.00	244750.00
1609	922	111	35000.00	6	2019-04-19	2019-04-25	6.00	12600.00	197400.00
1610	923	103	35000.00	7	2019-09-28	2019-10-05	7.00	17150.00	227850.00
1611	924	124	25000.00	4	2022-04-14	2022-04-18	4.00	4000.00	96000.00
1612	925	106	25000.00	8	2023-01-21	2023-01-29	8.00	16000.00	184000.00
1613	926	119	35000.00	9	2024-10-14	2024-10-23	9.00	28350.00	286650.00
1614	927	117	35000.00	2	2021-03-22	2021-03-24	2.00	1400.00	68600.00
1615	928	114	25000.00	5	2019-11-14	2019-11-19	5.00	6250.00	118750.00
1616	929	123	25000.00	9	2020-04-24	2020-05-03	9.00	20250.00	204750.00
1617	930	127	25000.00	5	2024-05-04	2024-05-09	5.00	6250.00	118750.00
1618	931	123	25000.00	9	2020-11-16	2020-11-25	9.00	20250.00	204750.00
1619	932	103	35000.00	5	2022-03-18	2022-03-23	5.00	8750.00	166250.00
1620	933	103	35000.00	9	2021-06-17	2021-06-26	9.00	28350.00	286650.00
1621	934	122	25000.00	8	2019-02-21	2019-03-01	8.00	16000.00	184000.00
1622	935	108	25000.00	11	2021-06-18	2021-06-29	11.00	30250.00	244750.00
1623	936	105	35000.00	13	2021-04-14	2021-04-27	13.00	59150.00	395850.00
1624	937	121	25000.00	12	2024-06-08	2024-06-20	12.00	36000.00	264000.00
1625	938	120	25000.00	10	2020-01-14	2020-01-24	10.00	25000.00	225000.00
1626	939	108	25000.00	15	2023-09-24	2023-10-09	15.00	56250.00	318750.00
1627	940	115	35000.00	6	2024-08-31	2024-09-06	6.00	12600.00	197400.00
1628	941	109	35000.00	10	2020-05-25	2020-06-04	10.00	35000.00	315000.00
1629	942	109	35000.00	8	2024-12-26	2025-01-03	8.00	22400.00	257600.00
1630	943	102	25000.00	12	2024-09-24	2024-10-06	12.00	36000.00	264000.00
1631	944	114	25000.00	7	2024-11-23	2024-11-30	7.00	12250.00	162750.00
1632	945	108	25000.00	12	2021-08-21	2021-09-02	12.00	36000.00	264000.00
1633	946	109	35000.00	1	2025-02-05	2025-02-06	1.00	350.00	34650.00
1634	947	122	25000.00	13	2020-10-20	2020-11-02	13.00	42250.00	282750.00
1635	948	111	35000.00	7	2023-11-30	2023-12-07	7.00	17150.00	227850.00
1636	949	113	35000.00	1	2023-03-20	2023-03-21	1.00	350.00	34650.00
1637	950	110	25000.00	6	2022-08-29	2022-09-04	6.00	9000.00	141000.00
1638	951	107	35000.00	12	2021-11-25	2021-12-07	12.00	50400.00	369600.00
1639	952	103	35000.00	12	2019-01-04	2019-01-16	12.00	50400.00	369600.00
1640	953	123	25000.00	4	2019-02-05	2019-02-09	4.00	4000.00	96000.00
1641	954	103	35000.00	9	2021-08-05	2021-08-14	9.00	28350.00	286650.00
1642	955	107	35000.00	7	2019-05-24	2019-05-31	7.00	17150.00	227850.00
1643	956	109	35000.00	7	2020-09-29	2020-10-06	7.00	17150.00	227850.00
1644	957	121	25000.00	9	2024-02-02	2024-02-11	9.00	20250.00	204750.00
1645	958	104	25000.00	12	2024-03-05	2024-03-17	0.00	0.00	300000.00
1646	959	116	25000.00	12	2019-04-13	2019-04-25	0.00	0.00	300000.00
1647	960	111	35000.00	6	2024-11-23	2024-11-29	0.00	0.00	210000.00
1648	961	111	35000.00	11	2023-03-20	2023-03-31	0.00	0.00	385000.00
1649	962	116	25000.00	2	2022-09-19	2022-09-21	0.00	0.00	50000.00
1650	963	108	25000.00	1	2020-01-16	2020-01-17	0.00	0.00	25000.00
1651	964	112	25000.00	14	2020-07-10	2020-07-24	0.00	0.00	350000.00
1652	965	107	35000.00	7	2020-04-26	2020-05-03	0.00	0.00	245000.00
1653	966	110	25000.00	7	2022-10-01	2022-10-08	0.00	0.00	175000.00
1654	967	105	35000.00	7	2023-03-18	2023-03-25	0.00	0.00	245000.00
1655	968	112	25000.00	11	2021-10-17	2021-10-28	0.00	0.00	275000.00
1656	969	117	35000.00	12	2023-01-04	2023-01-16	0.00	0.00	420000.00
1657	970	103	35000.00	12	2022-09-30	2022-10-12	0.00	0.00	420000.00
1658	971	126	25000.00	6	2025-04-11	2025-04-17	0.00	0.00	150000.00
1659	972	123	25000.00	5	2022-03-04	2022-03-09	0.00	0.00	125000.00
1660	973	103	35000.00	10	2019-03-30	2019-04-09	0.00	0.00	350000.00
1661	974	117	35000.00	3	2020-01-04	2020-01-07	0.00	0.00	105000.00
1662	975	127	25000.00	2	2019-12-06	2019-12-08	0.00	0.00	50000.00
1663	976	113	35000.00	15	2023-10-02	2023-10-17	0.00	0.00	525000.00
1664	977	105	35000.00	7	2020-07-14	2020-07-21	0.00	0.00	245000.00
1665	978	120	25000.00	10	2021-04-19	2021-04-29	0.00	0.00	250000.00
1666	979	126	25000.00	4	2019-07-14	2019-07-18	0.00	0.00	100000.00
1667	980	121	25000.00	5	2019-08-26	2019-08-31	0.00	0.00	125000.00
1668	981	116	25000.00	11	2023-01-15	2023-01-26	0.00	0.00	275000.00
1669	982	123	25000.00	4	2022-02-07	2022-02-11	0.00	0.00	100000.00
1670	983	104	25000.00	14	2021-01-20	2021-02-03	0.00	0.00	350000.00
1671	984	107	35000.00	6	2023-03-02	2023-03-08	0.00	0.00	210000.00
1672	985	103	35000.00	6	2019-06-20	2019-06-26	0.00	0.00	210000.00
1673	986	125	25000.00	3	2025-02-27	2025-03-02	0.00	0.00	75000.00
1674	987	110	25000.00	5	2022-05-12	2022-05-17	0.00	0.00	125000.00
1675	988	124	25000.00	12	2024-03-16	2024-03-28	0.00	0.00	300000.00
1676	989	102	25000.00	9	2024-06-30	2024-07-09	0.00	0.00	225000.00
1677	990	125	25000.00	12	2022-01-05	2022-01-17	0.00	0.00	300000.00
1678	991	105	35000.00	5	2024-08-26	2024-08-31	0.00	0.00	175000.00
1679	992	116	25000.00	12	2021-10-03	2021-10-15	0.00	0.00	300000.00
1680	993	114	25000.00	9	2020-12-20	2020-12-29	0.00	0.00	225000.00
1681	994	108	25000.00	15	2022-10-06	2022-10-21	0.00	0.00	375000.00
1682	995	122	25000.00	14	2024-10-24	2024-11-07	0.00	0.00	350000.00
1683	996	105	35000.00	2	2020-06-16	2020-06-18	0.00	0.00	70000.00
1684	997	115	35000.00	6	2020-07-23	2020-07-29	0.00	0.00	210000.00
1685	998	101	35000.00	7	2021-11-14	2021-11-21	0.00	0.00	245000.00
1686	999	125	25000.00	9	2019-04-20	2019-04-29	0.00	0.00	225000.00
1687	1000	117	35000.00	14	2022-10-28	2022-11-11	0.00	0.00	490000.00
1688	1001	121	25000.00	1	2020-02-15	2020-02-16	0.00	0.00	25000.00
1689	1002	105	35000.00	11	2020-12-13	2020-12-24	0.00	0.00	385000.00
\.


                                                                                                                  4967.dat                                                                                            0000600 0004000 0002000 00000076333 15015342721 0014277 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	15000.00	1	15000.00
6	2	2	19010.00	1	0.00
2	2	2	40672.00	1	40672.00
1	4	8	15000.00	1	15000.00
5	5	11	38938.00	1	38938.00
5	6	12	38938.00	1	38938.00
1	7	15	15000.00	1	15000.00
3	8	16	25851.00	1	25851.00
500	9	17	35882.00	2	71764.00
8	10	21	19004.00	1	19004.00
9	11	22	46299.00	1	46299.00
10	12	24	21261.00	1	21261.00
11	13	28	27492.00	1	27492.00
5	14	29	38938.00	1	38938.00
13	15	31	48425.00	1	48425.00
14	16	35	36470.00	1	36470.00
5	17	36	38938.00	1	38938.00
11	18	40	27492.00	1	27492.00
12	19	43	44284.00	1	44284.00
11	20	44	27492.00	1	27492.00
5	21	45	38938.00	1	38938.00
13	22	46	48425.00	1	48425.00
9	23	47	46299.00	1	46299.00
13	24	48	48425.00	1	48425.00
8	25	49	19004.00	1	19004.00
15	26	51	33966.00	1	33966.00
3	27	53	25851.00	1	25851.00
9	28	56	46299.00	1	46299.00
3	29	58	25851.00	1	25851.00
2	30	59	40672.00	1	40672.00
10	31	61	21261.00	1	21261.00
14	32	63	36470.00	1	36470.00
15	33	65	33966.00	1	33966.00
3	34	70	25851.00	1	25851.00
5	35	72	38938.00	1	38938.00
6	36	79	19010.00	1	19010.00
3	37	92	25851.00	1	25851.00
12	38	93	44284.00	1	44284.00
9	39	95	46299.00	1	46299.00
13	40	103	48425.00	1	48425.00
1	41	104	15000.00	1	15000.00
12	42	110	44284.00	1	44284.00
5	43	115	38938.00	1	38938.00
14	44	118	36470.00	1	36470.00
9	45	119	46299.00	1	46299.00
9	46	123	46299.00	1	46299.00
7	47	125	23107.00	1	23107.00
10	48	130	21261.00	1	21261.00
11	49	131	27492.00	1	27492.00
3	50	132	25851.00	1	25851.00
13	51	134	48425.00	1	48425.00
12	52	136	44284.00	1	44284.00
4	53	137	14171.00	1	14171.00
4	54	138	14171.00	1	14171.00
5	55	143	38938.00	1	38938.00
3	56	144	25851.00	1	25851.00
3	57	148	25851.00	1	25851.00
3	58	150	25851.00	1	25851.00
11	59	162	27492.00	1	27492.00
9	60	166	46299.00	1	46299.00
15	61	168	33966.00	1	33966.00
4	62	170	14171.00	1	14171.00
7	63	174	23107.00	1	23107.00
12	64	178	44284.00	1	44284.00
11	65	182	27492.00	1	27492.00
10	66	187	21261.00	1	21261.00
10	67	189	21261.00	1	21261.00
10	68	191	21261.00	1	21261.00
1	69	192	15000.00	1	15000.00
6	70	199	19010.00	1	19010.00
8	71	201	19004.00	1	19004.00
11	72	202	27492.00	1	27492.00
833	73	207	42477.00	1	42477.00
834	74	209	18771.00	1	18771.00
835	75	211	15241.00	1	15241.00
839	76	213	46618.00	1	46618.00
843	77	225	10111.00	1	10111.00
844	78	229	47581.00	1	47581.00
845	79	230	28414.00	1	28414.00
853	80	252	17708.00	1	17708.00
854	81	254	42369.00	1	42369.00
858	82	259	45647.00	1	45647.00
263	83	260	33538.00	1	33538.00
268	84	261	31414.00	1	31414.00
270	85	262	31965.00	1	31965.00
271	86	263	40841.00	1	40841.00
272	87	268	13909.00	1	13909.00
273	88	270	30979.00	1	30979.00
64	89	271	43351.00	3	130053.00
11	90	272	27492.00	1	27492.00
32	91	273	24293.00	1	24293.00
60	92	277	29837.00	1	29837.00
9	93	278	46299.00	1	46299.00
5	94	279	38938.00	1	38938.00
55	95	284	38380.00	1	38380.00
77	96	286	28336.00	1	28336.00
2	97	288	40672.00	1	40672.00
31	98	290	48143.00	1	48143.00
17	99	293	27907.00	1	27907.00
74	100	295	34780.00	1	34780.00
58	101	300	37671.00	1	37671.00
32	102	307	24293.00	1	24293.00
50	103	308	16494.00	1	16494.00
2	104	312	40672.00	1	40672.00
26	105	314	49896.00	1	49896.00
38	106	315	48183.00	1	48183.00
73	107	329	11419.00	1	11419.00
34	108	331	48629.00	1	48629.00
12	109	336	44284.00	1	44284.00
10	110	344	21261.00	1	21261.00
19	111	349	34950.00	1	34950.00
3	112	351	25851.00	1	25851.00
41	113	353	15415.00	1	15415.00
15	114	357	33966.00	1	33966.00
14	115	359	36470.00	1	36470.00
46	116	363	18733.00	1	18733.00
24	117	364	13764.00	1	13764.00
98	118	367	42366.00	1	42366.00
69	119	368	34898.00	1	34898.00
96	120	374	35322.00	1	35322.00
22	121	378	34122.00	1	34122.00
27	122	380	10157.00	1	10157.00
80	123	384	43899.00	1	43899.00
91	124	389	49118.00	1	49118.00
25	125	390	22031.00	1	22031.00
18	126	397	15577.00	1	15577.00
43	127	398	12322.00	1	12322.00
28	128	399	11140.00	1	11140.00
19	129	401	34950.00	1	34950.00
19	130	403	34950.00	1	34950.00
87	131	404	25648.00	1	25648.00
58	132	408	37671.00	1	37671.00
66	133	412	34788.00	1	34788.00
5	134	416	38938.00	1	38938.00
15	135	423	33966.00	1	33966.00
54	136	425	30954.00	1	30954.00
47	137	426	31660.00	1	31660.00
40	138	427	42149.00	2	84298.00
20	139	429	32951.00	1	32951.00
44	140	430	31389.00	1	31389.00
45	141	435	11169.00	1	11169.00
43	142	437	12322.00	1	12322.00
100	143	439	15995.00	1	15995.00
40	144	440	42149.00	1	42149.00
38	145	442	48183.00	1	48183.00
10	146	443	21261.00	1	21261.00
85	147	446	46935.00	1	46935.00
95	148	447	44401.00	1	44401.00
90	149	450	42053.00	1	42053.00
40	150	451	42149.00	1	42149.00
10	151	466	21261.00	1	21261.00
85	152	467	46935.00	1	46935.00
100	153	469	15995.00	1	15995.00
40	154	471	42149.00	1	42149.00
47	155	472	31660.00	1	31660.00
7	156	482	23107.00	1	23107.00
61	157	487	28467.00	1	28467.00
86	158	492	43228.00	1	43228.00
29	159	496	44374.00	1	44374.00
40	160	497	42149.00	1	42149.00
36	161	498	11247.00	1	11247.00
88	162	502	29262.00	1	29262.00
14	163	503	36470.00	1	36470.00
90	164	510	42053.00	1	42053.00
82	165	511	37375.00	1	37375.00
14	166	512	36470.00	1	36470.00
24	167	514	13764.00	1	13764.00
65	168	518	33278.00	1	33278.00
58	169	519	37671.00	1	37671.00
79	170	522	16132.00	1	16132.00
47	171	525	31660.00	1	31660.00
40	172	527	42149.00	1	42149.00
4	173	529	14171.00	1	14171.00
38	174	534	48183.00	1	48183.00
57	175	536	13677.00	1	13677.00
48	176	537	18373.00	1	18373.00
72	177	553	44162.00	1	44162.00
24	178	554	13764.00	1	13764.00
99	179	555	42556.00	1	42556.00
21	180	568	25414.00	1	25414.00
60	181	577	29837.00	1	29837.00
5	182	579	38938.00	1	38938.00
42	183	583	32549.00	1	32549.00
30	184	584	16375.00	1	16375.00
14	185	586	36470.00	1	36470.00
14	186	588	36470.00	1	36470.00
42	187	591	32549.00	1	32549.00
45	188	600	11169.00	1	11169.00
4	189	604	14171.00	1	14171.00
82	190	605	37375.00	1	37375.00
64	191	606	43351.00	1	43351.00
93	192	607	48872.00	1	48872.00
87	193	613	25648.00	1	25648.00
61	194	620	28467.00	1	28467.00
48	195	621	18373.00	1	18373.00
77	196	623	28336.00	1	28336.00
85	197	624	46935.00	1	46935.00
66	198	627	34788.00	1	34788.00
99	199	631	42556.00	1	42556.00
45	200	632	11169.00	1	11169.00
34	201	642	48629.00	1	48629.00
47	202	643	31660.00	1	31660.00
12	203	644	44284.00	1	44284.00
84	204	649	44124.00	1	44124.00
71	205	651	46666.00	1	46666.00
89	206	659	17215.00	1	17215.00
38	207	663	48183.00	1	48183.00
92	208	668	21232.00	1	21232.00
12	209	678	44284.00	1	44284.00
60	210	679	29837.00	1	29837.00
32	211	682	24293.00	1	24293.00
87	212	683	25648.00	1	25648.00
70	213	684	11840.00	1	11840.00
84	214	687	44124.00	1	44124.00
55	215	688	38380.00	1	38380.00
83	216	690	19560.00	1	19560.00
45	217	691	11169.00	1	11169.00
94	218	693	43134.00	1	43134.00
16	219	695	17741.00	1	17741.00
36	220	696	11247.00	1	11247.00
44	221	697	31389.00	1	31389.00
38	222	700	48183.00	1	48183.00
77	223	703	28336.00	1	28336.00
53	224	708	17651.00	1	17651.00
94	225	710	43134.00	1	43134.00
6	226	712	19010.00	1	19010.00
91	227	715	49118.00	1	49118.00
2	228	716	40672.00	1	40672.00
69	229	717	34898.00	1	34898.00
36	230	720	11247.00	1	11247.00
46	231	723	18733.00	1	18733.00
61	232	726	28467.00	1	28467.00
15	233	727	33966.00	1	33966.00
40	234	728	42149.00	1	42149.00
85	235	733	46935.00	1	46935.00
94	236	735	43134.00	1	43134.00
17	237	738	27907.00	1	27907.00
48	238	743	18373.00	1	18373.00
35	239	748	14099.00	1	14099.00
70	240	750	11840.00	1	11840.00
15	241	751	33966.00	1	33966.00
75	242	754	48488.00	1	48488.00
62	243	759	48344.00	1	48344.00
88	244	763	29262.00	1	29262.00
29	245	765	44374.00	1	44374.00
74	246	767	34780.00	1	34780.00
67	247	768	31644.00	1	31644.00
98	248	774	42366.00	1	42366.00
20	249	781	32951.00	1	32951.00
72	250	785	44162.00	1	44162.00
83	251	791	19560.00	1	19560.00
60	252	793	29837.00	1	29837.00
89	253	797	17215.00	1	17215.00
89	254	799	17215.00	1	17215.00
60	255	800	29837.00	1	29837.00
65	256	805	33278.00	1	33278.00
18	257	807	15577.00	1	15577.00
40	258	819	42149.00	1	42149.00
25	259	820	22031.00	1	22031.00
46	260	829	18733.00	1	18733.00
42	261	831	32549.00	1	32549.00
16	262	833	17741.00	1	17741.00
48	263	834	18373.00	1	18373.00
46	264	835	18733.00	1	18733.00
49	265	839	48176.00	1	48176.00
36	266	843	11247.00	1	11247.00
38	267	844	48183.00	1	48183.00
59	268	845	15598.00	1	15598.00
12	269	853	44284.00	1	44284.00
46	270	854	18733.00	1	18733.00
30	271	858	16375.00	1	16375.00
66	272	861	34788.00	1	34788.00
12	273	866	44284.00	1	44284.00
28	274	876	11140.00	1	11140.00
23	275	877	22156.00	1	22156.00
18	276	881	15577.00	1	15577.00
49	277	883	48176.00	1	48176.00
57	278	884	13677.00	1	13677.00
85	279	885	46935.00	1	46935.00
83	280	888	19560.00	1	19560.00
96	281	896	35322.00	1	35322.00
66	282	902	34788.00	1	34788.00
100	283	909	15995.00	1	15995.00
87	284	917	25648.00	1	25648.00
25	285	923	22031.00	1	22031.00
46	286	926	18733.00	1	18733.00
26	287	929	49896.00	1	49896.00
62	288	936	48344.00	1	48344.00
12	289	940	44284.00	1	44284.00
99	290	941	42556.00	1	42556.00
17	291	944	27907.00	1	27907.00
98	292	945	42366.00	1	42366.00
9	293	947	46299.00	1	46299.00
63	294	949	48656.00	1	48656.00
57	295	954	13677.00	1	13677.00
82	296	956	37375.00	1	37375.00
74	297	958	34780.00	2	69560.00
171	298	960	16257.00	1	16257.00
172	299	963	44572.00	1	44572.00
173	300	969	36282.00	1	36282.00
174	301	973	20280.00	1	20280.00
57	302	975	13677.00	2	27354.00
85	303	977	46935.00	1	46935.00
83	304	980	19560.00	1	19560.00
96	305	984	35322.00	1	35322.00
66	306	985	34788.00	1	34788.00
174	307	988	20280.00	1	20280.00
175	308	990	49014.00	1	49014.00
176	309	992	36581.00	1	36581.00
177	310	999	17906.00	1	17906.00
178	311	1000	31578.00	1	31578.00
20	312	1001	32951.00	1	32951.00
21	313	1002	25414.00	1	25414.00
22	314	1003	34122.00	1	34122.00
23	315	1004	22156.00	1	22156.00
24	316	1005	13764.00	1	13764.00
25	317	1006	22031.00	1	22031.00
26	318	1007	49896.00	1	49896.00
27	319	1008	10157.00	1	10157.00
14	320	1009	36470.00	1	36470.00
29	321	1010	44374.00	1	44374.00
30	322	1011	16375.00	3	49125.00
31	323	1012	48143.00	1	48143.00
32	324	1013	24293.00	1	24293.00
33	325	1014	44056.00	1	44056.00
34	326	1015	48629.00	1	48629.00
35	327	1016	14099.00	1	14099.00
36	328	1017	11247.00	2	22494.00
12	329	1018	44284.00	7	309988.00
38	330	1019	48183.00	4	192732.00
39	331	1020	11468.00	1	11468.00
40	332	1021	42149.00	1	42149.00
41	333	1022	15415.00	1	15415.00
42	334	1023	32549.00	1	32549.00
43	335	1024	12322.00	1	12322.00
44	336	1025	31389.00	1	31389.00
45	337	1026	11169.00	1	11169.00
46	338	1027	18733.00	1	18733.00
47	339	1028	31660.00	1	31660.00
48	340	1029	18373.00	1	18373.00
49	341	1030	48176.00	1	48176.00
50	342	1031	16494.00	1	16494.00
51	343	1032	16364.00	1	16364.00
52	344	1033	15299.00	1	15299.00
53	345	1034	17651.00	1	17651.00
54	346	1035	30954.00	1	30954.00
55	347	1036	38380.00	1	38380.00
56	348	1037	20305.00	1	20305.00
57	349	1038	13677.00	1	13677.00
58	350	1039	37671.00	1	37671.00
59	351	1040	15598.00	1	15598.00
60	352	1041	29837.00	1	29837.00
61	353	1042	28467.00	1	28467.00
62	354	1043	48344.00	1	48344.00
23	355	1044	22156.00	1	22156.00
64	356	1045	43351.00	1	43351.00
65	357	1046	33278.00	1	33278.00
66	358	1047	34788.00	1	34788.00
67	359	1048	31644.00	1	31644.00
68	360	1049	14904.00	1	14904.00
69	361	1050	34898.00	1	34898.00
70	362	1051	11840.00	1	11840.00
71	363	1052	46666.00	1	46666.00
72	364	1053	44162.00	1	44162.00
233	365	1054	14599.00	1	14599.00
234	366	1055	34817.00	1	34817.00
235	367	1056	30402.00	1	30402.00
236	368	1057	45806.00	1	45806.00
237	369	1058	44345.00	1	44345.00
238	370	1059	26372.00	1	26372.00
239	371	1060	31052.00	1	31052.00
240	372	1061	48385.00	1	48385.00
241	373	1062	12515.00	1	12515.00
2	374	1063	40672.00	1	40672.00
243	375	1064	33585.00	1	33585.00
244	376	1065	22705.00	1	22705.00
222	377	1066	44753.00	1	44753.00
246	378	1067	12004.00	1	12004.00
1	379	1068	15000.00	1	15000.00
248	380	1069	16682.00	1	16682.00
249	381	1070	12397.00	1	12397.00
250	382	1071	27784.00	1	27784.00
251	383	1072	39632.00	1	39632.00
252	384	1073	34656.00	1	34656.00
253	385	1074	38135.00	1	38135.00
254	386	1075	24881.00	1	24881.00
255	387	1076	10997.00	1	10997.00
256	388	1077	28671.00	1	28671.00
257	389	1078	36421.00	1	36421.00
258	390	1079	38333.00	1	38333.00
259	391	1080	38834.00	1	38834.00
260	392	1081	46656.00	1	46656.00
261	393	1082	33688.00	1	33688.00
262	394	1083	24018.00	1	24018.00
263	395	1084	33538.00	1	33538.00
264	396	1085	47241.00	1	47241.00
265	397	1086	18810.00	7	131670.00
266	398	1087	30744.00	2	61488.00
267	399	1088	19567.00	2	39134.00
268	400	1089	31414.00	2	62828.00
269	401	1090	16693.00	2	33386.00
270	402	1091	31965.00	2	63930.00
271	403	1092	40841.00	2	81682.00
272	404	1093	13909.00	1	13909.00
273	405	1094	30979.00	5	154895.00
274	406	1095	24982.00	3	74946.00
275	407	1096	41286.00	1	41286.00
276	408	1097	20225.00	1	20225.00
277	409	1098	21461.00	1	21461.00
278	410	1099	13319.00	1	13319.00
279	411	1100	13580.00	1	13580.00
280	412	1101	47170.00	1	47170.00
281	413	1102	25489.00	1	25489.00
282	414	1103	37025.00	1	37025.00
460	415	1104	37435.00	1	37435.00
461	416	1105	46808.00	1	46808.00
462	417	1106	38564.00	1	38564.00
463	418	1107	14874.00	1	14874.00
464	419	1108	17884.00	1	17884.00
465	420	1109	44937.00	1	44937.00
466	421	1110	29716.00	1	29716.00
2	422	1111	40672.00	1	40672.00
468	423	1112	24509.00	1	24509.00
469	424	1113	42739.00	1	42739.00
470	425	1114	11097.00	1	11097.00
471	426	1115	26681.00	1	26681.00
472	427	1116	46863.00	1	46863.00
43	428	1117	12322.00	1	12322.00
474	429	1118	31771.00	1	31771.00
475	430	1119	19811.00	1	19811.00
476	431	1120	41665.00	1	41665.00
477	432	1121	30446.00	1	30446.00
478	433	1122	26835.00	1	26835.00
479	434	1123	18100.00	1	18100.00
480	435	1124	15375.00	1	15375.00
481	436	1125	12900.00	1	12900.00
482	437	1126	17738.00	1	17738.00
483	438	1127	17046.00	1	17046.00
484	439	1128	27017.00	1	27017.00
485	440	1129	44487.00	1	44487.00
486	441	1130	29350.00	1	29350.00
487	442	1131	24300.00	1	24300.00
488	443	1132	18893.00	1	18893.00
489	444	1133	36772.00	1	36772.00
490	445	1134	30946.00	1	30946.00
491	446	1135	10477.00	1	10477.00
492	447	1136	14929.00	1	14929.00
493	448	1137	25971.00	1	25971.00
494	449	1138	49766.00	2	99532.00
495	450	1139	40807.00	6	244842.00
496	451	1140	49126.00	2	98252.00
497	452	1141	46618.00	1	46618.00
498	453	1142	17901.00	1	17901.00
499	454	1143	31019.00	1	31019.00
500	455	1144	35882.00	1	35882.00
3	456	1145	25851.00	1	25851.00
3	457	1146	25851.00	1	25851.00
3	458	1147	25851.00	1	25851.00
504	459	1148	47519.00	1	47519.00
505	460	1149	19866.00	1	19866.00
506	461	1150	30623.00	1	30623.00
507	462	1151	28335.00	1	28335.00
508	463	1152	20880.00	1	20880.00
509	464	1153	21616.00	1	21616.00
510	465	1154	47309.00	1	47309.00
511	466	1155	43232.00	1	43232.00
512	467	1156	14112.00	1	14112.00
513	468	1157	29083.00	1	29083.00
514	469	1158	17875.00	1	17875.00
515	470	1159	17632.00	1	17632.00
516	471	1160	17110.00	1	17110.00
517	472	1161	43089.00	1	43089.00
518	473	1162	38175.00	1	38175.00
519	474	1163	13438.00	1	13438.00
520	475	1164	25486.00	1	25486.00
521	476	1165	36923.00	1	36923.00
522	477	1166	23069.00	1	23069.00
523	478	1167	24594.00	1	24594.00
524	479	1168	16230.00	1	16230.00
525	480	1169	41431.00	1	41431.00
526	481	1170	28840.00	1	28840.00
527	482	1171	15651.00	1	15651.00
528	483	1172	34741.00	1	34741.00
529	484	1173	36301.00	1	36301.00
530	485	1174	16206.00	1	16206.00
531	486	1175	36452.00	1	36452.00
532	487	1176	32291.00	1	32291.00
533	488	1177	13120.00	1	13120.00
534	489	1178	26638.00	1	26638.00
535	490	1179	44313.00	1	44313.00
536	491	1180	28265.00	1	28265.00
537	492	1181	30302.00	1	30302.00
538	493	1182	41470.00	1	41470.00
539	494	1183	36628.00	1	36628.00
540	495	1184	28964.00	1	28964.00
541	496	1185	36687.00	1	36687.00
542	497	1186	39750.00	1	39750.00
543	498	1187	30411.00	1	30411.00
544	499	1188	19815.00	1	19815.00
545	500	1189	39254.00	1	39254.00
546	501	1190	39402.00	1	39402.00
547	502	1191	31940.00	1	31940.00
548	503	1192	44654.00	1	44654.00
710	504	1193	12403.00	1	12403.00
711	505	1194	30522.00	1	30522.00
712	506	1195	28125.00	1	28125.00
713	507	1196	40184.00	1	40184.00
714	508	1197	37914.00	1	37914.00
12	509	1198	44284.00	1	44284.00
716	510	1199	15021.00	4	60084.00
717	511	1200	11459.00	1	11459.00
718	512	1201	25783.00	4	103132.00
719	513	1202	29057.00	4	116228.00
720	514	1203	35369.00	2	70738.00
435	515	1204	42487.00	3	127461.00
722	516	1205	49097.00	1	49097.00
723	517	1206	45908.00	1	45908.00
724	518	1207	20939.00	1	20939.00
355	519	1208	27635.00	1	27635.00
726	520	1209	41539.00	1	41539.00
727	521	1210	29290.00	1	29290.00
728	522	1211	36216.00	1	36216.00
729	523	1212	25059.00	1	25059.00
730	524	1213	14036.00	1	14036.00
731	525	1214	32203.00	1	32203.00
732	526	1215	32984.00	1	32984.00
733	527	1216	20043.00	1	20043.00
734	528	1217	25214.00	1	25214.00
735	529	1218	32691.00	1	32691.00
736	530	1219	16674.00	1	16674.00
737	531	1220	32991.00	1	32991.00
738	532	1221	10546.00	1	10546.00
739	533	1222	22434.00	1	22434.00
740	534	1223	15815.00	1	15815.00
741	535	1224	40350.00	1	40350.00
742	536	1225	13861.00	1	13861.00
743	537	1226	23488.00	1	23488.00
744	538	1227	34688.00	1	34688.00
745	539	1228	26288.00	1	26288.00
746	540	1229	28005.00	1	28005.00
747	541	1230	10371.00	1	10371.00
748	542	1231	32607.00	1	32607.00
749	543	1232	24578.00	1	24578.00
750	544	1233	19177.00	1	19177.00
751	545	1234	16431.00	1	16431.00
752	546	1235	18536.00	1	18536.00
753	547	1236	11761.00	1	11761.00
754	548	1237	26955.00	1	26955.00
755	549	1238	47062.00	1	47062.00
756	550	1239	11690.00	1	11690.00
757	551	1240	13052.00	1	13052.00
758	552	1241	24806.00	1	24806.00
759	553	1242	26905.00	1	26905.00
760	554	1243	49263.00	1	49263.00
761	555	1244	12180.00	1	12180.00
762	556	1245	20164.00	1	20164.00
763	557	1246	40437.00	1	40437.00
764	558	1247	32741.00	1	32741.00
765	559	1248	33374.00	1	33374.00
766	560	1249	20454.00	1	20454.00
767	561	1250	49516.00	1	49516.00
68	562	1251	14904.00	1	14904.00
769	563	1252	22731.00	1	22731.00
770	564	1253	43622.00	1	43622.00
771	565	1254	22058.00	1	22058.00
772	566	1255	13533.00	1	13533.00
773	567	1256	30851.00	1	30851.00
774	568	1257	30079.00	1	30079.00
775	569	1258	47207.00	1	47207.00
776	570	1259	37544.00	1	37544.00
777	571	1260	11853.00	1	11853.00
778	572	1261	45479.00	1	45479.00
779	573	1262	40131.00	1	40131.00
780	574	1263	16570.00	1	16570.00
781	575	1264	34038.00	1	34038.00
782	576	1265	21854.00	1	21854.00
783	577	1266	34886.00	1	34886.00
784	578	1267	20585.00	1	20585.00
785	579	1268	42100.00	1	42100.00
786	580	1269	16585.00	1	16585.00
787	581	1270	30728.00	1	30728.00
788	582	1271	23418.00	1	23418.00
789	583	1272	13492.00	1	13492.00
790	584	1273	41426.00	1	41426.00
791	585	1274	39780.00	1	39780.00
792	586	1275	15111.00	1	15111.00
793	587	1276	31856.00	1	31856.00
794	588	1277	40362.00	1	40362.00
795	589	1278	30139.00	1	30139.00
796	590	1279	10144.00	1	10144.00
797	591	1280	28566.00	1	28566.00
798	592	1281	35277.00	1	35277.00
799	593	1282	20734.00	1	20734.00
800	594	1283	36148.00	1	36148.00
801	595	1284	15125.00	1	15125.00
802	596	1285	29275.00	1	29275.00
803	597	1286	36767.00	1	36767.00
6	598	1287	19010.00	1	19010.00
7	599	1288	23107.00	1	23107.00
8	600	1289	19004.00	1	19004.00
9	601	1290	46299.00	1	46299.00
10	602	1291	21261.00	1	21261.00
11	603	1292	27492.00	1	27492.00
608	604	1293	28910.00	1	28910.00
13	605	1294	48425.00	1	48425.00
14	606	1295	36470.00	1	36470.00
15	607	1296	33966.00	1	33966.00
16	608	1297	17741.00	1	17741.00
17	609	1298	27907.00	1	27907.00
18	610	1299	15577.00	1	15577.00
19	611	1300	34950.00	1	34950.00
20	612	1301	32951.00	1	32951.00
21	613	1302	25414.00	1	25414.00
22	614	1303	34122.00	1	34122.00
23	615	1304	22156.00	1	22156.00
24	616	1305	13764.00	1	13764.00
25	617	1306	22031.00	1	22031.00
26	618	1307	49896.00	1	49896.00
27	619	1308	10157.00	1	10157.00
28	620	1309	11140.00	1	11140.00
29	621	1310	44374.00	1	44374.00
30	622	1311	16375.00	1	16375.00
31	623	1312	48143.00	1	48143.00
32	624	1313	24293.00	1	24293.00
33	625	1314	44056.00	1	44056.00
34	626	1315	48629.00	1	48629.00
35	627	1316	14099.00	1	14099.00
36	628	1317	11247.00	1	11247.00
37	629	1318	41949.00	1	41949.00
38	630	1319	48183.00	1	48183.00
39	631	1320	11468.00	1	11468.00
40	632	1321	42149.00	1	42149.00
41	633	1322	15415.00	1	15415.00
42	634	1323	32549.00	1	32549.00
43	635	1324	12322.00	1	12322.00
44	636	1325	31389.00	1	31389.00
45	637	1326	11169.00	1	11169.00
46	638	1327	18733.00	1	18733.00
47	639	1328	31660.00	1	31660.00
48	640	1329	18373.00	1	18373.00
49	641	1330	48176.00	1	48176.00
50	642	1331	16494.00	1	16494.00
51	643	1332	16364.00	1	16364.00
52	644	1333	15299.00	1	15299.00
53	645	1334	17651.00	1	17651.00
54	646	1335	30954.00	1	30954.00
55	647	1336	38380.00	1	38380.00
56	648	1337	20305.00	1	20305.00
57	649	1338	13677.00	1	13677.00
58	650	1339	37671.00	1	37671.00
59	651	1340	15598.00	1	15598.00
60	652	1341	29837.00	1	29837.00
61	653	1342	28467.00	1	28467.00
62	654	1343	48344.00	1	48344.00
63	655	1344	48656.00	1	48656.00
64	656	1345	43351.00	1	43351.00
65	657	1346	33278.00	1	33278.00
66	658	1347	34788.00	1	34788.00
67	659	1348	31644.00	1	31644.00
68	660	1349	14904.00	1	14904.00
69	661	1350	34898.00	1	34898.00
70	662	1351	11840.00	1	11840.00
71	663	1352	46666.00	1	46666.00
72	664	1353	44162.00	1	44162.00
73	665	1354	11419.00	1	11419.00
74	666	1355	34780.00	1	34780.00
75	667	1356	48488.00	1	48488.00
76	668	1357	12719.00	1	12719.00
77	669	1358	28336.00	1	28336.00
78	670	1359	32499.00	1	32499.00
79	671	1360	16132.00	1	16132.00
80	672	1361	43899.00	1	43899.00
81	673	1362	41236.00	1	41236.00
82	674	1363	37375.00	1	37375.00
83	675	1364	19560.00	1	19560.00
84	676	1365	44124.00	1	44124.00
85	677	1366	46935.00	1	46935.00
86	678	1367	43228.00	1	43228.00
87	679	1368	25648.00	1	25648.00
88	680	1369	29262.00	1	29262.00
89	681	1370	17215.00	1	17215.00
90	682	1371	42053.00	1	42053.00
91	683	1372	49118.00	1	49118.00
92	684	1373	21232.00	1	21232.00
93	685	1374	48872.00	1	48872.00
94	686	1375	43134.00	1	43134.00
95	687	1376	44401.00	1	44401.00
96	688	1377	35322.00	1	35322.00
97	689	1378	20784.00	1	20784.00
98	690	1379	42366.00	1	42366.00
99	691	1380	42556.00	1	42556.00
100	692	1381	15995.00	1	15995.00
101	693	1382	31545.00	1	31545.00
102	694	1383	29079.00	1	29079.00
103	695	1384	25709.00	1	25709.00
104	696	1385	31416.00	1	31416.00
105	697	1386	32498.00	1	32498.00
106	698	1387	20992.00	1	20992.00
107	699	1388	31990.00	1	31990.00
108	700	1389	21037.00	1	21037.00
109	701	1390	37048.00	1	37048.00
110	702	1391	33340.00	1	33340.00
111	703	1392	45497.00	1	45497.00
112	704	1393	24791.00	1	24791.00
113	705	1394	38952.00	1	38952.00
114	706	1395	30550.00	1	30550.00
115	707	1396	35912.00	1	35912.00
116	708	1397	29853.00	1	29853.00
117	709	1398	20010.00	1	20010.00
118	710	1399	34098.00	1	34098.00
119	711	1400	28188.00	1	28188.00
120	712	1401	45305.00	1	45305.00
121	713	1402	19710.00	1	19710.00
122	714	1403	35741.00	1	35741.00
123	715	1404	39283.00	1	39283.00
124	716	1405	36705.00	1	36705.00
125	717	1406	11571.00	1	11571.00
126	718	1407	18451.00	1	18451.00
127	719	1408	32609.00	1	32609.00
128	720	1409	26077.00	1	26077.00
129	721	1410	39046.00	1	39046.00
130	722	1411	29038.00	1	29038.00
131	723	1412	31196.00	1	31196.00
132	724	1413	35316.00	1	35316.00
133	725	1414	29681.00	1	29681.00
134	726	1415	18430.00	1	18430.00
135	727	1416	46228.00	1	46228.00
136	728	1417	43666.00	1	43666.00
137	729	1418	47610.00	1	47610.00
138	730	1419	23900.00	1	23900.00
139	731	1420	16277.00	1	16277.00
140	732	1421	38772.00	1	38772.00
141	733	1422	39732.00	1	39732.00
142	734	1423	16013.00	1	16013.00
143	735	1424	14406.00	1	14406.00
144	736	1425	31182.00	1	31182.00
145	737	1426	49013.00	1	49013.00
146	738	1427	39750.00	1	39750.00
147	739	1428	18943.00	1	18943.00
148	740	1429	21256.00	1	21256.00
149	741	1430	48001.00	1	48001.00
150	742	1431	42491.00	1	42491.00
151	743	1432	40510.00	1	40510.00
152	744	1433	45473.00	1	45473.00
153	745	1434	26568.00	1	26568.00
154	746	1435	32769.00	1	32769.00
155	747	1436	37253.00	1	37253.00
156	748	1437	20098.00	1	20098.00
157	749	1438	31657.00	1	31657.00
158	750	1439	25239.00	1	25239.00
159	751	1440	22233.00	1	22233.00
160	752	1441	12775.00	1	12775.00
161	753	1442	13997.00	1	13997.00
162	754	1443	14681.00	1	14681.00
163	755	1444	49184.00	1	49184.00
164	756	1445	21452.00	1	21452.00
165	757	1446	49719.00	1	49719.00
166	758	1447	12826.00	1	12826.00
167	759	1448	39758.00	1	39758.00
168	760	1449	25402.00	1	25402.00
169	761	1450	22701.00	1	22701.00
170	762	1451	16144.00	1	16144.00
171	763	1452	16257.00	1	16257.00
172	764	1453	44572.00	1	44572.00
173	765	1454	36282.00	1	36282.00
174	766	1455	20280.00	1	20280.00
175	767	1456	49014.00	1	49014.00
176	768	1457	36581.00	1	36581.00
177	769	1458	17906.00	1	17906.00
178	770	1459	31578.00	1	31578.00
179	771	1460	35774.00	1	35774.00
180	772	1461	45973.00	1	45973.00
181	773	1462	18610.00	1	18610.00
182	774	1463	27808.00	1	27808.00
183	775	1464	45896.00	1	45896.00
184	776	1465	26923.00	1	26923.00
185	777	1466	48002.00	1	48002.00
186	778	1467	17430.00	1	17430.00
187	779	1468	46030.00	1	46030.00
188	780	1469	20430.00	1	20430.00
189	781	1470	20638.00	1	20638.00
190	782	1471	23746.00	1	23746.00
191	783	1472	17089.00	1	17089.00
192	784	1473	39078.00	1	39078.00
193	785	1474	12153.00	1	12153.00
194	786	1475	25231.00	1	25231.00
195	787	1476	15345.00	1	15345.00
196	788	1477	40583.00	1	40583.00
197	789	1478	29915.00	1	29915.00
198	790	1479	19627.00	1	19627.00
199	791	1480	33049.00	1	33049.00
200	792	1481	37132.00	1	37132.00
201	793	1482	39332.00	1	39332.00
202	794	1483	36119.00	1	36119.00
203	795	1484	30012.00	1	30012.00
204	796	1485	19785.00	1	19785.00
205	797	1486	28912.00	1	28912.00
206	798	1487	30497.00	1	30497.00
207	799	1488	33269.00	1	33269.00
208	800	1489	49001.00	1	49001.00
209	801	1490	30633.00	1	30633.00
210	802	1491	37638.00	1	37638.00
211	803	1492	21746.00	1	21746.00
212	804	1493	39441.00	1	39441.00
213	805	1494	35219.00	1	35219.00
214	806	1495	48868.00	1	48868.00
215	807	1496	19132.00	1	19132.00
216	808	1497	37470.00	1	37470.00
217	809	1498	38113.00	1	38113.00
218	810	1499	46393.00	1	46393.00
219	811	1500	14193.00	1	14193.00
220	812	1501	26576.00	1	26576.00
221	813	1502	19738.00	1	19738.00
222	814	1503	44753.00	1	44753.00
223	815	1504	26950.00	1	26950.00
224	816	1505	23398.00	1	23398.00
225	817	1506	20740.00	1	20740.00
226	818	1507	40221.00	1	40221.00
227	819	1508	27001.00	1	27001.00
228	820	1509	12820.00	1	12820.00
229	821	1510	41170.00	1	41170.00
230	822	1511	13014.00	1	13014.00
231	823	1512	11713.00	1	11713.00
232	824	1513	23756.00	1	23756.00
233	825	1514	14599.00	1	14599.00
234	826	1515	34817.00	1	34817.00
235	827	1516	30402.00	1	30402.00
236	828	1517	45806.00	1	45806.00
237	829	1518	44345.00	1	44345.00
238	830	1519	26372.00	1	26372.00
239	831	1520	31052.00	1	31052.00
240	832	1521	48385.00	1	48385.00
241	833	1522	12515.00	1	12515.00
242	834	1523	25432.00	1	25432.00
243	835	1524	33585.00	1	33585.00
244	836	1525	22705.00	1	22705.00
245	837	1526	40826.00	1	40826.00
246	838	1527	12004.00	1	12004.00
247	839	1528	26936.00	1	26936.00
248	840	1529	16682.00	1	16682.00
249	841	1530	12397.00	1	12397.00
250	842	1531	27784.00	1	27784.00
251	843	1532	39632.00	1	39632.00
252	844	1533	34656.00	1	34656.00
253	845	1534	38135.00	1	38135.00
254	846	1535	24881.00	1	24881.00
255	847	1536	10997.00	1	10997.00
256	848	1537	28671.00	1	28671.00
257	849	1538	36421.00	1	36421.00
258	850	1539	38333.00	1	38333.00
259	851	1540	38834.00	1	38834.00
260	852	1541	46656.00	1	46656.00
261	853	1542	33688.00	1	33688.00
262	854	1543	24018.00	1	24018.00
263	855	1544	33538.00	1	33538.00
264	856	1545	47241.00	1	47241.00
265	857	1546	18810.00	1	18810.00
266	858	1547	30744.00	1	30744.00
267	859	1548	19567.00	1	19567.00
268	860	1549	31414.00	1	31414.00
269	861	1550	16693.00	1	16693.00
270	862	1551	31965.00	1	31965.00
271	863	1552	40841.00	1	40841.00
272	864	1553	13909.00	1	13909.00
273	865	1554	30979.00	1	30979.00
55	866	1555	38380.00	1	38380.00
56	867	1556	20305.00	1	20305.00
57	868	1557	13677.00	1	13677.00
58	869	1558	37671.00	1	37671.00
59	870	1559	15598.00	1	15598.00
60	871	1560	29837.00	1	29837.00
61	872	1561	28467.00	1	28467.00
62	873	1562	48344.00	1	48344.00
63	874	1563	48656.00	1	48656.00
64	875	1564	43351.00	1	43351.00
65	876	1565	33278.00	1	33278.00
66	877	1566	34788.00	1	34788.00
67	878	1567	31644.00	1	31644.00
68	879	1568	14904.00	1	14904.00
69	880	1569	34898.00	1	34898.00
70	881	1570	11840.00	1	11840.00
71	882	1571	46666.00	1	46666.00
72	883	1572	44162.00	1	44162.00
73	884	1573	11419.00	1	11419.00
74	885	1574	34780.00	1	34780.00
75	886	1575	48488.00	1	48488.00
76	887	1576	12719.00	1	12719.00
77	888	1577	28336.00	1	28336.00
78	889	1578	32499.00	1	32499.00
79	890	1579	16132.00	1	16132.00
80	891	1580	43899.00	1	43899.00
81	892	1581	41236.00	1	41236.00
82	893	1582	37375.00	1	37375.00
83	894	1583	19560.00	1	19560.00
84	895	1584	44124.00	1	44124.00
85	896	1585	46935.00	1	46935.00
86	897	1586	43228.00	1	43228.00
87	898	1587	25648.00	1	25648.00
88	899	1588	29262.00	1	29262.00
89	900	1589	17215.00	1	17215.00
90	901	1590	42053.00	1	42053.00
91	902	1591	49118.00	1	49118.00
92	903	1592	21232.00	1	21232.00
93	904	1593	48872.00	1	48872.00
94	905	1594	43134.00	1	43134.00
95	906	1595	44401.00	1	44401.00
96	907	1596	35322.00	1	35322.00
97	908	1597	20784.00	1	20784.00
98	909	1598	42366.00	1	42366.00
99	910	1599	42556.00	1	42556.00
100	911	1600	15995.00	1	15995.00
101	912	1601	31545.00	1	31545.00
102	913	1602	29079.00	1	29079.00
103	914	1603	25709.00	1	25709.00
104	915	1604	31416.00	1	31416.00
105	916	1605	32498.00	1	32498.00
106	917	1606	20992.00	1	20992.00
107	918	1607	31990.00	1	31990.00
108	919	1608	21037.00	1	21037.00
109	920	1609	37048.00	1	37048.00
110	921	1610	33340.00	1	33340.00
111	922	1611	45497.00	1	45497.00
112	923	1612	24791.00	1	24791.00
113	924	1613	38952.00	1	38952.00
114	925	1614	30550.00	1	30550.00
115	926	1615	35912.00	1	35912.00
116	927	1616	29853.00	1	29853.00
117	928	1617	20010.00	1	20010.00
118	929	1618	34098.00	1	34098.00
119	930	1619	28188.00	1	28188.00
120	931	1620	45305.00	1	45305.00
121	932	1621	19710.00	1	19710.00
122	933	1622	35741.00	1	35741.00
123	934	1623	39283.00	1	39283.00
124	935	1624	36705.00	1	36705.00
125	936	1625	11571.00	1	11571.00
126	937	1626	18451.00	1	18451.00
127	938	1627	32609.00	1	32609.00
128	939	1628	26077.00	1	26077.00
129	940	1629	39046.00	1	39046.00
130	941	1630	29038.00	1	29038.00
131	942	1631	31196.00	1	31196.00
132	943	1632	35316.00	1	35316.00
133	944	1633	29681.00	1	29681.00
134	945	1634	18430.00	1	18430.00
135	946	1635	46228.00	1	46228.00
136	947	1636	43666.00	1	43666.00
137	948	1637	47610.00	1	47610.00
138	949	1638	23900.00	1	23900.00
139	950	1639	16277.00	1	16277.00
140	951	1640	38772.00	1	38772.00
141	952	1641	39732.00	1	39732.00
142	953	1642	16013.00	1	16013.00
984	954	1643	26062.00	1	26062.00
985	955	1644	11432.00	1	11432.00
986	956	1645	17671.00	1	17671.00
987	957	1646	18315.00	1	18315.00
988	958	1647	37769.00	1	37769.00
989	959	1648	26420.00	1	26420.00
990	960	1649	38692.00	1	38692.00
991	961	1650	11781.00	1	11781.00
992	962	1651	40644.00	1	40644.00
993	963	1652	17002.00	1	17002.00
994	964	1653	40497.00	1	40497.00
995	965	1654	48323.00	1	48323.00
996	966	1655	42572.00	1	42572.00
997	967	1656	17732.00	1	17732.00
998	968	1657	46393.00	1	46393.00
999	969	1658	29953.00	1	29953.00
1000	970	1659	25968.00	1	25968.00
4	971	1660	14171.00	1	14171.00
5	972	1661	38938.00	1	38938.00
6	973	1662	19010.00	1	19010.00
7	974	1663	23107.00	1	23107.00
8	975	1664	19004.00	1	19004.00
9	976	1665	46299.00	1	46299.00
10	977	1666	21261.00	1	21261.00
11	978	1667	27492.00	1	27492.00
12	979	1668	44284.00	1	44284.00
13	980	1669	48425.00	1	48425.00
100	981	1670	15995.00	1	15995.00
101	982	1671	31545.00	1	31545.00
102	983	1672	29079.00	1	29079.00
103	984	1673	25709.00	1	25709.00
104	985	1674	31416.00	1	31416.00
105	986	1675	32498.00	1	32498.00
301	988	1677	28871.00	12	346452.00
302	989	1678	25568.00	5	127840.00
303	990	1679	49854.00	12	598248.00
304	991	1680	25245.00	9	227205.00
305	992	1681	38942.00	15	584130.00
112	993	1682	24791.00	14	347074.00
26	994	1683	49896.00	2	99792.00
27	995	1684	10157.00	6	60942.00
28	996	1685	11140.00	7	77980.00
29	997	1686	44374.00	9	399366.00
30	998	1687	16375.00	14	229250.00
31	999	1688	48143.00	1	48143.00
32	1000	1689	24293.00	11	267223.00
\.


                                                                                                                                                                                                                                                                                                     4947.dat                                                                                            0000600 0004000 0002000 00000000323 15015342721 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        RC	REGISTRO CIVIL
TI	TARJETA DE IDENTIDAD
CC	CEDULA DE CIUDADANIA
CE	CEDULA DE EXTRANJERIA
PP	PASAPORTE
NIT	NUMERO DE IDENTIFICACION TRIBUTARIA
TE	TARJETA DE EXTRANJERIA
PEP	PERMISO ESPECIAL DE PERMANENCIA
\.


                                                                                                                                                                                                                                                                                                             4952.dat                                                                                            0000600 0004000 0002000 00000000077 15015342721 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        H001	HOTEL SUEÑO REAL	3118360951	sueñoreal@gmail.com	27
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                 4946.dat                                                                                            0000600 0004000 0002000 00000106053 15015342721 0014265 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        P001	MEDICO	PROFESIONAL DE LA SALUD DEDICADO AL DIAGNOSTICO Y TRATAMIENTO DE ENFERMEDADES
P002	INGENIERO	PROFESIONAL TECNICO ESPECIALIZADO EN DISENO Y CONSTRUCCION
P003	ABOGADO	PROFESIONAL DEL DERECHO ESPECIALIZADO EN ASESORIA LEGAL
P004	CONTADOR	PROFESIONAL ESPECIALIZADO EN CONTABILIDAD Y FINANZAS
P005	ARQUITECTO	PROFESIONAL DEL DISENO Y CONSTRUCCION DE EDIFICACIONES
P006	ENFERMERO	PROFESIONAL DE LA SALUD ESPECIALIZADO EN CUIDADOS MEDICOS
P007	PSICOLOGO	PROFESIONAL ESPECIALIZADO EN SALUD MENTAL Y COMPORTAMIENTO
P008	VETERINARIO	PROFESIONAL DE LA SALUD ANIMAL
P009	ODONTOLOGO	PROFESIONAL ESPECIALIZADO EN SALUD ORAL Y DENTAL
P010	FARMACEUTA	PROFESIONAL ESPECIALIZADO EN MEDICAMENTOS Y FARMACOLOGIA
P011	PROFESOR	EDUCADOR PROFESIONAL EN INSTITUCIONES ACADEMICAS
P012	ECONOMISTA	PROFESIONAL ESPECIALIZADO EN ANALISIS ECONOMICO
P013	ADMINISTRADOR	PROFESIONAL EN GESTION Y ADMINISTRACION EMPRESARIAL
P014	NUTRICIONISTA	PROFESIONAL ESPECIALIZADO EN ALIMENTACION Y NUTRICION
P015	FISIOTERAPEUTA	PROFESIONAL EN REHABILITACION FISICA Y TERAPIA
P016	PERIODISTA	PROFESIONAL DE LA COMUNICACION Y MEDIOS INFORMATIVOS
P017	DISENADOR	PROFESIONAL CREATIVO ESPECIALIZADO EN DISENO VISUAL
P018	PROGRAMADOR	PROFESIONAL ESPECIALIZADO EN DESARROLLO DE SOFTWARE
P019	MECANICO	TECNICO ESPECIALIZADO EN REPARACION DE VEHICULOS
P020	ELECTRICISTA	TECNICO ESPECIALIZADO EN INSTALACIONES ELECTRICAS
P021	PLOMERO	TECNICO ESPECIALIZADO EN INSTALACIONES HIDRAULICAS
P022	CARPINTERO	ARTESANO ESPECIALIZADO EN TRABAJO CON MADERA
P023	ALBANIL	TRABAJADOR ESPECIALIZADO EN CONSTRUCCION
P024	CHEF	PROFESIONAL CULINARIO ESPECIALIZADO EN GASTRONOMIA
P025	MESERO	PROFESIONAL DEL SERVICIO GASTRONOMICO
P026	RECEPCIONISTA	PROFESIONAL DE ATENCION AL CLIENTE
P027	CONDUCTOR	PROFESIONAL DEL TRANSPORTE DE PERSONAS O MERCANCIAS
P028	VIGILANTE	PROFESIONAL DE SEGURIDAD PRIVADA
P029	AGRICULTOR	PROFESIONAL DEL SECTOR AGROPECUARIO
P030	GANADERO	PROFESIONAL ESPECIALIZADO EN CRIANZA DE GANADO
P031	COMERCIANTE	PROFESIONAL DEDICADO AL COMERCIO Y VENTAS
P032	VENDEDOR	PROFESIONAL ESPECIALIZADO EN VENTAS DIRECTAS
P033	CONSULTOR	PROFESIONAL ESPECIALIZADO EN ASESORIAS EMPRESARIALES
P034	GERENTE	PROFESIONAL EJECUTIVO EN ADMINISTRACION
P035	DIRECTOR	PROFESIONAL DE ALTO NIVEL DIRECTIVO
P036	SECRETARIO	PROFESIONAL DE APOYO ADMINISTRATIVO
P037	AUXILIAR	PROFESIONAL DE APOYO EN DIVERSAS AREAS
P038	TECNICO	PROFESIONAL ESPECIALIZADO EN AREAS TECNICAS
P039	OPERARIO	TRABAJADOR ESPECIALIZADO EN OPERACIONES INDUSTRIALES
P040	SUPERVISOR	PROFESIONAL ENCARGADO DE SUPERVISION DE EQUIPOS
P041	COORDINADOR	PROFESIONAL ENCARGADO DE COORDINACION DE ACTIVIDADES
P042	ANALISTA	PROFESIONAL ESPECIALIZADO EN ANALISIS DE DATOS
P043	INVESTIGADOR	PROFESIONAL DEDICADO A LA INVESTIGACION CIENTIFICA
P044	CIENTIFICO	PROFESIONAL ESPECIALIZADO EN CIENCIAS EXACTAS
P045	BIOLOGO	PROFESIONAL ESPECIALIZADO EN CIENCIAS BIOLOGICAS
P046	QUIMICO	PROFESIONAL ESPECIALIZADO EN QUIMICA
P047	FISICO	PROFESIONAL ESPECIALIZADO EN FISICA
P048	MATEMATICO	PROFESIONAL ESPECIALIZADO EN MATEMATICAS
P049	ESTADISTICO	PROFESIONAL ESPECIALIZADO EN ESTADISTICA
P050	ARTISTA	PROFESIONAL CREATIVO EN ARTES VISUALES O ESCENICAS
P051	PILOTO	PROFESIONAL ESPECIALIZADO EN OPERACION DE AERONAVES
P052	AZAFATA	PROFESIONAL DEL SERVICIO DE CABINA EN AERONAVES
P053	MARINERO	PROFESIONAL DE LA NAVEGACION MARITIMA
P054	SOLDADOR	TECNICO ESPECIALIZADO EN UNION DE METALES
P055	TORNERO	TECNICO ESPECIALIZADO EN MECANIZADO DE PIEZAS
P056	PANADERO	ARTESANO ESPECIALIZADO EN ELABORACION DE PAN
P057	PASTELERO	ARTESANO ESPECIALIZADO EN REPOSTERIA Y PASTELERIA
P058	BARBERO	PROFESIONAL ESPECIALIZADO EN CORTE Y ARREGLO CAPILAR
P059	ESTILISTA	PROFESIONAL ESPECIALIZADO EN BELLEZA Y PELUQUERIA
P060	MASAJISTA	PROFESIONAL ESPECIALIZADO EN TERAPIAS DE MASAJE
P061	ENTRENADOR	PROFESIONAL ESPECIALIZADO EN PREPARACION FISICA
P062	ARBITRO	PROFESIONAL ESPECIALIZADO EN DIRECCION DEPORTIVA
P063	LOCUTOR	PROFESIONAL DE LA COMUNICACION RADIOFONICA
P064	ACTOR	ARTISTA PROFESIONAL DE LAS ARTES ESCENICAS
P065	MUSICO	ARTISTA PROFESIONAL DE LA MUSICA
P066	BAILARIN	ARTISTA PROFESIONAL DE LA DANZA
P067	FOTOGRAFO	PROFESIONAL ESPECIALIZADO EN FOTOGRAFIA
P068	CAMAROGRAFO	PROFESIONAL ESPECIALIZADO EN GRABACION AUDIOVISUAL
P069	EDITOR	PROFESIONAL ESPECIALIZADO EN EDICION DE CONTENIDOS
P070	TRADUCTOR	PROFESIONAL ESPECIALIZADO EN TRADUCCION DE IDIOMAS
P071	INTERPRETE	PROFESIONAL ESPECIALIZADO EN INTERPRETACION ORAL
P072	BIBLIOTECARIO	PROFESIONAL ESPECIALIZADO EN GESTION DE BIBLIOTECAS
P073	ARCHIVISTA	PROFESIONAL ESPECIALIZADO EN GESTION DOCUMENTAL
P074	MUSEOLOGO	PROFESIONAL ESPECIALIZADO EN GESTION DE MUSEOS
P075	ANTROPOLOGO	PROFESIONAL ESPECIALIZADO EN ESTUDIO DE CULTURAS
P076	SOCIOLOGO	PROFESIONAL ESPECIALIZADO EN ESTUDIO DE SOCIEDADES
P077	HISTORIADOR	PROFESIONAL ESPECIALIZADO EN INVESTIGACION HISTORICA
P078	GEOGRAFO	PROFESIONAL ESPECIALIZADO EN ESTUDIOS GEOGRAFICOS
P079	METEOROLOGO	PROFESIONAL ESPECIALIZADO EN CIENCIAS ATMOSFERICAS
P080	GEOLOGO	PROFESIONAL ESPECIALIZADO EN CIENCIAS DE LA TIERRA
P081	TOPOGRAFO	PROFESIONAL ESPECIALIZADO EN MEDICION DE TERRENOS
P082	AGRIMENSOR	PROFESIONAL ESPECIALIZADO EN DELIMITACION DE TIERRAS
P083	FORESTAL	PROFESIONAL ESPECIALIZADO EN MANEJO DE BOSQUES
P084	MINERO	PROFESIONAL ESPECIALIZADO EN EXTRACCION MINERA
P085	PETROLERO	PROFESIONAL ESPECIALIZADO EN INDUSTRIA PETROLERA
P086	QUIMICO INDUSTRIAL	PROFESIONAL ESPECIALIZADO EN PROCESOS QUIMICOS INDUSTRIALES
P087	TEXTILERO	PROFESIONAL ESPECIALIZADO EN INDUSTRIA TEXTIL
P088	CERAMISTA	ARTESANO ESPECIALIZADO EN TRABAJO CON CERAMICA
P089	JOYERO	ARTESANO ESPECIALIZADO EN ELABORACION DE JOYAS
P090	RELOJERO	TECNICO ESPECIALIZADO EN REPARACION DE RELOJES
P091	OPTICO	PROFESIONAL ESPECIALIZADO EN OPTICA Y LENTES
P092	PODOLOGO	PROFESIONAL ESPECIALIZADO EN CUIDADO DE PIES
P093	QUIROPRACTICO	PROFESIONAL ESPECIALIZADO EN TERAPIA QUIROPRACTICA
P094	ACUPUNTURISTA	PROFESIONAL ESPECIALIZADO EN MEDICINA ALTERNATIVA
P095	HOMEOPATA	PROFESIONAL ESPECIALIZADO EN MEDICINA HOMEOPATICA
P096	NATUROPATA	PROFESIONAL ESPECIALIZADO EN MEDICINA NATURAL
P097	RADIOLOGO	PROFESIONAL ESPECIALIZADO EN DIAGNOSTICO POR IMAGENES
P098	ANESTESIOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ANESTESIA
P099	CIRUJANO	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA
P100	PEDIATRA	PROFESIONAL MEDICO ESPECIALIZADO EN SALUD INFANTIL
P101	SOMMELIER	PROFESIONAL ESPECIALIZADO EN VINOS Y MARIDAJES
P102	BARISTA	PROFESIONAL ESPECIALIZADO EN PREPARACION DE CAFE
P103	BARTENDER	PROFESIONAL ESPECIALIZADO EN PREPARACION DE COCTELES
P104	CRUPIER	PROFESIONAL ESPECIALIZADO EN JUEGOS DE CASINO
P105	GUIA TURISTICO	PROFESIONAL ESPECIALIZADO EN SERVICIOS TURISTICOS
P106	AZAFATA DE TIERRA	PROFESIONAL DE SERVICIOS AEROPORTUARIOS
P107	CONTROLADOR AEREO	PROFESIONAL ESPECIALIZADO EN CONTROL DE TRAFICO AEREO
P108	DESPACHADOR	PROFESIONAL ESPECIALIZADO EN LOGISTICA Y ENVIOS
P109	ESTIBADOR	TRABAJADOR ESPECIALIZADO EN CARGA PORTUARIA
P110	MAQUINISTA	PROFESIONAL ESPECIALIZADO EN OPERACION DE TRENES
P111	TAXISTA	PROFESIONAL DEL TRANSPORTE URBANO
P112	REPARTIDOR	PROFESIONAL ESPECIALIZADO EN DISTRIBUCION Y ENTREGA
P113	CONSERJE	PROFESIONAL DE MANTENIMIENTO Y SERVICIOS GENERALES
P114	JARDINERO	PROFESIONAL ESPECIALIZADO EN CUIDADO DE JARDINES
P115	FLORISTERIA	PROFESIONAL ESPECIALIZADO EN ARREGLOS FLORALES
P116	PAISAJISTA	PROFESIONAL ESPECIALIZADO EN DISENO DE PAISAJES
P117	FUMIGADOR	TECNICO ESPECIALIZADO EN CONTROL DE PLAGAS
P118	CERRAJERO	TECNICO ESPECIALIZADO EN CERRADURAS Y SEGURIDAD
P119	TAPICERO	ARTESANO ESPECIALIZADO EN TAPICERIA Y MUEBLES
P120	VIDRIERO	TECNICO ESPECIALIZADO EN TRABAJO CON VIDRIO
P121	HERRERO	ARTESANO ESPECIALIZADO EN TRABAJO CON HIERRO
P122	ORFEBRE	ARTESANO ESPECIALIZADO EN METALES PRECIOSOS
P123	LUTIER	ARTESANO ESPECIALIZADO EN INSTRUMENTOS MUSICALES
P124	ENCUADERNADOR	ARTESANO ESPECIALIZADO EN ENCUADERNACION
P125	IMPRESOR	TECNICO ESPECIALIZADO EN ARTES GRAFICAS
P126	SERIGRAFISTA	TECNICO ESPECIALIZADO EN SERIGRAFIA
P127	GRABADOR	ARTESANO ESPECIALIZADO EN GRABADO ARTISTICO
P128	ESCULTOR	ARTISTA ESPECIALIZADO EN ESCULTURA
P129	PINTOR ARTISTICO	ARTISTA ESPECIALIZADO EN PINTURA
P130	ILUSTRADOR	PROFESIONAL ESPECIALIZADO EN ILUSTRACION GRAFICA
P131	ANIMADOR	PROFESIONAL ESPECIALIZADO EN ANIMACION DIGITAL
P132	MODELADOR 3D	PROFESIONAL ESPECIALIZADO EN MODELADO TRIDIMENSIONAL
P133	DESARROLLADOR WEB	PROFESIONAL ESPECIALIZADO EN DESARROLLO WEB
P134	ADMINISTRADOR DE SISTEMAS	PROFESIONAL ESPECIALIZADO EN SISTEMAS INFORMATICOS
P135	ESPECIALISTA EN CIBERSEGURIDAD	PROFESIONAL ESPECIALIZADO EN SEGURIDAD INFORMATICA
P136	ANALISTA DE DATOS	PROFESIONAL ESPECIALIZADO EN ANALISIS DE BIG DATA
P137	TESTER DE SOFTWARE	PROFESIONAL ESPECIALIZADO EN PRUEBAS DE SOFTWARE
P138	COMMUNITY MANAGER	PROFESIONAL ESPECIALIZADO EN REDES SOCIALES
P139	INFLUENCER	PROFESIONAL DE MARKETING DIGITAL Y CONTENIDOS
P140	STREAMER	PROFESIONAL DE ENTRETENIMIENTO EN PLATAFORMAS DIGITALES
P141	EDITOR DE VIDEO	PROFESIONAL ESPECIALIZADO EN POSTPRODUCCION AUDIOVISUAL
P142	DISENADOR UX/UI	PROFESIONAL ESPECIALIZADO EN EXPERIENCIA DE USUARIO
P143	PRODUCTOR MUSICAL	PROFESIONAL ESPECIALIZADO EN PRODUCCION MUSICAL
P144	INGENIERO DE SONIDO	PROFESIONAL ESPECIALIZADO EN AUDIO PROFESIONAL
P145	DOBLAJISTA	PROFESIONAL ESPECIALIZADO EN DOBLAJE DE VOZ
P146	PRESENTADOR	PROFESIONAL DE LA COMUNICACION TELEVISIVA
P147	COMENTARISTA DEPORTIVO	PROFESIONAL ESPECIALIZADO EN NARRACION DEPORTIVA
P148	CRITICO GASTRONOMICO	PROFESIONAL ESPECIALIZADO EN CRITICA CULINARIA
P149	SOMMELIER DE TE	PROFESIONAL ESPECIALIZADO EN CULTURA DEL TE
P150	ESPECIALISTA EN PROTOCOLO	PROFESIONAL ESPECIALIZADO EN ETIQUETA Y CEREMONIAL
P151	DETECTIVE PRIVADO	PROFESIONAL ESPECIALIZADO EN INVESTIGACIONES PRIVADAS
P152	INVESTIGADOR FORENSE	PROFESIONAL ESPECIALIZADO EN CRIMINALISTICA
P153	PERITO JUDICIAL	PROFESIONAL ESPECIALIZADO EN PERITAJES LEGALES
P154	NOTARIO	PROFESIONAL DEL DERECHO ESPECIALIZADO EN FE PUBLICA
P155	ESCRIBANO	PROFESIONAL ESPECIALIZADO EN DOCUMENTACION LEGAL
P156	PROCURADOR	PROFESIONAL AUXILIAR DE LA JUSTICIA
P157	MEDIADOR	PROFESIONAL ESPECIALIZADO EN RESOLUCION DE CONFLICTOS
P158	ARBITRO LEGAL	PROFESIONAL ESPECIALIZADO EN ARBITRAJE COMERCIAL
P159	CORREDOR DE BOLSA	PROFESIONAL ESPECIALIZADO EN MERCADOS FINANCIEROS
P160	AGENTE DE SEGUROS	PROFESIONAL ESPECIALIZADO EN SEGUROS Y RIESGOS
P161	VALUADOR	PROFESIONAL ESPECIALIZADO EN TASACION DE BIENES
P162	MARTILLERO	PROFESIONAL ESPECIALIZADO EN SUBASTAS Y REMATES
P163	INMOBILIARIO	PROFESIONAL ESPECIALIZADO EN BIENES RAICES
P164	ADMINISTRADOR DE CONSORCIOS	PROFESIONAL ESPECIALIZADO EN ADMINISTRACION EDILICIA
P165	GESTOR AMBIENTAL	PROFESIONAL ESPECIALIZADO EN MEDIO AMBIENTE
P166	ESPECIALISTA EN RECURSOS HUMANOS	PROFESIONAL ESPECIALIZADO EN GESTION DE PERSONAL
P167	HEADHUNTER	PROFESIONAL ESPECIALIZADO EN BUSQUEDA DE EJECUTIVOS
P168	COACH EJECUTIVO	PROFESIONAL ESPECIALIZADO EN DESARROLLO EMPRESARIAL
P169	CONSULTOR EN CALIDAD	PROFESIONAL ESPECIALIZADO EN SISTEMAS DE CALIDAD
P170	AUDITOR	PROFESIONAL ESPECIALIZADO EN AUDITORIAS EMPRESARIALES
P171	ESPECIALISTA EN COMPLIANCE	PROFESIONAL ESPECIALIZADO EN CUMPLIMIENTO NORMATIVO
P172	RISK MANAGER	PROFESIONAL ESPECIALIZADO EN GESTION DE RIESGOS
P173	BUSINESS ANALYST	PROFESIONAL ESPECIALIZADO EN ANALISIS DE NEGOCIOS
P174	PRODUCT MANAGER	PROFESIONAL ESPECIALIZADO EN GESTION DE PRODUCTOS
P175	PROJECT MANAGER	PROFESIONAL ESPECIALIZADO EN GESTION DE PROYECTOS
P176	SCRUM MASTER	PROFESIONAL ESPECIALIZADO EN METODOLOGIAS AGILES
P177	DEVOPS ENGINEER	PROFESIONAL ESPECIALIZADO EN DESARROLLO Y OPERACIONES
P178	DATA SCIENTIST	PROFESIONAL ESPECIALIZADO EN CIENCIA DE DATOS
P179	MACHINE LEARNING ENGINEER	PROFESIONAL ESPECIALIZADO EN APRENDIZAJE AUTOMATICO
P180	BLOCKCHAIN DEVELOPER	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA BLOCKCHAIN
P181	ESPECIALISTA EN IOT	PROFESIONAL ESPECIALIZADO EN INTERNET DE LAS COSAS
P182	ESPECIALISTA EN IA	PROFESIONAL ESPECIALIZADO EN INTELIGENCIA ARTIFICIAL
P183	ROBOTICISTA	PROFESIONAL ESPECIALIZADO EN ROBOTICA
P184	INGENIERO BIOMEDICO	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA MEDICA
P185	GENETISTA	PROFESIONAL ESPECIALIZADO EN GENETICA
P186	BIOTECNOLOGO	PROFESIONAL ESPECIALIZADO EN BIOTECNOLOGIA
P187	NANOTECNOLOGO	PROFESIONAL ESPECIALIZADO EN NANOTECNOLOGIA
P188	ASTROFISICO	PROFESIONAL ESPECIALIZADO EN ASTROFISICA
P189	COSMOLOGO	PROFESIONAL ESPECIALIZADO EN COSMOLOGIA
P190	PALEONTOLOGO	PROFESIONAL ESPECIALIZADO EN PALEONTOLOGIA
P191	ARQUEOLOGO	PROFESIONAL ESPECIALIZADO EN ARQUEOLOGIA
P192	RESTAURADOR	PROFESIONAL ESPECIALIZADO EN RESTAURACION DE OBRAS
P193	CONSERVADOR DE MUSEOS	PROFESIONAL ESPECIALIZADO EN CONSERVACION PATRIMONIAL
P194	CURADOR DE ARTE	PROFESIONAL ESPECIALIZADO EN CURADURIA ARTISTICA
P195	GALERISTA	PROFESIONAL ESPECIALIZADO EN GALERIAS DE ARTE
P196	SUBASTADOR DE ARTE	PROFESIONAL ESPECIALIZADO EN SUBASTAS ARTISTICAS
P197	TASADOR DE ARTE	PROFESIONAL ESPECIALIZADO EN VALUACION ARTISTICA
P198	COLECCIONISTA	PROFESIONAL ESPECIALIZADO EN COLECCIONISMO
P199	ANTICUARIO	PROFESIONAL ESPECIALIZADO EN ANTIGUEDADES
P200	GEMOLOGO	PROFESIONAL ESPECIALIZADO EN PIEDRAS PRECIOSAS
P201	RELOJERO DE LUJO	ESPECIALISTA EN RELOJERIA DE ALTA GAMA
P202	SOMMELIER DE PUROS	PROFESIONAL ESPECIALIZADO EN CULTURA DEL TABACO
P203	CATADOR DE CAFE	PROFESIONAL ESPECIALIZADO EN EVALUACION DE CAFE
P204	CATADOR DE CACAO	PROFESIONAL ESPECIALIZADO EN EVALUACION DE CACAO
P205	MAESTRO CERVECERO	PROFESIONAL ESPECIALIZADO EN ELABORACION DE CERVEZA
P206	DESTILADOR	PROFESIONAL ESPECIALIZADO EN DESTILACION DE LICORES
P207	ENOLOGO	PROFESIONAL ESPECIALIZADO EN ELABORACION DE VINOS
P208	QUESERO	ARTESANO ESPECIALIZADO EN ELABORACION DE QUESOS
P209	CHARCUTERO	ARTESANO ESPECIALIZADO EN EMBUTIDOS Y CONSERVAS
P210	APICULTOR	PROFESIONAL ESPECIALIZADO EN CRIANZA DE ABEJAS
P211	AVICULTOR	PROFESIONAL ESPECIALIZADO EN CRIANZA DE AVES
P212	PISCICULTOR	PROFESIONAL ESPECIALIZADO EN CRIANZA DE PECES
P213	CUNICULTOR	PROFESIONAL ESPECIALIZADO EN CRIANZA DE CONEJOS
P214	EQUINOTERAPEUTA	PROFESIONAL ESPECIALIZADO EN TERAPIA CON CABALLOS
P215	ADIESTRADOR CANINO	PROFESIONAL ESPECIALIZADO EN ENTRENAMIENTO DE PERROS
P216	ETOLOGO	PROFESIONAL ESPECIALIZADO EN COMPORTAMIENTO ANIMAL
P217	ZOOLOGO	PROFESIONAL ESPECIALIZADO EN ZOOLOGIA
P218	ORNITOLOGO	PROFESIONAL ESPECIALIZADO EN AVES
P219	ENTOMOLOGO	PROFESIONAL ESPECIALIZADO EN INSECTOS
P220	HERPETOLOGO	PROFESIONAL ESPECIALIZADO EN REPTILES Y ANFIBIOS
P221	ICTIOLOGIA	PROFESIONAL ESPECIALIZADO EN PECES
P222	BOTANICO	PROFESIONAL ESPECIALIZADO EN BOTANICA
P223	MICOLOGO	PROFESIONAL ESPECIALIZADO EN HONGOS
P224	FITOPATOLOGO	PROFESIONAL ESPECIALIZADO EN ENFERMEDADES DE PLANTAS
P225	AGRONOMO	PROFESIONAL ESPECIALIZADO EN CIENCIAS AGRICOLAS
P226	ZOOTECNISTA	PROFESIONAL ESPECIALIZADO EN PRODUCCION ANIMAL
P227	INGENIERO FORESTAL	PROFESIONAL ESPECIALIZADO EN MANEJO FORESTAL
P228	OCEANOGRAFO	PROFESIONAL ESPECIALIZADO EN CIENCIAS MARINAS
P229	LIMNOLOGO	PROFESIONAL ESPECIALIZADO EN AGUAS CONTINENTALES
P230	HIDROLOGO	PROFESIONAL ESPECIALIZADO EN RECURSOS HIDRICOS
P231	SISMOLOGO	PROFESIONAL ESPECIALIZADO EN SISMOLOGIA
P232	VULCANOLOGO	PROFESIONAL ESPECIALIZADO EN VULCANOLOGIA
P233	CLIMATOLOGO	PROFESIONAL ESPECIALIZADO EN CLIMATOLOGIA
P234	GLACIOLOGO	PROFESIONAL ESPECIALIZADO EN GLACIARES
P235	CARTOGRAFO	PROFESIONAL ESPECIALIZADO EN CARTOGRAFIA
P236	ESPECIALISTA EN SIG	PROFESIONAL ESPECIALIZADO EN SISTEMAS DE INFORMACION GEOGRAFICA
P237	URBANISTA	PROFESIONAL ESPECIALIZADO EN PLANIFICACION URBANA
P238	ESPECIALISTA EN SMART CITIES	PROFESIONAL ESPECIALIZADO EN CIUDADES INTELIGENTES
P239	CONSULTOR EN SOSTENIBILIDAD	PROFESIONAL ESPECIALIZADO EN DESARROLLO SOSTENIBLE
P240	ESPECIALISTA EN ENERGIAS RENOVABLES	PROFESIONAL ESPECIALIZADO EN ENERGIAS LIMPIAS
P241	INGENIERO NUCLEAR	PROFESIONAL ESPECIALIZADO EN ENERGIA NUCLEAR
P242	ESPECIALISTA EN EFICIENCIA ENERGETICA	PROFESIONAL ESPECIALIZADO EN OPTIMIZACION ENERGETICA
P243	CONSULTOR EN MOVILIDAD	PROFESIONAL ESPECIALIZADO EN SISTEMAS DE TRANSPORTE
P244	ESPECIALISTA EN LOGISTICA	PROFESIONAL ESPECIALIZADO EN CADENAS DE SUMINISTRO
P245	PLANIFICADOR DE TRANSPORTE	PROFESIONAL ESPECIALIZADO EN PLANIFICACION DE MOVILIDAD
P246	ESPECIALISTA EN E-COMMERCE	PROFESIONAL ESPECIALIZADO EN COMERCIO ELECTRONICO
P247	GROWTH HACKER	PROFESIONAL ESPECIALIZADO EN CRECIMIENTO DIGITAL
P248	SEO SPECIALIST	PROFESIONAL ESPECIALIZADO EN OPTIMIZACION WEB
P249	SEM SPECIALIST	PROFESIONAL ESPECIALIZADO EN MARKETING EN BUSCADORES
P250	ESPECIALISTA EN REALIDAD VIRTUAL	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA VR
P251	ESPECIALISTA EN REALIDAD AUMENTADA	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA AR
P252	DRONE PILOT	PROFESIONAL ESPECIALIZADO EN OPERACION DE DRONES
P253	INGENIERO AEROESPACIAL	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA AEROESPACIAL
P254	INGENIERO MECATRONICO	PROFESIONAL ESPECIALIZADO EN MECATRONICA
P255	INGENIERO EN AUTOMATIZACION	PROFESIONAL ESPECIALIZADO EN AUTOMATIZACION INDUSTRIAL
P256	TECNICO EN REFRIGERACION	PROFESIONAL ESPECIALIZADO EN SISTEMAS DE REFRIGERACION
P257	TECNICO EN CLIMATIZACION	PROFESIONAL ESPECIALIZADO EN SISTEMAS HVAC
P258	INSTALADOR DE PANELES SOLARES	TECNICO ESPECIALIZADO EN ENERGIA SOLAR
P259	TECNICO EN TURBINAS EOLICAS	PROFESIONAL ESPECIALIZADO EN ENERGIA EOLICA
P260	OPERADOR DE PLANTA	PROFESIONAL ESPECIALIZADO EN OPERACIONES INDUSTRIALES
P261	CONTROLISTA DE CALIDAD	PROFESIONAL ESPECIALIZADO EN CONTROL DE CALIDAD
P262	TECNICO EN METROLOGIA	PROFESIONAL ESPECIALIZADO EN MEDICIONES PRECISAS
P263	CALIBRADOR DE INSTRUMENTOS	TECNICO ESPECIALIZADO EN CALIBRACION
P264	TECNICO EN FIBRA OPTICA	PROFESIONAL ESPECIALIZADO EN TELECOMUNICACIONES
P265	TECNICO 5G	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA 5G
P266	ESPECIALISTA EN SATELITES	PROFESIONAL ESPECIALIZADO EN COMUNICACIONES SATELITALES
P267	RADIOAFICIONADO	PROFESIONAL ESPECIALIZADO EN RADIOCOMUNICACIONES
P268	TECNICO EN BROADCAST	PROFESIONAL ESPECIALIZADO EN TRANSMISIONES
P269	OPERADOR DE CAMARA	PROFESIONAL ESPECIALIZADO EN OPERACION DE CAMARAS
P270	ILUMINADOR	PROFESIONAL ESPECIALIZADO EN ILUMINACION TECNICA
P271	TECNICO DE SONIDO	PROFESIONAL ESPECIALIZADO EN AUDIO TECNICO
P272	ROADIE	TECNICO ESPECIALIZADO EN EQUIPOS MUSICALES
P273	REGIDOR	PROFESIONAL ESPECIALIZADO EN PRODUCCION TELEVISIVA
P274	SCRIPT	PROFESIONAL ESPECIALIZADO EN CONTINUIDAD AUDIOVISUAL
P275	CASTING DIRECTOR	PROFESIONAL ESPECIALIZADO EN SELECCION DE ACTORES
P276	AGENTE ARTISTICO	PROFESIONAL ESPECIALIZADO EN REPRESENTACION ARTISTICA
P277	MANAGER ARTISTICO	PROFESIONAL ESPECIALIZADO EN GESTION ARTISTICA
P278	PROMOTOR DE EVENTOS	PROFESIONAL ESPECIALIZADO EN PROMOCION DE ESPECTACULOS
P279	WEDDING PLANNER	PROFESIONAL ESPECIALIZADO EN ORGANIZACION DE BODAS
P280	EVENT PLANNER	PROFESIONAL ESPECIALIZADO EN ORGANIZACION DE EVENTOS
P281	ORGANIZADOR DE CONGRESOS	PROFESIONAL ESPECIALIZADO EN EVENTOS CORPORATIVOS
P282	COORDINADOR DE PROTOCOLO	PROFESIONAL ESPECIALIZADO EN PROTOCOLO EMPRESARIAL
P283	RELACIONES PUBLICAS	PROFESIONAL ESPECIALIZADO EN COMUNICACION INSTITUCIONAL
P284	LOBBYISTA	PROFESIONAL ESPECIALIZADO EN CABILDEO
P285	SPIN DOCTOR	PROFESIONAL ESPECIALIZADO EN COMUNICACION POLITICA
P286	CONSULTOR POLITICO	PROFESIONAL ESPECIALIZADO EN ESTRATEGIA POLITICA
P287	ENCUESTADOR	PROFESIONAL ESPECIALIZADO EN INVESTIGACION DE MERCADOS
P288	ANALISTA DE TENDENCIAS	PROFESIONAL ESPECIALIZADO EN ANALISIS DE TENDENCIAS
P289	COOLHUNTER	PROFESIONAL ESPECIALIZADO EN DETECCION DE TENDENCIAS
P290	FUTURISTA	PROFESIONAL ESPECIALIZADO EN PROSPECTIVA
P291	ESTRATEGA DIGITAL	PROFESIONAL ESPECIALIZADO EN ESTRATEGIAS DIGITALES
P292	BRAND MANAGER	PROFESIONAL ESPECIALIZADO EN GESTION DE MARCAS
P293	CATEGORY MANAGER	PROFESIONAL ESPECIALIZADO EN GESTION DE CATEGORIAS
P294	TRADE MARKETING	PROFESIONAL ESPECIALIZADO EN MARKETING COMERCIAL
P295	MERCHANDISER	PROFESIONAL ESPECIALIZADO EN EXHIBICION COMERCIAL
P296	VISUAL MERCHANDISER	PROFESIONAL ESPECIALIZADO EN EXHIBICION VISUAL
P297	ESCAPARATISTA	PROFESIONAL ESPECIALIZADO EN DISENO DE ESCAPARATES
P298	DISENADOR DE INTERIORES	PROFESIONAL ESPECIALIZADO EN DISENO DE ESPACIOS
P299	INTERIORISTA	PROFESIONAL ESPECIALIZADO EN DECORACION DE INTERIORES
P300	FENG SHUI MASTER	PROFESIONAL ESPECIALIZADO EN ARMONIZACION ESPACIAL
P301	HOME STAGER	PROFESIONAL ESPECIALIZADO EN PRESENTACION INMOBILIARIA
P302	PERSONAL SHOPPER	PROFESIONAL ESPECIALIZADO EN ASESORAMIENTO DE COMPRAS
P303	ESTILISTA DE MODA	PROFESIONAL ESPECIALIZADO EN ASESORAMIENTO DE IMAGEN
P304	CONSULTOR DE IMAGEN	PROFESIONAL ESPECIALIZADO EN IMAGEN PERSONAL
P305	ESPECIALISTA EN COLOR	PROFESIONAL ESPECIALIZADO EN COLORIMETRIA PERSONAL
P306	MAQUILLADOR PROFESIONAL	PROFESIONAL ESPECIALIZADO EN MAQUILLAJE ARTISTICO
P307	CARACTERIZADOR	PROFESIONAL ESPECIALIZADO EN EFECTOS ESPECIALES DE MAQUILLAJE
P308	PROTESIS DENTAL	TECNICO ESPECIALIZADO EN PROTESIS DENTALES
P309	ORTODONCISTA	PROFESIONAL MEDICO ESPECIALIZADO EN ORTODONCIA
P310	PERIODONCISTA	PROFESIONAL MEDICO ESPECIALIZADO EN ENCIAS
P311	ENDODONCISTA	PROFESIONAL MEDICO ESPECIALIZADO EN ENDODONCIA
P312	CIRUJANO ORAL	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA ORAL
P313	IMPLANTOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN IMPLANTES DENTALES
P314	PROTESISTA	TECNICO ESPECIALIZADO EN PROTESIS MEDICAS
P315	ORTESISTA	TECNICO ESPECIALIZADO EN ORTESIS MEDICAS
P316	AUDIOPROTESISTA	TECNICO ESPECIALIZADO EN AUDIFONOS
P317	TECNICO EN LABORATORIO	PROFESIONAL ESPECIALIZADO EN ANALISIS CLINICOS
P318	CITOTECNOLOGO	PROFESIONAL ESPECIALIZADO EN CITOLOGIA
P319	HISTOTECNOLOGO	PROFESIONAL ESPECIALIZADO EN HISTOPATOLOGIA
P320	TECNICO EN HEMOTERAPIA	PROFESIONAL ESPECIALIZADO EN BANCOS DE SANGRE
P321	PERFUSIONISTA	TECNICO ESPECIALIZADO EN CIRCULACION EXTRACORPOREA
P322	TECNICO EN DIALISIS	PROFESIONAL ESPECIALIZADO EN HEMODIALISIS
P323	TECNICO EN RAYOS X	PROFESIONAL ESPECIALIZADO EN RADIOLOGIA
P324	TECNICO EN TOMOGRAFIA	PROFESIONAL ESPECIALIZADO EN TOMOGRAFIA COMPUTADA
P325	TECNICO EN RESONANCIA	PROFESIONAL ESPECIALIZADO EN RESONANCIA MAGNETICA
P326	TECNICO EN ULTRASONIDO	PROFESIONAL ESPECIALIZADO EN ECOGRAFIA
P327	TECNICO EN MEDICINA NUCLEAR	PROFESIONAL ESPECIALIZADO EN MEDICINA NUCLEAR
P328	DOSIMETRISTA	PROFESIONAL ESPECIALIZADO EN RADIOTERAPIA
P329	TECNICO EN ELECTROFISIOLOGIA	PROFESIONAL ESPECIALIZADO EN ESTUDIOS CARDIACOS
P330	TECNICO EN POLISOMNOGRAFIA	PROFESIONAL ESPECIALIZADO EN ESTUDIOS DEL SUENO
P331	ESPECIALISTA EN SUENO	PROFESIONAL MEDICO ESPECIALIZADO EN TRASTORNOS DEL SUENO
P332	NEUMOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES RESPIRATORIAS
P333	CARDIOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES CARDIACAS
P334	GASTROENTEROLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN SISTEMA DIGESTIVO
P335	NEFROLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES RENALES
P336	ENDOCRINOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN SISTEMA ENDOCRINO
P337	REUMATOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES REUMATICAS
P338	DERMATOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES DE LA PIEL
P339	OFTALMOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES OCULARES
P340	OTORRINOLARINGOLOGO	PROFESIONAL ESPECIALIZADO EN OIDO, NARIZ Y GARGANTA
P341	NEUROLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN SISTEMA NERVIOSO
P342	NEUROCIRUJANO	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA NEUROLOGICA
P343	TRAUMATOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN TRAUMATOLOGIA
P344	UROLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN SISTEMA URINARIO
P345	GINECOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN SALUD FEMENINA
P346	OBSTETRA	PROFESIONAL MEDICO ESPECIALIZADO EN EMBARAZO Y PARTO
P347	NEONATOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN RECIEN NACIDOS
P348	GERIATRA	PROFESIONAL MEDICO ESPECIALIZADO EN MEDICINA GERIATRICA
P349	FISIATRA	PROFESIONAL MEDICO ESPECIALIZADO EN MEDICINA FISICA
P350	MEDICINA DEL DEPORTE	PROFESIONAL MEDICO ESPECIALIZADO EN MEDICINA DEPORTIVA
P351	MEDICINA DEL TRABAJO	PROFESIONAL MEDICO ESPECIALIZADO EN SALUD OCUPACIONAL
P352	TOXICOLOGO	PROFESIONAL ESPECIALIZADO EN TOXICOLOGIA
P353	PATOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ANATOMIA PATOLOGICA
P354	MICROBIOLOGO	PROFESIONAL ESPECIALIZADO EN MICROBIOLOGIA
P355	PARASITOLOGO	PROFESIONAL ESPECIALIZADO EN PARASITOLOGIA
P356	VIROLOGO	PROFESIONAL ESPECIALIZADO EN VIROLOGIA
P357	INMUNOLOGO	PROFESIONAL ESPECIALIZADO EN INMUNOLOGIA
P358	HEMATOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN ENFERMEDADES DE LA SANGRE
P359	ONCOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN CANCER
P360	RADIO-ONCOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN RADIOTERAPIA
P361	CIRUJANO PLASTICO	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA PLASTICA
P362	CIRUJANO VASCULAR	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA VASCULAR
P363	CIRUJANO TORACICO	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA TORACICA
P364	CIRUJANO CARDIOVASCULAR	PROFESIONAL MEDICO ESPECIALIZADO EN CIRUGIA CARDIACA
P365	INTENSIVISTA	PROFESIONAL MEDICO ESPECIALIZADO EN CUIDADOS INTENSIVOS
P366	EMERGENTOLOGO	PROFESIONAL MEDICO ESPECIALIZADO EN MEDICINA DE EMERGENCIA
P367	MEDICO LEGISTA	PROFESIONAL MEDICO ESPECIALIZADO EN MEDICINA LEGAL
P368	EPIDEMIOLOGO	PROFESIONAL ESPECIALIZADO EN EPIDEMIOLOGIA
P369	SALUBRISTA	PROFESIONAL ESPECIALIZADO EN SALUD PUBLICA
P370	BIOESTADISTICO	PROFESIONAL ESPECIALIZADO EN ESTADISTICA MEDICA
P371	INFORMATICO MEDICO	PROFESIONAL ESPECIALIZADO EN INFORMATICA MEDICA
P372	INGENIERO CLINICO	PROFESIONAL ESPECIALIZADO EN TECNOLOGIA MEDICA
P373	TECNICO BIOMEDICO	PROFESIONAL ESPECIALIZADO EN EQUIPOS MEDICOS
P374	ESPECIALISTA EN TELEMEDICINA	PROFESIONAL ESPECIALIZADO EN MEDICINA A DISTANCIA
P375	GESTOR SANITARIO	PROFESIONAL ESPECIALIZADO EN GESTION HOSPITALARIA
P376	FARMACEUTICO HOSPITALARIO	PROFESIONAL ESPECIALIZADO EN FARMACIA HOSPITALARIA
P377	FARMACEUTICO CLINICO	PROFESIONAL ESPECIALIZADO EN FARMACOTERAPIA
P378	FARMACOLOGO	PROFESIONAL ESPECIALIZADO EN FARMACOLOGIA
P379	FARMACOVIGILANTE	PROFESIONAL ESPECIALIZADO EN SEGURIDAD DE MEDICAMENTOS
P380	REGULATORY AFFAIRS	PROFESIONAL ESPECIALIZADO EN ASUNTOS REGULATORIOS
P381	MEDICAL WRITER	PROFESIONAL ESPECIALIZADO EN REDACCION MEDICA
P382	INVESTIGADOR CLINICO	PROFESIONAL ESPECIALIZADO EN INVESTIGACION MEDICA
P383	MONITOR DE ENSAYOS CLINICOS	PROFESIONAL ESPECIALIZADO EN MONITOREO DE ESTUDIOS
P384	DATA MANAGER	PROFESIONAL ESPECIALIZADO EN GESTION DE DATOS CLINICOS
P385	BIOESTADISTICO CLINICO	PROFESIONAL ESPECIALIZADO EN ANALISIS ESTADISTICO MEDICO
P386	ESPECIALISTA EN FARMACOECONOMIA	PROFESIONAL ESPECIALIZADO EN ECONOMIA DE LA SALUD
P387	ESPECIALISTA EN ACCESO AL MERCADO	PROFESIONAL ESPECIALIZADO EN ACCESO DE MEDICAMENTOS
P388	ESPECIALISTA EN EVIDENCIA REAL	PROFESIONAL ESPECIALIZADO EN ESTUDIOS OBSERVACIONALES
P389	ESPECIALISTA EN OUTCOMES RESEARCH	PROFESIONAL ESPECIALIZADO EN INVESTIGACION DE RESULTADOS
P390	CONSULTOR EN SALUD DIGITAL	PROFESIONAL ESPECIALIZADO EN TRANSFORMACION DIGITAL SANITARIA
P391	ESPECIALISTA EN INTELIGENCIA ARTIFICIAL MEDICA	PROFESIONAL ESPECIALIZADO EN IA APLICADA A MEDICINA
P392	ESPECIALISTA EN MEDICINA PERSONALIZADA	PROFESIONAL ESPECIALIZADO EN MEDICINA DE PRECISION
P393	CONSEJERO GENETICO	PROFESIONAL ESPECIALIZADO EN ASESORAMIENTO GENETICO
P394	ESPECIALISTA EN MEDICINA REGENERATIVA	PROFESIONAL ESPECIALIZADO EN TERAPIAS REGENERATIVAS
P395	ESPECIALISTA EN TERAPIA GENICA	PROFESIONAL ESPECIALIZADO EN TERAPIAS GENICAS
P396	ESPECIALISTA EN CELULAS MADRE	PROFESIONAL ESPECIALIZADO EN TERAPIA CELULAR
P397	ESPECIALISTA EN NANOMEDICINA	PROFESIONAL ESPECIALIZADO EN NANOTECNOLOGIA MEDICA
P398	ESPECIALISTA EN MEDICINA NUCLEAR TERAPEUTICA	PROFESIONAL ESPECIALIZADO EN RADIOFARMACOS TERAPEUTICOS
P399	ESPECIALISTA EN MEDICINA CUANTICA	PROFESIONAL ESPECIALIZADO EN APLICACIONES CUANTICAS MEDICAS
P400	ESPECIALISTA EN CRIOGENIA MEDICA	PROFESIONAL ESPECIALIZADO EN PRESERVACION CRIOGENICA
P401	ESPECIALISTA EN MEDICINA ESPACIAL	PROFESIONAL ESPECIALIZADO EN MEDICINA AEROESPACIAL
P402	ESPECIALISTA EN MEDICINA SUBACUATICA	PROFESIONAL ESPECIALIZADO EN MEDICINA HIPERBARICA
P403	ESPECIALISTA EN MEDICINA DE MONTANA	PROFESIONAL ESPECIALIZADO EN MEDICINA DE ALTURA
P404	ESPECIALISTA EN MEDICINA TROPICAL	PROFESIONAL ESPECIALIZADO EN ENFERMEDADES TROPICALES
P405	ESPECIALISTA EN MEDICINA DE VIAJES	PROFESIONAL ESPECIALIZADO EN MEDICINA DEL VIAJERO
P406	ESPECIALISTA EN MEDICINA DEPORTIVA	PROFESIONAL ESPECIALIZADO EN ATLETAS DE ELITE
P407	ESPECIALISTA EN MEDICINA ESTETICA	PROFESIONAL ESPECIALIZADO EN TRATAMIENTOS ESTETICOS
P408	ESPECIALISTA EN MEDICINA ANTI-AGING	PROFESIONAL ESPECIALIZADO EN MEDICINA ANTIENVEJECIMIENTO
P409	ESPECIALISTA EN MEDICINA FUNCIONAL	PROFESIONAL ESPECIALIZADO EN MEDICINA FUNCIONAL
P410	ESPECIALISTA EN MEDICINA INTEGRATIVA	PROFESIONAL ESPECIALIZADO EN MEDICINA INTEGRATIVA
P411	ESPECIALISTA EN MEDICINA AYURVEDICA	PROFESIONAL ESPECIALIZADO EN MEDICINA AYURVEDICA
P412	ESPECIALISTA EN MEDICINA TRADICIONAL CHINA	PROFESIONAL ESPECIALIZADO EN MEDICINA CHINA
P413	ESPECIALISTA EN MEDICINA ANTROPOSOFICA	PROFESIONAL ESPECIALIZADO EN MEDICINA ANTROPOSOFICA
P414	ESPECIALISTA EN FLORES DE BACH	PROFESIONAL ESPECIALIZADO EN TERAPIA FLORAL
P415	ESPECIALISTA EN AROMATERAPIA	PROFESIONAL ESPECIALIZADO EN ACEITES ESENCIALES
P416	ESPECIALISTA EN CRISTALOTERAPIA	PROFESIONAL ESPECIALIZADO EN TERAPIA CON CRISTALES
P417	ESPECIALISTA EN MUSICOTERAPIA	PROFESIONAL ESPECIALIZADO EN TERAPIA MUSICAL
P418	ESPECIALISTA EN ARTETERAPIA	PROFESIONAL ESPECIALIZADO EN TERAPIA ARTISTICA
P419	ESPECIALISTA EN DANZATERAPIA	PROFESIONAL ESPECIALIZADO EN TERAPIA DE MOVIMIENTO
P420	ESPECIALISTA EN HIPNOTERAPIA	PROFESIONAL ESPECIALIZADO EN HIPNOSIS TERAPEUTICA
P421	ESPECIALISTA EN TERAPIA COGNITIVO-CONDUCTUAL	PROFESIONAL ESPECIALIZADO EN TCC
P422	ESPECIALISTA EN TERAPIA GESTALT	PROFESIONAL ESPECIALIZADO EN TERAPIA GESTALTICA
P423	ESPECIALISTA EN TERAPIA SISTEMICA	PROFESIONAL ESPECIALIZADO EN TERAPIA FAMILIAR
P424	ESPECIALISTA EN TERAPIA DE PAREJA	PROFESIONAL ESPECIALIZADO EN TERAPIA DE PAREJA
P425	ESPECIALISTA EN TERAPIA SEXUAL	PROFESIONAL ESPECIALIZADO EN SEXOLOGIA CLINICA
P426	ESPECIALISTA EN TERAPIA DE DUELO	PROFESIONAL ESPECIALIZADO EN PROCESO DE DUELO
P427	ESPECIALISTA EN TERAPIA DE TRAUMA	PROFESIONAL ESPECIALIZADO EN TRAUMA PSICOLOGICO
P428	ESPECIALISTA EN TERAPIA EMDR	PROFESIONAL ESPECIALIZADO EN DESENSIBILIZACION Y REPROCESAMIENTO
P429	ESPECIALISTA EN TERAPIA BREVE	PROFESIONAL ESPECIALIZADO EN TERAPIAS BREVES
P430	ESPECIALISTA EN COACHING ONTOLOGICO	PROFESIONAL ESPECIALIZADO EN COACHING ONTOLOGICO
P431	ESPECIALISTA EN COACHING DE VIDA	PROFESIONAL ESPECIALIZADO EN LIFE COACHING
P432	ESPECIALISTA EN COACHING NUTRICIONAL	PROFESIONAL ESPECIALIZADO EN COACHING ALIMENTARIO
P433	ESPECIALISTA EN COACHING DEPORTIVO	PROFESIONAL ESPECIALIZADO EN COACHING DEPORTIVO
P434	ESPECIALISTA EN COACHING EMPRESARIAL	PROFESIONAL ESPECIALIZADO EN COACHING CORPORATIVO
P435	ESPECIALISTA EN COACHING DE EQUIPOS	PROFESIONAL ESPECIALIZADO EN TEAM COACHING
P436	ESPECIALISTA EN COACHING DE LIDERAZGO	PROFESIONAL ESPECIALIZADO EN LIDERAZGO
P437	ESPECIALISTA EN COACHING DE CARRERA	PROFESIONAL ESPECIALIZADO EN DESARROLLO PROFESIONAL
P438	ESPECIALISTA EN COACHING FINANCIERO	PROFESIONAL ESPECIALIZADO EN FINANZAS PERSONALES
P439	ESPECIALISTA EN COACHING DE IMAGEN	PROFESIONAL ESPECIALIZADO EN IMAGEN PERSONAL
P440	ESPECIALISTA EN COACHING PARENTAL	PROFESIONAL ESPECIALIZADO EN CRIANZA
P441	ESPECIALISTA EN EDUCACION EMOCIONAL	PROFESIONAL ESPECIALIZADO EN INTELIGENCIA EMOCIONAL
P442	ESPECIALISTA EN MINDFULNESS	PROFESIONAL ESPECIALIZADO EN ATENCION PLENA
P443	ESPECIALISTA EN MEDITACION	PROFESIONAL ESPECIALIZADO EN TECNICAS MEDITATIVAS
P444	ESPECIALISTA EN YOGA TERAPEUTICO	PROFESIONAL ESPECIALIZADO EN YOGA MEDICINAL
P445	ESPECIALISTA EN PILATES TERAPEUTICO	PROFESIONAL ESPECIALIZADO EN PILATES MEDICINAL
P446	ESPECIALISTA EN TAI CHI	PROFESIONAL ESPECIALIZADO EN TAI CHI CHUAN
P447	ESPECIALISTA EN QI GONG	PROFESIONAL ESPECIALIZADO EN QI GONG
P448	ESPECIALISTA EN REIKI	PROFESIONAL ESPECIALIZADO EN TERAPIA ENERGETICA REIKI
P449	ESPECIALISTA EN REFLEXOLOGIA	PROFESIONAL ESPECIALIZADO EN REFLEXOLOGIA PODAL
P450	ESPECIALISTA EN SHIATSU	PROFESIONAL ESPECIALIZADO EN MASAJE SHIATSU
P451	ESPECIALISTA EN MASAJE AYURVEDICO	PROFESIONAL ESPECIALIZADO EN MASAJE AYURVEDICO
P452	ESPECIALISTA EN MASAJE TAILANDES	PROFESIONAL ESPECIALIZADO EN MASAJE TRADICIONAL TAILANDES
P453	ESPECIALISTA EN MASAJE SUECO	PROFESIONAL ESPECIALIZADO EN MASAJE SUECO
P454	ESPECIALISTA EN MASAJE DEPORTIVO	PROFESIONAL ESPECIALIZADO EN MASAJE PARA DEPORTISTAS
P455	ESPECIALISTA EN MASAJE TERAPEUTICO	PROFESIONAL ESPECIALIZADO EN MASOTERAPIA
P456	ESPECIALISTA EN DRENAJE LINFATICO	PROFESIONAL ESPECIALIZADO EN DRENAJE LINFATICO MANUAL
P457	ESPECIALISTA EN OSTEOPATIA	PROFESIONAL ESPECIALIZADO EN MEDICINA OSTEOPATICA
P458	ESPECIALISTA EN KINESIOLOGIA	PROFESIONAL ESPECIALIZADO EN KINESIOLOGIA APLICADA
P459	ESPECIALISTA EN FELDENKRAIS	PROFESIONAL ESPECIALIZADO EN METODO FELDENKRAIS
P460	ESPECIALISTA EN ALEXANDER	PROFESIONAL ESPECIALIZADO EN TECNICA ALEXANDER
P461	ESPECIALISTA EN ROLFING	PROFESIONAL ESPECIALIZADO EN INTEGRACION ESTRUCTURAL
P462	ESPECIALISTA EN BIODANZA	PROFESIONAL ESPECIALIZADO EN BIODANZA
P463	ESPECIALISTA EN CONSTELACIONES FAMILIARES	PROFESIONAL ESPECIALIZADO EN CONSTELACIONES SISTEMICAS
P464	ESPECIALISTA EN PNL	PROFESIONAL ESPECIALIZADO EN PROGRAMACION NEUROLINGUISTICA
P465	ESPECIALISTA EN ANALISIS TRANSACCIONAL	PROFESIONAL ESPECIALIZADO EN AT
P466	ESPECIALISTA EN ENEAGRAMA	PROFESIONAL ESPECIALIZADO EN ENEAGRAMA DE PERSONALIDAD
P467	ESPECIALISTA EN MBTI	PROFESIONAL ESPECIALIZADO EN TIPOS DE PERSONALIDAD MYERS-BRIGGS
P468	ESPECIALISTA EN DISC	PROFESIONAL ESPECIALIZADO EN METODOLOGIA DISC
P469	ESPECIALISTA EN INTELIGENCIAS MULTIPLES	PROFESIONAL ESPECIALIZADO EN TEORIA DE GARDNER
P470	ESPECIALISTA EN NEUROEDUCACION	PROFESIONAL ESPECIALIZADO EN NEUROCIENCIA EDUCATIVA
P471	ESPECIALISTA EN EDUCACION ESPECIAL	PROFESIONAL ESPECIALIZADO EN NECESIDADES EDUCATIVAS ESPECIALES
P472	ESPECIALISTA EN AUTISMO	PROFESIONAL ESPECIALIZADO EN TRASTORNOS DEL ESPECTRO AUTISTA
P473	ESPECIALISTA EN TDAH	PROFESIONAL ESPECIALIZADO EN DEFICIT DE ATENCION
P474	ESPECIALISTA EN DISLEXIA	PROFESIONAL ESPECIALIZADO EN TRASTORNOS DE APRENDIZAJE
P475	ESPECIALISTA EN ALTAS CAPACIDADES	PROFESIONAL ESPECIALIZADO EN SUPERDOTACION
P476	ESPECIALISTA EN ORIENTACION VOCACIONAL	PROFESIONAL ESPECIALIZADO EN ORIENTACION PROFESIONAL
P477	ESPECIALISTA EN LUDOTERAPIA	PROFESIONAL ESPECIALIZADO EN TERAPIA LUDICA
P478	ESPECIALISTA EN TERAPIA OCUPACIONAL	PROFESIONAL ESPECIALIZADO EN REHABILITACION FUNCIONAL
P479	ESPECIALISTA EN TERAPIA DEL LENGUAJE	PROFESIONAL ESPECIALIZADO EN FONOAUDIOLOGIA
P480	ESPECIALISTA EN AUDIOLOGIA	PROFESIONAL ESPECIALIZADO EN AUDICION
P481	ESPECIALISTA EN OPTOMETRIA	PROFESIONAL ESPECIALIZADO EN SALUD VISUAL
P482	ESPECIALISTA EN ORTOPTICA	PROFESIONAL ESPECIALIZADO EN MOTILIDAD OCULAR
P483	ESPECIALISTA EN BAJA VISION	PROFESIONAL ESPECIALIZADO EN REHABILITACION VISUAL
P484	ESPECIALISTA EN ORIENTACION Y MOVILIDAD	PROFESIONAL ESPECIALIZADO EN DESPLAZAMIENTO PARA CIEGOS
P485	ESPECIALISTA EN BRAILLE	PROFESIONAL ESPECIALIZADO EN SISTEMA BRAILLE
P486	ESPECIALISTA EN LENGUA DE SENAS	PROFESIONAL ESPECIALIZADO EN COMUNICACION PARA SORDOS
P487	ESPECIALISTA EN TECNOLOGIA ASISTIVA	PROFESIONAL ESPECIALIZADO EN AYUDAS TECNICAS
P488	ESPECIALISTA EN ACCESIBILIDAD	PROFESIONAL ESPECIALIZADO EN DISENO UNIVERSAL
P489	ESPECIALISTA EN ERGONOMIA	PROFESIONAL ESPECIALIZADO EN ERGONOMIA OCUPACIONAL
P490	ESPECIALISTA EN HIGIENE INDUSTRIAL	PROFESIONAL ESPECIALIZADO EN SALUD OCUPACIONAL
P491	ESPECIALISTA EN SEGURIDAD LABORAL	PROFESIONAL ESPECIALIZADO EN PREVENCION DE RIESGOS
P492	ESPECIALISTA EN MEDICINA OCUPACIONAL	PROFESIONAL MEDICO ESPECIALIZADO EN SALUD LABORAL
P493	ESPECIALISTA EN PSICOLOGIA LABORAL	PROFESIONAL ESPECIALIZADO EN PSICOLOGIA ORGANIZACIONAL
P494	ESPECIALISTA EN CLIMA LABORAL	PROFESIONAL ESPECIALIZADO EN AMBIENTE DE TRABAJO
P495	ESPECIALISTA EN CULTURA ORGANIZACIONAL	PROFESIONAL ESPECIALIZADO EN CULTURA CORPORATIVA
P496	ESPECIALISTA EN TRANSFORMACION DIGITAL	PROFESIONAL ESPECIALIZADO EN DIGITALIZACION EMPRESARIAL
P497	ESPECIALISTA EN INNOVACION	PROFESIONAL ESPECIALIZADO EN GESTION DE LA INNOVACION
P498	ESPECIALISTA EN DESIGN THINKING	PROFESIONAL ESPECIALIZADO EN PENSAMIENTO DE DISENO
P499	ESPECIALISTA EN LEAN MANAGEMENT	PROFESIONAL ESPECIALIZADO EN GESTION LEAN
P500	ESPECIALISTA EN SIX SIGMA	PROFESIONAL ESPECIALIZADO EN METODOLOGIA SIX SIGMA
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     4959.dat                                                                                            0000600 0004000 0002000 00000317024 15015342721 0014273 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        3	CONFIRMADA	CORREO	2024-11-15	190000.00	1029847651	STF02
2	CONFIRMADA	EMAIL	2019-08-20	108922.00	1024756381	STF01
1	CONFIRMADA	REDES SOCIALES	2019-04-12	60000.00	1332432138	STF01
1011	CONFIRMADA	WHATSAPP	2022-03-20	154125.00	1076543210	STF01
1012	CONFIRMADA	REDES SOCIALES	2023-04-15	153143.00	1043210987	STF02
4	PENDIENTE	LLAMADA TELEFONICA	2019-11-15	0.00	1045697382	STF03
5	PENDIENTE	REDES SOCIALES	2023-06-25	0.00	1032568749	STF02
6	CANCELADA	WHATSAPP	2021-12-02	0.00	1038457296	STF03
7	PENDIENTE	REFERIDO	2022-09-19	0.00	1026745832	STF03
9	PENDIENTE	REDES SOCIALES	2023-07-18	0.00	1037952684	STF01
10	PENDIENTE	REDES SOCIALES	2025-02-04	0.00	1043687524	STF03
13	CANCELADA	REDES SOCIALES	2019-01-09	0.00	1033576842	STF01
14	CANCELADA	WHATSAPP	2022-01-03	0.00	1029485736	STF02
8	CONFIRMADA	LLAMADA TELEFONICA	2025-02-02	340000.00	1041856739	STF02
11	CONFIRMADA	LLAMADA TELEFONICA	2023-08-13	318938.00	1030482597	STF03
18	PENDIENTE	WHATSAPP	2021-10-01	0.00	1098762232	STF03
19	CANCELADA	REFERIDO	2022-07-18	0.00	1054321098	STF01
20	PENDIENTE	WHATSAPP	2022-03-20	0.00	1076543210	STF01
12	CONFIRMADA	LLAMADA TELEFONICA	2023-10-19	563938.00	1046785923	STF02
15	CONFIRMADA	WHATSAPP	2021-06-03	90000.00	1092692837	STF02
23	CANCELADA	REDES SOCIALES	2023-04-15	0.00	1043210987	STF02
21	CONFIRMADA	REDES SOCIALES	2021-07-21	194004.00	1032109876	STF01
25	PENDIENTE	REFERIDO	2022-10-27	0.00	1076549873	STF01
26	PENDIENTE	CORREO	2021-03-02	0.00	1098765123	STF01
27	CANCELADA	REDES SOCIALES	2019-12-08	0.00	1032165498	STF03
22	CONFIRMADA	WHATSAPP	2019-12-07	196299.00	1087654321	STF03
24	CONFIRMADA	LLAMADA TELEFONICA	2023-07-04	441261.00	1065432109	STF03
30	CANCELADA	REFERIDO	2025-04-14	0.00	1076321098	STF01
28	CONFIRMADA	REDES SOCIALES	2021-12-25	327492.00	1087659321	STF01
32	PENDIENTE	CORREO	2020-09-25	0.00	1043659871	STF02
33	CANCELADA	REFERIDO	2020-04-09	0.00	1065987412	STF03
34	CANCELADA	REDES SOCIALES	2023-04-30	0.00	1087321654	STF02
29	CONFIRMADA	WHATSAPP	2022-06-30	163938.00	1054987654	STF02
31	CONFIRMADA	WHATSAPP	2024-11-19	273425.00	1098123456	STF03
37	PENDIENTE	WHATSAPP	2022-11-23	0.00	1076987654	STF02
38	PENDIENTE	REDES SOCIALES	2020-12-06	0.00	1032453389	STF02
39	CANCELADA	LLAMADA TELEFONICA	2022-07-02	0.00	1087456123	STF02
35	CONFIRMADA	REDES SOCIALES	2025-01-04	421470.00	1098654789	STF01
41	CANCELADA	LLAMADA TELEFONICA	2022-03-04	0.00	1065456987	STF02
42	CANCELADA	WHATSAPP	2019-10-13	0.00	1076234567	STF01
36	CONFIRMADA	CORREO	2019-08-08	111688.00	1054123987	STF01
40	CONFIRMADA	LLAMADA TELEFONICA	2020-01-11	161892.00	1043789654	STF01
43	CONFIRMADA	REDES SOCIALES	2020-02-06	117034.00	1098789123	STF02
44	CONFIRMADA	REDES SOCIALES	2022-11-13	100242.00	1054876543	STF03
45	CONFIRMADA	REDES SOCIALES	2021-03-05	381588.00	1087123654	STF01
46	CONFIRMADA	CORREO	2022-02-16	335075.00	1043654987	STF01
47	CONFIRMADA	REDES SOCIALES	2019-07-24	492549.00	1065321456	STF01
50	CANCELADA	LLAMADA TELEFONICA	2021-08-29	0.00	1054789012	STF03
48	CONFIRMADA	REFERIDO	2019-11-20	181425.00	1076456789	STF02
52	PENDIENTE	REFERIDO	2021-06-21	0.00	1043567890	STF02
49	CONFIRMADA	CORREO	2022-12-14	185254.00	1098321456	STF01
54	PENDIENTE	CORREO	2022-12-24	0.00	1076789012	STF02
55	PENDIENTE	REFERIDO	2023-12-25	0.00	1098456789	STF03
51	CONFIRMADA	WHATSAPP	2021-04-14	399716.00	1087987654	STF01
57	CANCELADA	LLAMADA TELEFONICA	2023-06-05	0.00	1054567890	STF02
53	CONFIRMADA	REFERIDO	2021-12-17	375851.00	1065654321	STF02
56	CONFIRMADA	WHATSAPP	2023-05-05	256299.00	1009125678	STF02
60	CANCELADA	LLAMADA TELEFONICA	2020-11-20	0.00	1065789123	STF03
58	CONFIRMADA	WHATSAPP	2023-07-25	410851.00	1087654098	STF01
62	CANCELADA	WHATSAPP	2023-06-15	0.00	1098789456	STF02
59	CONFIRMADA	REDES SOCIALES	2025-02-07	530672.00	1043890765	STF03
64	CANCELADA	CORREO	2022-01-31	0.00	1087456789	STF02
61	CONFIRMADA	LLAMADA TELEFONICA	2020-06-11	546261.00	1076567432	STF02
66	CANCELADA	REDES SOCIALES	2019-04-15	0.00	1091234567	STF02
67	CANCELADA	REFERIDO	2019-10-21	0.00	1065432876	STF01
68	PENDIENTE	WHATSAPP	2021-11-06	0.00	1076890123	STF02
69	PENDIENTE	REFERIDO	2022-01-21	0.00	1098567321	STF02
63	CONFIRMADA	CORREO	2020-05-14	176470.00	1054321567	STF01
71	PENDIENTE	CORREO	2020-07-25	0.00	1087789654	STF02
65	CONFIRMADA	REDES SOCIALES	2023-09-14	523966.00	1043123456	STF01
73	CANCELADA	REFERIDO	2022-11-26	0.00	1065123789	STF02
74	PENDIENTE	CORREO	2021-03-28	0.00	1076321654	STF02
75	PENDIENTE	REDES SOCIALES	2024-11-02	0.00	1098654123	STF03
76	CANCELADA	REFERIDO	2019-01-10	0.00	1054987324	STF03
77	CANCELADA	CORREO	2024-08-23	0.00	1087321987	STF01
78	PENDIENTE	LLAMADA TELEFONICA	2024-07-08	0.00	1043789321	STF02
70	CONFIRMADA	WHATSAPP	2023-02-07	325851.00	1054678954	STF01
80	CANCELADA	WHATSAPP	2022-11-23	0.00	1076123987	STF03
81	CANCELADA	CORREO	2021-08-18	0.00	1098321789	STF03
82	CANCELADA	WHATSAPP	2023-01-12	0.00	AB1234567	STF03
83	PENDIENTE	LLAMADA TELEFONICA	2022-06-06	0.00	1054456789	STF01
84	CANCELADA	REDES SOCIALES	2019-05-17	0.00	1087123987	STF02
85	PENDIENTE	REDES SOCIALES	2019-06-03	0.00	1043654321	STF03
86	CANCELADA	LLAMADA TELEFONICA	2024-02-04	0.00	1065789456	STF03
87	PENDIENTE	LLAMADA TELEFONICA	2020-02-01	0.00	1076654987	STF01
88	CANCELADA	CORREO	2020-11-07	0.00	1098456321	STF03
89	CANCELADA	LLAMADA TELEFONICA	2024-01-29	0.00	1054123654	STF02
90	PENDIENTE	REDES SOCIALES	2025-04-24	0.00	1087987321	STF01
91	PENDIENTE	LLAMADA TELEFONICA	2025-05-08	0.00	1043567321	STF03
72	CONFIRMADA	REDES SOCIALES	2023-02-05	213938.00	1043456123	STF03
79	CONFIRMADA	REDES SOCIALES	2025-02-24	404010.00	1065456123	STF01
94	CANCELADA	WHATSAPP	2022-03-06	0.00	1098123987	STF01
1013	CONFIRMADA	REFERIDO	2022-10-27	249293.00	1076549873	STF01
1014	CONFIRMADA	CORREO	2021-03-02	439906.00	1098765123	STF01
1015	CONFIRMADA	REDES SOCIALES	2019-12-08	73629.00	1032165498	STF03
92	CONFIRMADA	REDES SOCIALES	2024-08-29	125851.00	1065321987	STF03
93	CONFIRMADA	LLAMADA TELEFONICA	2023-07-01	119284.00	1076789456	STF03
96	CANCELADA	WHATSAPP	2021-10-22	0.00	12345678	STF03
97	PENDIENTE	CORREO	2019-01-15	0.00	1087456987	STF01
98	CANCELADA	LLAMADA TELEFONICA	2022-12-13	0.00	1043321654	STF01
99	CANCELADA	REFERIDO	2019-09-07	0.00	1065654987	STF01
100	PENDIENTE	REFERIDO	2024-08-03	0.00	1076456321	STF01
101	PENDIENTE	CORREO	2022-07-31	0.00	1098789654	STF01
102	CANCELADA	REFERIDO	2020-06-02	0.00	1054321789	STF02
95	CONFIRMADA	LLAMADA TELEFONICA	2019-11-08	246299.00	1054789456	STF03
103	CONFIRMADA	REDES SOCIALES	2024-07-16	323425.00	1087654456	STF02
105	PENDIENTE	REFERIDO	2020-11-25	0.00	1065123456	STF02
106	PENDIENTE	WHATSAPP	2025-01-18	0.00	1076987123	STF02
107	CANCELADA	CORREO	2019-02-15	0.00	1098456987	STF03
108	PENDIENTE	REDES SOCIALES	2019-02-22	0.00	1054654321	STF01
109	PENDIENTE	REFERIDO	2021-12-11	0.00	1087321456	STF02
104	CONFIRMADA	WHATSAPP	2024-02-05	65000.00	1043987654	STF02
111	PENDIENTE	CORREO	2021-07-06	0.00	1065987654	STF02
112	PENDIENTE	CORREO	2023-01-31	0.00	1234521341	STF01
113	CANCELADA	CORREO	2021-11-30	0.00	1076123654	STF03
114	CANCELADA	REFERIDO	2020-05-30	0.00	1098652289	STF01
110	CONFIRMADA	CORREO	2020-03-30	254284.00	1043456987	STF01
116	CANCELADA	LLAMADA TELEFONICA	2022-12-05	0.00	1087789123	STF03
117	CANCELADA	CORREO	2022-11-22	0.00	1043123789	STF01
115	CONFIRMADA	WHATSAPP	2022-12-17	178938.00	1054987123	STF01
118	CONFIRMADA	REDES SOCIALES	2023-04-12	246470.00	1087234569	STF03
120	CANCELADA	WHATSAPP	2025-01-12	0.00	1023456789	STF02
121	CANCELADA	REDES SOCIALES	2021-07-31	0.00	1056789123	STF03
122	CANCELADA	REFERIDO	2020-06-21	0.00	1034567891	STF01
119	CONFIRMADA	CORREO	2025-02-10	256299.00	1045678912	STF01
124	CANCELADA	REDES SOCIALES	2019-08-27	0.00	1045123456	STF02
123	CONFIRMADA	LLAMADA TELEFONICA	2024-01-13	109299.00	1067891234	STF01
126	CANCELADA	CORREO	2023-12-06	0.00	1034512789	STF01
127	PENDIENTE	CORREO	2019-09-20	0.00	1067834512	STF03
128	CANCELADA	LLAMADA TELEFONICA	2020-12-15	0.00	1045678234	STF01
129	PENDIENTE	WHATSAPP	2020-03-16	0.00	1076543218	STF01
125	CONFIRMADA	WHATSAPP	2021-02-27	261107.00	1078912345	STF03
130	CONFIRMADA	REFERIDO	2023-11-07	121261.00	1034569871	STF03
131	CONFIRMADA	REFERIDO	2023-02-18	168492.00	1065432178	STF03
133	PENDIENTE	CORREO	2022-08-31	0.00	1076523519	STF01
132	CONFIRMADA	WHATSAPP	2022-04-02	225851.00	1043216789	STF01
135	PENDIENTE	CORREO	2022-04-17	0.00	1065879123	STF01
134	CONFIRMADA	REFERIDO	2024-12-20	118425.00	1034578912	STF03
136	CONFIRMADA	LLAMADA TELEFONICA	2024-12-14	429284.00	1043567891	STF03
137	CONFIRMADA	REFERIDO	2021-01-21	259171.00	1074321987	STF03
139	CANCELADA	WHATSAPP	2021-07-27	0.00	1083654927	STF01
140	PENDIENTE	CORREO	2021-11-30	0.00	1051234876	STF03
141	PENDIENTE	WHATSAPP	2023-05-08	0.00	1072345689	STF03
142	CANCELADA	CORREO	2020-10-21	0.00	1040987654	STF03
138	CONFIRMADA	CORREO	2021-06-15	289171.00	1042187659	STF02
143	CONFIRMADA	REDES SOCIALES	2020-11-11	353938.00	1081234567	STF02
145	CANCELADA	REDES SOCIALES	2023-05-02	0.00	1078901234	STF03
146	CANCELADA	WHATSAPP	2021-08-06	0.00	1046789012	STF01
147	CANCELADA	CORREO	2022-04-22	0.00	1085432167	STF02
144	CONFIRMADA	REDES SOCIALES	2019-01-30	350851.00	1049876543	STF03
149	PENDIENTE	REDES SOCIALES	2023-09-18	0.00	1074567890	STF03
148	CONFIRMADA	REDES SOCIALES	2025-01-02	325851.00	1043223487	STF02
151	CANCELADA	REDES SOCIALES	2021-04-15	0.00	1081098765	STF02
152	PENDIENTE	REFERIDO	2020-10-08	0.00	1048765432	STF01
153	CANCELADA	REFERIDO	2020-10-10	0.00	1076543310	STF01
154	CANCELADA	LLAMADA TELEFONICA	2024-04-17	0.00	1045678901	STF01
155	CANCELADA	REFERIDO	2023-01-05	0.00	1083456789	STF02
156	PENDIENTE	WHATSAPP	2019-08-27	0.00	1052109876	STF02
157	CANCELADA	WHATSAPP	2023-09-16	0.00	1074321098	STF03
158	PENDIENTE	WHATSAPP	2023-09-09	0.00	1043876521	STF01
159	CANCELADA	LLAMADA TELEFONICA	2021-03-09	0.00	1081234098	STF03
160	CANCELADA	LLAMADA TELEFONICA	2021-11-10	0.00	1049567834	STF03
161	CANCELADA	REFERIDO	2022-10-10	0.00	1076893323	STF02
150	CONFIRMADA	LLAMADA TELEFONICA	2024-01-27	305851.00	1052341876	STF01
163	CANCELADA	CORREO	2020-11-03	0.00	1083654210	STF01
164	CANCELADA	REFERIDO	2022-02-07	0.00	1051987654	STF03
165	CANCELADA	LLAMADA TELEFONICA	2021-04-23	0.00	1072345876	STF01
162	CONFIRMADA	REFERIDO	2019-06-17	132492.00	1045321876	STF03
167	PENDIENTE	CORREO	2019-05-19	0.00	1081098432	STF01
166	CONFIRMADA	REDES SOCIALES	2019-02-15	96299.00	1040654321	STF01
169	PENDIENTE	REFERIDO	2023-02-20	0.00	1078432109	STF02
168	CONFIRMADA	REDES SOCIALES	2020-04-19	83966.00	1049765123	STF01
171	PENDIENTE	WHATSAPP	2019-01-28	0.00	1523456733	STF01
172	PENDIENTE	REFERIDO	2025-05-05	0.00	1083210765	STF03
173	CANCELADA	REDES SOCIALES	2024-05-26	0.00	1051654321	STF03
170	CONFIRMADA	REFERIDO	2023-11-25	224171.00	1046521098	STF03
175	CANCELADA	LLAMADA TELEFONICA	2020-11-14	0.00	1040987321	STF02
176	PENDIENTE	LLAMADA TELEFONICA	2019-10-01	0.00	1081543210	STF02
177	PENDIENTE	WHATSAPP	2023-12-03	0.00	1049321876	STF02
174	CONFIRMADA	REDES SOCIALES	2023-09-16	408107.00	1072109876	STF03
179	CANCELADA	LLAMADA TELEFONICA	2019-12-20	0.00	1046789321	STF01
180	PENDIENTE	CORREO	2024-12-25	0.00	1008200987	STF03
181	PENDIENTE	REFERIDO	2020-07-27	0.00	1053456789	STF02
178	CONFIRMADA	LLAMADA TELEFONICA	2023-01-23	94284.00	1078654321	STF01
183	PENDIENTE	WHATSAPP	2021-03-09	0.00	1042987654	STF02
184	CANCELADA	LLAMADA TELEFONICA	2021-03-28	0.00	1083456210	STF02
185	PENDIENTE	CORREO	2020-08-01	0.00	1051789654	STF02
186	PENDIENTE	LLAMADA TELEFONICA	2020-09-16	0.00	1072543210	STF03
182	CONFIRMADA	LLAMADA TELEFONICA	2021-12-09	517492.00	1074321654	STF01
188	CANCELADA	LLAMADA TELEFONICA	2023-04-23	0.00	1081321098	STF03
190	CANCELADA	CORREO	2019-10-08	0.00	1078210987	STF01
193	CANCELADA	LLAMADA TELEFONICA	2020-12-18	0.00	1053321654	STF01
194	CANCELADA	WHATSAPP	2020-11-21	0.00	1074876543	STF01
195	PENDIENTE	LLAMADA TELEFONICA	2023-06-12	0.00	1042210987	STF02
196	CANCELADA	CORREO	2022-02-13	0.00	1083543210	STF02
197	PENDIENTE	CORREO	2019-09-03	0.00	1051876543	STF01
198	CANCELADA	REDES SOCIALES	2024-03-07	0.00	1072654321	STF01
187	CONFIRMADA	REFERIDO	2020-05-29	476261.00	1040876543	STF01
200	PENDIENTE	WHATSAPP	2019-12-25	0.00	108138765	STF02
189	CONFIRMADA	CORREO	2023-04-27	161261.00	1049654321	STF02
191	CONFIRMADA	REFERIDO	2023-03-23	271261.00	1046543210	STF03
203	PENDIENTE	LLAMADA TELEFONICA	2024-07-12	0.00	1085321654	STF01
204	PENDIENTE	REDES SOCIALES	2024-10-20	0.00	16345678	STF03
205	PENDIENTE	REFERIDO	2023-02-06	0.00	1053987654	STF03
206	CANCELADA	REDES SOCIALES	2023-06-14	0.00	1074543210	STF01
192	CONFIRMADA	REDES SOCIALES	2024-04-13	505000.00	1085098765	STF01
208	CANCELADA	CORREO	2023-08-13	0.00	1083210654	STF03
199	CONFIRMADA	REFERIDO	2023-03-31	344010.00	1040321098	STF02
210	CANCELADA	CORREO	2024-01-19	0.00	1072098765	STF03
201	CONFIRMADA	REDES SOCIALES	2024-02-22	244004.00	1046210987	STF03
212	PENDIENTE	WHATSAPP	2025-01-21	0.00	1081432109	STF02
202	CONFIRMADA	REDES SOCIALES	2024-07-12	412492.00	37654321	STF01
214	CANCELADA	LLAMADA TELEFONICA	2023-10-27	0.00	1078543210	STF03
215	CANCELADA	WHATSAPP	2021-11-09	0.00	1046321098	STF03
216	CANCELADA	WHATSAPP	2022-12-13	0.00	1085098432	STF01
217	PENDIENTE	WHATSAPP	2023-06-02	0.00	88145756	STF01
218	PENDIENTE	CORREO	2020-07-01	0.00	1053654321	STF03
219	CANCELADA	CORREO	2020-02-24	0.00	1074210987	STF01
220	PENDIENTE	WHATSAPP	2019-09-15	0.00	1042543210	STF02
221	PENDIENTE	REDES SOCIALES	2019-11-10	0.00	1065456987	STF03
222	PENDIENTE	WHATSAPP	2024-07-25	0.00	1076234567	STF01
223	PENDIENTE	REFERIDO	2023-10-04	0.00	1098789123	STF02
224	PENDIENTE	REDES SOCIALES	2021-11-21	0.00	1054876543	STF02
207	CONFIRMADA	REFERIDO	2021-01-21	217477.00	1042876543	STF03
226	PENDIENTE	CORREO	2024-05-28	0.00	1043654987	STF01
227	PENDIENTE	REFERIDO	2020-12-16	0.00	1065321456	STF03
228	CANCELADA	WHATSAPP	2022-09-18	0.00	1076456789	STF03
209	CONFIRMADA	WHATSAPP	2023-09-03	368771.00	1051543210	STF02
211	CONFIRMADA	REFERIDO	2024-02-25	190241.00	1040654987	STF02
231	PENDIENTE	REDES SOCIALES	2019-12-30	0.00	1087987654	STF01
232	CANCELADA	CORREO	2024-06-13	0.00	1043567890	STF03
233	CANCELADA	REFERIDO	2022-10-23	0.00	1065654321	STF02
234	CANCELADA	REDES SOCIALES	2020-02-18	0.00	1076789012	STF01
235	PENDIENTE	WHATSAPP	2021-01-07	0.00	1098456789	STF02
236	PENDIENTE	CORREO	2021-03-23	0.00	1009125678	STF03
237	CANCELADA	WHATSAPP	2019-02-09	0.00	1054567890	STF02
238	PENDIENTE	REDES SOCIALES	2020-06-13	0.00	1087654098	STF01
239	CANCELADA	CORREO	2023-06-02	0.00	1043890765	STF03
240	CANCELADA	LLAMADA TELEFONICA	2024-06-10	0.00	1065789123	STF03
241	CANCELADA	LLAMADA TELEFONICA	2025-04-26	0.00	1076567432	STF01
242	CANCELADA	CORREO	2021-01-11	0.00	1098789456	STF02
243	CANCELADA	LLAMADA TELEFONICA	2019-01-07	0.00	1054321567	STF03
244	CANCELADA	WHATSAPP	2021-05-29	0.00	1087456789	STF02
245	PENDIENTE	REFERIDO	2023-05-05	0.00	1043123456	STF01
246	PENDIENTE	REFERIDO	2020-04-12	0.00	1091234567	STF02
247	CANCELADA	REDES SOCIALES	2020-09-28	0.00	1065432876	STF02
248	CANCELADA	REFERIDO	2019-02-04	0.00	1076890123	STF01
249	PENDIENTE	REDES SOCIALES	2023-02-24	0.00	1098567321	STF02
250	PENDIENTE	CORREO	2023-12-03	0.00	1054678954	STF01
251	PENDIENTE	REDES SOCIALES	2021-02-20	0.00	1087789654	STF03
213	CONFIRMADA	LLAMADA TELEFONICA	2024-03-28	116618.00	1049876210	STF03
253	CANCELADA	REDES SOCIALES	2020-10-04	0.00	1065123789	STF02
225	CONFIRMADA	CORREO	2022-07-10	500111.00	1087123654	STF02
255	CANCELADA	LLAMADA TELEFONICA	2022-09-09	0.00	1098654123	STF02
256	PENDIENTE	REFERIDO	2021-04-28	0.00	1054987324	STF02
257	CANCELADA	CORREO	2021-01-12	0.00	1087321987	STF02
258	CANCELADA	REDES SOCIALES	2022-07-16	0.00	1043789321	STF01
229	CONFIRMADA	WHATSAPP	2021-02-03	502581.00	1098321456	STF02
230	CONFIRMADA	REFERIDO	2023-06-21	303414.00	1054789012	STF01
252	CONFIRMADA	REDES SOCIALES	2019-08-01	392708.00	1043456123	STF02
254	CONFIRMADA	WHATSAPP	2019-12-30	292369.00	1076321654	STF03
259	CONFIRMADA	WHATSAPP	2021-07-27	395647.00	1065456123	STF03
264	CANCELADA	REDES SOCIALES	2019-07-07	0.00	1087123987	STF03
265	CANCELADA	WHATSAPP	2020-08-05	0.00	1043654321	STF01
266	PENDIENTE	REDES SOCIALES	2019-12-06	0.00	1065789456	STF02
267	CANCELADA	LLAMADA TELEFONICA	2024-06-30	0.00	1076654987	STF02
260	CONFIRMADA	LLAMADA TELEFONICA	2023-03-03	348538.00	1076123987	STF02
269	CANCELADA	REDES SOCIALES	2021-07-13	0.00	1054123654	STF03
261	CONFIRMADA	WHATSAPP	2019-08-20	231414.00	1098321789	STF03
262	CONFIRMADA	LLAMADA TELEFONICA	2019-04-27	381965.00	AB1234567	STF01
263	CONFIRMADA	REDES SOCIALES	2022-07-16	250841.00	1054456789	STF02
268	CONFIRMADA	REDES SOCIALES	2023-07-09	468909.00	1098456321	STF02
274	PENDIENTE	LLAMADA TELEFONICA	2023-10-12	0.00	1098123987	STF01
275	PENDIENTE	REDES SOCIALES	2023-06-23	0.00	1054789456	STF02
276	PENDIENTE	WHATSAPP	2022-12-03	0.00	12345678	STF01
270	CONFIRMADA	REFERIDO	2020-01-24	255979.00	1087987321	STF01
271	CONFIRMADA	REDES SOCIALES	2024-06-30	255053.00	1043567321	STF03
272	CONFIRMADA	LLAMADA TELEFONICA	2025-04-21	447492.00	1065321987	STF03
280	PENDIENTE	REDES SOCIALES	2021-01-20	0.00	1076456321	STF01
281	PENDIENTE	LLAMADA TELEFONICA	2021-01-16	0.00	1098789654	STF01
282	PENDIENTE	LLAMADA TELEFONICA	2021-06-01	0.00	1054321789	STF02
283	PENDIENTE	REFERIDO	2022-09-17	0.00	1087654456	STF01
273	CONFIRMADA	REFERIDO	2020-08-02	409293.00	1076789456	STF03
285	CANCELADA	LLAMADA TELEFONICA	2021-02-25	0.00	1065123456	STF03
277	CONFIRMADA	LLAMADA TELEFONICA	2019-01-31	404837.00	1087456987	STF03
287	CANCELADA	REFERIDO	2021-09-17	0.00	1098456987	STF02
278	CONFIRMADA	CORREO	2025-03-18	256299.00	1043321654	STF03
289	PENDIENTE	REFERIDO	2021-11-21	0.00	1087321456	STF02
279	CONFIRMADA	REDES SOCIALES	2023-10-20	493938.00	1065654987	STF03
291	PENDIENTE	REFERIDO	2020-02-13	0.00	1065987654	STF01
292	PENDIENTE	REDES SOCIALES	2023-02-16	0.00	1234521341	STF02
294	CANCELADA	WHATSAPP	2020-03-09	0.00	1098652289	STF03
296	PENDIENTE	REDES SOCIALES	2019-08-21	0.00	1087789123	STF03
297	PENDIENTE	LLAMADA TELEFONICA	2024-12-19	0.00	1043123789	STF01
298	CANCELADA	CORREO	2022-12-18	0.00	1087234569	STF01
299	PENDIENTE	REDES SOCIALES	2022-03-13	0.00	1045678912	STF02
284	CONFIRMADA	REFERIDO	2020-05-19	188380.00	1043987654	STF02
301	PENDIENTE	WHATSAPP	2025-04-10	0.00	1056789123	STF01
302	CANCELADA	LLAMADA TELEFONICA	2024-04-21	0.00	1034567891	STF03
303	CANCELADA	CORREO	2021-10-23	0.00	1067891234	STF03
304	CANCELADA	REFERIDO	2024-01-02	0.00	1091483627	STF02
305	CANCELADA	REFERIDO	2021-04-12	0.00	1027395841	STF02
306	PENDIENTE	REDES SOCIALES	2023-04-25	0.00	1075962843	STF02
286	CONFIRMADA	LLAMADA TELEFONICA	2024-10-25	133336.00	1076987123	STF03
288	CONFIRMADA	WHATSAPP	2020-09-23	215672.00	1054654321	STF01
309	CANCELADA	CORREO	2020-02-01	0.00	1039627485	STF02
310	CANCELADA	REDES SOCIALES	2022-03-20	0.00	1087529641	STF02
311	PENDIENTE	REFERIDO	2019-05-08	0.00	1007529441	STF03
290	CONFIRMADA	REFERIDO	2024-11-29	538143.00	1043456987	STF03
313	CANCELADA	REDES SOCIALES	2021-05-31	0.00	1074295863	STF01
293	CONFIRMADA	REDES SOCIALES	2023-09-26	352907.00	1076123654	STF02
295	CONFIRMADA	LLAMADA TELEFONICA	2023-11-13	309780.00	1054987123	STF01
316	PENDIENTE	WHATSAPP	2019-10-21	0.00	1024759638	STF01
317	PENDIENTE	LLAMADA TELEFONICA	2020-07-26	0.00	1078364925	STF01
318	CANCELADA	REFERIDO	2019-03-31	0.00	1053826794	STF02
319	CANCELADA	WHATSAPP	2021-09-25	0.00	1092746835	STF01
320	PENDIENTE	LLAMADA TELEFONICA	2025-05-27	0.00	1037485962	STF03
321	CANCELADA	REDES SOCIALES	2023-03-04	0.00	1085372941	STF02
322	CANCELADA	CORREO	2023-08-01	0.00	1049638527	STF03
323	CANCELADA	WHATSAPP	2023-09-30	0.00	1076294853	STF03
324	PENDIENTE	WHATSAPP	2024-01-21	0.00	1042857396	STF03
325	PENDIENTE	LLAMADA TELEFONICA	2023-06-12	0.00	1088249637	STF01
326	PENDIENTE	LLAMADA TELEFONICA	2024-10-02	0.00	1034759628	STF02
327	CANCELADA	WHATSAPP	2019-01-30	0.00	1081637425	STF01
328	PENDIENTE	CORREO	2025-01-04	0.00	1056382947	STF01
300	CONFIRMADA	REDES SOCIALES	2024-04-14	352671.00	1023456789	STF03
330	CANCELADA	LLAMADA TELEFONICA	2024-06-20	0.00	1038462759	STF02
307	CONFIRMADA	WHATSAPP	2024-09-26	299293.00	1052847396	STF01
332	CANCELADA	WHATSAPP	2019-09-05	0.00	1047385926	STF01
333	CANCELADA	WHATSAPP	2023-08-28	0.00	1089472635	STF02
334	CANCELADA	LLAMADA TELEFONICA	2022-08-16	0.00	1025847396	STF03
335	CANCELADA	LLAMADA TELEFONICA	2022-06-19	0.00	1074628395	STF02
308	CONFIRMADA	CORREO	2023-11-08	366494.00	1084736291	STF03
337	CANCELADA	WHATSAPP	2019-09-26	0.00	1086274935	STF03
338	CANCELADA	REFERIDO	2021-11-08	0.00	1043758296	STF01
339	CANCELADA	REDES SOCIALES	2020-11-07	0.00	1091638527	STF02
340	CANCELADA	LLAMADA TELEFONICA	2022-04-02	0.00	1036829475	STF02
341	CANCELADA	CORREO	2023-10-05	0.00	1079485362	STF02
342	PENDIENTE	REFERIDO	2021-02-06	0.00	1048273659	STF03
343	PENDIENTE	REDES SOCIALES	2019-03-28	0.00	37331882	STF02
312	CONFIRMADA	REFERIDO	2024-10-31	495672.00	1063847291	STF03
345	PENDIENTE	LLAMADA TELEFONICA	2020-04-14	0.00	1054827396	STF02
346	PENDIENTE	LLAMADA TELEFONICA	2023-03-06	0.00	1093847625	STF03
347	CANCELADA	WHATSAPP	2019-08-20	0.00	1029473658	STF02
348	PENDIENTE	REFERIDO	2019-07-03	0.00	1076384925	STF02
314	CONFIRMADA	CORREO	2019-05-31	349896.00	1046829537	STF01
350	CANCELADA	REFERIDO	2019-05-18	0.00	1089374115	STF03
315	CONFIRMADA	CORREO	2020-02-01	298183.00	1089374625	STF01
352	CANCELADA	CORREO	2019-01-30	0.00	1084729635	STF02
329	CONFIRMADA	LLAMADA TELEFONICA	2019-07-21	361419.00	1095174862	STF03
354	CANCELADA	CORREO	2019-02-12	0.00	1092847365	STF03
355	PENDIENTE	REDES SOCIALES	2019-01-29	0.00	1927485962	STF01
356	CANCELADA	REDES SOCIALES	2019-01-20	0.00	1085729463	STF03
331	CONFIRMADA	REDES SOCIALES	2024-03-12	423629.00	1082749635	STF03
358	CANCELADA	WHATSAPP	2020-09-18	0.00	1098373335	STF01
336	CONFIRMADA	WHATSAPP	2021-08-31	534284.00	1051394827	STF01
360	PENDIENTE	REDES SOCIALES	2021-08-02	0.00	1087399925	STF01
361	PENDIENTE	WHATSAPP	2019-09-30	0.00	1052822396	STF02
362	PENDIENTE	CORREO	2021-01-02	0.00	1094738526	STF03
344	CONFIRMADA	REDES SOCIALES	2023-02-10	266261.00	1087394625	STF02
349	CONFIRMADA	WHATSAPP	2024-08-10	284950.00	1052947296	STF02
365	PENDIENTE	CORREO	2022-12-01	0.00	1047312346	STF03
366	PENDIENTE	REFERIDO	2022-03-24	0.00	1092842265	STF01
351	CONFIRMADA	LLAMADA TELEFONICA	2023-08-28	270851.00	1035829473	STF02
353	CONFIRMADA	WHATSAPP	2020-01-07	65415.00	1048293657	STF02
369	PENDIENTE	LLAMADA TELEFONICA	2021-03-31	0.00	1052839475	STF03
370	PENDIENTE	LLAMADA TELEFONICA	2021-02-07	0.00	1096384725	STF03
371	CANCELADA	REFERIDO	2024-09-18	0.00	1041738526	STF02
372	PENDIENTE	REDES SOCIALES	2024-01-21	0.00	1080914625	STF03
373	PENDIENTE	CORREO	2023-01-20	0.00	1036729485	STF02
357	CONFIRMADA	REDES SOCIALES	2024-01-16	523966.00	1053847296	STF02
375	PENDIENTE	REFERIDO	2024-09-14	0.00	1084123625	STF01
376	PENDIENTE	REFERIDO	2019-02-14	0.00	1058392746	STF02
377	CANCELADA	REFERIDO	2019-05-28	0.00	1091237625	STF02
359	CONFIRMADA	WHATSAPP	2024-05-27	236470.00	1034729888	STF03
379	CANCELADA	REDES SOCIALES	2023-06-16	0.00	1083249635	STF03
363	CONFIRMADA	REFERIDO	2025-03-18	123733.00	1038495762	STF02
381	PENDIENTE	LLAMADA TELEFONICA	2021-04-30	0.00	1096843725	STF02
382	CANCELADA	REDES SOCIALES	2022-11-22	0.00	1032749658	STF03
383	PENDIENTE	WHATSAPP	2019-07-17	0.00	1089234625	STF03
364	CONFIRMADA	REDES SOCIALES	2025-05-22	213764.00	1083749625	STF02
385	PENDIENTE	LLAMADA TELEFONICA	2024-01-21	0.00	1094123526	STF01
386	PENDIENTE	LLAMADA TELEFONICA	2023-05-18	0.00	1138495762	STF01
387	PENDIENTE	REDES SOCIALES	2023-08-30	0.00	1385739624	STF01
388	CANCELADA	WHATSAPP	2024-04-29	0.00	1092847296	STF01
391	CANCELADA	CORREO	2021-02-28	0.00	1043384925	STF03
392	CANCELADA	REDES SOCIALES	2024-01-13	0.00	1045758396	STF02
393	PENDIENTE	CORREO	2023-09-17	0.00	1089564625	STF03
394	CANCELADA	REFERIDO	2020-11-24	0.00	1035134463	STF03
395	PENDIENTE	LLAMADA TELEFONICA	2022-03-21	0.00	1082394625	STF03
396	CANCELADA	LLAMADA TELEFONICA	2025-02-05	0.00	1012349637	STF01
367	CONFIRMADA	CORREO	2022-05-04	77366.00	1035729463	STF02
368	CONFIRMADA	REDES SOCIALES	2025-01-12	454898.00	1087312925	STF03
374	CONFIRMADA	CORREO	2019-06-16	245322.00	1084739625	STF03
400	CANCELADA	WHATSAPP	2023-06-14	0.00	1047312926	STF03
378	CONFIRMADA	REDES SOCIALES	2019-04-16	104122.00	1037481212	STF03
402	CANCELADA	LLAMADA TELEFONICA	2019-01-23	0.00	1033329485	STF02
380	CONFIRMADA	REFERIDO	2022-09-14	535157.00	1112232659	STF02
384	CONFIRMADA	WHATSAPP	2020-11-17	268899.00	1047389026	STF02
405	PENDIENTE	REFERIDO	2024-07-15	0.00	1095847362	STF03
406	PENDIENTE	WHATSAPP	2024-08-01	0.00	1034829475	STF01
407	CANCELADA	REFERIDO	2023-03-10	0.00	1086391225	STF02
389	CONFIRMADA	WHATSAPP	2020-05-14	324118.00	1098373325	STF03
409	CANCELADA	WHATSAPP	2020-06-05	0.00	1007847296	STF02
410	CANCELADA	CORREO	2023-07-04	0.00	1098234625	STF02
411	CANCELADA	LLAMADA TELEFONICA	2019-05-04	0.00	1042758396	STF03
390	CONFIRMADA	WHATSAPP	2021-05-01	407031.00	88142897	STF01
413	CANCELADA	REDES SOCIALES	2021-05-07	0.00	1040238657	STF03
414	CANCELADA	REDES SOCIALES	2025-01-19	0.00	1025697841	STF02
415	PENDIENTE	REFERIDO	2024-06-26	0.00	1032456789	STF01
397	CONFIRMADA	LLAMADA TELEFONICA	2023-07-12	215577.00	1096374825	STF03
417	CANCELADA	WHATSAPP	2021-10-20	0.00	1051234567	STF01
418	PENDIENTE	CORREO	2021-01-08	0.00	1039876542	STF02
419	PENDIENTE	CORREO	2024-06-11	0.00	1047896321	STF02
420	PENDIENTE	REDES SOCIALES	2024-09-11	0.00	1028564973	STF03
421	CANCELADA	WHATSAPP	2023-11-18	0.00	1041759638	STF01
422	CANCELADA	REDES SOCIALES	2021-05-17	0.00	1036524789	STF01
398	CONFIRMADA	WHATSAPP	2023-06-22	222322.00	1038982762	STF01
424	PENDIENTE	REDES SOCIALES	2021-06-06	0.00	1029843756	STF01
399	CONFIRMADA	CORREO	2023-10-18	211140.00	1084719625	STF03
401	CONFIRMADA	REDES SOCIALES	2024-09-11	69950.00	1092347625	STF01
403	CONFIRMADA	LLAMADA TELEFONICA	2023-10-06	209950.00	1082748536	STF03
428	PENDIENTE	REFERIDO	2023-03-03	0.00	1046789125	STF03
404	CONFIRMADA	LLAMADA TELEFONICA	2022-10-12	275648.00	1049384726	STF02
408	CONFIRMADA	CORREO	2023-02-01	492671.00	107294625	STF03
431	PENDIENTE	LLAMADA TELEFONICA	2025-04-19	0.00	1042357896	STF03
432	CANCELADA	WHATSAPP	2019-07-31	0.00	1039654783	STF03
433	PENDIENTE	LLAMADA TELEFONICA	2025-04-17	0.00	1035789126	STF01
434	CANCELADA	REDES SOCIALES	2021-01-13	0.00	1048521369	STF03
412	CONFIRMADA	WHATSAPP	2024-03-27	244788.00	1007584920	STF01
436	CANCELADA	LLAMADA TELEFONICA	2019-06-29	0.00	1041236587	STF03
416	CONFIRMADA	LLAMADA TELEFONICA	2024-11-26	528938.00	1048765123	STF03
438	CANCELADA	WHATSAPP	2023-01-24	0.00	1043785642	STF03
423	CONFIRMADA	LLAMADA TELEFONICA	2021-07-10	68966.00	1044587123	STF01
425	CONFIRMADA	WHATSAPP	2019-12-27	380954.00	1038765412	STF01
441	PENDIENTE	REDES SOCIALES	2019-09-09	0.00	1032874569	STF01
426	CONFIRMADA	REFERIDO	2019-10-19	206660.00	1045123698	STF03
427	CONFIRMADA	WHATSAPP	2022-03-30	159298.00	1031678954	STF02
444	CANCELADA	WHATSAPP	2021-08-19	0.00	1031697854	STF01
445	PENDIENTE	CORREO	2025-02-21	0.00	1046283759	STF03
429	CONFIRMADA	REDES SOCIALES	2023-05-12	242951.00	1033456782	STF03
430	CONFIRMADA	LLAMADA TELEFONICA	2024-04-26	486389.00	1027895641	STF03
448	CANCELADA	WHATSAPP	2019-01-05	0.00	1041582736	STF02
449	PENDIENTE	CORREO	2023-03-27	0.00	1038467592	STF01
435	CONFIRMADA	REDES SOCIALES	2023-03-13	151169.00	1026874591	STF02
437	CONFIRMADA	REDES SOCIALES	2021-09-10	137322.00	1037458926	STF01
452	PENDIENTE	LLAMADA TELEFONICA	2025-05-15	0.00	1027841596	STF02
453	CANCELADA	LLAMADA TELEFONICA	2022-10-28	0.00	1043527896	STF01
454	CANCELADA	WHATSAPP	2020-09-29	0.00	1040896327	STF03
455	PENDIENTE	REFERIDO	2024-11-05	0.00	1036745892	STF03
456	PENDIENTE	LLAMADA TELEFONICA	2025-05-24	0.00	1028596374	STF02
457	PENDIENTE	WHATSAPP	2023-06-07	0.00	1044728159	STF01
458	CANCELADA	CORREO	2025-02-01	0.00	1031457896	STF01
459	PENDIENTE	WHATSAPP	2023-01-11	0.00	1037859641	STF01
460	CANCELADA	CORREO	2020-11-04	0.00	1043682597	STF02
461	PENDIENTE	REDES SOCIALES	2024-01-07	0.00	1029374856	STF02
462	CANCELADA	WHATSAPP	2020-08-25	0.00	1045896327	STF03
463	PENDIENTE	LLAMADA TELEFONICA	2020-10-30	0.00	1032741856	STF03
464	PENDIENTE	REFERIDO	2025-05-10	0.00	1038567423	STF01
465	PENDIENTE	CORREO	2020-12-12	0.00	1026849537	STF01
439	CONFIRMADA	LLAMADA TELEFONICA	2019-12-24	290995.00	1030159874	STF03
440	CONFIRMADA	REFERIDO	2019-05-27	112149.00	1045692837	STF02
468	PENDIENTE	WHATSAPP	2023-02-21	0.00	1035428697	STF02
442	CONFIRMADA	LLAMADA TELEFONICA	2022-04-30	258183.00	1028459367	STF02
470	PENDIENTE	CORREO	2021-07-31	0.00	1028563794	STF02
443	CONFIRMADA	WHATSAPP	2021-06-22	161261.00	1044176325	STF03
446	CONFIRMADA	CORREO	2020-07-03	81935.00	1033587462	STF03
473	CANCELADA	WHATSAPP	2021-09-26	0.00	1037452896	STF02
474	CANCELADA	LLAMADA TELEFONICA	2021-06-15	0.00	1043758962	STF02
475	CANCELADA	LLAMADA TELEFONICA	2025-01-22	0.00	1029637854	STF01
476	CANCELADA	CORREO	2023-12-27	0.00	1045896321	STF02
477	CANCELADA	CORREO	2021-03-22	0.00	1032574896	STF01
478	PENDIENTE	REDES SOCIALES	2021-05-26	0.00	1038695741	STF02
479	PENDIENTE	WHATSAPP	2022-10-08	0.00	1026745893	STF02
480	PENDIENTE	CORREO	2019-06-02	0.00	1041528367	STF03
481	PENDIENTE	REDES SOCIALES	2025-05-23	0.00	1037896524	STF02
447	CONFIRMADA	LLAMADA TELEFONICA	2023-04-24	359401.00	1029756841	STF01
483	PENDIENTE	CORREO	2025-03-20	0.00	1030485762	STF02
484	PENDIENTE	REFERIDO	2024-08-14	0.00	1046785932	STF01
485	PENDIENTE	REDES SOCIALES	2022-07-05	0.00	1033658947	STF01
486	PENDIENTE	CORREO	2024-01-26	0.00	1029745862	STF01
488	CANCELADA	REFERIDO	2023-04-14	0.00	1032874695	STF01
489	PENDIENTE	REDES SOCIALES	2021-03-18	0.00	1038675429	STF01
490	PENDIENTE	REFERIDO	2024-02-23	0.00	1026598734	STF01
491	CANCELADA	REFERIDO	2025-01-29	0.00	1042741856	STF03
493	PENDIENTE	REFERIDO	2024-10-07	0.00	1035896742	STF03
494	CANCELADA	REFERIDO	2019-03-14	0.00	1041758362	STF01
495	PENDIENTE	WHATSAPP	2025-05-15	0.00	1028647593	STF03
450	CONFIRMADA	LLAMADA TELEFONICA	2021-05-10	242053.00	1045728361	STF03
451	CONFIRMADA	LLAMADA TELEFONICA	2024-12-24	417149.00	1032659874	STF03
466	CONFIRMADA	LLAMADA TELEFONICA	2020-03-07	346261.00	1042185736	STF02
499	CANCELADA	CORREO	2021-09-29	0.00	1043785629	STF02
500	CANCELADA	REDES SOCIALES	2019-12-04	0.00	1030596387	STF03
501	PENDIENTE	REDES SOCIALES	2023-11-07	0.00	1037544920	STF03
467	CONFIRMADA	REDES SOCIALES	2024-06-14	96935.00	1039756842	STF01
469	CONFIRMADA	REDES SOCIALES	2021-01-07	190995.00	1041697825	STF02
504	CANCELADA	LLAMADA TELEFONICA	2023-06-06	0.00	1065432187	STF03
505	CANCELADA	REDES SOCIALES	2019-03-12	0.00	1032145698	STF03
506	CANCELADA	LLAMADA TELEFONICA	2025-04-03	0.00	1087452963	STF02
507	CANCELADA	WHATSAPP	2022-02-21	0.00	1054789632	STF01
508	PENDIENTE	CORREO	2019-05-27	0.00	1076543219	STF03
509	PENDIENTE	LLAMADA TELEFONICA	2021-06-07	0.00	1041258963	STF02
471	CONFIRMADA	REFERIDO	2021-08-08	417149.00	1044859672	STF01
472	CONFIRMADA	WHATSAPP	2022-11-24	231660.00	1031687452	STF02
482	CONFIRMADA	WHATSAPP	2023-06-23	98107.00	1043257896	STF01
513	PENDIENTE	LLAMADA TELEFONICA	2022-02-01	0.00	1048529637	STF03
487	CONFIRMADA	LLAMADA TELEFONICA	2021-06-25	253467.00	1045239687	STF03
515	PENDIENTE	CORREO	2023-02-15	0.00	1036741892	STF01
516	PENDIENTE	REFERIDO	2024-10-31	0.00	1081479632	STF02
517	PENDIENTE	REFERIDO	2021-10-27	0.00	1057896143	STF03
492	CONFIRMADA	REDES SOCIALES	2020-04-09	118228.00	1039527841	STF02
496	CONFIRMADA	LLAMADA TELEFONICA	2023-02-28	254374.00	1044526897	STF03
520	PENDIENTE	REDES SOCIALES	2020-11-15	0.00	1074185296	STF01
521	PENDIENTE	LLAMADA TELEFONICA	2021-06-05	0.00	1045827396	STF02
497	CONFIRMADA	REFERIDO	2022-02-06	367149.00	1031852796	STF03
523	CANCELADA	CORREO	2020-08-29	0.00	1051963847	STF03
524	CANCELADA	CORREO	2022-10-02	0.00	1098374625	STF03
498	CONFIRMADA	CORREO	2024-09-23	111247.00	1037698524	STF01
526	CANCELADA	REDES SOCIALES	2020-06-06	0.00	1086295174	STF03
502	CONFIRMADA	REFERIDO	2023-05-27	554262.00	1024756381	STF02
528	CANCELADA	LLAMADA TELEFONICA	2024-07-01	0.00	1091483627	STF03
503	CONFIRMADA	LLAMADA TELEFONICA	2025-03-03	361470.00	1098765432	STF03
530	PENDIENTE	REDES SOCIALES	2019-04-06	0.00	1075962843	STF02
531	CANCELADA	LLAMADA TELEFONICA	2023-08-08	0.00	1052847396	STF01
532	PENDIENTE	REFERIDO	2024-09-14	0.00	1084736291	STF02
533	CANCELADA	WHATSAPP	2022-10-28	0.00	1039627485	STF02
510	CONFIRMADA	LLAMADA TELEFONICA	2022-10-02	192053.00	1089634521	STF02
535	CANCELADA	REFERIDO	2023-11-01	0.00	1007529441	STF03
511	CONFIRMADA	LLAMADA TELEFONICA	2022-11-15	352375.00	1025874136	STF02
512	CONFIRMADA	WHATSAPP	2022-04-27	61470.00	1073658924	STF03
538	PENDIENTE	WHATSAPP	2020-07-20	0.00	1046829537	STF02
539	CANCELADA	CORREO	2021-11-23	0.00	1089374625	STF02
540	PENDIENTE	REFERIDO	2020-03-07	0.00	1024759638	STF02
541	CANCELADA	REDES SOCIALES	2022-02-28	0.00	1078364925	STF02
542	PENDIENTE	WHATSAPP	2022-11-01	0.00	1053826794	STF03
543	CANCELADA	WHATSAPP	2020-09-18	0.00	1092746835	STF02
544	CANCELADA	REFERIDO	2025-01-27	0.00	1037485962	STF03
545	CANCELADA	LLAMADA TELEFONICA	2020-02-03	0.00	1085372941	STF03
546	CANCELADA	REFERIDO	2020-04-17	0.00	1049638527	STF01
547	CANCELADA	WHATSAPP	2021-01-12	0.00	1076294853	STF02
548	CANCELADA	LLAMADA TELEFONICA	2023-11-22	0.00	1042857396	STF03
549	CANCELADA	REFERIDO	2021-06-01	0.00	1088249637	STF01
550	CANCELADA	WHATSAPP	2019-10-25	0.00	1034759628	STF02
551	CANCELADA	REDES SOCIALES	2023-08-20	0.00	1081637425	STF02
552	PENDIENTE	LLAMADA TELEFONICA	2020-04-08	0.00	1056382947	STF01
514	CONFIRMADA	REDES SOCIALES	2023-05-12	113764.00	1096325874	STF02
518	CONFIRMADA	WHATSAPP	2023-01-04	348278.00	1092583741	STF02
519	CONFIRMADA	WHATSAPP	2023-06-10	317671.00	1029637485	STF03
556	PENDIENTE	CORREO	2025-01-01	0.00	1047385926	STF02
557	CANCELADA	LLAMADA TELEFONICA	2020-09-19	0.00	1089472635	STF02
558	CANCELADA	LLAMADA TELEFONICA	2023-06-18	0.00	1025847396	STF03
559	PENDIENTE	REDES SOCIALES	2021-10-12	0.00	1074628395	STF03
560	PENDIENTE	REFERIDO	2019-04-12	0.00	1051394827	STF03
561	CANCELADA	REDES SOCIALES	2023-05-12	0.00	1086274935	STF01
562	PENDIENTE	WHATSAPP	2023-06-19	0.00	1043758296	STF02
563	CANCELADA	CORREO	2019-06-10	0.00	1091638527	STF02
564	PENDIENTE	WHATSAPP	2024-11-20	0.00	1036829475	STF01
565	PENDIENTE	WHATSAPP	2020-07-07	0.00	1079485362	STF01
566	CANCELADA	REFERIDO	2024-05-22	0.00	1048273659	STF03
567	PENDIENTE	REDES SOCIALES	2022-03-19	0.00	37331882	STF03
522	CONFIRMADA	CORREO	2019-04-08	66132.00	1087419635	STF01
569	CANCELADA	REFERIDO	2020-09-19	0.00	1054827396	STF03
570	PENDIENTE	WHATSAPP	2024-09-09	0.00	1093847625	STF01
571	CANCELADA	CORREO	2023-11-03	0.00	1029473658	STF02
572	PENDIENTE	REDES SOCIALES	2020-07-05	0.00	1076384925	STF01
573	PENDIENTE	REFERIDO	2024-04-02	0.00	1052947296	STF02
574	CANCELADA	WHATSAPP	2019-11-07	0.00	1089374115	STF03
575	CANCELADA	LLAMADA TELEFONICA	2023-08-10	0.00	1035829473	STF02
576	PENDIENTE	LLAMADA TELEFONICA	2019-10-14	0.00	1084729635	STF03
525	CONFIRMADA	CORREO	2021-10-19	131660.00	1033741852	STF01
578	PENDIENTE	WHATSAPP	2020-12-30	0.00	1092847365	STF02
527	CONFIRMADA	CORREO	2022-03-01	417149.00	1058149637	STF02
580	PENDIENTE	REFERIDO	2025-01-07	0.00	1085729463	STF03
581	PENDIENTE	REFERIDO	2021-11-10	0.00	1053847296	STF02
582	CANCELADA	CORREO	2022-05-06	0.00	1098373335	STF02
529	CONFIRMADA	WHATSAPP	2024-03-19	154171.00	1027395841	STF01
534	CONFIRMADA	WHATSAPP	2021-03-20	293183.00	1087529641	STF02
585	CANCELADA	CORREO	2020-05-25	0.00	1052822396	STF02
587	PENDIENTE	REFERIDO	2024-06-01	0.00	1038495762	STF03
589	CANCELADA	WHATSAPP	2024-03-10	0.00	1047312346	STF02
590	CANCELADA	LLAMADA TELEFONICA	2022-09-07	0.00	1092842265	STF03
592	CANCELADA	REFERIDO	2019-09-21	0.00	1087312925	STF01
593	PENDIENTE	REDES SOCIALES	2023-12-18	0.00	1052839475	STF01
594	PENDIENTE	CORREO	2019-11-14	0.00	1096384725	STF02
595	PENDIENTE	LLAMADA TELEFONICA	2022-03-23	0.00	1041738526	STF02
596	CANCELADA	CORREO	2024-08-09	0.00	1080914625	STF01
597	CANCELADA	WHATSAPP	2020-11-14	0.00	1036729485	STF03
598	PENDIENTE	WHATSAPP	2019-05-06	0.00	1084739625	STF03
599	PENDIENTE	LLAMADA TELEFONICA	2021-05-22	0.00	1084123625	STF01
536	CONFIRMADA	CORREO	2022-08-16	263677.00	1063847291	STF03
601	PENDIENTE	REDES SOCIALES	2021-03-30	0.00	1091237625	STF01
602	PENDIENTE	WHATSAPP	2024-10-11	0.00	1037481212	STF02
603	PENDIENTE	REFERIDO	2025-01-27	0.00	1083249635	STF01
537	CONFIRMADA	REFERIDO	2019-11-04	298373.00	1074295863	STF01
553	CONFIRMADA	REDES SOCIALES	2020-09-15	219162.00	1095174862	STF01
554	CONFIRMADA	WHATSAPP	2019-01-13	113764.00	1038462759	STF01
555	CONFIRMADA	REFERIDO	2025-01-07	392556.00	1082749635	STF01
608	CANCELADA	CORREO	2019-10-21	0.00	1047389026	STF03
609	CANCELADA	REFERIDO	2022-08-26	0.00	1094123526	STF02
610	PENDIENTE	REFERIDO	2022-07-28	0.00	1138495762	STF03
611	CANCELADA	LLAMADA TELEFONICA	2024-06-05	0.00	1385739624	STF03
612	CANCELADA	CORREO	2020-05-11	0.00	1092847296	STF03
568	CONFIRMADA	REFERIDO	2021-09-21	515414.00	1087394625	STF01
614	PENDIENTE	LLAMADA TELEFONICA	2022-12-23	0.00	88142897	STF03
615	PENDIENTE	REDES SOCIALES	2019-04-29	0.00	1043384925	STF03
616	PENDIENTE	CORREO	2020-02-17	0.00	1045758396	STF01
617	PENDIENTE	LLAMADA TELEFONICA	2024-07-13	0.00	1089564625	STF02
618	PENDIENTE	CORREO	2024-09-20	0.00	1035134463	STF02
619	PENDIENTE	WHATSAPP	2022-10-20	0.00	1082394625	STF03
577	CONFIRMADA	CORREO	2019-07-25	99837.00	1048293657	STF03
579	CONFIRMADA	REFERIDO	2021-06-03	238938.00	1927485962	STF03
622	PENDIENTE	WHATSAPP	2024-01-14	0.00	1038982762	STF02
583	CONFIRMADA	REDES SOCIALES	2019-02-19	102549.00	1034729888	STF02
584	CONFIRMADA	WHATSAPP	2020-03-11	41375.00	1087399925	STF02
625	PENDIENTE	CORREO	2020-10-15	0.00	1092347625	STF01
626	PENDIENTE	REDES SOCIALES	2024-11-19	0.00	1033329485	STF02
586	CONFIRMADA	REFERIDO	2024-02-16	176470.00	1094738526	STF02
628	CANCELADA	WHATSAPP	2020-04-21	0.00	1049384726	STF01
629	PENDIENTE	CORREO	2020-08-21	0.00	1095847362	STF01
630	PENDIENTE	LLAMADA TELEFONICA	2024-12-05	0.00	1034829475	STF03
588	CONFIRMADA	CORREO	2021-08-06	176470.00	1083749625	STF01
591	CONFIRMADA	WHATSAPP	2022-08-08	307549.00	1035729463	STF01
633	PENDIENTE	REDES SOCIALES	2023-08-27	0.00	1007847296	STF03
634	CANCELADA	CORREO	2021-04-10	0.00	1098234625	STF03
635	CANCELADA	LLAMADA TELEFONICA	2019-04-27	0.00	1042758396	STF01
636	PENDIENTE	CORREO	2021-04-13	0.00	1007584920	STF01
637	CANCELADA	WHATSAPP	2024-08-09	0.00	1040238657	STF03
638	CANCELADA	WHATSAPP	2019-07-08	0.00	1025697841	STF03
639	PENDIENTE	WHATSAPP	2019-03-08	0.00	1032456789	STF03
640	CANCELADA	LLAMADA TELEFONICA	2023-01-06	0.00	1048765123	STF01
641	CANCELADA	REDES SOCIALES	2025-01-12	0.00	1051234567	STF03
600	CONFIRMADA	CORREO	2019-06-18	291169.00	1058392746	STF01
604	CONFIRMADA	LLAMADA TELEFONICA	2024-01-25	364171.00	1112232659	STF02
605	CONFIRMADA	LLAMADA TELEFONICA	2024-12-22	137375.00	1096843725	STF02
645	PENDIENTE	CORREO	2019-08-25	0.00	1041759638	STF01
646	CANCELADA	REDES SOCIALES	2024-11-22	0.00	1036524789	STF02
647	CANCELADA	CORREO	2020-12-12	0.00	1044587123	STF01
648	CANCELADA	REFERIDO	2019-07-18	0.00	1029843756	STF02
606	CONFIRMADA	CORREO	2023-11-21	463351.00	1032749658	STF02
650	PENDIENTE	LLAMADA TELEFONICA	2024-08-04	0.00	1045123698	STF03
607	CONFIRMADA	WHATSAPP	2024-02-11	293872.00	1089234625	STF01
652	CANCELADA	REDES SOCIALES	2022-09-08	0.00	1046789125	STF03
653	PENDIENTE	CORREO	2019-08-31	0.00	1033456782	STF01
654	PENDIENTE	REDES SOCIALES	2024-11-17	0.00	1027895641	STF01
655	CANCELADA	CORREO	2024-02-06	0.00	1042357896	STF01
656	CANCELADA	REDES SOCIALES	2021-01-08	0.00	1039654783	STF02
657	CANCELADA	CORREO	2025-03-27	0.00	1035789126	STF01
658	CANCELADA	WHATSAPP	2021-06-16	0.00	1048521369	STF03
613	CONFIRMADA	WHATSAPP	2023-12-16	175648.00	1098373325	STF02
660	PENDIENTE	CORREO	2022-01-23	0.00	1041236587	STF02
661	PENDIENTE	REDES SOCIALES	2024-01-05	0.00	1037458926	STF03
662	CANCELADA	REDES SOCIALES	2020-06-29	0.00	1043785642	STF02
620	CONFIRMADA	REFERIDO	2022-02-19	553467.00	1012349637	STF01
664	CANCELADA	REDES SOCIALES	2022-02-26	0.00	1045692837	STF01
665	CANCELADA	CORREO	2019-07-30	0.00	1032874569	STF02
666	CANCELADA	WHATSAPP	2021-04-25	0.00	1028459367	STF02
667	CANCELADA	REDES SOCIALES	2024-12-06	0.00	1044176325	STF02
621	CONFIRMADA	LLAMADA TELEFONICA	2022-12-11	263373.00	1096374825	STF03
669	PENDIENTE	REDES SOCIALES	2020-01-26	0.00	1046283759	STF03
670	PENDIENTE	REDES SOCIALES	2022-12-09	0.00	1033587462	STF01
671	PENDIENTE	WHATSAPP	2020-11-14	0.00	1029756841	STF02
672	PENDIENTE	LLAMADA TELEFONICA	2024-03-29	0.00	1041582736	STF02
673	PENDIENTE	CORREO	2021-01-23	0.00	1038467592	STF01
674	PENDIENTE	CORREO	2021-07-16	0.00	1045728361	STF02
675	PENDIENTE	CORREO	2022-11-19	0.00	1032659874	STF01
676	PENDIENTE	CORREO	2023-04-14	0.00	1027841596	STF03
677	CANCELADA	REFERIDO	2020-01-19	0.00	1043527896	STF02
623	CONFIRMADA	CORREO	2023-03-10	253336.00	1084719625	STF03
624	CONFIRMADA	CORREO	2025-04-10	196935.00	1047312926	STF02
680	PENDIENTE	REDES SOCIALES	2022-02-18	0.00	1028596374	STF02
681	PENDIENTE	REFERIDO	2021-07-28	0.00	1044728159	STF01
627	CONFIRMADA	REFERIDO	2021-02-17	309788.00	1082748536	STF01
631	CONFIRMADA	REDES SOCIALES	2022-03-28	67556.00	1086391225	STF01
632	CONFIRMADA	CORREO	2024-02-18	386169.00	107294625	STF03
685	CANCELADA	REDES SOCIALES	2024-11-25	0.00	1029374856	STF03
686	PENDIENTE	LLAMADA TELEFONICA	2019-06-12	0.00	1045896327	STF03
642	CONFIRMADA	REDES SOCIALES	2024-09-22	373629.00	1039876542	STF01
643	CONFIRMADA	REDES SOCIALES	2025-01-14	81660.00	1047896321	STF03
689	CANCELADA	LLAMADA TELEFONICA	2024-03-01	0.00	1026849537	STF02
644	CONFIRMADA	WHATSAPP	2024-02-22	94284.00	1028564973	STF01
649	CONFIRMADA	REDES SOCIALES	2021-08-18	569124.00	1038765412	STF02
692	PENDIENTE	REFERIDO	2022-08-30	0.00	1035428697	STF02
651	CONFIRMADA	CORREO	2022-12-30	396666.00	1031678954	STF03
694	CANCELADA	REDES SOCIALES	2022-01-28	0.00	1028563794	STF02
659	CONFIRMADA	LLAMADA TELEFONICA	2021-02-15	507215.00	1026874591	STF02
698	PENDIENTE	LLAMADA TELEFONICA	2024-12-25	0.00	1043758962	STF03
699	PENDIENTE	WHATSAPP	2020-02-26	0.00	1029637854	STF02
663	CONFIRMADA	WHATSAPP	2021-01-12	148183.00	1030159874	STF01
701	CANCELADA	REDES SOCIALES	2023-01-09	0.00	1032574896	STF03
702	PENDIENTE	WHATSAPP	2020-04-07	0.00	1038695741	STF02
668	CONFIRMADA	REFERIDO	2021-12-18	371232.00	1031697854	STF01
704	CANCELADA	LLAMADA TELEFONICA	2021-04-26	0.00	1041528367	STF02
705	PENDIENTE	REDES SOCIALES	2024-07-05	0.00	1037896524	STF03
706	PENDIENTE	REDES SOCIALES	2022-04-18	0.00	1043257896	STF03
707	PENDIENTE	WHATSAPP	2025-01-25	0.00	1030485762	STF02
678	CONFIRMADA	REFERIDO	2019-03-08	94284.00	1040896327	STF01
709	PENDIENTE	REFERIDO	2023-07-17	0.00	1033658947	STF01
679	CONFIRMADA	REDES SOCIALES	2023-10-31	99837.00	1036745892	STF03
711	CANCELADA	CORREO	2023-11-30	0.00	1045239687	STF01
682	CONFIRMADA	REDES SOCIALES	2020-04-08	74293.00	1031457896	STF03
713	CANCELADA	WHATSAPP	2024-02-14	0.00	1038675429	STF02
714	PENDIENTE	CORREO	2023-05-23	0.00	1026598734	STF01
683	CONFIRMADA	REFERIDO	2020-11-17	225648.00	1037859641	STF02
684	CONFIRMADA	CORREO	2023-10-02	336840.00	1043682597	STF02
687	CONFIRMADA	REDES SOCIALES	2019-10-14	289124.00	1032741856	STF01
718	CANCELADA	LLAMADA TELEFONICA	2025-02-02	0.00	1041758362	STF01
719	PENDIENTE	REDES SOCIALES	2019-05-26	0.00	1028647593	STF01
688	CONFIRMADA	LLAMADA TELEFONICA	2020-06-20	493380.00	1038567423	STF03
721	PENDIENTE	REFERIDO	2021-09-29	0.00	1031852796	STF02
722	PENDIENTE	WHATSAPP	2019-07-24	0.00	1037698524	STF01
690	CONFIRMADA	REDES SOCIALES	2022-01-16	44560.00	1042185736	STF02
724	PENDIENTE	LLAMADA TELEFONICA	2020-04-08	0.00	1030596387	STF03
725	CANCELADA	CORREO	2023-08-23	0.00	1046258973	STF03
691	CONFIRMADA	LLAMADA TELEFONICA	2024-02-20	221169.00	1039756842	STF01
693	CONFIRMADA	LLAMADA TELEFONICA	2019-10-14	93134.00	1041697825	STF01
695	CONFIRMADA	REFERIDO	2021-05-31	167741.00	1044859672	STF02
729	CANCELADA	REFERIDO	2021-12-10	0.00	1032568749	STF02
730	PENDIENTE	LLAMADA TELEFONICA	2025-05-19	0.00	1038457296	STF01
731	CANCELADA	LLAMADA TELEFONICA	2020-03-06	0.00	1026745832	STF01
732	CANCELADA	WHATSAPP	2019-07-18	0.00	1041856739	STF03
696	CONFIRMADA	WHATSAPP	2022-09-30	326247.00	1031687452	STF02
734	PENDIENTE	REDES SOCIALES	2024-10-23	0.00	1043687524	STF02
697	CONFIRMADA	REFERIDO	2019-04-23	521389.00	1037452896	STF02
736	CANCELADA	WHATSAPP	2020-07-23	0.00	1046785923	STF02
737	CANCELADA	WHATSAPP	2020-12-29	0.00	1033576842	STF01
700	CONFIRMADA	LLAMADA TELEFONICA	2019-09-22	83183.00	1045896321	STF01
739	CANCELADA	REDES SOCIALES	2024-12-14	0.00	1092692837	STF03
740	CANCELADA	CORREO	2020-03-17	0.00	1725139428	STF02
741	CANCELADA	LLAMADA TELEFONICA	2022-06-28	0.00	1183328812	STF02
742	PENDIENTE	REFERIDO	2019-04-23	0.00	1929839528	STF03
703	CONFIRMADA	REFERIDO	2021-04-05	153336.00	1026745893	STF03
744	PENDIENTE	WHATSAPP	2022-03-21	0.00	1230931647	STF01
745	CANCELADA	WHATSAPP	2024-01-07	0.00	1884331481	STF03
746	PENDIENTE	LLAMADA TELEFONICA	2025-04-21	0.00	1935770226	STF02
747	PENDIENTE	REFERIDO	2020-03-19	0.00	1202533744	STF02
708	CONFIRMADA	CORREO	2021-10-06	402651.00	1046785932	STF01
749	PENDIENTE	REDES SOCIALES	2021-10-18	0.00	1478116328	STF03
710	CONFIRMADA	REDES SOCIALES	2024-01-09	293134.00	1029745862	STF02
712	CONFIRMADA	WHATSAPP	2025-01-20	94010.00	1032874695	STF02
752	CANCELADA	WHATSAPP	2022-05-01	0.00	1047475612	STF03
753	CANCELADA	WHATSAPP	2019-01-22	0.00	1464574808	STF01
715	CONFIRMADA	WHATSAPP	2022-02-12	329118.00	1042741856	STF02
755	PENDIENTE	LLAMADA TELEFONICA	2023-01-04	0.00	1631956907	STF01
756	PENDIENTE	CORREO	2022-09-12	0.00	1787501891	STF03
757	CANCELADA	REFERIDO	2020-02-24	0.00	1041975258	STF01
758	PENDIENTE	REDES SOCIALES	2019-08-14	0.00	1778141926	STF02
716	CONFIRMADA	LLAMADA TELEFONICA	2019-08-25	425672.00	1039527841	STF03
760	PENDIENTE	LLAMADA TELEFONICA	2022-08-11	0.00	1167386679	STF01
761	PENDIENTE	WHATSAPP	2021-04-26	0.00	1422314667	STF03
762	PENDIENTE	CORREO	2019-10-09	0.00	1490844569	STF02
717	CONFIRMADA	REFERIDO	2024-05-26	284898.00	1035896742	STF02
764	PENDIENTE	REDES SOCIALES	2022-08-22	0.00	1666421753	STF03
720	CONFIRMADA	CORREO	2019-08-30	36247.00	1044526897	STF03
766	PENDIENTE	REDES SOCIALES	2019-06-12	0.00	1193115306	STF03
723	CONFIRMADA	CORREO	2024-04-26	43733.00	1043785629	STF02
726	CONFIRMADA	LLAMADA TELEFONICA	2019-08-14	553467.00	1033587426	STF02
769	PENDIENTE	LLAMADA TELEFONICA	2020-12-21	0.00	1864093182	STF01
770	CANCELADA	LLAMADA TELEFONICA	2019-06-16	0.00	1416137157	STF01
771	PENDIENTE	REDES SOCIALES	2024-10-04	0.00	1083528498	STF03
772	CANCELADA	LLAMADA TELEFONICA	2022-09-29	0.00	1419417107	STF01
773	PENDIENTE	WHATSAPP	2019-09-21	0.00	1270386383	STF01
727	CONFIRMADA	WHATSAPP	2021-02-11	383966.00	1029847651	STF01
775	PENDIENTE	CORREO	2024-04-12	0.00	1405864092	STF03
776	CANCELADA	CORREO	2022-06-23	0.00	1343929963	STF03
777	PENDIENTE	CORREO	2024-05-08	0.00	1045516867	STF01
778	PENDIENTE	WHATSAPP	2023-10-19	0.00	1918835899	STF01
779	PENDIENTE	LLAMADA TELEFONICA	2020-12-30	0.00	1127901676	STF03
780	PENDIENTE	WHATSAPP	2019-12-24	0.00	1454657901	STF02
728	CONFIRMADA	WHATSAPP	2020-09-30	497149.00	1045697382	STF02
782	PENDIENTE	WHATSAPP	2023-06-12	0.00	1593506873	STF02
783	CANCELADA	LLAMADA TELEFONICA	2022-02-13	0.00	1682502627	STF02
784	CANCELADA	LLAMADA TELEFONICA	2025-01-26	0.00	1680095673	STF02
786	CANCELADA	REDES SOCIALES	2022-03-13	0.00	1415109500	STF03
787	CANCELADA	LLAMADA TELEFONICA	2024-06-13	0.00	1605462995	STF01
788	PENDIENTE	LLAMADA TELEFONICA	2023-07-28	0.00	1089252687	STF01
789	CANCELADA	WHATSAPP	2023-03-23	0.00	1076374647	STF02
790	CANCELADA	REFERIDO	2019-09-02	0.00	1054216554	STF03
792	PENDIENTE	LLAMADA TELEFONICA	2019-04-21	0.00	1864383026	STF03
794	PENDIENTE	LLAMADA TELEFONICA	2025-01-28	0.00	1263427561	STF01
795	CANCELADA	WHATSAPP	2019-03-16	0.00	1537584488	STF01
796	PENDIENTE	REDES SOCIALES	2020-02-05	0.00	1344786348	STF01
733	CONFIRMADA	REFERIDO	2024-05-17	71935.00	1037952684	STF03
798	CANCELADA	CORREO	2019-12-09	0.00	1203968909	STF01
735	CONFIRMADA	REDES SOCIALES	2021-05-04	393134.00	1030482597	STF02
738	CONFIRMADA	LLAMADA TELEFONICA	2020-12-03	97907.00	1029485736	STF03
801	CANCELADA	LLAMADA TELEFONICA	2023-10-10	0.00	1218506523	STF02
802	PENDIENTE	LLAMADA TELEFONICA	2020-05-25	0.00	1111671499	STF01
803	CANCELADA	REDES SOCIALES	2021-09-26	0.00	1020921984	STF01
804	PENDIENTE	REDES SOCIALES	2021-02-09	0.00	1223998980	STF03
743	CONFIRMADA	LLAMADA TELEFONICA	2023-05-22	393373.00	1312469894	STF03
806	PENDIENTE	CORREO	2020-08-16	0.00	1669253556	STF01
748	CONFIRMADA	CORREO	2023-01-15	339099.00	1785969923	STF01
808	CANCELADA	WHATSAPP	2024-08-29	0.00	1022592522	STF02
809	CANCELADA	CORREO	2020-02-18	0.00	1757397091	STF03
810	PENDIENTE	LLAMADA TELEFONICA	2024-04-07	0.00	1386018072	STF02
811	CANCELADA	CORREO	2021-02-17	0.00	1917356957	STF01
812	CANCELADA	REDES SOCIALES	2023-10-28	0.00	1091038072	STF03
813	CANCELADA	REDES SOCIALES	2019-03-13	0.00	1812553699	STF01
814	CANCELADA	REFERIDO	2021-04-15	0.00	1399626520	STF01
815	CANCELADA	LLAMADA TELEFONICA	2020-05-18	0.00	1741759367	STF01
816	PENDIENTE	CORREO	2020-07-27	0.00	1655318354	STF02
817	CANCELADA	REFERIDO	2023-04-19	0.00	1968889416	STF01
818	PENDIENTE	REDES SOCIALES	2024-08-23	0.00	1538597770	STF01
750	CONFIRMADA	WHATSAPP	2021-04-25	116840.00	1959657063	STF03
751	CONFIRMADA	LLAMADA TELEFONICA	2023-10-26	58966.00	1114508860	STF01
821	CANCELADA	LLAMADA TELEFONICA	2021-12-24	0.00	1641274057	STF02
822	PENDIENTE	CORREO	2021-08-14	0.00	1236084614	STF02
823	CANCELADA	WHATSAPP	2020-08-18	0.00	1685381052	STF01
824	PENDIENTE	REFERIDO	2021-11-23	0.00	1039703861	STF01
825	CANCELADA	CORREO	2022-12-14	0.00	1253475646	STF02
826	CANCELADA	REFERIDO	2021-10-08	0.00	1259854800	STF02
827	CANCELADA	REFERIDO	2019-10-08	0.00	1204561555	STF03
828	PENDIENTE	LLAMADA TELEFONICA	2020-02-16	0.00	1100836481	STF01
754	CONFIRMADA	CORREO	2024-07-25	153488.00	1242388377	STF01
830	CANCELADA	LLAMADA TELEFONICA	2022-02-20	0.00	1551707633	STF03
759	CONFIRMADA	WHATSAPP	2020-11-20	118344.00	1417980671	STF02
832	PENDIENTE	WHATSAPP	2019-02-15	0.00	1300931839	STF01
763	CONFIRMADA	REFERIDO	2024-10-29	449262.00	1605295501	STF02
765	CONFIRMADA	CORREO	2020-04-12	319374.00	1510277087	STF03
767	CONFIRMADA	REFERIDO	2021-04-09	284780.00	1102820213	STF01
836	PENDIENTE	WHATSAPP	2019-07-05	0.00	1933729913	STF02
837	PENDIENTE	REDES SOCIALES	2022-07-30	0.00	1596399157	STF02
838	PENDIENTE	REFERIDO	2023-12-14	0.00	1881638781	STF01
768	CONFIRMADA	LLAMADA TELEFONICA	2021-09-02	276644.00	1675143007	STF02
840	PENDIENTE	CORREO	2019-07-16	0.00	1166861277	STF03
841	CANCELADA	WHATSAPP	2020-04-07	0.00	1640749632	STF03
842	PENDIENTE	REDES SOCIALES	2020-08-12	0.00	1838819285	STF01
774	CONFIRMADA	REDES SOCIALES	2023-10-18	532366.00	1842029766	STF01
781	CONFIRMADA	REFERIDO	2020-12-31	207951.00	1484247160	STF03
785	CONFIRMADA	WHATSAPP	2022-07-10	569162.00	1542093722	STF02
846	PENDIENTE	LLAMADA TELEFONICA	2021-07-28	0.00	1808469970	STF02
847	CANCELADA	WHATSAPP	2022-01-19	0.00	1897920692	STF01
848	PENDIENTE	LLAMADA TELEFONICA	2019-12-16	0.00	1058108381	STF03
849	CANCELADA	WHATSAPP	2023-07-06	0.00	1232317863	STF03
850	CANCELADA	REFERIDO	2022-05-31	0.00	1725308984	STF02
851	CANCELADA	CORREO	2023-01-31	0.00	1628870403	STF03
852	CANCELADA	CORREO	2021-04-24	0.00	1720359248	STF01
791	CONFIRMADA	WHATSAPP	2021-03-04	269560.00	1142491485	STF02
793	CONFIRMADA	CORREO	2023-06-06	104837.00	1934510055	STF03
855	PENDIENTE	LLAMADA TELEFONICA	2024-12-22	0.00	1922128577	STF02
856	CANCELADA	LLAMADA TELEFONICA	2020-07-17	0.00	1580029091	STF01
857	PENDIENTE	REFERIDO	2021-02-19	0.00	1405817763	STF02
797	CONFIRMADA	WHATSAPP	2023-02-15	542215.00	1814404528	STF02
859	CANCELADA	LLAMADA TELEFONICA	2023-12-21	0.00	1280389928	STF03
860	CANCELADA	REDES SOCIALES	2024-11-17	0.00	1471771788	STF01
799	CONFIRMADA	REDES SOCIALES	2021-02-15	92215.00	1045396340	STF03
862	CANCELADA	CORREO	2024-06-16	0.00	1753463126	STF03
863	CANCELADA	REDES SOCIALES	2019-03-31	0.00	1960618335	STF03
864	PENDIENTE	WHATSAPP	2023-07-05	0.00	1065761959	STF02
865	PENDIENTE	CORREO	2019-04-06	0.00	1481708505	STF02
800	CONFIRMADA	REFERIDO	2024-05-06	329837.00	1030621593	STF02
867	CANCELADA	LLAMADA TELEFONICA	2025-05-10	0.00	1929124097	STF02
868	CANCELADA	WHATSAPP	2022-02-26	0.00	1996779429	STF01
869	PENDIENTE	CORREO	2022-02-02	0.00	1788276940	STF03
870	CANCELADA	REFERIDO	2022-08-14	0.00	1683880178	STF01
871	CANCELADA	WHATSAPP	2025-01-13	0.00	1300201589	STF02
872	PENDIENTE	CORREO	2021-08-04	0.00	1638945776	STF03
873	CANCELADA	WHATSAPP	2020-03-23	0.00	1125677966	STF01
874	CANCELADA	CORREO	2024-11-09	0.00	1303756905	STF02
875	PENDIENTE	REFERIDO	2020-07-16	0.00	1593822136	STF02
805	CONFIRMADA	LLAMADA TELEFONICA	2023-06-23	308278.00	1576176978	STF03
807	CONFIRMADA	WHATSAPP	2023-07-19	260577.00	1892293961	STF01
878	PENDIENTE	REDES SOCIALES	2021-02-25	0.00	1283191065	STF01
879	PENDIENTE	LLAMADA TELEFONICA	2023-10-04	0.00	1508223094	STF03
880	CANCELADA	WHATSAPP	2024-11-27	0.00	1270949634	STF01
819	CONFIRMADA	CORREO	2022-03-21	117149.00	1353558033	STF02
882	PENDIENTE	REDES SOCIALES	2021-11-30	0.00	1548337558	STF02
820	CONFIRMADA	WHATSAPP	2020-11-03	197031.00	1755312066	STF03
829	CONFIRMADA	CORREO	2021-03-20	543733.00	1138875185	STF02
831	CONFIRMADA	CORREO	2020-07-17	282549.00	1469092671	STF01
886	PENDIENTE	WHATSAPP	2019-10-11	0.00	1838247372	STF02
887	PENDIENTE	WHATSAPP	2022-09-30	0.00	1679787577	STF02
833	CONFIRMADA	CORREO	2020-04-26	542741.00	1123271973	STF01
889	PENDIENTE	CORREO	2019-04-19	0.00	1234227944	STF01
890	PENDIENTE	CORREO	2019-09-28	0.00	1314202958	STF02
891	CANCELADA	REFERIDO	2022-04-14	0.00	1251058824	STF03
892	CANCELADA	LLAMADA TELEFONICA	2023-01-21	0.00	1193211969	STF03
893	CANCELADA	WHATSAPP	2024-10-14	0.00	1735671925	STF01
894	CANCELADA	LLAMADA TELEFONICA	2021-03-22	0.00	1355918173	STF03
895	CANCELADA	REDES SOCIALES	2019-11-14	0.00	1507445443	STF02
897	PENDIENTE	REDES SOCIALES	2020-04-24	0.00	1352517204	STF01
898	CANCELADA	WHATSAPP	2024-05-04	0.00	1720509893	STF03
899	PENDIENTE	LLAMADA TELEFONICA	2020-11-16	0.00	1656027058	STF01
900	PENDIENTE	CORREO	2022-03-18	0.00	1083932272	STF02
901	PENDIENTE	WHATSAPP	2021-06-17	0.00	1291247389	STF02
834	CONFIRMADA	WHATSAPP	2025-01-22	93373.00	1683530870	STF03
903	PENDIENTE	REDES SOCIALES	2019-02-21	0.00	1399301476	STF01
904	PENDIENTE	REFERIDO	2021-06-18	0.00	1443675929	STF01
905	PENDIENTE	REFERIDO	2021-04-14	0.00	1654588046	STF01
906	PENDIENTE	REDES SOCIALES	2024-06-08	0.00	1423799052	STF02
907	CANCELADA	REFERIDO	2020-01-14	0.00	1003790393	STF03
908	PENDIENTE	WHATSAPP	2023-09-24	0.00	1125599413	STF02
835	CONFIRMADA	LLAMADA TELEFONICA	2025-01-12	268733.00	1790967203	STF01
910	PENDIENTE	LLAMADA TELEFONICA	2024-08-31	0.00	1171457990	STF01
911	CANCELADA	REFERIDO	2020-05-25	0.00	1938753343	STF03
912	CANCELADA	CORREO	2024-12-26	0.00	1331041751	STF03
913	CANCELADA	REFERIDO	2024-09-24	0.00	1211167169	STF01
914	PENDIENTE	LLAMADA TELEFONICA	2024-11-23	0.00	1753313643	STF01
915	CANCELADA	REDES SOCIALES	2021-08-21	0.00	1729810007	STF01
916	PENDIENTE	CORREO	2025-02-05	0.00	1755776771	STF01
839	CONFIRMADA	CORREO	2023-04-27	363176.00	1356258550	STF01
918	PENDIENTE	WHATSAPP	2020-10-20	0.00	1746164254	STF01
919	CANCELADA	WHATSAPP	2023-11-30	0.00	1625602835	STF02
920	PENDIENTE	REFERIDO	2023-03-20	0.00	1224498048	STF03
921	PENDIENTE	CORREO	2022-08-29	0.00	1833508236	STF02
922	CANCELADA	CORREO	2021-11-25	0.00	1866149035	STF03
843	CONFIRMADA	REDES SOCIALES	2021-08-04	286247.00	1601928849	STF03
924	CANCELADA	LLAMADA TELEFONICA	2019-01-04	0.00	1853233955	STF03
925	PENDIENTE	REFERIDO	2019-02-05	0.00	1438677097	STF03
844	CONFIRMADA	WHATSAPP	2020-01-02	123183.00	1208622456	STF02
927	PENDIENTE	CORREO	2021-08-05	0.00	1263203026	STF03
928	CANCELADA	REDES SOCIALES	2019-05-24	0.00	1165956354	STF02
845	CONFIRMADA	LLAMADA TELEFONICA	2019-02-17	215598.00	1169722277	STF02
930	CANCELADA	REDES SOCIALES	2020-09-29	0.00	1945386662	STF01
931	CANCELADA	WHATSAPP	2024-02-02	0.00	1796116097	STF02
932	CANCELADA	REDES SOCIALES	2024-03-05	0.00	1067635015	STF03
933	CANCELADA	WHATSAPP	2019-04-13	0.00	1231108263	STF01
934	CANCELADA	CORREO	2024-11-23	0.00	1146134107	STF01
935	CANCELADA	WHATSAPP	2023-03-20	0.00	1837224001	STF02
853	CONFIRMADA	CORREO	2021-07-13	464284.00	1371272857	STF03
937	PENDIENTE	LLAMADA TELEFONICA	2022-09-19	0.00	1115673167	STF03
938	PENDIENTE	WHATSAPP	2020-01-16	0.00	1020310398	STF03
939	CANCELADA	CORREO	2020-07-10	0.00	1815004195	STF03
854	CONFIRMADA	REDES SOCIALES	2020-03-20	68733.00	1970406429	STF01
858	CONFIRMADA	REDES SOCIALES	2019-07-02	541375.00	1517118152	STF02
942	PENDIENTE	LLAMADA TELEFONICA	2020-04-26	0.00	1180598299	STF02
943	PENDIENTE	WHATSAPP	2022-10-01	0.00	1222220742	STF03
861	CONFIRMADA	LLAMADA TELEFONICA	2025-01-31	139788.00	1944698152	STF01
866	CONFIRMADA	REDES SOCIALES	2023-06-17	114284.00	1802030577	STF03
946	PENDIENTE	REFERIDO	2023-03-18	0.00	1300538656	STF01
876	CONFIRMADA	REFERIDO	2022-11-17	291140.00	1873044318	STF02
948	PENDIENTE	REDES SOCIALES	2021-10-17	0.00	1681289427	STF03
877	CONFIRMADA	REDES SOCIALES	2025-02-16	397156.00	1391572838	STF03
950	PENDIENTE	REDES SOCIALES	2023-01-04	0.00	1554798202	STF01
951	PENDIENTE	REDES SOCIALES	2022-09-30	0.00	1177638502	STF01
952	CANCELADA	REFERIDO	2025-04-11	0.00	1382835172	STF03
953	PENDIENTE	REDES SOCIALES	2022-03-04	0.00	1768778021	STF02
881	CONFIRMADA	REDES SOCIALES	2023-04-18	140577.00	1248174096	STF01
955	CANCELADA	REDES SOCIALES	2019-03-30	0.00	1329515246	STF02
883	CONFIRMADA	REDES SOCIALES	2019-05-30	503176.00	1245989685	STF02
957	CANCELADA	REFERIDO	2020-01-04	0.00	1381026101	STF03
884	CONFIRMADA	REFERIDO	2021-03-24	118677.00	1809933012	STF02
959	CANCELADA	WHATSAPP	2019-12-06	0.00	1054122280	STF01
885	CONFIRMADA	REDES SOCIALES	2023-07-10	221935.00	1269935678	STF01
961	PENDIENTE	REFERIDO	2023-10-02	0.00	1749163283	STF01
962	CANCELADA	REFERIDO	2020-07-14	0.00	1038861012	STF03
888	CONFIRMADA	REDES SOCIALES	2022-01-28	334560.00	1371024237	STF01
964	PENDIENTE	CORREO	2021-04-19	0.00	1634289995	STF01
965	PENDIENTE	REFERIDO	2019-07-14	0.00	1659896058	STF01
966	CANCELADA	REFERIDO	2019-08-26	0.00	1962244664	STF01
967	PENDIENTE	LLAMADA TELEFONICA	2023-01-15	0.00	1728689252	STF01
968	PENDIENTE	LLAMADA TELEFONICA	2022-02-07	0.00	1602720554	STF03
896	CONFIRMADA	REDES SOCIALES	2022-09-11	210322.00	1124818705	STF01
970	CANCELADA	LLAMADA TELEFONICA	2021-01-20	0.00	1012802155	STF01
971	CANCELADA	REFERIDO	2023-03-02	0.00	1194704269	STF01
972	CANCELADA	WHATSAPP	2019-06-20	0.00	1341234686	STF03
902	CONFIRMADA	REDES SOCIALES	2024-08-22	353538.00	1338848584	STF02
974	CANCELADA	LLAMADA TELEFONICA	2025-02-27	0.00	1752062831	STF02
1016	CONFIRMADA	REFERIDO	2025-04-14	504099.00	1076321098	STF01
976	PENDIENTE	CORREO	2022-05-12	0.00	1115439806	STF02
1017	CONFIRMADA	CORREO	2020-09-25	247494.00	1043659871	STF02
978	PENDIENTE	WHATSAPP	2024-03-16	0.00	1572760719	STF02
979	CANCELADA	WHATSAPP	2024-06-30	0.00	1102314457	STF01
1018	CONFIRMADA	REFERIDO	2020-04-09	554988.00	1065987412	STF03
981	PENDIENTE	CORREO	2022-01-05	0.00	1946415469	STF01
982	PENDIENTE	CORREO	2024-08-26	0.00	1937598799	STF02
983	CANCELADA	REFERIDO	2021-10-03	0.00	1629949814	STF02
1019	CONFIRMADA	REDES SOCIALES	2023-04-30	542732.00	1087321654	STF02
1020	CONFIRMADA	WHATSAPP	2022-11-23	336468.00	1076987654	STF02
986	CANCELADA	LLAMADA TELEFONICA	2020-12-20	0.00	1659843290	STF01
987	CANCELADA	WHATSAPP	2022-10-06	0.00	1373516410	STF03
1021	CONFIRMADA	REDES SOCIALES	2020-12-06	342149.00	1032453389	STF02
989	PENDIENTE	LLAMADA TELEFONICA	2024-10-24	0.00	1635418500	STF02
991	PENDIENTE	CORREO	2020-06-16	0.00	1721355935	STF02
993	CANCELADA	REFERIDO	2020-07-23	0.00	1419876028	STF03
994	CANCELADA	LLAMADA TELEFONICA	2021-11-14	0.00	1359118468	STF03
995	CANCELADA	REDES SOCIALES	2019-04-20	0.00	1407630662	STF03
996	CANCELADA	CORREO	2022-10-28	0.00	1640553597	STF03
997	CANCELADA	WHATSAPP	2020-02-15	0.00	1072141457	STF03
998	PENDIENTE	LLAMADA TELEFONICA	2020-12-13	0.00	1079475888	STF03
16	CONFIRMADA	WHATSAPP	2020-06-26	95851.00	1037588220	STF03
17	CONFIRMADA	CORREO	2019-11-19	386764.00	1025678432	STF03
1022	CONFIRMADA	LLAMADA TELEFONICA	2022-07-02	155415.00	1087456123	STF02
1023	CONFIRMADA	LLAMADA TELEFONICA	2022-03-04	207549.00	1065456987	STF02
1024	CONFIRMADA	WHATSAPP	2019-10-13	87322.00	1076234567	STF01
1025	CONFIRMADA	LLAMADA TELEFONICA	2021-08-29	331389.00	1054789012	STF03
1026	CONFIRMADA	REFERIDO	2021-06-21	261169.00	1043567890	STF02
1027	CONFIRMADA	CORREO	2022-12-24	268733.00	1076789012	STF02
1028	CONFIRMADA	REFERIDO	2023-12-25	56660.00	1098456789	STF03
1029	CONFIRMADA	LLAMADA TELEFONICA	2023-06-05	298373.00	1054567890	STF02
1030	CONFIRMADA	LLAMADA TELEFONICA	2020-11-20	148176.00	1065789123	STF03
1031	CONFIRMADA	WHATSAPP	2023-06-15	261494.00	1098789456	STF02
1032	CONFIRMADA	CORREO	2022-01-31	366364.00	1087456789	STF02
1033	CONFIRMADA	REDES SOCIALES	2019-04-15	120299.00	1091234567	STF02
1034	CONFIRMADA	REFERIDO	2019-10-21	542651.00	1065432876	STF01
1035	CONFIRMADA	WHATSAPP	2021-11-06	155954.00	1076890123	STF02
1036	CONFIRMADA	REFERIDO	2022-01-21	388380.00	1098567321	STF02
1037	CONFIRMADA	CORREO	2020-07-25	55305.00	1087789654	STF02
1038	CONFIRMADA	REFERIDO	2022-11-26	388677.00	1065123789	STF02
1039	CONFIRMADA	CORREO	2021-03-28	457671.00	1076321654	STF02
1040	CONFIRMADA	REDES SOCIALES	2024-11-02	65598.00	1098654123	STF03
1041	CONFIRMADA	REFERIDO	2019-01-10	239837.00	1054987324	STF03
1042	CONFIRMADA	CORREO	2024-08-23	238467.00	1087321987	STF01
1043	CONFIRMADA	LLAMADA TELEFONICA	2024-07-08	373344.00	1043789321	STF02
1044	CONFIRMADA	WHATSAPP	2022-11-23	72156.00	1076123987	STF03
1045	CONFIRMADA	CORREO	2021-08-18	168351.00	1098321789	STF03
1046	CONFIRMADA	WHATSAPP	2023-01-12	208278.00	AB1234567	STF03
1047	CONFIRMADA	LLAMADA TELEFONICA	2022-06-06	134788.00	1054456789	STF01
1048	CONFIRMADA	REDES SOCIALES	2019-05-17	556644.00	1087123987	STF02
1049	CONFIRMADA	REDES SOCIALES	2019-06-03	504904.00	1043654321	STF03
1050	CONFIRMADA	LLAMADA TELEFONICA	2024-02-04	419898.00	1065789456	STF03
1051	CONFIRMADA	LLAMADA TELEFONICA	2020-02-01	221840.00	1076654987	STF01
1052	CONFIRMADA	CORREO	2020-11-07	121666.00	1098456321	STF03
1053	CONFIRMADA	LLAMADA TELEFONICA	2024-01-29	114162.00	1054123654	STF02
1054	CONFIRMADA	REDES SOCIALES	2025-04-24	214599.00	1087987321	STF01
1055	CONFIRMADA	LLAMADA TELEFONICA	2025-05-08	309817.00	1043567321	STF03
1056	CONFIRMADA	WHATSAPP	2022-03-06	65402.00	1098123987	STF01
1057	CONFIRMADA	WHATSAPP	2021-10-22	220806.00	12345678	STF03
1058	CONFIRMADA	CORREO	2019-01-15	169345.00	1087456987	STF01
1059	CONFIRMADA	LLAMADA TELEFONICA	2022-12-13	131372.00	1043321654	STF01
1060	CONFIRMADA	REFERIDO	2019-09-07	171052.00	1065654987	STF01
1061	CONFIRMADA	REFERIDO	2024-08-03	188385.00	1076456321	STF01
1062	CONFIRMADA	CORREO	2022-07-31	397515.00	1098789654	STF01
1063	CONFIRMADA	REFERIDO	2020-06-02	320672.00	1054321789	STF02
1064	CONFIRMADA	REFERIDO	2020-11-25	183585.00	1065123456	STF02
1065	CONFIRMADA	WHATSAPP	2025-01-18	272705.00	1076987123	STF02
1066	CONFIRMADA	CORREO	2019-02-15	269753.00	1098456987	STF03
1067	CONFIRMADA	REDES SOCIALES	2019-02-22	87004.00	1054654321	STF01
1068	CONFIRMADA	REFERIDO	2021-12-11	265000.00	1087321456	STF02
1069	CONFIRMADA	CORREO	2021-07-06	121682.00	1065987654	STF02
1070	CONFIRMADA	CORREO	2023-01-31	117397.00	1234521341	STF01
1071	CONFIRMADA	CORREO	2021-11-30	342784.00	1076123654	STF03
1072	CONFIRMADA	REFERIDO	2020-05-30	414632.00	1098652289	STF01
1073	CONFIRMADA	LLAMADA TELEFONICA	2022-12-05	159656.00	1087789123	STF03
1074	CONFIRMADA	CORREO	2022-11-22	138135.00	1043123789	STF01
1075	CONFIRMADA	WHATSAPP	2025-01-12	204881.00	1023456789	STF02
1076	CONFIRMADA	REDES SOCIALES	2021-07-31	290997.00	1056789123	STF03
1077	CONFIRMADA	REFERIDO	2020-06-21	518671.00	1034567891	STF01
1078	CONFIRMADA	REDES SOCIALES	2019-08-27	386421.00	1045123456	STF02
1079	CONFIRMADA	CORREO	2023-12-06	493333.00	1034512789	STF01
1080	CONFIRMADA	CORREO	2019-09-20	338834.00	1067834512	STF03
1081	CONFIRMADA	LLAMADA TELEFONICA	2020-12-15	536656.00	1045678234	STF01
1082	CONFIRMADA	WHATSAPP	2020-03-16	158688.00	1076543218	STF01
1083	CONFIRMADA	CORREO	2022-08-31	374018.00	1076523519	STF01
1085	CONFIRMADA	WHATSAPP	2021-07-27	372241.00	1083654927	STF01
1086	CONFIRMADA	CORREO	2021-11-30	376670.00	1051234876	STF03
1087	CONFIRMADA	WHATSAPP	2023-05-08	436488.00	1072345689	STF03
1088	CONFIRMADA	CORREO	2020-10-21	319134.00	1040987654	STF03
1089	CONFIRMADA	REDES SOCIALES	2023-05-02	517828.00	1078901234	STF03
1090	CONFIRMADA	WHATSAPP	2021-08-06	127886.00	1046789012	STF01
1091	CONFIRMADA	CORREO	2022-04-22	221430.00	1085432167	STF02
1092	CONFIRMADA	REDES SOCIALES	2023-09-18	261682.00	1074567890	STF03
1093	CONFIRMADA	REDES SOCIALES	2021-04-15	351409.00	1081098765	STF02
1094	CONFIRMADA	REFERIDO	2020-10-08	267395.00	1048765432	STF01
1095	CONFIRMADA	REFERIDO	2020-10-10	142446.00	1076543310	STF01
1096	CONFIRMADA	LLAMADA TELEFONICA	2024-04-17	387786.00	1045678901	STF01
1097	CONFIRMADA	REFERIDO	2023-01-05	209225.00	1083456789	STF02
1098	CONFIRMADA	WHATSAPP	2019-08-27	84461.00	1052109876	STF02
1099	CONFIRMADA	WHATSAPP	2023-09-16	233819.00	1074321098	STF03
1100	CONFIRMADA	WHATSAPP	2023-09-09	283580.00	1043876521	STF01
1101	CONFIRMADA	LLAMADA TELEFONICA	2021-03-09	110170.00	1081234098	STF03
1102	CONFIRMADA	LLAMADA TELEFONICA	2021-11-10	466489.00	1049567834	STF03
1103	CONFIRMADA	REFERIDO	2022-10-10	61775.00	1076893323	STF02
1104	CONFIRMADA	CORREO	2020-11-03	156185.00	1083654210	STF01
1105	CONFIRMADA	REFERIDO	2022-02-07	365558.00	1051987654	STF03
1106	CONFIRMADA	LLAMADA TELEFONICA	2021-04-23	283314.00	1072345876	STF01
1107	CONFIRMADA	CORREO	2019-05-19	410724.00	1081098432	STF01
1108	CONFIRMADA	REFERIDO	2023-02-20	281884.00	1078432109	STF02
1109	CONFIRMADA	WHATSAPP	2019-01-28	163687.00	1523456733	STF01
1110	CONFIRMADA	REFERIDO	2025-05-05	344716.00	1083210765	STF03
1111	CONFIRMADA	REDES SOCIALES	2024-05-26	175072.00	1051654321	STF03
1112	CONFIRMADA	LLAMADA TELEFONICA	2020-11-14	49259.00	1040987321	STF02
1113	CONFIRMADA	LLAMADA TELEFONICA	2019-10-01	226739.00	1081543210	STF02
1114	CONFIRMADA	WHATSAPP	2023-12-03	457347.00	1049321876	STF02
1115	CONFIRMADA	LLAMADA TELEFONICA	2019-12-20	51431.00	1046789321	STF01
1116	CONFIRMADA	CORREO	2024-12-25	329613.00	1008200987	STF03
1117	CONFIRMADA	REFERIDO	2020-07-27	433722.00	1053456789	STF02
1118	CONFIRMADA	WHATSAPP	2021-03-09	259621.00	1042987654	STF02
1119	CONFIRMADA	LLAMADA TELEFONICA	2021-03-28	466061.00	1083456210	STF02
1120	CONFIRMADA	CORREO	2020-08-01	266665.00	1051789654	STF02
1121	CONFIRMADA	LLAMADA TELEFONICA	2020-09-16	255446.00	1072543210	STF03
1122	CONFIRMADA	LLAMADA TELEFONICA	2023-04-23	271585.00	1081321098	STF03
1123	CONFIRMADA	CORREO	2019-10-08	86700.00	1078210987	STF01
1124	CONFIRMADA	LLAMADA TELEFONICA	2020-12-18	436775.00	1053321654	STF01
1125	CONFIRMADA	WHATSAPP	2020-11-21	147300.00	1074876543	STF01
1126	CONFIRMADA	LLAMADA TELEFONICA	2023-06-12	42488.00	1042210987	STF02
1127	CONFIRMADA	CORREO	2022-02-13	51696.00	1083543210	STF02
1128	CONFIRMADA	CORREO	2019-09-03	271767.00	1051876543	STF01
1129	CONFIRMADA	REDES SOCIALES	2024-03-07	249237.00	1072654321	STF01
1130	CONFIRMADA	WHATSAPP	2019-12-25	372000.00	108138765	STF02
1131	CONFIRMADA	LLAMADA TELEFONICA	2024-07-12	229050.00	1085321654	STF01
1132	CONFIRMADA	REDES SOCIALES	2024-10-20	243893.00	16345678	STF03
1133	CONFIRMADA	REFERIDO	2023-02-06	281522.00	1053987654	STF03
1134	CONFIRMADA	REDES SOCIALES	2023-06-14	294946.00	1074543210	STF01
1135	CONFIRMADA	CORREO	2023-08-13	173227.00	1083210654	STF03
1136	CONFIRMADA	CORREO	2024-01-19	155929.00	1072098765	STF03
1137	CONFIRMADA	WHATSAPP	2025-01-21	368621.00	1081432109	STF02
1138	CONFIRMADA	LLAMADA TELEFONICA	2023-10-27	469132.00	1078543210	STF03
1139	CONFIRMADA	WHATSAPP	2021-11-09	385842.00	1046321098	STF03
1140	CONFIRMADA	WHATSAPP	2022-12-13	166852.00	1085098432	STF01
1141	CONFIRMADA	WHATSAPP	2023-06-02	310618.00	88145756	STF01
1142	CONFIRMADA	CORREO	2020-07-01	113901.00	1053654321	STF03
1143	CONFIRMADA	CORREO	2020-02-24	400619.00	1074210987	STF01
1144	CONFIRMADA	WHATSAPP	2019-09-15	104482.00	1042543210	STF02
1145	CONFIRMADA	REDES SOCIALES	2019-11-10	250851.00	1065456987	STF03
1146	CONFIRMADA	WHATSAPP	2024-07-25	340851.00	1076234567	STF01
1147	CONFIRMADA	REFERIDO	2023-10-04	283451.00	1098789123	STF02
1148	CONFIRMADA	REDES SOCIALES	2021-11-21	272519.00	1054876543	STF02
1149	CONFIRMADA	CORREO	2024-05-28	88466.00	1043654987	STF01
1150	CONFIRMADA	REFERIDO	2020-12-16	400223.00	1065321456	STF03
1151	CONFIRMADA	WHATSAPP	2022-09-18	311085.00	1076456789	STF03
1152	CONFIRMADA	REDES SOCIALES	2019-12-30	416730.00	1087987654	STF01
1153	CONFIRMADA	CORREO	2024-06-13	56266.00	1043567890	STF03
1154	CONFIRMADA	REFERIDO	2022-10-23	72059.00	1065654321	STF02
1155	CONFIRMADA	REDES SOCIALES	2020-02-18	385882.00	1076789012	STF01
1156	CONFIRMADA	WHATSAPP	2021-01-07	198112.00	1098456789	STF02
1157	CONFIRMADA	CORREO	2021-03-23	398683.00	1009125678	STF03
1158	CONFIRMADA	WHATSAPP	2019-02-09	52525.00	1054567890	STF02
1159	CONFIRMADA	REDES SOCIALES	2020-06-13	86232.00	1087654098	STF01
1160	CONFIRMADA	CORREO	2023-06-02	359760.00	1043890765	STF03
1161	CONFIRMADA	LLAMADA TELEFONICA	2024-06-10	227089.00	1065789123	STF03
1162	CONFIRMADA	LLAMADA TELEFONICA	2025-04-26	156925.00	1076567432	STF01
1163	CONFIRMADA	CORREO	2021-01-11	82038.00	1098789456	STF02
1164	CONFIRMADA	LLAMADA TELEFONICA	2019-01-07	127336.00	1054321567	STF03
1165	CONFIRMADA	WHATSAPP	2021-05-29	281673.00	1087456789	STF02
1166	CONFIRMADA	REFERIDO	2023-05-05	365719.00	1043123456	STF01
1167	CONFIRMADA	REFERIDO	2020-04-12	93194.00	1091234567	STF02
1168	CONFIRMADA	REDES SOCIALES	2020-09-28	273830.00	1065432876	STF02
1169	CONFIRMADA	REFERIDO	2019-02-04	66181.00	1076890123	STF01
1170	CONFIRMADA	REDES SOCIALES	2023-02-24	315490.00	1098567321	STF02
1171	CONFIRMADA	CORREO	2023-12-03	260401.00	1054678954	STF01
1172	CONFIRMADA	REDES SOCIALES	2021-02-20	103341.00	1087789654	STF03
1173	CONFIRMADA	REDES SOCIALES	2020-10-04	319051.00	1065123789	STF02
1174	CONFIRMADA	LLAMADA TELEFONICA	2022-09-09	112206.00	1098654123	STF02
1175	CONFIRMADA	REFERIDO	2021-04-28	457852.00	1054987324	STF02
1176	CONFIRMADA	CORREO	2021-01-12	260141.00	1087321987	STF02
1177	CONFIRMADA	REDES SOCIALES	2022-07-16	328120.00	1043789321	STF01
1178	CONFIRMADA	REDES SOCIALES	2019-07-07	145388.00	1087123987	STF03
1179	CONFIRMADA	WHATSAPP	2020-08-05	163063.00	1043654321	STF01
1180	CONFIRMADA	REDES SOCIALES	2019-12-06	212265.00	1065789456	STF02
1181	CONFIRMADA	LLAMADA TELEFONICA	2024-06-30	349052.00	1076654987	STF02
1182	CONFIRMADA	REDES SOCIALES	2021-07-13	137470.00	1054123654	STF03
1183	CONFIRMADA	LLAMADA TELEFONICA	2023-10-12	432478.00	1098123987	STF01
1184	CONFIRMADA	REDES SOCIALES	2023-06-23	424814.00	1054789456	STF02
1185	CONFIRMADA	WHATSAPP	2022-12-03	71337.00	12345678	STF01
1186	CONFIRMADA	REDES SOCIALES	2021-01-20	174150.00	1076456321	STF01
1187	CONFIRMADA	LLAMADA TELEFONICA	2021-01-16	55161.00	1098789654	STF01
1188	CONFIRMADA	LLAMADA TELEFONICA	2021-06-01	264565.00	1054321789	STF02
1189	CONFIRMADA	REFERIDO	2022-09-17	354254.00	1087654456	STF01
1190	CONFIRMADA	LLAMADA TELEFONICA	2021-02-25	180402.00	1065123456	STF03
1191	CONFIRMADA	REFERIDO	2021-09-17	166340.00	1098456987	STF02
1192	CONFIRMADA	REFERIDO	2021-11-21	440504.00	1087321456	STF02
1193	CONFIRMADA	REFERIDO	2020-02-13	209803.00	1065987654	STF01
1194	CONFIRMADA	REDES SOCIALES	2023-02-16	55272.00	1234521341	STF02
1195	CONFIRMADA	WHATSAPP	2020-03-09	194375.00	1098652289	STF03
1196	CONFIRMADA	REDES SOCIALES	2019-08-21	206434.00	1087789123	STF03
1197	CONFIRMADA	LLAMADA TELEFONICA	2024-12-19	178914.00	1043123789	STF01
1198	CONFIRMADA	CORREO	2022-12-18	210534.00	1087234569	STF01
1199	CONFIRMADA	REDES SOCIALES	2022-03-13	194484.00	1045678912	STF02
1200	CONFIRMADA	WHATSAPP	2025-04-10	174209.00	1056789123	STF01
1201	CONFIRMADA	LLAMADA TELEFONICA	2024-04-21	199132.00	1034567891	STF03
1202	CONFIRMADA	CORREO	2021-10-23	212228.00	1067891234	STF03
1203	CONFIRMADA	REFERIDO	2024-01-02	275488.00	1091483627	STF02
1204	CONFIRMADA	REFERIDO	2021-04-12	229311.00	1027395841	STF02
1205	CONFIRMADA	REDES SOCIALES	2023-04-25	391747.00	1075962843	STF02
1206	CONFIRMADA	CORREO	2020-02-01	186908.00	1039627485	STF02
1207	CONFIRMADA	REDES SOCIALES	2022-03-20	321939.00	1087529641	STF02
1208	CONFIRMADA	REFERIDO	2019-05-08	252635.00	1007529441	STF03
1209	CONFIRMADA	REDES SOCIALES	2021-05-31	204289.00	1074295863	STF01
1210	CONFIRMADA	WHATSAPP	2019-10-21	371940.00	1024759638	STF01
1211	CONFIRMADA	LLAMADA TELEFONICA	2020-07-26	482466.00	1078364925	STF01
1212	CONFIRMADA	REFERIDO	2019-03-31	269809.00	1053826794	STF02
1213	CONFIRMADA	WHATSAPP	2021-09-25	132786.00	1092746835	STF01
1214	CONFIRMADA	LLAMADA TELEFONICA	2025-05-27	229603.00	1037485962	STF03
1215	CONFIRMADA	REDES SOCIALES	2023-03-04	260834.00	1085372941	STF02
1216	CONFIRMADA	CORREO	2023-08-01	44793.00	1049638527	STF03
1217	CONFIRMADA	WHATSAPP	2023-09-30	282814.00	1076294853	STF03
1218	CONFIRMADA	WHATSAPP	2024-01-21	151441.00	1042857396	STF03
1219	CONFIRMADA	LLAMADA TELEFONICA	2023-06-12	335424.00	1088249637	STF01
1220	CONFIRMADA	LLAMADA TELEFONICA	2024-10-02	67641.00	1034759628	STF02
1221	CONFIRMADA	WHATSAPP	2019-01-30	325546.00	1081637425	STF01
1222	CONFIRMADA	CORREO	2025-01-04	141184.00	1056382947	STF01
1223	CONFIRMADA	LLAMADA TELEFONICA	2024-06-20	111815.00	1038462759	STF02
1224	CONFIRMADA	WHATSAPP	2019-09-05	383000.00	1047385926	STF01
1225	CONFIRMADA	WHATSAPP	2023-08-28	314861.00	1089472635	STF02
1226	CONFIRMADA	LLAMADA TELEFONICA	2022-08-16	393088.00	1025847396	STF03
1227	CONFIRMADA	LLAMADA TELEFONICA	2022-06-19	103288.00	1074628395	STF02
1228	CONFIRMADA	WHATSAPP	2019-09-26	60938.00	1086274935	STF03
1229	CONFIRMADA	REFERIDO	2021-11-08	232755.00	1043758296	STF01
1230	CONFIRMADA	REDES SOCIALES	2020-11-07	329121.00	1091638527	STF02
1231	CONFIRMADA	LLAMADA TELEFONICA	2022-04-02	296607.00	1036829475	STF02
1232	CONFIRMADA	CORREO	2023-10-05	307328.00	1079485362	STF02
1233	CONFIRMADA	REFERIDO	2021-02-06	388777.00	1048273659	STF03
1234	CONFIRMADA	REDES SOCIALES	2019-03-28	65431.00	37331882	STF02
1235	CONFIRMADA	LLAMADA TELEFONICA	2020-04-14	202536.00	1054827396	STF02
1236	CONFIRMADA	LLAMADA TELEFONICA	2023-03-06	354411.00	1093847625	STF03
1237	CONFIRMADA	WHATSAPP	2019-08-20	341955.00	1029473658	STF02
1238	CONFIRMADA	REFERIDO	2019-07-03	362062.00	1076384925	STF02
1239	CONFIRMADA	REFERIDO	2019-05-18	330440.00	1089374115	STF03
1240	CONFIRMADA	CORREO	2019-01-30	47702.00	1084729635	STF02
1241	CONFIRMADA	CORREO	2019-02-12	471056.00	1092847365	STF03
1242	CONFIRMADA	REDES SOCIALES	2019-01-29	396505.00	1927485962	STF01
1243	CONFIRMADA	REDES SOCIALES	2019-01-20	277113.00	1085729463	STF03
1244	CONFIRMADA	WHATSAPP	2020-09-18	196180.00	1098373335	STF01
1245	CONFIRMADA	REDES SOCIALES	2021-08-02	284164.00	1087399925	STF01
1246	CONFIRMADA	WHATSAPP	2019-09-30	341437.00	1052822396	STF02
1247	CONFIRMADA	CORREO	2021-01-02	454141.00	1094738526	STF03
1248	CONFIRMADA	CORREO	2022-12-01	174374.00	1047312346	STF03
1249	CONFIRMADA	REFERIDO	2022-03-24	441854.00	1092842265	STF01
1250	CONFIRMADA	LLAMADA TELEFONICA	2021-03-31	145516.00	1052839475	STF03
1251	CONFIRMADA	LLAMADA TELEFONICA	2021-02-07	219654.00	1096384725	STF03
1252	CONFIRMADA	REFERIDO	2024-09-18	47481.00	1041738526	STF02
1253	CONFIRMADA	REDES SOCIALES	2024-01-21	358622.00	1080914625	STF03
1254	CONFIRMADA	CORREO	2023-01-20	46808.00	1036729485	STF02
1255	CONFIRMADA	REFERIDO	2024-09-14	332283.00	1084123625	STF01
1256	CONFIRMADA	REFERIDO	2019-02-14	99451.00	1058392746	STF02
1257	CONFIRMADA	REFERIDO	2019-05-28	126079.00	1091237625	STF02
1258	CONFIRMADA	REDES SOCIALES	2023-06-16	143207.00	1083249635	STF03
1259	CONFIRMADA	LLAMADA TELEFONICA	2021-04-30	72194.00	1096843725	STF02
1260	CONFIRMADA	REDES SOCIALES	2022-11-22	130603.00	1032749658	STF03
1261	CONFIRMADA	WHATSAPP	2019-07-17	328229.00	1089234625	STF03
1262	CONFIRMADA	LLAMADA TELEFONICA	2024-01-21	136131.00	1094123526	STF01
1263	CONFIRMADA	LLAMADA TELEFONICA	2023-05-18	157570.00	1138495762	STF01
1264	CONFIRMADA	REDES SOCIALES	2023-08-30	106788.00	1385739624	STF01
1265	CONFIRMADA	WHATSAPP	2024-04-29	336854.00	1092847296	STF01
1266	CONFIRMADA	CORREO	2021-02-28	298886.00	1043384925	STF03
1267	CONFIRMADA	REDES SOCIALES	2024-01-13	339335.00	1045758396	STF02
1268	CONFIRMADA	CORREO	2023-09-17	488350.00	1089564625	STF03
1269	CONFIRMADA	REFERIDO	2020-11-24	89335.00	1035134463	STF03
1270	CONFIRMADA	LLAMADA TELEFONICA	2022-03-21	258578.00	1082394625	STF03
1271	CONFIRMADA	LLAMADA TELEFONICA	2025-02-05	189668.00	1012349637	STF01
1272	CONFIRMADA	WHATSAPP	2023-06-14	241342.00	1047312926	STF03
1273	CONFIRMADA	LLAMADA TELEFONICA	2019-01-23	462826.00	1033329485	STF02
1274	CONFIRMADA	REFERIDO	2024-07-15	135780.00	1095847362	STF03
1275	CONFIRMADA	WHATSAPP	2024-08-01	83711.00	1034829475	STF01
1276	CONFIRMADA	REFERIDO	2023-03-10	172856.00	1086391225	STF02
1277	CONFIRMADA	WHATSAPP	2020-06-05	355362.00	1007847296	STF02
1278	CONFIRMADA	CORREO	2023-07-04	196389.00	1098234625	STF02
1279	CONFIRMADA	LLAMADA TELEFONICA	2019-05-04	106144.00	1042758396	STF03
1280	CONFIRMADA	REDES SOCIALES	2021-05-07	329566.00	1040238657	STF03
1281	CONFIRMADA	REDES SOCIALES	2025-01-19	60027.00	1025697841	STF02
1282	CONFIRMADA	REFERIDO	2024-06-26	55384.00	1032456789	STF01
1283	CONFIRMADA	WHATSAPP	2021-10-20	240898.00	1051234567	STF01
1284	CONFIRMADA	CORREO	2021-01-08	64125.00	1039876542	STF02
1285	CONFIRMADA	CORREO	2024-06-11	398875.00	1047896321	STF02
1286	CONFIRMADA	REDES SOCIALES	2024-09-11	61517.00	1028564973	STF03
1287	CONFIRMADA	WHATSAPP	2023-11-18	440410.00	1041759638	STF01
1288	CONFIRMADA	REDES SOCIALES	2021-05-17	189357.00	1036524789	STF01
1289	CONFIRMADA	REDES SOCIALES	2021-06-06	334004.00	1029843756	STF01
1290	CONFIRMADA	REFERIDO	2023-03-03	365049.00	1046789125	STF03
1291	CONFIRMADA	LLAMADA TELEFONICA	2025-04-19	304011.00	1042357896	STF03
1292	CONFIRMADA	WHATSAPP	2019-07-31	52242.00	1039654783	STF03
1293	CONFIRMADA	LLAMADA TELEFONICA	2025-04-17	212910.00	1035789126	STF01
1294	CONFIRMADA	REDES SOCIALES	2021-01-13	150275.00	1048521369	STF03
1295	CONFIRMADA	LLAMADA TELEFONICA	2019-06-29	294070.00	1041236587	STF03
1296	CONFIRMADA	WHATSAPP	2023-01-24	200216.00	1043785642	STF03
1297	CONFIRMADA	REDES SOCIALES	2019-09-09	152141.00	1032874569	STF01
1298	CONFIRMADA	WHATSAPP	2021-08-19	291907.00	1031697854	STF01
909	CONFIRMADA	LLAMADA TELEFONICA	2025-04-20	120995.00	1406210137	STF01
917	CONFIRMADA	REDES SOCIALES	2025-03-11	225648.00	1076570978	STF03
923	CONFIRMADA	LLAMADA TELEFONICA	2023-09-17	127031.00	1667427647	STF02
926	CONFIRMADA	WHATSAPP	2022-02-05	228733.00	1383916991	STF01
929	CONFIRMADA	LLAMADA TELEFONICA	2024-04-29	84896.00	1136740472	STF03
936	CONFIRMADA	REFERIDO	2021-08-08	373344.00	1885795495	STF01
940	CONFIRMADA	LLAMADA TELEFONICA	2023-01-01	119284.00	1380111989	STF01
941	CONFIRMADA	LLAMADA TELEFONICA	2021-03-06	532556.00	1654465547	STF03
944	CONFIRMADA	REDES SOCIALES	2022-06-24	447907.00	1373161364	STF01
945	CONFIRMADA	LLAMADA TELEFONICA	2024-03-11	357366.00	1943030030	STF02
947	CONFIRMADA	CORREO	2025-05-17	71299.00	1480316666	STF01
949	CONFIRMADA	REDES SOCIALES	2020-05-07	328656.00	1035179304	STF02
954	CONFIRMADA	REDES SOCIALES	2025-01-01	258677.00	1465448275	STF02
956	CONFIRMADA	REDES SOCIALES	2020-03-14	107375.00	1388901812	STF01
958	CONFIRMADA	LLAMADA TELEFONICA	2021-02-08	319560.00	1687593244	STF03
960	CONFIRMADA	CORREO	2020-12-26	506257.00	1441138039	STF02
963	CONFIRMADA	REDES SOCIALES	2021-01-23	219572.00	1441937555	STF02
969	CONFIRMADA	WHATSAPP	2025-04-01	386282.00	1382037266	STF01
973	CONFIRMADA	REFERIDO	2024-09-25	220280.00	1094981158	STF02
975	CONFIRMADA	LLAMADA TELEFONICA	2022-08-03	202354.00	1464211798	STF02
977	CONFIRMADA	LLAMADA TELEFONICA	2022-04-25	371935.00	1499945977	STF02
980	CONFIRMADA	LLAMADA TELEFONICA	2020-06-08	294560.00	1820597500	STF01
984	CONFIRMADA	REFERIDO	2019-12-19	525322.00	1400891038	STF01
985	CONFIRMADA	CORREO	2023-10-05	259788.00	1673715337	STF03
988	CONFIRMADA	REFERIDO	2022-02-05	120280.00	1084967541	STF02
990	CONFIRMADA	REDES SOCIALES	2021-10-17	84014.00	1848162045	STF02
992	CONFIRMADA	REFERIDO	2019-07-25	246581.00	1458299989	STF02
999	CONFIRMADA	WHATSAPP	2019-05-06	367906.00	1128207000	STF02
1000	CONFIRMADA	CORREO	2019-02-01	556578.00	1322328432	STF03
1299	CONFIRMADA	CORREO	2025-02-21	88327.00	1046283759	STF03
1300	CONFIRMADA	WHATSAPP	2019-01-05	175950.00	1041582736	STF02
1301	CONFIRMADA	CORREO	2023-03-27	290551.00	1038467592	STF01
1302	CONFIRMADA	LLAMADA TELEFONICA	2025-05-15	166414.00	1027841596	STF02
1303	CONFIRMADA	LLAMADA TELEFONICA	2022-10-28	320772.00	1043527896	STF01
1304	CONFIRMADA	WHATSAPP	2020-09-29	226906.00	1040896327	STF03
1305	CONFIRMADA	REFERIDO	2024-11-05	271364.00	1036745892	STF03
1306	CONFIRMADA	LLAMADA TELEFONICA	2025-05-24	443431.00	1028596374	STF02
1307	CONFIRMADA	WHATSAPP	2023-06-07	254646.00	1044728159	STF01
1308	CONFIRMADA	CORREO	2025-02-01	144557.00	1031457896	STF01
1309	CONFIRMADA	WHATSAPP	2023-01-11	45790.00	1037859641	STF01
1310	CONFIRMADA	CORREO	2020-11-04	269374.00	1043682597	STF02
1311	CONFIRMADA	REDES SOCIALES	2024-01-07	157375.00	1029374856	STF02
1312	CONFIRMADA	WHATSAPP	2020-08-25	305743.00	1045896327	STF03
1313	CONFIRMADA	LLAMADA TELEFONICA	2020-10-30	165293.00	1032741856	STF03
1314	CONFIRMADA	REFERIDO	2025-05-10	308056.00	1038567423	STF01
1315	CONFIRMADA	CORREO	2020-12-12	367379.00	1026849537	STF01
1316	CONFIRMADA	WHATSAPP	2023-02-21	460349.00	1035428697	STF02
1317	CONFIRMADA	CORREO	2021-07-31	145647.00	1028563794	STF02
1318	CONFIRMADA	WHATSAPP	2021-09-26	204699.00	1037452896	STF02
1319	CONFIRMADA	LLAMADA TELEFONICA	2021-06-15	97183.00	1043758962	STF02
1320	CONFIRMADA	LLAMADA TELEFONICA	2025-01-22	407318.00	1029637854	STF01
1321	CONFIRMADA	CORREO	2023-12-27	437999.00	1045896321	STF02
1322	CONFIRMADA	CORREO	2021-03-22	240415.00	1032574896	STF01
1323	CONFIRMADA	REDES SOCIALES	2021-05-26	105299.00	1038695741	STF02
1324	CONFIRMADA	WHATSAPP	2022-10-08	458572.00	1026745893	STF02
1325	CONFIRMADA	CORREO	2019-06-02	165789.00	1041528367	STF03
1326	CONFIRMADA	REDES SOCIALES	2025-05-23	129919.00	1037896524	STF02
1327	CONFIRMADA	CORREO	2025-03-20	414583.00	1030485762	STF02
1328	CONFIRMADA	REFERIDO	2024-08-14	289260.00	1046785932	STF01
1329	CONFIRMADA	REDES SOCIALES	2022-07-05	275973.00	1033658947	STF01
1330	CONFIRMADA	CORREO	2024-01-26	349176.00	1029745862	STF01
1331	CONFIRMADA	REFERIDO	2023-04-14	112494.00	1032874695	STF01
1332	CONFIRMADA	REDES SOCIALES	2021-03-18	200364.00	1038675429	STF01
1333	CONFIRMADA	REFERIDO	2024-02-23	301949.00	1026598734	STF01
1334	CONFIRMADA	REFERIDO	2025-01-29	439051.00	1042741856	STF03
1335	CONFIRMADA	REFERIDO	2024-10-07	228354.00	1035896742	STF03
1336	CONFIRMADA	REFERIDO	2019-03-14	140230.00	1041758362	STF01
1337	CONFIRMADA	WHATSAPP	2025-05-15	248155.00	1028647593	STF03
1338	CONFIRMADA	CORREO	2021-09-29	132427.00	1043785629	STF02
1339	CONFIRMADA	REDES SOCIALES	2019-12-04	380321.00	1030596387	STF03
1340	CONFIRMADA	REDES SOCIALES	2023-11-07	273198.00	1037544920	STF03
1341	CONFIRMADA	LLAMADA TELEFONICA	2023-06-06	125837.00	1065432187	STF03
1342	CONFIRMADA	REDES SOCIALES	2019-03-12	212467.00	1032145698	STF03
1343	CONFIRMADA	LLAMADA TELEFONICA	2025-04-03	144344.00	1087452963	STF02
1344	CONFIRMADA	WHATSAPP	2022-02-21	150506.00	1054789632	STF01
1345	CONFIRMADA	CORREO	2019-05-27	206101.00	1076543219	STF03
1346	CONFIRMADA	LLAMADA TELEFONICA	2021-06-07	101878.00	1041258963	STF02
1347	CONFIRMADA	LLAMADA TELEFONICA	2022-02-01	317538.00	1048529637	STF03
1348	CONFIRMADA	CORREO	2023-02-15	80644.00	1036741892	STF01
1349	CONFIRMADA	REFERIDO	2024-10-31	116754.00	1081479632	STF02
1350	CONFIRMADA	REFERIDO	2021-10-27	377548.00	1057896143	STF03
1351	CONFIRMADA	REDES SOCIALES	2020-11-15	381440.00	1074185296	STF01
1352	CONFIRMADA	LLAMADA TELEFONICA	2021-06-05	142666.00	1045827396	STF02
1353	CONFIRMADA	CORREO	2020-08-29	116912.00	1051963847	STF03
1354	CONFIRMADA	CORREO	2022-10-02	84169.00	1098374625	STF03
1355	CONFIRMADA	REDES SOCIALES	2020-06-06	317530.00	1086295174	STF03
1356	CONFIRMADA	LLAMADA TELEFONICA	2024-07-01	189488.00	1091483627	STF03
1357	CONFIRMADA	REDES SOCIALES	2019-04-06	382319.00	1075962843	STF02
1358	CONFIRMADA	LLAMADA TELEFONICA	2023-08-08	233086.00	1052847396	STF01
1359	CONFIRMADA	REFERIDO	2024-09-14	333499.00	1084736291	STF02
1360	CONFIRMADA	WHATSAPP	2022-10-28	84732.00	1039627485	STF02
1361	CONFIRMADA	REFERIDO	2023-11-01	490149.00	1007529441	STF03
1362	CONFIRMADA	WHATSAPP	2020-07-20	238636.00	1046829537	STF02
1363	CONFIRMADA	CORREO	2021-11-23	294975.00	1089374625	STF02
1364	CONFIRMADA	REFERIDO	2020-03-07	415410.00	1024759638	STF02
1365	CONFIRMADA	REDES SOCIALES	2022-02-28	178524.00	1078364925	STF02
1366	CONFIRMADA	WHATSAPP	2022-11-01	148785.00	1053826794	STF03
1367	CONFIRMADA	WHATSAPP	2020-09-18	205978.00	1092746835	STF02
1368	CONFIRMADA	REFERIDO	2025-01-27	283248.00	1037485962	STF03
1369	CONFIRMADA	LLAMADA TELEFONICA	2020-02-03	450662.00	1085372941	STF03
1370	CONFIRMADA	REFERIDO	2020-04-17	303865.00	1049638527	STF01
1371	CONFIRMADA	WHATSAPP	2021-01-12	357053.00	1076294853	STF02
1372	CONFIRMADA	LLAMADA TELEFONICA	2023-11-22	246518.00	1042857396	STF03
1373	CONFIRMADA	REFERIDO	2021-06-01	249082.00	1088249637	STF01
1374	CONFIRMADA	WHATSAPP	2019-10-25	335522.00	1034759628	STF02
1375	CONFIRMADA	REDES SOCIALES	2023-08-20	227134.00	1081637425	STF02
1376	CONFIRMADA	LLAMADA TELEFONICA	2020-04-08	269401.00	1056382947	STF01
1377	CONFIRMADA	CORREO	2025-01-01	481572.00	1047385926	STF02
1378	CONFIRMADA	LLAMADA TELEFONICA	2020-09-19	161784.00	1089472635	STF02
1379	CONFIRMADA	LLAMADA TELEFONICA	2023-06-18	77016.00	1025847396	STF03
1380	CONFIRMADA	REDES SOCIALES	2021-10-12	77206.00	1074628395	STF03
1381	CONFIRMADA	REFERIDO	2019-04-12	437395.00	1051394827	STF03
1382	CONFIRMADA	REDES SOCIALES	2023-05-12	133395.00	1086274935	STF01
1383	CONFIRMADA	WHATSAPP	2023-06-19	125079.00	1043758296	STF02
1384	CONFIRMADA	CORREO	2019-06-10	471959.00	1091638527	STF02
1385	CONFIRMADA	WHATSAPP	2024-11-20	194166.00	1036829475	STF01
1386	CONFIRMADA	WHATSAPP	2020-07-07	347498.00	1079485362	STF01
1387	CONFIRMADA	REFERIDO	2024-05-22	278592.00	1048273659	STF03
1388	CONFIRMADA	REDES SOCIALES	2022-03-19	401590.00	37331882	STF03
1389	CONFIRMADA	REFERIDO	2020-09-19	442437.00	1054827396	STF03
1390	CONFIRMADA	WHATSAPP	2024-09-09	203298.00	1093847625	STF01
1391	CONFIRMADA	CORREO	2023-11-03	167740.00	1029473658	STF02
1392	CONFIRMADA	REDES SOCIALES	2020-07-05	303097.00	1076384925	STF01
1393	CONFIRMADA	REFERIDO	2024-04-02	269541.00	1052947296	STF02
1394	CONFIRMADA	WHATSAPP	2019-11-07	87952.00	1089374115	STF03
1395	CONFIRMADA	LLAMADA TELEFONICA	2023-08-10	373200.00	1035829473	STF02
1396	CONFIRMADA	LLAMADA TELEFONICA	2019-10-14	131912.00	1084729635	STF03
1397	CONFIRMADA	WHATSAPP	2020-12-30	372503.00	1092847365	STF02
1398	CONFIRMADA	REFERIDO	2025-01-07	92760.00	1085729463	STF03
1399	CONFIRMADA	REFERIDO	2021-11-10	175098.00	1053847296	STF02
1400	CONFIRMADA	CORREO	2022-05-06	130038.00	1098373335	STF02
1401	CONFIRMADA	CORREO	2020-05-25	208055.00	1052822396	STF02
1402	CONFIRMADA	REFERIDO	2024-06-01	415560.00	1038495762	STF03
1403	CONFIRMADA	WHATSAPP	2024-03-10	378391.00	1047312346	STF02
1404	CONFIRMADA	LLAMADA TELEFONICA	2022-09-07	358033.00	1092842265	STF03
1405	CONFIRMADA	REFERIDO	2019-09-21	155455.00	1087312925	STF01
1406	CONFIRMADA	REDES SOCIALES	2023-12-18	46221.00	1052839475	STF01
1407	CONFIRMADA	CORREO	2019-11-14	114451.00	1096384725	STF02
1408	CONFIRMADA	LLAMADA TELEFONICA	2022-03-23	257609.00	1041738526	STF02
1409	CONFIRMADA	CORREO	2024-08-09	312727.00	1080914625	STF01
1410	CONFIRMADA	WHATSAPP	2020-11-14	236446.00	1036729485	STF03
1411	CONFIRMADA	WHATSAPP	2019-05-06	213038.00	1084739625	STF03
1412	CONFIRMADA	LLAMADA TELEFONICA	2021-05-22	275946.00	1084123625	STF01
1413	CONFIRMADA	REDES SOCIALES	2021-03-30	137166.00	1091237625	STF01
1414	CONFIRMADA	WHATSAPP	2024-10-11	293681.00	1037481212	STF02
1415	CONFIRMADA	REFERIDO	2025-01-27	337180.00	1083249635	STF01
1416	CONFIRMADA	CORREO	2019-10-21	180628.00	1047389026	STF03
1417	CONFIRMADA	REFERIDO	2022-08-26	206416.00	1094123526	STF02
1418	CONFIRMADA	REFERIDO	2022-07-28	311610.00	1138495762	STF03
1419	CONFIRMADA	LLAMADA TELEFONICA	2024-06-05	58550.00	1385739624	STF03
1420	CONFIRMADA	CORREO	2020-05-11	241277.00	1092847296	STF03
1421	CONFIRMADA	LLAMADA TELEFONICA	2022-12-23	321522.00	88142897	STF03
1422	CONFIRMADA	REDES SOCIALES	2019-04-29	382382.00	1043384925	STF03
1423	CONFIRMADA	CORREO	2020-02-17	40763.00	1045758396	STF01
1424	CONFIRMADA	LLAMADA TELEFONICA	2024-07-13	329406.00	1089564625	STF02
1425	CONFIRMADA	CORREO	2024-09-20	400782.00	1035134463	STF02
1426	CONFIRMADA	WHATSAPP	2022-10-20	150863.00	1082394625	STF03
1427	CONFIRMADA	WHATSAPP	2024-01-14	354750.00	1038982762	STF02
1428	CONFIRMADA	CORREO	2020-10-15	91693.00	1092347625	STF01
1429	CONFIRMADA	REDES SOCIALES	2024-11-19	266006.00	1033329485	STF02
1430	CONFIRMADA	WHATSAPP	2020-04-21	189001.00	1049384726	STF01
1431	CONFIRMADA	CORREO	2020-08-21	144341.00	1095847362	STF01
1432	CONFIRMADA	LLAMADA TELEFONICA	2024-12-05	285260.00	1034829475	STF03
1433	CONFIRMADA	REDES SOCIALES	2023-08-27	141473.00	1007847296	STF03
1434	CONFIRMADA	CORREO	2021-04-10	51318.00	1098234625	STF03
1435	CONFIRMADA	LLAMADA TELEFONICA	2019-04-27	105519.00	1042758396	STF01
1436	CONFIRMADA	CORREO	2021-04-13	422253.00	1007584920	STF01
1437	CONFIRMADA	WHATSAPP	2024-08-09	95098.00	1040238657	STF03
1438	CONFIRMADA	WHATSAPP	2019-07-08	311657.00	1025697841	STF03
1439	CONFIRMADA	WHATSAPP	2019-03-08	200239.00	1032456789	STF03
1440	CONFIRMADA	LLAMADA TELEFONICA	2023-01-06	222233.00	1048765123	STF01
1441	CONFIRMADA	REDES SOCIALES	2025-01-12	327775.00	1051234567	STF03
1442	CONFIRMADA	CORREO	2019-08-25	163997.00	1041759638	STF01
1443	CONFIRMADA	REDES SOCIALES	2024-11-22	329681.00	1036524789	STF02
1444	CONFIRMADA	CORREO	2020-12-12	199184.00	1044587123	STF01
1445	CONFIRMADA	REFERIDO	2019-07-18	266452.00	1029843756	STF02
1446	CONFIRMADA	LLAMADA TELEFONICA	2024-08-04	574719.00	1045123698	STF03
1447	CONFIRMADA	REDES SOCIALES	2022-09-08	387826.00	1046789125	STF03
1448	CONFIRMADA	CORREO	2019-08-31	239758.00	1033456782	STF01
1449	CONFIRMADA	REDES SOCIALES	2024-11-17	375402.00	1027895641	STF01
1450	CONFIRMADA	CORREO	2024-02-06	297701.00	1042357896	STF01
1451	CONFIRMADA	REDES SOCIALES	2021-01-08	341144.00	1039654783	STF02
1452	CONFIRMADA	CORREO	2025-03-27	91257.00	1035789126	STF01
1453	CONFIRMADA	WHATSAPP	2021-06-16	429572.00	1048521369	STF03
1454	CONFIRMADA	CORREO	2022-01-23	316282.00	1041236587	STF02
1455	CONFIRMADA	REDES SOCIALES	2024-01-05	45280.00	1037458926	STF03
1456	CONFIRMADA	REDES SOCIALES	2020-06-29	424014.00	1043785642	STF02
1457	CONFIRMADA	REDES SOCIALES	2022-02-26	111581.00	1045692837	STF01
1458	CONFIRMADA	CORREO	2019-07-30	167906.00	1032874569	STF02
1459	CONFIRMADA	WHATSAPP	2021-04-25	156578.00	1028459367	STF02
1460	CONFIRMADA	REDES SOCIALES	2024-12-06	160774.00	1044176325	STF02
1461	CONFIRMADA	REDES SOCIALES	2020-01-26	220973.00	1046283759	STF03
1462	CONFIRMADA	REDES SOCIALES	2022-12-09	193610.00	1033587462	STF01
1463	CONFIRMADA	WHATSAPP	2020-11-14	370458.00	1029756841	STF02
1464	CONFIRMADA	LLAMADA TELEFONICA	2024-03-29	70646.00	1041582736	STF02
1465	CONFIRMADA	CORREO	2021-01-23	369573.00	1038467592	STF01
1466	CONFIRMADA	CORREO	2021-07-16	443852.00	1045728361	STF02
1467	CONFIRMADA	CORREO	2022-11-19	262180.00	1032659874	STF01
1468	CONFIRMADA	CORREO	2023-04-14	80680.00	1027841596	STF03
1469	CONFIRMADA	REFERIDO	2020-01-19	265180.00	1043527896	STF02
1470	CONFIRMADA	REDES SOCIALES	2022-02-18	335638.00	1028596374	STF02
1471	CONFIRMADA	REFERIDO	2021-07-28	189996.00	1044728159	STF01
1472	CONFIRMADA	REDES SOCIALES	2024-11-25	89839.00	1029374856	STF03
1473	CONFIRMADA	LLAMADA TELEFONICA	2019-06-12	205328.00	1045896327	STF03
1474	CONFIRMADA	LLAMADA TELEFONICA	2024-03-01	327153.00	1026849537	STF02
1475	CONFIRMADA	REFERIDO	2022-08-30	253081.00	1035428697	STF02
1476	CONFIRMADA	REDES SOCIALES	2022-01-28	88095.00	1028563794	STF02
1477	CONFIRMADA	LLAMADA TELEFONICA	2024-12-25	237983.00	1043758962	STF03
1478	CONFIRMADA	WHATSAPP	2020-02-26	98515.00	1029637854	STF02
1479	CONFIRMADA	REDES SOCIALES	2023-01-09	362277.00	1032574896	STF03
1480	CONFIRMADA	WHATSAPP	2020-04-07	290649.00	1038695741	STF02
1481	CONFIRMADA	LLAMADA TELEFONICA	2021-04-26	281882.00	1041528367	STF02
1482	CONFIRMADA	REDES SOCIALES	2024-07-05	236732.00	1037896524	STF03
1483	CONFIRMADA	REDES SOCIALES	2022-04-18	104719.00	1043257896	STF03
1484	CONFIRMADA	WHATSAPP	2025-01-25	164412.00	1030485762	STF02
1485	CONFIRMADA	REFERIDO	2023-07-17	54435.00	1033658947	STF01
1486	CONFIRMADA	CORREO	2023-11-30	329912.00	1045239687	STF01
1487	CONFIRMADA	WHATSAPP	2024-02-14	255497.00	1038675429	STF02
1488	CONFIRMADA	CORREO	2023-05-23	258269.00	1026598734	STF01
1489	CONFIRMADA	LLAMADA TELEFONICA	2025-02-02	211751.00	1041758362	STF01
1490	CONFIRMADA	REDES SOCIALES	2019-05-26	79633.00	1028647593	STF01
1491	CONFIRMADA	REFERIDO	2021-09-29	86638.00	1031852796	STF02
1492	CONFIRMADA	WHATSAPP	2019-07-24	246746.00	1037698524	STF01
1493	CONFIRMADA	LLAMADA TELEFONICA	2020-04-08	322191.00	1030596387	STF03
1494	CONFIRMADA	CORREO	2023-08-23	321869.00	1046258973	STF03
1495	CONFIRMADA	REFERIDO	2021-12-10	363868.00	1032568749	STF02
1496	CONFIRMADA	LLAMADA TELEFONICA	2025-05-19	283132.00	1038457296	STF01
1497	CONFIRMADA	LLAMADA TELEFONICA	2020-03-06	282220.00	1026745832	STF01
1498	CONFIRMADA	WHATSAPP	2019-07-18	353113.00	1041856739	STF03
1499	CONFIRMADA	REDES SOCIALES	2024-10-23	271393.00	1043687524	STF02
1500	CONFIRMADA	WHATSAPP	2020-07-23	148593.00	1046785923	STF02
1501	CONFIRMADA	WHATSAPP	2020-12-29	145326.00	1033576842	STF01
1502	CONFIRMADA	REDES SOCIALES	2024-12-14	88338.00	1092692837	STF03
1503	CONFIRMADA	CORREO	2020-03-17	363503.00	1725139428	STF02
1504	CONFIRMADA	LLAMADA TELEFONICA	2022-06-28	271700.00	1183328812	STF02
1505	CONFIRMADA	REFERIDO	2019-04-23	48148.00	1929839528	STF03
1506	CONFIRMADA	WHATSAPP	2022-03-21	183490.00	1230931647	STF01
1507	CONFIRMADA	WHATSAPP	2024-01-07	268071.00	1884331481	STF03
1508	CONFIRMADA	LLAMADA TELEFONICA	2025-04-21	211001.00	1935770226	STF02
1509	CONFIRMADA	REFERIDO	2020-03-19	114670.00	1202533744	STF02
1510	CONFIRMADA	REDES SOCIALES	2021-10-18	203920.00	1478116328	STF03
1511	CONFIRMADA	WHATSAPP	2022-05-01	257764.00	1047475612	STF03
1512	CONFIRMADA	WHATSAPP	2019-01-22	209113.00	1464574808	STF01
1513	CONFIRMADA	LLAMADA TELEFONICA	2023-01-04	251606.00	1631956907	STF01
1514	CONFIRMADA	CORREO	2022-09-12	278599.00	1787501891	STF03
1515	CONFIRMADA	REFERIDO	2020-02-24	349817.00	1041975258	STF01
1516	CONFIRMADA	REDES SOCIALES	2019-08-14	317052.00	1778141926	STF02
1517	CONFIRMADA	LLAMADA TELEFONICA	2022-08-11	415406.00	1167386679	STF01
1518	CONFIRMADA	WHATSAPP	2021-04-26	241745.00	1422314667	STF03
1519	CONFIRMADA	CORREO	2019-10-09	283972.00	1490844569	STF02
1520	CONFIRMADA	REDES SOCIALES	2022-08-22	165452.00	1666421753	STF03
1521	CONFIRMADA	REDES SOCIALES	2019-06-12	189385.00	1193115306	STF03
1522	CONFIRMADA	LLAMADA TELEFONICA	2020-12-21	382115.00	1864093182	STF01
1523	CONFIRMADA	LLAMADA TELEFONICA	2019-06-16	340432.00	1416137157	STF01
1524	CONFIRMADA	REDES SOCIALES	2024-10-04	261435.00	1083528498	STF03
1525	CONFIRMADA	LLAMADA TELEFONICA	2022-09-29	163705.00	1419417107	STF01
1526	CONFIRMADA	WHATSAPP	2019-09-21	341826.00	1270386383	STF01
1527	CONFIRMADA	CORREO	2024-04-12	354654.00	1405864092	STF03
1528	CONFIRMADA	CORREO	2022-06-23	95536.00	1343929963	STF03
1529	CONFIRMADA	CORREO	2024-05-08	386282.00	1045516867	STF01
1530	CONFIRMADA	WHATSAPP	2023-10-19	114247.00	1918835899	STF01
1531	CONFIRMADA	LLAMADA TELEFONICA	2020-12-30	211784.00	1127901676	STF03
1532	CONFIRMADA	WHATSAPP	2019-12-24	112382.00	1454657901	STF02
1533	CONFIRMADA	WHATSAPP	2023-06-12	279406.00	1593506873	STF02
1534	CONFIRMADA	LLAMADA TELEFONICA	2022-02-13	324785.00	1682502627	STF02
1535	CONFIRMADA	LLAMADA TELEFONICA	2025-01-26	343631.00	1680095673	STF02
1536	CONFIRMADA	REDES SOCIALES	2022-03-13	457247.00	1415109500	STF03
1537	CONFIRMADA	LLAMADA TELEFONICA	2024-06-13	169671.00	1605462995	STF01
1538	CONFIRMADA	LLAMADA TELEFONICA	2023-07-28	261421.00	1089252687	STF01
1539	CONFIRMADA	WHATSAPP	2023-03-23	380983.00	1076374647	STF02
1540	CONFIRMADA	REFERIDO	2019-09-02	485084.00	1054216554	STF03
1541	CONFIRMADA	LLAMADA TELEFONICA	2019-04-21	142656.00	1864383026	STF03
1542	CONFIRMADA	LLAMADA TELEFONICA	2025-01-28	196438.00	1263427561	STF01
1543	CONFIRMADA	WHATSAPP	2019-03-16	325018.00	1537584488	STF01
1544	CONFIRMADA	REDES SOCIALES	2020-02-05	106288.00	1344786348	STF01
1545	CONFIRMADA	CORREO	2019-12-09	362241.00	1203968909	STF01
1546	CONFIRMADA	LLAMADA TELEFONICA	2023-10-10	243810.00	1218506523	STF02
1547	CONFIRMADA	LLAMADA TELEFONICA	2020-05-25	103494.00	1111671499	STF01
1548	CONFIRMADA	REDES SOCIALES	2021-09-26	244567.00	1020921984	STF01
1549	CONFIRMADA	REDES SOCIALES	2021-02-09	256414.00	1223998980	STF03
1550	CONFIRMADA	CORREO	2020-08-16	317693.00	1669253556	STF01
1551	CONFIRMADA	WHATSAPP	2024-08-29	453365.00	1022592522	STF02
1552	CONFIRMADA	CORREO	2020-02-18	410441.00	1757397091	STF03
1553	CONFIRMADA	LLAMADA TELEFONICA	2024-04-07	328909.00	1386018072	STF02
1554	CONFIRMADA	CORREO	2021-02-17	103729.00	1917356957	STF01
1555	CONFIRMADA	REDES SOCIALES	2023-10-28	73030.00	1091038072	STF03
1556	CONFIRMADA	REDES SOCIALES	2019-03-13	362955.00	1812553699	STF01
1557	CONFIRMADA	REFERIDO	2021-04-15	271277.00	1399626520	STF01
1558	CONFIRMADA	LLAMADA TELEFONICA	2020-05-18	133671.00	1741759367	STF01
1559	CONFIRMADA	CORREO	2020-07-27	411448.00	1655318354	STF02
1560	CONFIRMADA	REFERIDO	2023-04-19	330837.00	1968889416	STF01
1561	CONFIRMADA	REDES SOCIALES	2024-08-23	162867.00	1538597770	STF01
1562	CONFIRMADA	LLAMADA TELEFONICA	2021-12-24	73094.00	1641274057	STF02
1563	CONFIRMADA	CORREO	2021-08-14	211406.00	1236084614	STF02
1564	CONFIRMADA	WHATSAPP	2020-08-18	240751.00	1685381052	STF01
1565	CONFIRMADA	REFERIDO	2021-11-23	174278.00	1039703861	STF01
1566	CONFIRMADA	CORREO	2022-12-14	259788.00	1253475646	STF02
1567	CONFIRMADA	REFERIDO	2021-10-08	215644.00	1259854800	STF02
1568	CONFIRMADA	REFERIDO	2019-10-08	212304.00	1204561555	STF03
1569	CONFIRMADA	LLAMADA TELEFONICA	2020-02-16	259898.00	1100836481	STF01
1570	CONFIRMADA	LLAMADA TELEFONICA	2022-02-20	46490.00	1551707633	STF03
1571	CONFIRMADA	WHATSAPP	2019-02-15	71416.00	1300931839	STF01
1572	CONFIRMADA	WHATSAPP	2019-07-05	68912.00	1933729913	STF02
1573	CONFIRMADA	REDES SOCIALES	2022-07-30	46069.00	1596399157	STF02
1574	CONFIRMADA	REFERIDO	2023-12-14	404380.00	1881638781	STF01
1575	CONFIRMADA	CORREO	2019-07-16	276338.00	1166861277	STF03
1576	CONFIRMADA	WHATSAPP	2020-04-07	131469.00	1640749632	STF03
1577	CONFIRMADA	REDES SOCIALES	2020-08-12	225736.00	1838819285	STF01
1578	CONFIRMADA	LLAMADA TELEFONICA	2021-07-28	128499.00	1808469970	STF02
1579	CONFIRMADA	WHATSAPP	2022-01-19	358782.00	1897920692	STF01
1580	CONFIRMADA	LLAMADA TELEFONICA	2019-12-16	344899.00	1058108381	STF03
1581	CONFIRMADA	WHATSAPP	2023-07-06	109836.00	1232317863	STF03
1582	CONFIRMADA	REFERIDO	2022-05-31	200125.00	1725308984	STF02
1583	CONFIRMADA	CORREO	2023-01-31	138310.00	1628870403	STF03
1584	CONFIRMADA	CORREO	2021-04-24	345124.00	1720359248	STF01
1585	CONFIRMADA	LLAMADA TELEFONICA	2024-12-22	291685.00	1922128577	STF02
1586	CONFIRMADA	LLAMADA TELEFONICA	2020-07-17	300828.00	1580029091	STF01
1587	CONFIRMADA	REFERIDO	2021-02-19	166648.00	1405817763	STF02
1588	CONFIRMADA	LLAMADA TELEFONICA	2023-12-21	257112.00	1280389928	STF03
1589	CONFIRMADA	REDES SOCIALES	2024-11-17	245065.00	1471771788	STF01
1590	CONFIRMADA	CORREO	2024-06-16	463453.00	1753463126	STF03
1591	CONFIRMADA	REDES SOCIALES	2019-03-31	391768.00	1960618335	STF03
1592	CONFIRMADA	WHATSAPP	2023-07-05	225982.00	1065761959	STF02
1593	CONFIRMADA	CORREO	2019-04-06	73622.00	1481708505	STF02
1594	CONFIRMADA	LLAMADA TELEFONICA	2025-05-10	77784.00	1929124097	STF02
1595	CONFIRMADA	WHATSAPP	2022-02-26	414001.00	1996779429	STF01
1596	CONFIRMADA	CORREO	2022-02-02	219322.00	1788276940	STF03
1597	CONFIRMADA	REFERIDO	2022-08-14	248634.00	1683880178	STF01
1598	CONFIRMADA	WHATSAPP	2025-01-13	161116.00	1300201589	STF02
1599	CONFIRMADA	CORREO	2021-08-04	325306.00	1638945776	STF03
1600	CONFIRMADA	WHATSAPP	2020-03-23	334745.00	1125677966	STF01
1601	CONFIRMADA	CORREO	2024-11-09	104295.00	1303756905	STF02
1602	CONFIRMADA	REFERIDO	2020-07-16	63729.00	1593822136	STF02
1603	CONFIRMADA	REDES SOCIALES	2021-02-25	209709.00	1283191065	STF01
1604	CONFIRMADA	LLAMADA TELEFONICA	2023-10-04	350166.00	1508223094	STF03
1605	CONFIRMADA	WHATSAPP	2024-11-27	57248.00	1270949634	STF01
1606	CONFIRMADA	REDES SOCIALES	2021-11-30	265742.00	1548337558	STF02
1607	CONFIRMADA	WHATSAPP	2019-10-11	127990.00	1838247372	STF02
1608	CONFIRMADA	WHATSAPP	2022-09-30	265787.00	1679787577	STF02
1609	CONFIRMADA	CORREO	2019-04-19	234448.00	1234227944	STF01
1610	CONFIRMADA	CORREO	2019-09-28	261190.00	1314202958	STF02
1611	CONFIRMADA	REFERIDO	2022-04-14	141497.00	1251058824	STF03
1612	CONFIRMADA	LLAMADA TELEFONICA	2023-01-21	208791.00	1193211969	STF03
1613	CONFIRMADA	WHATSAPP	2024-10-14	325602.00	1735671925	STF01
1614	CONFIRMADA	LLAMADA TELEFONICA	2021-03-22	99150.00	1355918173	STF03
1615	CONFIRMADA	REDES SOCIALES	2019-11-14	154662.00	1507445443	STF02
1616	CONFIRMADA	REDES SOCIALES	2020-04-24	234603.00	1352517204	STF01
1617	CONFIRMADA	WHATSAPP	2024-05-04	138760.00	1720509893	STF03
1618	CONFIRMADA	LLAMADA TELEFONICA	2020-11-16	238848.00	1656027058	STF01
1619	CONFIRMADA	CORREO	2022-03-18	194438.00	1083932272	STF02
1620	CONFIRMADA	WHATSAPP	2021-06-17	331955.00	1291247389	STF02
1621	CONFIRMADA	REDES SOCIALES	2019-02-21	203710.00	1399301476	STF01
1622	CONFIRMADA	REFERIDO	2021-06-18	280491.00	1443675929	STF01
1623	CONFIRMADA	REFERIDO	2021-04-14	435133.00	1654588046	STF01
1624	CONFIRMADA	REDES SOCIALES	2024-06-08	300705.00	1423799052	STF02
1625	CONFIRMADA	REFERIDO	2020-01-14	236571.00	1003790393	STF03
1626	CONFIRMADA	WHATSAPP	2023-09-24	337201.00	1125599413	STF02
1627	CONFIRMADA	LLAMADA TELEFONICA	2024-08-31	230009.00	1171457990	STF01
1628	CONFIRMADA	REFERIDO	2020-05-25	341077.00	1938753343	STF03
1629	CONFIRMADA	CORREO	2024-12-26	296646.00	1331041751	STF03
1630	CONFIRMADA	REFERIDO	2024-09-24	293038.00	1211167169	STF01
1631	CONFIRMADA	LLAMADA TELEFONICA	2024-11-23	193946.00	1753313643	STF01
1632	CONFIRMADA	REDES SOCIALES	2021-08-21	299316.00	1729810007	STF01
1633	CONFIRMADA	CORREO	2025-02-05	64331.00	1755776771	STF01
1634	CONFIRMADA	WHATSAPP	2020-10-20	301180.00	1746164254	STF01
1635	CONFIRMADA	WHATSAPP	2023-11-30	274078.00	1625602835	STF02
1636	CONFIRMADA	REFERIDO	2023-03-20	78316.00	1224498048	STF03
1637	CONFIRMADA	CORREO	2022-08-29	188610.00	1833508236	STF02
1638	CONFIRMADA	CORREO	2021-11-25	393500.00	1866149035	STF03
1639	CONFIRMADA	LLAMADA TELEFONICA	2019-01-04	385877.00	1853233955	STF03
1001	CONFIRMADA	LLAMADA TELEFONICA	2019-11-15	307951.00	1045697382	STF03
1002	CONFIRMADA	REDES SOCIALES	2023-06-25	325414.00	1032568749	STF02
1003	CONFIRMADA	WHATSAPP	2021-12-02	419122.00	1038457296	STF03
1004	CONFIRMADA	REFERIDO	2022-09-19	147156.00	1026745832	STF03
1005	CONFIRMADA	REDES SOCIALES	2023-07-18	238764.00	1037952684	STF01
1006	CONFIRMADA	REDES SOCIALES	2025-02-04	347031.00	1043687524	STF03
1007	CONFIRMADA	REDES SOCIALES	2019-01-09	124896.00	1033576842	STF01
1008	CONFIRMADA	WHATSAPP	2022-01-03	325157.00	1029485736	STF02
1009	CONFIRMADA	WHATSAPP	2021-10-01	386470.00	1098762232	STF03
1010	CONFIRMADA	REFERIDO	2022-07-18	363124.00	1054321098	STF01
1084	CONFIRMADA	CORREO	2022-04-17	358538.00	1065879123	STF01
1676	CONFIRMADA	WHATSAPP	2024-06-30	225000.00	1102314457	STF01
1640	CONFIRMADA	REFERIDO	2019-02-05	134772.00	1438677097	STF03
1641	CONFIRMADA	CORREO	2021-08-05	326382.00	1263203026	STF03
1642	CONFIRMADA	REDES SOCIALES	2019-05-24	243863.00	1165956354	STF02
1643	CONFIRMADA	REDES SOCIALES	2020-09-29	253912.00	1945386662	STF01
1644	CONFIRMADA	WHATSAPP	2024-02-02	216182.00	1796116097	STF02
1645	CONFIRMADA	REDES SOCIALES	2024-03-05	317671.00	1067635015	STF03
1646	CONFIRMADA	WHATSAPP	2019-04-13	318315.00	1231108263	STF01
1647	CONFIRMADA	CORREO	2024-11-23	247769.00	1146134107	STF01
1648	CONFIRMADA	WHATSAPP	2023-03-20	411420.00	1837224001	STF02
1649	CONFIRMADA	LLAMADA TELEFONICA	2022-09-19	88692.00	1115673167	STF03
1650	CONFIRMADA	WHATSAPP	2020-01-16	36781.00	1020310398	STF03
1651	CONFIRMADA	CORREO	2020-07-10	390644.00	1815004195	STF03
1652	CONFIRMADA	LLAMADA TELEFONICA	2020-04-26	262002.00	1180598299	STF02
1653	CONFIRMADA	WHATSAPP	2022-10-01	215497.00	1222220742	STF03
1654	CONFIRMADA	REFERIDO	2023-03-18	293323.00	1300538656	STF01
1655	CONFIRMADA	REDES SOCIALES	2021-10-17	317572.00	1681289427	STF03
1656	CONFIRMADA	REDES SOCIALES	2023-01-04	437732.00	1554798202	STF01
1657	CONFIRMADA	REDES SOCIALES	2022-09-30	466393.00	1177638502	STF01
1658	CONFIRMADA	REFERIDO	2025-04-11	179953.00	1382835172	STF03
1659	CONFIRMADA	REDES SOCIALES	2022-03-04	150968.00	1768778021	STF02
1660	CONFIRMADA	REDES SOCIALES	2019-03-30	364171.00	1329515246	STF02
1661	CONFIRMADA	REFERIDO	2020-01-04	143938.00	1381026101	STF03
1662	CONFIRMADA	WHATSAPP	2019-12-06	69010.00	1054122280	STF01
1663	CONFIRMADA	REFERIDO	2023-10-02	548107.00	1749163283	STF01
1664	CONFIRMADA	REFERIDO	2020-07-14	264004.00	1038861012	STF03
1665	CONFIRMADA	CORREO	2021-04-19	296299.00	1634289995	STF01
1666	CONFIRMADA	REFERIDO	2019-07-14	121261.00	1659896058	STF01
1667	CONFIRMADA	REFERIDO	2019-08-26	152492.00	1962244664	STF01
1668	CONFIRMADA	LLAMADA TELEFONICA	2023-01-15	319284.00	1728689252	STF01
1669	CONFIRMADA	LLAMADA TELEFONICA	2022-02-07	148425.00	1602720554	STF03
1670	CONFIRMADA	LLAMADA TELEFONICA	2021-01-20	365995.00	1012802155	STF01
1671	CONFIRMADA	REFERIDO	2023-03-02	241545.00	1194704269	STF01
1672	CONFIRMADA	WHATSAPP	2019-06-20	239079.00	1341234686	STF03
1673	CONFIRMADA	LLAMADA TELEFONICA	2025-02-27	100709.00	1752062831	STF02
1674	CONFIRMADA	CORREO	2022-05-12	156416.00	1115439806	STF02
1675	CONFIRMADA	WHATSAPP	2024-03-16	332498.00	1572760719	STF02
1677	CONFIRMADA	CORREO	2022-01-05	646452.00	1946415469	STF01
1678	CONFIRMADA	CORREO	2024-08-26	302840.00	1937598799	STF02
1679	CONFIRMADA	REFERIDO	2021-10-03	898248.00	1629949814	STF02
1680	CONFIRMADA	LLAMADA TELEFONICA	2020-12-20	452205.00	1659843290	STF01
1681	CONFIRMADA	WHATSAPP	2022-10-06	959130.00	1373516410	STF03
1682	CONFIRMADA	LLAMADA TELEFONICA	2024-10-24	697074.00	1635418500	STF02
1683	CONFIRMADA	CORREO	2020-06-16	169792.00	1721355935	STF02
1684	CONFIRMADA	REFERIDO	2020-07-23	270942.00	1419876028	STF03
1685	CONFIRMADA	LLAMADA TELEFONICA	2021-11-14	322980.00	1359118468	STF03
1686	CONFIRMADA	REDES SOCIALES	2019-04-20	624366.00	1407630662	STF03
1687	CONFIRMADA	CORREO	2022-10-28	719250.00	1640553597	STF03
1688	CONFIRMADA	WHATSAPP	2020-02-15	73143.00	1072141457	STF03
1689	CONFIRMADA	LLAMADA TELEFONICA	2020-12-13	652223.00	1079475888	STF03
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            4954.dat                                                                                            0000600 0004000 0002000 00000000511 15015342721 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        101	HD	H001
102	HI	H001
103	HD	H001
104	HI	H001
105	HD	H001
106	HI	H001
107	HD	H001
108	HI	H001
109	HD	H001
110	HI	H001
111	HD	H001
112	HI	H001
113	HD	H001
114	HI	H001
115	HD	H001
116	HI	H001
117	HD	H001
118	HI	H001
119	HD	H001
120	HI	H001
121	HI	H001
122	HI	H001
123	HI	H001
124	HI	H001
125	HI	H001
126	HI	H001
127	HI	H001
\.


                                                                                                                                                                                       4951.dat                                                                                            0000600 0004000 0002000 00000000257 15015342721 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        HI	HABITACION INDIVIDUAL	25000.00	HABITACION COMODA PARA UNA PERSONA CON CAMA SENCILLA
HD	HABITACION DOBLE	35000.00	HABITACION ESPACIOSA PARA DOS PERSONAS CON CAMA DOBLE
\.


                                                                                                                                                                                                                                                                                                                                                 4965.dat                                                                                            0000600 0004000 0002000 00000110145 15015342721 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	Lavado Manual Ropa	15000.00	1
2	Transporte al aeropuerto	40672.00	981
3	Limpieza de habitación	25851.00	304
4	Acceso al gimnasio	14171.00	522
5	Limpieza de habitación	38938.00	413
6	Desayuno buffet	19010.00	341
7	Acceso al gimnasio	23107.00	1000
8	Excursión local	19004.00	104
9	Cena en restaurante asociado	46299.00	268
10	Clases de cocina	21261.00	354
11	Excursión local	27492.00	811
12	Servicio de lavandería	44284.00	308
13	Masaje en spa	48425.00	570
14	Transporte al aeropuerto	36470.00	608
15	Excursión local	33966.00	442
16	Servicio de lavandería	17741.00	905
17	Clases de cocina	27907.00	815
18	Alquiler de coche	15577.00	378
19	Transporte al aeropuerto	34950.00	206
20	Limpieza de habitación	32951.00	262
21	Alquiler de coche	25414.00	224
22	Limpieza de habitación	34122.00	427
23	Transporte al aeropuerto	22156.00	210
24	Servicio de lavandería	13764.00	522
25	Alquiler de coche	22031.00	552
26	Masaje en spa	49896.00	582
27	Limpieza de habitación	10157.00	408
28	Alquiler de coche	11140.00	591
29	Excursión local	44374.00	216
30	Servicio de lavandería	16375.00	420
31	Servicio de lavandería	48143.00	665
32	Alquiler de coche	24293.00	308
33	Masaje en spa	44056.00	342
34	Limpieza de habitación	48629.00	77
35	Masaje en spa	14099.00	277
36	Excursión local	11247.00	984
37	Transporte al aeropuerto	41949.00	70
38	Cena en restaurante asociado	48183.00	188
39	Transporte al aeropuerto	11468.00	752
40	Alquiler de coche	42149.00	241
41	Desayuno buffet	15415.00	78
42	Alquiler de coche	32549.00	823
43	Acceso al gimnasio	12322.00	222
44	Excursión local	31389.00	488
45	Masaje en spa	11169.00	704
46	Acceso al gimnasio	18733.00	708
47	Transporte al aeropuerto	31660.00	717
48	Excursión local	18373.00	906
49	Alquiler de coche	48176.00	612
50	Servicio de lavandería	16494.00	973
51	Servicio de lavandería	16364.00	223
52	Limpieza de habitación	15299.00	46
53	Clases de cocina	17651.00	924
54	Desayuno buffet	30954.00	800
55	Acceso al gimnasio	38380.00	272
56	Limpieza de habitación	20305.00	246
57	Alquiler de coche	13677.00	418
58	Masaje en spa	37671.00	351
59	Excursión local	15598.00	422
60	Masaje en spa	29837.00	605
61	Excursión local	28467.00	370
62	Limpieza de habitación	48344.00	94
63	Servicio de lavandería	48656.00	247
64	Servicio de lavandería	43351.00	285
65	Alquiler de coche	33278.00	374
66	Servicio de lavandería	34788.00	205
67	Acceso al gimnasio	31644.00	604
68	Excursión local	14904.00	122
69	Masaje en spa	34898.00	49
70	Transporte al aeropuerto	11840.00	141
71	Excursión local	46666.00	303
72	Servicio de lavandería	44162.00	760
73	Alquiler de coche	11419.00	177
74	Alquiler de coche	34780.00	174
75	Cena en restaurante asociado	48488.00	944
76	Transporte al aeropuerto	12719.00	157
77	Masaje en spa	28336.00	702
78	Desayuno buffet	32499.00	349
79	Clases de cocina	16132.00	833
80	Desayuno buffet	43899.00	320
81	Masaje en spa	41236.00	2
82	Clases de cocina	37375.00	133
83	Clases de cocina	19560.00	103
84	Excursión local	44124.00	40
85	Desayuno buffet	46935.00	4
86	Limpieza de habitación	43228.00	993
87	Alquiler de coche	25648.00	649
88	Excursión local	29262.00	890
89	Desayuno buffet	17215.00	35
90	Masaje en spa	42053.00	508
91	Excursión local	49118.00	310
92	Masaje en spa	21232.00	520
93	Excursión local	48872.00	165
94	Alquiler de coche	43134.00	786
95	Alquiler de coche	44401.00	625
96	Cena en restaurante asociado	35322.00	355
97	Acceso al gimnasio	20784.00	309
98	Desayuno buffet	42366.00	836
99	Limpieza de habitación	42556.00	755
100	Masaje en spa	15995.00	577
101	Masaje en spa	31545.00	692
102	Cena en restaurante asociado	29079.00	175
103	Alquiler de coche	25709.00	527
104	Cena en restaurante asociado	31416.00	860
105	Alquiler de coche	32498.00	711
106	Acceso al gimnasio	20992.00	73
107	Acceso al gimnasio	31990.00	247
108	Alquiler de coche	21037.00	638
109	Servicio de lavandería	37048.00	791
110	Alquiler de coche	33340.00	150
111	Masaje en spa	45497.00	197
112	Masaje en spa	24791.00	775
113	Masaje en spa	38952.00	127
114	Alquiler de coche	30550.00	624
115	Excursión local	35912.00	766
116	Servicio de lavandería	29853.00	958
117	Alquiler de coche	20010.00	750
118	Servicio de lavandería	34098.00	409
119	Clases de cocina	28188.00	604
120	Acceso al gimnasio	45305.00	856
121	Alquiler de coche	19710.00	33
122	Clases de cocina	35741.00	614
123	Cena en restaurante asociado	39283.00	826
124	Cena en restaurante asociado	36705.00	242
125	Cena en restaurante asociado	11571.00	986
126	Cena en restaurante asociado	18451.00	929
127	Acceso al gimnasio	32609.00	377
128	Acceso al gimnasio	26077.00	315
129	Cena en restaurante asociado	39046.00	846
130	Limpieza de habitación	29038.00	485
131	Desayuno buffet	31196.00	416
132	Servicio de lavandería	35316.00	156
133	Desayuno buffet	29681.00	354
134	Cena en restaurante asociado	18430.00	350
135	Acceso al gimnasio	46228.00	103
136	Servicio de lavandería	43666.00	960
137	Alquiler de coche	47610.00	123
138	Transporte al aeropuerto	23900.00	689
139	Cena en restaurante asociado	16277.00	870
140	Excursión local	38772.00	536
141	Excursión local	39732.00	140
142	Alquiler de coche	16013.00	115
143	Desayuno buffet	14406.00	459
144	Alquiler de coche	31182.00	790
145	Desayuno buffet	49013.00	723
146	Masaje en spa	39750.00	104
147	Limpieza de habitación	18943.00	36
148	Masaje en spa	21256.00	410
149	Masaje en spa	48001.00	873
150	Cena en restaurante asociado	42491.00	313
151	Servicio de lavandería	40510.00	792
152	Excursión local	45473.00	124
153	Transporte al aeropuerto	26568.00	647
154	Excursión local	32769.00	223
155	Servicio de lavandería	37253.00	912
156	Acceso al gimnasio	20098.00	53
157	Desayuno buffet	31657.00	993
158	Cena en restaurante asociado	25239.00	986
159	Limpieza de habitación	22233.00	317
160	Alquiler de coche	12775.00	449
161	Excursión local	13997.00	408
162	Clases de cocina	14681.00	194
163	Clases de cocina	49184.00	388
164	Clases de cocina	21452.00	646
165	Acceso al gimnasio	49719.00	781
166	Excursión local	12826.00	358
167	Servicio de lavandería	39758.00	440
168	Acceso al gimnasio	25402.00	225
169	Desayuno buffet	22701.00	161
170	Transporte al aeropuerto	16144.00	699
171	Cena en restaurante asociado	16257.00	90
172	Acceso al gimnasio	44572.00	587
173	Servicio de lavandería	36282.00	532
174	Desayuno buffet	20280.00	899
175	Masaje en spa	49014.00	269
176	Masaje en spa	36581.00	332
177	Masaje en spa	17906.00	144
178	Acceso al gimnasio	31578.00	858
179	Masaje en spa	35774.00	997
180	Cena en restaurante asociado	45973.00	805
181	Desayuno buffet	18610.00	867
182	Servicio de lavandería	27808.00	655
183	Alquiler de coche	45896.00	569
184	Acceso al gimnasio	26923.00	237
185	Servicio de lavandería	48002.00	749
186	Excursión local	17430.00	702
187	Acceso al gimnasio	46030.00	439
188	Transporte al aeropuerto	20430.00	445
189	Cena en restaurante asociado	20638.00	816
190	Transporte al aeropuerto	23746.00	663
191	Servicio de lavandería	17089.00	827
192	Servicio de lavandería	39078.00	924
193	Excursión local	12153.00	196
194	Acceso al gimnasio	25231.00	198
195	Desayuno buffet	15345.00	122
196	Acceso al gimnasio	40583.00	306
197	Limpieza de habitación	29915.00	281
198	Cena en restaurante asociado	19627.00	856
199	Alquiler de coche	33049.00	158
200	Cena en restaurante asociado	37132.00	930
201	Transporte al aeropuerto	39332.00	381
202	Cena en restaurante asociado	36119.00	890
203	Masaje en spa	30012.00	201
204	Alquiler de coche	19785.00	414
205	Excursión local	28912.00	835
206	Desayuno buffet	30497.00	602
207	Clases de cocina	33269.00	460
208	Servicio de lavandería	49001.00	264
209	Transporte al aeropuerto	30633.00	445
210	Clases de cocina	37638.00	388
211	Acceso al gimnasio	21746.00	123
212	Limpieza de habitación	39441.00	720
213	Clases de cocina	35219.00	425
214	Servicio de lavandería	48868.00	139
215	Cena en restaurante asociado	19132.00	538
216	Acceso al gimnasio	37470.00	495
217	Servicio de lavandería	38113.00	332
218	Transporte al aeropuerto	46393.00	534
219	Excursión local	14193.00	361
220	Excursión local	26576.00	764
221	Transporte al aeropuerto	19738.00	539
222	Servicio de lavandería	44753.00	820
223	Desayuno buffet	26950.00	745
224	Servicio de lavandería	23398.00	43
225	Desayuno buffet	20740.00	589
226	Masaje en spa	40221.00	567
227	Acceso al gimnasio	27001.00	679
228	Transporte al aeropuerto	12820.00	100
229	Alquiler de coche	41170.00	503
230	Excursión local	13014.00	724
231	Alquiler de coche	11713.00	704
232	Masaje en spa	23756.00	6
233	Masaje en spa	14599.00	312
234	Cena en restaurante asociado	34817.00	337
235	Transporte al aeropuerto	30402.00	193
236	Servicio de lavandería	45806.00	1
237	Limpieza de habitación	44345.00	450
238	Desayuno buffet	26372.00	345
239	Excursión local	31052.00	899
240	Servicio de lavandería	48385.00	197
241	Alquiler de coche	12515.00	131
242	Cena en restaurante asociado	25432.00	77
243	Alquiler de coche	33585.00	304
244	Desayuno buffet	22705.00	970
245	Transporte al aeropuerto	40826.00	9
246	Acceso al gimnasio	12004.00	792
247	Excursión local	26936.00	349
248	Limpieza de habitación	16682.00	554
249	Clases de cocina	12397.00	476
250	Alquiler de coche	27784.00	298
251	Desayuno buffet	39632.00	428
252	Transporte al aeropuerto	34656.00	319
253	Alquiler de coche	38135.00	804
254	Masaje en spa	24881.00	978
255	Servicio de lavandería	10997.00	874
256	Alquiler de coche	28671.00	645
257	Limpieza de habitación	36421.00	329
258	Transporte al aeropuerto	38333.00	273
259	Alquiler de coche	38834.00	548
260	Acceso al gimnasio	46656.00	993
261	Cena en restaurante asociado	33688.00	274
262	Servicio de lavandería	24018.00	291
263	Clases de cocina	33538.00	781
264	Acceso al gimnasio	47241.00	608
265	Acceso al gimnasio	18810.00	536
266	Clases de cocina	30744.00	411
267	Servicio de lavandería	19567.00	376
268	Clases de cocina	31414.00	730
269	Alquiler de coche	16693.00	972
270	Acceso al gimnasio	31965.00	920
271	Masaje en spa	40841.00	1000
272	Transporte al aeropuerto	13909.00	756
273	Acceso al gimnasio	30979.00	274
274	Limpieza de habitación	24982.00	861
275	Transporte al aeropuerto	41286.00	977
276	Excursión local	20225.00	611
277	Cena en restaurante asociado	21461.00	443
278	Clases de cocina	13319.00	586
279	Clases de cocina	13580.00	142
280	Clases de cocina	47170.00	637
281	Transporte al aeropuerto	25489.00	471
282	Transporte al aeropuerto	37025.00	223
283	Acceso al gimnasio	26145.00	497
284	Limpieza de habitación	27712.00	817
285	Cena en restaurante asociado	30613.00	903
286	Cena en restaurante asociado	29506.00	318
287	Excursión local	16569.00	12
288	Limpieza de habitación	37561.00	557
289	Transporte al aeropuerto	40233.00	548
290	Masaje en spa	28131.00	677
291	Masaje en spa	21913.00	721
292	Limpieza de habitación	39080.00	975
293	Transporte al aeropuerto	47241.00	599
294	Transporte al aeropuerto	15973.00	437
295	Cena en restaurante asociado	45383.00	554
296	Clases de cocina	49813.00	354
297	Servicio de lavandería	21223.00	892
298	Transporte al aeropuerto	17630.00	127
299	Masaje en spa	41099.00	932
300	Transporte al aeropuerto	36663.00	16
301	Clases de cocina	28871.00	918
302	Cena en restaurante asociado	25568.00	634
303	Acceso al gimnasio	49854.00	111
304	Alquiler de coche	25245.00	831
305	Transporte al aeropuerto	38942.00	741
306	Servicio de lavandería	40183.00	616
307	Transporte al aeropuerto	37171.00	49
308	Cena en restaurante asociado	19350.00	621
309	Masaje en spa	10466.00	598
310	Desayuno buffet	47638.00	560
311	Limpieza de habitación	12827.00	815
312	Clases de cocina	21924.00	655
313	Excursión local	18674.00	329
314	Servicio de lavandería	13137.00	215
315	Servicio de lavandería	14120.00	74
316	Excursión local	45562.00	59
317	Excursión local	36875.00	230
318	Cena en restaurante asociado	37669.00	444
319	Masaje en spa	11469.00	60
320	Desayuno buffet	11183.00	510
321	Masaje en spa	47938.00	249
322	Alquiler de coche	39444.00	751
323	Desayuno buffet	48548.00	48
324	Excursión local	39119.00	351
325	Alquiler de coche	17785.00	310
326	Excursión local	47918.00	572
327	Excursión local	45930.00	499
328	Excursión local	41764.00	363
329	Excursión local	21256.00	942
330	Alquiler de coche	42465.00	367
331	Clases de cocina	42260.00	105
332	Cena en restaurante asociado	25315.00	439
333	Desayuno buffet	42576.00	798
334	Acceso al gimnasio	47418.00	499
335	Acceso al gimnasio	49608.00	392
336	Masaje en spa	11345.00	623
337	Excursión local	43463.00	761
338	Desayuno buffet	32318.00	696
339	Excursión local	22311.00	218
340	Acceso al gimnasio	31781.00	404
341	Acceso al gimnasio	31824.00	618
342	Acceso al gimnasio	17749.00	514
343	Alquiler de coche	37789.00	570
344	Limpieza de habitación	14190.00	91
345	Acceso al gimnasio	20844.00	288
346	Acceso al gimnasio	18079.00	786
347	Transporte al aeropuerto	33816.00	81
348	Clases de cocina	30024.00	306
349	Clases de cocina	21473.00	595
350	Limpieza de habitación	16674.00	17
351	Transporte al aeropuerto	22828.00	74
352	Clases de cocina	42570.00	411
353	Cena en restaurante asociado	35734.00	402
354	Excursión local	28665.00	439
355	Transporte al aeropuerto	27635.00	889
356	Clases de cocina	20399.00	175
357	Alquiler de coche	32845.00	682
358	Acceso al gimnasio	10291.00	31
359	Alquiler de coche	27360.00	303
360	Cena en restaurante asociado	16442.00	86
361	Cena en restaurante asociado	24435.00	338
362	Excursión local	13225.00	762
363	Limpieza de habitación	42168.00	420
364	Acceso al gimnasio	29218.00	418
365	Alquiler de coche	31982.00	585
366	Masaje en spa	27789.00	963
367	Masaje en spa	25939.00	753
368	Transporte al aeropuerto	18510.00	636
369	Clases de cocina	22378.00	85
370	Transporte al aeropuerto	14561.00	890
371	Excursión local	44767.00	935
372	Servicio de lavandería	14789.00	339
373	Desayuno buffet	44775.00	501
374	Cena en restaurante asociado	42711.00	516
375	Cena en restaurante asociado	27317.00	412
376	Acceso al gimnasio	34550.00	85
377	Masaje en spa	14069.00	814
378	Desayuno buffet	13249.00	322
379	Limpieza de habitación	49896.00	398
380	Masaje en spa	20438.00	827
381	Limpieza de habitación	36312.00	986
382	Servicio de lavandería	37777.00	192
383	Masaje en spa	21499.00	708
384	Acceso al gimnasio	11717.00	621
385	Clases de cocina	10908.00	163
386	Acceso al gimnasio	33708.00	482
387	Excursión local	45609.00	276
388	Excursión local	22774.00	978
389	Clases de cocina	39334.00	193
390	Alquiler de coche	20635.00	124
391	Limpieza de habitación	25144.00	441
392	Servicio de lavandería	46734.00	28
393	Excursión local	38905.00	527
394	Cena en restaurante asociado	21757.00	888
395	Alquiler de coche	10468.00	778
396	Masaje en spa	34904.00	913
397	Limpieza de habitación	47869.00	13
398	Cena en restaurante asociado	18488.00	163
399	Limpieza de habitación	25964.00	212
400	Masaje en spa	49843.00	249
401	Acceso al gimnasio	45993.00	192
402	Limpieza de habitación	11341.00	196
403	Servicio de lavandería	29083.00	992
404	Clases de cocina	15193.00	481
405	Cena en restaurante asociado	35834.00	211
406	Clases de cocina	36827.00	761
407	Servicio de lavandería	40886.00	140
408	Masaje en spa	35240.00	527
409	Transporte al aeropuerto	36467.00	630
410	Cena en restaurante asociado	21339.00	610
411	Cena en restaurante asociado	10870.00	721
412	Servicio de lavandería	23417.00	412
413	Excursión local	13779.00	103
414	Acceso al gimnasio	46631.00	788
415	Masaje en spa	45191.00	552
416	Excursión local	44954.00	163
417	Cena en restaurante asociado	42448.00	406
418	Transporte al aeropuerto	12810.00	841
419	Cena en restaurante asociado	48714.00	12
420	Limpieza de habitación	30654.00	273
421	Alquiler de coche	24937.00	831
422	Excursión local	26144.00	66
423	Limpieza de habitación	23185.00	883
424	Acceso al gimnasio	28488.00	838
425	Desayuno buffet	35182.00	452
426	Limpieza de habitación	33225.00	163
427	Excursión local	29076.00	88
428	Desayuno buffet	14208.00	567
429	Alquiler de coche	13137.00	742
430	Alquiler de coche	13185.00	280
431	Alquiler de coche	10940.00	592
432	Cena en restaurante asociado	35169.00	107
433	Transporte al aeropuerto	40013.00	312
434	Limpieza de habitación	18927.00	931
435	Masaje en spa	42487.00	878
436	Clases de cocina	37753.00	435
437	Desayuno buffet	37392.00	338
438	Limpieza de habitación	19946.00	621
439	Masaje en spa	15375.00	704
440	Acceso al gimnasio	12905.00	864
441	Servicio de lavandería	38348.00	272
442	Masaje en spa	11830.00	552
443	Limpieza de habitación	41544.00	74
444	Servicio de lavandería	21655.00	776
445	Excursión local	47799.00	587
446	Excursión local	49744.00	773
447	Excursión local	31841.00	884
448	Limpieza de habitación	27911.00	354
449	Clases de cocina	27955.00	671
450	Alquiler de coche	17215.00	206
451	Desayuno buffet	11708.00	87
452	Limpieza de habitación	46183.00	347
453	Desayuno buffet	25511.00	3
454	Masaje en spa	39429.00	463
455	Masaje en spa	13862.00	174
456	Transporte al aeropuerto	13882.00	669
457	Cena en restaurante asociado	20990.00	964
458	Excursión local	13324.00	528
459	Alquiler de coche	28316.00	927
460	Limpieza de habitación	37435.00	46
461	Acceso al gimnasio	46808.00	718
462	Acceso al gimnasio	38564.00	71
463	Transporte al aeropuerto	14874.00	513
464	Transporte al aeropuerto	17884.00	458
465	Excursión local	44937.00	901
466	Desayuno buffet	29716.00	465
467	Transporte al aeropuerto	16771.00	80
468	Servicio de lavandería	24509.00	26
469	Limpieza de habitación	42739.00	196
470	Masaje en spa	11097.00	474
471	Acceso al gimnasio	26681.00	548
472	Transporte al aeropuerto	46863.00	976
473	Desayuno buffet	21600.00	152
474	Alquiler de coche	31771.00	560
475	Acceso al gimnasio	19811.00	936
476	Desayuno buffet	41665.00	495
477	Limpieza de habitación	30446.00	573
478	Masaje en spa	26835.00	166
479	Clases de cocina	18100.00	29
480	Servicio de lavandería	15375.00	486
481	Cena en restaurante asociado	12900.00	913
482	Clases de cocina	17738.00	176
483	Masaje en spa	17046.00	202
484	Acceso al gimnasio	27017.00	875
485	Limpieza de habitación	44487.00	899
486	Acceso al gimnasio	29350.00	66
487	Transporte al aeropuerto	24300.00	988
488	Masaje en spa	18893.00	820
489	Desayuno buffet	36772.00	860
490	Servicio de lavandería	30946.00	960
491	Servicio de lavandería	10477.00	461
492	Excursión local	14929.00	91
493	Servicio de lavandería	25971.00	63
494	Clases de cocina	49766.00	941
495	Acceso al gimnasio	40807.00	477
496	Clases de cocina	49126.00	374
497	Transporte al aeropuerto	46618.00	272
498	Excursión local	17901.00	182
499	Acceso al gimnasio	31019.00	520
500	Acceso al gimnasio	35882.00	736
501	Masaje en spa	13269.00	281
502	Acceso al gimnasio	49127.00	742
503	Cena en restaurante asociado	14909.00	244
504	Desayuno buffet	47519.00	196
505	Masaje en spa	19866.00	964
506	Excursión local	30623.00	853
507	Acceso al gimnasio	28335.00	684
508	Alquiler de coche	20880.00	313
509	Limpieza de habitación	21616.00	338
510	Acceso al gimnasio	47309.00	501
511	Clases de cocina	43232.00	995
512	Excursión local	14112.00	660
513	Cena en restaurante asociado	29083.00	288
514	Cena en restaurante asociado	17875.00	152
515	Alquiler de coche	17632.00	545
516	Limpieza de habitación	17110.00	485
517	Excursión local	43089.00	689
518	Excursión local	38175.00	364
519	Clases de cocina	13438.00	255
520	Desayuno buffet	25486.00	75
521	Acceso al gimnasio	36923.00	935
522	Alquiler de coche	23069.00	41
523	Clases de cocina	24594.00	576
524	Masaje en spa	16230.00	653
525	Transporte al aeropuerto	41431.00	953
526	Servicio de lavandería	28840.00	593
527	Cena en restaurante asociado	15651.00	25
528	Masaje en spa	34741.00	319
529	Masaje en spa	36301.00	738
530	Clases de cocina	16206.00	698
531	Transporte al aeropuerto	36452.00	872
532	Excursión local	32291.00	253
533	Excursión local	13120.00	747
534	Excursión local	26638.00	443
535	Acceso al gimnasio	44313.00	674
536	Cena en restaurante asociado	28265.00	973
537	Servicio de lavandería	30302.00	336
538	Limpieza de habitación	41470.00	411
539	Masaje en spa	36628.00	1
540	Desayuno buffet	28964.00	185
541	Transporte al aeropuerto	36687.00	412
542	Limpieza de habitación	39750.00	823
543	Desayuno buffet	30411.00	263
544	Desayuno buffet	19815.00	792
545	Servicio de lavandería	39254.00	597
546	Limpieza de habitación	39402.00	319
547	Masaje en spa	31940.00	503
548	Servicio de lavandería	44654.00	180
549	Masaje en spa	19369.00	483
550	Acceso al gimnasio	17266.00	541
551	Limpieza de habitación	35686.00	593
552	Cena en restaurante asociado	44830.00	170
553	Desayuno buffet	34552.00	824
554	Limpieza de habitación	13304.00	874
555	Masaje en spa	21974.00	362
556	Alquiler de coche	14161.00	948
557	Masaje en spa	25231.00	321
558	Acceso al gimnasio	28765.00	489
559	Limpieza de habitación	36439.00	42
560	Acceso al gimnasio	43805.00	395
561	Excursión local	48254.00	726
562	Masaje en spa	18868.00	839
563	Desayuno buffet	37801.00	138
564	Acceso al gimnasio	46603.00	469
565	Clases de cocina	10590.00	213
566	Desayuno buffet	31561.00	944
567	Transporte al aeropuerto	38600.00	600
568	Cena en restaurante asociado	32244.00	453
569	Masaje en spa	33660.00	12
570	Acceso al gimnasio	46137.00	501
571	Acceso al gimnasio	23560.00	761
572	Transporte al aeropuerto	34124.00	662
573	Cena en restaurante asociado	40137.00	822
574	Alquiler de coche	42326.00	730
575	Excursión local	13016.00	116
576	Desayuno buffet	17813.00	536
577	Cena en restaurante asociado	41884.00	4
578	Alquiler de coche	39357.00	310
579	Excursión local	20015.00	305
580	Acceso al gimnasio	40871.00	1
581	Acceso al gimnasio	28388.00	58
582	Servicio de lavandería	24579.00	716
583	Cena en restaurante asociado	46595.00	113
584	Desayuno buffet	21264.00	713
585	Desayuno buffet	32704.00	550
586	Clases de cocina	33199.00	908
587	Limpieza de habitación	29082.00	505
588	Acceso al gimnasio	20466.00	735
589	Cena en restaurante asociado	11467.00	224
590	Alquiler de coche	42976.00	40
591	Acceso al gimnasio	40203.00	910
592	Cena en restaurante asociado	38772.00	89
593	Desayuno buffet	22743.00	920
594	Cena en restaurante asociado	35511.00	905
595	Acceso al gimnasio	11599.00	160
596	Acceso al gimnasio	37174.00	332
597	Servicio de lavandería	14798.00	515
598	Clases de cocina	39484.00	427
599	Limpieza de habitación	46260.00	549
600	Servicio de lavandería	39670.00	559
601	Servicio de lavandería	18747.00	878
602	Alquiler de coche	10901.00	448
603	Cena en restaurante asociado	36849.00	231
604	Cena en restaurante asociado	16199.00	796
605	Masaje en spa	29079.00	629
606	Masaje en spa	45852.00	618
607	Transporte al aeropuerto	14128.00	595
608	Cena en restaurante asociado	28910.00	324
609	Alquiler de coche	33014.00	55
610	Servicio de lavandería	20328.00	637
611	Cena en restaurante asociado	12039.00	892
612	Acceso al gimnasio	12825.00	304
613	Excursión local	16611.00	319
614	Servicio de lavandería	38660.00	623
615	Masaje en spa	28389.00	626
616	Transporte al aeropuerto	21837.00	253
617	Transporte al aeropuerto	37363.00	82
618	Limpieza de habitación	48885.00	770
619	Alquiler de coche	16805.00	60
620	Excursión local	45523.00	907
621	Transporte al aeropuerto	42039.00	2
622	Desayuno buffet	25214.00	299
623	Cena en restaurante asociado	38118.00	921
624	Clases de cocina	49111.00	280
625	Excursión local	26412.00	972
626	Clases de cocina	37652.00	951
627	Excursión local	43659.00	897
628	Cena en restaurante asociado	43136.00	415
629	Alquiler de coche	29336.00	610
630	Transporte al aeropuerto	42555.00	405
631	Limpieza de habitación	18003.00	354
632	Desayuno buffet	36594.00	513
633	Alquiler de coche	27930.00	4
634	Acceso al gimnasio	31312.00	425
635	Desayuno buffet	19208.00	104
636	Clases de cocina	16336.00	958
637	Desayuno buffet	22510.00	626
638	Masaje en spa	37438.00	283
639	Desayuno buffet	43621.00	931
640	Limpieza de habitación	27185.00	222
641	Excursión local	33261.00	633
642	Transporte al aeropuerto	22418.00	45
643	Desayuno buffet	45223.00	225
644	Acceso al gimnasio	20520.00	456
645	Clases de cocina	21694.00	115
646	Clases de cocina	15310.00	729
647	Servicio de lavandería	25914.00	183
648	Limpieza de habitación	34779.00	121
649	Excursión local	43036.00	371
650	Servicio de lavandería	15456.00	895
651	Servicio de lavandería	21078.00	19
652	Masaje en spa	28364.00	64
653	Clases de cocina	41667.00	34
654	Cena en restaurante asociado	12103.00	746
655	Masaje en spa	49789.00	424
656	Excursión local	35695.00	268
657	Desayuno buffet	41071.00	576
658	Transporte al aeropuerto	18083.00	87
659	Transporte al aeropuerto	11890.00	873
660	Masaje en spa	28217.00	838
661	Clases de cocina	44578.00	174
662	Transporte al aeropuerto	21658.00	361
663	Clases de cocina	42943.00	823
664	Cena en restaurante asociado	47726.00	831
665	Servicio de lavandería	31708.00	48
666	Acceso al gimnasio	38662.00	997
667	Acceso al gimnasio	23695.00	376
668	Cena en restaurante asociado	40805.00	629
669	Transporte al aeropuerto	16552.00	786
670	Limpieza de habitación	21109.00	365
671	Limpieza de habitación	19748.00	129
672	Excursión local	11239.00	278
673	Desayuno buffet	37351.00	786
674	Limpieza de habitación	37364.00	102
675	Transporte al aeropuerto	23988.00	954
676	Clases de cocina	32619.00	877
677	Excursión local	44486.00	287
678	Clases de cocina	42019.00	579
679	Cena en restaurante asociado	21151.00	619
680	Servicio de lavandería	10009.00	790
681	Clases de cocina	18116.00	363
682	Limpieza de habitación	43809.00	375
683	Cena en restaurante asociado	22321.00	398
684	Alquiler de coche	46641.00	170
685	Masaje en spa	14884.00	245
686	Transporte al aeropuerto	49934.00	288
687	Masaje en spa	41025.00	31
688	Acceso al gimnasio	32361.00	409
689	Desayuno buffet	17605.00	430
690	Limpieza de habitación	41830.00	597
691	Desayuno buffet	15897.00	853
692	Transporte al aeropuerto	45280.00	78
693	Alquiler de coche	46701.00	185
694	Excursión local	41550.00	700
695	Excursión local	25486.00	705
696	Cena en restaurante asociado	23388.00	469
697	Excursión local	22644.00	478
698	Alquiler de coche	34871.00	294
699	Desayuno buffet	15377.00	868
700	Clases de cocina	26600.00	357
701	Masaje en spa	22711.00	368
702	Transporte al aeropuerto	48565.00	273
703	Servicio de lavandería	45650.00	349
704	Cena en restaurante asociado	38391.00	261
705	Clases de cocina	17734.00	768
706	Alquiler de coche	42040.00	994
707	Masaje en spa	44806.00	975
708	Alquiler de coche	46186.00	252
709	Masaje en spa	41567.00	556
710	Clases de cocina	12403.00	342
711	Servicio de lavandería	30522.00	496
712	Acceso al gimnasio	28125.00	514
713	Cena en restaurante asociado	40184.00	167
714	Excursión local	37914.00	8
715	Limpieza de habitación	18297.00	38
716	Alquiler de coche	15021.00	927
717	Excursión local	11459.00	894
718	Clases de cocina	25783.00	841
719	Cena en restaurante asociado	29057.00	744
720	Cena en restaurante asociado	35369.00	579
721	Excursión local	37717.00	299
722	Desayuno buffet	49097.00	609
723	Clases de cocina	45908.00	891
724	Masaje en spa	20939.00	151
725	Alquiler de coche	44218.00	867
726	Servicio de lavandería	41539.00	124
727	Clases de cocina	29290.00	439
728	Excursión local	36216.00	876
729	Transporte al aeropuerto	25059.00	515
730	Transporte al aeropuerto	14036.00	107
731	Transporte al aeropuerto	32203.00	109
732	Limpieza de habitación	32984.00	947
733	Acceso al gimnasio	20043.00	797
734	Masaje en spa	25214.00	11
735	Masaje en spa	32691.00	988
736	Clases de cocina	16674.00	894
737	Cena en restaurante asociado	32991.00	641
738	Clases de cocina	10546.00	691
739	Masaje en spa	22434.00	878
740	Limpieza de habitación	15815.00	248
741	Acceso al gimnasio	40350.00	656
742	Alquiler de coche	13861.00	80
743	Limpieza de habitación	23488.00	96
744	Excursión local	34688.00	34
745	Servicio de lavandería	26288.00	529
746	Masaje en spa	28005.00	722
747	Transporte al aeropuerto	10371.00	607
748	Excursión local	32607.00	836
749	Alquiler de coche	24578.00	676
750	Acceso al gimnasio	19177.00	138
751	Transporte al aeropuerto	16431.00	859
752	Masaje en spa	18536.00	468
753	Limpieza de habitación	11761.00	169
754	Excursión local	26955.00	124
755	Clases de cocina	47062.00	424
756	Alquiler de coche	11690.00	642
757	Masaje en spa	13052.00	293
758	Desayuno buffet	24806.00	683
759	Excursión local	26905.00	236
760	Desayuno buffet	49263.00	407
761	Alquiler de coche	12180.00	193
762	Limpieza de habitación	20164.00	357
763	Servicio de lavandería	40437.00	168
764	Excursión local	32741.00	432
765	Excursión local	33374.00	360
766	Cena en restaurante asociado	20454.00	281
767	Transporte al aeropuerto	49516.00	364
768	Transporte al aeropuerto	44173.00	715
769	Limpieza de habitación	22731.00	256
770	Alquiler de coche	43622.00	67
771	Masaje en spa	22058.00	595
772	Masaje en spa	13533.00	547
773	Limpieza de habitación	30851.00	754
774	Cena en restaurante asociado	30079.00	52
775	Clases de cocina	47207.00	237
776	Limpieza de habitación	37544.00	647
777	Servicio de lavandería	11853.00	675
778	Desayuno buffet	45479.00	144
779	Desayuno buffet	40131.00	217
780	Servicio de lavandería	16570.00	919
781	Desayuno buffet	34038.00	429
782	Desayuno buffet	21854.00	372
783	Masaje en spa	34886.00	735
784	Servicio de lavandería	20585.00	236
785	Clases de cocina	42100.00	79
786	Cena en restaurante asociado	16585.00	256
787	Acceso al gimnasio	30728.00	946
788	Clases de cocina	23418.00	300
789	Transporte al aeropuerto	13492.00	333
790	Excursión local	41426.00	866
791	Clases de cocina	39780.00	603
792	Desayuno buffet	15111.00	358
793	Cena en restaurante asociado	31856.00	589
794	Clases de cocina	40362.00	271
795	Excursión local	30139.00	622
796	Cena en restaurante asociado	10144.00	683
797	Servicio de lavandería	28566.00	883
798	Cena en restaurante asociado	35277.00	984
799	Limpieza de habitación	20734.00	715
800	Masaje en spa	36148.00	813
801	Transporte al aeropuerto	15125.00	100
802	Alquiler de coche	29275.00	182
803	Masaje en spa	36767.00	156
804	Excursión local	25689.00	813
805	Clases de cocina	43172.00	258
806	Excursión local	33900.00	342
807	Excursión local	26708.00	962
808	Alquiler de coche	27680.00	692
809	Transporte al aeropuerto	40095.00	387
810	Clases de cocina	43966.00	784
811	Acceso al gimnasio	46099.00	112
812	Servicio de lavandería	36004.00	817
813	Servicio de lavandería	23538.00	320
814	Alquiler de coche	47773.00	441
815	Clases de cocina	13945.00	964
816	Cena en restaurante asociado	43977.00	29
817	Alquiler de coche	36381.00	150
818	Limpieza de habitación	44506.00	144
819	Alquiler de coche	19330.00	573
820	Servicio de lavandería	39653.00	608
821	Cena en restaurante asociado	38576.00	2
822	Acceso al gimnasio	47653.00	406
823	Masaje en spa	18530.00	37
824	Excursión local	37373.00	540
825	Clases de cocina	33806.00	298
826	Clases de cocina	35204.00	864
827	Transporte al aeropuerto	47048.00	7
828	Excursión local	13762.00	884
829	Clases de cocina	28988.00	278
830	Masaje en spa	30435.00	154
831	Servicio de lavandería	47578.00	425
832	Excursión local	20445.00	624
833	Cena en restaurante asociado	42477.00	888
834	Cena en restaurante asociado	18771.00	572
835	Masaje en spa	15241.00	431
836	Cena en restaurante asociado	43581.00	606
837	Servicio de lavandería	48550.00	66
838	Servicio de lavandería	33035.00	132
839	Desayuno buffet	46618.00	303
840	Servicio de lavandería	21922.00	532
841	Masaje en spa	35802.00	214
842	Desayuno buffet	32683.00	953
843	Limpieza de habitación	10111.00	352
844	Cena en restaurante asociado	47581.00	882
845	Desayuno buffet	28414.00	257
846	Limpieza de habitación	22975.00	467
847	Servicio de lavandería	25223.00	816
848	Cena en restaurante asociado	13727.00	292
849	Clases de cocina	46528.00	214
850	Transporte al aeropuerto	48930.00	181
851	Cena en restaurante asociado	36609.00	355
852	Cena en restaurante asociado	27208.00	767
853	Clases de cocina	17708.00	777
854	Cena en restaurante asociado	42369.00	982
855	Excursión local	25694.00	691
856	Servicio de lavandería	12614.00	250
857	Alquiler de coche	14037.00	749
858	Masaje en spa	45647.00	874
859	Transporte al aeropuerto	14591.00	725
860	Limpieza de habitación	24082.00	773
861	Clases de cocina	27302.00	30
862	Limpieza de habitación	49037.00	264
863	Acceso al gimnasio	49491.00	708
864	Clases de cocina	20705.00	855
865	Excursión local	42046.00	887
866	Transporte al aeropuerto	24082.00	871
867	Excursión local	15052.00	421
868	Excursión local	39200.00	735
869	Transporte al aeropuerto	18527.00	288
870	Masaje en spa	31537.00	861
871	Servicio de lavandería	35384.00	859
872	Clases de cocina	32410.00	4
873	Acceso al gimnasio	39942.00	535
874	Transporte al aeropuerto	46573.00	592
875	Servicio de lavandería	10206.00	652
876	Alquiler de coche	11117.00	842
877	Acceso al gimnasio	29442.00	807
878	Alquiler de coche	43533.00	421
879	Acceso al gimnasio	35128.00	396
880	Masaje en spa	13360.00	225
881	Masaje en spa	18872.00	609
882	Excursión local	17831.00	763
883	Alquiler de coche	10422.00	701
884	Transporte al aeropuerto	41017.00	924
885	Clases de cocina	30535.00	193
886	Excursión local	11381.00	537
887	Cena en restaurante asociado	46539.00	388
888	Excursión local	13782.00	888
889	Cena en restaurante asociado	13464.00	563
890	Clases de cocina	23654.00	711
891	Desayuno buffet	49848.00	921
892	Acceso al gimnasio	22780.00	625
893	Alquiler de coche	28293.00	316
894	Excursión local	32988.00	832
895	Masaje en spa	45572.00	226
896	Cena en restaurante asociado	32042.00	909
897	Desayuno buffet	47524.00	872
898	Servicio de lavandería	33092.00	763
899	Transporte al aeropuerto	47044.00	265
900	Limpieza de habitación	35683.00	74
901	Masaje en spa	40701.00	66
902	Limpieza de habitación	45411.00	302
903	Acceso al gimnasio	12345.00	932
904	Cena en restaurante asociado	42082.00	967
905	Alquiler de coche	27988.00	465
906	Clases de cocina	37203.00	360
907	Clases de cocina	16204.00	512
908	Acceso al gimnasio	46252.00	544
909	Alquiler de coche	24779.00	632
910	Acceso al gimnasio	46581.00	546
911	Servicio de lavandería	41561.00	943
912	Acceso al gimnasio	42070.00	603
913	Clases de cocina	35291.00	332
914	Servicio de lavandería	21049.00	532
915	Clases de cocina	20009.00	284
916	Alquiler de coche	33919.00	68
917	Clases de cocina	33576.00	55
918	Masaje en spa	40554.00	744
919	Acceso al gimnasio	19559.00	288
920	Transporte al aeropuerto	47371.00	525
921	Masaje en spa	23848.00	773
922	Clases de cocina	46779.00	368
923	Transporte al aeropuerto	20095.00	475
924	Acceso al gimnasio	19813.00	894
925	Cena en restaurante asociado	46252.00	797
926	Cena en restaurante asociado	29038.00	740
927	Alquiler de coche	19013.00	169
928	Masaje en spa	49539.00	201
929	Desayuno buffet	38953.00	823
930	Clases de cocina	28603.00	776
931	Alquiler de coche	41261.00	529
932	Excursión local	14050.00	529
933	Masaje en spa	15258.00	733
934	Desayuno buffet	42866.00	797
935	Limpieza de habitación	30790.00	650
936	Excursión local	26966.00	521
937	Masaje en spa	24283.00	725
938	Excursión local	44024.00	895
939	Masaje en spa	30530.00	135
940	Clases de cocina	20261.00	118
941	Servicio de lavandería	31698.00	195
942	Masaje en spa	49996.00	139
943	Limpieza de habitación	36820.00	361
944	Masaje en spa	42822.00	534
945	Acceso al gimnasio	35772.00	632
946	Clases de cocina	21989.00	82
947	Transporte al aeropuerto	36833.00	51
948	Masaje en spa	24971.00	597
949	Excursión local	31852.00	622
950	Clases de cocina	17402.00	499
951	Clases de cocina	34986.00	961
952	Cena en restaurante asociado	13771.00	238
953	Masaje en spa	34811.00	897
954	Masaje en spa	35772.00	829
955	Excursión local	37603.00	234
956	Masaje en spa	43432.00	336
957	Servicio de lavandería	21457.00	411
958	Servicio de lavandería	45797.00	888
959	Acceso al gimnasio	40252.00	627
960	Acceso al gimnasio	23177.00	774
961	Cena en restaurante asociado	41331.00	303
962	Clases de cocina	47684.00	158
963	Transporte al aeropuerto	49388.00	987
964	Cena en restaurante asociado	42351.00	357
965	Cena en restaurante asociado	19019.00	866
966	Clases de cocina	41180.00	206
967	Servicio de lavandería	45507.00	249
968	Masaje en spa	17805.00	639
969	Servicio de lavandería	34669.00	211
970	Cena en restaurante asociado	13414.00	460
971	Transporte al aeropuerto	48719.00	554
972	Alquiler de coche	45406.00	251
973	Desayuno buffet	16052.00	430
974	Limpieza de habitación	42877.00	401
975	Transporte al aeropuerto	45467.00	84
976	Transporte al aeropuerto	31956.00	532
977	Masaje en spa	29601.00	680
978	Clases de cocina	36850.00	92
979	Masaje en spa	22735.00	677
980	Acceso al gimnasio	24807.00	749
981	Masaje en spa	38700.00	410
982	Masaje en spa	18988.00	252
983	Servicio de lavandería	39902.00	759
984	Masaje en spa	26062.00	49
985	Clases de cocina	11432.00	800
986	Cena en restaurante asociado	17671.00	182
987	Clases de cocina	18315.00	683
988	Cena en restaurante asociado	37769.00	707
989	Alquiler de coche	26420.00	148
990	Desayuno buffet	38692.00	852
991	Servicio de lavandería	11781.00	333
992	Desayuno buffet	40644.00	217
993	Desayuno buffet	17002.00	757
994	Transporte al aeropuerto	40497.00	761
995	Limpieza de habitación	48323.00	194
996	Servicio de lavandería	42572.00	37
997	Limpieza de habitación	17732.00	546
998	Clases de cocina	46393.00	373
999	Clases de cocina	29953.00	485
1000	Alquiler de coche	25968.00	23
\.


                                                                                                                                                                                                                                                                                                                                                                                                                           4956.dat                                                                                            0000600 0004000 0002000 00000001203 15015342721 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        STF01	Andres	Camilo	Perez	Jimenez	3101234567	Santa Clara	2021-05-10	2500000.00	CC	103456789	Recepcionista	\N	\N	DIURNA	H001	STF02
STF02	Laura	\N	Gomez	Alvarez	3199876543	el Carmen	2020-08-12	3200000.00	CC	189765432	Gerente	2	STF01,STF03,STF04	DIURNA	H001	STF05
STF03	Maria	Camila	Cardenas	Torres	3115566789	la luz polar	2022-02-10	2300000.00	CC	100233445	Recepcionista	\N	\N	NOCTURNA	H001	STF02
STF04	Juliana	\N	Carrascal	Suarez	3123344556	Tejarito	2021-03-14	1000000.00	CC	37330081	Aux. Limpieza	\N	STF02	DIURNA	H001	STF02
STF05	Leidy	Johana	Mora	Perez	3154192262	El mercado	2019-11-05	4000000.00	CC	88765431	Jefe	2	STF02	DIURNA	H001	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                             restore.sql                                                                                         0000600 0004000 0002000 00000115772 15015342721 0015401 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE "Hotel";
--
-- Name: Hotel; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "Hotel" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'es-MX';


ALTER DATABASE "Hotel" OWNER TO postgres;

\connect "Hotel"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hotel; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA hotel;


ALTER SCHEMA hotel OWNER TO postgres;

--
-- Name: audi_detail_reservation_func(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.audi_detail_reservation_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.audi_detail_reservation_func() OWNER TO postgres;

--
-- Name: audi_detail_service_func(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.audi_detail_service_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

$$;


ALTER FUNCTION hotel.audi_detail_service_func() OWNER TO postgres;

--
-- Name: calc_detail_reservation(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.calc_detail_reservation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.calc_detail_reservation() OWNER TO postgres;

--
-- Name: calc_detail_service(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.calc_detail_service() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.quantity IS NULL THEN
        RAISE EXCEPTION 'Cantidad no puede ser nula';
    END IF;

    NEW.sub_total := NEW.price * NEW.quantity;
    RETURN NEW;
END;
$$;


ALTER FUNCTION hotel.calc_detail_service() OWNER TO postgres;

--
-- Name: set_price_and_calc_subtotal(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.set_price_and_calc_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.set_price_and_calc_subtotal() OWNER TO postgres;

--
-- Name: set_room_price(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.set_room_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.set_room_price() OWNER TO postgres;

--
-- Name: set_service_price(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.set_service_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.set_service_price() OWNER TO postgres;

--
-- Name: set_service_price_and_subtotal(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.set_service_price_and_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.set_service_price_and_subtotal() OWNER TO postgres;

--
-- Name: update_reservation_total(); Type: FUNCTION; Schema: hotel; Owner: postgres
--

CREATE FUNCTION hotel.update_reservation_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION hotel.update_reservation_total() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agreement; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.agreement (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200),
    start_date date NOT NULL,
    end_date date NOT NULL
);


ALTER TABLE hotel.agreement OWNER TO postgres;

--
-- Name: agreement_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.agreement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.agreement_id_seq OWNER TO postgres;

--
-- Name: agreement_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.agreement_id_seq OWNED BY hotel.agreement.id;


--
-- Name: audi_detail_reservation; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.audi_detail_reservation (
    consecutivo integer NOT NULL,
    rsv_id integer,
    line_item_id integer,
    room_id integer,
    price numeric(10,2),
    quantity integer,
    check_in date,
    check_out date,
    discount numeric(10,2),
    discount_value numeric(10,2),
    subtotal numeric(10,2),
    fecha_registro timestamp without time zone,
    usuario character varying(50),
    accion character(1)
);


ALTER TABLE hotel.audi_detail_reservation OWNER TO postgres;

--
-- Name: audi_detail_reservation_consecutivo_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.audi_detail_reservation_consecutivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.audi_detail_reservation_consecutivo_seq OWNER TO postgres;

--
-- Name: audi_detail_reservation_consecutivo_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.audi_detail_reservation_consecutivo_seq OWNED BY hotel.audi_detail_reservation.consecutivo;


--
-- Name: audi_detail_service; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.audi_detail_service (
    consecutivo integer NOT NULL,
    srv_id integer,
    line_item_id integer,
    rsv_id integer,
    price numeric(10,2),
    quantity integer,
    sub_total numeric(10,2),
    fecha_registro timestamp without time zone,
    usuario character varying(50),
    accion character(1)
);


ALTER TABLE hotel.audi_detail_service OWNER TO postgres;

--
-- Name: audi_detail_service_consecutivo_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.audi_detail_service_consecutivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.audi_detail_service_consecutivo_seq OWNER TO postgres;

--
-- Name: audi_detail_service_consecutivo_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.audi_detail_service_consecutivo_seq OWNED BY hotel.audi_detail_service.consecutivo;


--
-- Name: city; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.city (
    id character varying(3) NOT NULL,
    dpt_id character varying(3) NOT NULL,
    cty_id character varying(3) NOT NULL,
    name character varying(60) NOT NULL
);


ALTER TABLE hotel.city OWNER TO postgres;

--
-- Name: country; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.country (
    id character varying(3) NOT NULL,
    name character varying(60)
);


ALTER TABLE hotel.country OWNER TO postgres;

--
-- Name: customer; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.customer (
    id character varying(15) NOT NULL,
    dct_typ_id character varying(2),
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    second_last_name character varying(50),
    birth_date date NOT NULL,
    gender character(1) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    prf_id character varying(4) NOT NULL,
    city_id character varying(3) NOT NULL,
    departament_id character varying(3) NOT NULL,
    country_id character varying(3) NOT NULL,
    destination_city_id character varying(3) NOT NULL,
    destination_departament_id character varying(3) NOT NULL,
    destination_country_id character varying(3) NOT NULL,
    CONSTRAINT chk_cst_gender CHECK ((gender = ANY (ARRAY['M'::bpchar, 'F'::bpchar, 'O'::bpchar])))
);


ALTER TABLE hotel.customer OWNER TO postgres;

--
-- Name: department; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.department (
    id character varying(3) NOT NULL,
    cty_id character varying(3) NOT NULL,
    name character varying(60) NOT NULL
);


ALTER TABLE hotel.department OWNER TO postgres;

--
-- Name: detail_reservation; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.detail_reservation (
    rsv_id integer NOT NULL,
    line_item_id integer NOT NULL,
    room_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    check_in date NOT NULL,
    check_out date NOT NULL,
    discount numeric(10,2) DEFAULT 0,
    discount_value numeric(10,2) DEFAULT 0,
    subtotal numeric(10,2) NOT NULL,
    CONSTRAINT chk_dtl_rsv_quantity CHECK ((quantity > 0))
);


ALTER TABLE hotel.detail_reservation OWNER TO postgres;

--
-- Name: detail_reservation_line_item_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.detail_reservation_line_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.detail_reservation_line_item_id_seq OWNER TO postgres;

--
-- Name: detail_reservation_line_item_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.detail_reservation_line_item_id_seq OWNED BY hotel.detail_reservation.line_item_id;


--
-- Name: detail_service; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.detail_service (
    srv_id integer NOT NULL,
    line_item_id integer NOT NULL,
    rsv_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    sub_total numeric(10,2) NOT NULL,
    CONSTRAINT chk_dtl_srv_quantity CHECK ((quantity > 0))
);


ALTER TABLE hotel.detail_service OWNER TO postgres;

--
-- Name: detail_service_line_item_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.detail_service_line_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.detail_service_line_item_id_seq OWNER TO postgres;

--
-- Name: detail_service_line_item_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.detail_service_line_item_id_seq OWNED BY hotel.detail_service.line_item_id;


--
-- Name: document_type; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.document_type (
    id character varying(3) NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE hotel.document_type OWNER TO postgres;

--
-- Name: hotel; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.hotel (
    id character varying(4) NOT NULL,
    name character varying(50) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    total_rooms integer NOT NULL
);


ALTER TABLE hotel.hotel OWNER TO postgres;

--
-- Name: profession; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.profession (
    id character varying(4) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200)
);


ALTER TABLE hotel.profession OWNER TO postgres;

--
-- Name: reservation; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.reservation (
    id integer NOT NULL,
    status character varying(50) NOT NULL,
    reservation_source character varying(50) NOT NULL,
    date date NOT NULL,
    total numeric(10,2) NOT NULL,
    cst_id character varying(15) NOT NULL,
    stf_id character varying(5)
);


ALTER TABLE hotel.reservation OWNER TO postgres;

--
-- Name: reservation_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.reservation_id_seq OWNER TO postgres;

--
-- Name: reservation_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.reservation_id_seq OWNED BY hotel.reservation.id;


--
-- Name: room; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.room (
    id integer NOT NULL,
    rom_typ_id character varying(3) NOT NULL,
    htl_id character varying(4) NOT NULL
);


ALTER TABLE hotel.room OWNER TO postgres;

--
-- Name: room_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.room_id_seq OWNER TO postgres;

--
-- Name: room_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.room_id_seq OWNED BY hotel.room.id;


--
-- Name: room_type; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.room_type (
    id character varying(3) NOT NULL,
    name character varying(50) NOT NULL,
    price_per_night numeric(10,2) NOT NULL,
    description character varying(200)
);


ALTER TABLE hotel.room_type OWNER TO postgres;

--
-- Name: service; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.service (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    price numeric(10,2) NOT NULL,
    agr_id integer NOT NULL
);


ALTER TABLE hotel.service OWNER TO postgres;

--
-- Name: service_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.service_id_seq OWNER TO postgres;

--
-- Name: service_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.service_id_seq OWNED BY hotel.service.id;


--
-- Name: staff; Type: TABLE; Schema: hotel; Owner: postgres
--

CREATE TABLE hotel.staff (
    id character varying(5) NOT NULL,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    last_name character varying(50) NOT NULL,
    second_last_name character varying(50),
    phone_number character varying(15),
    address character varying(100) NOT NULL,
    hire_date date NOT NULL,
    salary numeric(10,2) NOT NULL,
    dct_typ_id character varying(2) NOT NULL,
    identity_document character varying(15) NOT NULL,
    worker_type character varying(50) NOT NULL,
    employee_number integer,
    direct_reports character varying(200),
    work_shift character varying(50),
    htl_id character varying(4) NOT NULL,
    boss_id character varying(5)
);


ALTER TABLE hotel.staff OWNER TO postgres;

--
-- Name: staff_id_seq; Type: SEQUENCE; Schema: hotel; Owner: postgres
--

CREATE SEQUENCE hotel.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE hotel.staff_id_seq OWNER TO postgres;

--
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: hotel; Owner: postgres
--

ALTER SEQUENCE hotel.staff_id_seq OWNED BY hotel.staff.id;


--
-- Name: agreement id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.agreement ALTER COLUMN id SET DEFAULT nextval('hotel.agreement_id_seq'::regclass);


--
-- Name: audi_detail_reservation consecutivo; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.audi_detail_reservation ALTER COLUMN consecutivo SET DEFAULT nextval('hotel.audi_detail_reservation_consecutivo_seq'::regclass);


--
-- Name: audi_detail_service consecutivo; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.audi_detail_service ALTER COLUMN consecutivo SET DEFAULT nextval('hotel.audi_detail_service_consecutivo_seq'::regclass);


--
-- Name: detail_reservation line_item_id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_reservation ALTER COLUMN line_item_id SET DEFAULT nextval('hotel.detail_reservation_line_item_id_seq'::regclass);


--
-- Name: detail_service line_item_id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_service ALTER COLUMN line_item_id SET DEFAULT nextval('hotel.detail_service_line_item_id_seq'::regclass);


--
-- Name: reservation id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.reservation ALTER COLUMN id SET DEFAULT nextval('hotel.reservation_id_seq'::regclass);


--
-- Name: room id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.room ALTER COLUMN id SET DEFAULT nextval('hotel.room_id_seq'::regclass);


--
-- Name: service id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.service ALTER COLUMN id SET DEFAULT nextval('hotel.service_id_seq'::regclass);


--
-- Name: staff id; Type: DEFAULT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.staff ALTER COLUMN id SET DEFAULT nextval('hotel.staff_id_seq'::regclass);


--
-- Data for Name: agreement; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.agreement (id, name, description, start_date, end_date) FROM stdin;
\.
COPY hotel.agreement (id, name, description, start_date, end_date) FROM '$$PATH$$/4963.dat';

--
-- Data for Name: audi_detail_reservation; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.audi_detail_reservation (consecutivo, rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal, fecha_registro, usuario, accion) FROM stdin;
\.
COPY hotel.audi_detail_reservation (consecutivo, rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal, fecha_registro, usuario, accion) FROM '$$PATH$$/4971.dat';

--
-- Data for Name: audi_detail_service; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.audi_detail_service (consecutivo, srv_id, line_item_id, rsv_id, price, quantity, sub_total, fecha_registro, usuario, accion) FROM stdin;
\.
COPY hotel.audi_detail_service (consecutivo, srv_id, line_item_id, rsv_id, price, quantity, sub_total, fecha_registro, usuario, accion) FROM '$$PATH$$/4969.dat';

--
-- Data for Name: city; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.city (id, dpt_id, cty_id, name) FROM stdin;
\.
COPY hotel.city (id, dpt_id, cty_id, name) FROM '$$PATH$$/4950.dat';

--
-- Data for Name: country; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.country (id, name) FROM stdin;
\.
COPY hotel.country (id, name) FROM '$$PATH$$/4948.dat';

--
-- Data for Name: customer; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.customer (id, dct_typ_id, first_name, middle_name, last_name, second_last_name, birth_date, gender, phone_number, email, prf_id, city_id, departament_id, country_id, destination_city_id, destination_departament_id, destination_country_id) FROM stdin;
\.
COPY hotel.customer (id, dct_typ_id, first_name, middle_name, last_name, second_last_name, birth_date, gender, phone_number, email, prf_id, city_id, departament_id, country_id, destination_city_id, destination_departament_id, destination_country_id) FROM '$$PATH$$/4957.dat';

--
-- Data for Name: department; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.department (id, cty_id, name) FROM stdin;
\.
COPY hotel.department (id, cty_id, name) FROM '$$PATH$$/4949.dat';

--
-- Data for Name: detail_reservation; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal) FROM stdin;
\.
COPY hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal) FROM '$$PATH$$/4961.dat';

--
-- Data for Name: detail_service; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.detail_service (srv_id, line_item_id, rsv_id, price, quantity, sub_total) FROM stdin;
\.
COPY hotel.detail_service (srv_id, line_item_id, rsv_id, price, quantity, sub_total) FROM '$$PATH$$/4967.dat';

--
-- Data for Name: document_type; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.document_type (id, name) FROM stdin;
\.
COPY hotel.document_type (id, name) FROM '$$PATH$$/4947.dat';

--
-- Data for Name: hotel; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.hotel (id, name, phone_number, email, total_rooms) FROM stdin;
\.
COPY hotel.hotel (id, name, phone_number, email, total_rooms) FROM '$$PATH$$/4952.dat';

--
-- Data for Name: profession; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.profession (id, name, description) FROM stdin;
\.
COPY hotel.profession (id, name, description) FROM '$$PATH$$/4946.dat';

--
-- Data for Name: reservation; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.reservation (id, status, reservation_source, date, total, cst_id, stf_id) FROM stdin;
\.
COPY hotel.reservation (id, status, reservation_source, date, total, cst_id, stf_id) FROM '$$PATH$$/4959.dat';

--
-- Data for Name: room; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.room (id, rom_typ_id, htl_id) FROM stdin;
\.
COPY hotel.room (id, rom_typ_id, htl_id) FROM '$$PATH$$/4954.dat';

--
-- Data for Name: room_type; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.room_type (id, name, price_per_night, description) FROM stdin;
\.
COPY hotel.room_type (id, name, price_per_night, description) FROM '$$PATH$$/4951.dat';

--
-- Data for Name: service; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.service (id, name, price, agr_id) FROM stdin;
\.
COPY hotel.service (id, name, price, agr_id) FROM '$$PATH$$/4965.dat';

--
-- Data for Name: staff; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.staff (id, first_name, middle_name, last_name, second_last_name, phone_number, address, hire_date, salary, dct_typ_id, identity_document, worker_type, employee_number, direct_reports, work_shift, htl_id, boss_id) FROM stdin;
\.
COPY hotel.staff (id, first_name, middle_name, last_name, second_last_name, phone_number, address, hire_date, salary, dct_typ_id, identity_document, worker_type, employee_number, direct_reports, work_shift, htl_id, boss_id) FROM '$$PATH$$/4956.dat';

--
-- Name: agreement_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.agreement_id_seq', 1, false);


--
-- Name: audi_detail_reservation_consecutivo_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.audi_detail_reservation_consecutivo_seq', 1, true);


--
-- Name: audi_detail_service_consecutivo_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.audi_detail_service_consecutivo_seq', 1, true);


--
-- Name: detail_reservation_line_item_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.detail_reservation_line_item_id_seq', 1, false);


--
-- Name: detail_service_line_item_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.detail_service_line_item_id_seq', 1, false);


--
-- Name: reservation_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.reservation_id_seq', 1, false);


--
-- Name: room_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.room_id_seq', 1, false);


--
-- Name: service_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.service_id_seq', 1, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.staff_id_seq', 1, false);


--
-- Name: agreement agreement_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.agreement
    ADD CONSTRAINT agreement_pkey PRIMARY KEY (id);


--
-- Name: audi_detail_reservation audi_detail_reservation_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.audi_detail_reservation
    ADD CONSTRAINT audi_detail_reservation_pkey PRIMARY KEY (consecutivo);


--
-- Name: audi_detail_service audi_detail_service_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.audi_detail_service
    ADD CONSTRAINT audi_detail_service_pkey PRIMARY KEY (consecutivo);


--
-- Name: country country_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: document_type document_type_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.document_type
    ADD CONSTRAINT document_type_pkey PRIMARY KEY (id);


--
-- Name: hotel hotel_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.hotel
    ADD CONSTRAINT hotel_pkey PRIMARY KEY (id);


--
-- Name: city pk_cyy; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.city
    ADD CONSTRAINT pk_cyy PRIMARY KEY (id, dpt_id, cty_id);


--
-- Name: department pk_dpt; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.department
    ADD CONSTRAINT pk_dpt PRIMARY KEY (id, cty_id);


--
-- Name: detail_reservation pk_dtl_rsv; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT pk_dtl_rsv PRIMARY KEY (rsv_id, line_item_id);


--
-- Name: detail_service pk_dtl_srv; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT pk_dtl_srv PRIMARY KEY (srv_id, line_item_id);


--
-- Name: profession profession_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.profession
    ADD CONSTRAINT profession_pkey PRIMARY KEY (id);


--
-- Name: reservation reservation_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id);


--
-- Name: room room_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (id);


--
-- Name: room_type room_type_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.room_type
    ADD CONSTRAINT room_type_pkey PRIMARY KEY (id);


--
-- Name: service service_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: profession uk_prf_name; Type: CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.profession
    ADD CONSTRAINT uk_prf_name UNIQUE (name);


--
-- Name: detail_reservation trg_audi_detail_reservation; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_audi_detail_reservation BEFORE DELETE OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.audi_detail_reservation_func();


--
-- Name: detail_service trg_audi_detail_service; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_audi_detail_service BEFORE DELETE OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.audi_detail_service_func();


--
-- Name: detail_reservation trg_calc_detail_reservation; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_calc_detail_reservation BEFORE INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.calc_detail_reservation();


--
-- Name: detail_service trg_calc_detail_service; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_calc_detail_service BEFORE INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.calc_detail_service();


--
-- Name: detail_reservation trg_set_price_and_calc_subtotal; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_set_price_and_calc_subtotal BEFORE INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.set_price_and_calc_subtotal();


--
-- Name: detail_reservation trg_set_room_price; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_set_room_price BEFORE INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.set_room_price();


--
-- Name: detail_service trg_set_service_price; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_set_service_price BEFORE INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.set_service_price();


--
-- Name: detail_service trg_set_service_price_and_subtotal; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_set_service_price_and_subtotal BEFORE INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.set_service_price_and_subtotal();


--
-- Name: detail_reservation trg_update_total_from_detail_reservation; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_update_total_from_detail_reservation AFTER INSERT OR UPDATE ON hotel.detail_reservation FOR EACH ROW EXECUTE FUNCTION hotel.update_reservation_total();


--
-- Name: detail_service trg_update_total_from_detail_service; Type: TRIGGER; Schema: hotel; Owner: postgres
--

CREATE TRIGGER trg_update_total_from_detail_service AFTER INSERT OR UPDATE ON hotel.detail_service FOR EACH ROW EXECUTE FUNCTION hotel.update_reservation_total();


--
-- Name: customer fk_cst_city; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_city FOREIGN KEY (city_id, departament_id, country_id) REFERENCES hotel.city(id, dpt_id, cty_id);


--
-- Name: customer fk_cst_dct_typ; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id);


--
-- Name: customer fk_cst_dest_city; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_dest_city FOREIGN KEY (destination_city_id, destination_departament_id, destination_country_id) REFERENCES hotel.city(id, dpt_id, cty_id);


--
-- Name: customer fk_cst_prf; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_prf FOREIGN KEY (prf_id) REFERENCES hotel.profession(id);


--
-- Name: city fk_cyy_dpt; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.city
    ADD CONSTRAINT fk_cyy_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES hotel.department(id, cty_id);


--
-- Name: department fk_dpt_cty; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.department
    ADD CONSTRAINT fk_dpt_cty FOREIGN KEY (cty_id) REFERENCES hotel.country(id);


--
-- Name: detail_reservation fk_dtl_rsv_rom; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT fk_dtl_rsv_rom FOREIGN KEY (room_id) REFERENCES hotel.room(id);


--
-- Name: detail_reservation fk_dtl_rsv_rsv; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT fk_dtl_rsv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id);


--
-- Name: detail_service fk_dtl_srv_rsv; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT fk_dtl_srv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id);


--
-- Name: detail_service fk_dtl_srv_srv; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT fk_dtl_srv_srv FOREIGN KEY (srv_id) REFERENCES hotel.service(id);


--
-- Name: room fk_rom_htl; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT fk_rom_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id);


--
-- Name: room fk_rom_typ; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT fk_rom_typ FOREIGN KEY (rom_typ_id) REFERENCES hotel.room_type(id);


--
-- Name: reservation fk_rsv_cst; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT fk_rsv_cst FOREIGN KEY (cst_id) REFERENCES hotel.customer(id);


--
-- Name: reservation fk_rsv_stf; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT fk_rsv_stf FOREIGN KEY (stf_id) REFERENCES hotel.staff(id);


--
-- Name: service fk_srv_agr; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.service
    ADD CONSTRAINT fk_srv_agr FOREIGN KEY (agr_id) REFERENCES hotel.agreement(id);


--
-- Name: staff fk_stf_boss; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_boss FOREIGN KEY (boss_id) REFERENCES hotel.staff(id);


--
-- Name: staff fk_stf_dct_typ; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id);


--
-- Name: staff fk_stf_htl; Type: FK CONSTRAINT; Schema: hotel; Owner: postgres
--

ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id);


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      