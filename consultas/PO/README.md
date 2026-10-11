# PO — Compras

Consultas técnicas para **Oracle Purchasing (PO), Oracle EBS R12 en adelante**.

| Archivo | Contenido |
| --- | --- |
| [ordenes_compra.sql](ordenes_compra.sql) | Tres resultados: cabecera; cabecera y líneas; cabecera, líneas, envíos y distribuciones. |
| [requisiciones.sql](requisiciones.sql) | Cabecera; cabecera y líneas; cabecera, líneas y distribuciones. |
| [requisiciones_ordenes_compra.sql](requisiciones_ordenes_compra.sql) | Trazabilidad por distribución desde la requisición hasta la orden, envío y liberación. |
| [configuracion_compras.sql](configuracion_compras.sql) | Sitios de proveedor, compradores, tipos de línea y tipos de documento. |

Los proveedores son compartidos con AP. Para contactos, cuentas bancarias y configuración completa de pagos, utiliza [proveedores_configuracion.sql](../AP/proveedores_configuracion.sql), con sus [parámetros de ejecución](../AP/README.md#proveedores-y-configuración).

## Convenciones y ejecución

Cabecera con autor, versión e historial; comentarios en español; tablas separadas por comas, relaciones por igualdad en `WHERE` y externas con `(+)`. Se consultan tablas base y traducciones con idioma explícito, sin depender de vistas que apliquen el contexto de sesión.

Declara todas las variables. `NULL` omite un filtro opcional. `p_org_id` identifica la unidad operativa, no la organización de inventario ni el libro. `p_language` es el código EBS instalado, por ejemplo `US`. Las traducciones ausentes no eliminan los registros principales.

Ejecuta el archivo completo en modo script: cada `/` ejecuta el SELECT anterior, sin `;` previo; la última consulta termina con `;`.

## Órdenes de compra

Incluye documentos `STANDARD`, `PLANNED`, `BLANKET` y `CONTRACT`, también cerrados o cancelados. Las cotizaciones y solicitudes de cotización quedan fuera de este script. Se consulta la revisión actual, no el histórico de revisiones.

Los parámetros obligatorios son `p_org_id` y `p_language`. Los opcionales son `p_po_header_id`, `p_po_number`, `p_vendor_id`, `p_type_lookup_code`, `p_fecha_desde` y `p_fecha_hasta`. El número comercial puede repetirse entre tipos/organizaciones; para un documento concreto usa `PO_HEADER_ID`.

Ejemplo desde la raíz del repositorio, con valores ficticios:

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_po_header_id NUMBER
VARIABLE p_po_number VARCHAR2(20)
VARIABLE p_vendor_id NUMBER
VARIABLE p_type_lookup_code VARCHAR2(25)
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_org_id := 204;
EXEC :p_language := 'US';
EXEC :p_po_header_id := NULL;
EXEC :p_po_number := '10001';
EXEC :p_vendor_id := NULL;
EXEC :p_type_lookup_code := 'STANDARD';
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;

@consultas/PO/ordenes_compra.sql
```

Las fechas se introducen como texto `YYYY-MM-DD`, incluyen ambos días y filtran `CREATION_DATE` de la cabecera. No filtran las fechas de envío, promesa o liberación. Los tres resultados usan los mismos filtros.

El tercer resultado relaciona cada distribución con **su envío, línea, cabecera y organización**. Muestra la liberación cuando existe. Conserva cabeceras sin líneas, líneas sin envíos y envíos sin distribuciones, con campos de detalle `NULL`.

Las cantidades/importes de línea y envío se repiten en el detalle. No deben sumarse como si pertenecieran a cada distribución. Los campos `AMOUNT` se muestran tal como están registrados; en compras basadas en cantidad pueden ser `NULL`. El script no calcula un total universal de la orden, impuestos ni saldo pendiente.

Las cantidades recibidas/facturadas son acumulados registrados, no el historial de recepción. Las cuentas de cargo, provisión, variación y presupuesto se muestran por sus identificadores.

## Configuración de compras

Son obligatorios `p_org_id`, `p_language` y `p_fecha_consulta` (texto `YYYY-MM-DD`). Esta fecha selecciona la versión del nombre del comprador en HR; no filtra documentos ni excluye compradores inactivos.

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_fecha_consulta VARCHAR2(10)
VARIABLE p_vendor_id NUMBER
VARIABLE p_agent_id NUMBER
VARIABLE p_line_type_id NUMBER

EXEC :p_org_id := 204;
EXEC :p_language := 'US';
EXEC :p_fecha_consulta := '2026-10-10';
EXEC :p_vendor_id := NULL;
EXEC :p_agent_id := NULL;
EXEC :p_line_type_id := NULL;

@consultas/PO/configuracion_compras.sql
```

| Resultado | Alcance de los filtros |
| --- | --- |
| Sitios de proveedor | Unidad operativa obligatoria y proveedor opcional. Incluye todos los sitios para revisar sus indicadores de compras/pagos. |
| Compradores | Catálogo global; comprador opcional y nombre HR vigente en la fecha indicada. Conserva compradores sin nombre vigente. |
| Tipos de línea | Catálogo global, traducción por idioma y tipo de línea opcional; incluye registros inactivos. |
| Tipos de documento | Unidad operativa e idioma explícitos; muestra opciones de aprobación, sin reconstruir jerarquías ni flujos. |

No se interpreta el catálogo de compradores como autorización de compra para una OU. La consulta requiere acceso a `PER_ALL_PEOPLE_F` para los nombres y a los demás objetos referenciados.

## Requisiciones y origen de las órdenes

`requisiciones.sql` devuelve tres resultados con los mismos filtros: cabecera; cabecera y líneas; cabecera, líneas y distribuciones. Conserva cabeceras sin líneas y líneas sin distribuciones. Incluye requisiciones de compra e internas, también cerradas o canceladas.

`requisiciones_ordenes_compra.sql` devuelve **una fila por distribución de compra vinculada**. Sigue esta relación:

```text
PO_REQUISITION_HEADERS_ALL.REQUISITION_HEADER_ID
  -> PO_REQUISITION_LINES_ALL.REQUISITION_HEADER_ID
     -> PO_REQ_DISTRIBUTIONS_ALL.REQUISITION_LINE_ID
        DISTRIBUTION_ID = PO_DISTRIBUTIONS_ALL.REQ_DISTRIBUTION_ID
          -> PO_HEADERS_ALL / PO_LINES_ALL / PO_LINE_LOCATIONS_ALL
             -> PO_RELEASES_ALL (cuando corresponde)
```

Una requisición puede abastecer varias órdenes, y una orden puede agrupar varias requisiciones. No se enlazan los números comerciales ni las referencias textuales de requisiciones en papel. El vínculo no demuestra por sí solo que la compra siga vigente: se muestran sus estados y cancelaciones.

El segundo archivo solo devuelve relaciones existentes; las requisiciones sin compra asociada se consultan en el primero. Las requisiciones internas que siguen el flujo de órdenes internas de OM no se trazan a OM aquí. Se muestra `PARENT_REQ_LINE_ID` para ayudar a revisar líneas divididas, sin reconstruir todo su árbol.

En ambos archivos, `p_org_id` es obligatorio e identifica **la unidad operativa de la requisición**. Se conserva la organización registrada de la compra por separado. Las fechas opcionales filtran la creación de la cabecera de requisición, con días inclusivos; no la fecha de compra. No requieren `p_language`: muestran códigos y textos registrados sin consultar traducciones.

Ejemplo con valores ficticios; ejecutar desde la raíz del repositorio:

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_req_header_id NUMBER
VARIABLE p_req_number VARCHAR2(20)
VARIABLE p_tipo_requisicion VARCHAR2(25)
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)
VARIABLE p_po_header_id NUMBER
VARIABLE p_po_number VARCHAR2(20)

EXEC :p_org_id := 204;
EXEC :p_req_header_id := NULL;
EXEC :p_req_number := '10001';
EXEC :p_tipo_requisicion := 'PURCHASE';
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;
EXEC :p_po_header_id := NULL;
EXEC :p_po_number := NULL;

@consultas/PO/requisiciones.sql
@consultas/PO/requisiciones_ordenes_compra.sql
```

`p_tipo_requisicion` acepta `PURCHASE`, `INTERNAL` o `NULL` para no filtrar. Los parámetros `p_po_header_id` y `p_po_number` se usan únicamente en el segundo archivo. Para buscar desde una orden, deja los filtros de requisición opcionales en `NULL` e indica su `p_po_header_id`; conserva la OU de origen en `p_org_id`.

Las cantidades/importes de requisición se repiten si tienen varias distribuciones de compra asociadas: no sumarlos directamente. Los precios e importes funcionales se distinguen de los campos de moneda extranjera; los importes pueden ser `NULL` para líneas por cantidad. No se calcula un saldo pendiente universal ni se mezclan unidades o monedas. Las cuentas contables se muestran por ID.

Referencias de Oracle eTRM archivado: [cabeceras de requisición](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavb318.html), [líneas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav2f74-2.html), [distribuciones de requisición](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav893b.html) y [vínculo desde las distribuciones de compra](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav2ce5-2.html).

Estos dos archivos pasaron 27 comprobaciones de lógica sobre cuatro consultas, con datos ficticios y adaptación temporal a SQLite: niveles sin detalle, divisiones entre órdenes, envíos compartidos, liberaciones y filtros. **Pendiente ejecución nativa en Oracle EBS.**

## Referencias y validación

Oracle eTRM, copias archivadas: [cabeceras](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavf46c-2.html), [líneas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav5ede.html), [envíos](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavb5d8-2.html), [distribuciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav2ce5-2.html), [compradores](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav110b.html) y [tipos de documento](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav5a6a-2.html).

La revisión conjunta de `ordenes_compra.sql`, `configuracion_compras.sql` y [pagos AP](../AP/pagos.sql) pasó 41 comprobaciones de lógica sobre diez consultas con datos ficticios y adaptación temporal a SQLite. **Pendiente ejecución nativa en Oracle EBS** y verificación por versión/parches. En R12.2 se mantienen los sinónimos estándar y su resolución a vistas de edición internas.

[Volver al inicio](../../README.md)
