-- ia_scribe/items.lua
-- Industrial replication tools for Gutenberg documents.

local modname = minetest.get_current_modname()
local log = ia_util.get_logger(modname)
local assert = ia_util.get_assert(modname)

-- Helper: Get the text or identity of what is being pointed at
local function get_source_stack(pointed_thing)
    if pointed_thing.type ~= "object" then return nil end
    local target = pointed_thing.ref
    
    local stack
    if target:is_player() then
        stack = target:get_wielded_item()
    elseif target:get_luaentity() and target:get_luaentity().name == "__builtin:item" then
        stack = ItemStack(target:get_luaentity().itemstring)
    end
    
    if stack and minetest.get_item_group(stack:get_name(), "book") > 0 then
        return stack
    end
    return nil
end

-- TIER I & II Logic: Copying Text
local function run_press(itemstack, user, pointed_thing, reusable)
    local source = get_source_stack(pointed_thing)
    
    -- STATE A: Pointing at nothing -> Return nil to trigger Gutenberg's default reader
    if not source then
        return nil 
    end

    -- STATE B: Pointing at a book -> Perform the imprint
    local source_meta = source:get_meta()
    local text = source_meta:get_string("text")
    if text == "" then 
        minetest.chat_send_player(user:get_player_name(), "Source document is blank. Aborting.")
        return itemstack
    end

    local meta = itemstack:get_meta()
    local pname = user:get_player_name()

    if reusable then
        -- Mese Press imprints onto itself
        meta:set_string("text", text)
        meta:set_string("title", "Mese Press Log")
        meta:set_string("owner", pname)
        
        minetest.sound_play("default_place_node_metal", {pos = user:get_pos(), gain = 0.5})
        -- Trigger immediate feedback by showing the reader after imprinting
        return nil 
    else
        -- Carbon Press spawns a separate book
        local copy = ItemStack("default:book_written")
        local c_meta = copy:get_meta()
        
        c_meta:set_string("text", text)
        c_meta:set_string("title", "Carbon Copy")
        c_meta:set_string("owner", pname)

        local inv = user:get_inventory()
        if inv:room_for_item("main", copy) then
            inv:add_item("main", copy)
        else
            minetest.add_item(user:get_pos(), copy)
        end

        minetest.sound_play("paper_settle", {pos = user:get_pos(), gain = 0.8})
        itemstack:take_item()
        return itemstack
    end
end

-- TIER III Logic: Identity Cloning
local function run_matrix(itemstack, user, pointed_thing)
    local source = get_source_stack(pointed_thing)
    if not source then return nil end 
    
    local name = source:get_name()
    local source_meta = source:get_meta()
    local text = source_meta:get_string("text")

    local new_stack = ItemStack(name)
    local n_meta = new_stack:get_meta()
    n_meta:set_string("text", text)
    n_meta:set_string("title", source_meta:get_string("title"))
    n_meta:set_string("owner", source_meta:get_string("owner"))
    
    minetest.sound_play("default_tool_breaks", {pos = user:get_pos(), gain = 0.5})
    return new_stack
end

--- REGISTRATIONS ---
-- Using ia_gutenberg.register_document ensures these have reader capabilities.

-- ia_scribe/items.lua
-- ... (helper functions and logic remain unchanged)

--- REGISTRATIONS ---

ia_gutenberg.register_document(modname, "carbon_press", {
    title = "Carbon Press",
    description = "Disposable. Consumed to create a standard copy of a book.",
    -- Visuals following ia_crapht pattern
    icon = "dye_black.png",
    icon_color = "#000000", -- Black
    on_use = function(itemstack, user, pointed_thing)
        return run_press(itemstack, user, pointed_thing, false)
    end,
    get_text = function(itemstack) return itemstack:get_meta():get_string("text") end,
})

ia_gutenberg.register_document(modname, "mese_press", {
    title = "Mese-Powered Press",
    description = "Reusable. Imprints the target's text onto itself.",
    -- Visuals following ia_crapht pattern
    icon = "default_mese_crystal.png",
    icon_color = "#ffff00", -- Mese Yellow
    on_use = function(itemstack, user, pointed_thing)
        return run_press(itemstack, user, pointed_thing, true)
    end,
    get_text = function(itemstack) return itemstack:get_meta():get_string("text") end,
})

ia_gutenberg.register_document(modname, "diamond_matrix", {
    title = "Diamond Matrix",
    description = "Clones identity and data. Becomes the target item.",
    -- Visuals following ia_crapht pattern
    icon = "default_diamond.png",
    icon_color = "#00ffff", -- Diamond Cyan
    on_use = function(itemstack, user, pointed_thing)
        return run_matrix(itemstack, user, pointed_thing)
    end,
    get_text = function(itemstack) return itemstack:get_meta():get_string("text") end,
})
