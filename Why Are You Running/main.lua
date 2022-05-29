if not SWAYRMod then
    local Self = {}
    Self.exclusions = {}

    local mod_data = {
        levels = {
            rat = {
                elements = {102230, 102242, 102243, 102244, 102246, 102316},
                name = "heist_rat",
                priority = 5
            },
            pal = {
                elements = {134713, 134763, 134813, 134863},
                name = "heist_pal",
                priority = 4
            },
            mus = {
                elements = {137238},
                name = "heist_mus",
                priority = 3
            },
            cane = {
                elements = {140713, 141013},
                name = "heist_cane",
                priority = 2
            },
            watchdogs_2 = {
                elements = {100683, 100690, 100699},
                name = "heist_watchdogs",
                priority = 1
            },
            pines = {
                elements = {130124, 130324, 130524, 130724},
                name = "heist_pines",
                priority = 0
            }
        },

        id = "swayr_mod_id",
        desc = "swayr_mod_desc",
        level_desc = "swayr_mod_level_desc",

        lang_path = ModPath .. "localization/",
        settings_path = SavePath .. "SWAYR_data.json"
    }

    function Self.load_language()
        local system_key = SystemInfo:language():key()
        local blt_index = LuaModManager:GetLanguageIndex()
        local blt_supported, system_language, blt_language = {
            "english", "chinese_traditional", "german", "spanish", "french", "indonesian", "turkish", "russian", "chinese_simplified"
        }

        for key, name in ipairs(file.GetFiles(mod_data.lang_path) or {}) do
            key = name:gsub("%.json$", ""):lower()

            if blt_supported[blt_index] == key then
                blt_language = mod_data.lang_path .. name
            end

            if key ~= "english" and system_key == key:key() then
                system_language = mod_data.lang_path .. name
                break
            end
        end

        return system_language or blt_language or ""
    end

    function Self.save()
        local f = io.open(mod_data.settings_path, "w+")

        if type(f) == "userdata" then
            local valid, data = pcall(json.encode, Self.exclusions)

            if valid and type(data) == "string" then
                f:write(data)
            end

            f:close()
        end
    end

    function Self.load()
        local f = io.open(mod_data.settings_path, "r")

        if type(f) == "userdata" then
            local valid, data = pcall(json.decode, f:read("*a"))

            if valid and type(data) == "table" then
                Self.exclusions = data
            end

            f:close()
        end
    end

    function Self.included(level_id)
        return type(mod_data.levels[level_id]) == "table" and not table.contains(Self.exclusions, level_id)
    end

    function Self.init()
        if RequiredScript == "lib/managers/menumanager" then
            Hooks:Add("LocalizationManagerPostInit", "SWAYRMod_LocalizationInit", function(self)
                self:add_localized_strings(
                    {
                        [mod_data.id] = "Why Are You Running?",
                        [mod_data.desc] = "Open mod settings.",
                        [mod_data.level_desc] = "Enable for \"$1\".\nLevel must be restarted for changes to apply."
                    }
                )

                self:load_localization_file(Self.load_language())
            end)

            Hooks:Add("MenuManagerSetupCustomMenus", "SWAYRMod_SetupMenu", function()
                MenuHelper:NewMenu(mod_data.id)

                MenuCallbackHandler[mod_data.id] = function(_, item)
                    if item then
                        for level_id in pairs(mod_data.levels) do
                            if item:name() == level_id then
                                if item:value() == "off" then
                                    table.insert(Self.exclusions, level_id)
                                else
                                    table.delete(Self.exclusions, level_id)
                                end

                                break
                            end
                        end
                    else
                        Self.save()
                    end
                end
            end)

            Hooks:Add("MenuManagerPopulateCustomMenus", "SWAYRMod_PopulateMenu", function()
                for level_id, data in pairs(mod_data.levels) do
                    local title_text = managers.localization:text(data.name)
                    local description_text = managers.localization:text(mod_data.level_desc, {title_text})

                    MenuHelper:AddToggle(
                        {
                            title = title_text,
                            desc = description_text,
                            value = Self.included(level_id),
                            priority = data.priority,
                            callback = mod_data.id,
                            menu_id = mod_data.id,
                            localized = false,
                            id = level_id
                        }
                    )
                end
            end)

            Hooks:Add("MenuManagerBuildCustomMenus", "SWAYRMod_BuildMenu", function(_, nodes)
                nodes[mod_data.id] = MenuHelper:BuildMenu(mod_data.id, {back_callback = mod_data.id})
                MenuHelper:AddMenuItem(nodes.blt_options, mod_data.id, mod_data.id, mod_data.desc)
            end)
        elseif Network:is_server() then
            local level_id = tostring(Global.level_data and Global.level_data.level_id):gsub("_day", "")

            if Self.included(level_id) then
                Hooks:PostHook(MissionScriptElement, "init", "PDCOMod_ElementInit", function(self)
                    if table.contains(mod_data.levels[level_id].elements, self._id) then
                        self:set_enabled(false)
                    end
                end)
            end
        end
    end

    SWAYRMod = Self
    Self.load()
end

SWAYRMod.init()