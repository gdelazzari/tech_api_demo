tech_api.energy.register_device("tech_api_demo:electric_furnace", "default", {
  class = { 'default' },
  type = 'user',
  max_rate = 20,
  linkable_faces = {'back', 'top', 'left', 'right', 'bottom'},
  callback = function(pos, dtime, available)
    local meta = minetest.get_meta(pos)
    local cook_time = meta:get_float("cook_time") or 0.0
    local inv = meta:get_inventory()
    local srclist = inv:get_list("src")

		local cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		local cookable = cooked.time ~= 0
    local needed_time = cooked.time / 5

    minetest.chat_send_all("available=" .. available)

    -- if we have something to cook
    if cookable then
      -- and we have enough energy
      if available >= 20 then
        -- increment the cooking time only if the dtime is reasonable
        -- this is necessary since, when we manually ask for a callback, the
        -- dtime may be really big (since the last callback was a long time ago)
        if dtime < 1 then
          cook_time = cook_time + dtime
          -- if we cooked the item
          if cook_time >= needed_time then
            -- place it in the dst slot
            if inv:room_for_item("dst", cooked.item) then
              inv:add_item("dst", cooked.item)
              inv:set_stack("src", 1, aftercooked.items[1])
              cook_time = 0.0
            end
          end
          meta:set_float("cook_time", cook_time)
        end

        minetest.chat_send_all("cook_time=" .. cook_time .. "/" .. cooked.time)

        -- then return telling the API we're requesting 20 EU/t, we're consuming
        -- 20 EU/t (since they're available) and we want the next callback ASAP
        return 20, 20, 1
      else
        -- if we have less than 20 EU/t, then tell the API we're still looking
        -- for 20 EU/t but, since they're not available, we're consuming 0 at
        -- the moment. Also we're asking for callbacks ASAP so we can resume as
        -- soon as we have enough energy available
        return 20, 0, 1
      end
    else
      -- otherwise, if we have nothing to cook, ensure the cooking time stays 0
      if cook_time > 0.0 then
        cook_time = 0.0
        meta:set_float("cook_time", cook_time)
      end

      -- and return telling the API we are not requesting any power and we're
      -- obviously not consuming any too. And that we don't
      -- want any more callback until we manually tell it to call us back
      return 0, 0, -1
    end

    -- if, for some reason, an unhandled situation happened...
    return 0, 0, -1
  end
})

minetest.register_node("tech_api_demo:electric_furnace", {
  groups = { snappy = 1 },
  tiles = { "electric_furnace_top.png",
            "electric_furnace_bottom.png",
            "electric_furnace_leftrightback.png",
            "electric_furnace_leftrightback.png",
            "electric_furnace_leftrightback.png",
            "electric_furnace_front.png" },
  paramtype2 = "facedir",
  on_construct = function(pos)
    tech_api.energy.on_construct(pos)

    local meta = minetest.get_meta(pos)
    meta:set_string("formspec",
      "size[8,9;]\n" ..
      "list[context;src;2,1;1,1;]\n" ..
      "list[context;dst;5,1;2,2;]\n" ..
      "list[current_player;main;0,5;8,4;]"
    )
    local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
  end,
  on_destruct = function(pos)
    tech_api.energy.on_destruct(pos)
  end,
  on_metadata_inventory_move = function(pos, fl, fi, tl, ti, c, p)
    tech_api.energy.request_callback(pos, "default")
  end,
  on_metadata_inventory_put = function(pos, l, i, s, p)
    tech_api.energy.request_callback(pos, "default")
  end,
  on_metadata_inventory_move = function(pos, l, i, s, p)
    tech_api.energy.request_callback(pos, "default")
  end
})
