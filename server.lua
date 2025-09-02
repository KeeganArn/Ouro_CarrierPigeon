-- server.lua with UID-based carrier pigeon system

local VorpCore = {}
local playerPigeonMap = {}

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

-- Database Setup
MySQL.ready(function()
    MySQL.Async.execute([[CREATE TABLE IF NOT EXISTS carrier_pigeons (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pigeon_uid VARCHAR(255) NOT NULL UNIQUE,
        owner_charid INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );]])

    MySQL.Async.execute([[CREATE TABLE IF NOT EXISTS carrier_pigeon_messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        recipient_pigeon_uid VARCHAR(255) NOT NULL,
        sender_pigeon_uid VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );]])

    MySQL.Async.execute([[CREATE TABLE IF NOT EXISTS carrier_pigeon_training (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pigeon_uid VARCHAR(255) NOT NULL,
        location_name VARCHAR(100) NOT NULL,
        coords_x FLOAT NOT NULL,
        coords_y FLOAT NOT NULL,
        coords_z FLOAT NOT NULL
    );]])
end)

local function generateUniquePigeonUID()
    return "PG" .. math.random(100000, 999999) .. "_" .. os.time()
end

AddEventHandler("playerDropped", function()
    playerPigeonMap[source] = nil
end)

-- Usable Item
exports.vorp_inventory:registerUsableItem("carrier_pigeon", function(data)
    local src = data.source or data.player or data._source or data.id
    if not src then return end

    local User = VorpCore.getUser(src)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character or not Character.charIdentifier then return end

    local charid = Character.charIdentifier
    local itemData = data.item
    local metadata = itemData.metadata or {}
    local pigeonUid = metadata.pigeon_uid

    if not pigeonUid then
        -- Generate new pigeon UID
        pigeonUid = "P" .. math.random(100000, 999999)

        -- Insert into DB
        MySQL.Async.execute("INSERT INTO carrier_pigeons (pigeon_uid, owner_charid) VALUES (?, ?)", {
            pigeonUid, charid
        })

        -- Update metadata on existing item
        exports.vorp_inventory:setItemMetadata(src, itemData.id, { pigeon_uid = pigeonUid }, 1, function(success)
            if not success then
                print("[ERROR] Failed to update pigeon metadata")
            end
        end)

        -- Exit early so user can reuse it now that it has metadata
        TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "Pigeon registered. Try using it again.", "menu_textures", "tick", 3000)
        return
    end

    -- Save to player session
    playerPigeonMap[src] = pigeonUid

    exports.vorp_inventory:closeInventory(src, 1)
    TriggerClientEvent("carrierpigeon:openUI", src)
    TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "Your pigeon flaps its wings eagerly.", "menu_textures", "tick", 3000)
end)




-- Send Message
RegisterServerEvent("carrierpigeon:send")
AddEventHandler("carrierpigeon:send", function(targetPigeonId, message)
    local src = source
    local senderPigeonId = playerPigeonMap[src]
    if not senderPigeonId then return end

    exports.vorp_inventory:getUserInventoryItems(src, function(inventory)
        local hasPen, hasBlankPaper = false, false
        for _, item in pairs(inventory) do
            if item.name == "pen" and item.count >= 1 then
                hasPen = true
            elseif item.name == "paper" and item.count >= 1 and (not item.metadata or next(item.metadata) == nil) then
                hasBlankPaper = true
            end
        end

        if not hasPen or not hasBlankPaper then
            TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "You need a pen and a blank sheet of paper.", "generic_textures", "cross", 5000)
            return
        end

        exports.vorp_inventory:subItem(src, "paper", 1, nil)

        local targetOnline = false
        local targetPlayer = nil
        for player, uid in pairs(playerPigeonMap) do
            if uid == targetPigeonId then
                targetOnline = true
                targetPlayer = player
                break
            end
        end

        TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "Your pigeon was dispatched.", "menu_textures", "tick", 5000)
        TriggerClientEvent("carrierpigeon:closeUI", src)
        TriggerClientEvent("carrierpigeon:sendAnimation", src)

        if not targetOnline then
            TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "The pigeon could not find the recipient.", "generic_textures", "cross", 5000)
            return
        end

        local senderCoords = GetEntityCoords(GetPlayerPed(src))
        local targetCoords = GetEntityCoords(GetPlayerPed(targetPlayer))
        local distance = #(senderCoords - targetCoords)

        local delay = math.floor(math.min(300, math.max(10, distance * 0.15))) * 1000

        SetTimeout(delay, function()
            MySQL.Async.fetchAll("SELECT * FROM carrier_pigeon_training WHERE pigeon_uid = ?", { senderPigeonId }, function(rows)
                local valid = false
                for _, row in ipairs(rows) do
                    local dist = math.abs(row.coords_x - targetCoords.x) <= 100.0 and math.abs(row.coords_y - targetCoords.y) <= 100.0
                    if dist then valid = true break end
                end

                if not valid then
                    TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "The pigeon does not know that area.", "generic_textures", "cross", 5000)
                    return
                end

                TriggerClientEvent("carrierpigeon:receiveAnimation", targetPlayer)
                MySQL.Async.execute([[INSERT INTO carrier_pigeon_messages (recipient_pigeon_uid, sender_pigeon_uid, message) VALUES (?, ?, ?)]], { targetPigeonId, senderPigeonId, message })
                Wait(7000)
                TriggerClientEvent("vorp:NotifyLeft", targetPlayer, "Carrier Pigeon", "A pigeon has arrived for you.", "menu_textures", "tick", 5000)
            end)
        end)
    end)
end)

-- Inbox
RegisterServerEvent("carrierpigeon:requestInbox")
AddEventHandler("carrierpigeon:requestInbox", function()
    local src = source
    local pigeonId = playerPigeonMap[src]
    if not pigeonId then 
        print("[ERROR] No pigeon UID found in playerPigeonMap for src:", src)
        return 
    end

    print("[DEBUG] Fetching messages for pigeon UID:", pigeonId)

    MySQL.Async.fetchAll("SELECT * FROM carrier_pigeon_messages WHERE recipient_pigeon_uid = ?", { pigeonId }, function(results)
        print("[DEBUG] Messages fetched:", json.encode(results or {}))
        TriggerClientEvent("carrierpigeon:receiveInbox", src, pigeonId, results or {})
    end)
end)


RegisterServerEvent("carrierpigeon:deleteMessage")
AddEventHandler("carrierpigeon:deleteMessage", function(messageId)
    local src = source
    local pigeonId = playerPigeonMap[src]
    if not pigeonId then return end

    MySQL.Async.execute("DELETE FROM carrier_pigeon_messages WHERE id = ? AND recipient_pigeon_uid = ?", { messageId, pigeonId })
end)

-- Train Pigeon
RegisterServerEvent("carrierpigeon:trainPigeon")
AddEventHandler("carrierpigeon:trainPigeon", function(locationName, coords)
    local src = source
    local pigeonId = playerPigeonMap[src]
    if not pigeonId then return end

    if not locationName or locationName == "" then
        locationName = "Zone " .. math.random(1000, 9999)
    end

    TriggerClientEvent("carrierpigeon:closeUI", src)
    TriggerClientEvent("carrierpigeon:sendAnimation", src)
    TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "Training in progress... stay nearby.", "generic_textures", "tick", 5000)

    local startCoords = coords
    SetTimeout(90000, function()
        local playerPed = GetPlayerPed(src)
        if not DoesEntityExist(playerPed) then return end
        local currentCoords = GetEntityCoords(playerPed)

        if #(vector3(startCoords.x, startCoords.y, startCoords.z) - currentCoords) > 100.0 then
            TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "Training failed: You moved too far.", "generic_textures", "cross", 5000)
            return
        end

        MySQL.Async.execute("INSERT INTO carrier_pigeon_training (pigeon_uid, location_name, coords_x, coords_y, coords_z) VALUES (?, ?, ?, ?, ?)", {
            pigeonId, locationName, coords.x, coords.y, coords.z
        })

        TriggerClientEvent("carrierpigeon:receiveAnimation", src)
        Wait(7000)
        TriggerClientEvent("vorp:NotifyLeft", src, "Carrier Pigeon", "Training complete for zone: " .. locationName, "menu_textures", "tick", 5000)
    end)
end)

-- Trained Zones
RegisterServerEvent("carrierpigeon:getTrainedZones")
AddEventHandler("carrierpigeon:getTrainedZones", function()
    local src = source
    local pigeonId = playerPigeonMap[src]
    if not pigeonId then return end

    MySQL.Async.fetchAll("SELECT location_name, coords_x, coords_y, coords_z FROM carrier_pigeon_training WHERE pigeon_uid = ?", { pigeonId }, function(zones)
        TriggerClientEvent("carrierpigeon:trainedZones", src, zones or {})
    end)
end)

RegisterServerEvent("carrierpigeon:getTrainedZonesForBlips")
AddEventHandler("carrierpigeon:getTrainedZonesForBlips", function()
    local src = source
    local pigeonId = playerPigeonMap[src]
    if not pigeonId then return end

    MySQL.Async.fetchAll("SELECT location_name, coords_x, coords_y, coords_z FROM carrier_pigeon_training WHERE pigeon_uid = ?", { pigeonId }, function(zones)
        TriggerClientEvent("carrierpigeon:showAllZoneBlips", src, zones or {})
    end)
end)
