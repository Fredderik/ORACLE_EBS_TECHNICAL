/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : lanzar_juego_solicitudes.sql                                 ║
║ Autor          : Freddy E. Aparicio M.                                        ║
║ Fecha creación : 12/10/2026                                                   ║
║ Versión        : 1.0                                                          ║
║ Descripción    : Plantilla de juego existente con dos programas.              ║
║ Parámetros     :                                                              ║
║   p_set_application: VARCHAR2(50), aplicación del juego                       ║
║   p_request_set: VARCHAR2(30), nombre de desarrollador del juego              ║
║   p_application_1: VARCHAR2(50), aplicación del primer programa               ║
║   p_program_1: VARCHAR2(30), primer programa                                  ║
║   p_stage_1: VARCHAR2(30), etapa de desarrollador del primer programa         ║
║   p_num_argumentos_1: NUMBER, entero de 0 a 3                                 ║
║   p_argumento1_1: VARCHAR2(240), admite NULL                                  ║
║   p_argumento2_1: VARCHAR2(240), admite NULL                                  ║
║   p_argumento3_1: VARCHAR2(240), admite NULL                                  ║
║   p_application_2: VARCHAR2(50), aplicación del segundo programa              ║
║   p_program_2: VARCHAR2(30), segundo programa                                 ║
║   p_stage_2: VARCHAR2(30), etapa de desarrollador del segundo programa        ║
║   p_num_argumentos_2: NUMBER, entero de 0 a 3                                 ║
║   p_argumento1_2: VARCHAR2(240), admite NULL                                  ║
║   p_argumento2_2: VARCHAR2(240), admite NULL                                  ║
║   p_argumento3_2: VARCHAR2(240), admite NULL                                  ║
║   p_request_id: NUMBER, salida: solicitud padre                               ║
║ Notas          : Oracle EBS R12.1/R12.2. Revisar README antes de ejecutar.    ║
║                  Pendiente validación nativa en Oracle EBS.                   ║
║ Actualizaciones: 12/10/2026 — versión 1.0, creación.                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
DECLARE
  l_correcto BOOLEAN;
  l_request_id NUMBER;
  PROCEDURE registrar_programa(
    p_application VARCHAR2, p_program VARCHAR2, p_stage VARCHAR2,
    p_cantidad NUMBER, p_arg1 VARCHAR2, p_arg2 VARCHAR2, p_arg3 VARCHAR2) IS
    l_registrado BOOLEAN;
  BEGIN
    IF p_application IS NULL OR p_program IS NULL OR p_stage IS NULL
       OR p_cantidad IS NULL OR p_cantidad NOT BETWEEN 0 AND 3
       OR p_cantidad <> TRUNC(p_cantidad) THEN
      raise_application_error(-20002, 'Revise programa, etapa y cantidad de argumentos (0 a 3).');
    END IF;
    l_registrado := fnd_submit.submit_program(
      application => p_application, program => p_program, stage => p_stage,
      argument1 => CASE WHEN p_cantidad = 0 THEN CHR(0) ELSE p_arg1 END,
    argument2 => CASE WHEN p_cantidad = 1 THEN CHR(0) ELSE p_arg2 END,
    argument3 => CASE WHEN p_cantidad = 2 THEN CHR(0) ELSE p_arg3 END,
    argument4 => CASE WHEN p_cantidad = 3 THEN CHR(0) ELSE NULL END);
    IF l_registrado IS NULL OR NOT l_registrado THEN
      raise_application_error(-20003, SUBSTR('No se pudo preparar ' || p_program
        || ': ' || fnd_message.get, 1, 500));
    END IF;
  END registrar_programa;
BEGIN
  :p_request_id := NULL;
  IF NVL(fnd_global.user_id, -1) < 0
     OR NVL(fnd_global.resp_id, -1) < 0
     OR NVL(fnd_global.resp_appl_id, -1) < 0 THEN
    raise_application_error(-20001, 'Inicialice primero usuario y responsabilidad.');
  END IF;
  IF :p_set_application IS NULL OR :p_request_set IS NULL THEN
    raise_application_error(-20004, 'Indique aplicación y nombre del juego.');
  END IF;
  l_correcto := fnd_submit.set_request_set(
    application => :p_set_application, request_set => :p_request_set);
  IF l_correcto IS NULL OR NOT l_correcto THEN
    raise_application_error(-20005, SUBSTR('No se pudo preparar el juego: '
      || fnd_message.get, 1, 500));
  END IF;
  -- Repetir esta llamada por cada miembro del juego existente.
  -- Las etapas y sus dependencias se definen en EBS, no por este orden de llamadas.
  registrar_programa(:p_application_1, :p_program_1, :p_stage_1,
    :p_num_argumentos_1, :p_argumento1_1, :p_argumento2_1, :p_argumento3_1);
  registrar_programa(:p_application_2, :p_program_2, :p_stage_2,
    :p_num_argumentos_2, :p_argumento1_2, :p_argumento2_2, :p_argumento3_2);
  l_request_id := fnd_submit.submit_set(start_time => NULL, sub_request => FALSE);
  IF NVL(l_request_id, 0) = 0 THEN
    raise_application_error(-20006, SUBSTR('No se pudo enviar el juego: '
      || fnd_message.get, 1, 500));
  END IF;
  :p_request_id := l_request_id;
  dbms_output.put_line('Solicitud padre del juego: ' || l_request_id);
  dbms_output.put_line('Envío pendiente de COMMIT del ejecutor.');
END;
/
