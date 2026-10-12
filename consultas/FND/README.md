# FND — Componentes técnicos y administración de EBS

Esta carpeta reúne consultas sobre **Oracle Application Object Library (FND)** para Oracle EBS R12 en adelante.

FND proporciona servicios compartidos por los módulos de EBS: seguridad y acceso, procesamiento concurrente, perfiles y flexfields. Es parte de la infraestructura funcional y técnica que permite administrar y extender la aplicación. Véase [Oracle EBS Concepts — Application Object Library](https://docs.oracle.com/cd/E18727-01/doc.121/e12841/T120505T120508.htm).

## Qué encontrarás aquí

El enfoque de esta carpeta es la **configuración y los metadatos del sistema**. Por ejemplo, consultar cómo está registrado un concurrente, qué ejecutable utiliza y qué parámetros recibe.

Las consultas sobre facturas, pedidos o asientos contables se organizarán por su módulo de negocio. Un concurrente de esos módulos puede aparecer aquí cuando lo que se estudia es su definición técnica.

### Consultas disponibles

| Archivo | Contenido |
| --- | --- |
| [executables.sql](executables.sql) | Ejecutables registrados, traducciones y método de ejecución. |
| [cp_and_executable.sql](cp_and_executable.sql) | Dos resultados: programas concurrentes con su ejecutable; parámetros definidos para esos programas. |
| [analisis_solicitud.sql](analisis_solicitud.sql) | Análisis de una solicitud: programa, fuente, responsabilidad, usuario y duración. |

### Analizar una ejecución concurrente

[analisis_solicitud.sql](analisis_solicitud.sql) consulta una solicitud por `p_request_id`. Muestra programa, ejecutable, fuente y subrutina registradas, método de ejecución, responsabilidad, usuario, fase, estado, fechas y archivos de registro y salida.

Parámetros obligatorios: `p_request_id` (número de solicitud), `p_language` (código EBS, por ejemplo `US`) y `p_security_group_id` (grupo de los lookups, normalmente `0`). El grupo controla las descripciones de los lookups; no filtra ni autoriza el acceso a solicitudes.

Ejemplo para SQL*Plus o ejecución como script en SQL Developer; sustituye los valores por los de tu entorno:

```sql
VARIABLE p_request_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_security_group_id NUMBER
EXEC :p_request_id := 123456;
EXEC :p_language := 'US';
EXEC :p_security_group_id := 0;
@analisis_solicitud.sql
```

- `en_ejecucion_segundos/minutos`: tiempo desde el inicio real hasta la consulta, solo mientras la fase sea ejecución y no exista fecha de fin.
- `duracion_total_segundos/minutos`: diferencia entre fin e inicio reales, también para ejecuciones terminadas con error.
- Los tiempos excluyen la espera en cola, admiten duraciones superiores a 24 horas y son tiempo de reloj, no CPU. Sin inicio real devuelven `NULL`; mientras se ejecuta, el total también es `NULL`.
- La fuente corresponde a la definición actual del ejecutable. No recupera el contenido ni la versión histórica del código utilizado.
- Una traducción o metadato ausente no elimina la solicitud: se conservan sus identificadores y los campos faltantes quedan en `NULL`. Las descripciones traducidas siguen el idioma indicado.

Referencia de estructura: [Oracle eTRM — FND_CONCURRENT_REQUESTS (copia archivada)](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavbedf.html). Validación local de lógica con datos simulados; pendiente ejecución en una instancia Oracle EBS.

### Temas previstos

Usuarios y responsabilidades, menús y funciones, perfiles, lookups, flexfields y conjuntos de valores. Se incorporarán progresivamente; todavía no hay consultas para todos estos temas.

## Criterios de las consultas

- Cabecera con autor, versión, descripción, parámetros e historial.
- Cabeceras, comentarios y mensajes en español.
- Uniones por igualdad en `WHERE`, con tablas separadas por comas en `FROM`; uniones externas con `(+)`.
- Tablas base y uniones explícitas con traducciones `_TL`.
- Idioma y grupo de seguridad indicados mediante parámetros, sin obtenerlos de la sesión.
- Filtros opcionales documentados; `NULL` permite omitirlos.
- Compatibilidad y pruebas identificadas por recurso.

En R12.2, los sinónimos estándar pueden resolver a vistas de edición internas. Esto conserva el mecanismo de EBS; no equivale a usar vistas funcionales `_VL` que seleccionen el idioma de la sesión.

Consulta los [ejemplos de ejecución del repositorio](../../README.md#cómo-utilizar-los-recursos). Para ubicar los archivos físicos de los componentes, continúa con [Servidor de aplicaciones](../../Application_Server/README.md).

[Volver al inicio](../../README.md)

## Diagnóstico de concurrentes

La [guía de diagnóstico](diagnostico_concurrentes.md) complementa el análisis de una ejecución con [jerarquía de solicitudes](jerarquia_solicitudes.sql), [reglas de incompatibilidad](incompatibilidades.sql) y [gestor e identificadores de sesión](gestor_solicitud.sql). Para fallos de transformación de salida, consultar [XML/BI Publisher](../../reportes/XML_Publisher/README.md).
