# FND — Utilidades PL/SQL

Ejemplos para inicializar contexto, enviar solicitudes y desarrollar un programa concurrente. Son operaciones de aplicación y ejemplos de desarrollo; las consultas de diagnóstico permanecen en [consultas/FND](../../consultas/FND/README.md).

## Archivos y parámetros

### [inicializar_contexto.sql](inicializar_contexto.sql)

| Parámetro | Tipo y uso |
| --- | --- |
| p_user_id | NUMBER, obligatorio |
| p_resp_id | NUMBER, obligatorio |
| p_resp_appl_id | NUMBER, obligatorio |

### [establecer_contexto_mo.sql](establecer_contexto_mo.sql)

| Parámetro | Tipo y uso |
| --- | --- |
| p_appl_short_name | VARCHAR2(50), aplicación MO, obligatoria |
| p_org_id | NUMBER, unidad operativa obligatoria |

### [lanzar_concurrente.sql](lanzar_concurrente.sql)

| Parámetro | Tipo y uso |
| --- | --- |
| p_application | VARCHAR2(50), aplicación del programa |
| p_program | VARCHAR2(30), nombre corto del programa |
| p_num_argumentos | NUMBER, entero de 0 a 3 |
| p_argumento1 | VARCHAR2(240), admite NULL |
| p_argumento2 | VARCHAR2(240), admite NULL |
| p_argumento3 | VARCHAR2(240), admite NULL |
| p_request_id | NUMBER, salida; declarar antes de ejecutar |

### [lanzar_juego_solicitudes.sql](lanzar_juego_solicitudes.sql)

| Parámetro | Tipo y uso |
| --- | --- |
| p_set_application | VARCHAR2(50), aplicación del juego |
| p_request_set | VARCHAR2(30), nombre de desarrollador del juego |
| p_application_1 | VARCHAR2(50), aplicación del primer programa |
| p_program_1 | VARCHAR2(30), primer programa |
| p_stage_1 | VARCHAR2(30), etapa de desarrollador del primer programa |
| p_num_argumentos_1 | NUMBER, entero de 0 a 3 |
| p_argumento1_1 | VARCHAR2(240), admite NULL |
| p_argumento2_1 | VARCHAR2(240), admite NULL |
| p_argumento3_1 | VARCHAR2(240), admite NULL |
| p_application_2 | VARCHAR2(50), aplicación del segundo programa |
| p_program_2 | VARCHAR2(30), segundo programa |
| p_stage_2 | VARCHAR2(30), etapa de desarrollador del segundo programa |
| p_num_argumentos_2 | NUMBER, entero de 0 a 3 |
| p_argumento1_2 | VARCHAR2(240), admite NULL |
| p_argumento2_2 | VARCHAR2(240), admite NULL |
| p_argumento3_2 | VARCHAR2(240), admite NULL |
| p_request_id | NUMBER, salida: solicitud padre |

### [esperar_concurrente.sql](esperar_concurrente.sql)

| Parámetro | Tipo y uso |
| --- | --- |
| p_request_id | NUMBER, solicitud ya confirmada |
| p_intervalo | NUMBER, segundos positivos enteros |
| p_tiempo_maximo | NUMBER, segundos positivos enteros |
| p_dev_phase | VARCHAR2(30), salida |
| p_dev_status | VARCHAR2(30), salida |
| p_mensaje | VARCHAR2(2000), salida |

### [plantilla_programa_concurrente.sql](plantilla_programa_concurrente.sql)

| Parámetro | Tipo y uso |
| --- | --- |
| errbuf | OUT VARCHAR2, mensaje al gestor |
| retcode | OUT VARCHAR2, 0 normal / 1 advertencia / 2 error |
| p_texto | IN VARCHAR2, único parámetro funcional |

## Ejemplos de uso

Los identificadores y nombres siguientes son ficticios. Sustitúyelos y ejecuta solo el ejemplo necesario. Mantén la misma conexión entre inicialización y envío. Los parámetros de salida también deben declararse antes de ejecutar.

### inicializar_contexto.sql

~~~sql
VARIABLE p_user_id NUMBER
VARIABLE p_resp_id NUMBER
VARIABLE p_resp_appl_id NUMBER
EXEC :p_user_id := 123;
EXEC :p_resp_id := 456;
EXEC :p_resp_appl_id := 200;
@utilidades/FND/inicializar_contexto.sql
~~~

### establecer_contexto_mo.sql

~~~sql
VARIABLE p_appl_short_name VARCHAR2(50)
VARIABLE p_org_id NUMBER
EXEC :p_appl_short_name := 'AP';
EXEC :p_org_id := 101;
@utilidades/FND/establecer_contexto_mo.sql
~~~

### lanzar_concurrente.sql

~~~sql
VARIABLE p_application VARCHAR2(50)
VARIABLE p_program VARCHAR2(30)
VARIABLE p_num_argumentos NUMBER
VARIABLE p_argumento1 VARCHAR2(240)
VARIABLE p_argumento2 VARCHAR2(240)
VARIABLE p_argumento3 VARCHAR2(240)
VARIABLE p_request_id NUMBER
EXEC :p_application := 'XXCUS';
EXEC :p_program := 'XX_EJEMPLO';
EXEC :p_num_argumentos := 1;
EXEC :p_argumento1 := 'Prueba';
EXEC :p_argumento2 := NULL;
EXEC :p_argumento3 := NULL;
EXEC :p_request_id := NULL;
@utilidades/FND/lanzar_concurrente.sql
PRINT p_request_id
-- Si el bloque terminó correctamente, decidir COMMIT o ROLLBACK.
-- COMMIT;
~~~

### lanzar_juego_solicitudes.sql

~~~sql
VARIABLE p_set_application VARCHAR2(50)
VARIABLE p_request_set VARCHAR2(30)
VARIABLE p_application_1 VARCHAR2(50)
VARIABLE p_program_1 VARCHAR2(30)
VARIABLE p_stage_1 VARCHAR2(30)
VARIABLE p_num_argumentos_1 NUMBER
VARIABLE p_argumento1_1 VARCHAR2(240)
VARIABLE p_argumento2_1 VARCHAR2(240)
VARIABLE p_argumento3_1 VARCHAR2(240)
VARIABLE p_application_2 VARCHAR2(50)
VARIABLE p_program_2 VARCHAR2(30)
VARIABLE p_stage_2 VARCHAR2(30)
VARIABLE p_num_argumentos_2 NUMBER
VARIABLE p_argumento1_2 VARCHAR2(240)
VARIABLE p_argumento2_2 VARCHAR2(240)
VARIABLE p_argumento3_2 VARCHAR2(240)
VARIABLE p_request_id NUMBER
EXEC :p_set_application := 'XXCUS';
EXEC :p_request_set := 'XX_JUEGO_EJEMPLO';
EXEC :p_application_1 := 'XXCUS';
EXEC :p_program_1 := 'XX_PROGRAMA_1';
EXEC :p_stage_1 := 'ETAPA_1';
EXEC :p_num_argumentos_1 := 0;
EXEC :p_argumento1_1 := NULL;
EXEC :p_argumento2_1 := NULL;
EXEC :p_argumento3_1 := NULL;
EXEC :p_application_2 := 'XXCUS';
EXEC :p_program_2 := 'XX_PROGRAMA_2';
EXEC :p_stage_2 := 'ETAPA_2';
EXEC :p_num_argumentos_2 := 0;
EXEC :p_argumento1_2 := NULL;
EXEC :p_argumento2_2 := NULL;
EXEC :p_argumento3_2 := NULL;
EXEC :p_request_id := NULL;
@utilidades/FND/lanzar_juego_solicitudes.sql
PRINT p_request_id
-- Si el bloque terminó correctamente, decidir COMMIT o ROLLBACK.
-- COMMIT;
~~~

### esperar_concurrente.sql

~~~sql
VARIABLE p_request_id NUMBER
VARIABLE p_intervalo NUMBER
VARIABLE p_tiempo_maximo NUMBER
VARIABLE p_dev_phase VARCHAR2(30)
VARIABLE p_dev_status VARCHAR2(30)
VARIABLE p_mensaje VARCHAR2(2000)
EXEC :p_request_id := 123456;
EXEC :p_intervalo := 10;
EXEC :p_tiempo_maximo := 300;
@utilidades/FND/esperar_concurrente.sql
~~~

## Ejecución y transacciones

Los ejemplos están orientados a SQL*Plus o SQLcl, conectados a una instancia EBS mediante el esquema y los permisos adecuados. En SQL Developer utiliza modo script. Cada bloque PL/SQL termina en END; seguido de slash en una línea independiente. No ejecutes todos los archivos como un lote de instalación.

APPS_INITIALIZE configura el contexto de una sesión externa; no autentica al usuario ni sustituye la autorización de su responsabilidad. Introduce una combinación válida y autorizada de usuario, responsabilidad y aplicación. Forms y el gestor concurrente ya inicializan su contexto: la plantilla concurrente no lo reemplaza.

La selección MO requiere ese contexto previo y comprueba el acceso a la unidad antes de seleccionarla. El grupo empresarial HR, el ledger y la organización de inventario no equivalen a una unidad operativa. El código de aplicación MO (por ejemplo AP) corresponde al producto que vas a utilizar.

Estos ejemplos leen FND_GLOBAL para comprobar el contexto inicializado, a diferencia de las consultas de diagnóstico que reciben sus filtros directamente. Toda identidad inicial y unidad operativa procede de parámetros explícitos.

Los scripts de envío no ejecutan COMMIT ni ROLLBACK. Tras un envío correcto, confirma en la misma sesión para que el gestor pueda procesarlo. Un ROLLBACK descarta el envío pendiente; el identificador devuelto no prueba que haya quedado confirmado. Ambas instrucciones afectan a la transacción completa de la sesión: usa una sesión sin trabajo ajeno pendiente. Si ocurre un error, revisa el mensaje y resuelve la transacción antes de reintentar; reinicia la preparación del juego desde SET_REQUEST_SET.

No esperes una solicitud recién creada antes de confirmar su envío. Inicializar contexto cambia estado de sesión: ROLLBACK no debe considerarse un mecanismo para restaurar el usuario, responsabilidad o contexto MO anterior.

## Parámetros de los envíos

Se utilizan nombres cortos de aplicación y programa; en juegos se utilizan nombres de desarrollador de juego y etapa, no etiquetas traducidas. Los objetos deben existir y estar habilitados y disponibles para la responsabilidad.

Las plantillas admiten de cero a tres parámetros funcionales por programa. p_num_argumentos indica cuántas posiciones reales se envían, incluidas las opcionales con NULL. CHR(0) se coloca después de la última posición real; no debe sustituir un NULL intermedio. Si el programa tiene más parámetros, amplía las llamadas, variables y validación hasta su número real (máximo de la API: 100). Envía fechas y números con el formato que espere el programa; no se fuerzan conversiones dependientes de NLS.

El inicio es inmediato (start_time NULL), sin repetición y sin modo subsolicitud. Para un programa que requiera contexto de unidad en su ejecución, configura sus opciones MO y parámetros según su contrato: el contexto MO de esta sesión no garantiza por sí solo el contexto de la sesión del gestor.

## Juego de solicitudes

lanzar_juego_solicitudes.sql es una plantilla para un juego existente de **dos miembros**, con hasta tres argumentos cada uno. Ajusta las llamadas registrar_programa para incluir todos los miembros de tu juego; no descubre ni reconstruye automáticamente su definición. Las dos etapas pueden ser la misma si así está configurado.

La definición del juego establece las dependencias, rutas por estado y orden de ejecución. Preparar dos programas consecutivamente en PL/SQL no crea una dependencia entre ellos. SUBMIT_SET devuelve la solicitud padre. Revisa también las solicitudes hijas y sus logs cuando el juego termine.

## Espera y resultado

p_intervalo y p_tiempo_maximo se expresan en segundos enteros positivos. El máximo evita una espera indefinida, pero no es un plazo exacto de tiempo real: la API consulta por intervalos y puede excederlo ligeramente. Alcanzarlo no cancela la solicitud.

El script muestra los valores de salida y distingue COMPLETE/NORMAL, advertencias y otros estados. Para encadenar procesos automáticamente, decide explícitamente si aceptas WARNING; no interpretes el booleano de la API como éxito funcional. Los mensajes devueltos por EBS pueden venir en el idioma del contexto; los mensajes propios del ejemplo están en español.

## Registrar la plantilla como concurrente

1. Revisa el nombre XX_EJEMPLO_CONCURRENTE y despliega el procedimiento de acuerdo con las normas de objetos personalizados de tu instancia. El archivo contiene CREATE OR REPLACE: modifica un objeto y produce COMMIT implícito.
2. Comprueba SHOW ERRORS y que el objeto esté válido. La publicación del archivo en GitHub no instala nada en EBS.
3. Registra un ejecutable en tu aplicación personalizada, con método **PL/SQL Stored Procedure** y archivo de ejecución que resuelva al procedimiento desplegado.
4. Registra el programa concurrente y vincula ese ejecutable.
5. Define únicamente p_texto como parámetro funcional, con conjunto de valores de texto y longitud compatible con el ejemplo (240). ERRBUF y RETCODE son parámetros reservados del gestor y no se registran como parámetros funcionales.
6. Habilita el programa y asígnalo al grupo de solicitudes de una responsabilidad autorizada. Ejecútalo y revisa log, salida y estado.

El ejemplo devuelve 0 para normal, 1 para advertencia y 2 para error; muestra escritura con FND_FILE.LOG y FND_FILE.OUTPUT. No realiza DML funcional. Si añades cambios de datos, define su atomicidad y manejo de errores: devolver RETCODE = 2 por sí solo no garantiza deshacerlos. No uses FND_FILE.CLOSE ni PUT_NAMES dentro del concurrente.

## Versiones y revisión

Objetivo: Oracle EBS R12.1/R12.2, sujeto a las APIs y parches instalados. Cabeceras y comentarios en español, autor y versión conservados. No se modifica directamente ninguna tabla de EBS. Las consultas SQL que se incorporen deben usar alias por iniciales y sintaxis tradicional.

Se revisaron firmas y flujo con documentación y controles estáticos. No se compilaron ni ejecutaron estos ejemplos contra Oracle EBS; queda pendiente esa validación, incluido el envío y la finalización real de solicitudes.

## Referencias

- [Oracle: inicialización con FND_GLOBAL](https://docs.oracle.com/cd/E26401_01/doc.122/e22961/T302934T462356.htm).
- [Oracle: APIs de concurrentes, FND_REQUEST, FND_SUBMIT y FND_FILE](https://docs.oracle.com/cd/E26401_01/doc.122/e22961/T302934T458258.htm).
- [Oracle: procedimientos concurrentes PL/SQL](https://docs.oracle.com/cd/E26401_01/doc.122/e22961/T302934T458252.htm).
- [MO_GLOBAL: especificación Oracle archivada en eTRM](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav1bbc-12.html).
