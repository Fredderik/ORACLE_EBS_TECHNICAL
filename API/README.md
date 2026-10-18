# API — Oracle EBS R12

Ejemplos PL/SQL de llamadas a paquetes públicos de EBS, organizados por aplicación.

| Aplicación | Contenido |
| --- | --- |
| [AP](AP/README.md) | Crear proveedores, sitios y contactos con AP_VENDOR_PUB_PKG. |
| [AR](AR/README.md) | Facturas, recibos, aplicaciones, reversión y ajustes. |
| [PER / HRMS](PER/README.md) | Empleados, asignaciones, cargos y ubicaciones. |

Las APIs ejecutan la operación durante la llamada. Cada una define sus identificadores de salida, advertencias y forma de comunicar errores; revisar el contrato documentado de AP o HRMS. Las [interfaces](../Interface/README.md) preparan datos para importación posterior. Las [consultas](../consultas/AP/README.md) permiten revisar resultados.

Usar las APIs publicadas para la versión instalada; no realizar DML directo sobre tablas funcionales. Cada ejemplo debe documentar contexto, parámetros, retorno y control de transacción. R12.1/R12.2 son versiones objetivo, no una certificación de ejecución.

[Volver al inicio](../README.md)
