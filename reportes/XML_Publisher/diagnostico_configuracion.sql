/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_configuracion.sql                                            ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Definiciones, plantillas y archivos registrados.                         ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_application_short_name VARCHAR2: aplicación de la definición.                           ║
║ p_data_source_code VARCHAR2: código de la definición.                                     ║
║ p_lob_application VARCHAR2: aplicación del archivo a revisar.                             ║
║ p_lob_code VARCHAR2: código del archivo a revisar.                                        ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por plantilla; conserva definiciones que no tienen plantilla.
-- La aplicación de la plantilla puede diferir de la aplicación de los datos.
SELECT xddb.application_short_name aplicacion_datos,
       xddb.data_source_code definicion_codigo,
       xddb.data_source_status estado_definicion,
       xddb.start_date inicio_definicion,
       xddb.end_date fin_definicion,
       xtb.application_short_name aplicacion_plantilla,
       xtb.template_code plantilla_codigo,
       xtb.template_type_code tipo_plantilla,
       xtb.default_language idioma_predeterminado
FROM xdo_ds_definitions_b xddb,
     xdo_templates_b xtb
WHERE xddb.application_short_name = :p_application_short_name
  AND xddb.data_source_code = :p_data_source_code
  AND xtb.ds_app_short_name(+) = xddb.application_short_name
  AND xtb.data_source_code(+) = xddb.data_source_code
ORDER BY xtb.application_short_name, xtb.template_code
/
-- Consulta independiente: cada idioma, territorio y tipo constituye un archivo.
-- Para el RTF usar aplicación/código de plantilla; para datos, los de definición.
-- No se extrae el contenido binario.
SELECT xl.lob_type tipo_archivo,
       xl.application_short_name aplicacion,
       xl.lob_code codigo,
       xl.language idioma,
       xl.territory territorio,
       xl.file_name nombre_archivo,
       xl.xdo_file_type tipo_xdo,
       xl.file_status estado_archivo,
       xl.file_content_type tipo_contenido,
       xl.last_update_date ultima_actualizacion
FROM xdo_lobs xl
WHERE xl.application_short_name = :p_lob_application
  AND xl.lob_code = :p_lob_code
ORDER BY xl.lob_type, xl.language, xl.territory;
