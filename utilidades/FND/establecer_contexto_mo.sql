/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : establecer_contexto_mo.sql                                   ║
║ Autor          : Freddy E. Aparicio M.                                        ║
║ Fecha creación : 12/10/2026                                                   ║
║ Versión        : 1.0                                                          ║
║ Descripción    : Unidad operativa para APIs multiorganización.                ║
║ Parámetros     :                                                              ║
║   p_appl_short_name: VARCHAR2(50), aplicación MO, obligatoria                 ║
║   p_org_id: NUMBER, unidad operativa obligatoria                              ║
║ Notas          : Oracle EBS R12.1/R12.2. Revisar README antes de ejecutar.    ║
║                  Pendiente validación nativa en Oracle EBS.                   ║
║ Actualizaciones: 12/10/2026 — versión 1.0, creación.                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
BEGIN
  IF NVL(fnd_global.user_id, -1) < 0
     OR NVL(fnd_global.resp_id, -1) < 0
     OR NVL(fnd_global.resp_appl_id, -1) < 0 THEN
    raise_application_error(-20001, 'Inicialice primero usuario y responsabilidad.');
  END IF;
  IF :p_appl_short_name IS NULL OR :p_org_id IS NULL OR :p_org_id <= 0 THEN
    raise_application_error(-20002, 'Indique aplicación MO y unidad operativa.');
  END IF;
  mo_global.init(:p_appl_short_name);
  IF NVL(mo_global.check_access(:p_org_id), 'N') <> 'Y' THEN
    raise_application_error(-20003, 'La unidad no está disponible para el contexto inicializado.');
  END IF;
  mo_global.set_policy_context('S', :p_org_id);
  dbms_output.put_line('Unidad operativa seleccionada: ' || mo_global.get_current_org_id);
END;
/
