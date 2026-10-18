# AR — Interfaces de Receivables (Oracle EBS R12)

Ejemplos para R12.1/R12.2: facturas mediante AutoInvoice, clientes mediante Customer Interface y diagnóstico de cobros importados por AutoLockbox. Son plantillas con alcance definido; no representan todas las integraciones de AR ni sustituyen las validaciones del importador estándar.

| Archivo | Alcance |
| --- | --- |
| [carga_autoinvoice.sql](carga_autoinvoice.sql) | Una factura INV, una línea, moneda del libro, numeración manual y cuentas por AutoAccounting. |
| [carga_clientes.sql](carga_clientes.sql) | Cliente nuevo, dirección BILL_TO, perfil de cuenta y perfil del sitio. |
| [diagnostico_autoinvoice.sql](diagnostico_autoinvoice.sql) | Líneas pendientes, errores, distribuciones y transacciones finales. |
| [diagnostico_clientes.sql](diagnostico_clientes.sql) | Direcciones y perfiles en interfaz; identificadores finales del cliente. |
| [diagnostico_lockbox.sql](diagnostico_lockbox.sql) | Registros y estados de una transmisión bancaria. |

## Ejecución y transacciones

Usar una conexión autorizada a APPS en pruebas. Declarar todas las variables bind de la cabecera, incluidas las opcionales con NULL; NUMBER para identificadores/importes y VARCHAR2 para textos. Las fechas de carga se reciben como texto YYYY-MM-DD. Activar `SET SERVEROUTPUT ON`. Ejecutar el archivo en modo script para interpretar los separadores `/`.

Los bloques de carga no hacen COMMIT ni envían concurrentes. Un error revierte únicamente hasta el SAVEPOINT del bloque; una carga correcta queda pendiente de revisión y COMMIT o ROLLBACK explícito. Confirmar antes de importar desde otra sesión. No ejecutar dos cargas simultáneas de la misma referencia: las comprobaciones previas no son un bloqueo ni garantizan idempotencia.

Los scripts consultan tablas base con alias por iniciales y SQL tradicional. La OU se recibe en `p_org_id`; no se obtiene de la sesión. La responsabilidad usada para importar debe tener acceso a esa OU. En R12.2 se conservan los sinónimos APPS estándar y su resolución a objetos de edición.

## AutoInvoice

Preparar un origen importado activo, con numeración manual y reglas por identificador para cliente, dirección, tipo y términos. Configurar AutoAccounting, agrupación, período AR abierto y un tipo INV vigente.

La plantilla requiere un contexto propio del flexfield de transacción con exactamente dos atributos habilitados: ATTRIBUTE1 identifica el documento y ATTRIBUTE2 la línea. La agrupación debe mantener separados los documentos. Adaptar la plantilla si el contexto usa más atributos; no reutilizar un contexto de OM ni de otra integración.

`p_bill_to_site_use_id` recibe el uso BILL_TO activo. El bloque obtiene el cliente y el CUST_ACCT_SITE_ID que necesita ORIG_SYSTEM_BILL_ADDRESS_ID; ambos identificadores son distintos. Los demás parámetros están en la cabecera.

La carga deja los identificadores internos, estados y REQUEST_ID sin asignar. AutoInvoice los genera. Para una ampliación con distribuciones o créditos de venta, relacionar las filas por el mismo contexto y todos los atributos del flexfield; no inventar secuencias de interfaz.

1. Ejecutar la carga y revisar la línea con el diagnóstico.
2. Confirmar la transacción.
3. Desde Receivables, enviar **AutoInvoice Master Program** con OU, origen y filtros específicos del documento/lote disponibles en la instalación. Verificar los parámetros locales en SRS; usar un origen dedicado si es necesario aislar el alcance.
4. Revisar la solicitud maestra, sus hijas, el log y el informe de validación.
5. Consultar errores y transacciones finales. Corregir únicamente los registros propios rechazados y volver a importar después de comprobar que no se creó ya la factura.

La plantilla usa AutoAccounting; no inserta distribuciones explícitas, créditos de venta ni contingencias. No cubre notas crédito, moneda extranjera, reglas de reconocimiento ni impuestos explícitos. ZX puede calcular impuestos por configuración. Si se exigen vendedores/créditos de venta, adaptar la carga antes de usarla.

AutoInvoice dispone de cuatro tablas de entrada: RA_INTERFACE_LINES_ALL, RA_INTERFACE_DISTRIBUTIONS_ALL, RA_INTERFACE_SALESCREDITS_ALL y AR_INTERFACE_CONTS_ALL. RA_INTERFACE_ERRORS_ALL guarda rechazos. El diagnóstico separa errores e importes para evitar multiplicaciones; las distribuciones se filtran por OU/contexto/documento, sin filtro de origen porque esa tabla no lo contiene. Usar referencias externas únicas.

## Customer Interface

La plantilla clásica sigue siendo un proceso distinto del Bulk Import de TCA. Usa RA_CUSTOMERS_INTERFACE_ALL y RA_CUSTOMER_PROFILES_INT_ALL para un cliente nuevo con dirección BILL_TO. No modifica tablas HZ directamente.

Indicar referencias externas únicas, nombre, país, dirección y clase de perfil activa. Número de cliente y location deben quedar NULL cuando su numeración es automática; si es manual son obligatorios. Completar ciudad, estado y código postal según las validaciones geográficas del país.

1. Ejecutar la carga y revisar dirección y dos perfiles.
2. Confirmar y enviar **Customer Interface** desde una responsabilidad autorizada, revisando el alcance real de sus parámetros antes del envío.
3. Revisar **Customer Interface Transfer Report** y los códigos INTERFACE_STATUS.
4. Recuperar los identificadores finales CUST_ACCOUNT_ID, CUST_ACCT_SITE_ID y SITE_USE_ID antes de cargar facturas.

Un estado NULL no demuestra éxito. El diagnóstico final muestra usos de dirección de la OU; no es un inventario global de cuentas sin sitios. Contactos/teléfonos, métodos de cobro y bancos quedan fuera de esta plantilla.

## AutoLockbox

1. Configurar banco, cuenta de remesa, método de recibo, lockbox y formato de transmisión.
2. Preparar el archivo del banco conforme al formato y control file instalados, con sus cabeceras, detalles y registros de continuación.
3. Ejecutar **Submit Lockbox Processing**: importación, validación y Post QuickCash según el flujo configurado.
4. Conservar el identificador de transmisión y revisar registros mediante el diagnóstico, además del informe de ejecución.
5. Corregir rechazos por el flujo estándar y comprobar recibos/aplicaciones finales; no reenviar a ciegas una transmisión ya procesada.

No se incluye un INSERT genérico: el contenido depende del formato bancario. La interfaz temporal no es el saldo final de recibos. No sumar cabeceras, detalles y registros de continuación como si todos fueran cobros.

## Validación y referencias

Revisión documental y comprobaciones estáticas del código. **Pendiente ejecutar y compilar en una instancia Oracle EBS** con la configuración y parches del cliente; no se afirma una certificación funcional R12.

- [Oracle Receivables Reference Guide — tablas de AutoInvoice y AutoLockbox](https://docs.oracle.com/cd/E26401_01/doc.122/f10312/T447348T383863.htm).
- [Oracle TCA Reference Guide — Customer Interface](https://docs.oracle.com/cd/E18727-01/doc.121/e13569/T169891T392486.htm).
- [Consultas AR](../../consultas/AR/README.md).
- [Volver a interfaces](../README.md).
