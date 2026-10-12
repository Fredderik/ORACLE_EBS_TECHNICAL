# IBY — Oracle Payments

Consultas del procesamiento de desembolsos: solicitudes, pagos, instrucciones, documentos pagables y errores de validación. Complementan los recursos de [AP](../AP/README.md) y [CE](../CE/README.md).

## Archivos

| Archivo | Resultado |
| --- | --- |
| [solicitudes.sql](solicitudes.sql) | Una fila por solicitud de proceso de pago, incluso sin pagos generados. |
| [pagos_instrucciones.sql](pagos_instrucciones.sql) | Una fila por pago y la instrucción asociada, si existe. |
| [documentos_pagables.sql](documentos_pagables.sql) | Una fila por documento enviado a Payments; conserva documentos sin pago. |
| [errores_validacion.sql](errores_validacion.sql) | Una fila por error de una entidad identificada por tipo e ID. |

## Parámetros por archivo

- **solicitudes.sql**: obligatorios: ninguno. Opcionales: p_payment_service_request_id, p_calling_app_id, p_estado_solicitud, p_fecha_desde, p_fecha_hasta.
- **pagos_instrucciones.sql**: obligatorios: p_org_id. Opcionales: p_payment_service_request_id, p_payment_id, p_payment_instruction_id, p_payment_status, p_fecha_desde, p_fecha_hasta.
- **documentos_pagables.sql**: obligatorios: p_org_id. Opcionales: p_payment_service_request_id, p_payment_id, p_document_payable_id, p_calling_app_id.
- **errores_validacion.sql**: obligatorios: p_transaction_type, p_transaction_id. Opcionales: p_error_status.

| Parámetro | Tipo |
| --- | --- |
| p_payment_service_request_id | NUMBER |
| p_calling_app_id | NUMBER |
| p_estado_solicitud | VARCHAR2(30) |
| p_fecha_desde | VARCHAR2(10), YYYY-MM-DD |
| p_fecha_hasta | VARCHAR2(10), YYYY-MM-DD |
| p_org_id | NUMBER |
| p_payment_id | NUMBER |
| p_payment_instruction_id | NUMBER |
| p_payment_status | VARCHAR2(30) |
| p_document_payable_id | NUMBER |
| p_transaction_type | VARCHAR2(30) |
| p_transaction_id | NUMBER |
| p_error_status | VARCHAR2(30) |

NULL omite un filtro opcional. Los nombres y códigos se comparan por igualdad exacta. En los rangos, la fecha desde es inclusiva y la fecha hasta incluye todo ese día. Introduce fechas válidas en orden ascendente. El idioma es un código instalado en EBS; si falta su traducción, se conserva el registro con descripción vacía.

## Ejemplo de ejecución

Valores ficticios: reemplaza los identificadores, libro y códigos por los de tu entorno. Declara todos los parámetros del archivo, incluso los opcionales. Este bloque prepara las variables de todos los scripts de la carpeta.

~~~sql
VARIABLE p_payment_service_request_id NUMBER
VARIABLE p_calling_app_id NUMBER
VARIABLE p_estado_solicitud VARCHAR2(30)
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)
VARIABLE p_org_id NUMBER
VARIABLE p_payment_id NUMBER
VARIABLE p_payment_instruction_id NUMBER
VARIABLE p_payment_status VARCHAR2(30)
VARIABLE p_document_payable_id NUMBER
VARIABLE p_transaction_type VARCHAR2(30)
VARIABLE p_transaction_id NUMBER
VARIABLE p_error_status VARCHAR2(30)

EXEC :p_payment_service_request_id := NULL;
EXEC :p_calling_app_id := NULL;
EXEC :p_estado_solicitud := NULL;
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;
EXEC :p_org_id := 101;
EXEC :p_payment_id := NULL;
EXEC :p_payment_instruction_id := NULL;
EXEC :p_payment_status := NULL;
EXEC :p_document_payable_id := NULL;
EXEC :p_transaction_type := 'PAYMENT';
EXEC :p_transaction_id := 12345;
EXEC :p_error_status := NULL;

@consultas/IBY/solicitudes.sql
@consultas/IBY/pagos_instrucciones.sql
@consultas/IBY/documentos_pagables.sql
@consultas/IBY/errores_validacion.sql
~~~

## Interpretación y alcance

El identificador PAYMENT_SERVICE_REQUEST_ID no es el REQUEST_ID de un concurrente. La solicitud puede agrupar documentos de varias organizaciones; solicitudes.sql no impone un ORG_ID inexistente en su tabla. Los scripts de pagos y documentos sí requieren p_org_id.

Para consultar errores se requiere el par p_transaction_type + p_transaction_id. Usa DOCUMENT_PAYABLE con DOCUMENT_PAYABLE_ID, PAYMENT con PAYMENT_ID o PAYMENT_INSTRUCTION con PAYMENT_INSTRUCTION_ID. Un mismo número puede identificar entidades distintas. p_error_status puede ser ACTIVE para limitar a errores activos o NULL para mostrar todos; el script devuelve códigos, no mensajes traducidos ni tokens. No usa idioma porque no consulta traducciones.

Las referencias CALLING_APP_DOC_UNIQUE_REF1..5 dependen de la aplicación de origen; no se convierten automáticamente a INVOICE_ID. Un pago puede agrupar varios documentos: importe_total_pago se repite en ese detalle y no debe sumarse. Una instrucción también puede agrupar varios pagos o solicitudes; se enlaza por PAYMENT_INSTRUCTION_ID, no por solicitud.

El rango de fechas se aplica a CREATION_DATE en solicitudes y PAYMENT_DATE en pagos. Los estados de procesamiento no prueban conciliación ni liquidación bancaria. El alcance inicial es desembolsos, no captura de cobros, configuración completa de cuentas bancarias ni todo el historial archivado.

## Convenciones y validación

Oracle EBS R12.1/R12.2 como versiones objetivo. Comentarios en español, cabeceras con autor y versión, alias por iniciales, tablas base y sintaxis tradicional con igualdad y (+). No se obtiene organización o idioma de la sesión. En R12.2 se utilizan los sinónimos estándar de APPS aunque internamente resuelvan a vistas de edición.

Los archivos con varios resultados usan slash en una línea independiente; la consulta previa no termina en punto y coma para evitar su doble ejecución en SQL*Plus. Ejecuta esos archivos en modo script.

Requiere permisos de lectura sobre los objetos referenciados. Se realizó revisión documental y comprobación con datos ficticios; queda pendiente la ejecución nativa en una instancia Oracle EBS y la validación según sus parches.

## Referencias de esquema

- [IBY_PAY_SERVICE_REQUESTS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnava51e-2.html).
- [IBY_PAYMENTS_ALL — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavb969-2.html).
- [IBY_DOCS_PAYABLE_ALL — eTRM Oracle archivado](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav3e05.html).
- [IBY_TRANSACTION_ERRORS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavebc4-2.html).
