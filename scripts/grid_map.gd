extends GridMap


@onready var player: CharacterBody3D = $"../Player"


func destroy_block(world_cord: Vector3):
    var map_cord = local_to_map(world_cord)
    set_cell_item(map_cord, -1)

func place_block(world_cord: Vector3, block_index: int):
    var map_cord = local_to_map(world_cord)
    if local_to_map(player.position) == map_cord:
        return
    set_cell_item(map_cord, block_index)

func replace_block(world_cord: Vector3, block_index: int):
    destroy_block(world_cord)
    place_block(world_cord, block_index)
