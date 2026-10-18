/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_empleado.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Alta de persona nueva como empleado y asignación predeterminada.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_business_group_id.
║ Común VARCHAR2 : p_validate (Y = solo validar; N = ejecutar sin COMMIT).
║ VARCHAR2 obligatorios: p_hire_date, p_last_name, p_sex.
║ Opcionales VARCHAR2: p_first_name, p_date_of_birth, p_national_identifier,
║ p_email_address, p_employee_number. NUMBER opcional: p_person_type_id.
║ Declarar todos los binds, incluidos los opcionales. Fechas: YYYY-MM-DD.
║ Contexto EBS previamente inicializado; ver README. R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_fecha DATE;
    l_nacimiento DATE;
    l_numero per_all_people_f.employee_number%TYPE;
    l_person_id NUMBER;
    l_assignment_id NUMBER;
    l_per_ovn NUMBER;
    l_asg_ovn NUMBER;
    l_inicio DATE;
    l_fin DATE;
    l_nombre VARCHAR2(2000);
    l_comentario NUMBER;
    l_secuencia NUMBER;
    l_numero_asignacion VARCHAR2(2000);
    l_aviso_nombre BOOLEAN;
    l_aviso_nomina BOOLEAN;
    l_aviso_alta BOOLEAN;
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

    l_fecha := TO_DATE(:p_hire_date, 'FXYYYY-MM-DD');
    l_nacimiento := TO_DATE(:p_date_of_birth, 'FXYYYY-MM-DD');
    l_numero := :p_employee_number;
    exigir(l_fecha IS NOT NULL AND TRIM(:p_last_name) IS NOT NULL
        AND TRIM(:p_sex) IS NOT NULL, 'Indicar fecha de alta, apellido y código de sexo.');
    hr_employee_api.create_employee(
        p_validate => l_validar,
        p_hire_date => l_fecha,
        p_business_group_id => :p_business_group_id,
        p_last_name => :p_last_name,
        p_sex => :p_sex,
        p_first_name => :p_first_name,
        p_date_of_birth => l_nacimiento,
        p_national_identifier => :p_national_identifier,
        p_email_address => :p_email_address,
        p_person_type_id => :p_person_type_id,
        p_employee_number => l_numero,
        p_person_id => l_person_id,
        p_assignment_id => l_assignment_id,
        p_per_object_version_number => l_per_ovn,
        p_asg_object_version_number => l_asg_ovn,
        p_per_effective_start_date => l_inicio,
        p_per_effective_end_date => l_fin,
        p_full_name => l_nombre,
        p_per_comment_id => l_comentario,
        p_assignment_sequence => l_secuencia,
        p_assignment_number => l_numero_asignacion,
        p_name_combination_warning => l_aviso_nombre,
        p_assign_payroll_warning => l_aviso_nomina,
        p_orig_hire_warning => l_aviso_alta);
    advertir(l_aviso_nombre, 'Existe una combinación de nombre y nacimiento coincidente.');
    advertir(l_aviso_nomina, 'Revisar fecha de nacimiento antes de asignar nómina.');
    advertir(l_aviso_alta, 'Revisar fecha original de contratación y tipo de persona.');
    IF NOT l_validar THEN
        exigir(l_person_id IS NOT NULL AND l_assignment_id IS NOT NULL,
               'La API no devolvió persona y asignación.');
        DBMS_OUTPUT.PUT_LINE('PERSON_ID: ' || l_person_id || '; ASSIGNMENT_ID: ' || l_assignment_id);
        DBMS_OUTPUT.PUT_LINE('Número empleado: ' || l_numero || '; número asignación: ' || l_numero_asignacion);
        DBMS_OUTPUT.PUT_LINE('OVN persona: ' || l_per_ovn || '; OVN asignación: ' || l_asg_ovn);
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
