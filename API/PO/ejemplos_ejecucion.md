# Ejecución de APIs PO

Ejecutar desde la raíz del repositorio en SQL*Plus o modo script compatible. Sustituir los NULL obligatorios por valores reales autorizados. Los valores de ejemplo son ilustrativos; no ejecutar todos los bloques sobre la misma orden sin revisar cada resultado.

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
VARIABLE p_org_id NUMBER
EXEC :p_org_id := NULL;
@utilidades/FND/inicializar_contexto.sql
```

Inicializar antes de invocar los paquetes PO y mantener la misma sesión. Los scripts de operación reutilizan estos cuatro binds. El diagnóstico solo necesita sus filtros y no requiere inicializar EBS.

## actualizar_orden.sql

```sql
VARIABLE p_po_header_id NUMBER
VARIABLE p_revision_num NUMBER
VARIABLE p_line_num NUMBER
VARIABLE p_shipment_num NUMBER
VARIABLE p_new_quantity NUMBER
VARIABLE p_new_price NUMBER
VARIABLE p_new_promised_date VARCHAR2(10)
VARIABLE p_new_need_by_date VARCHAR2(10)
VARIABLE p_override_date VARCHAR2(10)
EXEC :p_po_header_id := NULL;
EXEC :p_revision_num := NULL;
EXEC :p_line_num := NULL;
EXEC :p_shipment_num := NULL;
EXEC :p_new_quantity := 15;
EXEC :p_new_price := NULL;
EXEC :p_new_promised_date := NULL;
EXEC :p_new_need_by_date := NULL;
EXEC :p_override_date := NULL;
@API/PO/actualizar_orden.sql
```

## registrar_aceptacion.sql

```sql
VARIABLE p_po_header_id NUMBER
VARIABLE p_revision_num NUMBER
VARIABLE p_accepted_flag VARCHAR2(1)
VARIABLE p_acceptance_lookup_code VARCHAR2(25)
VARIABLE p_action_date VARCHAR2(10)
VARIABLE p_note VARCHAR2(240)
EXEC :p_po_header_id := NULL;
EXEC :p_revision_num := NULL;
EXEC :p_accepted_flag := 'Y';
EXEC :p_acceptance_lookup_code := NULL;
EXEC :p_action_date := '2026-10-19';
EXEC :p_note := NULL;
@API/PO/registrar_aceptacion.sql
```

## cancelar_documento.sql

```sql
VARIABLE p_confirmar_cancelacion VARCHAR2(2)
VARIABLE p_nivel VARCHAR2(10)
VARIABLE p_po_line_id NUMBER
VARIABLE p_line_location_id NUMBER
VARIABLE p_cancel_reqs_flag VARCHAR2(1)
VARIABLE p_use_gldate VARCHAR2(1)
VARIABLE p_cancel_reason VARCHAR2(240)
VARIABLE p_action_date VARCHAR2(10)
VARIABLE p_po_header_id NUMBER
VARIABLE p_revision_num NUMBER
VARIABLE p_note VARCHAR2(240)
EXEC :p_confirmar_cancelacion := 'NO';
EXEC :p_nivel := 'ENVIO';
EXEC :p_po_line_id := NULL;
EXEC :p_line_location_id := NULL;
EXEC :p_cancel_reqs_flag := 'N';
EXEC :p_use_gldate := 'N';
EXEC :p_cancel_reason := NULL;
EXEC :p_action_date := '2026-10-19';
EXEC :p_po_header_id := NULL;
EXEC :p_revision_num := NULL;
EXEC :p_note := NULL;
@API/PO/cancelar_documento.sql
```

## diagnostico_operaciones.sql

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_po_header_id NUMBER
VARIABLE p_interface_transaction_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_security_group_id NUMBER
EXEC :p_org_id := NULL;
EXEC :p_po_header_id := NULL;
EXEC :p_interface_transaction_id := NULL;
EXEC :p_language := 'US';
EXEC :p_security_group_id := 0;
@API/PO/diagnostico_operaciones.sql
```

Para actualización y aceptación, revisar y ejecutar manualmente COMMIT o ROLLBACK. La cancelación usa confirmación interna de Oracle: iniciar una sesión exclusiva, inicializar su contexto y asignar SI a p_confirmar_cancelacion solo tras revisar IDs, nivel y efectos. ROLLBACK no deshace una cancelación exitosa. El ejemplo no imprime ni envía el documento al proveedor.

El diagnóstico requiere p_org_id y p_po_header_id, idioma y grupo de seguridad explícitos. p_interface_transaction_id es el identificador impreso por registrar_aceptacion.sql; NULL omite esos errores. Los mensajes de actualizar_orden.sql se encuentran en DBMS_OUTPUT, no en esa consulta de errores.
