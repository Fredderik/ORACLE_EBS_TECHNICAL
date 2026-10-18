# Ejecución de ejemplos QP

Ejecutar desde la raíz del repositorio con SQL*Plus o modo script compatible. Mantener la misma conexión. Todos los IDs y códigos NULL obligatorios deben sustituirse por valores reales autorizados; no se incluyen credenciales. Los valores no nulos son ilustrativos.

## Contexto común

```sql
SET SERVEROUTPUT ON
SET AUTOCOMMIT OFF
VARIABLE p_user_id NUMBER
VARIABLE p_resp_id NUMBER
VARIABLE p_resp_appl_id NUMBER
VARIABLE p_org_id NUMBER
EXEC :p_user_id := NULL;
EXEC :p_resp_id := NULL;
EXEC :p_resp_appl_id := NULL;
EXEC :p_org_id := NULL;
@utilidades/FND/inicializar_contexto.sql
```

Asignar los IDs antes de ejecutar la inicialización. Los ejemplos siguientes reutilizan estos cuatro binds.

## crear_lista_precios.sql

```sql
VARIABLE p_start_date VARCHAR2(10)
VARIABLE p_end_date VARCHAR2(10)
VARIABLE p_name VARCHAR2(240)
VARIABLE p_currency_code VARCHAR2(30)
VARIABLE p_rounding_factor NUMBER
VARIABLE p_description VARCHAR2(2000)
EXEC :p_start_date := '2026-10-18';
EXEC :p_end_date := NULL;
EXEC :p_name := 'XX_QP_EJEMPLO';
EXEC :p_currency_code := 'USD';
EXEC :p_rounding_factor := -2;
EXEC :p_description := 'Ejemplo técnico de QP';
@API/QP/crear_lista_precios.sql
```

## agregar_articulo.sql

```sql
VARIABLE p_list_header_id NUMBER
VARIABLE p_start_date VARCHAR2(10)
VARIABLE p_end_date VARCHAR2(10)
VARIABLE p_inventory_item_id NUMBER
VARIABLE p_inventory_org_id NUMBER
VARIABLE p_uom_code VARCHAR2(3)
VARIABLE p_unit_price NUMBER
EXEC :p_list_header_id := NULL;
EXEC :p_start_date := '2026-10-18';
EXEC :p_end_date := NULL;
EXEC :p_inventory_item_id := NULL;
EXEC :p_inventory_org_id := NULL;
EXEC :p_uom_code := NULL;
EXEC :p_unit_price := 125;
@API/QP/agregar_articulo.sql
```

## actualizar_precio.sql

```sql
VARIABLE p_list_header_id NUMBER
VARIABLE p_list_line_id NUMBER
VARIABLE p_expected_price NUMBER
VARIABLE p_unit_price NUMBER
EXEC :p_list_header_id := NULL;
EXEC :p_list_line_id := NULL;
EXEC :p_expected_price := 100;
EXEC :p_unit_price := 125;
@API/QP/actualizar_precio.sql
```

## crear_descuento.sql

```sql
VARIABLE p_start_date VARCHAR2(10)
VARIABLE p_end_date VARCHAR2(10)
VARIABLE p_inventory_item_id NUMBER
VARIABLE p_inventory_org_id NUMBER
VARIABLE p_uom_code VARCHAR2(3)
VARIABLE p_name VARCHAR2(240)
VARIABLE p_currency_code VARCHAR2(30)
VARIABLE p_discount_percent NUMBER
VARIABLE p_pricing_phase_id NUMBER
VARIABLE p_pricing_group_sequence NUMBER
VARIABLE p_incompatibility_grp_code VARCHAR2(30)
VARIABLE p_pte_code VARCHAR2(30)
VARIABLE p_source_system_code VARCHAR2(30)
VARIABLE p_description VARCHAR2(2000)
EXEC :p_start_date := '2026-10-18';
EXEC :p_end_date := NULL;
EXEC :p_inventory_item_id := NULL;
EXEC :p_inventory_org_id := NULL;
EXEC :p_uom_code := NULL;
EXEC :p_name := 'XX_QP_EJEMPLO';
EXEC :p_currency_code := 'USD';
EXEC :p_discount_percent := 10;
EXEC :p_pricing_phase_id := NULL;
EXEC :p_pricing_group_sequence := NULL;
EXEC :p_incompatibility_grp_code := NULL;
EXEC :p_pte_code := NULL;
EXEC :p_source_system_code := NULL;
EXEC :p_description := 'Ejemplo técnico de QP';
@API/QP/crear_descuento.sql
```

Para agregar o actualizar, copiar el ID real de la lista y de la línea correspondiente. El precio esperado debe coincidir con el importe consultado inmediatamente antes. Para descuentos usar una fase de ajuste de línea y los códigos configurados en la instancia; el script deja la cabecera inactiva.

Revisar los resultados con las [consultas QP](../../consultas/QP/README.md), declarando sus parámetros de filtro e idioma. Tras cada operación decidir explícitamente entre `COMMIT;` y `ROLLBACK;`. No ejecutar ambos de forma consecutiva esperando deshacer una confirmación.
