# Generador de migración de un concurrente BI Publisher

Autor: **Freddy E. Aparicio M.** · Versión **1.0** · Fecha: **17/10/2026**.

[generar_migracion_bip.sql](generar_migracion_bip.sql) recibe **dos variables de enlace** y devuelve por **DBMS_OUTPUT** un shell Bash completo. El bloque PL/SQL consulta metadatos; no descarga archivos, ejecuta comandos ni modifica EBS.

| Parámetro | Tipo | Ejemplo |
| --- | --- | --- |
| p_application_short_name | VARCHAR2 | XXCUS |
| p_concurrent_program_name | VARCHAR2 | XXFND_SOLICITUDES |

La aplicación es el **nombre corto**, no APPLICATION_ID ni el nombre traducido. La comparación distingue mayúsculas/minúsculas. Debe existir una Data Definition con esa misma aplicación y código, como en la asociación estándar de concurrentes con Publisher.

## Generar el shell

En SQL Developer, declarar los dos binds, habilitar DBMS Output y ejecutar el bloque. Guardar **solo la salida**, desde la línea #!/usr/bin/env bash, en migrar_bip.sh.

Ejemplo SQL*Plus conectado a la base de origen con acceso a los metadatos APPS. Ejecutar desde la carpeta del generador o sustituir su ruta:

~~~sql
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
VARIABLE p_application_short_name VARCHAR2(50)
VARIABLE p_concurrent_program_name VARCHAR2(30)
EXEC :p_application_short_name := 'XXCUS';
EXEC :p_concurrent_program_name := 'XXFND_SOLICITUDES';
SPOOL migrar_bip.sh
@generar_migracion_bip.sql
SPOOL OFF
~~~

Verificar que no haya errores ORA-/SP2-, prompts ni texto adicional en el archivo. El generador construye todo el contenido antes de emitirlo, para evitar un shell parcialmente generado si falta una dependencia.

Guardar con finales de línea **UNIX (LF)**, sin BOM y con una codificación compatible con el servidor. No introducir contraseñas en el SQL ni en el shell.

## Descargar en origen

Cargar el entorno EBS de origen, revisar NLS_LANG, CLASSPATH, FND_TOP, XDO_TOP y TWO_TASK. Se requieren Bash y utilidades UNIX habituales, incluidos sha256sum, find y sort con soporte para separadores nulos.

~~~bash
chmod 700 migrar_bip.sh
bash -n migrar_bip.sh
bash migrar_bip.sh descargar /u01/migraciones/XXFND_SOLICITUDES_20261017
~~~

El directorio padre debe existir; el directorio final **debe ser nuevo**. No se sobrescribe un paquete anterior.

El shell pide la conexión JDBC y la contraseña APPS para XDOLoader. FNDLOAD apps solicita su contraseña en cada llamada. **TWO_TASK y JDBC deben apuntar a la misma base**; revisar ambos antes de ejecutar. No se guarda la contraseña en el paquete; XDOLoader la recibe como argumento de proceso, según la interfaz de la herramienta. No activar trazas Bash.

El paquete tendrá esta estructura:

~~~text
XXFND_SOLICITUDES_20261017/
├── migrar_bip.sh
├── ldt/
│   ├── valores_00001.ldt      # Si existen conjuntos de valores
│   ├── ejecutable.ldt        # Si no utiliza XDODTEXE estándar
│   ├── concurrente.ldt
│   ├── parametros.ldt        # Si tiene parámetros SRS
│   └── publisher.ldt
├── archivos/
│   ├── archivo_00001.xml
│   ├── archivo_00002.rtf
│   └── ...                   # Una entrada por tipo/idioma/territorio
├── logs/
│   └── descargar.XXXXXXXX/
├── SHA256SUMS
└── DESCARGA_COMPLETA
~~~

Los nombres de archivos son controlados por el generador; la correspondencia con aplicación, código, tipo, idioma y territorio queda escrita en la función procesar_componentes del shell. Conserva la extensión registrada cuando es utilizable.

XDOLoader decide el nombre físico de la descarga. Por eso cada clave se descarga en una carpeta vacía independiente, se exige exactamente un archivo no vacío y después se le asigna el nombre del paquete. Si el parche del cargador produce varios archivos o archivos auxiliares en esa carpeta, el shell se detiene para revisar el resultado; no selecciona uno arbitrariamente.

Revisar logs y LDT antes de transferir. DESCARGA_COMPLETA indica que los comandos y controles de archivos finalizaron, **no certifica el contenido funcional del paquete**.

## Instalar en destino

Transferir **todo el directorio**, conservar sus subcarpetas y cargar el entorno EBS de destino. La copia del shell dentro del paquete ya permite instalar:

~~~bash
cd /u01/migraciones/XXFND_SOLICITUDES_20261017
bash migrar_bip.sh instalar "$PWD"
~~~

La ruta indicada siempre es la raíz del paquete; puede contener espacios. El shell comprueba SHA256SUMS y todos los archivos esperados antes de comenzar las cargas. No mezcla logs de distintas ejecuciones.

Orden de carga:

1. Conjuntos de valores de parámetros, con sus padres antes que los dependientes.
2. Registro del ejecutable, cuando corresponda.
3. Programa concurrente.
4. Definición de parámetros SRS.
5. Data Definition y metadatos de plantillas.
6. Archivos de Publisher mediante XDOLoader.

Utiliza las reglas normales de FNDLOAD y **NOFORCE** en XDOLoader. No fuerza una sobrescritura ni garantiza que una versión existente sea sustituida. Revisar los logs aunque el proceso devuelva código cero; algunos rechazos u omisiones deben comprobarse allí.

Si falla una carga, se detiene. Las cargas anteriores pueden haber quedado confirmadas: **no existe una transacción única ni rollback global**. Corregir la causa y revisar lo aplicado antes de repetir.

En R12.2 seguir el procedimiento de despliegue y el ciclo adop del entorno. La carpeta es un paquete de transporte: no copia archivos directamente dentro de fs1/fs2 ni presupone cuál es el filesystem activo.

## Qué identifica automáticamente

- Concurrente y ejecutable por sus claves compuestas de aplicación.
- Parámetros de $SRS$.NOMBRE_CORTO y conjuntos de valores, incluidos los padres declarados por PARENT_FLEX_VALUE_SET_ID.
- Data Definition y **todas** sus plantillas, incluidas las de una aplicación distinta y las no vigentes. Revisar si deben transportarse todas.
- DATA_TEMPLATE, BURSTING_FILE, XML_SAMPLE y XML_SCHEMA asociados directamente.
- TEMPLATE_SOURCE de cada variante. Cuando no hay fuente para esa misma clave, conserva TEMPLATE conforme a lo registrado. No presenta un TEMPLATE compilado como si fuera un RTF fuente.
- Idioma, territorio, XDO_FILE_TYPE y FILE_CONTENT_TYPE reales del registro, sin imponer en/US ni valores de sesión.

XDODTEXE estándar debe existir en destino y no se vuelve a cargar. Si el reporte utiliza otro ejecutable se exporta su **registro**, no el código fuente. Como el filtro documentado de EXECUTABLE es su nombre, el generador rechaza nombres repetidos entre aplicaciones para evitar exportar registros ajenos.

Se detiene si faltan definición, plantillas, archivos, metadatos necesarios, el Data Template de XDODTEXE o si detecta tipos LOB no cubiertos en las plantillas. También detecta ciclos entre conjuntos padre/hijo.

## Dependencias que requieren revisión

Este paquete cubre el registro y los componentes asociados que identifica en las tablas. Antes de instalar, verificar:

- Aplicaciones registradas y objetos usados por los juegos de valores. FNDLOAD no transporta automáticamente las tablas/vistas de validación ni sus datos de negocio. Los conjuntos compartidos y sus valores pueden afectar otros programas.
- Paquetes PL/SQL, RDF, scripts Host, clases Java, permisos y sinónimos usados por el ejecutable o el Data Template.
- Subplantillas, imágenes externas, fuentes, XLIFF y otras referencias dentro del RTF/XML. No se analiza recursivamente el contenido de los documentos ni se usa XLIFFLoader.
- Destinatarios, rutas, servidores y demás configuración de bursting específicos del ambiente.
- Grupos de solicitudes, responsabilidades y acceso al concurrente en destino. No se copian asociaciones de seguridad de origen automáticamente.
- Traducciones de metadatos transportadas por FNDLOAD según sus LCT y NLS_LANG. Recorrer todos los idiomas de XDO_LOBS no garantiza por sí solo todas las traducciones AOL.
- Compatibilidad de los tipos LOB y de los LCT con los parches de origen/destino.

Después, comprobar parámetros, definición, plantillas y ejecutar una solicitud de prueba con salida PDF. Puede utilizarse el [diagnóstico XML Publisher](../../reportes/XML_Publisher/README.md).

## Verificación y referencias

Shell revisado con bash -n y pruebas con cargadores simulados: descarga, instalación, dos idiomas, nombres con espacios/comillas, archivo alterado, descarga ambigua y error de herramienta. **Pendiente compilar/ejecutar el bloque en EBS y comprobar FNDLOAD/XDOLoader reales**.

- [Oracle: FNDLOAD, concurrentes y flexfields](https://docs.oracle.com/cd/E18727_01/doc.121/e12893/T174296T206863.htm).
- [Oracle: XML Publisher, migración con FNDLOAD y XDOLoader, apéndice C](https://docs.oracle.com/cd/B34956_01/current/acrobat/120xdoig.pdf).
- [Oracle: tipos de archivo de Publisher y parámetros](https://docs.oracle.com/en-us/iaas/Content/managed-cloud-self-service/mgdcloudss_object_types_that_use_parameters.htm).

[Volver a FNDLOAD](README.md)
