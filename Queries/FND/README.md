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

### Temas previstos

Usuarios y responsabilidades, menús y funciones, perfiles, solicitudes concurrentes, lookups, flexfields y conjuntos de valores. Se incorporarán progresivamente; todavía no hay consultas para todos estos temas.

## Criterios de las consultas

- Cabecera con autor, versión, descripción, parámetros e historial.
- Tablas base y uniones explícitas con traducciones `_TL`.
- Idioma y grupo de seguridad indicados mediante parámetros, sin obtenerlos de la sesión.
- Filtros opcionales documentados; `NULL` permite omitirlos.
- Compatibilidad y pruebas identificadas por recurso.

En R12.2, los sinónimos estándar pueden resolver a vistas de edición internas. Esto conserva el mecanismo de EBS; no equivale a usar vistas funcionales `_VL` que seleccionen el idioma de la sesión.

Consulta los [ejemplos de ejecución del repositorio](../../README.md#cómo-utilizar-los-recursos). Para ubicar los archivos físicos de los componentes, continúa con [Servidor de aplicaciones](../../Application_Server/README.md).

[Volver al inicio](../../README.md)
