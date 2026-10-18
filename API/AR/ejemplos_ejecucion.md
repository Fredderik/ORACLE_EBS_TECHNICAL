# Declaraciones y ejecución — API/AR

Desde la raíz del repositorio, preparar la misma sesión SQL*Plus. Los NULL son marcadores: completar todos los obligatorios con datos válidos antes de llamar cada script. Revisar [alcance y transacciones](README.md). No ejecutar toda esta página como un lote.

## Contexto común

```sql
SET SERVEROUTPUT ON
VARIABLE p_user_id NUMBER
VARIABLE p_resp_id NUMBER
VARIABLE p_resp_appl_id NUMBER
VARIABLE p_org_id NUMBER
EXEC :p_user_id := NULL;
EXEC :p_resp_id := NULL;
EXEC :p_resp_appl_id := NULL;
EXEC :p_org_id := NULL;
-- Completar IDs autorizados antes de continuar.
@utilidades/FND/inicializar_contexto.sql
```

## crear_factura.sql

```sql
VARIABLE p_trx_date VARCHAR2(2000)
VARIABLE p_gl_date VARCHAR2(2000)
VARIABLE p_amount NUMBER
VARIABLE p_term_id NUMBER
VARIABLE p_description VARCHAR2(2000)
VARIABLE p_bill_to_site_use_id NUMBER
VARIABLE p_batch_source_id NUMBER
VARIABLE p_cust_trx_type_id NUMBER
VARIABLE p_trx_number VARCHAR2(2000)
VARIABLE p_primary_salesrep_id NUMBER
EXEC :p_trx_date := NULL;
EXEC :p_gl_date := NULL;
EXEC :p_amount := NULL;
EXEC :p_term_id := NULL;
EXEC :p_description := NULL;
EXEC :p_bill_to_site_use_id := NULL;
EXEC :p_batch_source_id := NULL;
EXEC :p_cust_trx_type_id := NULL;
EXEC :p_trx_number := NULL;
EXEC :p_primary_salesrep_id := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/crear_factura.sql
```

## crear_recibo.sql

```sql
VARIABLE p_receipt_date VARCHAR2(2000)
VARIABLE p_gl_date VARCHAR2(2000)
VARIABLE p_amount NUMBER
VARIABLE p_receipt_number VARCHAR2(2000)
VARIABLE p_receipt_method_id NUMBER
VARIABLE p_bank_acct_use_id NUMBER
VARIABLE p_bill_to_site_use_id NUMBER
VARIABLE p_comments VARCHAR2(2000)
EXEC :p_receipt_date := NULL;
EXEC :p_gl_date := NULL;
EXEC :p_amount := NULL;
EXEC :p_receipt_number := NULL;
EXEC :p_receipt_method_id := NULL;
EXEC :p_bank_acct_use_id := NULL;
EXEC :p_bill_to_site_use_id := NULL;
EXEC :p_comments := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/crear_recibo.sql
```

## aplicar_recibo.sql

```sql
VARIABLE p_apply_date VARCHAR2(2000)
VARIABLE p_gl_date VARCHAR2(2000)
VARIABLE p_amount_applied NUMBER
VARIABLE p_cash_receipt_id NUMBER
VARIABLE p_payment_schedule_id NUMBER
EXEC :p_apply_date := NULL;
EXEC :p_gl_date := NULL;
EXEC :p_amount_applied := NULL;
EXEC :p_cash_receipt_id := NULL;
EXEC :p_payment_schedule_id := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/aplicar_recibo.sql
```

## desaplicar_recibo.sql

```sql
VARIABLE p_reversal_gl_date VARCHAR2(2000)
VARIABLE p_receivable_application_id NUMBER
EXEC :p_reversal_gl_date := NULL;
EXEC :p_receivable_application_id := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/desaplicar_recibo.sql
```

## revertir_recibo.sql

```sql
VARIABLE p_reversal_date VARCHAR2(2000)
VARIABLE p_reversal_gl_date VARCHAR2(2000)
VARIABLE p_reversal_category_code VARCHAR2(2000)
VARIABLE p_reversal_reason_code VARCHAR2(2000)
VARIABLE p_cash_receipt_id NUMBER
VARIABLE p_comments VARCHAR2(2000)
EXEC :p_reversal_date := NULL;
EXEC :p_reversal_gl_date := NULL;
EXEC :p_reversal_category_code := NULL;
EXEC :p_reversal_reason_code := NULL;
EXEC :p_cash_receipt_id := NULL;
EXEC :p_comments := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/revertir_recibo.sql
```

## crear_ajuste.sql

```sql
VARIABLE p_apply_date VARCHAR2(2000)
VARIABLE p_gl_date VARCHAR2(2000)
VARIABLE p_expected_balance NUMBER
VARIABLE p_receivables_trx_id NUMBER
VARIABLE p_payment_schedule_id NUMBER
VARIABLE p_comments VARCHAR2(2000)
EXEC :p_apply_date := NULL;
EXEC :p_gl_date := NULL;
EXEC :p_expected_balance := NULL;
EXEC :p_receivables_trx_id := NULL;
EXEC :p_payment_schedule_id := NULL;
EXEC :p_comments := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/crear_ajuste.sql
```

## diagnostico_operaciones.sql

```sql
VARIABLE p_customer_trx_id NUMBER
VARIABLE p_cash_receipt_id NUMBER
EXEC :p_customer_trx_id := NULL;
EXEC :p_cash_receipt_id := NULL;
-- Completar los parámetros de la cabecera; fechas YYYY-MM-DD.
@API/AR/diagnostico_operaciones.sql
```

Los ejemplos de cada sección reinician sus binds; copiar los IDs finales correctos antes de ejecutar. Para diagnóstico, dejar en NULL el ID de factura o recibo que no corresponda. En la aplicación usar el PAYMENT_SCHEDULE_ID de la cuota; para desaplicar usar el RECEIVABLE_APPLICATION_ID exacto. No sustituirlos por CUSTOMER_TRX_ID ni por el número visible del documento.

Tras una llamada exitosa, inspeccionar el resultado en la misma sesión y emitir COMMIT o ROLLBACK manualmente. En los casos de desaplicación, reversión o ajuste, ejecutar únicamente la operación de negocio requerida.
