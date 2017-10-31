-- try registering some classes
tech_api.energy.register_class('LV', 1)
tech_api.energy.register_class('MV', 2)
tech_api.energy.register_class('HV', 3)

dofile(minetest.get_modpath("tech_api_demo") .. "/machines/electric_furnace.lua")

-- a stupid user device definition for the node "tech_api_demo:user"
-- that keeps consuming 20 EU/t
tech_api.energy.register_device("tech_api_demo:user", "default", {
  class = { 'default' },
  type = 'user',
  max_rate = 20,
  linkable_faces = {'back', 'top', 'left', 'right', 'bottom'},
  callback = function(pos, dtime, available)
    local use = math.min(available, 20)
    minetest.get_meta(pos):set_string("infotext", "available=" .. available .. "EU/t - using=" .. use .. "EU/t")
    return 20, use, 8 -- return energy used, and ask next callback within 8 time units
  end
})

-- a wonderful provider device definition for the node "tech_api_demo:provider"
-- that keeps producing 10 EU/t (for free!)
tech_api.energy.register_device("tech_api_demo:provider", "default", {
  class = { 'default' },
  type = 'provider',
  max_rate = 10,
  linkable_faces = {'back', 'top', 'left', 'right', 'bottom'},
  callback = function(pos, dtime, request)
    local produce = math.min(request, 10)
    minetest.chat_send_all("provider callback")
    minetest.get_meta(pos):set_string("infotext", "request=" .. request .. "EU/t - producing=" .. produce .. "EU/t")
    return produce, 8 -- return energy produced, and ask next callback within 8 time units
  end
})

-- an example storage device definition for the node "tech_api_demo:storage"
-- that stores up to 10000 EUs and displays its content and its current rate on
-- its infotext
tech_api.energy.register_device("tech_api_demo:storage", "default", {
  class = { 'default' },
  type = 'storage',
  max_rate = 50,
  capacity = 10000,
  linkable_faces = {'back', 'top', 'left', 'right', 'bottom'},
  callback = function(pos, dtime, storage_info)
    minetest.chat_send_all("storage callback")
    minetest.get_meta(pos):set_string("infotext", "content=" .. storage_info.content .. "/" .. storage_info.capacity .. "EU - current rate=" .. storage_info.current_rate .. "EU/t")
    return 0, 1 -- next callback (update) in 4 time units
  end
})

-- also register the storage device as a transporter
tech_api.energy.register_transporter("tech_api_demo:storage", {
  class = 'default'
})

-- an example power monitor that shows stuff on its infotext
tech_api.energy.register_device("tech_api_demo:monitor", "default", {
  class = { 'default' },
  type = 'monitor',
  linkable_faces = {'back', 'top', 'left', 'right', 'bottom'},
  callback = function(pos, dtime, network_info)
    local infostring = "request = " .. network_info.request .. "\n"
    infostring = infostring .. "provider available = " .. network_info.provider_available .. "; total available = " .. network_info.total_available .. "\n"
    infostring = infostring .. "total storage = " .. network_info.total_content .. "/" .. network_info.total_capacity .. "\n"
    infostring = infostring .. "total usage = " .. network_info.usage .. "\n"
    infostring = infostring .. "storages rate = " .. network_info.storages_rate .. "\n"
    minetest.get_meta(pos):set_string("infotext", infostring)
    return 1 -- next callback (update) in 4 time units
  end
})

-- a transporter definition for the node "tech_api_demo:wire" for the default
-- class (thus able to connect devices belonging to that same class)
tech_api.energy.register_transporter("tech_api_demo:wire", {
  class = 'default'
})

-- Minetest nodes registration for the devices we defined above, pretty straightforward
minetest.register_node("tech_api_demo:user", {
  groups = { snappy = 1, ['tech_api_demo_default'] = 1 },
  tiles = { "tech_api_demo_user.png" },
  paramtype2 = "facedir",
  on_construct = function(pos)
    tech_api.energy.on_construct(pos)
  end,
  on_destruct = function(pos)
    tech_api.energy.on_destruct(pos)
  end
})

minetest.register_node("tech_api_demo:provider", {
  groups = { snappy = 1, ['tech_api_demo_default'] = 1 },
  tiles = { "tech_api_demo_provider.png" },
  paramtype2 = "facedir",
  on_construct = function(pos)
    tech_api.energy.on_construct(pos)
  end,
  on_destruct = function(pos)
    tech_api.energy.on_destruct(pos)
  end
})

minetest.register_node("tech_api_demo:storage", {
  groups = { snappy = 1, ['tech_api_demo_default'] = 1 },
  tiles = { "tech_api_demo_storage.png" },
  paramtype2 = "facedir",
  on_construct = function(pos)
    tech_api.energy.on_construct(pos)
  end,
  on_destruct = function(pos)
    tech_api.energy.on_destruct(pos)
  end
})

minetest.register_node("tech_api_demo:monitor", {
  groups = { snappy = 1, ['tech_api_demo_default'] = 1 },
  paramtype2 = "facedir",
  on_construct = function(pos)
    tech_api.energy.on_construct(pos)
  end,
  on_destruct = function(pos)
    tech_api.energy.on_destruct(pos)
  end,
  connect_sides = {'back', 'top', 'left', 'right', 'bottom'}
})

local size = 0.12

local node_box = {
		type = "connected",
		fixed          = {-size, -size, -size, size,  size, size},
		connect_top    = {-size, -size, -size, size,  0.5,  size}, -- y+
		connect_bottom = {-size, -0.5,  -size, size,  size, size}, -- y-
		connect_front  = {-size, -size, -0.5,  size,  size, size}, -- z-
		connect_back   = {-size, -size,  size, size,  size, 0.5 }, -- z+
		connect_left   = {-0.5,  -size, -size, size,  size, size}, -- x-
		connect_right  = {-size, -size, -size, 0.5,   size, size}, -- x+
	}

minetest.register_node("tech_api_demo:wire", {
  groups = { snappy = 1, ['tech_api_demo_default'] = 1 },
  tiles = { "tech_api_demo_wire.png" },
  paramtype2 = "facedir",
  on_construct = function(pos)
    tech_api.energy.on_construct(pos)
  end,
  on_destruct = function(pos)
    tech_api.energy.on_destruct(pos)
  end,
  drawtype = "nodebox",
  node_box = node_box,
  connects_to = {"group:tech_api_demo_default"}
})

-- Debug command to rebuild networks
minetest.register_chatcommand("rebuild_networks", {
	params = "",
	description = "Rebuild tech_api networks graph",
	privs = {},
	func = function( _ )
		tech_api.energy.rediscover_networks()
    tech_api.energy.log_networks()
	end,
})

-- Silly way of filling up the minetest world with tons of nodes.
-- Creates a network of <wires_n> wires with <devices_n> devices connected,
-- alternating between users and providers. Use at your own risk, first set
-- the amount of "things" below.
-- You can call the same command with "clean" as a parameter to remove everything.

minetest.register_chatcommand("stress_energy", {
	params = "<clean>",
	description = "",
	privs = {},
	func = function( _ , pclean)
    local clean = false
    if pclean == 'clean' then
      clean = true
    end

    -- settings
    local wires_n = 1000
    local devices_n = 1000

    local x_min = 280
    local z_min = 300
    local z_max = 450

    -- pre-calculate some stuff
    local device_every = math.floor(wires_n / devices_n)

    -- current state of the placement
    local inc_x = 0
    local move_z = 1
    local x = x_min
    local y = 20
    local z = z_min
    local dtype = 0
    local wire_count = 0
    local device_countdown = device_every

    -- main loop (aka "super code mess")
    while wire_count < wires_n do
      if clean == false then
        minetest.set_node({x=x, y=y, z=z}, {name="tech_api_demo:wire"})

        device_countdown = device_countdown - 1
        if device_countdown <= 0 then
          local type = 'tech_api_demo:user'
          if dtype == 1 then
            type ='tech_api_demo:provider'
            dtype = 0
          else
            dtype = 1
          end
          minetest.set_node({x=x, y=(y + 1), z=z}, {name=type})
          device_countdown = device_every
        end
      else
        minetest.set_node({x=x, y=y, z=z}, {name="air"})
        minetest.set_node({x=x, y=(y + 1), z=z}, {name="air"})
      end

      if inc_x > 0 then
        x = x + inc_x
        inc_x = inc_x - 1
      else
        z = z + move_z
        if z > z_max then
          z = z - 1
          move_z = -1
          inc_x = 1
          x = x + 1
        end
        if z < z_min then
          z = z + 1
          move_z = 1
          inc_x = 1
          x = x + 1
        end
      end

      wire_count = wire_count + 1

      if wire_count % 100 == 0 then
        minetest.chat_send_all("[ENERGY STRESS] done: " .. wire_count)
      end
    end

    minetest.chat_send_all("[ENERGY STRESS] testing full traversal 10 times...")
    local avg = 0
    local count = 0
    for i = 1, 10 do
      local t0_us = minetest.get_us_time()
      tech_api.energy.rediscover_networks()
      local t1_us = minetest.get_us_time()
      local millis = (t1_us - t0_us) / 1000
      avg = avg + millis
      count = count + 1
    end
    minetest.chat_send_all("[ENERGY STRESS] full traversal took " .. (avg / count) .. " ms (10 run avg)")
	end,
})
