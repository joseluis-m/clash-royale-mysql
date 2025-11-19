-- archivo: clash_royale_dml.sql
-- =========================================================
-- Datos de ejemplo para el esquema Clash Royale
-- ---------------------------------------------------------
-- Objetivo:
--   - Población mínima pero rica para practicar consultas:
--       * Varias arenas.
--       * Clanes con y sin miembros.
--       * Colecciones de cartas variadas por jugador.
--       * Diferentes batallas (victoria/derrota/empate).
-- =========================================================

-- Seleccionamos la base de datos
USE clash_royale;

-- Trabajamos en una única transacción para garantizar consistencia
SET @OLD_AUTOCOMMIT = @@autocommit;
SET autocommit = 0;
START TRANSACTION;

-- =========================================================
-- Población de arenas
-- ---------------------------------------------------------
-- Nota:
--   - Los IDs de arena empiezan en 1 y se usan como referencia
--     en la tabla carta.id_arena_desbloqueo.
-- =========================================================
INSERT INTO arena (id_arena, nombre, trofeos_requeridos) VALUES
(1,  'Campo de Entrenamiento', 0),
(2,  'Estadio Duende',         0),
(3,  'Foso de Huesos',         300),
(4,  'Coliseo Bárbaro',        600),
(5,  'Valle de Hechizos',      1000),
(6,  'Taller del Constructor', 1300),
(7,  'Fuerte de la P.E.K.K.A.',1600),
(8,  'Arena Real',             2000),
(9,  'Pico Helado',            2300),
(10, 'Arena Selvática',        2600),
(11, 'Montepuerco',            3000),
(12, 'Electrovalle',           3400),
(13, 'Pueblo Espeluznante',    3800),
(14, 'Escondite de los Pillos',4200),
(15, 'Pico Sereno',            4600),
(16, 'Arena Legendaria',       5000);

-- =========================================================
-- Población de clanes
-- ---------------------------------------------------------
-- Nota:
--   - Se insertan id_clan específicos a pesar de ser AUTO_INCREMENT
--     para facilitar la comprensión y la relación con jugadores.
--   - El clan 'ClanFantasma' no tiene miembros inicialmente.
-- =========================================================
INSERT INTO clan (id_clan, nombre, descripcion, fecha_creacion, tipo) VALUES
(1, 'ClanEterno',            'Clan dedicado a las batallas legendarias', '2024-01-15', 'Abierto'),
(2, 'ArmaduraInquebrantable','Nada nos puede romper',                   '2024-05-10', 'Cerrado'),
(3, 'LaOrdenReal',           'Los guardianes del reino',                 '2025-02-20', 'Con invitación'),
(4, 'ClanFantasma',          'Este clan no tiene miembros',              '2025-08-01', 'Abierto'),
(5, 'LegendariosUnidos',     'Solo para verdaderas leyendas',            '2023-12-01', 'Abierto');

-- =========================================================
-- Población de cartas
-- ---------------------------------------------------------
-- Tipos:
--   - Comunes, Especiales, Épicas, Legendarias y Campeones.
--   - La columna id_arena_desbloqueo hace referencia a arena.id_arena (1..16).
-- =========================================================
INSERT INTO carta (id_carta, nombre, tipo, rareza, coste_elixir, id_arena_desbloqueo) VALUES
-- Comunes
(1,  'Caballero',         'Tropa',     'Común',      3,  1),
(2,  'Arqueras',          'Tropa',     'Común',      3,  1),
(3,  'Esbirros',          'Tropa',     'Común',      3,  1),
(4,  'Flechas',           'Hechizo',   'Común',      3,  1),
(5,  'Duendes',           'Tropa',     'Común',      2,  2),
(6,  'Duendes con lanza', 'Tropa',     'Común',      2,  2),
(7,  'Bombardero',        'Tropa',     'Común',      2,  3),
(8,  'Esqueletos',        'Tropa',     'Común',      1,  3),
(9,  'Cañón',             'Estructura','Común',      3,  4),
(10, 'Bárbaros',          'Tropa',     'Común',      5,  4),

-- Especiales
(11, 'Gigante',           'Tropa',     'Especial',   5,  1),
(12, 'Mosquetera',        'Tropa',     'Especial',   4,  1),
(13, 'Bola de Fuego',     'Hechizo',   'Especial',   4,  1),
(14, 'Mini P.E.K.K.A.',   'Tropa',     'Especial',   4,  1),
(15, 'Montapuercos',      'Tropa',     'Especial',   4,  5),
(16, 'Valquiria',         'Tropa',     'Especial',   4,  3),
(17, 'Choza de duendes',  'Estructura','Especial',   5,  5),
(18, 'Choza de bárbaros', 'Estructura','Especial',   7,  8),
(19, 'Lápida',            'Estructura','Especial',   3,  3),
(20, 'Recolector de elixir','Estructura','Especial', 6,  7),

-- Épicas
(21, 'P.E.K.K.A.',            'Tropa',   'Épica', 7,  5),
(22, 'Bruja',                 'Tropa',   'Épica', 5,  1),
(23, 'Bebé dragón',           'Tropa',   'Épica', 4,  1),
(24, 'Príncipe',              'Tropa',   'Épica', 5,  1),
(25, 'Ejército de esqueletos','Tropa',   'Épica', 3,  1),
(26, 'Globo bombástico',      'Tropa',   'Épica', 5,  7),
(27, 'Veneno',                'Hechizo', 'Épica', 4,  6),
(28, 'Rayo',                  'Hechizo', 'Épica', 6,  5),
(29, 'Congelación',           'Hechizo', 'Épica', 4,  5),
(30, 'Esqueleto gigante',     'Tropa',   'Épica', 6,  8),

-- Legendarias
(31, 'Princesa',          'Tropa',   'Legendaria', 3,  8),
(32, 'El Tronco',         'Hechizo', 'Legendaria', 2,  8),
(33, 'Mago de Hielo',     'Tropa',   'Legendaria', 3,  9),
(34, 'Minero',            'Tropa',   'Legendaria', 3, 10),
(35, 'Chispitas',         'Tropa',   'Legendaria', 6, 12),
(36, 'Sabueso de Lava',   'Tropa',   'Legendaria', 7, 11),
(37, 'Mega Caballero',    'Tropa',   'Legendaria', 7, 13),
(38, 'Dragón infernal',   'Tropa',   'Legendaria', 4, 10),

-- Campeones
(39, 'Reina Arquera',     'Tropa',   'Campeón',    5, 16),
(40, 'Caballero Dorado',  'Tropa',   'Campeón',    4, 16),
(41, 'Rey Esqueleto',     'Tropa',   'Campeón',    4, 16),
(42, 'Gran Minero',       'Tropa',   'Campeón',    4, 16),
(43, 'Monje',             'Tropa',   'Campeón',    5, 16);

-- =========================================================
-- Población de jugadores
-- ---------------------------------------------------------
-- Notas:
--   - id_jugador se fija explícitamente (1..12).
--   - Algunos jugadores pertenecen a clanes con distintos roles.
--   - Otros jugadores están sin clan (id_clan NULL, clan_rol NULL).
-- =========================================================
INSERT INTO jugador (id_jugador, nombre, nivel_rey, trofeos, fecha_creacion, id_clan, clan_rol) VALUES
(1,  'ReyDelElixir',    10, 1500, '2023-07-15', 1, 'Líder'),
(2,  'FuriaLegendaria',  9, 1430, '2023-09-10', 1, 'Colíder'),
(3,  'LanzaSombras',    10, 1570, '2023-06-30', 1, 'Miembro'),
(4,  'GeneralOscuro',    7,  480, '2024-03-05', 2, 'Líder'),
(5,  'DestructorRojo',   7,  500, '2024-03-20', 2, 'Veterano'),
(6,  'DragonInfernal',   6,  285, '2025-01-01', 3, 'Líder'),
(7,  'MineroLegendario', 6,  300, '2025-01-10', 3, 'Colíder'),
(8,  'PrincesaOscura',   8, 1000, '2024-06-18', NULL, NULL),
(9,  'DuendeMalvado',    3,   50, '2025-09-01', NULL, NULL),
(10, 'MontapuercosOP',  11, 2600, '2023-01-10', NULL, NULL),
(11, 'SabuesoDivino',    8,  800, '2023-11-25', 5, 'Líder'),
(12, 'Novato',           1,    0, '2025-09-20', NULL, NULL);

-- =========================================================
-- Colección de cartas por jugador (tabla jugador_carta)
-- ---------------------------------------------------------
-- Estrategia:
--   - Se han definido colecciones variadas para que haya:
--       * Jugadores con mazos básicos.
--       * Jugadores con legendarias / campeones.
--       * Jugadores sin ninguna carta (jugador 12).
-- =========================================================

-- Jugador 1: mazo equilibrado con algunas legendarias
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(1, 1, 9),
(1, 2, 9),
(1, 10, 9),
(1, 12, 7),
(1, 13, 7),
(1, 22, 5),
(1, 24, 5),
(1, 31, 2);

-- Jugador 2: mazo con buen daño aéreo y montapuercos
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(2, 3, 8),
(2, 4, 8),
(2, 10, 8),
(2, 15, 6),
(2, 16, 6),
(2, 23, 4),
(2, 25, 4),
(2, 34, 2);

-- Jugador 3: combinación de gigantes, P.E.K.K.A. y legendarias
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(3, 1, 9),
(3, 2, 9),
(3, 6, 9),
(3, 11, 7),
(3, 14, 7),
(3, 21, 5),
(3, 28, 5),
(3, 32, 2);

-- Jugador 4: mazo centrado en duendes y estructuras
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(4, 5, 7),
(4, 7, 7),
(4, 12, 5),
(4, 13, 5),
(4, 19, 5),
(4, 26, 3);

-- Jugador 5: mazo defensivo con recolector y splash
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(5, 9, 7),
(5, 10, 7),
(5, 16, 5),
(5, 20, 5),
(5, 23, 3);

-- Jugador 6: mazo sencillo con bruja y gigante
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(6, 2, 6),
(6, 8, 6),
(6, 11, 4),
(6, 22, 4);

-- Jugador 7: mazo centrado en mineros y tropas de apoyo
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(7, 3, 6),
(7, 6, 6),
(7, 14, 4),
(7, 25, 4);

-- Jugador 8: mazo mixto con legendaria Sabueso de Lava
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(8, 2, 8),
(8, 10, 8),
(8, 13, 6),
(8, 15, 6),
(8, 17, 6),
(8, 29, 4),
(8, 36, 1);

-- Jugador 9: jugador muy nuevo, pocas cartas
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(9, 1, 3),
(9, 2, 3);

-- Jugador 10: jugador avanzado con varias legendarias
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(10, 2, 10),
(10, 12, 8),
(10, 14, 8),
(10, 15, 8),
(10, 21, 6),
(10, 26, 6),
(10, 29, 6),
(10, 37, 3),
(10, 38, 3);

-- Jugador 11: mazo fuerte en aire y control
INSERT INTO jugador_carta (id_jugador, id_carta, nivel) VALUES
(11, 3, 8),
(11, 6, 8),
(11, 11, 6),
(11, 16, 6),
(11, 23, 4),
(11, 27, 4);

-- Jugador 12: sin cartas (permite practicar LEFT JOIN y casos vacíos)

-- =========================================================
-- Población de batallas
-- ---------------------------------------------------------
-- Notas:
--   - id_batalla se fija explícitamente (1..5).
--   - La fecha se indica de forma explícita, aunque la columna tiene
--     DEFAULT CURRENT_TIMESTAMP.
--   - Se incluye un empate (batalla 5) con trofeos_ganados = 0.
-- =========================================================
INSERT INTO batalla (id_batalla, fecha, id_jugador1, id_jugador2, id_ganador, trofeos_ganados) VALUES
(1, '2025-09-01 15:30:00', 1, 2, 1,   30),  -- Gana jugador 1
(2, '2025-09-02 16:00:00', 1, 3, 3,   30),  -- Gana jugador 3
(3, '2025-09-05 10:00:00', 4, 5, 4,   20),  -- Gana jugador 4
(4, '2025-09-10 18:45:00', 6, 7, 6,   15),  -- Gana jugador 6
(5, '2025-09-15 20:00:00', 2, 3, NULL, 0);  -- Empate entre jugadores 2 y 3

-- Confirmamos la carga
COMMIT;
SET autocommit = @OLD_AUTOCOMMIT;
