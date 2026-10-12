# PER — Recursos humanos (HRMS)

HRMS agrupa distintas áreas de recursos humanos. Esta carpeta aborda el núcleo de **PER / Human Resources**: personas, asignaciones y estructuras básicas. Oracle Payroll (PAY), beneficios y control de tiempos tienen un alcance propio.

## Consultas

| Archivo | Resultado |
| --- | --- |
| [personas.sql](personas.sql) | Persona en la fecha de corte; puede ser empleado, exempleado, candidato u otro tipo. |
| [asignaciones.sql](asignaciones.sql) | Asignación vigente con persona, organización y supervisor. |
| [organizaciones.sql](organizaciones.sql) | Unidades organizativas vigentes y nombre en el idioma solicitado. |
| [cargos_posiciones.sql](cargos_posiciones.sql) | Dos resultados: cargos y posiciones. |
| [periodos_servicio.sql](periodos_servicio.sql) | Historial de períodos de empleo de una persona, incluidas recontrataciones. |

## Parámetros por archivo

- **personas.sql**: obligatorios: p_business_group_id, p_fecha_corte. Opcionales: p_person_id, p_employee_number.
- **asignaciones.sql**: obligatorios: p_business_group_id, p_fecha_corte, p_language. Opcionales: p_person_id, p_assignment_id, p_assignment_type, p_primary_flag, p_organization_id.
- **organizaciones.sql**: obligatorios: p_business_group_id, p_fecha_corte, p_language. Opcionales: p_organization_id.
- **cargos_posiciones.sql**: obligatorios: p_business_group_id, p_fecha_corte. Opcionales: p_job_id, p_position_id.
- **periodos_servicio.sql**: obligatorios: p_business_group_id, p_person_id. Opcionales: p_period_of_service_id.

| Parámetro | Tipo y significado |
| --- | --- |
| p_business_group_id | NUMBER. Grupo empresarial de HR; no equivale al ORG_ID de una unidad operativa. |
| p_fecha_corte | VARCHAR2(10), YYYY-MM-DD. Fecha efectiva de consulta, obligatoria salvo en períodos de servicio. |
| p_language | VARCHAR2(4). Código de idioma instalado, por ejemplo US; solo en asignaciones y organizaciones. |
| p_person_id | NUMBER. Persona; obligatorio en períodos de servicio. |
| p_employee_number | VARCHAR2(30). Número de empleado, conservado como texto. |
| p_assignment_id | NUMBER. Identificador de asignación. |
| p_assignment_type | VARCHAR2(1). Código de tipo, por ejemplo E para empleado; NULL conserva todos los tipos. |
| p_primary_flag | VARCHAR2(1). Y/N; NULL conserva asignaciones principales y secundarias. |
| p_organization_id | NUMBER. Organización de HR. |
| p_job_id | NUMBER. Cargo; filtra ambos resultados del catálogo. |
| p_position_id | NUMBER. Posición; solo filtra el segundo resultado del catálogo. |
| p_period_of_service_id | NUMBER. Período de servicio específico. |

Todos los filtros opcionales admiten NULL. Los identificadores y códigos se comparan por igualdad exacta. Declara todas las variables del archivo, aunque sean opcionales.

## Ejemplo SQL*Plus / SQLcl

Los valores son ficticios; sustituye el grupo y la persona por los de tu entorno.

~~~sql
VARIABLE p_business_group_id NUMBER
VARIABLE p_fecha_corte VARCHAR2(10)
VARIABLE p_language VARCHAR2(4)
VARIABLE p_person_id NUMBER
VARIABLE p_employee_number VARCHAR2(30)
VARIABLE p_assignment_id NUMBER
VARIABLE p_assignment_type VARCHAR2(1)
VARIABLE p_primary_flag VARCHAR2(1)
VARIABLE p_organization_id NUMBER
VARIABLE p_job_id NUMBER
VARIABLE p_position_id NUMBER
VARIABLE p_period_of_service_id NUMBER

EXEC :p_business_group_id := 101;
EXEC :p_fecha_corte := '2026-10-11';
EXEC :p_language := 'US';
EXEC :p_person_id := 12345;
EXEC :p_employee_number := NULL;
EXEC :p_assignment_id := NULL;
EXEC :p_assignment_type := NULL;
EXEC :p_primary_flag := NULL;
EXEC :p_organization_id := NULL;
EXEC :p_job_id := NULL;
EXEC :p_position_id := NULL;
EXEC :p_period_of_service_id := NULL;

@consultas/PER/personas.sql
@consultas/PER/asignaciones.sql
@consultas/PER/organizaciones.sql
@consultas/PER/cargos_posiciones.sql
@consultas/PER/periodos_servicio.sql
~~~

Los catálogos de organizaciones, cargos y posiciones no se filtran por persona. En cargos_posiciones.sql, el slash ejecuta la primera consulta; esta no lleva punto y coma antes para evitar duplicarla. Ejecuta el archivo en modo script.

## Fechas y relaciones

Las tablas PER_ALL_PEOPLE_F, PER_ALL_ASSIGNMENTS_F y HR_ALL_POSITIONS_F conservan versiones DateTrack. Se selecciona la versión cuyo intervalo incluye p_fecha_corte, con ambos extremos inclusivos. No se utiliza SYSDATE ni se toma la fecha de la sesión.

La persona y la asignación se filtran por la misma fecha y grupo empresarial. Una persona puede tener varias asignaciones simultáneas: son filas distintas, no duplicados que deban eliminarse con DISTINCT. PRIMARY_FLAG = Y no demuestra que una asignación esté activa; se muestra ASSIGNMENT_STATUS_TYPE_ID para analizar su estado.

El supervisor se resuelve por SUPERVISOR_ID y por su versión vigente. Puede pertenecer a otro grupo empresarial. Si no existe versión para esa fecha, se conserva la asignación con su identificador y el nombre vacío.

Las traducciones organizativas se enlazan por clave e idioma explícito; si no existen, se conserva el registro. No tienen historial DateTrack: el nombre traducido puede reflejar una denominación posterior a la fecha de corte. Los nombres base de cargos y posiciones se muestran tal como están almacenados, sin resolución de idioma por sesión; el catálogo no consulta sus traducciones.

Un cargo (job) describe una función; una posición (position) la concreta dentro de una organización. El catálogo de organizaciones no reconstruye jerarquías ni identifica todas sus clasificaciones funcionales.

periodos_servicio.sql no aplica fecha de corte ni une versiones de personas: muestra un período por fila. DATE_START representa el inicio de ese período de empleo. Las fechas de baja y de procesamiento de nómina tienen significados distintos. El script cubre empleo; no consulta los períodos de trabajadores contingentes en PER_PERIODS_OF_PLACEMENT.

## Convenciones y validación

Versiones objetivo: EBS R12.1/R12.2. Comentarios en español, cabeceras con autor y versión, alias por iniciales y sufijo de función cuando se repite una tabla (papf_sup). Tablas base, sintaxis tradicional, relaciones por igualdad y (+). No se usan vistas funcionales dependientes de sesión.

Requiere lectura sobre los objetos indicados. El filtro BUSINESS_GROUP_ID define el alcance de la consulta; no reproduce los perfiles de seguridad de HRMS. En R12.2 utiliza los sinónimos estándar de APPS, aunque resuelvan internamente a vistas de edición.

Revisión documental y comprobaciones con datos ficticios; pendiente ejecución nativa en una instancia Oracle EBS según su versión y parches.

## Referencias de esquema

- [PER_ALL_PEOPLE_F — eTRM Oracle archivado](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav9226-2.html).
- [PER_ALL_ASSIGNMENTS_F — eTRM Oracle archivado](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav00ce.html).
- [HR_ALL_ORGANIZATION_UNITS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav57bb.html).
- [PER_JOBS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav5be0-2.html).
- [HR_ALL_POSITIONS_F — eTRM Oracle archivado](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav8591.html).
- [PER_PERIODS_OF_SERVICE — eTRM Oracle archivado](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav1b9f-3.html).
