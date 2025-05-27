COPY hotel.customer(id,dct_typ_id,first_name,middle_name,last_name,second_last_name,birth_date,gender,phone_number,email,prf_id,city_id,departament_id,country_id,destination_city_id,destination_departament_id,destination_country_id)
FROM 'C:\fuente1\customer2.csv'
WITH DELIMITER AS ';' CSV QUOTE AS '"';

COPY hotel.detail_reservation(rsv_id, line_item_id, room_id, price, quantity, check_in,check_out,discount,discount_value,subtotal)
FROM 'C:\fuente1\detalle_r_final.csv'
WITH DELIMITER AS ';' CSV QUOTE AS '"';

SELECT * FROM hoteL.reservation
WHERE id=11

COPY hotel.detail_service(srv_id,line_item_id,rsv_id,price,quantity,sub_total)
FROM 'C:\fuente1\detalle_ser_final.csv'
WITH DELIMITER AS ';' CSV QUOTE AS '"';

COPY hotel.reservation(id,status,reservation_source,date,total,cst_id,stf_id)
FROM 'C:\fuente1\reservas_final.csv'
WITH DELIMITER AS ';' CSV QUOTE AS '"';

-- INSERT INTO hotel.hotel (id, name, phone_number, email, total_rooms)
-- VALUES ('H001', 'HOTEL SUEÑO REAL', '3118360951', 'sueñoreal@gmail.com', 27);

INSERT INTO hotel.reservation (id, status, reservation_source, date, total, cst_id,stf_id)
VALUES (2,'CONFIRMADA','EMAIL','20/08/2019',0,'1024756381','STF01');

INSERT INTO hotel.agreement (id, name, description, start_date, end_date)
VALUES (1,'Acuerdo de Lavanderia','Lavanderia para los clientes que deseen.','05/03/2020','05/03/2023');

INSERT INTO hotel.service (id, name, price, total, agr_id)
VALUES (1,'Lavado Manual Ropa',15000,0,1);

INSERT INTO hotel.detail_service (srv_id,line_item_id, rsv_id, price, quantity, sub_total)
VALUES (2,2,2,0,1,0);

INSERT INTO hotel.detail_reservation (rsv_id, line_item_id, room_id, price, quantity, check_in,check_out,discount,discount_value,subtotal)
VALUES (2,4,109,0,1,'21/08/2019','22/08/2019',5,0,0);

SELECT * FROM hoteL.detail_service
SELECT * FROM hoteL.detail_reservation
-- ALTER TABLE hotel.reservation
-- ALTER COLUMN stf_id TYPE VARCHAR(5);
-- ALTER COLUMN boss_id TYPE VARCHAR(5);


WHERE  id='68'

ALTER TABLE HOTEL.agreement ALTER COLUMN ID TYPE VARCHAR(6);
ALTER TABLE HOTEL.service ALTER COLUMN agr_id TYPE VARCHAR(6);

ALTER TABLE HOTEL.document_type ALTER COLUMN ID TYPE VARCHAR(3);
ALTER TABLE hotel.room ADD COLUMN room_number VARCHAR(3) NOT NULL;

ALTER TABLE hotel.service DROP COLUMN total;

SELECT * FROM hoteL.service
WHERE id=11


