--Consulta 1:
SELECT
  c.id_cancha,
  c.deporte,
  ROUND(COUNT(r.id_reserva)::NUMERIC  / GREATEST(
        DATE_PART('day', MAX(r.fecha) - MIN(r.fecha)), 1), 2) AS reservas_por_día
FROM cancha c
LEFT JOIN reserva r
  ON c.id_cancha = r.id_cancha
     AND r.estado <> 'cancelada'
GROUP BY c.id_cancha, c.deporte
ORDER BY reservas_por-día DESC
LIMIT 5;

--Consulta 2:
SELECT
  u.id_usuario,
  u.nombre,
  SUM(
    EXTRACT(EPOCH FROM (r.hora_fin - r.hora_inicio)) / 3600
  ) AS horas_totales,
  COUNT(r.id_reserva) AS num_reservas
FROM usuario u
JOIN reserva r
  ON u.id_usuario = r.id_usuario
GROUP BY u.id_usuario, u.nombre
HAVING
  SUM(EXTRACT(EPOCH FROM (r.hora_fin - r.hora_inicio)) / 3600) > 100
  AND COUNT(r.id_reserva) >= 5
ORDER BY horas_totales DESC
LIMIT 10;

--Consulta 3:
SELECT
  c.id_cancha,
  SUM(p.monto) AS ingresos_totales
FROM cancha c
JOIN reserva r
  ON c.id_cancha = r.id_cancha
JOIN pago p
  ON r.id_reserva = p.id_reserva
WHERE p.fecha_pago BETWEEN '2025-01-01' AND '2025-06-30'
GROUP BY c.id_cancha
ORDER BY ingresos_totales DESC
LIMIT 5;

--Consulta 4:
SELECT
  id_cancha,
  ROUND(
    COUNT(*) FILTER (WHERE estado = 'cancelada')::NUMERIC
    / GREATEST(COUNT(*),1) * 100
  , 2) AS pct_cancelaciones
FROM reserva
GROUP BY id_cancha
ORDER BY pct_cancelaciones DESC
LIMIT 5;
