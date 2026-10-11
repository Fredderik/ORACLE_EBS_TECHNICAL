# Oracle EBS Technical

Recursos técnicos para el desarrollo sobre **Oracle E-Business Suite (EBS), con enfoque en la versión R12 en adelante**.

Este repositorio reúne consultas SQL, scripts, ejemplos y documentación de apoyo para comprender, desarrollar y mantener soluciones dentro de Oracle EBS. Su propósito es construir una base de conocimiento práctica que facilite el trabajo de desarrolladores y consultores técnicos, desde la consulta de metadatos hasta la creación de componentes e integraciones.

## Enfoque del repositorio

El alcance previsto abarca los principales temas del desarrollo técnico en Oracle EBS:

- **SQL y PL/SQL:** consultas, procedimientos, paquetes y utilidades de desarrollo.
- **Application Object Library (FND):** metadatos y componentes técnicos de la aplicación.
- **Programas concurrentes:** ejecutables, parámetros, solicitudes y diagnóstico de ejecución.
- **Interfaces, APIs e integraciones:** intercambio de información y procesos de carga.
- **Reportes y personalizaciones:** ejemplos y documentación para extender funcionalidades.
- **Diagnóstico y buenas prácticas:** recursos para analizar problemas y mantener desarrollos.

El contenido se incorporará progresivamente. Esta lista describe el alcance del proyecto; no todos los temas cuentan todavía con material publicado.

## Versiones objetivo

El repositorio está orientado a **Oracle EBS R12 y versiones posteriores**, incluyendo la familia **R12.1 y R12.2**. R11i queda fuera del alcance objetivo del proyecto.

La versión objetivo no implica que todos los recursos estén probados en cada versión. La compatibilidad de cada script debe verificarse según la versión de EBS, los parches instalados y los objetos disponibles en el entorno. Cuando exista una validación específica, deberá indicarse en la documentación del recurso.

## Contenido disponible

| Recurso | Descripción |
| --- | --- |
| [PO: compras](Queries/PO/README.md) | Órdenes, líneas, envíos, distribuciones y configuración de compras. |
| [AR: cuentas por cobrar](Queries/AR/README.md) | Transacciones, líneas y distribuciones; clientes y configuración de cobro. |
| [AP: cuentas por pagar](Queries/AP/README.md) | Facturas, proveedores, configuración y análisis de pagos. |
| [GL: contabilidad general](Queries/GL/README.md) | Detalle de asientos, análisis de cuenta, configuración e interfaz de importación. |
| [FND: componentes del sistema](Queries/FND/README.md) | Introducción y catálogo de consultas técnicas de FND. |
| [Servidor de aplicaciones](Application_Server/README.md) | Árbol de directorios, archivos por idioma y diferencias entre R12.1 y R12.2. |
| [Ejecutables](Queries/FND/executables.sql) | Consulta independiente de ejecutables, traducciones y método de ejecución. |
| [Programas concurrentes, ejecutables y parámetros](Queries/FND/cp_and_executable.sql) | Dos consultas: el concurrente con su ejecutable y los parámetros definidos para ese concurrente. |

### Estructura actual

```text
ORACLE_EBS_TECHNICAL/
├── README.md
├── Application_Server/
│   └── README.md
└── Queries/
    ├── AP/
    │   ├── README.md
    │   ├── facturas.sql
    │   ├── pagos.sql
    │   └── proveedores_configuracion.sql
    ├── AR/
    │   ├── README.md
    │   ├── facturas.sql
    │   └── clientes_configuracion.sql
    ├── PO/
    │   ├── README.md
    │   ├── ordenes_compra.sql
    │   └── configuracion_compras.sql
    ├── FND/
    │   ├── README.md
    │   ├── analisis_solicitud.sql
    │   ├── cp_and_executable.sql
    │   └── executables.sql
    └── GL/
        ├── README.md
        ├── asientos_detalle.sql
        ├── analisis_cuenta.sql
        ├── configuracion_gl.sql
        └── carga_gl_interface.sql
```

## Convenciones de los scripts

- Cabeceras, comentarios y mensajes propios en español.
- Autor, fecha, versión e historial conservados en cada archivo.
- Sintaxis SQL tradicional: tablas separadas por comas en `FROM` y relaciones por igualdad en `WHERE`.
- Uniones externas mediante `(+)`, incluida la condición de idioma o cualquier otra restricción de la tabla opcional.
- Variables de enlace explícitas para los filtros; nombres técnicos y códigos de Oracle conservados.

## Cómo utilizar los recursos

Las instrucciones siguientes corresponden a las consultas FND. Para GL, consulta sus [parámetros, conciliación y plantilla de carga](Queries/GL/README.md). Para AP, consulta los [parámetros y ejemplos de facturas y proveedores](Queries/AP/README.md). Para AR, consulta los [ejemplos de transacciones y configuración de clientes](Queries/AR/README.md). Para PO, consulta las [órdenes y configuración de compras](Queries/PO/README.md).

1. Selecciona el recurso y revisa su descripción, parámetros y requisitos.
2. Comprueba que los objetos y permisos necesarios estén disponibles en tu entorno de Oracle EBS.
3. Configura los parámetros según la herramienta de ejecución utilizada.
4. Valida el comportamiento y los resultados en un entorno de desarrollo o pruebas antes de utilizarlo en producción.

Los scripts utilizan nombres de tablas base y uniones explícitas con las tablas de traducciones `_TL`, sin vistas funcionales `_VL` ni valores obtenidos de `USERENV` o `FND_GLOBAL`. En R12.2, los sinónimos estándar de APPS pueden resolver internamente a vistas de edición; se mantiene ese mecanismo de EBS, que no selecciona el idioma por sesión.

**Parámetros obligatorios:** `p_language` (código de idioma instalado en EBS, por ejemplo `US`) y `p_security_group_id` (grupo de seguridad del lookup; habitualmente `0`, a verificar en el entorno). No se toman valores de la sesión. El grupo de seguridad solo interviene en la consulta del método de ejecución.

**Filtros opcionales:** se puede introducir `NULL` para omitirlos. `p_application_id` corresponde a la aplicación del ejecutable en `executables.sql`, y a la del programa concurrente en `cp_and_executable.sql`. Los demás filtros están documentados en la cabecera de cada archivo. Los nombres se comparan por igualdad exacta.

Se necesita acceso a los objetos FND referenciados. En SQL*Plus deben declararse todas las variables bind, incluso las de filtros opcionales. Ejemplo para consultar concurrentes en inglés y el grupo de seguridad estándar:

```sql
VARIABLE p_language VARCHAR2(4)
VARIABLE p_security_group_id NUMBER
VARIABLE p_application_id NUMBER
VARIABLE p_concurrent_program_name VARCHAR2(30)
VARIABLE p_user_concurrent_program_name VARCHAR2(240)
VARIABLE p_concurrent_program_id NUMBER

EXEC :p_language := 'US';
EXEC :p_security_group_id := 0;
EXEC :p_application_id := NULL;
EXEC :p_concurrent_program_name := NULL;
EXEC :p_user_concurrent_program_name := NULL;
EXEC :p_concurrent_program_id := NULL;

@Queries/FND/cp_and_executable.sql
```

Reemplaza los valores según tu búsqueda; con todos los filtros opcionales en `NULL` se consultan todos los programas del idioma seleccionado. Para `executables.sql`, declara `p_language`, `p_security_group_id`, `p_application_id`, `p_executable_id` (NUMBER), `p_executable_name` (VARCHAR2(30)) y `p_user_executable_name` (VARCHAR2(240)).

En el archivo de concurrentes, `/` ejecuta la primera consulta y separa la segunda. La primera no lleva `;` antes del slash para evitar ejecutarla dos veces en SQL*Plus. Ejecuta el archivo en modo script para obtener ambos resultados.

La segunda consulta utiliza los mismos filtros de programa e idioma y devuelve sus definiciones de parámetros, incluidos los deshabilitados. Los programas sin parámetros no generan filas en ese segundo resultado. Las consultas requieren validación de ejecución en una instancia EBS.

## Evolución y contribuciones

Las mejoras, correcciones y nuevos ejemplos pueden proponerse mediante issues o pull requests.

Cada nuevo recurso debería incluir su propósito, requisitos, parámetros, ejemplo de uso y versiones en las que fue probado. Los ejemplos deben utilizar datos ficticios y omitir credenciales o información de clientes.

## Sobre el autor

**Freddy E. Aparicio M.**

Ingeniero de Sistemas y especialista en Desarrollo de Software, con más de 10 años de experiencia profesional. Su trayectoria técnica incluye desarrollo backend y trabajo con **PL/SQL, Oracle E-Business Suite y Java**, en proyectos de desarrollo e integración.

Este repositorio busca compartir conocimientos y recursos prácticos de desarrollo sobre Oracle EBS, para apoyar a otros desarrolladores y consultores técnicos.

[Perfil profesional en LinkedIn](https://www.linkedin.com/in/freddyaparicio/) · [GitHub](https://github.com/Fredderik)
