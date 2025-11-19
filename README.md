# Clash Royale MySQL

Esquema de base de datos didáctico inspirado en *Clash Royale*, diseñado para practicar SQL en MySQL 8.x: creación de tablas, claves foráneas, vistas, procedimientos almacenados, triggers e índices.

## Objetivos

- Disponer de una base de datos sencilla pero realista para:
  - Practicar consultas `SELECT` (JOIN, agregaciones, subconsultas…).
  - Trabajar con integridad referencial y restricciones (`CHECK`, `FK`).
  - Ver ejemplos de lógica de negocio en procedimientos almacenados y triggers.
- Usarla en entornos formativos (FP, universidad, cursos de SQL, etc.).

## Requisitos

- **MySQL 8.x** (imprescindible por `CHECK`, `SIGNAL`, vistas con `SQL SECURITY`, etc.).
- Cliente compatible:
  - MySQL Workbench, consola `mysql`, DBeaver, TablePlus, etc.
- Juego de caracteres: `utf8mb4`
- Motor de almacenamiento: `InnoDB`

## Contenido del repositorio

- `01_clash_royale_schema.sql`  
  Crea la base de datos `clash_royale` con:
  - Tablas: `arena`, `clan`, `jugador`, `carta`, `jugador_carta`, `batalla`.
  - Índices y restricciones (`PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, índice funcional para garantizar un único líder por clan).
  - Vistas de apoyo:
    - `vw_cartas_detalle`
    - `vw_jugadores_clanes`
    - `vw_batallas_info`
    - `vw_cantidad_cartas_por_jugador`
    - `vw_clan_miembros`
  - Procedimientos almacenados:
    - `sp_registrar_batalla`
    - `sp_subir_nivel_carta`
    - `sp_crear_clan`
  - Triggers sobre:
    - `jugador` (coherencia `id_clan` / `clan_rol`)
    - `batalla` (validación de reglas de negocio y actualización de trofeos)

- `02_clash_royale_seed_data.sql`  
  Inserta datos de ejemplo:
  - Arenas (1–16) con sus trofeos requeridos.
  - Clanes con y sin miembros.
  - Cartas de todos los tipos (Común, Especial, Épica, Legendaria, Campeón).
  - Jugadores con distintos niveles, trofeos y roles de clan.
  - Relación `jugador_carta` para simular mazos variados.
  - Batallas 1v1 (victorias y empates) para explotar las vistas y triggers.

## Cómo usarlo

1. Clona el repositorio:

    ```bash
    # git clone https://github.com/tu-usuario/clash-royale-mysql-lab.git
    # cd clash-royale-mysql-lab
    ```

2. Conéctate a MySQL 8.x y ejecuta primero el esquema:

    ```sql    
    SOURCE 01_clash_royale_schema.sql;
    ```

3. Carga los datos de ejemplo:

    ```sql
    SOURCE 02_clash_royale_seed_data.sql;
    ```

4. Verifica que todo está correcto:

    ```sql
    USE clash_royale;
    SHOW TABLES;
    SELECT * FROM vw_jugadores_clanes;
    SELECT * FROM vw_batallas_info;
    ```

## Ideas de práctica

Algunas consultas típicas que se pueden practicar con este esquema:

- Ranking de jugadores por trofeos.
- Número de miembros por clan usando `vw_clan_miembros`.
- Jugadores sin clan (potenciales reclutas).
- Jugadores con más cartas legendarias.
- Estadísticas de batallas entre dos jugadores concretos.

Cualquier mejora (nuevos datos, vistas adicionales, ejercicios de consulta, etc.) puede añadirse fácilmente sobre estos scripts base.
