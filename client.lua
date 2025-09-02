RegisterNetEvent("carrierpigeon:openUI")
AddEventHandler("carrierpigeon:openUI", function()
    print("[CLIENT DEBUG] carrierpigeon:openUI triggered")
    TriggerEvent("vorp_inventory:forceClose")

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
    TriggerServerEvent("carrierpigeon:requestInbox")
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hide" })
    cb("ok")
end)

RegisterNUICallback("sendMessage", function(data, cb)
    TriggerServerEvent("carrierpigeon:send", data.target, data.message)
    cb("ok")
end)

RegisterNetEvent("carrierpigeon:receiveInbox")
AddEventHandler("carrierpigeon:receiveInbox", function(pigeonId, messages)
    SendNUIMessage({
        action = "loadInbox",
        messages = messages,
        pigeonId = pigeonId
    })
end)

RegisterNetEvent("carrierpigeon:closeUI")
AddEventHandler("carrierpigeon:closeUI", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hide" })
end)

RegisterNUICallback("deleteMessage", function(data, cb)
    TriggerServerEvent("carrierpigeon:deleteMessage", data.id)
    cb("ok")
end)

RegisterNUICallback("refreshInbox", function(_, cb)
    TriggerServerEvent("carrierpigeon:requestInbox")
    cb("ok")
end)

RegisterNetEvent("carrierpigeon:sendAnimation")
AddEventHandler("carrierpigeon:sendAnimation", function()
    local player = PlayerPedId()
    if not IsPedOnMount(player) and not IsPedInAnyVehicle(player, true) then
        ClearPedTasksImmediately(player)
        TaskStartScenarioInPlace(player, GetHashKey("WORLD_PLAYER_DYNAMIC_KNEEL"), 0, true, false, false, false)
        Wait(2500)

        local pigeonHash = GetHashKey("A_C_Pigeon")
        RequestModel(pigeonHash)
        while not HasModelLoaded(pigeonHash) do Wait(10) end

        local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.25, 0.25, -0.25))
        local pigeon = CreatePed("A_C_Pigeon", x, y, z, true, false, true)
        Citizen.InvokeNative(0x77FF8D35EEC6BBC4, pigeon, 1, 0)
        TaskFlyAway(pigeon, true)

        Wait(1000)
        ClearPedTasks(player)

        Wait(30000)
        DeleteEntity(pigeon)
    end
end)

RegisterNetEvent("carrierpigeon:receiveAnimation")
AddEventHandler("carrierpigeon:receiveAnimation", function()
    local player = PlayerPedId()
    local pigeonHash = GetHashKey("A_C_Pigeon")
    RequestModel(pigeonHash)
    while not HasModelLoaded(pigeonHash) do Wait(10) end

    local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 10.0, 10.0, 10.0))
    local a,b,c = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 0.0))
    local pigeon = CreatePed("A_C_Pigeon", x, y, z, true, false, true)
    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, pigeon, 1, 0)
    TaskFlyToCoord(pigeon, 2, a, b, c, true, true)

    Wait(7000)
    DeleteEntity(pigeon)
end)

RegisterNUICallback("trainPigeon", function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local locationName = data.locationName or "Unknown"
    TriggerServerEvent("carrierpigeon:trainPigeon", locationName, coords)
    cb("ok")
end)



RegisterNUICallback("showZone", function(data, cb)
    print("[CLIENT DEBUG] Showing single zone blip...")
    local coords = vector3(data.coords_x, data.coords_y, data.coords_z)
    local blip = N_0x554d9d53f696d002(1664425300, coords) -- area blip
    SetBlipSprite(blip, -185399168, true) -- blue area sprite
    Citizen.CreateThread(function()
        Wait(20000)
        RemoveBlip(blip)
    end)
    cb("ok")
end)

RegisterNetEvent("carrierpigeon:showAllZoneBlips")
AddEventHandler("carrierpigeon:showAllZoneBlips", function(zones)
    print("[CLIENT DEBUG] Showing all zone blips...")
    for _, zone in ipairs(zones) do
        local coords = vector3(zone.coords_x, zone.coords_y, zone.coords_z)
        local blip = N_0x554d9d53f696d002(1664425300, coords)
        SetBlipSprite(blip, -185399168, true) -- blue area sprite
        Citizen.CreateThread(function()
            Wait(20000)
            RemoveBlip(blip)
        end)
    end
end)



RegisterNUICallback("getTrainedZones", function(_, cb)
    print("[CLIENT DEBUG] Requesting trained zones from server...")
    TriggerServerEvent("carrierpigeon:getTrainedZones")
    cb("ok")
end)

RegisterNetEvent("carrierpigeon:trainedZones")
AddEventHandler("carrierpigeon:trainedZones", function(zones)
    print("[CLIENT DEBUG] Received zones:", json.encode(zones or {}))
    SendNUIMessage({
        action = "displayTrainedZones",
        zones = zones or {}
    })
end)

-- Display a 200m teal area blip at the given coordinates

function ShowZoneBlip(coords, name)
    -- Create area-style blip only (no icon)
    local blip = Citizen.InvokeNative(0x45F13B7E0A15C880, GetHashKey("BLIP_STYLE_AREA"), coords.x, coords.y, coords.z, 100.0)
    -- Make it teal colored
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey("BLIP_MODIFIER_MP_COLOR_5"))
    -- Auto-remove after 20s
    Citizen.SetTimeout(20000, function()
        RemoveBlip(blip)
    end)
end




-- Show a single zone's blip from UI
RegisterNUICallback("showZone", function(data, cb)
    print("[CLIENT DEBUG] Showing single zone blip...")
    print("[CLIENT DEBUG] Data from NUI: " .. json.encode(data))

    local x = data.x or data.coords_x
    local y = data.y or data.coords_y
    local z = data.z or data.coords_z or 1.0  -- Default to 1.0 if z is missing
    local name = data.name or data.location_name or "Training Zone"

    if not x or not y then
        print("[CLIENT ERROR] Missing x or y in showZone!")
        cb("fail")
        return
    end

    local coords = vector3(x, y, z)
    ShowZoneBlip(coords, name)
    cb("ok")
end)


RegisterNUICallback("showAllZones", function(_, cb)
    print("[CLIENT DEBUG] Triggering blip display request for all trained zones...")
    TriggerServerEvent("carrierpigeon:getTrainedZonesForBlips")
    cb("ok")
end)

RegisterNetEvent("carrierpigeon:showAllZoneBlips")
AddEventHandler("carrierpigeon:showAllZoneBlips", function(zones)
    print("[CLIENT DEBUG] Drawing blips for all trained zones...")
    for _, zone in ipairs(zones) do
        local coords = vector3(zone.coords_x, zone.coords_y, zone.coords_z)
        ShowZoneBlip(coords, zone.location_name)
    end
end)











