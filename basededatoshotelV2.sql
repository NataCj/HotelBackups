toc.dat                                                                                             0000600 0004000 0002000 00000073730 15014150412 0014442 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP       0                }            Hotel    17.4    17.4 a    G           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false         H           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false         I           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false         J           1262    33272    Hotel    DATABASE     m   CREATE DATABASE "Hotel" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'es-MX';
    DROP DATABASE "Hotel";
                     postgres    false                     2615    33273    hotel    SCHEMA        CREATE SCHEMA hotel;
    DROP SCHEMA hotel;
                     postgres    false         �            1259    33426 	   agreement    TABLE     �   CREATE TABLE hotel.agreement (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200),
    start_date date NOT NULL,
    end_date date NOT NULL
);
    DROP TABLE hotel.agreement;
       hotel         heap r       postgres    false    6         �            1259    33425    agreement_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.agreement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE hotel.agreement_id_seq;
       hotel               postgres    false    235    6         K           0    0    agreement_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE hotel.agreement_id_seq OWNED BY hotel.agreement.id;
          hotel               postgres    false    234         �            1259    33301    city    TABLE     �   CREATE TABLE hotel.city (
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
       hotel         heap r       postgres    false    6         �            1259    33311    customer    TABLE     %  CREATE TABLE hotel.customer (
    id character varying(15) NOT NULL,
    dct_typ_id character varying(2),
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
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
       hotel         heap r       postgres    false    6         �            1259    33406    detail_reservation    TABLE     �  CREATE TABLE hotel.detail_reservation (
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
       hotel         heap r       postgres    false    6         �            1259    33405 #   detail_reservation_line_item_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.detail_reservation_line_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE hotel.detail_reservation_line_item_id_seq;
       hotel               postgres    false    233    6         L           0    0 #   detail_reservation_line_item_id_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE hotel.detail_reservation_line_item_id_seq OWNED BY hotel.detail_reservation.line_item_id;
          hotel               postgres    false    232         �            1259    33445    detail_service    TABLE       CREATE TABLE hotel.detail_service (
    srv_id integer NOT NULL,
    line_item_id integer NOT NULL,
    rsv_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    sub_total date NOT NULL,
    CONSTRAINT chk_dtl_srv_quantity CHECK ((quantity > 0))
);
 !   DROP TABLE hotel.detail_service;
       hotel         heap r       postgres    false    6         �            1259    33444    detail_service_line_item_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.detail_service_line_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE hotel.detail_service_line_item_id_seq;
       hotel               postgres    false    239    6         M           0    0    detail_service_line_item_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE hotel.detail_service_line_item_id_seq OWNED BY hotel.detail_service.line_item_id;
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
       hotel         heap r       postgres    false    6         �            1259    33389    reservation    TABLE        CREATE TABLE hotel.reservation (
    id integer NOT NULL,
    status character varying(50) NOT NULL,
    reservation_source character varying(50) NOT NULL,
    date date NOT NULL,
    total numeric(10,2) NOT NULL,
    cst_id character varying(15) NOT NULL,
    stf_id integer NOT NULL
);
    DROP TABLE hotel.reservation;
       hotel         heap r       postgres    false    6         �            1259    33388    reservation_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE hotel.reservation_id_seq;
       hotel               postgres    false    231    6         N           0    0    reservation_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE hotel.reservation_id_seq OWNED BY hotel.reservation.id;
          hotel               postgres    false    230         �            1259    33348    room    TABLE     �   CREATE TABLE hotel.room (
    id integer NOT NULL,
    rom_typ_id character varying(3) NOT NULL,
    status character varying(15) NOT NULL,
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
       hotel               postgres    false    227    6         O           0    0    room_id_seq    SEQUENCE OWNED BY     9   ALTER SEQUENCE hotel.room_id_seq OWNED BY hotel.room.id;
          hotel               postgres    false    226         �            1259    33337 	   room_type    TABLE     �   CREATE TABLE hotel.room_type (
    id character varying(3) NOT NULL,
    name character varying(50) NOT NULL,
    price_per_night numeric(10,2) NOT NULL,
    description character varying(200)
);
    DROP TABLE hotel.room_type;
       hotel         heap r       postgres    false    6         �            1259    33433    service    TABLE     �   CREATE TABLE hotel.service (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    price numeric(10,2) NOT NULL,
    total date NOT NULL,
    agr_id integer NOT NULL
);
    DROP TABLE hotel.service;
       hotel         heap r       postgres    false    6         �            1259    33432    service_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE hotel.service_id_seq;
       hotel               postgres    false    237    6         P           0    0    service_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE hotel.service_id_seq OWNED BY hotel.service.id;
          hotel               postgres    false    236         �            1259    33365    staff    TABLE     i  CREATE TABLE hotel.staff (
    id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
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
    boss_id integer
);
    DROP TABLE hotel.staff;
       hotel         heap r       postgres    false    6         �            1259    33364    staff_id_seq    SEQUENCE     �   CREATE SEQUENCE hotel.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE hotel.staff_id_seq;
       hotel               postgres    false    229    6         Q           0    0    staff_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE hotel.staff_id_seq OWNED BY hotel.staff.id;
          hotel               postgres    false    228         f           2604    33429    agreement id    DEFAULT     j   ALTER TABLE ONLY hotel.agreement ALTER COLUMN id SET DEFAULT nextval('hotel.agreement_id_seq'::regclass);
 :   ALTER TABLE hotel.agreement ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    235    234    235         c           2604    33409    detail_reservation line_item_id    DEFAULT     �   ALTER TABLE ONLY hotel.detail_reservation ALTER COLUMN line_item_id SET DEFAULT nextval('hotel.detail_reservation_line_item_id_seq'::regclass);
 M   ALTER TABLE hotel.detail_reservation ALTER COLUMN line_item_id DROP DEFAULT;
       hotel               postgres    false    233    232    233         h           2604    33448    detail_service line_item_id    DEFAULT     �   ALTER TABLE ONLY hotel.detail_service ALTER COLUMN line_item_id SET DEFAULT nextval('hotel.detail_service_line_item_id_seq'::regclass);
 I   ALTER TABLE hotel.detail_service ALTER COLUMN line_item_id DROP DEFAULT;
       hotel               postgres    false    239    238    239         b           2604    33392    reservation id    DEFAULT     n   ALTER TABLE ONLY hotel.reservation ALTER COLUMN id SET DEFAULT nextval('hotel.reservation_id_seq'::regclass);
 <   ALTER TABLE hotel.reservation ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    231    230    231         `           2604    33351    room id    DEFAULT     `   ALTER TABLE ONLY hotel.room ALTER COLUMN id SET DEFAULT nextval('hotel.room_id_seq'::regclass);
 5   ALTER TABLE hotel.room ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    226    227    227         g           2604    33436 
   service id    DEFAULT     f   ALTER TABLE ONLY hotel.service ALTER COLUMN id SET DEFAULT nextval('hotel.service_id_seq'::regclass);
 8   ALTER TABLE hotel.service ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    237    236    237         a           2604    33368    staff id    DEFAULT     b   ALTER TABLE ONLY hotel.staff ALTER COLUMN id SET DEFAULT nextval('hotel.staff_id_seq'::regclass);
 6   ALTER TABLE hotel.staff ALTER COLUMN id DROP DEFAULT;
       hotel               postgres    false    228    229    229         @          0    33426 	   agreement 
   TABLE DATA           O   COPY hotel.agreement (id, name, description, start_date, end_date) FROM stdin;
    hotel               postgres    false    235       4928.dat 3          0    33301    city 
   TABLE DATA           7   COPY hotel.city (id, dpt_id, cty_id, name) FROM stdin;
    hotel               postgres    false    222       4915.dat 1          0    33286    country 
   TABLE DATA           *   COPY hotel.country (id, name) FROM stdin;
    hotel               postgres    false    220       4913.dat 4          0    33311    customer 
   TABLE DATA           �   COPY hotel.customer (id, dct_typ_id, first_name, last_name, birth_date, gender, phone_number, email, prf_id, city_id, departament_id, country_id, destination_city_id, destination_departament_id, destination_country_id) FROM stdin;
    hotel               postgres    false    223       4916.dat 2          0    33291 
   department 
   TABLE DATA           5   COPY hotel.department (id, cty_id, name) FROM stdin;
    hotel               postgres    false    221       4914.dat >          0    33406    detail_reservation 
   TABLE DATA           �   COPY hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal) FROM stdin;
    hotel               postgres    false    233       4926.dat D          0    33445    detail_service 
   TABLE DATA           a   COPY hotel.detail_service (srv_id, line_item_id, rsv_id, price, quantity, sub_total) FROM stdin;
    hotel               postgres    false    239       4932.dat 0          0    33281    document_type 
   TABLE DATA           0   COPY hotel.document_type (id, name) FROM stdin;
    hotel               postgres    false    219       4912.dat 6          0    33342    hotel 
   TABLE DATA           J   COPY hotel.hotel (id, name, phone_number, email, total_rooms) FROM stdin;
    hotel               postgres    false    225       4918.dat /          0    33274 
   profession 
   TABLE DATA           :   COPY hotel.profession (id, name, description) FROM stdin;
    hotel               postgres    false    218       4911.dat <          0    33389    reservation 
   TABLE DATA           a   COPY hotel.reservation (id, status, reservation_source, date, total, cst_id, stf_id) FROM stdin;
    hotel               postgres    false    231       4924.dat 8          0    33348    room 
   TABLE DATA           =   COPY hotel.room (id, rom_typ_id, status, htl_id) FROM stdin;
    hotel               postgres    false    227       4920.dat 5          0    33337 	   room_type 
   TABLE DATA           J   COPY hotel.room_type (id, name, price_per_night, description) FROM stdin;
    hotel               postgres    false    224       4917.dat B          0    33433    service 
   TABLE DATA           @   COPY hotel.service (id, name, price, total, agr_id) FROM stdin;
    hotel               postgres    false    237       4930.dat :          0    33365    staff 
   TABLE DATA           �   COPY hotel.staff (id, first_name, last_name, phone_number, address, hire_date, salary, dct_typ_id, identity_document, worker_type, employee_number, direct_reports, work_shift, htl_id, boss_id) FROM stdin;
    hotel               postgres    false    229       4922.dat R           0    0    agreement_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('hotel.agreement_id_seq', 1, false);
          hotel               postgres    false    234         S           0    0 #   detail_reservation_line_item_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('hotel.detail_reservation_line_item_id_seq', 1, false);
          hotel               postgres    false    232         T           0    0    detail_service_line_item_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('hotel.detail_service_line_item_id_seq', 1, false);
          hotel               postgres    false    238         U           0    0    reservation_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('hotel.reservation_id_seq', 1, false);
          hotel               postgres    false    230         V           0    0    room_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('hotel.room_id_seq', 1, false);
          hotel               postgres    false    226         W           0    0    service_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('hotel.service_id_seq', 1, false);
          hotel               postgres    false    236         X           0    0    staff_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('hotel.staff_id_seq', 1, false);
          hotel               postgres    false    228         �           2606    33431    agreement agreement_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY hotel.agreement
    ADD CONSTRAINT agreement_pkey PRIMARY KEY (id);
 A   ALTER TABLE ONLY hotel.agreement DROP CONSTRAINT agreement_pkey;
       hotel                 postgres    false    235         s           2606    33290    country country_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY hotel.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY hotel.country DROP CONSTRAINT country_pkey;
       hotel                 postgres    false    220         y           2606    33316    customer customer_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT customer_pkey;
       hotel                 postgres    false    223         q           2606    33464     document_type document_type_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY hotel.document_type
    ADD CONSTRAINT document_type_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY hotel.document_type DROP CONSTRAINT document_type_pkey;
       hotel                 postgres    false    219         }           2606    33346    hotel hotel_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY hotel.hotel
    ADD CONSTRAINT hotel_pkey PRIMARY KEY (id);
 9   ALTER TABLE ONLY hotel.hotel DROP CONSTRAINT hotel_pkey;
       hotel                 postgres    false    225         w           2606    33305    city pk_cyy 
   CONSTRAINT     X   ALTER TABLE ONLY hotel.city
    ADD CONSTRAINT pk_cyy PRIMARY KEY (id, dpt_id, cty_id);
 4   ALTER TABLE ONLY hotel.city DROP CONSTRAINT pk_cyy;
       hotel                 postgres    false    222    222    222         u           2606    33295    department pk_dpt 
   CONSTRAINT     V   ALTER TABLE ONLY hotel.department
    ADD CONSTRAINT pk_dpt PRIMARY KEY (id, cty_id);
 :   ALTER TABLE ONLY hotel.department DROP CONSTRAINT pk_dpt;
       hotel                 postgres    false    221    221         �           2606    33414    detail_reservation pk_dtl_rsv 
   CONSTRAINT     l   ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT pk_dtl_rsv PRIMARY KEY (rsv_id, line_item_id);
 F   ALTER TABLE ONLY hotel.detail_reservation DROP CONSTRAINT pk_dtl_rsv;
       hotel                 postgres    false    233    233         �           2606    33451    detail_service pk_dtl_srv 
   CONSTRAINT     h   ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT pk_dtl_srv PRIMARY KEY (srv_id, line_item_id);
 B   ALTER TABLE ONLY hotel.detail_service DROP CONSTRAINT pk_dtl_srv;
       hotel                 postgres    false    239    239         m           2606    33278    profession profession_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY hotel.profession
    ADD CONSTRAINT profession_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY hotel.profession DROP CONSTRAINT profession_pkey;
       hotel                 postgres    false    218         �           2606    33394    reservation reservation_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY hotel.reservation DROP CONSTRAINT reservation_pkey;
       hotel                 postgres    false    231                    2606    33353    room room_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (id);
 7   ALTER TABLE ONLY hotel.room DROP CONSTRAINT room_pkey;
       hotel                 postgres    false    227         {           2606    33341    room_type room_type_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY hotel.room_type
    ADD CONSTRAINT room_type_pkey PRIMARY KEY (id);
 A   ALTER TABLE ONLY hotel.room_type DROP CONSTRAINT room_type_pkey;
       hotel                 postgres    false    224         �           2606    33438    service service_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY hotel.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY hotel.service DROP CONSTRAINT service_pkey;
       hotel                 postgres    false    237         �           2606    33372    staff staff_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);
 9   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT staff_pkey;
       hotel                 postgres    false    229         o           2606    33280    profession uk_prf_name 
   CONSTRAINT     P   ALTER TABLE ONLY hotel.profession
    ADD CONSTRAINT uk_prf_name UNIQUE (name);
 ?   ALTER TABLE ONLY hotel.profession DROP CONSTRAINT uk_prf_name;
       hotel                 postgres    false    218         �           2606    33327    customer fk_cst_city    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_city FOREIGN KEY (city_id, departament_id, country_id) REFERENCES hotel.city(id, dpt_id, cty_id);
 =   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_city;
       hotel               postgres    false    222    222    4727    223    223    223    222         �           2606    33465    customer fk_cst_dct_typ    FK CONSTRAINT        ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id);
 @   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_dct_typ;
       hotel               postgres    false    4721    223    219         �           2606    33332    customer fk_cst_dest_city    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_dest_city FOREIGN KEY (destination_city_id, destination_departament_id, destination_country_id) REFERENCES hotel.city(id, dpt_id, cty_id);
 B   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_dest_city;
       hotel               postgres    false    4727    222    222    223    223    222    223         �           2606    33322    customer fk_cst_prf    FK CONSTRAINT     t   ALTER TABLE ONLY hotel.customer
    ADD CONSTRAINT fk_cst_prf FOREIGN KEY (prf_id) REFERENCES hotel.profession(id);
 <   ALTER TABLE ONLY hotel.customer DROP CONSTRAINT fk_cst_prf;
       hotel               postgres    false    223    218    4717         �           2606    33306    city fk_cyy_dpt    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.city
    ADD CONSTRAINT fk_cyy_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES hotel.department(id, cty_id);
 8   ALTER TABLE ONLY hotel.city DROP CONSTRAINT fk_cyy_dpt;
       hotel               postgres    false    222    4725    221    221    222         �           2606    33296    department fk_dpt_cty    FK CONSTRAINT     s   ALTER TABLE ONLY hotel.department
    ADD CONSTRAINT fk_dpt_cty FOREIGN KEY (cty_id) REFERENCES hotel.country(id);
 >   ALTER TABLE ONLY hotel.department DROP CONSTRAINT fk_dpt_cty;
       hotel               postgres    false    220    221    4723         �           2606    33420 !   detail_reservation fk_dtl_rsv_rom    FK CONSTRAINT     }   ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT fk_dtl_rsv_rom FOREIGN KEY (room_id) REFERENCES hotel.room(id);
 J   ALTER TABLE ONLY hotel.detail_reservation DROP CONSTRAINT fk_dtl_rsv_rom;
       hotel               postgres    false    4735    233    227         �           2606    33415 !   detail_reservation fk_dtl_rsv_rsv    FK CONSTRAINT     �   ALTER TABLE ONLY hotel.detail_reservation
    ADD CONSTRAINT fk_dtl_rsv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id);
 J   ALTER TABLE ONLY hotel.detail_reservation DROP CONSTRAINT fk_dtl_rsv_rsv;
       hotel               postgres    false    233    4739    231         �           2606    33457    detail_service fk_dtl_srv_rsv    FK CONSTRAINT        ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT fk_dtl_srv_rsv FOREIGN KEY (rsv_id) REFERENCES hotel.reservation(id);
 F   ALTER TABLE ONLY hotel.detail_service DROP CONSTRAINT fk_dtl_srv_rsv;
       hotel               postgres    false    4739    231    239         �           2606    33452    detail_service fk_dtl_srv_srv    FK CONSTRAINT     {   ALTER TABLE ONLY hotel.detail_service
    ADD CONSTRAINT fk_dtl_srv_srv FOREIGN KEY (srv_id) REFERENCES hotel.service(id);
 F   ALTER TABLE ONLY hotel.detail_service DROP CONSTRAINT fk_dtl_srv_srv;
       hotel               postgres    false    239    237    4745         �           2606    33359    room fk_rom_htl    FK CONSTRAINT     k   ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT fk_rom_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id);
 8   ALTER TABLE ONLY hotel.room DROP CONSTRAINT fk_rom_htl;
       hotel               postgres    false    4733    227    225         �           2606    33354    room fk_rom_typ    FK CONSTRAINT     s   ALTER TABLE ONLY hotel.room
    ADD CONSTRAINT fk_rom_typ FOREIGN KEY (rom_typ_id) REFERENCES hotel.room_type(id);
 8   ALTER TABLE ONLY hotel.room DROP CONSTRAINT fk_rom_typ;
       hotel               postgres    false    227    4731    224         �           2606    33395    reservation fk_rsv_cst    FK CONSTRAINT     u   ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT fk_rsv_cst FOREIGN KEY (cst_id) REFERENCES hotel.customer(id);
 ?   ALTER TABLE ONLY hotel.reservation DROP CONSTRAINT fk_rsv_cst;
       hotel               postgres    false    231    223    4729         �           2606    33400    reservation fk_rsv_stf    FK CONSTRAINT     r   ALTER TABLE ONLY hotel.reservation
    ADD CONSTRAINT fk_rsv_stf FOREIGN KEY (stf_id) REFERENCES hotel.staff(id);
 ?   ALTER TABLE ONLY hotel.reservation DROP CONSTRAINT fk_rsv_stf;
       hotel               postgres    false    229    231    4737         �           2606    33439    service fk_srv_agr    FK CONSTRAINT     r   ALTER TABLE ONLY hotel.service
    ADD CONSTRAINT fk_srv_agr FOREIGN KEY (agr_id) REFERENCES hotel.agreement(id);
 ;   ALTER TABLE ONLY hotel.service DROP CONSTRAINT fk_srv_agr;
       hotel               postgres    false    235    4743    237         �           2606    33383    staff fk_stf_boss    FK CONSTRAINT     n   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_boss FOREIGN KEY (boss_id) REFERENCES hotel.staff(id);
 :   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT fk_stf_boss;
       hotel               postgres    false    229    229    4737         �           2606    33470    staff fk_stf_dct_typ    FK CONSTRAINT     |   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_dct_typ FOREIGN KEY (dct_typ_id) REFERENCES hotel.document_type(id);
 =   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT fk_stf_dct_typ;
       hotel               postgres    false    219    4721    229         �           2606    33378    staff fk_stf_htl    FK CONSTRAINT     l   ALTER TABLE ONLY hotel.staff
    ADD CONSTRAINT fk_stf_htl FOREIGN KEY (htl_id) REFERENCES hotel.hotel(id);
 9   ALTER TABLE ONLY hotel.staff DROP CONSTRAINT fk_stf_htl;
       hotel               postgres    false    229    225    4733                                                4928.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4915.dat                                                                                            0000600 0004000 0002000 00000057031 15014150412 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	5	170	MEDELLIN
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


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       4913.dat                                                                                            0000600 0004000 0002000 00000005275 15014150412 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        ﻿4	AFGANISTAN
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


                                                                                                                                                                                                                                                                                                                                   4916.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4914.dat                                                                                            0000600 0004000 0002000 00000000776 15014150412 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        5	170	ANTIOQUIA
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


  4926.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4932.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014237 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4912.dat                                                                                            0000600 0004000 0002000 00000000323 15014150412 0014240 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        RC	REGISTRO CIVIL
TI	TARJETA DE IDENTIDAD
CC	CEDULA DE CIUDADANIA
CE	CEDULA DE EXTRANJERIA
PP	PASAPORTE
NIT	NUMERO DE IDENTIFICACION TRIBUTARIA
TE	TARJETA DE EXTRANJERIA
PEP	PERMISO ESPECIAL DE PERMANENCIA
\.


                                                                                                                                                                                                                                                                                                             4918.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014243 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4911.dat                                                                                            0000600 0004000 0002000 00000106053 15014150412 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        P001	MEDICO	PROFESIONAL DE LA SALUD DEDICADO AL DIAGNOSTICO Y TRATAMIENTO DE ENFERMEDADES
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


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     4924.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014240 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4920.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014234 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4917.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4930.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014235 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4922.dat                                                                                            0000600 0004000 0002000 00000000005 15014150412 0014236 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           restore.sql                                                                                         0000600 0004000 0002000 00000057175 15014150412 0015374 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
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
    last_name character varying(50) NOT NULL,
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
    sub_total date NOT NULL,
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
    stf_id integer NOT NULL
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
    status character varying(15) NOT NULL,
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
    total date NOT NULL,
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
    id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
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
    boss_id integer
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
COPY hotel.agreement (id, name, description, start_date, end_date) FROM '$$PATH$$/4928.dat';

--
-- Data for Name: city; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.city (id, dpt_id, cty_id, name) FROM stdin;
\.
COPY hotel.city (id, dpt_id, cty_id, name) FROM '$$PATH$$/4915.dat';

--
-- Data for Name: country; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.country (id, name) FROM stdin;
\.
COPY hotel.country (id, name) FROM '$$PATH$$/4913.dat';

--
-- Data for Name: customer; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.customer (id, dct_typ_id, first_name, last_name, birth_date, gender, phone_number, email, prf_id, city_id, departament_id, country_id, destination_city_id, destination_departament_id, destination_country_id) FROM stdin;
\.
COPY hotel.customer (id, dct_typ_id, first_name, last_name, birth_date, gender, phone_number, email, prf_id, city_id, departament_id, country_id, destination_city_id, destination_departament_id, destination_country_id) FROM '$$PATH$$/4916.dat';

--
-- Data for Name: department; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.department (id, cty_id, name) FROM stdin;
\.
COPY hotel.department (id, cty_id, name) FROM '$$PATH$$/4914.dat';

--
-- Data for Name: detail_reservation; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal) FROM stdin;
\.
COPY hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in, check_out, discount, discount_value, subtotal) FROM '$$PATH$$/4926.dat';

--
-- Data for Name: detail_service; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.detail_service (srv_id, line_item_id, rsv_id, price, quantity, sub_total) FROM stdin;
\.
COPY hotel.detail_service (srv_id, line_item_id, rsv_id, price, quantity, sub_total) FROM '$$PATH$$/4932.dat';

--
-- Data for Name: document_type; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.document_type (id, name) FROM stdin;
\.
COPY hotel.document_type (id, name) FROM '$$PATH$$/4912.dat';

--
-- Data for Name: hotel; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.hotel (id, name, phone_number, email, total_rooms) FROM stdin;
\.
COPY hotel.hotel (id, name, phone_number, email, total_rooms) FROM '$$PATH$$/4918.dat';

--
-- Data for Name: profession; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.profession (id, name, description) FROM stdin;
\.
COPY hotel.profession (id, name, description) FROM '$$PATH$$/4911.dat';

--
-- Data for Name: reservation; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.reservation (id, status, reservation_source, date, total, cst_id, stf_id) FROM stdin;
\.
COPY hotel.reservation (id, status, reservation_source, date, total, cst_id, stf_id) FROM '$$PATH$$/4924.dat';

--
-- Data for Name: room; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.room (id, rom_typ_id, status, htl_id) FROM stdin;
\.
COPY hotel.room (id, rom_typ_id, status, htl_id) FROM '$$PATH$$/4920.dat';

--
-- Data for Name: room_type; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.room_type (id, name, price_per_night, description) FROM stdin;
\.
COPY hotel.room_type (id, name, price_per_night, description) FROM '$$PATH$$/4917.dat';

--
-- Data for Name: service; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.service (id, name, price, total, agr_id) FROM stdin;
\.
COPY hotel.service (id, name, price, total, agr_id) FROM '$$PATH$$/4930.dat';

--
-- Data for Name: staff; Type: TABLE DATA; Schema: hotel; Owner: postgres
--

COPY hotel.staff (id, first_name, last_name, phone_number, address, hire_date, salary, dct_typ_id, identity_document, worker_type, employee_number, direct_reports, work_shift, htl_id, boss_id) FROM stdin;
\.
COPY hotel.staff (id, first_name, last_name, phone_number, address, hire_date, salary, dct_typ_id, identity_document, worker_type, employee_number, direct_reports, work_shift, htl_id, boss_id) FROM '$$PATH$$/4922.dat';

--
-- Name: agreement_id_seq; Type: SEQUENCE SET; Schema: hotel; Owner: postgres
--

SELECT pg_catalog.setval('hotel.agreement_id_seq', 1, false);


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

SELECT pg_catalog.setval('hotel.service_id_seq', 1, false);


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

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   