# AP — interfaces abiertas de Payables

Autor: **Freddy E. Aparicio M.** · Versión **1.0** · Fecha: **17/10/2026**.

## Cuántas interfaces se incluyen

Para este directorio contamos **4 procesos principales de importación y 5 tablas de entrada**:

| Proceso | Tablas de entrada | Script de carga |
| --- | --- | --- |
| Facturas | AP_INVOICES_INTERFACE y AP_INVOICE_LINES_INTERFACE | [carga_facturas.sql](carga_facturas.sql) |
| Proveedores | AP_SUPPLIERS_INT | [carga_proveedores.sql](carga_proveedores.sql) |
| Sitios de proveedores | AP_SUPPLIER_SITES_INT | [carga_sitios.sql](carga_sitios.sql) |
| Contactos de sitios | AP_SUP_SITE_CONTACT_INT | [carga_contactos.sql](carga_contactos.sql) |

Este es el alcance de las interfaces abiertas de facturas y proveedores documentadas en la guía de Payables R12; **no es un inventario de todas las integraciones relacionadas con AP**. También existen flujos especializados de gastos, tarjetas e intercambio con otros productos. Pagos y cuentas bancarias involucran IBY/TCA y no se resuelven insertando directamente en AP_CHECKS_ALL.

AP_INTERFACE_REJECTIONS es una tabla de diagnóstico de facturas, no una sexta tabla de carga ni otro proceso de importación. Tampoco hay que inventar una AP_INVOICE_DISTRIBUTIONS_INTERFACE para este flujo: las distribuciones se generan a partir de las líneas y sus datos contables.

## Alcance de las plantillas

Los cuatro archivos son bloques PL/SQL de **alta de ejemplo**. Escriben solamente en las tablas de interfaz. Mantienen comentarios en español, alias por iniciales, parámetros explícitos, tablas base y relaciones tradicionales.

- Factura STANDARD positiva, una línea ITEM, sin orden de compra, moneda del libro de la OU y cuenta de gasto existente. Exige un período AP normal abierto. No implementa conciliación PO, notas de crédito, divisas, anticipos, retenciones ni carga explícita de impuestos. La configuración fiscal puede generar impuestos y debe revisarse en la factura resultante.
- Proveedor global con nombre y número opcional. Si la numeración es manual se debe suministrar el número; si es automática, el importador aplica su configuración.
- Sitio de pago para un proveedor existente, con OU y dirección explícitas. La dirección puede requerir más datos según el país y la configuración de TCA.
- Contacto para proveedor/sitio ya existentes. No crea un usuario de iSupplier ni registra cuentas bancarias.

Las comprobaciones previas son parciales: el importador estándar sigue siendo responsable de las validaciones completas y de los valores predeterminados.

## Orden de trabajo y transacción

1. Declarar todos los binds de la cabecera del archivo elegido, incluidos los opcionales con NULL. Usar una sesión dedicada con permisos adecuados y activar SET SERVEROUTPUT ON.
2. Ejecutar solamente la carga deseada. Guardar el identificador de interfaz mostrado por DBMS_OUTPUT.
3. Revisar las filas con los scripts de diagnóstico. Ejecutar COMMIT explícitamente para que el concurrente las vea, o ROLLBACK para descartarlas.
4. Enviar la importación estándar y comprobar su log, salida y errores por fila.
5. Si se están creando los cuatro objetos: importar primero proveedor, obtener su VENDOR_ID, importar el sitio y obtener VENDOR_SITE_ID; después importar contactos o facturas.

Los bloques no confirman ni envían solicitudes automáticamente. Ante un error revierten hasta su propio SAVEPOINT; no deshacen trabajo anterior de la sesión. Las secuencias pueden dejar huecos incluso tras un rollback.

Los controles de duplicidad son preventivos y no garantizan idempotencia ni exclusión entre sesiones concurrentes. Conservar una clave externa y trazabilidad del lote para una integración productiva; no reejecutar una carga simplemente porque la interfaz fue purgada. Un rechazo existente requiere diagnóstico, no otro INSERT idéntico.

## Lanzamiento estándar

| Carga | Programa que se debe localizar en Solicitudes |
| --- | --- |
| Facturas | Payables Open Interface Import |
| Proveedores | Supplier Open Interface Import |
| Sitios | Supplier Sites Open Interface Import |
| Contactos | Supplier Site Contacts Open Interface Import |

Los nombres visibles pueden variar por traducción. Revisar el nombre corto y los parámetros instalados con [las consultas FND](../../consultas/FND/README.md), especialmente [programas y parámetros](../../consultas/FND/cp_and_executable.sql).

Para facturas, seleccionar la OU autorizada y exactamente el SOURCE y GROUP_ID cargados. El origen debe estar configurado para importación; el grupo es VARCHAR2, no un número obligatorio. En la primera prueba, conservar las filas de interfaz para el diagnóstico y revisar el parámetro de purga.

En proveedores, la cabecera es global; los valores predeterminados del importador pueden proceder de la OU de la responsabilidad. Elegirla de manera explícita en la aplicación. No asumir que estos tres programas filtran por el ID de interfaz que imprimió el script: verificar los parámetros y el alcance de selección en el entorno para no procesar otras filas pendientes.

Para automatizar el envío, utilizar las [utilidades FND](../../utilidades/FND/README.md) después de verificar el orden y significado de los argumentos SRS. No se fijan posiciones de argumentos supuestas en estas plantillas.

Importar una factura no equivale a validarla, aprobarla, contabilizarla o pagarla.

## Parámetros y ejemplo de factura

Las cabeceras de cada SQL enumeran todos sus parámetros. Los identificadores siguientes son **marcadores ficticios** y deben reemplazarse antes de ejecutar; el origen también debe existir en el entorno.

~~~sql
SET SERVEROUTPUT ON
VARIABLE p_org_id NUMBER
VARIABLE p_vendor_id NUMBER
VARIABLE p_vendor_site_id NUMBER
VARIABLE p_terms_id NUMBER
VARIABLE p_expense_ccid NUMBER
VARIABLE p_amount NUMBER
VARIABLE p_created_by NUMBER
VARIABLE p_source VARCHAR2(80)
VARIABLE p_group_id VARCHAR2(80)
VARIABLE p_invoice_num VARCHAR2(50)
VARIABLE p_invoice_date VARCHAR2(10)
VARIABLE p_gl_date VARCHAR2(10)
VARIABLE p_description VARCHAR2(240)

EXEC :p_org_id := 204;
EXEC :p_vendor_id := 1001;
EXEC :p_vendor_site_id := 2001;
EXEC :p_terms_id := 10000;
EXEC :p_expense_ccid := 3001;
EXEC :p_amount := 100;
EXEC :p_created_by := 1234;
EXEC :p_source := 'XX_CARGA_AP';
EXEC :p_group_id := 'PRUEBA_20261017_01';
EXEC :p_invoice_num := 'PRUEBA_AP_001';
EXEC :p_invoice_date := '2026-10-17';
EXEC :p_gl_date := '2026-10-17';
EXEC :p_description := 'Prueba de interfaz AP';

@carga_facturas.sql
@diagnostico_facturas.sql
-- Revisar antes de decidir COMMIT o ROLLBACK.
~~~

Ejecutar desde esta carpeta. Fechas en texto YYYY-MM-DD; el SQL usa conversión explícita y no depende de NLS_DATE_FORMAT.

## Diagnóstico

- [diagnostico_facturas.sql](diagnostico_facturas.sql): una consulta por cabecera con suma de líneas y otra con rechazos de cabecera/línea. Requiere p_org_id, p_source y p_group_id.
- [diagnostico_proveedores.sql](diagnostico_proveedores.sql): tres consultas independientes. Declarar p_vendor_interface_id, p_vendor_site_interface_id, p_vendor_contact_interface_id y p_org_id como NUMBER. Asignar NULL a los IDs que no se quieran consultar. Sitios y contactos requieren la OU exacta.
- [Análisis de solicitud concurrente](../../consultas/FND/analisis_solicitud.sql): ejecutable, usuario, responsabilidad, estado, tiempos y archivos.
- [Consultas AP](../../consultas/AP/README.md): revisar los objetos finales después de la importación.

Los IDs de interfaz y los IDs de las tablas finales no deben confundirse. No se enlazan proveedor, sitio y contacto suponiendo que sus IDs de interfaz son iguales.

Un lote sin filas puede haber sido purgado o corresponder a filtros incorrectos; no demuestra una importación correcta. En facturas, cada rechazo se relaciona mediante PARENT_TABLE y PARENT_ID, porque los identificadores de cabecera y línea pueden coincidir. Los rechazos no se unen a la consulta de importes para evitar duplicar sumas.

## Validación y fuentes

Revisión de estructuras, secuencias, filtros y diagnóstico con casos locales. **Pendiente compilar y ejecutar los bloques contra Oracle EBS y realizar las importaciones estándar**. No se han ejecutado cargas en una base de datos.

- [Oracle Payables Reference Guide R12.1: interfaces abiertas](https://docs.oracle.com/cd/E18727_01/doc.121/e12796/T434602T367248.htm).
- [Oracle Payables Reference Guide R12.2](https://docs.oracle.com/cd/V46499_02/current/acrobat/122aprg.pdf).
- [AP_SUPPLIERS_INT](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav930b.html), [AP_SUPPLIER_SITES_INT](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav1645-2.html?c_name=AP_SUPPLIER_SITES_INT&c_owner=AP&c_type=TABLE) y [AP_SUP_SITE_CONTACT_INT](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd00d.html).
- [AP_INVOICE_LINES_INTERFACE](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavaac3.html) y [AP_INTERFACE_REJECTIONS](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav786f.html).

[Interfaces](../README.md) · [Inicio](../../README.md)
