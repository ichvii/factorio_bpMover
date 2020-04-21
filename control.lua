



function get_signal_from_set(signal,set)
  for _,sig in pairs(set) do
    if sig.signal.type == signal.type and sig.signal.name == signal.name then
      return sig.count
    end
  end
  return 0
end

function get_signals_filtered(filters,signals)
  --   filters = {
  --  SignalID,
  --  }
  local results = {}
  local count = 0
  for _,sig in pairs(signals) do
    for i,f in pairs(filters) do
      if f.name and sig.signal.type == f.type and sig.signal.name == f.name then
        results[i] = sig.count
        count = count + 1
        if count == #filters then return results end
      end
    end
  end
  return results
end

-- pre-built signal tables to save loads of table/string constructions
local knownsignals = require("knownsignals")

local signalsets = {
  position1 = {
    x = knownsignals.X,
    y = knownsignals.Y,
  },
  position2 = {
    x = knownsignals.U,
    y = knownsignals.V,
  },
  color = {
    r = knownsignals.red,
    g = knownsignals.green,
    b = knownsignals.blue,
  }
}



local function ReadColor(signals)
  return get_signals_filtered(signalsets.color,signals)
end


local function ReadFilters(signals,count)
  local filters = {}
  if signals then
    for i,s in pairs(signals) do
      if s.signal.type == "item" then
        filters[#filters+1]={index = #filters+1, name = s.signal.name, count = s.count}
        if count and #filters==count then break end
      end
    end
  end
  return filters
end

local function ReadInventoryFilters(signals,count)
  local filters = {}
  local nfilters = 0
  if signals then
    for _,s in pairs(signals) do
      if s.signal.type == "item" then
        for b=0,31 do
          local bit = bit32.extract(s.count,b)
          if bit == 1 and not filters[b+1] then
            filters[b+1]={index = b+1, name = s.signal.name}
            nfilters = nfilters +1
            if b == 31 and count > 31 then
              for n=32,count do
                filters[n]={index = n, name = s.signal.name}
                nfilters = nfilters +1
              end
            end
          end
        end
      end
    end
  end
  return filters
end

local function ReadItems(signals,count)
  local items = {}
  if signals then
    for i,s in pairs(signals) do
      if s.signal.type == "item" then
        local n = s.count
        if n < 0 then n = n + 0x100000000 end
        items[s.signal.name] = n
        if count and #items==count then break end
      end
    end
  end
  return items
end

--TODO use iconstrip reader from magiclamp
local function ReadSignalList(signals,nbits)
  local selected = {}
  for i=0,(nbits or 31) do
    for _,sig in pairs(signals) do
      local sigbit = bit32.extract(sig.count,i)
      if sigbit==1 then
        selected[i+1] = sig.signal
        break
      end
    end
  end
  return selected
end



local function ReportBlueprintLabel(manager,signals1,signals2)
  local inInv = manager.ent.get_inventory(defines.inventory.assembling_machine_input)
  -- confirm it's a blueprint and is setup and such...
  local bp = inInv[1]
  local outsignals = {}
  if bp.valid and bp.valid_for_read then
    if bp.label and remote.interfaces['signalstrings'] then
      -- create label signals
      outsignals = remote.call('signalstrings','string_to_signals', bp.label)
    end

    -- add color signals
    if bp.label_color then
      outsignals[#outsignals+1]={index=#outsignals+1,count=bp.label_color.r*256,signal=knownsignals.red}
      outsignals[#outsignals+1]={index=#outsignals+1,count=bp.label_color.g*256,signal=knownsignals.green}
      outsignals[#outsignals+1]={index=#outsignals+1,count=bp.label_color.b*256,signal=knownsignals.blue}
      outsignals[#outsignals+1]={index=#outsignals+1,count=bp.label_color.a*256,signal=knownsignals.white}
    end
  end
  manager.cc2.get_or_create_control_behavior().parameters={parameters=outsignals}
  manager.clearcc2 = true
end

local function ReportBlueprintBoM(manager,signals1,signals2)
  local inInv = manager.ent.get_inventory(defines.inventory.assembling_machine_input)
  -- confirm it's a blueprint and is setup and such...
  local bp = inInv[1]
  local outsignals = {}
  if bp.valid and bp.valid_for_read then
    -- BoM signals
    for k,v in pairs(bp.cost_to_build) do
      outsignals[#outsignals+1]={index=#outsignals+1,count=v,signal={name=k,type="item"}}
    end
  end
  manager.cc2.get_or_create_control_behavior().parameters={parameters=outsignals}
  manager.clearcc2 = true
end

local function enumerate_book(book)
  local bookinv=book.get_inventory(defines.inventory.item_main)
  local pagenumber= bookinv.get_item_count()
  local label =""
  local a =0
  for page = 1, pagenumber, 1 do
    if not bookinv[page].is_blueprint_setup() then 
	  --enter tile or random stuff
	  bookinv[page].set_blueprint_tiles({{tile_number=1, name= "concrete", position={0,0} }})
	end
    label = bookinv[page].label or ""
	a = tonumber(string.sub(label,1,4))
    if a and string.sub(label,5,6)==": " then label = string.sub(label, 7) end
    label = string.format("%04d", page) .. ": " .. label	
	bookinv[page].label=label
  end
end

local function find_anchor_position(bp)
  local entities= bp.get_blueprint_entities()
  local anchor_pos={}
  for _, ent in pairs(entities) do
    if ent.name == "blueprint-deployer" then 
	  anchor_pos.x= ent.position.x
	  anchor_pos.y=ent.position.y
	  return anchor_pos
    end  
  end
  return nil
end

local function special_find_entity_in_bp_pos (bp, pos)
  local entities= bp.get_blueprint_entities()
  local anchor_pos= find_anchor_position(bp)
  local pos_x =anchor_pos.x + pos.x
  local pos_y =anchor_pos.y + pos.y
  for _, ent in pairs(entities) do
    if ent.position.x == pos_x and ent.position.y == pos_y then
	  return ent  
	end
  end 
end



local function special_enumerate_book(book,ref_book)
  local bookinv=book.get_inventory(defines.inventory.item_main)
  local pagenumber= bookinv.get_item_count()
  local label =""
  local a =0
  local last_empty=0
  local stages= {}
  local ent
  local stage_item_list={}
  local info =
    {
      CALL1={number=7, stage_level_list ={x= 0, y=4}, stage_header_list = {x=0, y=3}},
	  header={product={x=0,y=4},educts={x=0,y=5},priorities={x=-1,y=5}},
	  tailer={products={x=-1,y=6},return_address={x=4,y=5}},
      normal={next_bp={x=3,y=0}}  
    }
  
  
  
  for page = 1, pagenumber, 1 do
    if not bookinv[page].is_blueprint_setup() then 
	  --enter tile or random stuff
	  bookinv[page].set_blueprint_tiles({{tile_number=1, name= "concrete", position={0,0} }})
	end
    label = bookinv[page].label or ""
	a = tonumber(string.sub(label,1,4))
    if a and string.sub(label,5,6)==": " then label = string.sub(label, 7) end
    label = string.format("%04d", page) .. ": " .. label	
	bookinv[page].label=label
    if not bookinv[page].get_blueprint_entities() then
      if page>19 then last_empty=page end
    end
    if page == last_empty+1 then
      stages[#stages+1]={header=page}
    end
  end
  last_empty=pagenumber+1
  local i = #stages
  for page =pagenumber , 20, -1 do
    if not bookinv[page].get_blueprint_entities() then
      last_empty=page
    end
    if page == last_empty-1 then
      stages[i].tailer=page
      ent=special_find_entity_in_bp_pos(bookinv[page],info.tailer.return_address)
	  if ent and ent.arithmetic_conditions then
	    local levelname= control.arithmetic_conditions.first_signal.name
		stage.level=tonumber(string.sub(levelname,8))		
	  end
	  ent=special_find_entity_in_bp_pos(bookinv[page],info.tailer.products)
	  if ent and game.entity_prototypes[ent.name].type == "constant-combinator"  then
		--stage.product_combinator_number=ent.entity_number
		stage.product_counts=ent.filters
	  end
	  
	  i=i-1
    end
  end
  -- reenumerated everything and listed the header and tailer of each stage and some useful values.
  
  for _, stage in pairs(stages) do
    if (not stage.level) or stage.level<12   then
      --below fuel oil case
	
	
	else
	  --above fuel oil case
	  for i = stage.header, stage.tailer-1 do
	    local entities=bookinv[i].get_blueprint_entities()
		ent= special_find_entity_in_bp_pos(bookinv[i],info.normal.next_bp)
		if ent and game.entity_prototypes[ent.name].type == "constant-combinator" then
		  entities[ent.entity_number].filters={}
		  entities[ent.entity_number].filters[1]={signal={type="item", name="construction-robot"},count=i+1}
		end
		bookinv[i].set_blueprint_entities(entities)
	  end
      local entities=bookinv[stage.tailer].get_blueprint_entities()
	  ent= special_find_entity_in_bp_pos(bookinv[stage.tailer],info.normal.next_bp)
	  if ent and game.entity_prototypes[ent.name].type == "constant-combinator" then
	    entities[ent.entity_number].filters={}
	    entities[ent.entity_number].filters[1]={signal={type="item", name="construction-robot"},count=stage.header}
	  end
	  bookinv[i].set_blueprint_entities(entities)
	  for _, sig in pairs(stage.product_counts) do
	    if stage_header_list[sig.name] then
		  game.print(string.format("The stages starting at %d and %d both produce %s",stage_header_list[sig.name],stage.header,sig.name))
		else
		  stage_item_list[sig.name]={header=stage.header, level=stage.level}
		end
	  
	  end
	
    end
	
	
	
  end  
  local stage_item_list_old={}
  for _, sig in pairs(special_find_entity_in_bp_pos(bookinv[info.CALL1.number],info.CALL1.stage_level_list).filters) do
    stage_item_list_old[sig.name].level=sig.count
  end
  for _, sig in pairs(special_find_entity_in_bp_pos(bookinv[info.CALL1.number],info.CALL1.stage_header_list).filters) do
    stage_item_list_old[sig.name].header=sig.count
  end
  
  for name,_ in pairs(stage_item_list) do
    stage_item_list_old[name]=stage_item_list[name]
  end
  local entities=bookinv[info.CALL1.number].get_blueprint_entities()
  local header_list_combinator = special_find_entity_in_bp_pos(bookinv[info.CALL1.number],info.CALL1.stage_header_list)
  local level_list_combinator = special_find_entity_in_bp_pos(bookinv[info.CALL1.number],info.CALL1.stage_level_list)
  local i=1
  entities[header_list_combinator].filters={}
  entities[level_list_combinator].filters={}
  for name, item in pairs(stage_item_list_old) do
    entities[header_list_combinator].filters[i]={signal={name=name,type="item"},count=item.header,index=i}
    entities[level_list_combinator].filters[i]={signal={name=name,type="item"},count=item.level,index=i} 
  end
  bookinv[info.CALL1.number].set_blueprint_entities(entities)
  
end



local function create_documentation(book)
  local bookinv=book.get_inventory(defines.inventory.item_main)
  local pagenumber= bookinv.get_item_count()
  local build_parameters={
    surface=1, -- or not?
	force = player, -- change for multiple forces?
	position={x=0,y=0}, -- just initialising
	force_build =true
  }
  local screenshot_parameters={
  
  
  } --TODO
  local anchor_place_pos={x= 0, y=0} --TODO   
  for i =1, pagenumber do
    local bp = bookinv[i]
    if (bp.is_blueprint_setup() and bp.get_blueprint_entities()) then 
	  local anchor_bp_pos= find_anchor_position(bp)
	  build_parameters.position.x=anchor_place_pos.x - anchor_bp_pos.x
	  build_parameters.position.y=anchor_place_pos.y - anchor_bp_pos.y
	  local entities= bp.build_blueprint(build_parameters)
	  for _, ent in entities do
	    ent.silent_revive()
	  end
	  game.take_screenshot(screenshot_parameters)
	  --add combinator graph generator call
	  
	  for _, ent in entities do
	    ent.destroy() --remnants??
      end
	  
	  
	  
	  
    end
  end
end










local function copy_blueprint_as(bp1, bp2, name)
  --sets blueprint if name is not nil
  if name == nil and bp2.can_set_stack(bp1) then 
    bp2.set_stack(bp1)
	return
  elseif name then
    bp2.set_stack(name)
  end
  bp2.set_blueprint_entities(bp1.get_blueprint_entities())
  bp2.set_blueprint_tiles(bp1.get_blueprint_tiles())
  if bp2.is_blueprint_setup() then
    bp2.blueprint_icons=bp1.blueprint_icons
    bp2.label=bp1.label  
  end
end

local function copy_book_as(book1,book2,name,delete,offset)
  --last variable sets 
  -- both need to be non empty
  local inv1=book1.get_inventory(defines.inventory.item_main)
  local inv2=book2.get_inventory(defines.inventory.item_main)
  if not offset then
    offset=0
	inv2.clear()
  end
  book2.label=book1.label
  for i = 1, inv1.get_item_count(),1 do
    copy_blueprint_as(inv1[i],inv2[i+offset],name)
  end
  if delete then book1.clear() end
end

local function copy(start,target,name,delete,internal_book)
  local item1=start.item
  local item2=target.item
  if item1 == item2 then 
    --if moving from one item to the same, set delete false and possibly change bp colors, using internal_book as memory
	delete=false
    if item1.is_blueprint then
	  copy(start,internal_book.get_inventory()[1],name,delete,internal_book)
	  copy(internal_book.get_inventory()[1],target,name,delete,internal_book)  
	elseif item1.is_blueprint_book then
	  copy(start,internal_book,name,delete,internal_book)
	  copy(internal_book,target,name,delete,internal_book)
	end	
  end
  if item1.is_blueprint_book and item2.is_blueprint_book then 
    copy_book_as(item1, item2 , name, delete)
  elseif item1.is_blueprint and item2.is_blueprint then
    copy_blueprint_as(item1,item2,name,delete)
  elseif item1.is_blueprint_book and item2.is_blueprint and target.book.item then
  elseif item1.is_blueprint and item2.is_blueprint_book then
  
  end
end

local function insert_and_find(inv,name)
  --returns item stack and (was item stack empty?)
  local a = inv.insert(name)
  return inv.find_item_stack(name) , a 
end

local function get_book_page(book,page)
  local size= book.prototype.inventory_size
  if page>size then page=size end
  if page == -1 then return book end
  local inv=book.get_inventory(defines.inventory.item_main)
  for i = inv.get_item_count()+1,page ,1 do
    inv[i].set_stack("blueprint")
  end
  return inv[page]  
end

local function handle_blueprint_signals(inv, signals)
  if not signals then return {bp={},book={}} end
  local book = {}
  local bp={}
  for _, signal in pairs (global.ColoredBlueprintBooks) do 
    if get_signal_from_set(signal,signals) ~=0 then
	  book.name= signal.name
	  book.count=get_signal_from_set(signal,signals)
	  break
	end
  end
  if book.name then 
    book.item, book.new = insert_and_find(inv,book.name) 
    item=get_book_page(book.item,book.count)
  end
  for _, signal in pairs (global.ColoredBlueprints) do 
    if get_signal_from_set(signal,signals) ~=0 then
	  bp.name= signal.name
	  bp.count=get_signal_from_set(signal,signals)
	  break
	end
  end
  if bp.name and not item then
    item=insert_and_find(inv,bp.name)
  end
  game.print(bp.name)
  return {bp=bp, book=book, item=item}
end

local function onTickManager(manager)
  if manager.clearcc2 then
    manager.clearcc2 = nil
    manager.cc2.get_or_create_control_behavior().parameters=nil
  end
  local inInv = manager.ent.get_inventory(defines.inventory.assembling_machine_input)
  local outInv = manager.ent.get_inventory(defines.inventory.assembling_machine_output)
  local signals1 = manager.cc1.get_merged_signals()
  local signals2 = manager.cc2.get_merged_signals()
  local internal_book= insert_and_find(inInv,"privatebpbook")
  if signals1 then
    if get_signal_from_set(knownsignals.I,signals1)==1 then
	--enumerate all books
	  for i =1, #inInv,1 do  --#global.ColoredBlueprints + #global.ColoredBlueprintBooks, 1 do
		if inInv[i].valid and inInv[i].valid_for_read and inInv[i].is_blueprint_book then enumerate_book(inInv[i]) end
	  end
	  return
	end
    if get_signal_from_set(knownsignals.O,signals1)==0 then outInv = inInv end
    start= handle_blueprint_signals(inInv,signals1)
	target=handle_blueprint_signals(outInv,signals2)
	local name = target.bp.name
	local delete= (get_signal_from_set(knownsignals.D,signals1) == 1)
	if not target.item then 
	  target.item = insert_and_find(outInv,start.item.name)
    end
	copy(start,target,name,delete,internal_book)	
  end 
end


local function onTick()
  if global.managers then
    for _,manager in pairs(global.managers) do
      if not (manager.ent.valid and manager.cc1.valid and manager.cc2.valid) then
        -- if anything is invalid, tear it all down
        if manager.ent.valid then manager.ent.destroy() end
        if manager.cc1.valid then manager.cc1.destroy() end
        if manager.cc2.valid then manager.cc2.destroy() end
        global.managers[_] = nil
      else
        onTickManager(manager)
      end
    end
  end
end

local function CreateControl(manager,position)
  local ghost = manager.surface.find_entity('entity-ghost', position)
  if ghost then
    -- if there's a ghost here, just claim it!
    _,ghost = ghost.revive()
  else
    -- or a pre-built one, if it was built in editor and script.dat cleared...
    ghost = manager.surface.find_entity('conman-control2', position)
  end

  local ent = ghost or manager.surface.create_entity{
      name='conman-control2',
      position = position,
      force = manager.force
    }

  ent.operable=false
  ent.minable=false
  ent.destructible=false

  return ent
end

local function onBuilt(event)
  
  local ent = event.created_entity
  if ent.name == "conman2" then

    ent.set_recipe("conman-process2")
    ent.active = false
--    ent.operable = false

    local cc1 = CreateControl(ent, {x=ent.position.x-1,y=ent.position.y+1.5})
    local cc2 = CreateControl(ent, {x=ent.position.x+1,y=ent.position.y+1.5})

    if not global.managers then global.managers = {} end
    global.managers[ent.unit_number]={ent=ent, cc1 = cc1, cc2 = cc2}

  end
end

function reindex_blueprints()
  local ColoredBlueprints = {}
  local ColoredBlueprintBooks = {}
 

  for name,itemproto in pairs(game.item_prototypes) do
    if itemproto.type == "blueprint" then
      table.insert(ColoredBlueprints, {name=itemproto.name,type="item"  })
    elseif itemproto.type == "blueprint-book" then
      table.insert(ColoredBlueprintBooks, { name=itemproto.name,type="item"  })
    end
  end

  global.ColoredBlueprints = ColoredBlueprints
  global.ColoredBlueprintBooks = ColoredBlueprintBooks
end

script.on_init(function()
  -- Index recipes for new install
  reindex_blueprints()
  


  -- Scan for pre-built ConMan2 in the world already...
  for _,surface in pairs(game.surfaces) do
    for _,entity in pairs(surface.find_entities_filtered{name="conman2"}) do
      onBuilt({created_entity=entity})
    end
  end
end
)

script.on_configuration_changed(function(data)
  -- when any mods change, reindex recipes
  reindex_blueprints()
end
)


script.on_event(defines.events.on_tick, onTick)
script.on_event(defines.events.on_built_entity, onBuilt)
script.on_event(defines.events.on_robot_built_entity, onBuilt)

No_Profiler_Commands = true
local ProfilerLoaded,Profiler = pcall(require,'__profiler__/profiler.lua')
if not ProfilerLoaded then Profiler=nil end

remote.add_interface('conman2',{
  --TODO: call to register items for custom decoding into ghost tags?

  read_preload_string = function(manager_id)
    return global.managers[manager_id] and global.managers[manager_id].preloadstring
  end,
  read_preload_color = function(manager_id)
    return global.managers[manager_id] and global.managers[manager_id].preloadstring
  end,
  
  set_preload_string = function(manager_id,str)
    if global.managers[manager_id] then
      global.managers[manager_id].preloadstring = str
    end
  end,
  set_preload_color = function(manager_id,color)
    if global.managers[manager_id] then
      global.managers[manager_id].preloadstring = color
    end
  end,
  
  startProfile = function()
    if Profiler then Profiler.Start() end
  end,
  stopProfile = function()
    if Profiler then Profiler.Stop() end
  end,
})
