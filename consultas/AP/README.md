# AP — Cuentas por pagar

Consultas técnicas para **Oracle Payables (AP), Oracle EBS R12 en adelante**: facturas, proveedores y configuración asociada de TCA y Oracle Payments.

| Archivo | Resultados |
| --- | --- |
| [facturas.sql](facturas.sql) | Tres consultas: cabecera; cabecera y líneas; cabecera, líneas y distribuciones. |
| [pagos.sql](pagos.sql) | Tres consultas: pago, aplicaciones a facturas/cuotas e historial. |
| [proveedores_configuracion.sql](proveedores_configuracion.sql) | Cinco consultas: proveedor; sitios; contactos y medios TCA; cuentas bancarias; métodos de pago. |

## Convenciones

Cabecera con autor, versión e historial; comentarios en español; tablas separadas por comas y uniones por igualdad en `WHERE`, con `(+)` para relaciones opcionales. Se utilizan tablas base y traducciones explícitas, sin vistas que seleccionen datos por idioma u organización de la sesión.

Declara todas las variables, incluidas las opcionales. `NULL` omite un filtro opcional. Los identificadores son `NUMBER`; los números comerciales de proveedor y factura son texto y se comparan exactamente. `p_language` es el código EBS instalado, por ejemplo `US`. Una traducción ausente deja su descripción en `NULL`, sin eliminar la fila principal.

Ejecuta cada archivo en modo script. El separador `/` ejecuta la consulta anterior; no se añade `;` antes de él para evitar ejecutar dos veces ese resultado en SQL*Plus. La última consulta termina en `;`.

## Facturas

Los tres resultados aplican los mismos filtros de cabecera. `p_org_id` es obligatorio y representa la **unidad operativa**, no el libro contable. También es obligatorio `p_language`.

Los filtros opcionales son `p_invoice_id`, `p_invoice_num`, `p_vendor_id`, `p_fecha_desde` y `p_fecha_hasta`. Las fechas son cadenas `YYYY-MM-DD`, filtran `INVOICE_DATE` e incluyen completos los días inicial y final. Indica un rango ordenado; un rango invertido no devuelve filas.

Ejemplo desde la raíz del repositorio, con valores ficticios:

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_invoice_id NUMBER
VARIABLE p_invoice_num VARCHAR2(50)
VARIABLE p_vendor_id NUMBER
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_org_id := 204;
EXEC :p_language := 'US';
EXEC :p_invoice_id := NULL;
EXEC :p_invoice_num := 'FACTURA-001';
EXEC :p_vendor_id := 12345;
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;

@consultas/AP/facturas.sql
```

La cabecera aporta proveedor, sitio, monedas, importes, condiciones de pago, fechas, cuenta de pasivo e indicadores. Las líneas añaden cantidades, precios y referencias a compras/recepciones. Las distribuciones añaden cuenta contable, período, importes, indicadores de contabilización/reversión y referencias de proyecto.

Las cabeceras sin líneas y las líneas sin distribuciones se conservan con detalle `NULL`. Las distribuciones se relacionan por factura **y número de línea**. Se incluyen cancelaciones, líneas descartadas y reversiones para su análisis.

**No sumes los importes repetidos de cabecera en los resultados de detalle ni los de línea en el resultado por distribución.** Agrega cada importe en su nivel y moneda. Los indicadores mostrados no equivalen a una reconstrucción del estado completo de validación, del saldo pendiente ni de los asientos SLA/GL. Las cuentas se muestran por su identificador `CCID`.

## Proveedores y configuración

`p_language` es obligatorio. `p_vendor_id`, `p_vendor_num` y `p_org_id` son opcionales; si se indican tanto ID como número, ambos deben coincidir. Sin filtros de proveedor se consultan todos.

```sql
VARIABLE p_language VARCHAR2(4)
VARIABLE p_vendor_id NUMBER
VARIABLE p_vendor_num VARCHAR2(30)
VARIABLE p_org_id NUMBER

EXEC :p_language := 'US';
EXEC :p_vendor_id := 12345;
EXEC :p_vendor_num := NULL;
EXEC :p_org_id := 204;

@consultas/AP/proveedores_configuracion.sql
```

| Resultado | Alcance |
| --- | --- |
| Proveedor | Registro global, vigencias, monedas, condiciones y bloqueos de pago, retenciones e identificación fiscal. No se filtra por organización. |
| Sitios | Una fila por sitio de la unidad operativa indicada; dirección, compras/pagos, bloqueos, cuentas contables y conjunto de distribución. |
| Contactos | Contactos AP vinculados mediante TCA o sitio AP antiguo. Una fila por contacto y medio de su relación TCA; conserva contactos sin medios. |
| Cuentas bancarias | Beneficiarios de pagos AP y sus asignaciones a cuentas externas en IBY, banco/sucursal, preferencia y vigencias. Conserva beneficiarios sin cuenta. |
| Métodos de pago | Métodos registrados por beneficiario, principal, baja y configuración del aviso de remesa. |

Con `p_org_id` informado, los detalles excluyen sitios de otras unidades operativas, pero conservan contactos y beneficiarios globales. Las direcciones TCA se incluyen cuando tienen un sitio AP en la organización indicada. Con `p_org_id = NULL` se incluyen todas las organizaciones. Este parámetro es un filtro de consulta, no una validación de autorizaciones MOAC.

Se incluyen registros inactivos y fechas de vigencia para diagnóstico. En contactos, los campos AP y los medios de `HZ_CONTACT_POINTS` se muestran por separado; estos últimos corresponden a `REL_PARTY_ID`, no a todas las relaciones de la persona.

Los números bancarios e IBAN se presentan mediante los campos enmascarados de Oracle Payments. Se muestra el nivel de configuración: proveedor, organización, dirección TCA o sitio AP. **La consulta no calcula la herencia ni garantiza cuál cuenta seleccionará el motor de pagos.** Las cuentas pertenecen al beneficiario registrado, no se determina la titularidad legal de cada cuenta. Métodos, contactos y cuentas se consultan por separado para evitar multiplicaciones entre estas listas.

## Pagos

[pagos.sql](pagos.sql) incluye tres consultas independientes:

1. Cabecera del pago, datos guardados del proveedor y referencia opcional al estado de Oracle Payments.
2. Aplicaciones a facturas y cuotas de vencimiento, importes, descuentos, indicadores contables y reversiones.
3. Historial de eventos registrados del pago, con referencias contables y montos por moneda.

El parámetro obligatorio es `p_org_id`, la unidad operativa del **pago**. Son opcionales `p_check_id`, `p_check_number`, `p_vendor_id`, `p_fecha_desde` y `p_fecha_hasta`. Todos los identificadores y el número de pago son `NUMBER`; las fechas son texto `YYYY-MM-DD` e incluyen completos ambos días sobre `CHECK_DATE`. No se necesita idioma porque se muestran códigos y nombres almacenados.

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_check_id NUMBER
VARIABLE p_check_number NUMBER
VARIABLE p_vendor_id NUMBER
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_org_id := 204;
EXEC :p_check_id := 12345;
EXEC :p_check_number := NULL;
EXEC :p_vendor_id := NULL;
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;

@consultas/AP/pagos.sql
```

`AP_CHECKS_ALL` comprende cheques, pagos electrónicos y reembolsos. `CHECK_NUMBER` no identifica de manera única un pago: utiliza `CHECK_ID` para uno concreto. Un rango de fechas invertido no devuelve filas.

Se conservan pagos sin aplicaciones, sin historia o sin registro IBY asociado. El detalle de facturas se vincula a su cuota mediante `INVOICE_ID` y `PAYMENT_NUM`. Las organizaciones de aplicación y factura se muestran por separado y no se fuerzan a coincidir con la del pago, para conservar las relaciones registradas en pagos centralizados.

Los pagos anulados y las aplicaciones de reversión se muestran con su signo e identificadores. **No sumes `importe_pago` repetido en los detalles ni uses valores absolutos para netear reversiones.** El historial se consulta separado de las aplicaciones para evitar multiplicaciones. Los importes base, del pago y de la factura se muestran por separado; no deben mezclarse entre monedas. `saldo_actual_cuota` es el saldo vigente al consultar, no el saldo histórico después de esa aplicación, y puede repetirse en varias aplicaciones.

No se reconstruyen los asientos SLA/GL ni todos los movimientos del extracto bancario. El filtro de OU no valida autorizaciones MOAC. No se publican números bancarios completos en el resultado.

Referencias Oracle eTRM (copias archivadas): [pagos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav34dd.html), [aplicaciones a facturas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav2024.html), [cuotas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavbf96.html) e [historial](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd231.html).

La revisión conjunta con los nuevos scripts PO pasó 41 comprobaciones de lógica sobre diez consultas mediante datos ficticios y adaptación a SQLite. Pendiente ejecución nativa Oracle EBS.

## Referencias y validación

Estructuras contrastadas con Oracle eTRM (copias archivadas):

- [Cabeceras de factura](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav6139.html), [líneas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav50aa.html) y [distribuciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav1a08.html).
- [Proveedores](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav14e6.html), [sitios](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavc96b.html) y [contactos AP](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavfb7c.html?c_name=AP_SUPPLIER_CONTACTS&c_owner=AP&c_type=TABLE).
- [Tablas de Oracle Payments](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/IBY_Tables3e06.html) y [medios de contacto TCA](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav87af.html?c_name=HZ_CONTACT_POINTS).

Se comprobaron ocho consultas mediante 28 verificaciones de lógica con datos ficticios y adaptación temporal a SQLite: granularidad, filtros, fechas, traducciones ausentes, contactos y niveles de asignación bancaria. **Pendiente ejecución nativa en Oracle EBS** y comprobación de permisos/objetos según versión y parches. En R12.2 se mantienen los sinónimos estándar y su resolución a vistas internas de edición.

[Volver al inicio](../../README.md)
