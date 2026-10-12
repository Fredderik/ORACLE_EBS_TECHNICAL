# XML / BI Publisher en Oracle EBS

Ejemplo de reporte de solicitudes concurrentes para EBS R12.1/R12.2. Recorre SQL → Data Template → XML de datos → plantilla RTF → salida. Autor: Freddy E. Aparicio M. · Versión 1.0 · 12/10/2026.

## Archivos

| Archivo | Uso |
| --- | --- |
| [solicitudes.sql](solicitudes.sql) | Probar los filtros y los datos antes de registrar el reporte. |
| [XXFND_SOLICITUDES.xml](XXFND_SOLICITUDES.xml) | Data Template del motor de datos; contiene la misma consulta. |
| [ejemplo_solicitudes.xml](ejemplo_solicitudes.xml) | Dos solicitudes ficticias para probar el diseño sin extraer datos reales. |
| [solicitudes.rtf](solicitudes.rtf) | Plantilla básica con grupo repetitivo y mensaje sin resultados. |
| [diagnostico_configuracion.sql](diagnostico_configuracion.sql) | Definición, plantillas y metadatos de archivos por idioma/territorio. |
| [diagnostico_salida.sql](diagnostico_salida.sql) | Solicitud, archivos y acciones de posprocesamiento. |

El XML de ejemplo es **dato de entrada del diseño**; el Data Template es **definición de extracción**. No son intercambiables. El RTF usa etiquetas escritas directamente (método básico RTF de Publisher), sin macros.

## Parámetros del reporte

Todos son obligatorios. La selección explícita de aplicación limita los datos, pero no implementa por sí misma seguridad por responsabilidad; asignar el reporte a responsabilidades autorizadas.

| Orden | Nombre/token exacto | Tipo Data Template | Ejemplo |
| --- | --- | --- | --- |
| 10 | p_application_id | number | 200 |
| 20 | p_fecha_desde | character | 2026-10-01 |
| 30 | p_fecha_hasta | character | 2026-10-12 |
| 40 | p_language | character | US |

Ambas fechas son texto con formato exacto YYYY-MM-DD y días inclusivos; hasta debe ser mayor o igual que desde. El límite superior SQL es el comienzo del día siguiente. Usar validación de valores de caracteres en el concurrente que mantenga ese formato; no pasar sin convertir una fecha canónica EBS con hora. El idioma es el código EBS de la traducción del programa, no el idioma ISO del archivo RTF. La ausencia de traducción conserva la solicitud y muestra su identificador de programa.

~~~sql
VARIABLE p_application_id NUMBER
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)
VARIABLE p_language VARCHAR2(10)
EXEC :p_application_id := 200;
EXEC :p_fecha_desde := '2026-10-01';
EXEC :p_fecha_hasta := '2026-10-12';
EXEC :p_language := 'US';
@solicitudes.sql
~~~

## Registro del ejemplo

1. Elegir una aplicación personalizada registrada, por ejemplo XXCUS; es un marcador y debe reemplazarse por la aplicación real.
2. En XML Publisher Administrator crear la **Data Definition** con código **XXFND_SOLICITUDES** y esa aplicación. Adjuntar XXFND_SOLICITUDES.xml como Data Template. Adjuntar ejemplo_solicitudes.xml como Sample Data cuando la pantalla lo permita.
3. Crear el programa concurrente con nombre corto **XXFND_SOLICITUDES**, en la misma aplicación de la definición. Seleccionar el ejecutable estándar **XDODTEXE** (motor de datos XML Publisher) y salida XML; no crear otro ejecutable con ese nombre.
4. Definir los cuatro parámetros con el orden, tokens y tipos de la tabla. Marcar todos obligatorios y usar juegos de valores compatibles. Probar primero un intervalo corto.
5. Crear una **Template** de tipo RTF vinculada a esa definición, por ejemplo código XXFND_SOLICITUDES_RTF. Cargar solicitudes.rtf y elegir idioma, territorio, fechas de vigencia y salida PDF. El código de plantilla puede diferir del código de definición.
6. Incluir el programa en el grupo de solicitudes de la responsabilidad autorizada. Enviar la solicitud y seleccionar el diseño e idioma correspondientes mediante las opciones de diseño.
7. Revisar el XML generado y el PDF. Confirmar que el servicio de posprocesamiento (OPP) está disponible si la transformación se realiza como posprocesamiento.

Para probar el diseño localmente, abrir solicitudes.rtf con Template Builder compatible con el entorno, cargar ejemplo_solicitudes.xml y previsualizar PDF. Probar además un XML con raíz XXFND_SOLICITUDES vacía: debe aparecer el mensaje sin resultados. Los códigos FASE y ESTADO se muestran literalmente; no son traducciones funcionales.

## Diagnóstico

**Configuración:** declarar p_application_short_name y p_data_source_code (VARCHAR2) para la definición. Declarar también p_lob_application y p_lob_code (VARCHAR2) para el archivo a revisar. Para el Data Template usar aplicación/código de definición; para el RTF usar los de la plantilla. Ejecutar diagnostico_configuracion.sql. Las consultas están separadas para no multiplicar plantillas por cada archivo o traducción.

La relación correcta usa DS_APP_SHORT_NAME + DATA_SOURCE_CODE: no asumir que la aplicación de la plantilla siempre coincide con la de la definición. XDO_LOBS distingue tipo, aplicación, código, idioma y territorio. No seleccionar arbitrariamente una fila ni confundir Data Template con RTF.

**Ejecución:** declarar p_request_id NUMBER y ejecutar diagnostico_salida.sql. Puede haber varias acciones por solicitud o ninguna; ausencia de acción no prueba un error de Publisher. Se muestran los códigos originales sin inferir que cualquier acción pertenezca a OPP. Revisar mensaje final, log, XML fuente, archivo de salida y fechas de posprocesamiento.

| Síntoma | Comprobación |
| --- | --- |
| No se genera XML | Tokens, tipos, intervalo, permisos y log del motor de datos. |
| XML vacío | Ejecutar solicitudes.sql con exactamente los mismos filtros. |
| XML correcto, PDF incorrecto | Grupo G_SOLICITUD, nombres de elementos, RTF, idioma y territorio. |
| Programa termina, transformación falla | Acciones de posprocesamiento, log de solicitud y log del servicio OPP con el administrador. |
| No aparece la plantilla | Asociación con la definición, aplicación, vigencia e idioma. |

Para transportar el componente, seguir [FNDLOAD y XDOLoader](../../Application_Server/fndload/xml_publisher.md). Los metadatos y los archivos son piezas diferentes.

## Validación y documentación

La revisión local comprueba estructura XML, correspondencia de consulta/campos y estructura básica RTF. **Pendiente ejecutar el concurrente y renderizar el RTF con el motor Publisher del entorno**; no se certifica compatibilidad de todos los parches.

- [Oracle XML Publisher Administration and Developer's Guide R12](https://docs.oracle.com/cd/B34956_01/current/acrobat/120xdoig.pdf).
- [Oracle: registro de definiciones y plantillas en EBS](https://docs.oracle.com/cd/E26401_01/doc.122/e48935/T564059T575599.htm).
- [Oracle: creación de plantillas RTF](https://docs.oracle.com/cd/E10383_01/doc/bip.1013/b40017/T421739T481157.htm).
- [XDO_TEMPLATES_B](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavaa8a-2.html), [XDO_LOBS](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav49b0.html) y [FND_CONC_PP_ACTIONS](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav034f.html).
