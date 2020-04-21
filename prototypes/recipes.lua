local results = {}
for _, itemproto in pairs (data.raw["blueprint-book"]) do
  table.insert(results, {type="item", name=itemproto.name, amount =1})
end

for _, itemproto in pairs (data.raw.blueprint) do
  table.insert(results, {type="item", name=itemproto.name, amount =1})
end






data:extend{
  {
    type = "recipe",
    name = "conman2",
    enabled = "true",
    ingredients =
    {
      {"assembling-machine-2", 1},
      {"constant-combinator", 2},
      {"roboport", 1},
    },
    result="conman2",
  },

  {
    type = "recipe-category",
    name = "conman2"
  },
  {
    type = "recipe",
    name = "conman-process2",
    enabled = false,
    energy_required = 1,
    category = "conman2",
    ingredients = results,
    results = results,
    subgroup= "other",
    icon = "__base__/graphics/icons/roboport.png",
    icon_size = 32,
  },

}
