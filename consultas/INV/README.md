# INV — Inventory

Oracle Inventory (INV) gestiona artículos por organización, subinventarios, localizadores, existencias y transacciones de material.

Consultas de lectura para Oracle EBS R12, orientadas a R12.1 y R12.2. Se mantienen comentarios en español, cabecera con autor y versión, alias por iniciales, relaciones por igualdad y uniones externas (+). Se utilizan tablas base y parámetros explícitos, sin vistas funcionales ni contexto de sesión.

## Contenido

| Archivo | Consultas |
| --- | --- |
| [articulos.sql](articulos.sql) | Artículos por organización, descripción por idioma y controles de inventario. |
| [existencias.sql](existencias.sql) | Detalle de registros de existencias y resumen con los mismos filtros. |
| [movimientos.sql](movimientos.sql) | Transacciones de material y un segundo resultado con sus lotes. |
| [configuracion_inv.sql](configuracion_inv.sql) | Organizaciones de inventario, subinventarios y localizadores. |

## Organización y claves

El parámetro p_organization_id es el identificador de la **organización de inventario**. No debe confundirse con el ORG_ID de una unidad operativa utilizado en AP, AR u ONT.

El artículo se identifica por INVENTORY_ITEM_ID y ORGANIZATION_ID. Las traducciones añaden LANGUAGE a esa clave. Las relaciones conservan esos componentes para evitar que un artículo de otra organización altere los resultados.

Los códigos de artículo y localizador son flexfields configurables. Se muestran SEGMENT1 a SEGMENT20 sin asumir una estructura o un separador. El filtro p_segment1 afecta únicamente al primer segmento del artículo; no representa necesariamente su código completo.

## Parámetros

Declarar todas las variables del archivo, incluidas las opcionales. NULL omite un filtro opcional. Las comparaciones de texto son exactas.

| Parámetro | Tipo | Archivos y uso |
| --- | --- | --- |
| p_organization_id | NUMBER | Obligatorio en artículos, existencias, movimientos, subinventarios y localizadores. Opcional en el listado de organizaciones. |
| p_inventory_item_id | NUMBER, opcional | Artículos, existencias y movimientos. |
| p_language | VARCHAR2(4), obligatorio | Solo artículos: código de idioma EBS, por ejemplo US. |
| p_segment1 | VARCHAR2(40), opcional | Solo artículos: primer segmento. |
| p_inventory_item_status_code | VARCHAR2(10), opcional | Solo artículos: estado registrado. |
| p_subinventory_code | VARCHAR2(10), opcional | Existencias, movimientos, subinventarios y localizadores. |
| p_locator_id | NUMBER, opcional | Existencias y localizadores. |
| p_lot_number | VARCHAR2(80), opcional | Solo existencias. |
| p_is_consigned | NUMBER, opcional | Solo existencias: 1 consignado, 2 no consignado. |
| p_transaction_id | NUMBER, opcional | Solo movimientos. |
| p_transaction_type_id | NUMBER, opcional | Solo movimientos. |
| p_fecha_desde, p_fecha_hasta | VARCHAR2(10), opcionales | Solo movimientos: YYYY-MM-DD sobre TRANSACTION_DATE, días inclusivos. |

Los filtros opcionales no permiten seleccionar exclusivamente valores NULL; NULL significa no aplicar la restricción. Las existencias muestran el estado actual y no reciben fecha de corte.

## Ejemplos

Ejecutar desde la raíz del repositorio mediante SQL*Plus, SQLcl o Ejecutar script de SQL Developer. Los identificadores son ficticios; reemplazarlos por valores del entorno.

Primero se pueden descubrir las organizaciones disponibles:

~~~sql
VARIABLE p_organization_id NUMBER
VARIABLE p_subinventory_code VARCHAR2(10)
VARIABLE p_locator_id NUMBER

EXEC :p_organization_id := NULL;
EXEC :p_subinventory_code := NULL;
EXEC :p_locator_id := NULL;

@consultas/INV/configuracion_inv.sql
~~~

Con p_organization_id en NULL, la primera consulta lista organizaciones y las otras dos no devuelven filas. Para consultar también subinventarios y localizadores:

~~~sql
EXEC :p_organization_id := 101;
@consultas/INV/configuracion_inv.sql
~~~

Artículos:

~~~sql
VARIABLE p_inventory_item_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_segment1 VARCHAR2(40)
VARIABLE p_inventory_item_status_code VARCHAR2(10)

EXEC :p_inventory_item_id := NULL;
EXEC :p_language := 'US';
EXEC :p_segment1 := NULL;
EXEC :p_inventory_item_status_code := NULL;

@consultas/INV/articulos.sql
~~~

Existencias, reutilizando organización, artículo, subinventario y localizador:

~~~sql
VARIABLE p_lot_number VARCHAR2(80)
VARIABLE p_is_consigned NUMBER

EXEC :p_lot_number := NULL;
EXEC :p_is_consigned := NULL;

@consultas/INV/existencias.sql
~~~

Movimientos:

~~~sql
VARIABLE p_transaction_id NUMBER
VARIABLE p_transaction_type_id NUMBER
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_transaction_id := NULL;
EXEC :p_transaction_type_id := NULL;
EXEC :p_fecha_desde := '2026-10-01';
EXEC :p_fecha_hasta := '2026-10-31';

@consultas/INV/movimientos.sql
~~~

En archivos con varias consultas, el slash ejecuta el SELECT anterior sin punto y coma previo. La última consulta termina con punto y coma.

## Interpretación

### Artículos y configuración

- Se incluyen artículos y ubicaciones deshabilitados; se muestran los controles y fechas disponibles, sin imponer vigencia por la fecha de sesión.
- Una traducción ausente deja la descripción del artículo en NULL, sin eliminarlo.
- Los estados y controles se entregan con sus valores almacenados. Los nombres de tipo de movimiento se leen directamente de MTL_TRANSACTION_TYPES.
- La organización maestra de artículos y la organización de costos se muestran por separado.
- Se requiere acceso a las tablas y autorización sobre la organización consultada; el filtro SQL no sustituye los controles de acceso del entorno.

### Existencias

- El detalle conserva una fila por ONHAND_QUANTITIES_ID; el resumen suma capas de recepción.
- El resumen conserva artículo, organización, subinventario, localizador, revisión, lote, grupo de costos, proyecto/tarea, propietario, planificación, consignación, LPN, estado y unidades.
- La cantidad primaria usa la unidad primaria del artículo. No se suman cantidades de transacción en unidades diferentes. La cantidad secundaria se agrupa por SECONDARY_UOM_CODE; NULL no se transforma en cero.
- Los identificadores de propietario y planificación deben interpretarse junto con sus tipos de tercero; no se supone que todos sean organizaciones de inventario.
- La existencia registrada no equivale a disponible para reservar, disponible para transaccionar ni ATP. Reservas, estados, restricciones y movimientos pendientes pueden modificar esas cantidades.
- No se calcula valoración monetaria ni un saldo histórico. La suma de movimientos de un período tampoco equivale al saldo actual sin considerar saldo inicial y alcance.
- Detalle y resumen usan los mismos filtros. Para compararlos exactamente, usar una lectura consistente o un momento sin cambios concurrentes; dos SELECT ejecutados separadamente pueden observar saldos distintos.

### Movimientos y lotes

- La primera consulta conserva una fila por TRANSACTION_ID. La segunda muestra sus lotes y conserva transacciones sin lote.
- Las cantidades de MTL_MATERIAL_TRANSACTIONS se repiten por lote. Para agregar el detalle de lotes utilizar las cantidades de MTL_TRANSACTION_LOT_NUMBERS, manteniendo artículo y unidad.
- Se conservan cantidades positivas y negativas. Los traslados pueden producir movimientos relacionados mediante TRANSFER_TRANSACTION_ID; no se interpretan como ingresos externos independientes.
- TRANSACTION_SOURCE_ID y TRX_SOURCE_LINE_ID dependen del tipo de origen; no se enlazan universalmente a un pedido o factura.
- COSTED_FLAG no demuestra contabilización en GL. Este archivo no consulta interfaces pendientes, reservas, números de serie ni distribuciones contables.
- SERIAL_TRANSACTION_ID es la referencia al detalle de series de un movimiento con lote; no es el número de serie.

## Referencias y validación

Estructuras contrastadas con metadatos Oracle eTRM archivados:

- [Artículos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav27af.html) y [traducciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav1358-2.html).
- [Existencias](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav316c.html).
- [Movimientos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav57ab.html?c_name=MTL_MATERIAL_TRANSACTIONS&c_owner=INV&c_type=TABLE), [lotes](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav0b8d.html) y [tipos de transacción](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav8487.html).
- [Parámetros de organización](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav7b39.html), [subinventarios](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav4793.html) y [localizadores](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav2e96.html).

Se realizaron 49 comprobaciones con datos ficticios y adaptación de las relaciones a SQLite: aislamiento de organizaciones, traducciones ausentes, unidades, consignación, resumen de capas, cantidades negativas y lotes. No equivale a ejecución nativa en Oracle; validar en la versión y nivel de parches de la instancia EBS.
