-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

-- A convenienence function that attempts to do a generic crafting operation.
-- "request_stack" is an item stack that it is assumed the player has removed from a set of possible outputs, it is assumed that the contents of request_stack will be added to the destination inventory as a result of an existing inventory transfer and it will be deducted from the craft result.
-- source_inv, source_listname are where the raw materials will be taken from
-- destination_inv, destination_listname are where the crafting outputs will be placed.
-- player_or_pos is either a player object or a pos table. This is used for logging purposes and as a place to put output in the event that destination_inv can't hold it all.
simplecrafting_lib.craft_stack = function(crafting_type, request_stack, source_inv, source_listname, destination_inv, destination_listname, player_or_pos)
	local player
	local pos
	if type(player_or_pos) == "userdata" then
		player = player_or_pos
	elseif type(player_or_pos) == "table" then
		pos = player_or_pos
	end

	local craft_result = simplecrafting_lib.get_crafting_result(crafting_type, source_inv:get_list(source_listname), request_stack)
	if craft_result then
		if simplecrafting_lib.remove_items(source_inv, source_listname, craft_result.input) then
			-- We've successfully paid for this craft's output.
			local item_name = request_stack:get_name()
			
			-- log it
			if player then
				minetest.log("action", S("@1 crafts @2", player:get_player_name(), item_name .. " " .. tostring(craft_result.output[item_name])))
			elseif pos then
				minetest.log("action", S("@1 was crafted at @2", item_name .. " " .. tostring(craft_result.output[item_name]), minetest.pos_to_string(pos)))
			else
				minetest.log("action", S("@1 was crafted somewhere by someone", item_name .. " " .. tostring(craft_result.output[item_name])))
			end
					
			-- subtract the amount of output that the player's getting anyway (from having taken it)
			craft_result.output[item_name] = craft_result.output[item_name] - request_stack:get_count()
			
			local total_output = simplecrafting_lib.count_list_add(craft_result.output, craft_result.returns)
			
			-- stuff the output in the target inventory, or the player's inventory if it doesn't fit, finally dropping anything that doesn't fit at the player's location
			local leftover = simplecrafting_lib.add_items(destination_inv, destination_listname, total_output)
			if player then
				leftover = simplecrafting_lib.add_items(player:get_inventory(), "main", leftover)
				simplecrafting_lib.drop_items(player:getpos(), leftover)
			elseif pos then
				simplecrafting_lib.drop_items(pos, leftover)
			else
				local still_has_leftovers = false
				for item, count in pairs(leftover) do
					still_has_leftovers = true
					break
				end
				if still_has_leftovers then
					minetest.log("error", S("After crafting @1 some output items could not be placed into an inventory or dropped in world, and were lost.",
						item_name .. " " .. tostring(craft_result.output[item_name])))
				end
			end
			return true
		end
	end
	return false
end