# XLA — Subledger Accounting

XLA es la capa de contabilidad auxiliar de Oracle EBS R12: transforma eventos de las aplicaciones en asientos que pueden transferirse a GL. Permite seguir el recorrido entidad → evento → cabecera contable → líneas → referencias GL.

## Contenido

| Archivo | Resultado |
| --- | --- |
| [eventos_contables.sql](eventos_contables.sql) | Entidades y eventos, incluidos eventos que aún no tienen asientos. |
| [asientos_detalle.sql](asientos_detalle.sql) | Dos consultas: cabeceras y cabeceras con líneas. Conserva cabeceras sin líneas. |
| [distribuciones_origen.sql](distribuciones_origen.sql) | Líneas y vínculos con distribuciones de la aplicación de origen; conserva líneas sin vínculo. |
| [trazabilidad_gl.sql](trazabilidad_gl.sql) | Líneas XLA, referencias de importación, líneas, asientos y lotes GL; conserva líneas sin referencia. |

Consultas de lectura orientadas a R12.1 y R12.2. Usan tablas base, relaciones por igualdad y uniones externas (+). No dependen del idioma ni de la organización de la sesión; muestran códigos originales. Deben ejecutarse con permisos sobre los objetos referenciados. La selección explícita de aplicación/libro no sustituye los controles de acceso del entorno.

## Parámetros

Declarar todas las variables del archivo, también las opcionales. NULL omite un filtro opcional; los obligatorios no admiten NULL. Las comparaciones de texto son exactas.

| Parámetro | Tipo | Alcance |
| --- | --- | --- |
| p_application_id | NUMBER, obligatorio en los cuatro scripts originales | Aplicación de origen del asiento/evento, no fijar siempre la aplicación XLA. |
| p_ledger_id | NUMBER, obligatorio salvo eventos | Libro de XLA_AE_HEADERS. |
| p_entity_ledger_id | NUMBER, opcional, solo eventos | Libro de XLA_TRANSACTION_ENTITIES. |
| p_entity_id, p_event_id | NUMBER, opcionales | Entidad y evento dentro de la aplicación indicada. |
| p_ae_header_id | NUMBER, opcional, salvo eventos | Cabecera contable. |
| p_period_name | VARCHAR2(15), opcional, salvo eventos | Período de cabecera XLA. |
| p_accounting_status | VARCHAR2(30), opcional, salvo eventos | ACCOUNTING_ENTRY_STATUS_CODE. |
| p_transfer_status | VARCHAR2(30), opcional, salvo eventos | GL_TRANSFER_STATUS_CODE. |
| p_entity_code | VARCHAR2(30), opcional, solo eventos | Clase de entidad de la aplicación. |
| p_transaction_number | VARCHAR2(240), opcional, solo eventos | Número de transacción; no se presume único. |
| p_event_status, p_process_status | VARCHAR2(1), opcionales, solo eventos | Estados originales del evento y su procesamiento. |
| p_fecha_desde, p_fecha_hasta | VARCHAR2(10), opcionales | YYYY-MM-DD; días inclusivos. EVENT_DATE en eventos y ACCOUNTING_DATE en los demás. |

El libro de una entidad puede diferir del libro contable de una cabecera, por ejemplo con libros secundarios. Por eso no se igualan esos dos campos.

## Ejecución

Ejemplo SQL*Plus / SQLcl con identificadores ficticios; reemplazar aplicación y libro por los del entorno. En SQL Developer utilizar Ejecutar script.

~~~sql
VARIABLE p_application_id NUMBER
VARIABLE p_ledger_id NUMBER
VARIABLE p_entity_id NUMBER
VARIABLE p_event_id NUMBER
VARIABLE p_ae_header_id NUMBER
VARIABLE p_period_name VARCHAR2(15)
VARIABLE p_accounting_status VARCHAR2(30)
VARIABLE p_transfer_status VARCHAR2(30)
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_application_id := 200;
EXEC :p_ledger_id := 101;
EXEC :p_entity_id := NULL;
EXEC :p_event_id := NULL;
EXEC :p_ae_header_id := NULL;
EXEC :p_period_name := NULL;
EXEC :p_accounting_status := NULL;
EXEC :p_transfer_status := NULL;
EXEC :p_fecha_desde := '2026-10-01';
EXEC :p_fecha_hasta := '2026-10-31';

@consultas/XLA/asientos_detalle.sql
~~~

Las mismas variables sirven para distribuciones_origen.sql y trazabilidad_gl.sql. En asientos_detalle.sql, el slash ejecuta la primera consulta sin punto y coma previo; la segunda termina con punto y coma.

Para eventos, declarar adicionalmente las siguientes variables y reutilizar p_application_id, p_entity_id, p_event_id y las fechas del ejemplo:

~~~sql
VARIABLE p_entity_ledger_id NUMBER
VARIABLE p_entity_code VARCHAR2(30)
VARIABLE p_transaction_number VARCHAR2(240)
VARIABLE p_event_status VARCHAR2(1)
VARIABLE p_process_status VARCHAR2(1)

EXEC :p_entity_ledger_id := NULL;
EXEC :p_entity_code := NULL;
EXEC :p_transaction_number := NULL;
EXEC :p_event_status := NULL;
EXEC :p_process_status := NULL;

@consultas/XLA/eventos_contables.sql
~~~

## Interpretación

- APPLICATION_ID forma parte de las relaciones de entidades, eventos, cabeceras, líneas y distribuciones. Un identificador numérico aislado no basta.
- SOURCE_ID_* y SOURCE_DISTRIBUTION_ID_* se interpretan según aplicación, entidad y tipo de distribución. No se presupone que el primer identificador sea una factura o una distribución AP.
- Una línea puede tener varios vínculos de distribución. Sus importes contables aparecen repetidos; los importes UNROUNDED_* corresponden al detalle sin redondear. No sumar los importes de línea en ese resultado.
- La relación con GL utiliza GL_SL_LINK_ID y GL_SL_LINK_TABLE conjuntamente. Una línea resumida GL puede recibir varias líneas XLA; no sumar repetidamente sus importes.
- GL_IMPORT_REFERENCES depende de la opción Import Journal References del origen y de que las referencias se conserven. Su ausencia por sí sola no demuestra falta de transferencia.
- El estado de transferencia XLA no confirma contabilización en GL: revisar también estado y fecha del asiento GL.
- No mezclar monedas ni tipos de saldo al sumar. Las consultas son de detalle y no constituyen por sí solas una conciliación de saldos.
- Los estados se muestran sin traducciones ni interpretaciones universales. Los filtros opcionales amplios pueden devolver mucho detalle: acotar fechas, evento o cabecera.

## Referencias y validación

Estructuras contrastadas con metadatos Oracle eTRM archivados: [entidades](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd662-2.html), [eventos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavfa2e-2.html), [cabeceras](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav095c-2.html), [líneas](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav0275-2.html), [distribuciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd003.html) y [referencias GL](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav2488.html).

La revisión local usa datos ficticios y adaptación de las relaciones a SQLite. No equivale a compilación ni ejecución nativa en Oracle. Pendiente validar los scripts en la instancia EBS y nivel de parches donde se utilizarán.

## Trazabilidad entre módulos

La [guía de trazabilidad](trazabilidad_modulos.md) documenta compras→AP, pedidos→AR y activos→depreciación, y explica cómo continuar hasta GL sin duplicar importes.

Nuevos puntos de entrada: [factura AP](ap_factura_xla.sql), [transacción AR](ar_transaccion_xla.sql) y [depreciación FA](fa_depreciacion_xla.sql). **Sus parámetros son específicos** y se describen en sus cabeceras y en la guía; la tabla anterior corresponde a los cuatro scripts originales.
