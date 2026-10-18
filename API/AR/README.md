# AR — APIs de Receivables (Oracle EBS R12)

Ejemplos PL/SQL de facturación y cobros para R12.1/R12.2. Usan APIs públicas; no insertan ni actualizan directamente las tablas funcionales.

| Archivo | API | Alcance |
| --- | --- | --- |
| [crear_factura.sql](crear_factura.sql) | AR_INVOICE_API_PUB.CREATE_SINGLE_INVOICE | Una factura INV de una línea, moneda del libro y AutoAccounting. |
| [crear_recibo.sql](crear_recibo.sql) | AR_RECEIPT_API_PUB.CREATE_CASH | Recibo identificado de un cliente, en moneda del libro. |
| [aplicar_recibo.sql](aplicar_recibo.sql) | AR_RECEIPT_API_PUB.APPLY | Aplicar importe a una cuota INV del mismo cliente y moneda. |
| [desaplicar_recibo.sql](desaplicar_recibo.sql) | AR_RECEIPT_API_PUB.UNAPPLY | Desaplicar una aplicación CASH/APP por su ID. |
| [revertir_recibo.sql](revertir_recibo.sql) | AR_RECEIPT_API_PUB.REVERSE | Reversión estándar de un recibo CASH. |
| [crear_ajuste.sql](crear_ajuste.sql) | AR_ADJUST_PUB.CREATE_ADJUSTMENT | Ajuste INVOICE por el saldo positivo completo de una cuota. |
| [diagnostico_operaciones.sql](diagnostico_operaciones.sql) | Consultas de lectura | Factura, cuotas, recibo, aplicaciones y ajustes. |
| [ejemplos_ejecucion.md](ejemplos_ejecucion.md) | Parámetros SQL*Plus | Declaraciones de todos los binds y orden de uso. |

## Preparación y contexto

Usar una sesión APPS autorizada de pruebas e inicializarla con [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql). Los parámetros comunes NUMBER son p_user_id, p_resp_id, p_resp_appl_id y p_org_id. No se toman IDs de negocio de la sesión.

Los bloques comprueban usuario/responsabilidad, llaman MO_GLOBAL.INIT('AR'), verifican acceso y seleccionan la OU recibida. APPS_INITIALIZE no autentica ni concede permisos. Usar una sesión nueva al cambiar de responsabilidad; las APIs pueden conservar valores globales. Una lectura directa en APPS no equivale a autorización funcional.

Declarar todos los binds de cada cabecera, incluidos opcionales con NULL. Las fechas son VARCHAR2 en formato YYYY-MM-DD. Los códigos técnicos se pasan como códigos, no traducciones de la pantalla.

## Flujo de ejemplo

1. Preparar cliente y uso BILL_TO activo de la OU, términos, tipo INV, origen Manual, AutoAccounting y configuración fiscal.
2. Crear la factura y revisar el CUSTOMER_TRX_ID final y COMPLETE_FLAG.
3. Consultar cuotas para escoger PAYMENT_SCHEDULE_ID.
4. Crear el recibo y conservar CASH_RECEIPT_ID.
5. Aplicar un importe a la cuota y revisar las filas resultantes.
6. Confirmar o revertir explícitamente la transacción según el resultado.

Desaplicar, revertir y ajustar son operaciones alternativas de mantenimiento; **no forman parte de una secuencia que deba ejecutarse completa**.

## Facturas

La API requiere un origen de tipo **Manual** (BATCH_SOURCE_TYPE = INV). El origen importado usado en [AutoInvoice](../../Interface/AR/README.md) no es intercambiable. La numeración del origen determina si p_trx_number debe informarse o permanecer NULL; dejarlo NULL cuando se copie la secuencia documental o se genere automáticamente.

El importe del ejemplo corresponde a una línea con cantidad 1. No incluye moneda extranjera, notas crédito, contingencias, distribución explícita ni créditos de venta. AutoAccounting debe resolver las cuentas; ZX puede calcular impuestos, por lo que el total final puede diferir del importe de la línea. Indicar vendedor cuando la configuración lo exija y ampliar las colecciones si se requieren créditos de venta.

Los IDs 1 de cabecera/línea relacionan las colecciones de una única llamada y no son IDs finales. El resultado válido se obtiene de X_CUSTOMER_TRX_ID. El script comprueba tanto el estado como AR_TRX_ERRORS_GT, imprime sus errores antes de revertir y exige un ID final. Si hay errores temporales de una llamada anterior, detenerse y usar una sesión nueva después de revisarlos; el ejemplo no los borra.

## Recibos y aplicaciones

Usar un método de recibo compatible con cobro manual y una cuenta de remesa configurada para ese método. p_bank_acct_use_id corresponde a **CE_BANK_ACCT_USES_ALL.BANK_ACCT_USE_ID**, aunque el parámetro de la API se llame p_remittance_bank_account_id. No pasar BANK_ACCOUNT_ID ni un ID de cuenta externa del cliente.

El recibo se crea identificado mediante BILL_TO y en moneda del libro. No representa una solicitud de cargo a tarjeta o débito bancario externo. La API valida además la configuración del método, cuenta, fechas y demás reglas.

La aplicación requiere PAYMENT_SCHEDULE_ID para identificar la cuota exacta, mismo cliente y moneda; no admite descuentos ni sobreaplicación en este ejemplo. La API verifica el importe disponible del recibo. Las consultas previas no bloquean el saldo ni garantizan que permanezca igual.

UNAPPLY recibe RECEIVABLE_APPLICATION_ID de una aplicación CASH, APP y DISPLAY = Y. Deshacer la aplicación libera el cobro; revertir el recibo afecta al recibo y sus aplicaciones según las reglas estándar. Los códigos de motivo/categoría y las fechas de reversión deben ser válidos en la instalación. Los ejemplos no solicitan cancelar reclamaciones; no abarcan casos de Trade Management ni reversión mediante nota de débito.

## Ajustes

La plantilla exige un saldo esperado positivo y lo compara con la cuota. Solicita un ajuste INVOICE por su negativo para compensar el saldo completo. No es un pago ni una nota crédito; no usar para ajustes parciales de líneas, impuesto o flete.

Configurar una actividad de ajuste con origen de cuenta contable Activity y los límites de aprobación del usuario. Se conservan P_CHK_APPROVAL_LIMITS y P_CHECK_AMOUNT en TRUE. Una respuesta exitosa no implica que el ajuste esté aprobado: revisar su estado y el flujo de aprobación antes de dar el saldo por cerrado.

AR_ADJUSTMENTS%ROWTYPE se usa exclusivamente porque es el tipo formal de la API; las consultas de diagnóstico usan AR_ADJUSTMENTS_ALL y filtros explícitos de OU.

## Errores y transacciones

Cada bloque imprime la pila de mensajes, exige estado S y vuelve a lanzar cualquier error. Facturas comprueba también la tabla temporal de errores. Un ID devuelto no basta para ignorar un estado fallido.

Todos pasan p_commit = FND_API.G_FALSE (p_commit_flag en ajustes). No hay COMMIT automático ni importador que lanzar. Revisar en la misma sesión y confirmar o revertir manualmente. Cada SAVEPOINT delimita el bloque actual: un fallo posterior no revierte los bloques anteriores. SQL*Plus puede continuar tras un error; ejecutar los ejemplos por separado y no agregar un COMMIT incondicional al final.

No se promete idempotencia. Conservar IDs y revisar antes de repetir altas, aplicaciones o ajustes; las validaciones preventivas no sustituyen un control de duplicados de la integración. Las APIs de este directorio no ofrecen el modo p_validate de los ejemplos HRMS.

## Otras APIs y alcance pendiente

El catálogo AR incluye CREATE_INVOICE para lotes, CREATE_AND_APPLY para crear/aplicar en una llamada y operaciones on-account. No se incluyen plantillas de esas variantes en esta entrega. Las APIs HZ/TCA para clientes son otro flujo y requieren gestionar cuenta, sitios, usos y perfiles.

## Validación y referencias

Firmas contrastadas con documentación de R12; revisión estática y de filtros. **Pendiente compilar y probar en una instancia Oracle EBS** con sus parches y configuración. Validar alta correcta, error funcional, OU incorrecta, cuotas, duplicados, reversión y aprobación de ajustes.

- [Oracle: Invoice Creation API](https://docs.oracle.com/cd/E26401_01/doc.122/f10312/T447348T399064.htm).
- [Oracle: Receipt API](https://docs.oracle.com/cd/E26401_01/doc.122/f10312/T447348T399045.htm).
- [Oracle: Adjustment API](https://docs.oracle.com/cd/E18727_01/doc.121/e13512/T447348T454972.htm).
- [Consultas AR](../../consultas/AR/README.md).
- [Interfaces AR](../../Interface/AR/README.md).

[Volver a API](../README.md)
