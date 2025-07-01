--Tabla Usuario (superclase con discriminador de tipo)
CREATE TABLE Usuario (
  IdUsuario    VARCHAR(20)   PRIMARY KEY,
  DNI          VARCHAR(15)   NOT NULL UNIQUE,
  Nombre       VARCHAR(100)  NOT NULL,
  Email        VARCHAR(100)  NOT NULL UNIQUE,
  TipoUsuario  VARCHAR(15)   NOT NULL CHECK (TipoUsuario IN ('administrador','socio','externo'))
);

-- Especializaciones de Usuario
CREATE TABLE Administrador (
  IdUsuario    VARCHAR(20)   PRIMARY KEY
                 REFERENCES Usuario(IdUsuario)
                 ON DELETE CASCADE,
  Cargo        VARCHAR(50) NOT NULL,
  FechaIngreso DATE NOT NULL);
CREATE TABLE Socio (
  IdUsuario       VARCHAR(20)   PRIMARY KEY
                    REFERENCES Usuario(IdUsuario)
                    ON DELETE CASCADE,
  TipoMembresia   VARCHAR(30) NOT NULL,
  FechaAfiliacion DATE NOT NULL
);

CREATE TABLE Externo (
  IdUsuario   VARCHAR(20)   PRIMARY KEY
                REFERENCES Usuario(IdUsuario)
                ON DELETE CASCADE,
  Telefono    BIGINT        NOT NULL
);

-- 4.1.3 Tabla Cancha
CREATE TABLE Cancha (
  IdCancha   VARCHAR(10)   PRIMARY KEY,
  Deporte    VARCHAR(30)   NOT NULL,
  Ubicacion  VARCHAR(100)
);

-- 4.1.4 Tabla Bloqueo
CREATE TABLE Bloqueo (
  IdBloqueo    VARCHAR(20)   PRIMARY KEY,
  IdCancha     VARCHAR(10)   NOT NULL
                  REFERENCES Cancha(IdCancha)
                  ON DELETE CASCADE,
  Fecha        DATE          NOT NULL,
  HoraInicio   TIME          NOT NULL,
  HoraFin      TIME          NOT NULL,
  Motivo       VARCHAR(100)  NOT NULL
);

-- 4.1.5 Tabla Reserva (con DNI_Usuario)
CREATE TABLE Reserva (
  IdReserva    VARCHAR(20)   PRIMARY KEY,
  IdCancha     VARCHAR(10)   NOT NULL
                  REFERENCES Cancha(IdCancha),
  DNI VARCHAR(15)   NOT NULL
                  REFERENCES Usuario(DNI),
  -- sólo un Socio o un Externo puede solicitarla:
  IdSocio      VARCHAR(20)   NULL
                  REFERENCES Socio(IdUsuario),
  IdExterno    VARCHAR(20)   NULL
                  REFERENCES Externo(IdUsuario),
  Fecha        DATE          NOT NULL,
  HoraInicio   TIME          NOT NULL,
  HoraFin      TIME          NOT NULL,
  Estado       VARCHAR(20)   NOT NULL
                  CHECK (Estado IN ('pendiente','pagado','cancelado')),
  CONSTRAINT chk_un_solicitante
    CHECK (
      (IdSocio    IS NOT NULL AND IdExterno IS NULL) OR
      (IdSocio    IS NULL     AND IdExterno IS NOT NULL)
    )
);

-- 4.1.6 Tabla Pago
CREATE TABLE Pago (
  IdPago       VARCHAR(20)      PRIMARY KEY,
  IdReserva    VARCHAR(20)      NOT NULL
                    REFERENCES Reserva(IdReserva)
                    ON DELETE CASCADE,
  Monto        DOUBLE PRECISION NOT NULL,
  Estado       VARCHAR(20)       NOT NULL
                    CHECK (Estado IN ('pendiente','confirmado','anulado')),
  MedioPago    VARCHAR(30),
  FechaPago    DATE              NOT NULL
);