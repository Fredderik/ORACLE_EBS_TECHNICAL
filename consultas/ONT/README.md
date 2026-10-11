# ONT — Order Management (OM)

Order Management gestiona pedidos de venta y devoluciones. OM es la abreviatura habitual; **ONT es el nombre corto técnico de la aplicación**, como indica la [documentación de Oracle](https://docs.oracle.com/cd/E18727_01/doc.121/e14322.pdf). Sus principales tablas transaccionales utilizan el prefijo OE_.

Este directorio contiene consultas de lectura para Oracle EBS R12, orientadas a R12.1 y R12.2. Se mantienen cabeceras con autor y versión, comentarios en español, alias por iniciales, relaciones por igualdad y uniones externas (+). No se utilizan vistas funcionales ni valores de idioma u organización obtenidos de la sesión.

## Contenido

| Archivo | Consultas |
| --- | --- |
| [pedidos.sql](pedidos.sql) | Cabeceras con cliente, tipo y origen; cabeceras con líneas, cantidades, precios y estados. |
| [pedidos_despachos.sql](pedidos_despachos.sql) | Líneas OM → detalles WSH → asignaciones → entregas. |
| [pedidos_facturacion.sql](pedidos_facturacion.sql) | Líneas OM → líneas y cabeceras AR mediante atributos de interfaz. |
| [configuracion_ont.sql](configuracion_ont.sql) | Tipos de transacción por unidad operativa e idioma; catálogo global de orígenes. |

WSH corresponde a Shipping Execution y AR a Receivables. Se consultan desde ONT para seguir el pedido. El detalle de despachos y el de facturación se entrega en archivos independientes para evitar multiplicar filas al combinar dos relaciones de uno a muchos.

## Parámetros de pedidos y seguimiento

| Parámetro | Tipo | Uso |
| --- | --- | --- |
| p_org_id | NUMBER, obligatorio | Unidad operativa de la cabecera y líneas OM. |
| p_header_id | NUMBER, opcional | Identificador interno del pedido. |
| p_order_number | NUMBER, opcional | Número de pedido; puede repetirse entre tipos/versiones. |
| p_order_type_id | NUMBER, opcional | Tipo de pedido. |
| p_sold_to_org_id | NUMBER, opcional | Cuenta del cliente, identificada por HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID. |
| p_fecha_desde, p_fecha_hasta | VARCHAR2(10), opcionales | YYYY-MM-DD; filtran ORDERED_DATE de cabecera, con ambos días incluidos. |
| p_language | VARCHAR2(4), obligatorio solo en pedidos.sql | Código de idioma EBS para traducciones de tipos; por ejemplo US. |
| p_line_id | NUMBER, opcional en despachos y facturación | Identificador de la línea OM. |
| p_interface_line_context | VARCHAR2(30), obligatorio solo en facturación | Contexto de interfaz AR; ejemplo estándar ORDER ENTRY. |

NULL omite un filtro opcional. Declarar todas las variables utilizadas por el archivo, incluidas las opcionales. Se requiere acceso a las tablas y autorización para consultar la unidad operativa seleccionada; el filtro no sustituye el control de acceso del entorno.

## Ejemplo de ejecución

Identificadores ficticios: reemplazar la unidad operativa y los filtros por valores del entorno. Ejecutar desde la raíz del repositorio mediante SQL*Plus, SQLcl o Ejecutar script de SQL Developer.

~~~sql
VARIABLE p_org_id NUMBER
VARIABLE p_header_id NUMBER
VARIABLE p_order_number NUMBER
VARIABLE p_order_type_id NUMBER
VARIABLE p_sold_to_org_id NUMBER
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)
VARIABLE p_language VARCHAR2(4)

EXEC :p_org_id := 101;
EXEC :p_header_id := NULL;
EXEC :p_order_number := NULL;
EXEC :p_order_type_id := NULL;
EXEC :p_sold_to_org_id := NULL;
EXEC :p_fecha_desde := '2026-10-01';
EXEC :p_fecha_hasta := '2026-10-31';
EXEC :p_language := 'US';

@consultas/ONT/pedidos.sql
~~~

Para despachos y facturación, reutilizar los parámetros comunes y declarar:

~~~sql
VARIABLE p_line_id NUMBER
VARIABLE p_interface_line_context VARCHAR2(30)

EXEC :p_line_id := NULL;
EXEC :p_interface_line_context := 'ORDER ENTRY';

@consultas/ONT/pedidos_despachos.sql
@consultas/ONT/pedidos_facturacion.sql
~~~

La consulta de despachos no utiliza idioma ni contexto AR. En los archivos con dos consultas, el slash ejecuta el primer SELECT sin punto y coma previo; el segundo termina con punto y coma.

## Configuración

La primera consulta utiliza p_org_id y p_language obligatorios. Filtros opcionales:

- p_transaction_type_id: NUMBER, identificador del tipo.
- p_transaction_type_code: VARCHAR2(30), código del tipo.
- p_fecha_vigencia: VARCHAR2(10), fecha YYYY-MM-DD evaluada por día. NULL incluye también tipos vencidos o futuros.

La segunda consulta muestra orígenes globales. Solo utiliza p_order_source_id (NUMBER) y p_enabled_flag (VARCHAR2(1)); ambos opcionales. No está limitada por los filtros de la primera consulta.

~~~sql
VARIABLE p_org_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_transaction_type_id NUMBER
VARIABLE p_transaction_type_code VARCHAR2(30)
VARIABLE p_fecha_vigencia VARCHAR2(10)
VARIABLE p_order_source_id NUMBER
VARIABLE p_enabled_flag VARCHAR2(1)

EXEC :p_org_id := 101;
EXEC :p_language := 'US';
EXEC :p_transaction_type_id := NULL;
EXEC :p_transaction_type_code := NULL;
EXEC :p_fecha_vigencia := NULL;
EXEC :p_order_source_id := NULL;
EXEC :p_enabled_flag := NULL;

@consultas/ONT/configuracion_ont.sql
~~~

## Interpretación de resultados

- ORG_ID representa la unidad operativa. SOLD_TO_ORG_ID representa una cuenta de cliente; SHIP_TO_ORG_ID e INVOICE_TO_ORG_ID representan usos de sitio del cliente. SHIP_FROM_ORG_ID representa la organización de inventario. No son identificadores intercambiables.
- Pedidos conserva cabeceras sin líneas y registros sin traducción en el idioma solicitado. Los scripts de seguimiento requieren una línea OM, pero conservan líneas sin despacho o vínculo AR.
- Los estados se muestran con sus códigos almacenados. BOOKED_FLAG, FLOW_STATUS_CODE, RELEASED_STATUS, estados de entrega y COMPLETE_FLAG representan etapas diferentes.
- No se calcula un total de pedido a partir de cantidad por precio: las devoluciones, componentes de modelos, impuestos, cargos y unidades de precio requieren reglas adicionales.
- Despachos muestra todas las asignaciones existentes y su ACTIVE_FLAG. Una línea puede tener varios detalles y un detalle varias asignaciones. No sumar las cantidades OM repetidas ni contar varias veces un mismo DELIVERY_DETAIL_ID. Revisar CONTAINER_FLAG y las unidades de medida antes de agregar cantidades.
- La consulta WSH sigue registros de origen OE mediante identificadores internos y unidad operativa. La ausencia de despacho puede ser válida en servicios, devoluciones, ventas con envío directo u otros flujos. No es una consulta de recepciones RMA.
- Facturación presupone que INTERFACE_LINE_ATTRIBUTE6 conserva el LINE_ID de OM, y que AR corresponde a la misma unidad operativa. El contexto se ingresa explícitamente; no se asume que cambiarlo haga compatible cualquier integración.
- El cruce AR convierte el identificador numérico OM a texto; evita convertir atributos ajenos o no numéricos a NUMBER. No usa el número visible de pedido como única clave.
- Facturación incluye líneas AR de tipo LINE, incluidas las de notas de crédito que conserven ese vínculo. No incluye impuestos, fletes, interfaz pendiente de AutoInvoice, cobros ni saldo pendiente. Los importes se muestran en la moneda AR y sin alterar su signo.
- SIN VINCULO AR solo informa ausencia de coincidencia según este mapeo. Revisar flujos pendientes, personalizaciones, intercompañía y referencias eliminadas antes de concluir que existe un error.

## Fuentes y validación

Se contrastaron las estructuras con metadatos Oracle eTRM archivados:

- [Cabeceras OM](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav7eb4-3.html?c_name=OE_ORDER_HEADERS_ALL&c_owner=ONT&c_type=TABLE) y [líneas OM](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav7bb8-2.html).
- [Tipos de transacción](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavc0b2.html), [traducciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav59e2-2.html) y [orígenes](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav47b5.html).
- [Detalles WSH](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd341.html?c_name=WSH_DELIVERY_DETAILS&c_type=TABLE), [asignaciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavaae3-2.html) y [entregas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav83e5.html?c_name=WSH_NEW_DELIVERIES&c_owner=WSH&c_type=TABLE).
- [Relación utilizada por OE_INVOICE_WF con las líneas AR](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav6767-15.html).

Se realizaron 48 comprobaciones con datos ficticios mediante adaptación de las relaciones a SQLite: unidad operativa, fechas, traducciones ausentes, divisiones de despacho, asignaciones, contexto AR y atributos no numéricos. No equivale a ejecución nativa Oracle. Validar en la versión y nivel de parches de la instancia EBS antes de utilizar los resultados.
