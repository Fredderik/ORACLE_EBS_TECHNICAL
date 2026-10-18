/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_ubicacion.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Crear ubicación de oficina restringida a un grupo empresarial.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_business_group_id.
║ Común VARCHAR2 : p_validate (Y = solo validar; N = ejecutar sin COMMIT).
║ VARCHAR2 obligatorios: p_effective_date, p_language_code, p_location_code,
║ p_style, p_country, p_address_line_1. Opcionales: p_description,
║ p_town_or_city, p_region_1, p_region_2, p_region_3, p_postal_code.
║ Declarar todos los binds, incluidos los opcionales. Fechas: YYYY-MM-DD.
║ Contexto EBS previamente inicializado; ver README. R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_fecha DATE;
    l_location_id NUMBER;
    l_ovn NUMBER;
    l_validar BOOLEAN;
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
    PROCEDURE advertir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion THEN
            DBMS_OUTPUT.PUT_LINE('Advertencia: ' || p_mensaje);
        END IF;
    END;
BEGIN
    SAVEPOINT ejemplo_api_per;
    exigir(:p_validate IN ('Y', 'N'), 'p_validate debe ser Y o N.');
    l_validar := (:p_validate = 'Y');
    exigir(:p_user_id >= 0 AND :p_resp_id >= 0 AND :p_resp_appl_id >= 0
        AND :p_business_group_id > 0, 'Indicar contexto EBS y grupo empresarial.');
    exigir(fnd_global.user_id = :p_user_id
        AND fnd_global.resp_id = :p_resp_id
        AND fnd_global.resp_appl_id = :p_resp_appl_id,
        'Inicializar primero el contexto EBS con estos identificadores.');
    -- Alcance deliberadamente limitado al grupo configurado en la responsabilidad.
    exigir(TO_NUMBER(fnd_profile.value('PER_BUSINESS_GROUP_ID')) = :p_business_group_id,
        'El grupo no coincide con HR: Business Group de esta responsabilidad.');

    l_fecha := TO_DATE(:p_effective_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL AND TRIM(:p_language_code) IS NOT NULL
        AND TRIM(:p_location_code) IS NOT NULL AND TRIM(:p_style) IS NOT NULL
        AND TRIM(:p_country) IS NOT NULL AND TRIM(:p_address_line_1) IS NOT NULL,
        'Indicar fecha, idioma, código, estilo de dirección, país y dirección.');
    hr_location_api.create_location(
        p_validate => l_validar,
        p_effective_date => l_fecha,
        p_language_code => :p_language_code,
        p_location_code => :p_location_code,
        p_description => :p_description,
        p_business_group_id => :p_business_group_id,
        p_style => :p_style,
        p_country => :p_country,
        p_address_line_1 => :p_address_line_1,
        p_town_or_city => :p_town_or_city,
        p_region_1 => :p_region_1,
        p_region_2 => :p_region_2,
        p_region_3 => :p_region_3,
        p_postal_code => :p_postal_code,
        p_office_site_flag => 'Y',
        p_bill_to_site_flag => 'N',
        p_ship_to_site_flag => 'N',
        p_receiving_site_flag => 'N',
        p_in_organization_flag => 'Y',
        p_location_id => l_location_id,
        p_object_version_number => l_ovn);
    IF NOT l_validar THEN
        exigir(l_location_id IS NOT NULL, 'La API no devolvió LOCATION_ID.');
        DBMS_OUTPUT.PUT_LINE('LOCATION_ID: ' || l_location_id || '; OVN: ' || l_ovn);
    END IF;
    IF l_validar THEN
        ROLLBACK TO ejemplo_api_per;
        DBMS_OUTPUT.PUT_LINE('Validación terminada. No se conservan cambios ni IDs nuevos.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Operación pendiente: revisar advertencias y decidir COMMIT o ROLLBACK.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error de la operación: ' || SQLERRM);
        ROLLBACK TO ejemplo_api_per;
        RAISE;
END;
/
