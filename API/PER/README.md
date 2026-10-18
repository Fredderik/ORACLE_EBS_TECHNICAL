# PER — APIs de HRMS (Oracle EBS R12)

Ejemplos de llamadas a APIs públicas de recursos humanos. PER mantiene la organización utilizada en [consultas/PER](../../consultas/PER/README.md). No se crean paquetes ni tablas propios.

| Archivo | API / propósito |
| --- | --- |
| [crear_empleado.sql](crear_empleado.sql) | HR_EMPLOYEE_API.CREATE_EMPLOYEE: persona nueva y asignación predeterminada. |
| [actualizar_asignacion.sql](actualizar_asignacion.sql) | HR_ASSIGNMENT_API.UPDATE_EMP_ASG: cambiar supervisor de una asignación existente. |
| [crear_cargo.sql](crear_cargo.sql) | HR_JOB_API.CREATE_JOB: cargo con su combinación de flexfield. |
| [crear_ubicacion.sql](crear_ubicacion.sql) | HR_LOCATION_API.CREATE_LOCATION: ubicación de oficina. |
| [consultar_asignacion.sql](consultar_asignacion.sql) | Leer OVN efectivo e historial DateTrack antes de actualizar. |
| [ejemplos_ejecucion.md](ejemplos_ejecucion.md) | Declaraciones de todos los binds para SQL*Plus. |

## Contexto y alcance

Usar una conexión APPS autorizada de pruebas. Inicializar usuario, responsabilidad y aplicación en la misma sesión mediante [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql) antes de ejecutar. APPS_INITIALIZE no autentica ni concede acceso: deben ser IDs autorizados. Usar una sesión nueva al cambiar de contexto.

Todos los bloques reciben p_user_id, p_resp_id, p_resp_appl_id y p_business_group_id como NUMBER. Comprueban el contexto y limitan el ejemplo al grupo indicado en el perfil HR: Business Group. Esta comprobación no sustituye la autorización ni la seguridad de personas de HR. Los filtros SQL utilizan el grupo explícito.

BUSINESS_GROUP_ID no es ORG_ID de una unidad operativa. Estos ejemplos no llaman MO_GLOBAL ni cambian perfiles para forzar el acceso a otro grupo. Las integraciones entre grupos requieren un diseño específico de seguridad y legislación.

## Validación, errores y transacciones

p_validate es un bind VARCHAR2: Y solicita validación; N ejecuta la operación dejando la transacción pendiente. Se convierte a BOOLEAN para la API. Declarar también los opcionales con NULL. Usar fechas de texto YYYY-MM-DD; no depender de NLS_DATE_FORMAT.

Las APIs HR aquí utilizadas comunican fallos mediante excepciones y algunas advertencias mediante parámetros OUT. No tienen el contrato X_RETURN_STATUS de los ejemplos AP. El bloque imprime SQLERRM, revierte a su SAVEPOINT y vuelve a lanzar el error. Las advertencias no se convierten automáticamente en errores: revisarlas antes de confirmar.

En modo Y se revierte al SAVEPOINT también al terminar correctamente. No reutilizar IDs o números obtenidos durante la validación; puede haber consumo de secuencias y deben revisarse los hooks locales si producen efectos externos. En modo N no hay COMMIT automático. Revisar cambios en la misma sesión y decidir COMMIT o ROLLBACK manualmente.

Un error solo deshace el bloque actual; no operaciones previas. SQL*Plus puede continuar tras errores: ejecutar cada ejemplo por separado y no añadir un COMMIT incondicional. Estos scripts no garantizan idempotencia: antes de reintentar una creación comprobar si ya existe.

## Empleados

La plantilla crea una persona nueva como empleado; no sirve para recontratar ni convertir un candidato existente. La numeración puede ser automática o manual: p_employee_number es IN OUT, usar NULL o un número según la configuración. p_person_type_id permite indicar un tipo válido o dejar que la API determine el predeterminado.

p_sex es el código de lookup admitido por la instalación. Fecha de nacimiento, identificador nacional y datos adicionales pueden ser obligatorios por legislación, configuración o hooks. Adaptar la llamada cuando se necesiten parámetros legislativos; el ejemplo no implementa todas las localizaciones.

El alta devuelve PERSON_ID, ASSIGNMENT_ID, versiones y vigencia. La asignación inicial aún puede necesitar organización, cargo, posición, nómina y otros datos. El ejemplo de actualización incluido cambia solo el supervisor; no configura todo el vínculo laboral.

## Asignaciones y DateTrack

Primero ejecutar consultar_asignacion.sql con la fecha exacta. Copiar OBJECT_VERSION_NUMBER del registro vigente a p_object_version_number, revisar el historial y escoger el modo:

- CORRECTION corrige el registro efectivo existente sin crear una nueva división temporal.
- UPDATE introduce un cambio efectivo; su viabilidad depende de la fecha y los cambios futuros.
- UPDATE_CHANGE_INSERT y UPDATE_OVERRIDE quedan fuera del ejemplo; no se borra automáticamente el historial futuro para resolver un error.

El nuevo supervisor se pasa como PERSON_ID, no ASSIGNMENT_ID. Se exige una persona del mismo grupo y fecha, y la API realiza sus validaciones adicionales. No se contempla retirar el supervisor con NULL.

La versión recibida se contrasta con la tabla y se entrega a la API para su control de concurrencia. Si cambia, volver a consultar y revisar; no sustituirla silenciosamente por la última. Los parámetros IN omitidos conservan sus valores mediante los centinelas HR_API; NULL explícito puede significar borrar un dato. Los IN OUT de flexfields se inicializan con G_NUMBER para conservarlos.

## Cargos y ubicaciones

En cargos, p_job_group_id identifica un grupo de cargos configurado; no es el grupo empresarial. p_concat_segments debe seguir el orden, valores y separador del Job Key Flexfield. Un Job no es una Position. Se pasa p_language_code explícito; no se presupone que un único segmento sirva para todas las instalaciones.

La ubicación se limita al grupo empresarial y se configura como oficina, sin habilitar recepción, envío ni facturación. p_style y los campos de país, ciudad y regiones deben corresponder al estilo de dirección configurado. p_effective_date sirve para validaciones de la API; no convierte la ubicación en una entidad DateTrack.

## Validación y fuentes

Objetivo R12.1/R12.2, sujeto a firmas y parches instalados. Revisión documental y estática; **pendientes compilación y pruebas funcionales en EBS**. Antes de adoptar los ejemplos probar validación sin persistencia, alta, reversión, advertencias, legislación, grupo incorrecto y OVN obsoleto.

- [Oracle HRMS: contratos de APIs, validación y OVN](https://docs.oracle.com/cd/E18727_01/doc.121/e13513/T2650T402390.htm).
- [HR_EMPLOYEE_API](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav54e8-13.html?c_detail_type=source&c_name=HR_EMPLOYEE_API&c_owner=APPS&c_type=PACKAGE).
- [HR_ASSIGNMENT_API](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav822a-11.html?c_detail_type=source&c_name=HR_ASSIGNMENT_API&c_owner=APPS&c_type=PACKAGE).
- [HR_JOB_API](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnave347-16.html).
- [HR_LOCATION_API](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav24bf-18.html?c_detail_type=source&c_name=HR_LOCATION_API&c_owner=APPS&c_type=PACKAGE).

[Volver a API](../README.md)
