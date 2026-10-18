/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : actualizar_asignacion.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Cambiar supervisor de una asignación de empleado existente.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_business_group_id.
║ Común VARCHAR2 : p_validate (Y = solo validar; N = ejecutar sin COMMIT).
║ NUMBER obligatorios: p_assignment_id, p_object_version_number,
║ p_supervisor_id (PERSON_ID). VARCHAR2: p_effective_date, p_datetrack_update_mode.
║ Modo permitido: CORRECTION o UPDATE; no elimina cambios futuros.
║ Declarar todos los binds, incluidos los opcionales. Fechas: YYYY-MM-DD.
║ Contexto EBS previamente inicializado; ver README. R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_fecha DATE;
    l_ovn NUMBER;
    l_ovn_actual NUMBER;
    l_person_id NUMBER;
    l_cantidad NUMBER;
    l_cagr_id NUMBER := hr_api.g_number;
    l_soft_id NUMBER := hr_api.g_number;
    l_cagr_segmentos VARCHAR2(2000);
    l_segmentos VARCHAR2(2000);
    l_comentario NUMBER;
    l_inicio DATE;
    l_fin DATE;
    l_aviso_sin_jefe BOOLEAN;
    l_aviso_otro_jefe BOOLEAN;
    l_aviso_salario BOOLEAN;
    l_aviso_gsp VARCHAR2(2000);
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
    l_ovn := :p_object_version_number;
    exigir(l_fecha IS NOT NULL AND :p_assignment_id > 0 AND l_ovn > 0
        AND :p_supervisor_id > 0, 'Indicar fecha, asignación, versión y supervisor.');
    exigir(:p_datetrack_update_mode IN ('CORRECTION', 'UPDATE'),
        'Usar CORRECTION o UPDATE tras revisar el historial DateTrack.');
    SELECT paaf.object_version_number, paaf.person_id
    INTO l_ovn_actual, l_person_id
    FROM per_all_assignments_f paaf
    WHERE paaf.assignment_id = :p_assignment_id
      AND paaf.business_group_id = :p_business_group_id
      AND paaf.assignment_type = 'E'
      AND l_fecha BETWEEN paaf.effective_start_date AND paaf.effective_end_date;
    exigir(l_ovn = l_ovn_actual, 'La versión cambió: volver a consultar y revisar antes de reintentar.');
    exigir(l_person_id <> :p_supervisor_id, 'La persona no puede supervisarse a sí misma.');
    SELECT COUNT(*) INTO l_cantidad
    FROM per_all_people_f papf
    WHERE papf.person_id = :p_supervisor_id
      AND papf.business_group_id = :p_business_group_id
      AND l_fecha BETWEEN papf.effective_start_date AND papf.effective_end_date;
    exigir(l_cantidad = 1, 'Supervisor inexistente en el grupo y fecha indicados.');

    -- Los parámetros IN omitidos conservan los centinelas HR_API.
    -- Los IN OUT de flexfields usan G_NUMBER para no borrar su configuración.
    hr_assignment_api.update_emp_asg(
        p_validate => l_validar,
        p_effective_date => l_fecha,
        p_datetrack_update_mode => :p_datetrack_update_mode,
        p_assignment_id => :p_assignment_id,
        p_object_version_number => l_ovn,
        p_supervisor_id => :p_supervisor_id,
        p_cagr_grade_def_id => l_cagr_id,
        p_cagr_concatenated_segments => l_cagr_segmentos,
        p_concatenated_segments => l_segmentos,
        p_soft_coding_keyflex_id => l_soft_id,
        p_comment_id => l_comentario,
        p_effective_start_date => l_inicio,
        p_effective_end_date => l_fin,
        p_no_managers_warning => l_aviso_sin_jefe,
        p_other_manager_warning => l_aviso_otro_jefe,
        p_hourly_salaried_warning => l_aviso_salario,
        p_gsp_post_process_warning => l_aviso_gsp);
    advertir(l_aviso_sin_jefe, 'La organización queda sin responsable.');
    advertir(l_aviso_otro_jefe, 'Ya existe otro responsable en la organización.');
    advertir(l_aviso_salario, 'Revisar base salarial y clasificación por horas/salario.');
    IF l_aviso_gsp IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Advertencia de progresión de grados: ' || l_aviso_gsp);
    END IF;
    IF NOT l_validar THEN
        DBMS_OUTPUT.PUT_LINE('ASSIGNMENT_ID: ' || :p_assignment_id || '; nuevo OVN: ' || l_ovn);
        DBMS_OUTPUT.PUT_LINE('Vigencia: ' || TO_CHAR(l_inicio, 'YYYY-MM-DD')
            || ' a ' || TO_CHAR(l_fin, 'YYYY-MM-DD'));
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
