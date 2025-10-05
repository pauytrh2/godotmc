extends GridMap


func destroy_block(world_cord: Vector3):
    var map_cord = local_to_map(world_cord)
    set_cell_item(map_cord, -1)
