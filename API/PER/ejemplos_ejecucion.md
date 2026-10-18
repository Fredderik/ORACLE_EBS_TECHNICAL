# Ejemplos de ejecución — API/PER

Ejecutar desde la raíz del repositorio. Los NULL son marcadores: sustituir los obligatorios por valores autorizados y válidos antes de ejecutar. Los opcionales pueden permanecer NULL según configuración. No ejecutar todos los bloques como una carga automática.

## Preparación común

```sql
SET SERVEROUTPUT ON
VARIABLE p_user_id NUMBER
VARIABLE p_resp_id NUMBER
VARIABLE p_resp_appl_id NUMBER
VARIABLE p_business_group_id NUMBER
VARIABLE p_validate VARCHAR2(2000)
EXEC :p_user_id := NULL;
EXEC :p_resp_id := NULL;
EXEC :p_resp_appl_id := NULL;
EXEC :p_business_group_id := NULL;
EXEC :p_validate := 'Y';
-- Completar los IDs y conservar p_validate = 'Y' para la primera revisión.
@utilidades/FND/inicializar_contexto.sql
```

Leer [contexto y transacciones](README.md) antes de continuar. Todos los ejemplos siguientes reutilizan esos binds. Tras validar, cambiar p_validate a N solo cuando se desee realizar la operación; luego revisar y confirmar o revertir manualmente.

## crear_empleado.sql

```sql
VARIABLE p_hire_date VARCHAR2(2000)
VARIABLE p_date_of_birth VARCHAR2(2000)
VARIABLE p_employee_number VARCHAR2(2000)
VARIABLE p_last_name VARCHAR2(2000)
VARIABLE p_sex VARCHAR2(2000)
VARIABLE p_first_name VARCHAR2(2000)
VARIABLE p_national_identifier VARCHAR2(2000)
VARIABLE p_email_address VARCHAR2(2000)
VARIABLE p_person_type_id NUMBER
EXEC :p_hire_date := NULL;
EXEC :p_date_of_birth := NULL;
EXEC :p_employee_number := NULL;
EXEC :p_last_name := NULL;
EXEC :p_sex := NULL;
EXEC :p_first_name := NULL;
EXEC :p_national_identifier := NULL;
EXEC :p_email_address := NULL;
EXEC :p_person_type_id := NULL;
-- Completar los parámetros indicados en la cabecera antes de ejecutar.
@API/PER/crear_empleado.sql
```

## crear_cargo.sql

```sql
VARIABLE p_date_from VARCHAR2(2000)
VARIABLE p_date_to VARCHAR2(2000)
VARIABLE p_job_group_id NUMBER
VARIABLE p_concat_segments VARCHAR2(2000)
VARIABLE p_language_code VARCHAR2(2000)
EXEC :p_date_from := NULL;
EXEC :p_date_to := NULL;
EXEC :p_job_group_id := NULL;
EXEC :p_concat_segments := NULL;
EXEC :p_language_code := NULL;
-- Completar los parámetros indicados en la cabecera antes de ejecutar.
@API/PER/crear_cargo.sql
```

## crear_ubicacion.sql

```sql
VARIABLE p_effective_date VARCHAR2(2000)
VARIABLE p_language_code VARCHAR2(2000)
VARIABLE p_location_code VARCHAR2(2000)
VARIABLE p_style VARCHAR2(2000)
VARIABLE p_country VARCHAR2(2000)
VARIABLE p_address_line_1 VARCHAR2(2000)
VARIABLE p_description VARCHAR2(2000)
VARIABLE p_town_or_city VARCHAR2(2000)
VARIABLE p_region_1 VARCHAR2(2000)
VARIABLE p_region_2 VARCHAR2(2000)
VARIABLE p_region_3 VARCHAR2(2000)
VARIABLE p_postal_code VARCHAR2(2000)
EXEC :p_effective_date := NULL;
EXEC :p_language_code := NULL;
EXEC :p_location_code := NULL;
EXEC :p_style := NULL;
EXEC :p_country := NULL;
EXEC :p_address_line_1 := NULL;
EXEC :p_description := NULL;
EXEC :p_town_or_city := NULL;
EXEC :p_region_1 := NULL;
EXEC :p_region_2 := NULL;
EXEC :p_region_3 := NULL;
EXEC :p_postal_code := NULL;
-- Completar los parámetros indicados en la cabecera antes de ejecutar.
@API/PER/crear_ubicacion.sql
```

## actualizar_asignacion.sql

```sql
VARIABLE p_effective_date VARCHAR2(2000)
VARIABLE p_object_version_number NUMBER
VARIABLE p_assignment_id NUMBER
VARIABLE p_supervisor_id NUMBER
VARIABLE p_datetrack_update_mode VARCHAR2(2000)
EXEC :p_effective_date := NULL;
EXEC :p_object_version_number := NULL;
EXEC :p_assignment_id := NULL;
EXEC :p_supervisor_id := NULL;
EXEC :p_datetrack_update_mode := NULL;
-- Completar los parámetros indicados en la cabecera antes de ejecutar.
@API/PER/actualizar_asignacion.sql
```

Para la asignación, obtener primero la versión con `@API/PER/consultar_asignacion.sql`. En cargos y ubicaciones, indicar el código de idioma instalado (por ejemplo US si corresponde). Las fechas usan YYYY-MM-DD. Los identificadores del ejemplo no se obtienen por suposición ni a partir de la OU.
