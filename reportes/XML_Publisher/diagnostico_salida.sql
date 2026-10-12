/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_salida.sql                                                   ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Solicitud y acciones de posprocesamiento.                                ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_request_id NUMBER: solicitud del reporte.                                               ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por acción; conserva la solicitud si aún no tiene acciones.
-- COMPLETED y ACTION_TYPE se muestran sin interpretar códigos no verificados.
-- Un concurrente terminado no garantiza que su salida se haya transformado.
SELECT fcr.request_id solicitud_id,
       fcr.phase_code fase_codigo,
       fcr.status_code estado_codigo,
       fcr.completion_text mensaje_final,
       fcr.output_file_type tipo_salida,
       fcr.outfile_name archivo_salida,
       fcr.outfile_node_name nodo_salida,
       fcr.logfile_name archivo_log,
       fcr.logfile_node_name nodo_log,
       fcr.pp_start_date inicio_posprocesamiento,
       fcr.pp_end_date fin_posprocesamiento,
       fcr.post_request_status estado_posprocesamiento,
       fcpa.sequence secuencia_accion,
       fcpa.action_type tipo_accion,
       fcpa.completed completada_codigo,
       fcpa.processor_id procesador_id,
       fcpa.publisher_return_results resultado_publisher
FROM fnd_concurrent_requests fcr,
     fnd_conc_pp_actions fcpa
WHERE fcr.request_id = :p_request_id
  AND fcpa.concurrent_request_id(+) = fcr.request_id
ORDER BY fcpa.sequence;
