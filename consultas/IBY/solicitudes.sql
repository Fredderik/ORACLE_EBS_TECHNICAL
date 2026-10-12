/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : solicitudes.sql                                             ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Solicitudes de proceso de pago.                             ║
║  Obligatorios   :                                                             ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_payment_service_request_id (NUMBER).                                     ║
║    p_calling_app_id (NUMBER).                                                 ║
║    p_estado_solicitud (VARCHAR2(30)).                                         ║
║    p_fecha_desde (VARCHAR2(10), YYYY-MM-DD).                                  ║
║    p_fecha_hasta (VARCHAR2(10), YYYY-MM-DD).                                  ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por solicitud, incluso si aún no tiene documentos o pagos.
-- Una solicitud puede abarcar varias organizaciones; no tiene ORG_ID propio.
SELECT
    ipsr.payment_service_request_id, ipsr.calling_app_id,
    ipsr.call_app_pay_service_req_code,
    ipsr.payment_service_request_status, ipsr.process_type,
    ipsr.internal_bank_account_id, ipsr.payment_profile_id,
    ipsr.creation_date, ipsr.last_update_date, ipsr.request_id
FROM iby_pay_service_requests ipsr
WHERE 1 = 1
    AND (:p_payment_service_request_id IS NULL OR ipsr.payment_service_request_id = :p_payment_service_request_id)
    AND (:p_calling_app_id IS NULL OR ipsr.calling_app_id = :p_calling_app_id)
    AND (:p_estado_solicitud IS NULL OR ipsr.payment_service_request_status = :p_estado_solicitud)
    AND (:p_fecha_desde IS NULL OR ipsr.creation_date >= TO_DATE(:p_fecha_desde, 'YYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL OR ipsr.creation_date < TO_DATE(:p_fecha_hasta, 'YYYY-MM-DD') + 1)
ORDER BY ipsr.creation_date, ipsr.payment_service_request_id;
