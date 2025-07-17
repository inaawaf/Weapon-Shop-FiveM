local weaponMarkers = {
    {x = -1757.7605, y = -2785.8469, z = 13.9447},
}

local excludedWeapons = {
    ["WEAPON_RPG"] = true,
    ["WEAPON_GRENADE"] = true,
    ["WEAPON_MOLOTOV"] = true,
    ["WEAPON_HOMINGLAUNCHER"] = true,
    ["WEAPON_PROXMINE"] = true,
    ["WEAPON_PIPEBOMB"] = true
}

local categories = {
    ["Pistols"] = {
        "WEAPON_PISTOL",
        "WEAPON_COMBATPISTOL",
        "WEAPON_APPISTOL",
        "WEAPON_PISTOL50"
    },
    ["Light SMGs"] = {
        "WEAPON_MICROSMG",
        "WEAPON_SMG",
        "WEAPON_MINISMG"
    },
    ["Heavy Rifles"] = {
        "WEAPON_ASSAULTRIFLE",
        "WEAPON_CARBINERIFLE",
        "WEAPON_SPECIALCARBINE"
    },
    ["Snipers"] = {
        "WEAPON_SNIPERRIFLE",
        "WEAPON_HEAVYSNIPER"
    },
    ["Shotguns"] = {
        "WEAPON_PUMPSHOTGUN",
        "WEAPON_SAWNOFFSHOTGUN"
    }
}

local mainMenu = nil
local menuPool = NativeUI.CreatePool()
local controlsBlockedThread = nil

local markerDrawDistance = 50.0
local markerInteractDistance = 2.0

Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local sleep = 1000

        for _, marker in ipairs(weaponMarkers) do
            local dist = #(playerCoords - vector3(marker.x, marker.y, marker.z))

            if dist < markerDrawDistance then
                sleep = 1
                DrawMarker(1, marker.x, marker.y, marker.z - 1.0, 0.0, 0.0, 0.0, 0, 0, 0,
                    1.2, 1.2, 1.0, 255, 0, 0, 100, false, true, 2, nil, nil, false)

                if dist < markerInteractDistance then
                    DrawText3D(marker.x, marker.y, marker.z + 0.5, "~g~[E]~w~ Open Weapon Shop")
                    if IsControlJustReleased(0, 38) then
                        OpenWeaponShop()
                    end
                end
            end
        end

        menuPool:ProcessMenus()
        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.45, 0.45)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function OpenWeaponShop()
    if mainMenu then
        mainMenu:Visible(true)
        BlockControlsWhileMenuOpen()
        return
    end

    mainMenu = NativeUI.CreateMenu("Weapon Shop", "Select a category")
    menuPool:Add(mainMenu)

    for categoryName, weapons in pairs(categories) do
        local subMenu = menuPool:AddSubMenu(mainMenu, categoryName, "Choose a weapon from " .. categoryName)

        for _, weaponName in ipairs(weapons) do
            if not excludedWeapons[weaponName] then
                local weaponHash = GetHashKey(weaponName)
                local damage = GetWeaponDamage(weaponName)
                local item = NativeUI.CreateItem(weaponName, "Damage: " .. damage)
                item.Activated = function(sender, item)
                    GiveWeaponToPed(PlayerPedId(), weaponHash, 250, false, true)
                    TriggerEvent("chat:addMessage", { args = {"Received weapon: " .. weaponName} })
                end
                subMenu:AddItem(item)
            end
        end
    end

    menuPool:RefreshIndex()
    mainMenu:Visible(true)
    BlockControlsWhileMenuOpen()
end

function BlockControlsWhileMenuOpen()
    if controlsBlockedThread then return end

    controlsBlockedThread = Citizen.CreateThread(function()
        while mainMenu and mainMenu:Visible() do
            DisableControlAction(0, 1, true)   -- Look left/right
            DisableControlAction(0, 2, true)   -- Look up/down
            DisableControlAction(0, 106, true) -- Mouse override
            DisableControlAction(0, 30, true)  -- Move left/right
            DisableControlAction(0, 31, true)  -- Move forward/back
            Wait(0)
        end
        controlsBlockedThread = nil
    end)
end

function GetWeaponDamage(weaponName)
    local defaultDamages = {
        ["WEAPON_PISTOL"] = 26,
        ["WEAPON_COMBATPISTOL"] = 27,
        ["WEAPON_APPISTOL"] = 28,
        ["WEAPON_PISTOL50"] = 32,
        ["WEAPON_MICROSMG"] = 20,
        ["WEAPON_SMG"] = 22,
        ["WEAPON_MINISMG"] = 23,
        ["WEAPON_ASSAULTRIFLE"] = 30,
        ["WEAPON_CARBINERIFLE"] = 32,
        ["WEAPON_SPECIALCARBINE"] = 33,
        ["WEAPON_SNIPERRIFLE"] = 101,
        ["WEAPON_HEAVYSNIPER"] = 157,
        ["WEAPON_PUMPSHOTGUN"] = 40,
        ["WEAPON_SAWNOFFSHOTGUN"] = 50
    }

    return defaultDamages[weaponName] or "N/A"
end
