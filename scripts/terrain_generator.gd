extends Node

const AIR_BLOCK: int = -1
const DIRT_BLOCK: int = 1
const CHUNK_SIZE: int = 16
const TERRAIN_HEIGHT: int = 0
const VIEW_DISTANCE: int = 16
const CHUNKS_PER_FRAME: int = 8

@onready var player: CharacterBody3D = $"../Player"
@onready var grid_map: GridMap = $"../GridMap"

var loaded_chunks: Array[Vector2i] = []
var last_player_chunk := Vector2i(-9999, -9999)
var chunks_to_generate: Array[Vector2i] = []
var chunks_to_unload: Array[Vector2i] = []

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

func update_loaded_chunks(center_chunk: Vector2i) -> void:
    var start_x = center_chunk.x - VIEW_DISTANCE
    var end_x = center_chunk.x + VIEW_DISTANCE
    var start_z = center_chunk.y - VIEW_DISTANCE
    var end_z = center_chunk.y + VIEW_DISTANCE

    var desired_chunks: Array[Vector2i] = []
    for x in range(start_x, end_x + 1):
        for z in range(start_z, end_z + 1):
            desired_chunks.append(Vector2i(x, z))

    desired_chunks.sort_custom(func(a, b):
        var da = center_chunk.distance_to(a)
        var db = center_chunk.distance_to(b)
        return da < db
    )

    for pos in desired_chunks:
        if not loaded_chunks.has(pos) and not chunks_to_generate.has(pos):
            chunks_to_generate.append(pos)
            loaded_chunks.append(pos)

    for chunk in loaded_chunks.duplicate():
        if not desired_chunks.has(chunk) and not chunks_to_unload.has(chunk):
            chunks_to_unload.append(chunk)

func _process(_delta: float) -> void:
    var current_chunk := Vector2i(
        int(player.position.x / CHUNK_SIZE),
        int(player.position.z / CHUNK_SIZE)
    )

    if current_chunk != last_player_chunk:
        last_player_chunk = current_chunk
        update_loaded_chunks(current_chunk)

    for i in range(CHUNKS_PER_FRAME):
        if chunks_to_generate.size() == 0:
            break
        var pos = chunks_to_generate.pop_front()
        generate_chunk(pos.x, pos.y)

    for i in range(CHUNKS_PER_FRAME):
        if chunks_to_unload.size() == 0:
            break
        var pos = chunks_to_unload.pop_front()
        unload_chunk(pos.x, pos.y)
        loaded_chunks.erase(pos)
