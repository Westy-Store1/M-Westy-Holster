
local framework = nil
local vRP = nil
local QBCore = nil
local ESX = nil

local function DetectFramework()
    local configFw = Config.Framework or 'auto'
    
    if configFw == 'vrp' or (configFw == 'auto' and GetResourceState('vrp') == 'started') then
        local utils = LoadResourceFile('vrp', 'lib/utils.lua')
        if utils then
            local f, err = load(utils)
            if f then
                f() -- Define a função global 'module'
                local Proxy = module("vrp", "lib/Proxy")
                vRP = Proxy.getInterface("vRP")
                framework = 'vrp'
            end
        end
    elseif configFw == 'qb' or (configFw == 'auto' and GetResourceState('qb-core') == 'started') then
        QBCore = exports['qb-core']:GetCoreObject()
        framework = 'qb'
    elseif configFw == 'qbox' or (configFw == 'auto' and (GetResourceState('qbx-core') == 'started' or GetResourceState('qbox') == 'started')) then
        framework = 'qbox'
    elseif configFw == 'esx' or (configFw == 'auto' and GetResourceState('es_extended') == 'started') then
        ESX = exports['es_extended']:getSharedObject()
        framework = 'esx'
    elseif configFw == 'standalone' then
        framework = 'standalone'
    end
end

DetectFramework()

lib.callback.register('m-westy_holster:getOwnedWeapons', function(source)
    local dataResponse = {
        weapons = {},
        isPolice = false
    }

    if framework == 'vrp' then
        local user_id = nil
        pcall(function() user_id = vRP.getUserId({source}) end)
        if not user_id or user_id == false then
            pcall(function() user_id = vRP.getUserId(source) end)
        end
        if not user_id or user_id == false then
            pcall(function() user_id = vRP.Passport(source) end)
        end

        if user_id then
            local isPol = false
            pcall(function() isPol = vRP.hasPermission({user_id, "police.permission"}) or vRP.hasPermission({user_id, "policial.permissao"}) end)
            if not isPol then
                pcall(function() isPol = vRP.hasPermission(user_id, "police.permission") or vRP.hasPermission(user_id, "policial.permissao") end)
            end
            if not isPol then
                pcall(function() isPol = vRP.HasPermission({user_id, "police.permission"}) or vRP.HasPermission({user_id, "policial.permissao"}) end)
            end
            if not isPol then
                pcall(function() isPol = vRP.HasPermission(user_id, "police.permission") or vRP.HasPermission(user_id, "policial.permissao") end)
            end
            dataResponse.isPolice = isPol

            local data = nil
            pcall(function() data = vRP.Datatable(user_id) end)
            if not data or data == false then
                pcall(function() data = vRP.Datatable({user_id}) end)
            end
            if not data or data == false then
                pcall(function() data = vRP.getUserDataTable({user_id}) end)
            end
            if not data or data == false then
                pcall(function() data = vRP.getUserDataTable(user_id) end)
            end

            if data then
                local inventory = data.inventory or data.inv or data.Inventory
                
                -- Se não achou na dataTable, tenta obter via vRP.Inventory(user_id)
                if not inventory then
                    pcall(function() inventory = vRP.Inventory({user_id}) end)
                    if not inventory or inventory == false then
                        pcall(function() inventory = vRP.Inventory(user_id) end)
                    end
                end

                if inventory then
                    for slot, itemData in pairs(inventory) do
                        local itemName = nil
                        if type(itemData) == "table" then
                            itemName = itemData.item or itemData.name or itemData[1]
                        elseif type(itemData) == "string" then
                            itemName = itemData
                        else
                            itemName = tostring(slot)
                        end

                        if itemName then
                            -- Limpa qualquer sufixo de durabilidade (ex: -1874289)
                            local cleanedItem = itemName
                            local dashIndex = string.find(itemName, "-")
                            if dashIndex then
                                cleanedItem = string.sub(itemName, 1, dashIndex - 1)
                            end

                            if string.sub(cleanedItem, 1, 6) == "wbody|" then
                                local weaponName = string.upper(string.sub(cleanedItem, 7))
                                dataResponse.weapons[weaponName] = true
                            elseif string.sub(cleanedItem, 1, 7) == "WEAPON_" then
                                local weaponName = string.upper(cleanedItem)
                                dataResponse.weapons[weaponName] = true
                            end
                        end
                    end
                end
            end
        end

    elseif framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            -- QBCore Police job check
            dataResponse.isPolice = (Player.PlayerData.job and Player.PlayerData.job.name == 'police')
            
            local inventory = Player.PlayerData.items
            if inventory then
                for _, itemData in pairs(inventory) do
                    if itemData and itemData.name then
                        local weaponName = string.upper(itemData.name)
                        if string.sub(weaponName, 1, 7) == "WEAPON_" then
                            dataResponse.weapons[weaponName] = true
                        end
                    end
                end
            end
        end

    elseif framework == 'qbox' then
        local Player = exports['qbx-core']:GetPlayer(source)
        if Player then
            -- QBox Police job check
            dataResponse.isPolice = (Player.PlayerData.job and Player.PlayerData.job.name == 'police')
            
            local inventory = Player.PlayerData.items
            if inventory then
                for _, itemData in pairs(inventory) do
                    if itemData and itemData.name then
                        local weaponName = string.upper(itemData.name)
                        if string.sub(weaponName, 1, 7) == "WEAPON_" then
                            dataResponse.weapons[weaponName] = true
                        end
                    end
                end
            end
        end

    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            -- ESX Police job check
            dataResponse.isPolice = (xPlayer.job and xPlayer.job.name == 'police')
            
            local inventory = xPlayer.getInventory(false)
            if inventory then
                for _, itemData in pairs(inventory) do
                    if itemData and itemData.count and itemData.count > 0 then
                        local weaponName = string.upper(itemData.name)
                        if string.sub(weaponName, 1, 7) == "WEAPON_" then
                            dataResponse.weapons[weaponName] = true
                        end
                    end
                end
            end
        end
    end

    return dataResponse
end)
