--CREATE DATABASE AlGranoNic_v3;
--GO

USE AlGranoNic_v3;
GO

USE AlGranoNic_v3;
GO

-- ========================================
-- TABLA DE USUARIOS
-- ========================================
CREATE TABLE Usuario (
    usuario_id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    correo NVARCHAR(100) UNIQUE NOT NULL,
    contrasena NVARCHAR(200) NOT NULL, -- Guardar encriptada/hasheada
    rol NVARCHAR(50) DEFAULT 'Productor', -- Ejemplo: Admin, Productor, Técnico
    fecha_registro DATE DEFAULT GETDATE()
);

-- ========================================
-- TABLAS DE FINCAS Y CULTIVOS
-- ========================================
CREATE TABLE Finca (
    finca_id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    propietario NVARCHAR(100),
    ubicacion NVARCHAR(200),
    latitud DECIMAL(10,6),
    longitud DECIMAL(10,6),
    area_total DECIMAL(10,2) -- en hectáreas
);

-- Relación usuarios - fincas (muchos a muchos)
CREATE TABLE UsuarioFinca (
    usuario_finca_id INT PRIMARY KEY IDENTITY(1,1),
    usuario_id INT NOT NULL,
    finca_id INT NOT NULL,
    rol NVARCHAR(50) DEFAULT 'Propietario', -- Propietario, Administrador, Colaborador
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id),
    FOREIGN KEY (finca_id) REFERENCES Finca(finca_id)
);

CREATE TABLE Cultivo (
    cultivo_id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(200)
);

CREATE TABLE FincaCultivo (
    finca_cultivo_id INT PRIMARY KEY IDENTITY(1,1),
    finca_id INT NOT NULL,
    cultivo_id INT NOT NULL,
    area_cultivada DECIMAL(10,2),
    ciclo NVARCHAR(50), -- Ejemplo: Ciclo 2025-1
    FOREIGN KEY (finca_id) REFERENCES Finca(finca_id),
    FOREIGN KEY (cultivo_id) REFERENCES Cultivo(cultivo_id)
);

-- ========================================
-- LABORES AGRÍCOLAS
-- ========================================
CREATE TABLE LaborAgricola (
    labor_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    usuario_id INT NULL,
    tipo NVARCHAR(100), -- Ej: Preparación, Siembra
    descripcion NVARCHAR(200),
    fecha DATE NOT NULL,
    costo DECIMAL(12,2),
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id)
);

-- ========================================
-- MANEJO AGRONÓMICO
-- ========================================
CREATE TABLE ManejoAgronomico (
    manejo_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    usuario_id INT NULL,
    tipo NVARCHAR(100), -- Fertilizante, Control de Malezas
    producto NVARCHAR(100),
    cantidad DECIMAL(10,2),
    unidad NVARCHAR(20),
    fecha DATE,
    costo DECIMAL(12,2),
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id)
);

-- ========================================
-- APLICACIONES DE INSECTICIDAS Y FUNGICIDAS
-- ========================================
CREATE TABLE AplicacionAgroquimico (
    aplicacion_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    usuario_id INT NULL,
    tipo NVARCHAR(50), -- Insecticida, Fungicida
    producto NVARCHAR(100),
    dosis DECIMAL(10,2),
    unidad NVARCHAR(20),
    fecha DATE,
    costo DECIMAL(12,2),
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id)
);

-- ========================================
-- COSECHA Y POSTCOSECHA
-- ========================================
CREATE TABLE Cosecha (
    cosecha_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    usuario_id INT NULL,
    fecha DATE NOT NULL,
    cantidad DECIMAL(12,2),
    unidad NVARCHAR(20), -- Kg, qq, ton
    costo DECIMAL(12,2),
    ingreso DECIMAL(12,2),
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id)
);

-- ========================================
-- COSTOS ADICIONALES Y DEPRECIACIÓN
-- ========================================
CREATE TABLE CostoAdicional (
    costo_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    usuario_id INT NULL,
    descripcion NVARCHAR(200),
    fecha DATE,
    monto DECIMAL(12,2),
    tipo NVARCHAR(50), -- Ej: Depreciación, Mantenimiento
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id)
);

-- ========================================
-- TRANSPORTE
-- ========================================
CREATE TABLE Transporte (
    transporte_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    usuario_id INT NULL,
    fecha DATE,
    descripcion NVARCHAR(200),
    costo DECIMAL(12,2),
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuario(usuario_id)
);

-- ========================================
-- ESTADOS FINANCIEROS (OPCIONAL)
-- ========================================
CREATE TABLE EstadoFinanciero (
    estado_id INT PRIMARY KEY IDENTITY(1,1),
    finca_cultivo_id INT NOT NULL,
    ingresos DECIMAL(12,2),
    costos DECIMAL(12,2),
    utilidad DECIMAL(12,2),
    rentabilidad DECIMAL(5,2), -- en %
    fecha_generado DATE DEFAULT GETDATE(),
    FOREIGN KEY (finca_cultivo_id) REFERENCES FincaCultivo(finca_cultivo_id)
);
GO

-- ========================================
-- VISTA PARA REPORTE DE COSTOS SOLO CAFÉ
-- ========================================
CREATE VIEW ReporteCostosCafe AS
SELECT 
    fc.finca_cultivo_id,
    f.nombre AS Finca,
    c.nombre AS Cultivo,
    SUM(ISNULL(l.costo,0) + ISNULL(m.costo,0) + ISNULL(a.costo,0) + ISNULL(cs.costo,0) + ISNULL(ca.monto,0) + ISNULL(t.costo,0)) AS Costo_Total
FROM FincaCultivo fc
INNER JOIN Finca f ON fc.finca_id = f.finca_id
INNER JOIN Cultivo c ON fc.cultivo_id = c.cultivo_id
LEFT JOIN LaborAgricola l ON fc.finca_cultivo_id = l.finca_cultivo_id
LEFT JOIN ManejoAgronomico m ON fc.finca_cultivo_id = m.finca_cultivo_id
LEFT JOIN AplicacionAgroquimico a ON fc.finca_cultivo_id = a.finca_cultivo_id
LEFT JOIN Cosecha cs ON fc.finca_cultivo_id = cs.finca_cultivo_id
LEFT JOIN CostoAdicional ca ON fc.finca_cultivo_id = ca.finca_cultivo_id
LEFT JOIN Transporte t ON fc.finca_cultivo_id = t.finca_cultivo_id
WHERE c.nombre = 'Café'  -- FILTRO SOLO CAFÉ
GROUP BY fc.finca_cultivo_id, f.nombre, c.nombre;
GO