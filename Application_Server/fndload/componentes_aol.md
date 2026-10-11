# Comandos FNDLOAD — componentes AOL

Autor: **Freddy E. Aparicio M.** · Versión **1.0** · Fecha: **10/10/2026**.

Ejemplos Bash para EBS R12. Ejecuta únicamente el bloque del componente elegido, después de la [preparación](README.md). Sustituye los nombres ficticios `XXCUS` y `XX_*`. Cada descarga se ejecuta en origen; su subida, en destino con el LDT transferido. `apps` solicita la contraseña de forma interactiva en las versiones que soportan esta sintaxis.

## Programa concurrente

Usa el nombre corto del programa. Revisa que el LDT contenga los parámetros SRS y las referencias necesarias; despliega también sus conjuntos de valores. El registro no transporta paquetes PL/SQL, scripts, RDF ni clases Java.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afcpprog.lct" \
  "concurrente.ldt" PROGRAM APPLICATION_SHORT_NAME="XXCUS" CONCURRENT_PROGRAM_NAME="XX_REPORTE"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afcpprog.lct" \
  "concurrente.ldt" -
```

## Ejecutable concurrente

La guía documenta el filtro EXECUTABLE_NAME. Si ese nombre existe en varias aplicaciones, inspecciona el alcance del LDT y los filtros DOWNLOAD del LCT instalado antes de cargarlo. Este comando migra el registro del ejecutable, no su código fuente.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afcpprog.lct" \
  "ejecutable.ldt" EXECUTABLE EXECUTABLE_NAME="XX_REPORTE_EXE"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afcpprog.lct" \
  "ejecutable.ldt" -
```

## Conjunto de valores — lista de valores de parámetros

Una LOV de un parámetro suele depender de un conjunto de valores. Si se valida por tabla, el LDT transporta su definición, no todas las filas de la tabla de negocio. Despliega sus tablas, vistas y datos de referencia por separado. Una LOV diseñada dentro de un formulario FMB no se migra como VALUE_SET.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afffload.lct" \
  "conjunto_valores.ldt" VALUE_SET FLEX_VALUE_SET_NAME="XX_CUENTAS_VS"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afffload.lct" \
  "conjunto_valores.ldt" -
```

## Lookup — tipo y valores

VIEW_APPSNAME corresponde a la aplicación de consulta del lookup; SECURITY_GROUP es la clave del grupo, no su ID numérico.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/aflvmlu.lct" \
  "lookup.ldt" FND_LOOKUP_TYPE VIEW_APPSNAME="XXCUS" LOOKUP_TYPE="XX_ESTADOS" SECURITY_GROUP="STANDARD"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/aflvmlu.lct" \
  "lookup.ldt" -
```

## Grupo de solicitudes

Comprueba que los programas referenciados existan en destino.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afcpreqg.lct" \
  "grupo_solicitudes.ldt" REQUEST_GROUP APPLICATION_SHORT_NAME="XXCUS" REQUEST_GROUP_NAME="XX_REPORTES"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afcpreqg.lct" \
  "grupo_solicitudes.ldt" -
```

## Registro de formulario

El FMB y el FMX requieren despliegue y compilación independientes.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afsload.lct" \
  "formulario.ldt" FORM FORM_APP_SHORT_NAME="XXCUS" FORM_NAME="XX_FORMULARIO"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afsload.lct" \
  "formulario.ldt" -
```

## Función

Verifica previamente los formularios o recursos web referenciados.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afsload.lct" \
  "funcion.ldt" FUNCTION FUNC_APP_SHORT_NAME="XXCUS" FUNCTION_NAME="XX_FUNCION"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afsload.lct" \
  "funcion.ldt" -
```

## Menú y entradas

Revisa también los submenús y funciones incluidos en el archivo.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afsload.lct" \
  "menu.ldt" MENU MENU_NAME="XX_MENU"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afsload.lct" \
  "menu.ldt" -
```

## Perfil y valores

Revisa los niveles y valores exportados: pueden contener configuración específica del origen. No presupongas que el LDT contiene solo la definición.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afscprof.lct" \
  "perfil.ldt" PROFILE APPLICATION_SHORT_NAME="XXCUS" PROFILE_NAME="XX_PERFIL"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afscprof.lct" \
  "perfil.ldt" -
```

## Mensaje

La carga actualiza el diccionario en base de datos; los archivos de mensajes de ejecución se generan por separado cuando corresponde.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afmdmsg.lct" \
  "mensaje.ldt" FND_NEW_MESSAGES APPLICATION_SHORT_NAME="XXCUS" MESSAGE_NAME="XX_MENSAJE"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afmdmsg.lct" \
  "mensaje.ldt" -
```

## Flexfield descriptivo — DFF

Revisa contextos, segmentos y conjuntos de valores dependientes.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afffload.lct" \
  "flexfield_descriptivo.ldt" DESC_FLEX APPLICATION_SHORT_NAME="XXCUS" DESCRIPTIVE_FLEXFIELD_NAME="XX_DATOS_ADICIONALES"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afffload.lct" \
  "flexfield_descriptivo.ldt" -
```

## Flexfield clave — KFF

Este filtro selecciona el flexfield, no una única estructura. Comprueba el alcance antes de cargar.

```bash
# Descargar en origen.
FNDLOAD apps 0 Y DOWNLOAD "$FND_TOP/patch/115/import/afffload.lct" \
  "flexfield_clave.ldt" KEY_FLEX APPLICATION_SHORT_NAME="XXCUS" ID_FLEX_CODE="XXK"

# Subir en destino.
FNDLOAD apps 0 Y UPLOAD "$FND_TOP/patch/115/import/afffload.lct" \
  "flexfield_clave.ldt" -
```

## Fuentes y validación

Entidades y claves contrastadas con las guías oficiales de [R12.1 — Loaders](https://docs.oracle.com/cd/E18727_01/doc.121/e12893/T174296T206863.htm) y [R12.2 — Using Loaders](https://docs.oracle.com/cd/E26401_01/doc.122/e22953/T174296T575361.htm). Las rutas deben existir en el entorno; usa el LCT estándar compatible con la instalación. No se han ejecutado cargas ni descargas en EBS.

Historial: 10/10/2026 — versión 1.0, creación del catálogo.

[Volver a FNDLOAD](README.md)
