# Ejecución de ejemplos CE

Ejecutar desde la raíz del repositorio con SQL*Plus o modo script compatible. Asignar los NULL obligatorios con datos de prueba válidos antes de ejecutar. No hay credenciales ni números bancarios reales en estos ejemplos.

## Contexto común

```sql
SET SERVEROUTPUT ON
SET AUTOCOMMIT OFF
VARIABLE p_user_id NUMBER
EXEC :p_user_id := NULL;
VARIABLE p_resp_id NUMBER
EXEC :p_resp_id := NULL;
VARIABLE p_resp_appl_id NUMBER
EXEC :p_resp_appl_id := NULL;
@utilidades/FND/inicializar_contexto.sql
```

Conservar la misma conexión. Los bloques reutilizan los tres binds de contexto. El diagnóstico no requiere inicialización EBS.

## crear_banco.sql

```sql
VARIABLE p_country_code VARCHAR2(2)
VARIABLE p_bank_name VARCHAR2(360)
VARIABLE p_bank_number VARCHAR2(30)
VARIABLE p_description VARCHAR2(240)
EXEC :p_country_code := NULL;
EXEC :p_bank_name := 'XX_BANCO_PRUEBA';
EXEC :p_bank_number := NULL;
EXEC :p_description := 'Ejemplo técnico CE';
@API/CE/crear_banco.sql
```

## crear_sucursal.sql

```sql
VARIABLE p_bank_id NUMBER
VARIABLE p_branch_name VARCHAR2(360)
VARIABLE p_branch_number VARCHAR2(30)
VARIABLE p_branch_type VARCHAR2(30)
VARIABLE p_description VARCHAR2(240)
VARIABLE p_bic VARCHAR2(30)
EXEC :p_bank_id := NULL;
EXEC :p_branch_name := 'XX_SUCURSAL_PRUEBA';
EXEC :p_branch_number := NULL;
EXEC :p_branch_type := NULL;
EXEC :p_description := 'Ejemplo técnico CE';
EXEC :p_bic := NULL;
@API/CE/crear_sucursal.sql
```

## crear_cuenta_interna.sql

```sql
VARIABLE p_branch_id NUMBER
VARIABLE p_legal_entity_id NUMBER
VARIABLE p_bank_account_name VARCHAR2(80)
VARIABLE p_bank_account_num VARCHAR2(100)
VARIABLE p_currency_code VARCHAR2(15)
VARIABLE p_ap_allowed VARCHAR2(1)
VARIABLE p_ar_allowed VARCHAR2(1)
VARIABLE p_start_date VARCHAR2(10)
VARIABLE p_end_date VARCHAR2(10)
VARIABLE p_account_type VARCHAR2(25)
VARIABLE p_iban VARCHAR2(50)
VARIABLE p_check_digits VARCHAR2(30)
VARIABLE p_description VARCHAR2(240)
EXEC :p_branch_id := NULL;
EXEC :p_legal_entity_id := NULL;
EXEC :p_bank_account_name := 'XX_CUENTA_PRUEBA';
EXEC :p_bank_account_num := NULL;
EXEC :p_currency_code := NULL;
EXEC :p_ap_allowed := 'Y';
EXEC :p_ar_allowed := 'N';
EXEC :p_start_date := '2026-10-19';
EXEC :p_end_date := NULL;
EXEC :p_account_type := NULL;
EXEC :p_iban := NULL;
EXEC :p_check_digits := NULL;
EXEC :p_description := 'Ejemplo técnico CE';
@API/CE/crear_cuenta_interna.sql
```

## crear_uso_cuenta.sql

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_bank_account_id NUMBER
VARIABLE p_legal_entity_id NUMBER
VARIABLE p_ledger_id NUMBER
VARIABLE p_cash_ccid NUMBER
VARIABLE p_ap_enabled VARCHAR2(1)
VARIABLE p_ar_enabled VARCHAR2(1)
VARIABLE p_validation_date VARCHAR2(10)
EXEC :p_org_id := NULL;
EXEC :p_bank_account_id := NULL;
EXEC :p_legal_entity_id := NULL;
EXEC :p_ledger_id := NULL;
EXEC :p_cash_ccid := NULL;
EXEC :p_ap_enabled := 'Y';
EXEC :p_ar_enabled := 'N';
EXEC :p_validation_date := '2026-10-19';
@API/CE/crear_uso_cuenta.sql
```

## diagnostico_configuracion.sql

```sql
VARIABLE p_bank_id NUMBER
VARIABLE p_branch_id NUMBER
VARIABLE p_legal_entity_id NUMBER
VARIABLE p_bank_account_id NUMBER
VARIABLE p_org_id NUMBER
EXEC :p_bank_id := NULL;
EXEC :p_branch_id := NULL;
EXEC :p_legal_entity_id := NULL;
EXEC :p_bank_account_id := NULL;
EXEC :p_org_id := NULL;
@API/CE/diagnostico_configuracion.sql
```

Copiar el ID de banco a p_bank_id, el ID de sucursal a p_branch_id y el ID de cuenta a p_bank_account_id antes de la siguiente operación. Los bloques ilustrativos vuelven a asignar NULL: sustituirlo por el ID que corresponda. p_legal_entity_id, p_org_id y p_ledger_id son identificadores diferentes y se obtienen de la configuración real.

Para reutilizar los datos sin confirmar aún, ejecutar el flujo en la misma sesión. Revisar los resultados y decidir COMMIT o ROLLBACK; no ejecutar ambos esperando deshacer lo ya confirmado. Un ROLLBACK completo elimina todas las altas aún pendientes de esa sesión.
