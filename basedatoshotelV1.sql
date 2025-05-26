-- Tabla PROFESSION
CREATE TABLE hotel.profession (
    id VARCHAR(4) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    CONSTRAINT uk_prf_name UNIQUE(name)
);

-- Tabla DOCUMENT_TYPE
CREATE TABLE hotel.document_type (
    id VARCHAR(2) PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

--Tabla COUNTRY
CREATE TABLE hotel.country (
    id VARCHAR(3) PRIMARY KEY,
    name VARCHAR(60)
);

--Tabla DEPARTMENT
CREATE TABLE hotel.department (
    id VARCHAR(3),
    cty_id VARCHAR(3) NOT NULL,
    name VARCHAR(60) NOT NULL,
    CONSTRAINT pk_dpt PRIMARY KEY (id, cty_id),
    CONSTRAINT fk_dpt_cty FOREIGN KEY (cty_id) REFERENCES hotel.country(id)
);

--Tabla CITY
CREATE TABLE hotel.city (
    id VARCHAR(3),
    dpt_id VARCHAR(3) NOT NULL,
    cty_id VARCHAR(3) NOT NULL,
    name VARCHAR(60) NOT NULL,
    CONSTRAINT pk_cyy PRIMARY KEY (id, dpt_id, cty_id),
    CONSTRAINT fk_cyy_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES hotel.department(id, cty_id)
);

--Tabla CUSTOMER
CREATE TABLE hotel.customer (
    id VARCHAR(15) PRIMARY KEY,
    dct_typ_id VARCHAR(2),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    gender CHAR(1) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    email VARCHAR(100),
    prf_id VARCHAR(4) NOT NULL,
    city_id VARCHAR(3) NOT NULL,
    departament_id VARCHAR(3) NOT NULL,
    country_id VARCHAR(3) NOT NULL,
    destination_city_id VARCHAR(3) NOT NULL,
    destination_departament_id VARCHAR(3) NOT NULL,
    destination_country_id VARCHAR(3) NOT NULL,
    CONSTRAINT fk_cst_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id),
    CONSTRAINT fk_cst_prf FOREIGN KEY (prf_id) REFERENCES hotel.profession(id),
    CONSTRAINT fk_cst_city FOREIGN KEY (city_id, departament_id, country_id) REFERENCES hotel.city(id, dpt_id, cty_id),
    CONSTRAINT fk_cst_dest_city FOREIGN KEY (destination_city_id, destination_departament_id, destination_country_id) 
        REFERENCES hotel.city(id, dpt_id, cty_id),
    CONSTRAINT chk_cst_gender CHECK (gender IN ('M', 'F', 'O'))
);

-- Tabla ROOM_TYPE 
CREATE TABLE hotel.room_type (
    id VARCHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,
    description VARCHAR(200)
);

--Tabla HOTEL 
CREATE TABLE hotel.hotel (
    id VARCHAR(4) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    email VARCHAR(100),
    total_rooms INTEGER NOT NULL
);

--Tabla ROOM
CREATE TABLE hotel.room (
    id SERIAL PRIMARY KEY,
    rom_typ_id VARCHAR(3) NOT NULL,
    status VARCHAR(15) NOT NULL,
    htl_id VARCHAR(4) NOT NULL,
    CONSTRAINT fk_rom_typ FOREIGN KEY (rom_typ_id) REFERENCES hotel.room_type(id),
    CONSTRAINT fk_rom_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id)
);


--Tabla STAFF
CREATE TABLE hotel.staff (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15),
    address VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    salary NUMERIC(10,2) NOT NULL,
    dct_typ_id VARCHAR(2) NOT NULL,
    identity_document VARCHAR(15) NOT NULL,
    worker_type VARCHAR(50) NOT NULL,
    employee_number INTEGER,
    direct_reports VARCHAR(200),
    work_shift VARCHAR(50),
    htl_id VARCHAR(4) NOT NULL,
    boss_id INTEGER,
    CONSTRAINT fk_stf_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id),
    CONSTRAINT fk_stf_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id),
    CONSTRAINT fk_stf_boss FOREIGN KEY (boss_id) REFERENCES hotel.staff(id)
);

-- tabla RESERVATION
CREATE TABLE hotel.reservation (
    id SERIAL PRIMARY KEY,
    status VARCHAR(50) NOT NULL,
    reservation_source VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    total NUMERIC(10,2) NOT NULL,
    cst_id VARCHAR(15) NOT NULL,
    stf_id INTEGER NOT NULL,
    CONSTRAINT fk_rsv_cst FOREIGN KEY (cst_id) REFERENCES hotel.customer(id),
    CONSTRAINT fk_rsv_stf FOREIGN KEY (stf_id) REFERENCES hotel.staff(id)
);

--Tabla DETAIL_RESERVATION
CREATE TABLE hotel.detail_reservation (
    rsv_id INTEGER,
    line_item_id SERIAL,
    room_id INTEGER NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    quantity INTEGER NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    discount NUMERIC(10,2) DEFAULT 0,
    discount_value NUMERIC(10,2) DEFAULT 0,
    subtotal NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_dtl_rsv PRIMARY KEY (rsv_id, line_item_id),
    CONSTRAINT fk_dtl_rsv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id),
    CONSTRAINT fk_dtl_rsv_rom FOREIGN KEY (room_id) REFERENCES hotel.room(id),
    CONSTRAINT chk_dtl_rsv_quantity CHECK (quantity > 0)
);

--  Tabla AGREEMENT
CREATE TABLE hotel.agreement (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

--  Tabla AService
CREATE TABLE hotel.service (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    total DATE NOT NULL,
    agr_id INTEGER NOT NULL,
    CONSTRAINT fk_srv_agr FOREIGN KEY (agr_id) REFERENCES hotel.agreement(id)
);

-- Tabla DETAIL_SERVICE 
CREATE TABLE hotel.detail_service (
    srv_id INTEGER,
    line_item_id SERIAL,
    rsv_id INTEGER NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    quantity INTEGER NOT NULL,
    sub_total DATE NOT NULL,
    CONSTRAINT pk_dtl_srv PRIMARY KEY (srv_id, line_item_id),
    CONSTRAINT fk_dtl_srv_srv FOREIGN KEY (srv_id) REFERENCES hotel.service(id),
    CONSTRAINT fk_dtl_srv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id),
    CONSTRAINT chk_dtl_srv_quantity CHECK (quantity > 0)
);

SELECT * FROM hotel.detail_service;








