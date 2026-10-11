# CE — Cash Management

Consultas técnicas de gestión de efectivo y conciliación bancaria para **Oracle EBS R12 en adelante**, con enfoque en R12.1 y R12.2.

| Archivo | Contenido |
| --- | --- |
| [cuentas_bancarias.sql](cuentas_bancarias.sql) | Dos consultas: cuentas bancarias internas con banco/sucursal; usos de las cuentas por organización. |
| [extractos_bancarios.sql](extractos_bancarios.sql) | Dos consultas: cabecera del extracto; cabecera y líneas. |
| [conciliacion_bancaria.sql](conciliacion_bancaria.sql) | Historial de conciliación, estados e identificadores de las transacciones relacionadas. |

Cabeceras con autor **Freddy E. Aparicio M.**, fecha **11/10/2026** y versión **1.0**. Comentarios en español, tablas separadas por comas, relaciones en WHERE y uniones externas con (+). No se usan vistas funcionales ni organización/idioma de sesión. Los estados se muestran con sus códigos originales; no se necesita parámetro de idioma. En R12.2 se conservan los sinónimos APPS y su resolución interna a vistas de edición.

## Cuentas y usos por organización

La primera consulta devuelve una fila por cuenta, incluso si no tiene usos o no se encuentra su banco/sucursal en HZ_PARTIES. La segunda muestra únicamente usos registrados; una cuenta puede aparecer varias veces.

Los filtros son opcionales: p_bank_account_id, p_bank_id y p_owner_org_id aplican a ambas consultas; **p_org_id solo aplica a la segunda**. Todos son NUMBER y NULL omite el filtro. ACCOUNT_OWNER_ORG_ID identifica la organización propietaria registrada en la cuenta y no debe confundirse con la OU del uso.

~~~sql
VARIABLE p_bank_account_id NUMBER
VARIABLE p_bank_id NUMBER
VARIABLE p_owner_org_id NUMBER
VARIABLE p_org_id NUMBER

EXEC :p_bank_account_id := NULL;
EXEC :p_bank_id := NULL;
EXEC :p_owner_org_id := NULL;
EXEC :p_org_id := 204;

@consultas/CE/cuentas_bancarias.sql
~~~

Los valores del ejemplo son ficticios. Incluye registros inactivos para revisar fechas e indicadores; no aplica un filtro de vigencia automático. Muestra los campos enmascarados de cuenta e IBAN, que pueden ser NULL según la configuración. Las cuentas contables aparecen por ID.

Estas son cuentas internas de CE. Las cuentas externas de proveedores están documentadas en [AP](../AP/README.md). Consultar tablas base no reproduce los permisos de una responsabilidad de EBS.

## Extractos

p_bank_account_id es **obligatorio**. Los demás parámetros son opcionales:

~~~sql
VARIABLE p_bank_account_id NUMBER
VARIABLE p_statement_header_id NUMBER
VARIABLE p_statement_number VARCHAR2(50)
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_bank_account_id := 1001;
EXEC :p_statement_header_id := NULL;
EXEC :p_statement_number := NULL;
EXEC :p_fecha_desde := '2026-10-01';
EXEC :p_fecha_hasta := '2026-10-31';

@consultas/CE/extractos_bancarios.sql
~~~

Las fechas incluyen ambos días y filtran **STATEMENT_DATE**, no TRX_DATE, GL_DATE ni la fecha de conciliación. El número de extracto se busca dentro de la cuenta indicada. Una cuenta obligatoria NULL no devuelve filas.

CE_STATEMENT_HEADERS y CE_STATEMENT_LINES son tablas base, aunque sus nombres no terminen en ALL. El ORG_ID de cabecera está marcado como obsoleto en el eTRM de R12; no se emplea para filtrar. Tampoco se enlaza el extracto con cada uso por OU, para evitar multiplicar sus líneas.

La segunda consulta conserva cabeceras sin líneas. Los controles de cabecera se repiten por cada línea: no deben sumarse en ese resultado. Los importes originales y sus monedas se muestran separados. No se infiere el signo de cada tipo de transacción ni se calcula una conciliación contra GL_BALANCES. Un extracto marcado como completo no equivale por sí solo a demostrar que todo está conciliado.

## Historial y conciliaciones vigentes

Declara los parámetros anteriores y añade:

~~~sql
VARIABLE p_statement_line_id NUMBER
VARIABLE p_org_id NUMBER
VARIABLE p_reference_type VARCHAR2(30)
VARIABLE p_current_record_flag VARCHAR2(1)
VARIABLE p_status_flag VARCHAR2(1)

EXEC :p_statement_line_id := NULL;
EXEC :p_org_id := NULL;
EXEC :p_reference_type := NULL;
EXEC :p_current_record_flag := NULL;
EXEC :p_status_flag := NULL;

@consultas/CE/conciliacion_bancaria.sql

-- Coincidencias vigentes: ambos filtros son necesarios.
EXEC :p_current_record_flag := 'Y';
EXEC :p_status_flag := 'M';

@consultas/CE/conciliacion_bancaria.sql
~~~

Con los filtros de estado en NULL se muestran las acciones históricas. CURRENT_RECORD_FLAG indica vigencia del registro; STATUS_FLAG distingue coincidencia (M) y desconciliación (U). No se calcula el saldo pendiente sumando este historial.

La consulta devuelve solo líneas con acciones registradas; las líneas sin historial se consultan en extractos_bancarios.sql. No utiliza DISTINCT: varias acciones o referencias para una misma línea pueden ser legítimas. El importe de la línea se repite en ese detalle.

p_org_id filtra la organización registrada en la conciliación, no la propietaria de la cuenta. Con NULL se conservan también referencias sin organización. El filtro puede limitar el resultado a una parte de una cuenta compartida.

| REFERENCE_TYPE | Interpretación de REFERENCE_ID |
| --- | --- |
| PAYMENT | CHECK_ID de AP_CHECKS_ALL. |
| RECEIPT | CASH_RECEIPT_HISTORY_ID de AR_CASH_RECEIPT_HISTORY_ALL; no es CASH_RECEIPT_ID. |
| JE_LINE | JE_LINE_NUM de GL_JE_LINES, junto con JE_HEADER_ID. |
| STATEMENT | STATEMENT_LINE_ID de otra línea de extracto. |

Se mantienen otros tipos con sus identificadores originales. El script no intenta resolver todas las fuentes ni enlazar IDs de distintos tipos como si fueran equivalentes. Para pagos identificados, utiliza [pagos AP](../AP/pagos.sql).

## Ejecución y validación

Declara todos los binds del archivo elegido, incluidos los opcionales. Ejecuta en modo script: cada slash ejecuta el SELECT anterior, que no lleva punto y coma; el último SELECT termina con punto y coma.

Se realizaron **29 comprobaciones sobre cinco consultas**, con datos ficticios y adaptación temporal a SQLite: cuentas con varios usos, metadatos ausentes, extractos sin líneas, límites de fechas, historial de conciliación/desconciliación y filtros por cuenta, organización y tipo. **Pendiente ejecución nativa en Oracle EBS** y validación según parches.

Fuentes: metadatos originales de Oracle eTRM archivados, no los resúmenes automáticos del buscador.

- [Cuentas bancarias](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavcb84.html).
- [Usos por organización](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav8e0c.html?c_name=CE_BANK_ACCT_USES_ALL&c_owner=CE&c_type=TABLE).
- [Cabeceras de extractos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavbb8a.html).
- [Líneas de extractos](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav9285.html).
- [Historial de conciliación](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavaa54.html).

[Volver al inicio](../../README.md)
