# Diagnóstico de concurrentes

Autor: Freddy E. Aparicio M. · Versión 1.0 · 12/10/2026.

Consultas de lectura para Oracle EBS R12.1/R12.2. Usan tablas base, parámetros explícitos y sintaxis Oracle tradicional. No inicializan contexto ni modifican solicitudes.

## Recorrido de análisis

1. Ejecutar [analisis_solicitud.sql](analisis_solicitud.sql): programa, ejecutable, fuente registrada, usuario, responsabilidad, fase, estado, tiempos y archivos. Declarar sus tres parámetros: solicitud, idioma y grupo de seguridad. La fuente registrada es la configuración actual, no una copia del ejecutable usado históricamente.
2. Ejecutar [jerarquia_solicitudes.sql](jerarquia_solicitudes.sql) para ver hijos y padres. Las dos consultas incluyen la solicitud inicial. Un límite de niveles puede ocultar descendientes o ancestros; ampliarlo de forma deliberada. Una solicitud padre puede esperar a sus hijos.
3. Si está pendiente, revisar retención, fecha programada, prioridad y estado en [gestor_solicitud.sql](gestor_solicitud.sql). Revisar además especialización, turnos, disponibilidad y configuración del gestor desde las pantallas de administración.
4. Usar [incompatibilidades.sql](incompatibilidades.sql) para identificar reglas y solicitudes en fase R del programa incompatible. Una coincidencia es una candidata, no una prueba del motivo de espera: intervienen dominio, alcance de la regla y ejecución exclusiva. Sin filas significa que no se encontró una regla para ese programa; no demuestra ausencia de otros motivos.
5. Si está ejecutándose, contrastar el log, el inicio real y los identificadores registrados con el DBA. Tiempo transcurrido no equivale a tiempo de CPU ni demuestra bloqueo.
6. Si finalizó pero falla la salida, usar [diagnostico_salida.sql](../../reportes/XML_Publisher/diagnostico_salida.sql) y la [guía XML Publisher](../../reportes/XML_Publisher/README.md).

## Parámetros de los archivos nuevos

| Archivo | Parámetros obligatorios | Resultado |
| --- | --- | --- |
| jerarquia_solicitudes.sql | p_request_id NUMBER; p_max_niveles NUMBER, entero positivo | Descendientes y ancestros; nivel 1 = solicitud inicial. |
| incompatibilidades.sql | p_request_id NUMBER | Una fila por regla/candidata; conserva reglas sin candidata en ejecución. |
| gestor_solicitud.sql | p_request_id NUMBER; p_language VARCHAR2, por ejemplo US | Una fila por solicitud, aunque no tenga gestor o traducción. |

Ejemplo SQL*Plus; cambiar 123456 por una solicitud real:

~~~sql
VARIABLE p_request_id NUMBER
VARIABLE p_max_niveles NUMBER
VARIABLE p_language VARCHAR2(10)
EXEC :p_request_id := 123456;
EXEC :p_max_niveles := 10;
EXEC :p_language := 'US';
@jerarquia_solicitudes.sql
@incompatibilidades.sql
@gestor_solicitud.sql
~~~

Ejecutar desde esta carpeta. Cada separador / ejecuta la consulta que lo precede; no añadir punto y coma antes de él.

## Interpretación del gestor y la sesión

CONTROLLING_MANAGER enlaza con CONCURRENT_PROCESS_ID. El registro de proceso puede ser histórico. Los contadores de la cola y su configuración no prueban que un proceso esté vivo ni cuántos trabajadores están libres.

ORACLE_SESSION_ID de la solicitud contiene AUDSID, **no SID**. ORACLE_PROCESS_ID de la solicitud corresponde al identificador de proceso Oracle registrado; no confundirlo con el identificador interno guardado en el registro del gestor. La solicitud y el gestor pueden tener sesiones distintas. El método de ejecución puede abrir conexiones adicionales.

Estas consultas respetan el uso de tablas base: muestran identificadores, pero no consultan vistas dinámicas de sesiones ni determinan SQL activo, espera o bloqueador. Para esa comprobación el DBA debe correlacionar instancia, AUDSID, proceso, estado actual y hora; los identificadores pueden reutilizarse. No cancelar ni reiniciar procesos basándose solo en un identificador histórico.

## Verificación y referencias

Revisados estructura, claves y filtros. Pendiente ejecutar contra Oracle EBS y validar los códigos/configuración del entorno.

- [FND_CONCURRENT_PROGRAM_SERIAL: reglas recíprocas de incompatibilidad](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavf056-2.html).
- [FND_CONCURRENT_PROCESSES: procesos de gestores](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav1fcb-2.html).
- [FND_CONCURRENT_QUEUES: configuración y contadores](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav5db9.html).
- [Código Oracle FND_CONCURRENT: registro de AUDSID y procesos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnava2c4-9.html).
