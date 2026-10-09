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
| [Consulta de programas concurrentes y ejecutables](Queries/FND/cp_and_executable.sql) | Consulta de datos del programa concurrente y su ejecutable, con filtros por idioma, nombre técnico, nombre visible e identificador del programa. |

### Estructura actual

```text
ORACLE_EBS_TECHNICAL/
├── README.md
└── Queries/
    └── FND/
        └── cp_and_executable.sql
```

## Cómo utilizar los recursos

1. Selecciona el recurso y revisa su descripción, parámetros y requisitos.
2. Comprueba que los objetos y permisos necesarios estén disponibles en tu entorno de Oracle EBS.
3. Configura los parámetros según la herramienta de ejecución utilizada.
4. Valida el comportamiento y los resultados en un entorno de desarrollo o pruebas antes de utilizarlo en producción.

Para la consulta actual se necesita acceso a los objetos FND referenciados. Si se ejecuta con SQL*Plus, las variables bind deben declararse aunque se utilice `NULL` para omitir un filtro.

## Evolución y contribuciones

Las mejoras, correcciones y nuevos ejemplos pueden proponerse mediante issues o pull requests.

Cada nuevo recurso debería incluir su propósito, requisitos, parámetros, ejemplo de uso y versiones en las que fue probado. Los ejemplos deben utilizar datos ficticios y omitir credenciales o información de clientes.

## Autor

**Freddy E. Aparicio M.** · [Fredderik](https://github.com/Fredderik)
