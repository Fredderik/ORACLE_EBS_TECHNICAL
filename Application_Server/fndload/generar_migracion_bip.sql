/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : generar_migracion_bip.sql                                   ║
║ Autor          : Freddy E. Aparicio M.                                       ║
║ Fecha creación : 17/10/2026                                                  ║
║ Versión        : 1.0                                                        ║
║ Descripción    : Genera un shell de descarga e instalación de un reporte BIP.║
║ Parámetros obligatorios (variables de enlace VARCHAR2):                     ║
║   p_application_short_name: nombre corto de la aplicación del concurrente.  ║
║   p_concurrent_program_name: nombre corto del programa concurrente.          ║
║ Notas: solo lectura; tablas base; no requiere inicializar contexto EBS.     ║
║        La salida DBMS_OUTPUT es un shell Bash, no ejecuta los cargadores.   ║
║        Oracle EBS R12.1/R12.2; revisar parches y ejecutar en pruebas.         ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                           ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET DEFINE OFF

DECLARE
    l_aplicacion fnd_application.application_short_name%TYPE :=
        TRIM(:p_application_short_name);
    l_programa fnd_concurrent_programs.concurrent_program_name%TYPE :=
        TRIM(:p_concurrent_program_name);
    l_aplicacion_id NUMBER;
    l_ejecutable fnd_executables.executable_name%TYPE;
    l_aplicacion_ejecutable fnd_application.application_short_name%TYPE;
    l_fuente fnd_executables.execution_file_name%TYPE;
    l_metodo fnd_executables.execution_method_code%TYPE;
    l_cantidad NUMBER;
    l_indice PLS_INTEGER := 0;
    l_conjuntos PLS_INTEGER := 0;
    l_salida CLOB;
    l_posicion PLS_INTEGER;
    l_siguiente PLS_INTEGER;
    l_linea VARCHAR2(32767);
    l_archivo VARCHAR2(100);
    TYPE t_visitados IS TABLE OF VARCHAR2(1) INDEX BY VARCHAR2(40);
    l_visitados t_visitados;

    -- Se conservan los códigos de idioma/territorio de cada registro.
    -- TEMPLATE se omite únicamente cuando existe su fuente para esa variante.
    CURSOR c_archivos IS
        SELECT xl.lob_type,
               xl.application_short_name,
               xl.lob_code,
               xl.language,
               xl.territory,
               xl.xdo_file_type,
               xl.file_content_type,
               xl.file_name
        FROM xdo_lobs xl
        WHERE (
                (xl.application_short_name = l_aplicacion
                 AND xl.lob_code = l_programa
                 AND xl.lob_type IN
                     ('DATA_TEMPLATE', 'BURSTING_FILE', 'XML_SAMPLE', 'XML_SCHEMA'))
                OR EXISTS (
                    SELECT 1
                    FROM xdo_templates_b xtb
                    WHERE xtb.ds_app_short_name = l_aplicacion
                      AND xtb.data_source_code = l_programa
                      AND xtb.application_short_name = xl.application_short_name
                      AND xtb.template_code = xl.lob_code
                      AND xl.lob_type NOT IN
                          ('DATA_TEMPLATE', 'BURSTING_FILE', 'XML_SAMPLE', 'XML_SCHEMA')
                )
              )
          AND NOT (
              xl.lob_type = 'TEMPLATE'
              AND EXISTS (
                  SELECT 1
                  FROM xdo_lobs xl_fuente
                  WHERE xl_fuente.application_short_name = xl.application_short_name
                    AND xl_fuente.lob_code = xl.lob_code
                    AND xl_fuente.language = xl.language
                    AND xl_fuente.territory = xl.territory
                    AND xl_fuente.lob_type = 'TEMPLATE_SOURCE'
              )
          )
        ORDER BY xl.lob_type, xl.application_short_name, xl.lob_code,
                 xl.language, xl.territory;

    PROCEDURE agregar(p_texto VARCHAR2) IS
        l_texto VARCHAR2(32767) := p_texto || CHR(10);
    BEGIN
        DBMS_LOB.WRITEAPPEND(l_salida, LENGTH(l_texto), l_texto);
    END;

    -- Comillas simples Bash: cada valor se transmite como un único argumento.
    -- Rechazar saltos/control evita romper comentarios, líneas o manifiestos.
    FUNCTION comillas(p_texto VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_texto IS NULL OR REGEXP_LIKE(p_texto, '[[:cntrl:]]') THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Metadato vacío o con caracteres de control; revisar el componente.');
        END IF;
        RETURN CHR(39) ||
               REPLACE(p_texto, CHR(39),
                       CHR(39) || CHR(34) || CHR(39) || CHR(34) || CHR(39)) ||
               CHR(39);
    END;

    -- Exportar una sola vez cada conjunto; los padres se cargan primero.
    PROCEDURE agregar_conjunto(p_id NUMBER) IS
        l_clave VARCHAR2(40) := TO_CHAR(p_id, 'FM99999999999999999999');
        l_nombre fnd_flex_value_sets.flex_value_set_name%TYPE;
        l_padre NUMBER;
    BEGIN
        IF l_visitados.EXISTS(l_clave) THEN
            IF l_visitados(l_clave) = 'P' THEN
                RAISE_APPLICATION_ERROR(-20002, 'Ciclo entre conjuntos de valores.');
            END IF;
            RETURN;
        END IF;
        l_visitados(l_clave) := 'P';
        SELECT ffvs.flex_value_set_name, ffvs.parent_flex_value_set_id
        INTO l_nombre, l_padre
        FROM fnd_flex_value_sets ffvs
        WHERE ffvs.flex_value_set_id = p_id;
        IF l_padre IS NOT NULL THEN
            agregar_conjunto(l_padre);
        END IF;
        l_conjuntos := l_conjuntos + 1;
        agregar('  ldt ' || comillas('valores_' || TO_CHAR(l_conjuntos, 'FM00000')) ||
                ' FND afffload.lct VALUE_SET ' ||
                comillas('FLEX_VALUE_SET_NAME=' || l_nombre));
        l_visitados(l_clave) := 'C';
    END;

BEGIN
    IF l_aplicacion IS NULL OR l_programa IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Indicar aplicación y nombre corto del programa.');
    END IF;
    -- No convertir a mayúsculas: las claves se comparan exactamente.
    SELECT fa.application_id, fe.executable_name,
           fa_ejecutable.application_short_name,
           fe.execution_file_name, fe.execution_method_code
    INTO l_aplicacion_id, l_ejecutable, l_aplicacion_ejecutable, l_fuente, l_metodo
    FROM fnd_application fa,
         fnd_concurrent_programs fcp,
         fnd_executables fe,
         fnd_application fa_ejecutable
    WHERE fa.application_short_name = l_aplicacion
      AND fcp.application_id = fa.application_id
      AND fcp.concurrent_program_name = l_programa
      AND fe.application_id = fcp.executable_application_id
      AND fe.executable_id = fcp.executable_id
      AND fa_ejecutable.application_id = fe.application_id;

    SELECT COUNT(*)
    INTO l_cantidad
    FROM xdo_ds_definitions_b xddb
    WHERE xddb.application_short_name = l_aplicacion
      AND xddb.data_source_code = l_programa;
    IF l_cantidad <> 1 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'No existe una Data Definition con la aplicación y código del concurrente.');
    END IF;

    SELECT COUNT(*)
    INTO l_cantidad
    FROM xdo_templates_b xtb
    WHERE xtb.ds_app_short_name = l_aplicacion
      AND xtb.data_source_code = l_programa;
    IF l_cantidad = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'La definición no tiene plantillas asociadas.');
    END IF;

    -- Detenerse si faltan archivos, sin emitir un shell parcial.
    FOR r_plantilla IN (
        SELECT xtb.application_short_name, xtb.template_code
        FROM xdo_templates_b xtb
        WHERE xtb.ds_app_short_name = l_aplicacion
          AND xtb.data_source_code = l_programa
          AND NOT EXISTS (
              SELECT 1
              FROM xdo_lobs xl
              WHERE xl.application_short_name = xtb.application_short_name
                AND xl.lob_code = xtb.template_code
                AND xl.lob_type IN ('TEMPLATE_SOURCE', 'TEMPLATE')
          )
    ) LOOP
        RAISE_APPLICATION_ERROR(-20006,
            'Plantilla sin archivo: ' || r_plantilla.application_short_name ||
            '/' || r_plantilla.template_code);
    END LOOP;

    IF l_ejecutable = 'XDODTEXE' THEN
        SELECT COUNT(*)
        INTO l_cantidad
        FROM xdo_lobs xl
        WHERE xl.application_short_name = l_aplicacion
          AND xl.lob_code = l_programa
          AND xl.lob_type = 'DATA_TEMPLATE';
        IF l_cantidad = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'XDODTEXE requiere un Data Template.');
        END IF;
    ELSE
        -- El LCT documenta EXECUTABLE_NAME como filtro, no su aplicación.
        SELECT COUNT(*)
        INTO l_cantidad
        FROM fnd_executables fe
        WHERE fe.executable_name = l_ejecutable;
        IF l_cantidad <> 1 THEN
            RAISE_APPLICATION_ERROR(-20008,
                'Nombre de ejecutable repetido entre aplicaciones; revisar exportación manual.');
        END IF;
    END IF;

    DBMS_LOB.CREATETEMPORARY(l_salida, TRUE);
    agregar(q'~#!/usr/bin/env bash
# Autor: Freddy E. Aparicio M. | Versión 1.0 | 17/10/2026
# Uso: bash migrar_bip.sh descargar /ruta/nuevo_paquete
#      bash migrar_bip.sh instalar /ruta/paquete
set +x
set -euo pipefail
umask 077
fallar() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ $# -eq 2 ]] || fallar 'Indicar modo (descargar/instalar) y directorio del paquete.'
MODO=$1
case "$MODO" in descargar|instalar) ;; *) fallar 'Modo desconocido.' ;; esac
: "${FND_TOP:?Cargar el entorno EBS}"
: "${XDO_TOP:?Cargar el entorno EBS}"
: "${CLASSPATH:?Cargar el CLASSPATH de EBS}"
: "${NLS_LANG:?Definir el idioma y juego de caracteres del entorno}"
: "${TWO_TASK:?Confirmar la conexión del entorno EBS}"
for herramienta in FNDLOAD java sha256sum find sort xargs cp mv mktemp chmod; do
  command -v "$herramienta" >/dev/null || fallar "Falta $herramienta"
done
for lct in "$FND_TOP/patch/115/import/afcpprog.lct" \
           "$FND_TOP/patch/115/import/afffload.lct" \
           "$XDO_TOP/patch/115/import/xdotmpl.lct"; do
  [[ -r "$lct" ]] || fallar "No se puede leer $lct"
done
if [[ "$MODO" == descargar ]]; then
  mkdir -- "$2" || fallar 'El directorio debe ser nuevo; no se sobrescribe un paquete.'
else
  [[ -d "$2" ]] || fallar 'No existe el paquete.'
fi
PAQUETE=$(cd -- "$2" && pwd -P)
if [[ "$MODO" == instalar ]]; then
  [[ -s "$PAQUETE/DESCARGA_COMPLETA" && -s "$PAQUETE/SHA256SUMS" ]] ||
    fallar 'La descarga no está completa.'
  (cd "$PAQUETE" && sha256sum --check SHA256SUMS) ||
    fallar 'Faltan archivos o cambiaron después de la descarga.'
fi
if [[ "$MODO" == descargar ]]; then
  mkdir "$PAQUETE/ldt" "$PAQUETE/archivos" "$PAQUETE/logs"
else
  [[ -d "$PAQUETE/ldt" && -d "$PAQUETE/archivos" && -d "$PAQUETE/logs" ]] ||
    fallar 'Estructura de paquete incompleta.'
fi
LOGS=$(mktemp -d "$PAQUETE/logs/${MODO}.XXXXXXXX")
# FNDLOAD usa TWO_TASK; XDOLoader usa JDBC. Deben apuntar a la MISMA base.
printf 'Modo: %s | TWO_TASK: %s | Paquete: %s\n' "$MODO" "$TWO_TASK" "$PAQUETE"
read -r -p 'Conexión JDBC del mismo entorno (formato admitido por XDOLoader): ' XDO_JDBC
[[ -n "$XDO_JDBC" ]] || fallar 'Falta la conexión JDBC.'
read -r -s -p 'Contraseña APPS para XDOLoader: ' XDO_PASSWORD
printf '\n'
[[ -n "$XDO_PASSWORD" ]] || fallar 'Contraseña vacía.'
trap 'unset XDO_PASSWORD' EXIT
# La contraseña no se escribe en archivos; Java la recibe como argumento.
# FNDLOAD apps solicita su contraseña de forma interactiva en cada llamada.
# NOFORCE respeta las reglas del cargador; no garantiza reemplazar lo existente.
ldt() {
  local nombre=$1 familia=$2 configuracion=$3 entidad=$4
  shift 4
  local lct archivo="$PAQUETE/ldt/$nombre.ldt"
  case "$familia" in
    FND) lct="$FND_TOP/patch/115/import/$configuracion" ;;
    XDO) lct="$XDO_TOP/patch/115/import/$configuracion" ;;
    *) fallar 'Familia LCT desconocida.' ;;
  esac
  if [[ "$FASE" == verificar ]]; then
    [[ -s "$archivo" ]] || fallar "Falta $archivo"
    return
  fi
  mkdir "$LOGS/$nombre"
  printf 'Procesando %s. FNDLOAD solicitará la contraseña APPS.\n' "$nombre"
  if [[ "$MODO" == descargar ]]; then
    (cd "$LOGS/$nombre" &&
      FNDLOAD apps 0 Y DOWNLOAD "$lct" "$archivo" "$entidad" "$@") ||
      fallar "Falló FNDLOAD: $nombre"
    [[ -s "$archivo" ]] || fallar "No se generó $archivo"
  else
    (cd "$LOGS/$nombre" &&
      FNDLOAD apps 0 Y UPLOAD "$lct" "$archivo" -) ||
      fallar "Falló FNDLOAD: $nombre"
  fi
}
lob() {
  local nombre=$1 tipo=$2 aplicacion=$3 codigo=$4 idioma=$5 territorio=$6
  local formato=$7 contenido=$8
  local archivo="$PAQUETE/archivos/$nombre"
  if [[ "$FASE" == verificar ]]; then
    [[ -s "$archivo" ]] || fallar "Falta $archivo"
    return
  fi
  printf 'Procesando archivo %s (%s / %s / %s / %s).\n' \
    "$nombre" "$tipo" "$codigo" "$idioma" "$territorio"
  if [[ "$MODO" == descargar ]]; then
    local temporal="$LOGS/${nombre}.descarga"
    mkdir "$temporal"
    # Una carpeta vacía por clave evita colisiones entre idiomas y plantillas.
    (cd "$temporal" &&
      java oracle.apps.xdo.oa.util.XDOLoader DOWNLOAD \
        -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
        -JDBC_CONNECTION "$XDO_JDBC" -LOB_TYPE "$tipo" \
        -APPS_SHORT_NAME "$aplicacion" -LOB_CODE "$codigo" \
        -LANGUAGE "$idioma" -TERRITORY "$territorio" \
        -LOG_FILE "$LOGS/${nombre}.log") \
        >"$LOGS/${nombre}.consola.log" 2>&1 ||
      fallar "Falló XDOLoader: revisar $LOGS/${nombre}.log"
    local encontrados=() candidato
    while IFS= read -r -d '' candidato; do
      encontrados+=("$candidato")
    done < <(find "$temporal" -type f -print0)
    [[ ${#encontrados[@]} -eq 1 ]] ||
      fallar "Se esperaba exactamente un archivo para $nombre; revisar $temporal"
    [[ -s "${encontrados[0]}" && ! -L "${encontrados[0]}" ]] ||
      fallar "Archivo vacío o enlace inesperado: $nombre"
    mv -- "${encontrados[0]}" "$archivo"
  else
    java oracle.apps.xdo.oa.util.XDOLoader UPLOAD \
      -DB_USERNAME apps -DB_PASSWORD "$XDO_PASSWORD" \
      -JDBC_CONNECTION "$XDO_JDBC" -LOB_TYPE "$tipo" \
      -APPS_SHORT_NAME "$aplicacion" -LOB_CODE "$codigo" \
      -LANGUAGE "$idioma" -TERRITORY "$territorio" \
      -XDO_FILE_TYPE "$formato" -FILE_CONTENT_TYPE "$contenido" \
      -FILE_NAME "$archivo" -NLS_LANG "$NLS_LANG" \
      -OWNER CUSTOM -CUSTOM_MODE NOFORCE \
      -LOG_FILE "$LOGS/${nombre}.log" \
      >"$LOGS/${nombre}.consola.log" 2>&1 ||
      fallar "Falló XDOLoader: revisar $LOGS/${nombre}.log"
  fi
}
~');
    agregar('# Aplicación: ' || comillas(l_aplicacion));
    agregar('# Concurrente: ' || comillas(l_programa));
    agregar('# Ejecutable: ' || comillas(l_aplicacion_ejecutable || '/' || l_ejecutable));
    agregar('# Método: ' || comillas(l_metodo));
    agregar('# Fuente registrada (no se extrae su código): ' || comillas(NVL(l_fuente, '(sin fuente)')));
    agregar('procesar_componentes() {');

    FOR r_conjunto IN (
        SELECT DISTINCT fdfcu.flex_value_set_id
        FROM fnd_descr_flex_column_usages fdfcu
        WHERE fdfcu.application_id = l_aplicacion_id
          AND fdfcu.descriptive_flexfield_name = '$SRS$.' || l_programa
          AND fdfcu.flex_value_set_id IS NOT NULL
        ORDER BY fdfcu.flex_value_set_id
    ) LOOP
        agregar_conjunto(r_conjunto.flex_value_set_id);
    END LOOP;

    IF l_ejecutable <> 'XDODTEXE' THEN
        agregar('  ldt ejecutable FND afcpprog.lct EXECUTABLE ' ||
                comillas('EXECUTABLE_NAME=' || l_ejecutable));
    ELSE
        agregar('  # XDODTEXE estándar debe existir en destino; no se sobrescribe.');
    END IF;
    agregar('  ldt concurrente FND afcpprog.lct PROGRAM ' ||
            comillas('APPLICATION_SHORT_NAME=' || l_aplicacion) || ' ' ||
            comillas('CONCURRENT_PROGRAM_NAME=' || l_programa));

    SELECT COUNT(*)
    INTO l_cantidad
    FROM fnd_descr_flex_column_usages fdfcu
    WHERE fdfcu.application_id = l_aplicacion_id
      AND fdfcu.descriptive_flexfield_name = '$SRS$.' || l_programa;
    IF l_cantidad > 0 THEN
        agregar('  ldt parametros FND afffload.lct DESC_FLEX ' ||
                comillas('APPLICATION_SHORT_NAME=' || l_aplicacion) || ' ' ||
                comillas('DESCRIPTIVE_FLEXFIELD_NAME=$SRS$.' || l_programa));
    END IF;

    agregar('  ldt publisher XDO xdotmpl.lct XDO_DS_DEFINITIONS ' ||
            comillas('APPLICATION_SHORT_NAME=' || l_aplicacion) || ' ' ||
            comillas('DATA_SOURCE_CODE=' || l_programa));

    FOR r_archivo IN c_archivos LOOP
        IF r_archivo.lob_type NOT IN
           ('TEMPLATE_SOURCE', 'TEMPLATE', 'DATA_TEMPLATE',
            'BURSTING_FILE', 'XML_SAMPLE', 'XML_SCHEMA') THEN
            RAISE_APPLICATION_ERROR(-20009,
                'Tipo LOB no cubierto: ' || r_archivo.lob_type ||
                '. Revisar herramienta de migración específica.');
        END IF;
        l_indice := l_indice + 1;
        l_archivo := 'archivo_' || TO_CHAR(l_indice, 'FM00000') ||
                     NVL(REGEXP_SUBSTR(r_archivo.file_name,
                         '\.[A-Za-z0-9]{1,10}$'), '.bin');
        agregar('  lob ' || comillas(l_archivo) || ' ' ||
                comillas(r_archivo.lob_type) || ' ' ||
                comillas(r_archivo.application_short_name) || ' ' ||
                comillas(r_archivo.lob_code) || ' ' ||
                comillas(r_archivo.language) || ' ' ||
                comillas(r_archivo.territory) || ' ' ||
                comillas(r_archivo.xdo_file_type) || ' ' ||
                comillas(r_archivo.file_content_type));
    END LOOP;
    IF l_indice = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'No se encontraron archivos para exportar.');
    END IF;
    agregar('}');
    agregar(q'~
# Verificar TODOS los archivos antes de iniciar las cargas.
if [[ "$MODO" == instalar ]]; then
  FASE=verificar
  procesar_componentes
fi
FASE=ejecutar
procesar_componentes
if [[ "$MODO" == descargar ]]; then
  cp -- "$0" "$PAQUETE/migrar_bip.sh"
  chmod 700 "$PAQUETE/migrar_bip.sh"
  (cd "$PAQUETE" &&
    find ldt archivos -type f -print0 | LC_ALL=C sort -z |
    xargs -0 sha256sum > SHA256SUMS)
  printf 'Descarga terminada; revisar logs y contenido de los LDT.\n' > "$PAQUETE/DESCARGA_COMPLETA"
  printf 'Transferir el paquete completo. En destino ejecutar:\n'
  printf 'bash migrar_bip.sh instalar /ruta/del/paquete\n'
else
  printf 'Comandos finalizados. Revisar logs, objetos omitidos por NOFORCE y ejecutar el reporte en EBS.\n'
fi
printf 'Logs: %s\n' "$LOGS"
~');

    -- Emitir al final, una línea por llamada, sin partir caracteres multibyte.
    l_posicion := 1;
    WHILE l_posicion <= DBMS_LOB.GETLENGTH(l_salida) LOOP
        l_siguiente := DBMS_LOB.INSTR(l_salida, CHR(10), l_posicion);
        l_linea := DBMS_LOB.SUBSTR(l_salida, l_siguiente - l_posicion, l_posicion);
        DBMS_OUTPUT.PUT_LINE(l_linea);
        l_posicion := l_siguiente + 1;
    END LOOP;
    DBMS_LOB.FREETEMPORARY(l_salida);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF DBMS_LOB.ISTEMPORARY(l_salida) = 1 THEN
            DBMS_LOB.FREETEMPORARY(l_salida);
        END IF;
        RAISE_APPLICATION_ERROR(-20011,
            'No se encontró el programa/ejecutable o una dependencia de conjuntos de valores.');
    WHEN OTHERS THEN
        IF DBMS_LOB.ISTEMPORARY(l_salida) = 1 THEN
            DBMS_LOB.FREETEMPORARY(l_salida);
        END IF;
        RAISE;
END;
/
