-- archivo: clash_royale_ddl.sql
-- =========================================================
-- Esquema educativo Clash Royale
-- ---------------------------------------------------------
-- Objetivo:
--   - Base de datos sencilla pero realista para practicar consultas SQL.
--   - Modelo basado en jugadores, clanes, cartas y batallas 1v1.
--
-- Tecnologías / supuestos:
--   - MySQL 8.x (CHECK, triggers, índices funcionales, etc.).
--   - Juego de caracteres: utf8mb4.
--   - Colación: utf8mb4_spanish_ci.
--   - Motor: InnoDB.
--   - Convenciones:
--       * Esquema y tablas en minúscula + snake_case.
--       * IDs INT UNSIGNED AUTO_INCREMENT cuando procede.
-- =========================================================

-- Desactivamos notas para evitar warnings en DROP DATABASE IF EXISTS
SET @OLD_SQL_NOTES = @@sql_notes;
SET sql_notes = 0;

DROP DATABASE IF EXISTS clash_royale;

-- Restauramos notas a su valor original
SET sql_notes = @OLD_SQL_NOTES;

-- Creamos la base de datos
CREATE DATABASE clash_royale
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

-- Seleccionamos la BD
USE clash_royale;

-- Nos aseguramos de trabajar en utf8mb4 en la sesión actual
SET NAMES utf8mb4;

-- =========================================================
-- Tabla: arena
-- ---------------------------------------------------------
-- Representa las diferentes arenas del juego.
-- =========================================================
CREATE TABLE arena (
    id_arena INT UNSIGNED NOT NULL,              -- PK manual: ID estable
    nombre VARCHAR(50) NOT NULL,                 -- Nombre de la arena
    trofeos_requeridos INT UNSIGNED NOT NULL,    -- Trofeos necesarios
    PRIMARY KEY (id_arena)
) ENGINE=InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_spanish_ci;

-- =========================================================
-- Tabla: clan
-- ---------------------------------------------------------
-- Representa un clan del juego.
-- El n.º de miembros no se almacena, se calcula en vw_clan_miembros.
-- =========================================================
CREATE TABLE clan (
    id_clan INT UNSIGNED NOT NULL AUTO_INCREMENT,                 -- PK
    nombre VARCHAR(50) NOT NULL,                                  -- Nombre (único)
    descripcion VARCHAR(255),                                     -- Descripción opcional
    fecha_creacion DATE,                                          -- Fecha de creación
    tipo ENUM('Abierto','Cerrado','Con invitación') NOT NULL      -- Tipo de acceso
         DEFAULT 'Abierto',
    CONSTRAINT uc_clan_nombre UNIQUE (nombre),                    -- Nombre único
    PRIMARY KEY (id_clan)
) ENGINE=InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_spanish_ci;

-- =========================================================
-- Tabla: jugador
-- ---------------------------------------------------------
-- Representa a un jugador.
-- Puede pertenecer a un clan y tener un rol dentro del mismo.
-- =========================================================
CREATE TABLE jugador (
    id_jugador INT UNSIGNED NOT NULL AUTO_INCREMENT,  -- PK
    nombre VARCHAR(50) NOT NULL,                      -- Nombre del jugador
    nivel_rey TINYINT UNSIGNED NOT NULL,              -- Nivel de rey (1..15)
    trofeos INT UNSIGNED NOT NULL,                    -- Trofeos actuales
    fecha_creacion DATE,                              -- Fecha de alta
    id_clan INT UNSIGNED NULL,                        -- FK opcional a clan
    clan_rol VARCHAR(20),                             -- Rol en el clan
    CONSTRAINT pk_jugador PRIMARY KEY (id_jugador),
    CONSTRAINT fk_jugador_clan FOREIGN KEY (id_clan)
        REFERENCES clan(id_clan)
        ON DELETE SET NULL                            -- Si se borra el clan, queda sin clan
        ON UPDATE CASCADE,
    CONSTRAINT chk_nivel_rey CHECK (nivel_rey BETWEEN 1 AND 15)
) ENGINE=InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_spanish_ci;

-- Índice único funcional: garantiza un solo 'Líder' por clan
CREATE UNIQUE INDEX uq_un_lider_por_clan
ON jugador ( (CASE WHEN clan_rol = 'Líder' THEN id_clan ELSE NULL END) );

-- Índice típico para búsquedas por nombre
CREATE INDEX idx_jugador_nombre ON jugador(nombre);

-- =========================================================
-- Tabla: carta
-- ---------------------------------------------------------
-- Representa cada tipo de carta.
-- Incluye tipo, rareza, coste de elixir y arena de desbloqueo.
-- =========================================================
CREATE TABLE carta (
    id_carta INT UNSIGNED NOT NULL AUTO_INCREMENT,    -- PK
    nombre VARCHAR(50) NOT NULL,                      -- Nombre de la carta
    tipo VARCHAR(20) NOT NULL,                        -- 'Tropa', 'Hechizo', 'Estructura', ...
    rareza ENUM('Común','Especial','Épica','Legendaria','Campeón') NOT NULL,
    coste_elixir TINYINT UNSIGNED NOT NULL,           -- Coste de elixir (1..10)
    id_arena_desbloqueo INT UNSIGNED NOT NULL,        -- FK a arena de desbloqueo
    CONSTRAINT pk_carta PRIMARY KEY (id_carta),
    CONSTRAINT fk_carta_arena FOREIGN KEY (id_arena_desbloqueo)
        REFERENCES arena(id_arena)
        ON DELETE RESTRICT                             -- No borrar arena usada por cartas
        ON UPDATE CASCADE,
    CONSTRAINT chk_coste_elixir CHECK (coste_elixir BETWEEN 1 AND 10)
) ENGINE=InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_spanish_ci;

-- Índice para consultas por arena de desbloqueo
CREATE INDEX idx_carta_arena ON carta(id_arena_desbloqueo);

-- =========================================================
-- Tabla: jugador_carta (N:M)
-- ---------------------------------------------------------
-- Relación muchos-a-muchos entre jugador y carta.
-- =========================================================
CREATE TABLE jugador_carta (
    id_jugador INT UNSIGNED NOT NULL,         -- FK a jugador
    id_carta   INT UNSIGNED NOT NULL,         -- FK a carta
    nivel      TINYINT UNSIGNED NOT NULL,     -- Nivel de la carta
    PRIMARY KEY (id_jugador, id_carta),
    CONSTRAINT fk_jc_jugador FOREIGN KEY (id_jugador)
        REFERENCES jugador(id_jugador)
        ON DELETE CASCADE                      -- Si se borra el jugador, se borran sus cartas
        ON UPDATE CASCADE,
    CONSTRAINT fk_jc_carta FOREIGN KEY (id_carta)
        REFERENCES carta(id_carta)
        ON DELETE CASCADE                      -- Si se borra la carta, se quita de todas las colecciones
        ON UPDATE CASCADE,
    CONSTRAINT chk_nivel_carta CHECK (nivel BETWEEN 1 AND 15)
) ENGINE=InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_spanish_ci;

-- =========================================================
-- Tabla: batalla (1v1)
-- ---------------------------------------------------------
-- Representa una batalla 1 vs 1 entre dos jugadores.
-- Reglas de negocio:
--   - Jugador1 y Jugador2 deben ser distintos.
--   - Ganador es uno de ellos o NULL (empate).
--   - Empate => trofeos_ganados = 0.
--   - Victoria => trofeos_ganados > 0.
--   Estas reglas se validan con triggers BEFORE INSERT/UPDATE.
-- =========================================================
CREATE TABLE batalla (
    id_batalla INT UNSIGNED NOT NULL AUTO_INCREMENT,   -- PK
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Fecha/hora de la batalla
    id_jugador1 INT UNSIGNED NOT NULL,                 -- Primer jugador
    id_jugador2 INT UNSIGNED NOT NULL,                 -- Segundo jugador
    id_ganador  INT UNSIGNED NULL,                     -- Ganador (NULL si empate)
    trofeos_ganados INT UNSIGNED NOT NULL,             -- Trofeos ganados por el ganador
    CONSTRAINT pk_batalla PRIMARY KEY (id_batalla),
    CONSTRAINT fk_bat_j1 FOREIGN KEY (id_jugador1)
        REFERENCES jugador(id_jugador)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_bat_j2 FOREIGN KEY (id_jugador2)
        REFERENCES jugador(id_jugador)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_bat_win FOREIGN KEY (id_ganador)
        REFERENCES jugador(id_jugador)
        ON DELETE SET NULL      -- Si se borra el jugador, el histórico se mantiene con ganador NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_spanish_ci;

-- Índices para consultas habituales sobre batallas
CREATE INDEX idx_batalla_j1    ON batalla(id_jugador1);
CREATE INDEX idx_batalla_j2    ON batalla(id_jugador2);
CREATE INDEX idx_batalla_fecha ON batalla(fecha);

-- =========================================================
-- Vistas de apoyo
--   (se crean con SQL SECURITY INVOKER para respetar permisos del llamante)
-- =========================================================

-- Vista: vw_cartas_detalle
--   - Carta + arena de desbloqueo y trofeos requeridos
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_cartas_detalle AS
SELECT
    c.nombre AS carta,
    c.tipo,
    c.rareza,
    c.coste_elixir AS coste,
    a.nombre AS arena_desbloqueo,
    a.trofeos_requeridos
FROM carta c
JOIN arena a
  ON c.id_arena_desbloqueo = a.id_arena;

-- Vista: vw_jugadores_clanes
--   - Jugador + datos básicos + nombre del clan (o 'Sin clan') + rol
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_jugadores_clanes AS
SELECT
    j.nombre AS jugador,
    j.nivel_rey,
    j.trofeos,
    COALESCE(cl.nombre, 'Sin clan') AS clan,
    j.clan_rol
FROM jugador j
LEFT JOIN clan cl
  ON j.id_clan = cl.id_clan;

-- Vista: vw_batallas_info
--   - Batalla con nombres de jugadores y nombre del ganador (o 'Empate')
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_batallas_info AS
SELECT
    b.id_batalla,
    b.fecha,
    j1.nombre                      AS jugador1,
    j2.nombre                      AS jugador2,
    COALESCE(jwin.nombre, 'Empate') AS ganador,
    b.trofeos_ganados
FROM batalla b
JOIN jugador j1
  ON b.id_jugador1 = j1.id_jugador
JOIN jugador j2
  ON b.id_jugador2 = j2.id_jugador
LEFT JOIN jugador jwin
  ON b.id_ganador = jwin.id_jugador;

-- Vista: vw_cantidad_cartas_por_jugador
--   - Número de cartas distintas que tiene cada jugador
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_cantidad_cartas_por_jugador AS
SELECT
    j.id_jugador,
    j.nombre AS jugador,
    COUNT(jc.id_carta) AS cartas_totales
FROM jugador j
LEFT JOIN jugador_carta jc
  ON j.id_jugador = jc.id_jugador
GROUP BY
    j.id_jugador,
    j.nombre;

-- Vista: vw_clan_miembros
--   - N.º de miembros por clan (jugadores con id_clan no NULL)
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_clan_miembros AS
SELECT
    id_clan,
    COUNT(*) AS miembros
FROM jugador
WHERE id_clan IS NOT NULL
GROUP BY id_clan;

-- =========================================================
-- Procedimientos almacenados y triggers (lógica de negocio)
-- =========================================================

DELIMITER $$

-- ---------------------------------------------------------
-- SP: sp_registrar_batalla
-- ---------------------------------------------------------
-- Inserta una nueva batalla:
--   - La fecha se toma por defecto (CURRENT_TIMESTAMP).
--   - La coherencia se valida en los triggers de batalla.
CREATE PROCEDURE sp_registrar_batalla(
    IN p_jugador1 INT UNSIGNED,
    IN p_jugador2 INT UNSIGNED,
    IN p_ganador  INT UNSIGNED,
    IN p_trofeos  INT UNSIGNED
)
    MODIFIES SQL DATA
BEGIN
    INSERT INTO batalla (id_jugador1, id_jugador2, id_ganador, trofeos_ganados)
    VALUES (p_jugador1, p_jugador2, p_ganador, p_trofeos);
END $$

-- ---------------------------------------------------------
-- SP: sp_subir_nivel_carta
-- ---------------------------------------------------------
-- Sube el nivel de una carta para un jugador:
--   - Si no la tiene, se crea con nivel = 1.
--   - Si ya la tiene, se incrementa en 1.
CREATE PROCEDURE sp_subir_nivel_carta(
    IN p_jugador INT UNSIGNED,
    IN p_carta   INT UNSIGNED
)
    MODIFIES SQL DATA
BEGIN
    INSERT INTO jugador_carta (id_jugador, id_carta, nivel)
    VALUES (p_jugador, p_carta, 1)
    ON DUPLICATE KEY UPDATE nivel = nivel + 1;
END $$

-- ---------------------------------------------------------
-- SP: sp_crear_clan
-- ---------------------------------------------------------
-- Crea un nuevo clan y asigna a un jugador como 'Líder':
--   - Solo si el jugador existe y no pertenece ya a otro clan.
--   - Validación explícita del tipo de clan.
--   - Operación transaccional.
CREATE PROCEDURE sp_crear_clan(
    IN p_nombre        VARCHAR(50),
    IN p_descripcion   VARCHAR(255),
    IN p_tipo          VARCHAR(20),
    IN p_jugador_lider INT UNSIGNED
)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_current_clan INT UNSIGNED;
    DECLARE v_new_clan_id  INT UNSIGNED;
    DECLARE v_player_count INT;

    -- Validar tipo de clan de forma explícita para evitar valores inválidos
    IF p_tipo NOT IN ('Abierto','Cerrado','Con invitación') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tipo de clan inválido. Valores válidos: Abierto, Cerrado, Con invitación';
    END IF;

    -- Comprobar si el jugador existe y si ya pertenece a un clan
    SELECT COUNT(*), MAX(id_clan)
      INTO v_player_count, v_current_clan
      FROM jugador
     WHERE id_jugador = p_jugador_lider;

    IF v_player_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: el jugador líder no existe';
    END IF;

    IF v_current_clan IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El jugador ya pertenece a un clan; primero debe salir del clan actual';
    END IF;

    START TRANSACTION;
        INSERT INTO clan (nombre, descripcion, fecha_creacion, tipo)
        VALUES (p_nombre, p_descripcion, CURDATE(), p_tipo);

        SET v_new_clan_id = LAST_INSERT_ID();

        UPDATE jugador
           SET id_clan  = v_new_clan_id,
               clan_rol = 'Líder'
         WHERE id_jugador = p_jugador_lider;
    COMMIT;
END $$

-- ---------------------------------------------------------
-- TRIGGERS jugador: coherencia clan / rol
-- ---------------------------------------------------------
-- Reglas:
--   - Si id_clan es NULL, clan_rol debe ser NULL.
--   - Si id_clan no es NULL, clan_rol debe ser uno de:
--       'Líder','Colíder','Veterano','Miembro'.
CREATE TRIGGER trg_jugador_bi_validar_rol
BEFORE INSERT ON jugador
FOR EACH ROW
BEGIN
    IF NEW.id_clan IS NULL AND NEW.clan_rol IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Si id_clan es NULL, clan_rol debe ser NULL';
    END IF;

    IF NEW.id_clan IS NOT NULL THEN
        IF NEW.clan_rol IS NULL
           OR NEW.clan_rol NOT IN ('Líder','Colíder','Veterano','Miembro') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'clan_rol inválido o NULL cuando id_clan no es NULL';
        END IF;
    END IF;
END $$

CREATE TRIGGER trg_jugador_bu_validar_rol
BEFORE UPDATE ON jugador
FOR EACH ROW
BEGIN
    IF NEW.id_clan IS NULL AND NEW.clan_rol IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Si id_clan es NULL, clan_rol debe ser NULL';
    END IF;

    IF NEW.id_clan IS NOT NULL THEN
        IF NEW.clan_rol IS NULL
           OR NEW.clan_rol NOT IN ('Líder','Colíder','Veterano','Miembro') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'clan_rol inválido o NULL cuando id_clan no es NULL';
        END IF;
    END IF;
END $$

-- ---------------------------------------------------------
-- TRIGGERS batalla: validación de coherencia
-- ---------------------------------------------------------
-- Reglas:
--   - id_jugador1 ≠ id_jugador2.
--   - id_ganador es uno de los dos o NULL.
--   - Empate => trofeos_ganados = 0.
--   - Victoria => trofeos_ganados > 0.
CREATE TRIGGER trg_batalla_bi_validar
BEFORE INSERT ON batalla
FOR EACH ROW
BEGIN
    IF NEW.id_jugador1 = NEW.id_jugador2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un jugador no puede luchar consigo mismo';
    END IF;

    IF NEW.id_ganador IS NULL THEN
        IF NEW.trofeos_ganados <> 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Empate: trofeos_ganados debe ser 0';
        END IF;
    ELSE
        IF NEW.id_ganador NOT IN (NEW.id_jugador1, NEW.id_jugador2) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El ganador debe ser uno de los jugadores';
        END IF;

        IF NEW.trofeos_ganados <= 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Victoria: trofeos_ganados debe ser > 0';
        END IF;
    END IF;
END $$

CREATE TRIGGER trg_batalla_bu_validar
BEFORE UPDATE ON batalla
FOR EACH ROW
BEGIN
    IF NEW.id_jugador1 = NEW.id_jugador2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un jugador no puede luchar consigo mismo';
    END IF;

    IF NEW.id_ganador IS NULL THEN
        IF NEW.trofeos_ganados <> 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Empate: trofeos_ganados debe ser 0';
        END IF;
    ELSE
        IF NEW.id_ganador NOT IN (NEW.id_jugador1, NEW.id_jugador2) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El ganador debe ser uno de los jugadores';
        END IF;

        IF NEW.trofeos_ganados <= 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Victoria: trofeos_ganados debe ser > 0';
        END IF;
    END IF;
END $$

-- ---------------------------------------------------------
-- TRIGGER AFTER INSERT en batalla: actualización de trofeos
-- ---------------------------------------------------------
--   - Ganador: trofeos += trofeos_ganados.
--   - Perdedor: trofeos -= trofeos_ganados, con mínimo 0.
--   - En empates no se modifica nada.
CREATE TRIGGER trg_batalla_ai_trofeos
AFTER INSERT ON batalla
FOR EACH ROW
BEGIN
    DECLARE v_loser INT UNSIGNED;

    IF NEW.id_ganador IS NOT NULL THEN
        IF NEW.id_ganador = NEW.id_jugador1 THEN
            SET v_loser = NEW.id_jugador2;
        ELSE
            SET v_loser = NEW.id_jugador1;
        END IF;

        UPDATE jugador
           SET trofeos = trofeos + NEW.trofeos_ganados
         WHERE id_jugador = NEW.id_ganador;

        UPDATE jugador
           SET trofeos = IF(trofeos < NEW.trofeos_ganados,
                             0,
                             trofeos - NEW.trofeos_ganados)
         WHERE id_jugador = v_loser;
    END IF;
END $$

DELIMITER ;
