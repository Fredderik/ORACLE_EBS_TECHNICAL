/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_cargo.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Crear cargo (Job) usando el flexfield configurado.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_business_group_id.
║ Común VARCHAR2 : p_validate (Y = solo validar; N = ejecutar sin COMMIT).
║ NUMBER obligatorio: p_job_group_id. VARCHAR2 obligatorios: p_date_from,
║ p_concat_segments, p_language_code. VARCHAR2 opcional: p_date_to.
║ Declarar todos los binds, incluidos los opcionales. Fechas: YYYY-MM-DD.
║ Contexto EBS previamente inicializado; ver README. R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_desde DATE;
    l_hasta DATE;
    l_job_id NUMBER;
    l_ovn NUMBER;
    l_definicion NUMBER := NULL;
    l_nombre VARCHAR2(2000);
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

    l_desde := TO_DATE(:p_date_from, 'FXYYYY-MM-DD');
    l_hasta := TO_DATE(:p_date_to, 'FXYYYY-MM-DD');
    exigir(l_desde IS NOT NULL AND :p_job_group_id IS NOT NULL
        AND TRIM(:p_concat_segments) IS NOT NULL AND TRIM(:p_language_code) IS NOT NULL,
        'Indicar fecha inicial, grupo de cargos, segmentos e idioma.');
    exigir(l_hasta IS NULL OR l_hasta >= l_desde, 'La fecha final es anterior a la inicial.');
    -- El separador y segmentos dependen del Job Key Flexfield de la instalación.
    hr_job_api.create_job(
        p_validate => l_validar,
        p_business_group_id => :p_business_group_id,
        p_date_from => l_desde,
        p_date_to => l_hasta,
        p_job_group_id => :p_job_group_id,
        p_concat_segments => :p_concat_segments,
        p_language_code => :p_language_code,
        p_job_id => l_job_id,
        p_object_version_number => l_ovn,
        p_job_definition_id => l_definicion,
        p_name => l_nombre);
    IF NOT l_validar THEN
        exigir(l_job_id IS NOT NULL, 'La API no devolvió JOB_ID.');
        DBMS_OUTPUT.PUT_LINE('JOB_ID: ' || l_job_id || '; OVN: ' || l_ovn);
        DBMS_OUTPUT.PUT_LINE('JOB_DEFINITION_ID: ' || l_definicion || '; nombre: ' || l_nombre);
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
