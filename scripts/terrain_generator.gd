extends Node

const AIR_BLOCK: int = -1
const DIRT_BLOCK: int = 1
const CHUNK_SIZE: int = 16
const TERRAIN_HEIGHT: int = 0
const VIEW_DISTANCE: int = 4

@onready var player: CharacterBody3D = $"../Player"
@onready var grid_map: GridMap = $"../GridMap"

var loaded_chunks: Array = []

func get_block(_x: int, _y: int, _z: int) -> int:
    return DIRT_BLOCK if _y == TERRAIN_HEIGHT else AIR_BLOCK

func generate_chunk(chunk_x: int, chunk_z: int) -> void:
    for x in range(CHUNK_SIZE):
        for z in range(CHUNK_SIZE):
            var block_type: int = get_block(chunk_x * CHUNK_SIZE + x, TERRAIN_HEIGHT, chunk_z * CHUNK_SIZE + z)
            grid_map.place_block(Vector3(chunk_x * CHUNK_SIZE + x, TERRAIN_HEIGHT, chunk_z * CHUNK_SIZE + z), block_type)

func unload_chunk(chunk_x: int, chunk_z: int) -> void:
    for x in range(CHUNK_SIZE):
        for z in range(CHUNK_SIZE):
            grid_map.destroy_block(Vector3(chunk_x * CHUNK_SIZE + x, TERRAIN_HEIGHT, chunk_z * CHUNK_SIZE + z))

func is_within_loaded_area(chunk_x: int, chunk_z: int) -> bool:
    var player_chunk_x: int = int(player.position.x / CHUNK_SIZE)
    var player_chunk_z: int = int(player.position.z / CHUNK_SIZE)
    return chunk_x >= (player_chunk_x - VIEW_DISTANCE) and chunk_x <= (player_chunk_x + VIEW_DISTANCE) and chunk_z >= (player_chunk_z - VIEW_DISTANCE) and chunk_z <= (player_chunk_z + VIEW_DISTANCE)

func _process(_delta: float) -> void:
    var player_chunk_x: int = int(player.position.x / CHUNK_SIZE)
    var player_chunk_z: int = int(player.position.z / CHUNK_SIZE)

    var start_loaded_area: Vector3 = Vector3(player_chunk_x - VIEW_DISTANCE, 0, player_chunk_z - VIEW_DISTANCE)
    var end_loaded_area: Vector3 = Vector3(player_chunk_x + VIEW_DISTANCE, 0, player_chunk_z + VIEW_DISTANCE)

    for chunk_x in range(start_loaded_area.x, end_loaded_area.x + 1):
        for chunk_z in range(start_loaded_area.z, end_loaded_area.z + 1):
            if not is_within_loaded_area(chunk_x, chunk_z):
                continue
            if not loaded_chunks.has([chunk_x, chunk_z]):
                generate_chunk(chunk_x, chunk_z)
                loaded_chunks.append([chunk_x, chunk_z])

    for chunk in loaded_chunks:
        var chunk_x: int = chunk[0]
        var chunk_z: int = chunk[1]

        if chunk_x < start_loaded_area.x or chunk_x > end_loaded_area.x or chunk_z < start_loaded_area.z or chunk_z > end_loaded_area.z:
            unload_chunk(chunk_x, chunk_z)
            loaded_chunks.erase(chunk)
