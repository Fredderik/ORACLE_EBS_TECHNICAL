/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : lanzar_concurrente.sql                                       ║
║ Autor          : Freddy E. Aparicio M.                                        ║
║ Fecha creación : 12/10/2026                                                   ║
║ Versión        : 1.0                                                          ║
║ Descripción    : Enviar un concurrente y devolver su solicitud.               ║
║ Parámetros     :                                                              ║
║   p_application: VARCHAR2(50), aplicación del programa                        ║
║   p_program: VARCHAR2(30), nombre corto del programa                          ║
║   p_num_argumentos: NUMBER, entero de 0 a 3                                   ║
║   p_argumento1: VARCHAR2(240), admite NULL                                    ║
║   p_argumento2: VARCHAR2(240), admite NULL                                    ║
║   p_argumento3: VARCHAR2(240), admite NULL                                    ║
║   p_request_id: NUMBER, salida; declarar antes de ejecutar                    ║
║ Notas          : Oracle EBS R12.1/R12.2. Revisar README antes de ejecutar.    ║
║                  Pendiente validación nativa en Oracle EBS.                   ║
║ Actualizaciones: 12/10/2026 — versión 1.0, creación.                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
DECLARE
  l_request_id NUMBER;
  l_num_argumentos NUMBER := :p_num_argumentos;
BEGIN
  :p_request_id := NULL;
  IF NVL(fnd_global.user_id, -1) < 0
     OR NVL(fnd_global.resp_id, -1) < 0
     OR NVL(fnd_global.resp_appl_id, -1) < 0 THEN
    raise_application_error(-20001, 'Inicialice primero usuario y responsabilidad.');
  END IF;
  IF :p_application IS NULL OR :p_program IS NULL THEN
    raise_application_error(-20002, 'Indique aplicación y nombre corto del programa.');
  END IF;
  IF l_num_argumentos IS NULL OR l_num_argumentos NOT BETWEEN 0 AND 3
     OR l_num_argumentos <> TRUNC(l_num_argumentos) THEN
    raise_application_error(-20003, 'La plantilla admite de cero a tres argumentos.');
  END IF;
  -- NULL puede ser un argumento real; CHR(0) marca el primer argumento no usado.
  -- Ampliar la lista y la validación si el programa necesita más argumentos.
  l_request_id := fnd_request.submit_request(
    application => :p_application, program => :p_program,
    description => NULL, start_time => NULL, sub_request => FALSE,
    argument1 => CASE WHEN l_num_argumentos = 0 THEN CHR(0) ELSE :p_argumento1 END,
    argument2 => CASE WHEN l_num_argumentos = 1 THEN CHR(0) ELSE :p_argumento2 END,
    argument3 => CASE WHEN l_num_argumentos = 2 THEN CHR(0) ELSE :p_argumento3 END,
    argument4 => CASE WHEN l_num_argumentos = 3 THEN CHR(0) ELSE NULL END);
  IF NVL(l_request_id, 0) = 0 THEN
    raise_application_error(-20004, SUBSTR('No se pudo enviar: '
      || fnd_message.get, 1, 500));
  END IF;
  :p_request_id := l_request_id;
  dbms_output.put_line('Solicitud creada: ' || l_request_id);
  dbms_output.put_line('Envío pendiente de COMMIT del ejecutor.');
  -- Sin COMMIT ni ROLLBACK automáticos: decidir en esta misma sesión.
END;
/
