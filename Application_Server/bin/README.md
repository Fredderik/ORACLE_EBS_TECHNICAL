# bin — ejemplo de programa Host

Autor: **Freddy E. Aparicio M.** · Versión **1.0** · Fecha: **10/10/2026**.

[XX_EJEMPLO_HOST.prog](XX_EJEMPLO_HOST.prog) es un shell Bash para EBS R12: log, variables, condicionales, bucle, SQL*Plus, Java y SFTP. [EjemploBasico.java](EjemploBasico.java) es la clase auxiliar.

## Modos y alcance

**SIMULAR**, predeterminado, muestra el flujo sin ejecutar integraciones. **REAL** consulta la fecha de Oracle, ejecuta Java y envía un texto ficticio por SFTP. El primer fallo detiene los pasos posteriores. No tiene reintentos ni compensa efectos externos; repetir REAL puede enviar otro archivo.

## Formato UNIX y permisos

Guarda el shell en **UTF-8 sin BOM y finales de línea UNIX (LF)**, con el shebang como primera línea. CRLF puede producir errores de intérprete y caracteres ^M. La extensión .prog corresponde al mecanismo Host de EBS.

En una copia de despliegue del servidor:

~~~bash
file XX_EJEMPLO_HOST.prog
# Convertir si el archivo tiene CRLF.
dos2unix XX_EJEMPLO_HOST.prog
head -1 XX_EJEMPLO_HOST.prog
bash -n XX_EJEMPLO_HOST.prog
chmod 750 XX_EJEMPLO_HOST.prog
~~~

En VS Code selecciona LF y UTF-8; en Notepad++ convierte a UNIX (LF) y UTF-8 sin BOM. Revisa la codificación además de ejecutar dos2unix. El repositorio fija LF mediante .gitattributes.

Los permisos **750** requieren un propietario/grupo adecuados para que la cuenta del Concurrent Manager pueda leer y ejecutar. Revisa también los directorios padre. El administrador debe asignar el propietario y grupo de aplicaciones de esa instalación cuando corresponda; no se necesitan permisos 777.

Comprueba que Bash esté en /bin/bash. No lo ejecutes con sh si ese intérprete no es Bash. No uses bash -x: los argumentos Host pueden contener credenciales.

## Despliegue y enlace simbólico

Ejemplo para una aplicación personalizada XXCUS ya registrada y con XXCUS_TOP definido. Sustituye el producto por el real. Esta carpeta del repositorio no es el bin físico de EBS.

~~~bash
: "${XXCUS_TOP:?Carga el entorno de la aplicación personalizada}"
: "${FND_TOP:?Carga el entorno EBS}"
: "${APPLBIN:?Comprueba APPLBIN}"

# Desde la raíz de la copia del repositorio.
cp Application_Server/bin/XX_EJEMPLO_HOST.prog "$XXCUS_TOP/$APPLBIN/"
chmod 750 "$XXCUS_TOP/$APPLBIN/XX_EJEMPLO_HOST.prog"

# El enlace sin extensión apunta a fndcpesr, NO al archivo .prog.
test -x "$FND_TOP/$APPLBIN/fndcpesr" || exit 1
cd "$XXCUS_TOP/$APPLBIN" || exit 1
ln -s "$FND_TOP/$APPLBIN/fndcpesr" XX_EJEMPLO_HOST
ls -l XX_EJEMPLO_HOST XX_EJEMPLO_HOST.prog
readlink XX_EJEMPLO_HOST
~~~

Si el enlace ya existe, inspecciónalo antes de reemplazarlo; no se fuerza su sustitución.

Registra el ejecutable con método **Host**, aplicación **XXCUS** y archivo de ejecución **XX_EJEMPLO_HOST**, sin extensión. Crea el concurrente asociado y asígnalo al grupo de solicitudes. Define un parámetro de carácter **Modo**, con valores SIMULAR y REAL y valor predeterminado SIMULAR.

| Posición Host | Contenido |
| --- | --- |
| $1 | Conexión EBS; este ejemplo no la imprime ni utiliza. |
| $2 | ID de usuario. |
| $3 | Nombre de usuario; no se registra. |
| $4 | ID de solicitud. |
| $5 | Primer parámetro propio: modo. |

SQL utiliza un wallet independiente, no la conexión recibida ni un contexto de responsabilidad. Consulta solamente DUAL. Para consultas funcionales o APIs, define los parámetros y contexto correspondientes.

En R12.2 coordina la copia y el enlace con la edición, filesystem y ciclo de despliegue de tu instalación. fs1 no siempre es run. Verifica cada nodo donde pueda ejecutar el Concurrent Manager.

## Simulación y log

Desde la raíz del repositorio en UNIX:

~~~bash
bash Application_Server/bin/XX_EJEMPLO_HOST.prog --local SIMULAR \
  > ejemplo_host.log 2>&1
estado=$?
cat ejemplo_host.log
printf 'Código de salida: %s\n' "$estado"
~~~

Desde EBS envía el concurrente en SIMULAR y revisa el log. La función registrar usa stdout y los errores usan stderr; SQL y Java también escriben su salida allí. No es necesario abrir directamente FCP_LOG ni asumir una ruta.

## SQL y Java para REAL

Configura un **Secure External Password Store** de Oracle para la cuenta del servicio. EJEMPLO_SQL_ALIAS debe coincidir con el alias de red y la credencial del wallet. Prueba sqlplus -L /@XX_EJEMPLO_DB desde esa cuenta. El script no crea wallets ni almacena contraseñas.

Compila con un JDK compatible con el Java de ejecución; no sustituyas el Java certificado de EBS por el de tu equipo.

~~~bash
: "${XXCUS_TOP:?Carga el entorno de la aplicación personalizada}"
mkdir -p "$XXCUS_TOP/java/ejemplo_host"
javac -encoding UTF-8 -d "$XXCUS_TOP/java/ejemplo_host" \
  Application_Server/bin/EjemploBasico.java

export EJEMPLO_SQL_ALIAS=XX_EJEMPLO_DB
export EJEMPLO_JAVA_CP="$XXCUS_TOP/java/ejemplo_host"
# Usar el Java compatible con la instalación.
export EJEMPLO_JAVA_BIN=java
"$EJEMPLO_JAVA_BIN" -cp "$EJEMPLO_JAVA_CP" EjemploBasico LOCAL
~~~

El SQL configura WHENEVER SQLERROR y WHENEVER OSERROR con salida de fallo y rollback. También se revisan errores SP2-: los errores propios de comandos SQL*Plus no siempre activan WHENEVER SQLERROR. No contiene DML.

## SFTP para REAL

Configura el alias SSH para la **cuenta del servicio**, por ejemplo en ~/.ssh/config:

~~~sshconfig
Host destino-ejemplo
    HostName sftp.ejemplo.invalid
    User usuario_transferencia
    Port 22
    IdentityFile ~/.ssh/id_ed25519_ebs
    IdentitiesOnly yes
    BatchMode yes
    StrictHostKeyChecking yes
~~~

Host y usuario son ficticios. Autoriza la clave pública en destino y verifica la clave del servidor por un canal fiable antes de registrarla en known_hosts. Una clave privada con frase de paso necesita un agente o mecanismo no interactivo aprobado para el servicio.

~~~bash
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config" "$HOME/.ssh/id_ed25519_ebs"
# Si existe:
chmod 600 "$HOME/.ssh/known_hosts"

export EJEMPLO_SFTP_ALIAS=destino-ejemplo
export EJEMPLO_SFTP_DIR=/entrada/pruebas
~~~

El directorio remoto debe existir y permitir escritura. El ejemplo admite solo letras, números, _, ., / y - en esa ruta para simplificar el lote SFTP. No desactiva la verificación del servidor ni introduce contraseñas en el shell.

Se envía un texto ficticio con nombre formado por solicitud, fecha y PID. No se transfieren logs SQL ni datos de negocio. No implementa idempotencia o publicación atómica para una integración productiva.

## Ejecución REAL

Una vez configuradas las dependencias:

~~~bash
bash Application_Server/bin/XX_EJEMPLO_HOST.prog --local REAL \
  > ejemplo_host_real.log 2>&1
estado=$?
cat ejemplo_host_real.log
printf 'Código de salida: %s\n' "$estado"
~~~

Para ejecutar desde EBS, las variables deben existir en el entorno del Concurrent Manager: exportarlas en tu terminal no modifica un gestor ya iniciado. Se crea un directorio temporal privado y se eliminan sus archivos al terminar; el archivo remoto permanece en destino.

## Validación y referencias

La clase Java se compiló con JDK 21 y se comprobó con LOCAL, ID numérico y entrada inválida. Esto no certifica compatibilidad con el JDK de EBS: compila con el JDK de tu instalación. Se revisaron estáticamente el shell, los finales LF y los enlaces. Bash no pudo iniciarse en el entorno Windows de revisión; quedan pendientes bash -n y la simulación en UNIX.

No se han ejecutado integraciones contra EBS ni un servidor SFTP real. La validación integral requiere Oracle, wallet, Java y destino SFTP configurados.

- [Oracle EBS: Host, parámetros y fndcpesr](https://docs.oracle.com/cd/E26401_01/doc.122/e22953/T174296T575591.htm).
- [Oracle: Secure External Password Store](https://docs.oracle.com/cd/B19306_01/network.102/b14266/cnctslsh.htm).
- [SQL*Plus: WHENEVER SQLERROR](https://docs.oracle.com/en/database/oracle/oracle-database/18/sqpug/WHENEVER-SQLERROR.html).
- [OpenSSH: sftp](https://man.openbsd.org/sftp) y [ssh_config](https://man.openbsd.org/ssh_config).

Historial: 10/10/2026 — versión 1.0, creación.

[Servidor de aplicaciones](../README.md) · [Inicio](../../README.md)
