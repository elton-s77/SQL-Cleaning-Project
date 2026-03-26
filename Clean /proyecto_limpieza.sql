create database if not exists clean;
## 0 inicio

-- Selección de una muestra de 10 registros para inspeccionar la estructura y el contenido de los datos antes de comenzar la limpieza.

use clean;
select * from limpieza limit 10; 

##1. Store procedure

-- Definición de un procedimiento almacenado que permite consultar fácilmente toda la tabla durante el proceso de limpieza y validación.

Delimiter // 
create procedure limp()
begin 
select * from limpieza;
end//
delimiter;

call limp() 

##2. Renombrar columnas

-- Renombrado de columnas con errores de codificación para mejorar la legibilidad, consistencia y facilidad de consulta en la base de datos.

alter table limpieza change column `ï»¿Id?empleado` id_emp varchar (20) null;
alter table limpieza change column `gÃ©nero` genero varchar (20) null;
alter table limpieza change column Apellido Last_name varchar (50) null;
alter table limpieza change column star_date start_date varchar (50) null;

##3. Identificar duplicados

-- Identificación y conteo de IDs repetidos mediante agrupación y subconsulta para evaluar la calidad e integridad de los datos.

select count(*) as cantidad_duplicados 
from (
Select id_emp, count(*) as cantidad_duplicados 
											   
from limpieza 
group by id_emp
having count(*) >1 ) as subquery;

## 4. Eliminar duplicados

-- Creación de una tabla temporal sin registros repetidos, validación de conteos y reconstrucción final de la tabla limpia eliminando los datos duplicados.

rename table limpieza to conduplicados; 

create temporary table temp_limpieza as 
select distinct * from conduplicados;

select count(*) as original from conduplicados;
select count(*) as original from temp_limpieza;

create table limpieza as select * from temp_limpieza;

drop table conduplicados; 
drop table `7. limpieza`;



## 5. Ver propiedades de la tabla

describe limpieza;

## 6. Remover espacios extra

-- Detección y corrección de espacios innecesarios al inicio y final de los campos de texto para mejorar la calidad y consistencia de los datos.

call limp()
SET SQL_SAFE_UPDATES = 0;  

select name from limpieza
where length(name) - length(trim(name)) >0;

select name, trim(name) as name
from limpieza
where length(name) - length(trim(name)) >0;

update limpieza set name= trim(name)
where length(name) - length(trim(name)) >0;


select name, trim(last_name) as last_name
from limpieza
where length(last_name) - length(trim(last_name)) >0;

update limpieza set last_name= trim(last_name)
where length(last_name) - length(trim(last_name)) >0;

## 7. remover espacios entre dos palabras

-- Detección y corrección de múltiples espacios consecutivos, unificando el texto para garantizar consistencia y facilitar análisis y agrupaciones.

update limpieza set area = replace (area, " ","   ");
call limp()
select area from limpieza 
where area regexp "\\s{2,}";

select area, trim(regexp_replace(area,"\\s+"," ")) as ensayo from limpieza;

update limpieza set area = trim(regexp_replace(area,"\\s+"," "));

## 8. Buscar y remplazar 

-- Renombrado, traducción y normalización de campos categóricos para unificar criterios, mejorar la consistencia semántica y facilitar el análisis posterior.

alter table limpieza change column genero gender varchar (50) null;

call limp()

select gender,
case
when gender = "hombre" then "male"
when gender = "mujer" then "female"
else "other"
end as gender1
from limpieza;

update limpieza set gender = case 
when gender = "hombre" then "male"
when gender = "mujer" then "female"
else "other"
end;


describe limpieza;

alter table limpieza modify column type text;

select type, 
case 
when type = 1 then "remote"
when type = 0 then "hybrid"
else "other"
end as ejemplo 
from limpieza

update limpieza 
set type = case 
when type = 1 then "remote"
when type = 0 then "hybrid"
else "other"
end;

call limp ()

## 9. Dar formato de nuemero a un texto 

-- Eliminación de símbolos monetarios y separadores, conversión a valor numérico y cambio del tipo de dato para permitir cálculos y análisis financieros correctos.

select salary,
cast(trim(replace(replace (salary,"$",""),",","")) as decimal (15,2)) as salary1 from limpieza;

update limpieza set salary = cast(trim(replace(replace (salary,"$",""),",","")) as decimal (15,2));

alter table limpieza modify column salary int null;

describe limpieza;

## 10. Ajustar formato de fechas

-- Detección de múltiples formatos de texto, transformación a fechas reales, 
-- validación previa y cambio de tipo de dato para asegurar consistencia temporal en los análisis.

-- ensayo dar formato de texto 
select start_date, case
when start_date like "%/%" then date_format(str_to_date(start_date, "%m/%d/%Y"),"%Y-%m-%d")
when start_date like "%-%" then date_format(str_to_date(start_date, "%m-%d-%Y"),"%Y-%m-%d")
else null 
end as new_start_date
from limpieza;

-- actualizar 
update limpieza 
set start_date=case 
when start_date like "%/%" then date_format(str_to_date(start_date, "%m/%d/%Y"),"%Y-%m-%d")
when start_date like "%-%" then date_format(str_to_date(start_date, "%m-%d-%Y"),"%Y-%m-%d")
else null 
end;

call limp ()

-- cambiar el tipo de dato de columna 
alter table limpieza modify column start_date date;
describe limpieza;

-- ensayo dar formato de texto 
select birth_date, case
when birth_date like "%/%" then date_format(str_to_date(birth_date, "%m/%d/%Y"),"%Y-%m-%d")
when birth_date like "%-%" then date_format(str_to_date(birth_date, "%m-%d-%Y"),"%Y-%m-%d")
else null 
end as new_birth_date
from limpieza;

-- actualizar 
update limpieza 
set birth_date=case 
when birth_date like "%/%" then date_format(str_to_date(birth_date, "%m/%d/%Y"),"%Y-%m-%d")
when birth_date like "%-%" then date_format(str_to_date(birth_date, "%m-%d-%Y"),"%Y-%m-%d")
else null 
end;

-- cambiar el tipo de dato de columna 
alter table limpieza modify column birth_date date;
describe limpieza;

## 11. Otras funciones de fecha 

-- Respaldo del dato original, conversión de texto a DATETIME, separación en campos fecha y hora,
--  normalización de valores nulos y tipado correcto para análisis temporal preciso.

alter table limpieza add column date_backup text;
call limp ()

update limpieza set date_backup = finish_date;

update limpieza set finish_date = str_to_date(finish_date, "%Y-%m-%d %H:%i:%s UTC") where finish_date <> "";

alter table limpieza
add column fecha date,
add column hora time;

update limpieza
set fecha = date(finish_date),
     hora = time (finish_date)
     where finish_date is not null and finish_date <> "";
     
update limpieza set finish_date = null where finish_date = "";

alter table limpieza modify column finish_date datetime;
describe limpieza;

##12 calculos con fechas 

-- Creación de la columna edad y cálculo automático de métricas demográficas clave para análisis de recursos humanos.

alter table limpieza add column age int;
call limp ()

select name, birth_date,start_date, timestampdiff(year, birth_date, start_date) as edad_de_ingreso from limpieza;

update limpieza 
set age = timestampdiff(year, birth_date, curdate());

select name, birth_date, age from limpieza;


##13 preparar para exportar

-- Extracción y ordenamiento de registros relevantes y generación de métricas agregadas por área para su posterior exportación y uso en dashboards.

select id_emp, name, last_name, age, gender, area, salary, finish_date  from limpieza
where finish_date <= curdate() or finish_date is null 
order by area, last_name;

select area, count(*) as cantidad_empleados from limpieza 
group by  area 
order by cantidad_empleados Desc;
