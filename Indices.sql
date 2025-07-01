--Consulta 1
CREATE INDEX idx_reserva_idcancha_estado_fecha 
ON reserva(idcancha, estado, fecha);

--Consulta 2
CREATE INDEX idx_reserva_dni_horainicio_horafin 
ON reserva(dni, horainicio, horafin);

--Consulta 3
CREATE INDEX idx_pago_fechapago_monto 
ON pago(fechapago, monto);

--Consulta 4
CREATE INDEX idx_reserva_estado_idcancha 
ON reserva(estado, idcancha);
