# XML Publisher — definiciones, plantillas y archivos

Autor: **Freddy E. Aparicio M.** · Versión **1.0** · Fecha: **10/10/2026**.

FNDLOAD transporta metadatos mediante `xdotmpl.lct`; XDOLoader transporta los archivos. Revisa la [preparación general](README.md) antes de ejecutar los ejemplos. Cambia `XXCUS`, `XX_REPORTE` y `XX_REPORTE_RTF` por las claves del componente.

## Data Definition y sus plantillas

Descarga la definición de datos con los metadatos de sus plantillas asociadas:

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$XDO_TOP/patch/115/import/xdotmpl.lct" \
  "definicion_datos.ldt" XDO_DS_DEFINITIONS \
  APPLICATION_SHORT_NAME="XXCUS" DATA_SOURCE_CODE="XX_REPORTE"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$XDO_TOP/patch/115/import/xdotmpl.lct" \
  "definicion_datos.ldt" -
```

No es una exportación del XML de extracción ni del contenido RTF.

## Data Definition y una plantilla concreta

Alternativa cuando necesitas seleccionar una plantilla específica:

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$XDO_TOP/patch/115/import/xdotmpl.lct" \
  "definicion_y_plantilla.ldt" XDO_DS_DEFINITIONS \
  APPLICATION_SHORT_NAME="XXCUS" DATA_SOURCE_CODE="XX_REPORTE" \
  TMPL_APP_SHORT_NAME="XXCUS" TEMPLATE_CODE="XX_REPORTE_RTF"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$XDO_TOP/patch/115/import/xdotmpl.lct" \
  "definicion_y_plantilla.ldt" -
```

Es una alternativa al bloque anterior; no hace falta cargar ambos archivos para el mismo reporte. La aplicación de plantilla puede ser distinta de la aplicación de Data Definition.

## Preparación de XDOLoader

Utiliza el Java y el `CLASSPATH` del entorno EBS. Configura la conexión del origen para descargar y repite la preparación con la del destino para subir.

```bash
# Ejemplo Bash: introducir valores del entorno actual.
: "${XDO_TOP:?Carga primero el entorno EBS}"
: "${CLASSPATH:?Carga el CLASSPATH de EBS}"
: "${NLS_LANG:?Configura NLS_LANG para este entorno}"
read -r -p 'Conexión JDBC admitida por XDOLoader (host:puerto:SID): ' XDO_JDBC
read -r -s -p 'Contraseña APPS: ' XDO_PASSWORD
printf '\n'
```

La lectura evita escribir la contraseña literal en el historial, pero XDOLoader la recibe como argumento y podría ser visible para usuarios con acceso a los procesos. Usa el procedimiento de credenciales del entorno y no actives trazas de shell.

## Identificar el archivo que corresponde

Consulta de lectura para ejecutar en una herramienta SQL; declara `p_application_short_name` y `p_lob_code` como VARCHAR2. Usa el código de plantilla para el RTF y el de Data Definition para archivos de datos.

```sql
SELECT application_short_name, lob_code, lob_type,
       language, territory, xdo_file_type, file_name
FROM xdo_lobs
WHERE application_short_name = :p_application_short_name
  AND lob_code = :p_lob_code
ORDER BY lob_type, language, territory;
```

Los ejemplos siguientes usan `TEMPLATE_SOURCE` para el RTF fuente. La guía original también documenta `TEMPLATE`; no son nombres intercambiables para todos los parches. Comprueba el registro y la ayuda del XDOLoader instalado. No sustituyas el RTF fuente por un artefacto generado.

## Descargar y subir el RTF fuente

Ejemplo para una variante inglesa de Estados Unidos. Sustituye idioma/territorio por los del registro; un territorio genérico puede ser `00`.

```bash
# Descargar en origen, desde una carpeta de trabajo dedicada.
java oracle.apps.xdo.oa.util.XDOLoader DOWNLOAD \
  -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
  -JDBC_CONNECTION "$XDO_JDBC" \
  -LOB_TYPE TEMPLATE_SOURCE -APPS_SHORT_NAME XXCUS \
  -LOB_CODE XX_REPORTE_RTF -LANGUAGE en -TERRITORY US \
  -LOG_FILE descarga_rtf.log

# Subir en destino. Indicar el nombre real del RTF descargado.
java oracle.apps.xdo.oa.util.XDOLoader UPLOAD \
  -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
  -JDBC_CONNECTION "$XDO_JDBC" \
  -LOB_TYPE TEMPLATE_SOURCE -APPS_SHORT_NAME XXCUS \
  -LOB_CODE XX_REPORTE_RTF -LANGUAGE en -TERRITORY US \
  -XDO_FILE_TYPE RTF -FILE_CONTENT_TYPE application/rtf \
  -FILE_NAME "./XX_REPORTE_RTF.rtf" -NLS_LANG "$NLS_LANG" \
  -OWNER CUSTOM -CUSTOM_MODE NOFORCE -LOG_FILE subida_rtf.log
```

XDOLoader determina el nombre descargado; revisa el log y el archivo generado antes de asignar `FILE_NAME`. El nombre del ejemplo no garantiza el nombre de salida.

## XML de ejemplo y esquema XSD

Son archivos de apoyo de la Data Definition. No son el XML de extracción de consultas de un Data Template.

```bash
# Descargar XML de ejemplo en origen.
java oracle.apps.xdo.oa.util.XDOLoader DOWNLOAD \
  -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
  -JDBC_CONNECTION "$XDO_JDBC" \
  -LOB_TYPE XML_SAMPLE -APPS_SHORT_NAME XXCUS -LOB_CODE XX_REPORTE \
  -LOG_FILE descarga_xml_ejemplo.log

# Subir XML de ejemplo en destino.
java oracle.apps.xdo.oa.util.XDOLoader UPLOAD \
  -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
  -JDBC_CONNECTION "$XDO_JDBC" \
  -LOB_TYPE XML_SAMPLE -APPS_SHORT_NAME XXCUS -LOB_CODE XX_REPORTE \
  -LANGUAGE 00 -TERRITORY 00 -XDO_FILE_TYPE XML \
  -FILE_CONTENT_TYPE text/xml -FILE_NAME "./ejemplo.xml" \
  -NLS_LANG "$NLS_LANG" -OWNER CUSTOM -CUSTOM_MODE NOFORCE \
  -LOG_FILE subida_xml_ejemplo.log

# Descargar esquema XSD en origen.
java oracle.apps.xdo.oa.util.XDOLoader DOWNLOAD \
  -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
  -JDBC_CONNECTION "$XDO_JDBC" \
  -LOB_TYPE XML_SCHEMA -APPS_SHORT_NAME XXCUS -LOB_CODE XX_REPORTE \
  -LOG_FILE descarga_xsd.log

# Subir esquema XSD en destino.
java oracle.apps.xdo.oa.util.XDOLoader UPLOAD \
  -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
  -JDBC_CONNECTION "$XDO_JDBC" \
  -LOB_TYPE XML_SCHEMA -APPS_SHORT_NAME XXCUS -LOB_CODE XX_REPORTE \
  -LANGUAGE 00 -TERRITORY 00 -XDO_FILE_TYPE XSD \
  -FILE_CONTENT_TYPE text/xml -FILE_NAME "./esquema.xsd" \
  -NLS_LANG "$NLS_LANG" -OWNER CUSTOM -CUSTOM_MODE NOFORCE \
  -LOG_FILE subida_xsd.log
```

Los ejemplos de XML/XSD suponen idioma y territorio neutros `00/00`; conserva los valores reales del registro. No todo reporte tiene estos archivos. Migra también el Data Template de extracción o bursting si el reporte los utiliza, usando los tipos admitidos por tu XDOLoader; el LDT de metadatos no los reemplaza.

Al terminar en cada entorno:

```bash
unset XDO_PASSWORD
```

## Comprobación del resultado

Revisa los logs de FNDLOAD y XDOLoader, la asociación entre Data Definition y plantilla, y las variantes de idioma disponibles. Ejecuta el reporte en EBS y comprueba la salida. Con `NOFORCE` una versión existente puede no sustituirse; determina la causa antes de forzar una actualización.

## Referencias y versión

- [Oracle XML Publisher, apéndice C: metadatos y archivos](https://docs.oracle.com/cd/B34956_01/current/acrobat/120xdoig.pdf).
- [Oracle Managed Cloud: tipos de archivo y parámetros, incluido TEMPLATE_SOURCE](https://docs.oracle.com/en-us/iaas/Content/managed-cloud-self-service/mgdcloudss_object_types_that_use_parameters.htm).

Pendiente ejecución con las bibliotecas y parches del entorno EBS. Historial: 10/10/2026 — versión 1.0, creación.

[Volver a FNDLOAD](README.md)
