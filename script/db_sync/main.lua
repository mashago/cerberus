
local do_db_sync = nil

local function main_entry()
	Log.info("sync_db main_entry")

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	g_funcs.connect_to_mysql(xml_doc)

	-- sync db
	do_db_sync()
	
end

do_db_sync = function()
	Log.debug("do_db_sync")
end

main_entry()
