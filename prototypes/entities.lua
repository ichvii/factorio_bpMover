
local conmanent = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
conmanent.name="conman2"
conmanent.minable.result = "conman2"
conmanent.fast_replaceable_group = nil
conmanent.next_upgrade = nil
conmanent.crafting_categories = {"conman2"}
conmanent.crafting_speed = 1
conmanent.ingredient_count = 252
conmanent.module_specification = nil
conmanent.allowed_effects = nil
conmanent.fluid_boxes = {}
conmanent.collision_box = {{-1.2, -1.2}, {1.2, 0.8}} -- collision_box = {{-1.2, -1.2}, {1.2, 1.2}}
data:extend{conmanent}

local conmanctrl = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
conmanctrl.name="conman-control2"
conmanctrl.minable= nil
conmanctrl.order="z[lol]-[conmanctrl]"
conmanctrl.item_slot_count = 500
conmanctrl.collision_box = {{-0.4,  0.0}, {0.4, 0.4}}
data:extend{conmanctrl}
