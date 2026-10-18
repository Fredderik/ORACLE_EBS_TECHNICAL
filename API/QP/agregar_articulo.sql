/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : agregar_articulo.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Agregar precio unitario fijo de un artículo a una lista local.
║ Parámetros y ejecución: README.md y ejemplos_ejecucion.md de este directorio.
║ Oracle EBS R12.1/R12.2. Pendiente compilación y ejecución en una instancia EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_cabecera qp_price_list_pub.price_list_rec_type := qp_price_list_pub.g_miss_price_list_rec;
    l_lineas qp_price_list_pub.price_list_line_tbl_type;
    l_atributos qp_price_list_pub.pricing_attr_tbl_type;
    l_cabecera_salida qp_price_list_pub.price_list_rec_type;
    l_valores_cabecera qp_price_list_pub.price_list_val_rec_type;
    l_lineas_salida qp_price_list_pub.price_list_line_tbl_type;
    l_valores_lineas qp_price_list_pub.price_list_line_val_tbl_type;
    l_calificadores qp_qualifier_rules_pub.qualifiers_tbl_type;
    l_valores_calificadores qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    l_atributos_salida qp_price_list_pub.pricing_attr_tbl_type;
    l_valores_atributos qp_price_list_pub.pricing_attr_val_tbl_type;
    l_estado VARCHAR2(1);
    l_num_mensajes NUMBER;
    l_mensaje VARCHAR2(2000);
    l_cantidad NUMBER;
    l_precio NUMBER;
    l_inicio DATE;
    l_fin DATE;
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
    PROCEDURE revisar_resultado IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Estado API: ' || NVL(l_estado, '(sin estado)'));
        IF NVL(l_num_mensajes, 0) > 0 THEN
            FOR l_indice IN 1..l_num_mensajes LOOP
                DBMS_OUTPUT.PUT_LINE('Mensaje: ' || oe_msg_pub.get(
                    p_msg_index => l_indice, p_encoded => fnd_api.g_false));
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE(l_mensaje);
        END IF;
        exigir(l_estado = fnd_api.g_ret_sts_success,
               'La API no terminó correctamente; revisar los mensajes.');
    END;
BEGIN
    SAVEPOINT inicio_qp;
    exigir(:p_user_id > 0 AND :p_resp_id > 0 AND :p_resp_appl_id > 0
            AND :p_org_id > 0, 'Indicar usuario, responsabilidad, aplicación y unidad operativa.');
    exigir(fnd_global.user_id = :p_user_id AND fnd_global.resp_id = :p_resp_id
            AND fnd_global.resp_appl_id = :p_resp_appl_id,
            'Inicializar primero el contexto EBS indicado, en esta misma sesión.');
    mo_global.init('ONT');
    exigir(mo_global.check_access(:p_org_id) = 'Y',
            'La responsabilidad no tiene acceso a la unidad operativa indicada.');
    mo_global.set_policy_context('S', :p_org_id);
    SELECT COUNT(*)
      INTO l_cantidad
      FROM qp_list_headers_b qlhb
     WHERE qlhb.list_header_id = :p_list_header_id
       AND qlhb.list_type_code = 'PRL'
       AND qlhb.orig_org_id = :p_org_id
       AND qlhb.global_flag = 'N';
    exigir(l_cantidad = 1, 'Se requiere una lista PRL local de la unidad operativa indicada.');
    l_cabecera.list_header_id := :p_list_header_id;
    l_cabecera.operation := qp_globals.g_opr_update;
    l_inicio := TO_DATE(:p_start_date, 'FXYYYY-MM-DD');
    l_fin := TO_DATE(:p_end_date, 'FXYYYY-MM-DD');
    exigir(l_inicio IS NOT NULL, 'Indicar fecha inicial con formato YYYY-MM-DD.');
    exigir(l_fin IS NULL OR l_fin >= l_inicio, 'La fecha final debe ser igual o posterior a la inicial.');
    exigir(:p_inventory_item_id > 0 AND :p_inventory_org_id > 0
            AND :p_uom_code IS NOT NULL, 'Indicar artículo, organización de inventario y unidad de medida.');
    SELECT COUNT(*)
      INTO l_cantidad
      FROM mtl_system_items_b msib
     WHERE msib.inventory_item_id = :p_inventory_item_id
       AND msib.organization_id = :p_inventory_org_id;
    exigir(l_cantidad = 1, 'El artículo no existe en la organización de inventario indicada.');
    exigir(:p_unit_price >= 0, 'Indicar un precio unitario igual o mayor que cero.');
    -- Alcance simple: rechazar cualquier línea previa para el artículo y UOM.
    -- La API valida además las reglas de duplicidad y las fechas de la lista.
    SELECT COUNT(*)
      INTO l_cantidad
      FROM qp_list_lines qll, qp_pricing_attributes qpa
     WHERE qll.list_header_id = :p_list_header_id
       AND qpa.list_line_id = qll.list_line_id
       AND qpa.product_attribute_context = 'ITEM'
       AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
       AND qpa.product_attr_value = TO_CHAR(:p_inventory_item_id, 'FM99999999999999999999')
       AND qpa.product_uom_code = :p_uom_code;
    exigir(l_cantidad = 0, 'Ya existe una línea para ese artículo y UOM; revisar antes de agregar.');
    l_lineas(1) := qp_price_list_pub.g_miss_price_list_line_rec;
    l_lineas(1).operation := qp_globals.g_opr_create;
    l_lineas(1).list_header_id := :p_list_header_id;
    l_lineas(1).list_line_type_code := 'PLL';
    l_lineas(1).arithmetic_operator := 'UNIT_PRICE';
    l_lineas(1).modifier_level_code := 'LINE';
    l_lineas(1).operand := :p_unit_price;
    l_lineas(1).start_date_active := l_inicio;
    l_lineas(1).end_date_active := l_fin;
    l_atributos(1) := qp_price_list_pub.g_miss_pricing_attr_rec;
    l_atributos(1).operation := qp_globals.g_opr_create;
    l_atributos(1).price_list_line_index := 1;
    l_atributos(1).product_attribute_context := 'ITEM';
    l_atributos(1).product_attribute := 'PRICING_ATTRIBUTE1';
    l_atributos(1).product_attr_value := TO_CHAR(:p_inventory_item_id, 'FM99999999999999999999');
    l_atributos(1).product_uom_code := :p_uom_code;
    l_atributos(1).excluder_flag := 'N';
    l_atributos(1).attribute_grouping_no := 1;
    l_atributos(1).comparison_operator_code := '=';
    qp_price_list_pub.process_price_list(
        p_api_version_number => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_return_values => fnd_api.g_false,
        p_commit => fnd_api.g_false,
        x_return_status => l_estado,
        x_msg_count => l_num_mensajes,
        x_msg_data => l_mensaje,
        p_price_list_rec => l_cabecera,
        p_price_list_line_tbl => l_lineas,
        p_pricing_attr_tbl => l_atributos,
        x_price_list_rec => l_cabecera_salida,
        x_price_list_val_rec => l_valores_cabecera,
        x_price_list_line_tbl => l_lineas_salida,
        x_price_list_line_val_tbl => l_valores_lineas,
        x_qualifiers_tbl => l_calificadores,
        x_qualifiers_val_tbl => l_valores_calificadores,
        x_pricing_attr_tbl => l_atributos_salida,
        x_pricing_attr_val_tbl => l_valores_atributos);
    revisar_resultado;
    DBMS_OUTPUT.PUT_LINE('Identificador de cabecera: ' || l_cabecera_salida.list_header_id);
    exigir(l_lineas_salida.EXISTS(1), 'La API no devolvió la línea creada.');
    DBMS_OUTPUT.PUT_LINE('Identificador de línea: ' || l_lineas_salida(1).list_line_id);
    DBMS_OUTPUT.PUT_LINE('Operación pendiente de confirmación. Revisar y ejecutar COMMIT o ROLLBACK manualmente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_qp;
        DBMS_OUTPUT.PUT_LINE('Operación deshecha: ' || SQLERRM);
        RAISE;
END;
/
