/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : esperar_concurrente.sql                                      ║
║ Autor          : Freddy E. Aparicio M.                                        ║
║ Fecha creación : 12/10/2026                                                   ║
║ Versión        : 1.0                                                          ║
║ Descripción    : Esperar y distinguir finalización, error y plazo.            ║
║ Parámetros     :                                                              ║
║   p_request_id: NUMBER, solicitud ya confirmada                               ║
║   p_intervalo: NUMBER, segundos positivos enteros                             ║
║   p_tiempo_maximo: NUMBER, segundos positivos enteros                         ║
║   p_dev_phase: VARCHAR2(30), salida                                           ║
║   p_dev_status: VARCHAR2(30), salida                                          ║
║   p_mensaje: VARCHAR2(2000), salida                                           ║
║ Notas          : Oracle EBS R12.1/R12.2. Revisar README antes de ejecutar.    ║
║                  Pendiente validación nativa en Oracle EBS.                   ║
║ Actualizaciones: 12/10/2026 — versión 1.0, creación.                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
DECLARE
  l_correcto BOOLEAN;
  l_phase VARCHAR2(80);
  l_status VARCHAR2(80);
  l_dev_phase VARCHAR2(30);
  l_dev_status VARCHAR2(30);
  l_mensaje VARCHAR2(2000);
BEGIN
  :p_dev_phase := NULL;
  :p_dev_status := NULL;
  :p_mensaje := NULL;
  IF :p_request_id IS NULL OR :p_request_id <= 0
     OR :p_intervalo IS NULL OR :p_intervalo <= 0
     OR :p_intervalo <> TRUNC(:p_intervalo)
     OR :p_tiempo_maximo IS NULL OR :p_tiempo_maximo <= 0
     OR :p_tiempo_maximo <> TRUNC(:p_tiempo_maximo)
     OR :p_intervalo > :p_tiempo_maximo THEN
    raise_application_error(-20001, 'Indique solicitud y tiempos positivos; intervalo <= máximo.');
  END IF;
  -- El envío debe estar confirmado antes de esperar.
  -- Se evita MAX_WAIT = 0 para no introducir una espera indefinida.
  l_correcto := fnd_concurrent.wait_for_request(
    request_id => :p_request_id, interval => :p_intervalo,
    max_wait => :p_tiempo_maximo, phase => l_phase, status => l_status,
    dev_phase => l_dev_phase, dev_status => l_dev_status, message => l_mensaje);
  :p_dev_phase := l_dev_phase;
  :p_dev_status := l_dev_status;
  :p_mensaje := l_mensaje;
  dbms_output.put_line('Fase: ' || l_dev_phase || '; estado: ' || l_dev_status);
  dbms_output.put_line('Mensaje EBS: ' || l_mensaje);
  IF l_correcto IS NULL OR NOT l_correcto THEN
    raise_application_error(-20002, 'La API no confirmó el resultado de la espera; revise la solicitud.');
  ELSIF NVL(l_dev_phase, '?') <> 'COMPLETE' THEN
    raise_application_error(-20003, 'La solicitud no finalizó dentro de la espera configurada.');
  ELSIF l_dev_status = 'WARNING' THEN
    dbms_output.put_line('Finalizó con advertencias; revisar log y salida.');
  ELSIF NVL(l_dev_status, '?') <> 'NORMAL' THEN
    raise_application_error(-20004, 'Finalizó sin éxito: ' || l_dev_status);
  ELSE
    dbms_output.put_line('Solicitud finalizada correctamente.');
  END IF;
END;
/
