Name = "power-profiles"
NamePretty = "Power profiles"
HideFromProviderlist = true

function GetEntries()
    local entries = {}


    local current_handle = io.popen(
        "powerprofilesctl list | awk '/^\\*/ { gsub(/^[*[:space:]]+|:$/,\"\"); print; exit }' 2>/dev/null"
    )
    local current_profile = ""
    if current_handle then
        current_profile = current_handle:read("*l") or ""
        current_handle:close()
    end


    local profiles_handle = io.popen(
        "powerprofilesctl list | awk '/^\\s*[* ]\\s*[a-zA-Z0-9\\-]+:$/ { gsub(/^[*[:space:]]+|:$/,\"\"); print }' 2>/dev/null"
    )

    if profiles_handle then
        local seen = {}
        for line in profiles_handle:lines() do
            local profile = line:match("^%s*(.-)%s*$")


            if profile ~= "" and not seen[profile] then
                seen[profile] = true


                local display_name = profile:gsub("-", " "):gsub("(%a)([%w_']*)", function(first, rest)
                    return first:upper() .. rest
                end)


                local is_current = (profile == current_profile)
                local subtext = is_current and "● Current" or ""

                table.insert(entries, {
                    Text = display_name,
                    Subtext = subtext,
                    Value = profile,
                    Actions = {
                        apply = "powerprofilesctl set "
                            .. profile
                            .. " && notify-send 'Power Profile' 'Set to: "
                            .. display_name
                            .. "'",
                    },
                })
            end
        end
        profiles_handle:close()
    end

    if #entries == 0 then
        table.insert(entries, {
            Text = "No power profiles found",
            Subtext = "Check powerprofilesctl",
            Value = "",
        })
    end

    return entries
end
