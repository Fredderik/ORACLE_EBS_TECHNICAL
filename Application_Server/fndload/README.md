# FNDLOAD y XDOLoader — migración de componentes

Autor: **Freddy E. Aparicio M.** · Versión **1.0** · Fecha: **10/10/2026**.

Guía de descarga y subida para Oracle EBS **R12.1 y R12.2** desde el servidor de aplicaciones UNIX/Linux. Los bloques son ejemplos independientes para ejecutar manualmente, no un despliegue automático.

| Documento | Componentes |
| --- | --- |
| [Componentes AOL](componentes_aol.md) | Concurrentes, ejecutables, conjuntos de valores, lookups, grupos de solicitudes, formularios, funciones, menús, perfiles, mensajes, DFF y KFF. |
| [XML Publisher](xml_publisher.md) | Data Definitions, metadatos de plantillas, archivos RTF, XML de ejemplo y esquemas XSD. |

## Preparación

1. Carga el entorno EBS del origen antes de descargar y el del destino antes de subir. Confirma instancia, usuario, `TWO_TASK`, `FND_TOP` y `XDO_TOP`.
2. En R12.2 coordina el filesystem y la edición con el procedimiento de despliegue y ciclo `adop` de tu instalación. No presupongas que `fs1` es siempre `run`; estos comandos no sustituyen ese procedimiento.
3. Trabaja en una carpeta de migración propia, con permisos restringidos, y transfiere los archivos al destino. No uses el directorio de los LCT como carpeta de salida.
4. Define el idioma y juego de caracteres requeridos en `NLS_LANG`. No copies un valor de otro servidor sin verificarlo.
5. Usa los LCT estándar de Oracle y revisa sus entidades/filtros para tu nivel de parches. No modifiques los LCT ni los LDT de flexfields.

Ejemplo Bash de comprobación del entorno, sin conectarse a la base:

```bash
: "${FND_TOP:?Carga primero el entorno EBS}"
: "${NLS_LANG:?Configura el idioma y juego de caracteres del entorno}"
command -v FNDLOAD
test -r "$FND_TOP/patch/115/import/afcpprog.lct"
printf 'Destino de conexión del entorno: %s\n' "${TWO_TASK:-NO_DEFINIDO}"
printf 'Idioma del cargador: %s\n' "$NLS_LANG"
```

FNDLOAD puede tomar el idioma del entorno. La convención de parámetros explícitos de las consultas SQL del repositorio no cambia el funcionamiento interno de los cargadores estándar.

## Ejecución y alcance

Los ejemplos usan nombres ficticios; reemplázalos por las claves técnicas del componente. La descarga puede sobrescribir un archivo local del mismo nombre. La subida modifica la configuración del destino y no equivale a sincronizar ni a eliminar todo lo que falta en el archivo.

En FNDLOAD, `.lct` define cómo cargar y `.ldt` contiene los datos transportados. En las subidas se usa `-` para procesar todas las entidades presentes en ese LDT. No se aplica `CUSTOM_MODE=FORCE` por defecto: una carga puede respetar reglas de propietario y fecha, por lo que hay que comprobar el resultado.

FNDLOAD con `apps` solicita la contraseña en las versiones documentadas de R12.2. Si tu versión requiere una cadena de conexión, usa el mecanismo aprobado en tu entorno; no guardes contraseñas en estos archivos. XDOLoader tiene otra interfaz de autenticación, explicada en su documento.

## Secuencia de un reporte personalizado

1. Desplegar las dependencias de código: tablas, vistas, paquetes, archivos y clases que utilice.
2. Migrar conjuntos de valores y ejecutable; después el programa concurrente con sus parámetros.
3. Migrar la Data Definition y los metadatos de plantilla; cargar el archivo RTF y los demás archivos asociados.
4. Migrar el grupo de solicitudes y los elementos de navegación necesarios.
5. Revisar cada log y verificar las definiciones desde EBS. Ejecutar el concurrente y comprobar parámetros, XML generado e informe final.

Conserva la descarga previa del destino y los logs de cada componente para poder comparar. Antes de subir, inspecciona las entidades del LDT: las dependencias pueden ampliar su alcance.

## Idiomas y archivos físicos

Un `VALUE_SET` no representa cualquier LOV de Forms. Una Data Definition tampoco contiene por sí sola el RTF ni sustituye el XML de extracción de datos. El registro del ejecutable no despliega su paquete, RDF, SQL o Java.

Los códigos de idioma de XDOLoader son distintos de los códigos de EBS: por ejemplo, `en` con territorio `US` frente al código EBS `US`. Descarga y sube cada variante lingüística que necesites.

## Referencias y validación

- [Oracle EBS R12.2 — Using Loaders](https://docs.oracle.com/cd/E26401_01/doc.122/e22953/T174296T575361.htm).
- [Oracle EBS R12.1 — Loaders](https://docs.oracle.com/cd/E18727_01/doc.121/e12893/T174296T206863.htm).
- [XML Publisher — migración entre instancias, apéndice C](https://docs.oracle.com/cd/B34956_01/current/acrobat/120xdoig.pdf).

Se revisaron las entidades y la estructura de los comandos frente a documentación de Oracle. **Pendiente ejecución en una instancia EBS**; no se han realizado cargas ni descargas reales.

Historial: 10/10/2026 — versión 1.0, creación.

[Servidor de aplicaciones](../README.md) · [Inicio](../../README.md)
