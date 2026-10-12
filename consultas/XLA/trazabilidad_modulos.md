# Trazabilidad entre módulos y GL

Autor: Freddy E. Aparicio M. · Versión 1.0 · 12/10/2026.

XLA enlaza los eventos contables de las aplicaciones con GL. Las relaciones comerciales entre documentos deben seguirse primero en el módulo: una orden no comparte necesariamente entidad o evento con su factura, pago o movimiento de inventario.

~~~text
Documento / distribución del módulo
    └── Entidad XLA (aplicación + entidad)
        └── Evento (aplicación + evento)
            └── Cabecera (aplicación + cabecera; libro contable)
                └── Línea (aplicación + cabecera + número de línea)
                    └── Referencia de importación GL
                        └── Línea GL → asiento → lote
~~~

## Entradas ejecutables

| Archivo | Parámetros obligatorios | Granularidad |
| --- | --- | --- |
| [ap_factura_xla.sql](ap_factura_xla.sql) | p_documento_id = INVOICE_ID, p_org_id, p_entity_ledger_id; NUMBER | Factura AP → entidad AP_INVOICES → eventos. |
| [ar_transaccion_xla.sql](ar_transaccion_xla.sql) | p_documento_id = CUSTOMER_TRX_ID, p_org_id, p_entity_ledger_id; NUMBER | Transacción AR → entidad TRANSACTIONS → eventos. |
| [fa_depreciacion_xla.sql](fa_depreciacion_xla.sql) | p_asset_id NUMBER, p_book_type_code VARCHAR2, p_period_counter NUMBER, p_ledger_id NUMBER | Resumen de depreciación → cabeceras XLA del libro indicado. |

AP utiliza APPLICATION_ID 200, AR 222 y FA 140 en estos recorridos estándar. Los archivos AP/AR conservan el documento aunque no exista la entidad o sus eventos. El de FA conserva el resumen aunque no tenga cabecera en el libro elegido.

Ejemplo de punto de entrada AP, reemplazando identificadores por valores del entorno:

~~~sql
VARIABLE p_documento_id NUMBER
VARIABLE p_org_id NUMBER
VARIABLE p_entity_ledger_id NUMBER
EXEC :p_documento_id := 12345;
EXEC :p_org_id := 204;
EXEC :p_entity_ledger_id := 2021;
@ap_factura_xla.sql
~~~

Después usar los identificadores obtenidos en [eventos_contables.sql](eventos_contables.sql), [asientos_detalle.sql](asientos_detalle.sql) y [trazabilidad_gl.sql](trazabilidad_gl.sql), declarando **todos** sus parámetros según el [README](README.md). Para el tramo contable indicar la aplicación de origen y el libro de XLA_AE_HEADERS. El libro de la entidad puede diferir del libro de cabecera cuando intervienen libros secundarios.

## Compras → recepción → AP → XLA → GL

1. [Requisición y orden](../PO/requisiciones_ordenes_compra.sql): partir de la distribución de requisición, no solo de su cabecera. PO_DISTRIBUTIONS_ALL.REQ_DISTRIBUTION_ID permite el enlace con PO_REQ_DISTRIBUTIONS_ALL.DISTRIBUTION_ID cuando la orden nace de una requisición.
2. [Orden de compra](../PO/ordenes_compra.sql): conservar PO_DISTRIBUTION_ID. Una línea puede tener varios envíos y distribuciones.
3. En facturas conciliadas con compras, AP_INVOICE_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID permite enlazar la distribución AP. Si existe conciliación con recepción, RCV_TRANSACTION_ID identifica la transacción de RCV_TRANSACTIONS; no todas las facturas tienen ambos enlaces.
4. [Factura AP](../AP/facturas.sql) → [entidad y eventos AP](ap_factura_xla.sql) → asiento XLA → referencia GL.
5. El [pago AP](../AP/pagos.sql) es otro recorrido contable. Una factura puede tener varios pagos y un pago varias facturas. No unir factura y pago por importes ni asumir que comparten evento.

La contabilización de recepción/acumulación puede originarse en otra aplicación contable según configuración. No asignar APPLICATION_ID 200 a todo el recorrido de compras ni tratar la orden como factura.

## Pedido ONT → despacho → AR → XLA → GL

1. Usar [pedidos](../ONT/pedidos.sql) y [despachos](../ONT/pedidos_despachos.sql) para conservar identificadores de pedido, línea y entrega.
2. Revisar [pedidos y facturación](../ONT/pedidos_facturacion.sql): el enlace hacia AR utiliza el contexto y los atributos de la interfaz de AutoInvoice del flujo correspondiente. No existe una regla universal que permita comparar siempre una columna genérica de AR con LINE_ID.
3. Con CUSTOMER_TRX_ID y ORG_ID, ejecutar [ar_transaccion_xla.sql](ar_transaccion_xla.sql). APPLICATION_ID 222 y entidad TRANSACTIONS corresponden a estas transacciones AR.
4. Continuar por los eventos y líneas XLA hasta GL. Los cobros y sus aplicaciones tienen su propio recorrido y no deben forzarse dentro de la misma entidad de factura.

Despachos parciales, facturas divididas y notas de crédito pueden cambiar la cardinalidad. La contabilidad del costo del movimiento INV es otra rama; no representa la misma línea de ingreso AR.

## AP → activo FA → depreciación → XLA → GL

1. Identificar la factura y su distribución AP que originan una incorporación. La etapa de altas masivas y el activo definitivo son estados distintos.
2. Revisar los datos de origen en FA_ASSET_INVOICES y la configuración del proceso de altas masivas. No todas las facturas generan activos ni todos los activos provienen de AP; pueden existir divisiones o agrupaciones.
3. Consultar el [activo](../FA/activos.sql), su libro y [depreciación](../FA/depreciacion.sql). No confundir BOOK_TYPE_CODE con LEDGER_ID.
4. Ejecutar [fa_depreciacion_xla.sql](fa_depreciacion_xla.sql): EVENT_ID de FA_DEPRN_SUMMARY enlaza con cabeceras XLA de aplicación 140 en el libro elegido. El script no pretende cubrir altas, bajas, transferencias y ajustes.
5. Usar AE_HEADER_ID, aplicación y libro para continuar en trazabilidad_gl.sql.

## Cómo evitar duplicar importes

- SOURCE_ID_INT_1 es polimórfico: interpretarlo junto con APPLICATION_ID y ENTITY_CODE. Los scripts AP/AR usan asociaciones concretas; no extenderlas a todas las entidades.
- XLA_DISTRIBUTION_LINKS también es polimórfica. Revisar SOURCE_DISTRIBUTION_TYPE y los identificadores mediante [distribuciones_origen.sql](distribuciones_origen.sql); no asumir que todos representan una distribución AP.
- Mantener APPLICATION_ID en cada relación entre tablas XLA.
- Para GL usar conjuntamente GL_SL_LINK_ID y GL_SL_LINK_TABLE; después JE_HEADER_ID y JE_LINE_NUM.
- Un evento puede generar varias cabeceras y una línea contable puede asociarse con varias distribuciones o referencias. No sumar los importes de una consulta expandida como si cada fila fuera un asiento independiente.
- Conciliar a granularidad controlada y con el mismo libro, moneda, período, estado y naturaleza contable. Comparar importes contabilizados cuando se concilie con GL; contabilización, transferencia e imputación en GL son estados diferentes.
- La ausencia de GL_IMPORT_REFERENCES no demuestra que no se transfirió: intervienen configuración de referencias y retención. No sustituir el enlace por una coincidencia de texto, fecha e importe.

## Alcance y fuentes

Recorridos estándar orientados a R12.1/R12.2, de lectura y sin contexto implícito. Verificar configuración y parches del entorno. Pendiente ejecución nativa en Oracle EBS.

- [Oracle: ejemplo de enlace AP con XLA_TRANSACTION_ENTITIES](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav7ff2-11.html).
- [Oracle: enlace AR TRANSACTIONS con XLA](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnave2a2-14.html).
- [FA_DEPRN_SUMMARY: evento y clave de depreciación](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd25c.html).
