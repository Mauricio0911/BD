--lo que necesitas hacer para el proyecto:
--generar 4 schenmas con el nombre de:
-- -experimento1
-- -experimento2
-- -experimento3
-- -experimento4

--posterior crear las tablas en cada una de ellas:

--tomo el experimento 1
--genero las canchas de nuestro proyecto
INSERT INTO experimento1.Cancha (IdCancha, Deporte, Ubicacion)
VALUES 
  ('C001', 'Futsal', 'Campo Norte'),
  ('C002', 'Futsal', 'Campo Sur'),
  ('C003', 'Futsal', 'Campo Este'),
  ('C004', 'Vóley', 'Zona Oeste'),
  ('C005', 'Vóley', 'Zona Central'),
  ('C006', 'Básquet', 'Polideportivo Principal');

--ahora genero los datos 1k con:
DECLARE
  i INT;
  uid TEXT;
  dni TEXT;
  nombre TEXT;
  email TEXT;
  tipo TEXT;
  idres TEXT;
  idpago TEXT;
  idcancha TEXT;
  hora_ini TIME;
  hora_fin TIME;
  estados TEXT[] := ARRAY['pendiente', 'pagado', 'cancelado'];
BEGIN
  FOR i IN 1..1000 LOOP
    -- Identificadores básicos
    uid := 'U' || LPAD(i::text, 5, '0');
    dni := 'DNI' || LPAD(i::text, 8, '0');
    nombre := 'Usuario' || i;
    email := 'usuario' || i || '@correo.com';
    
    -- Determinar tipo de usuario
    tipo := CASE
              WHEN i % 3 = 0 THEN 'administrador'
              WHEN i % 3 = 1 THEN 'socio'
              ELSE 'externo'
            END;

    -- Insertar usuario base
    INSERT INTO experimento1.Usuario (IdUsuario, DNI, Nombre, Email, TipoUsuario)
    VALUES (uid, dni, nombre, email, tipo);

    -- Insertar según tipo
    IF tipo = 'socio' THEN
      INSERT INTO experimento1.Socio (IdUsuario, TipoMembresia, FechaAfiliacion)
      VALUES (uid, 'Plata', current_date - (i % 300));
    ELSIF tipo = 'externo' THEN
      INSERT INTO experimento1.Externo (IdUsuario, Telefono)
      VALUES (uid, 900000000 + i);
    ELSE
      INSERT INTO experimento1.Administrador (IdUsuario, Cargo, FechaIngreso)
      VALUES (uid, 'Asistente', current_date - (i % 100));
    END IF;

    -- Solo socios y externos pueden hacer reservas
    IF tipo IN ('socio', 'externo') THEN
      idres := 'R' || LPAD(i::text, 6, '0');
      
      -- Asegurar IdCancha válida (C001 - C005)
      idcancha := 'C00' || ((i % 5) + 1);

      -- Horarios controlados para no pasar de 23:00
      hora_ini := TIME '08:00' + ((i % 10) * INTERVAL '1 hour');
      hora_ini := LEAST(hora_ini, TIME '22:00');
      hora_fin := hora_ini + INTERVAL '1 hour';

      -- Insertar reserva
      INSERT INTO experimento1.Reserva (
        IdReserva, IdCancha, DNI,
        IdSocio, IdExterno, Fecha, HoraInicio, HoraFin, Estado
      )
      VALUES (
        idres,
        idcancha,
        dni,
        CASE WHEN tipo = 'socio' THEN uid ELSE NULL END,
        CASE WHEN tipo = 'externo' THEN uid ELSE NULL END,
        current_date - (i % 30),
        hora_ini,
        hora_fin,
        estados[(i % 3) + 1]
      );

      -- Insertar pago si no está cancelado
      IF (i % 3) <> 0 THEN
        idpago := 'P' || LPAD(i::text, 6, '0');
        INSERT INTO experimento1.Pago (IdPago, IdReserva, Monto, Estado, MedioPago, FechaPago)
        VALUES (
          idpago,
          idres,
          30 + (i % 20),
          'confirmado',
          CASE WHEN i % 2 = 0 THEN 'efectivo' ELSE 'tarjeta' END,
          current_date - (i % 30)
        );
      END IF;
    END IF;
  END LOOP;
END $$;

--Consulta normal:

--consulta plan de ejecucion_
EXPLAIN ANALYZE
SELECT
  c.idcancha,
  c.deporte,
  ROUND(
    COUNT(r.idreserva)::NUMERIC / GREATEST(
      (MAX(r.fecha) - MIN(r.fecha)) + 1, 1
    ), 2
  ) AS reservas_por_dia
FROM experimento1.cancha c
LEFT JOIN experimento1.reserva r
  ON c.idcancha = r.idcancha
     AND r.estado <> 'cancelado'
GROUP BY c.idcancha, c.deporte
ORDER BY reservas_por_dia DESC
LIMIT 5;

--sin indice: no se coloca nada mas
--con indice:
creamos el indice:
CREATE INDEX idx_exp1_reserva_cancha_estado_fecha
ON experimento1.reserva(idcancha, estado, fecha);

--y corremos esto:
EXPLAIN ANALYZE
SELECT
  c.idcancha,
  c.deporte,
  ROUND(
    COUNT(r.idreserva)::NUMERIC / GREATEST(
      (MAX(r.fecha) - MIN(r.fecha)) + 1, 1
    ), 2
  ) AS reservas_por_dia
FROM experimento1.cancha c
LEFT JOIN experimento1.reserva r
  ON c.idcancha = r.idcancha
     AND r.estado <> 'cancelado'
GROUP BY c.idcancha, c.deporte
ORDER BY reservas_por_dia DESC
LIMIT 5;


--ahora para experimento de 10k
--vamos a experimento2 y agregamos nuestras canchas
INSERT INTO experimento2.Cancha (IdCancha, Deporte, Ubicacion)
VALUES 
  ('C001', 'Futsal', 'Campo Norte'),
  ('C002', 'Futsal', 'Campo Sur'),
  ('C003', 'Futsal', 'Campo Este'),
  ('C004', 'Vóley', 'Zona Oeste'),
  ('C005', 'Vóley', 'Zona Central'),
  ('C006', 'Básquet', 'Polideportivo Principal');

-- Verifica que el tipo de IdUsuario sea suficientemente largo
ALTER TABLE experimento2.Usuario
ALTER COLUMN IdUsuario TYPE VARCHAR(10);

--sigo con los 1k del experimento 1 para ver consulta3
--consulta3:
SELECT
  c.idcancha,
  SUM(p.monto) AS ingresos_totales
FROM cancha c
JOIN reserva r ON c.idcancha = r.idcancha
JOIN pago p ON r.idreserva = p.idreserva
WHERE p.fechapago BETWEEN '2025-01-01' AND '2025-06-30'
GROUP BY c.idcancha
ORDER BY ingresos_totales DESC
LIMIT 5;









SET search_path TO experimento2;

-- Ahora generar los 10,000 datos:
DO $$
DECLARE
  i INT;
  uid TEXT;
  dni TEXT;
  nombre TEXT;
  email TEXT;
  tipo TEXT;
  idres TEXT;
  idpago TEXT;
  idcancha TEXT;
  hora_ini TIME;
  hora_fin TIME;
  estados TEXT[] := ARRAY['pendiente', 'pagado', 'cancelado'];
BEGIN
  FOR i IN 1..9999 LOOP
    uid := 'U' || LPAD(i::text, 4, '0');
    dni := 'DNI' || LPAD(i::text, 8, '0');
    nombre := 'Usuario' || i;
    email := 'usuario' || i || '@correo.com';
    tipo := CASE
              WHEN i % 3 = 0 THEN 'administrador'
              WHEN i % 3 = 1 THEN 'socio'
              ELSE 'externo'
            END;

    BEGIN
      INSERT INTO experimento2.Usuario (IdUsuario, DNI, Nombre, Email, TipoUsuario)
      VALUES (uid, dni, nombre, email, tipo);
    EXCEPTION WHEN OTHERS THEN
      -- Si ya existe el usuario, pasa al siguiente
      CONTINUE;
    END;

    IF tipo = 'socio' THEN
      BEGIN
        INSERT INTO experimento2.Socio (IdUsuario, TipoMembresia, FechaAfiliacion)
        VALUES (uid, 'Plata', current_date - (i % 300));
      EXCEPTION WHEN OTHERS THEN
        CONTINUE;
      END;
    ELSIF tipo = 'externo' THEN
      BEGIN
        INSERT INTO experimento2.Externo (IdUsuario, Telefono)
        VALUES (uid, 900000000 + i);
      EXCEPTION WHEN OTHERS THEN
        CONTINUE;
      END;
    ELSE
      BEGIN
        INSERT INTO experimento2.Administrador (IdUsuario, Cargo, FechaIngreso)
        VALUES (uid, 'Asistente', current_date - (i % 100));
      EXCEPTION WHEN OTHERS THEN
        CONTINUE;
      END;
    END IF;

    IF tipo IN ('socio', 'externo') THEN
      idres := 'R' || LPAD(i::text, 6, '0');
      idcancha := 'C00' || ((i % 6) + 1);  -- Asegúrate que existan C001 a C006
      hora_ini := TIME '08:00' + ((i % 10) * INTERVAL '1 hour');
      hora_ini := LEAST(hora_ini, TIME '22:00');
      hora_fin := hora_ini + INTERVAL '1 hour';

      BEGIN
        INSERT INTO experimento2.Reserva (
          IdReserva, IdCancha, DNI,
          IdSocio, IdExterno, Fecha, HoraInicio, HoraFin, Estado
        )
        VALUES (
          idres,
          idcancha,
          dni,
          CASE WHEN tipo = 'socio' THEN uid ELSE NULL END,
          CASE WHEN tipo = 'externo' THEN uid ELSE NULL END,
          current_date - (i % 30),
          hora_ini,
          hora_fin,
          estados[(i % 3) + 1]
        );
      EXCEPTION WHEN OTHERS THEN
        CONTINUE;
      END;

      IF (i % 3) <> 0 THEN
        idpago := 'P' || LPAD(i::text, 6, '0');
        BEGIN
          INSERT INTO experimento2.Pago (IdPago, IdReserva, Monto, Estado, MedioPago, FechaPago)
          VALUES (
            idpago,
            idres,
            30 + (i % 20),
            'confirmado',
            CASE WHEN i % 2 = 0 THEN 'efectivo' ELSE 'tarjeta' END,
            current_date - (i % 30)
          );
        EXCEPTION WHEN OTHERS THEN
          CONTINUE;
        END;
      END IF;
    END IF;
  END LOOP;
END $$;

-- pruebo consultas:
