-- M-Westy Holster Client Handling script (silenced, clean production code)

local Weapons = {}
local Loaded = true
local realWeapons = Config.RealWeapons
local handgunFlag = 'backhandgun'
local rifleFlag = 'assault'
local offsetCoords = nil
local weaponCategoryOffsets = {}
local showPistol = true
local showKnife = true
local holstered  = true
local removedByCar = false
local blocked = false
local switched = false

local OwnedWeapons = {}
local IsPolice = false

-- Dynamic Thread Wait Controller
local currentThreadDelay = 1500

-- Load Preferences on Resource Startup
local function LoadSavedPreferences()
    local savedHandgun = GetResourceKvpString("m-westy_holster:handgunFlag")
    local savedRifle = GetResourceKvpString("m-westy_holster:rifleFlag")
    if savedHandgun then
        handgunFlag = savedHandgun
    end
    if savedRifle then
        rifleFlag = savedRifle
    end
end

local RealWeaponsLookup = {}
for i = 1, #Config.RealWeapons do
    local w = Config.RealWeapons[i]
    local upperName = string.upper(w.name)
    w.hash = GetHashKey(w.name)
    RealWeaponsLookup[upperName] = w
end

CreateThread(function()
    LoadSavedPreferences()
    print("^3*Desenvolvido com excelência por M-Westy © 2026. Todos os direitos reservados.*^0")
    
    while true do
        if Config.Framework == 'standalone' then
            local playerPed = PlayerPedId()
            local tempOwned = {}
            for i = 1, #Config.RealWeapons do
                local w = Config.RealWeapons[i]
                if HasPedGotWeapon(playerPed, w.hash, false) then
                    tempOwned[string.upper(w.name)] = true
                end
            end
            OwnedWeapons = tempOwned
            IsPolice = false
        else
            local success, result = pcall(function()
                return lib.callback.await('m-westy_holster:getOwnedWeapons', 2000)
            end)
            if success and result then
                OwnedWeapons = result.weapons or {}
                IsPolice = result.isPolice or false
            end
        end
        Wait(5000)
    end
end)

local function HasWeaponItem(weaponName)
    local uppercaseName = string.upper(weaponName)
    return OwnedWeapons[uppercaseName] == true
end

local function GetPlayerJob()
    if IsPolice then
        return 'police'
    end
    return nil
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerJob = job.name
    if PlayerJob == 'police' then
        handgunFlag = 'handguns'
    end
    RemoveGears()
end)

RegisterNetEvent('qbx-core:client:OnJobUpdate', function(job)
    PlayerJob = job.name
    if PlayerJob == 'police' then
        handgunFlag = 'handguns'
    end
    RemoveGears()
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerJob = job.name
    if PlayerJob == 'police' then
        handgunFlag = 'handguns'
    end
    RemoveGears()
end)

local function DeleteWeaponObject(object)
    if DoesEntityExist(object) then
        SetEntityAsMissionEntity(object, false, true)
        DeleteObject(object)
    end
end

local function SpawnWeaponObject(model, cb)
    CreateThread(function()
        model = type(model) == 'number' and model or GetHashKey(model)
        if lib.requestModel(model, 5000) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local obj = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
            if cb then
                cb(obj)
            end
        end
    end)
end

function GetCoords(cat)
    for i=1, #weaponCategoryOffsets, 1 do
        if weaponCategoryOffsets[i].category == cat then
            return weaponCategoryOffsets[i].bone, weaponCategoryOffsets[i].x, weaponCategoryOffsets[i].y, weaponCategoryOffsets[i].z, weaponCategoryOffsets[i].xRot, weaponCategoryOffsets[i].yRot, weaponCategoryOffsets[i].zRot
        end
    end
end

function SetGear(weapon)
    local bone       = nil
    local boneX      = 0.0
    local boneY      = 0.0
    local boneZ      = 0.0
    local boneXRot   = 0.0
    local boneYRot   = 0.0
    local boneZRot   = 0.0
    local playerPed  = PlayerPedId()
    local model      = nil
    local isPolice   = false

    local job = GetPlayerJob()
    if job then
        isPolice = (job == 'police')
    end
    
    for i=1, #realWeapons, 1 do
        if realWeapons[i].name == weapon then
            if realWeapons[i].category == 'handguns' or realWeapons[i].category == 'revolver' then
                if isPolice and not switched then 
                    offsetCoords = "handguns"
                    handgunFlag = "handguns"
                else
                    offsetCoords = handgunFlag
                end
            elseif realWeapons[i].category == 'machine' or realWeapons[i].category == 'assault' or realWeapons[i].category == 'shotgun' or realWeapons[i].category == 'sniper' or realWeapons[i].category == 'heavy' then
				offsetCoords = rifleFlag
            else
                offsetCoords = realWeapons[i].category
            end

            bone, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot = GetCoords(offsetCoords)
            model      = realWeapons[i].model
            break
        end 
    end

    if not model then 
        return 
    end

    SpawnWeaponObject(model, function(object)
        local boneIndex = GetPedBoneIndex(playerPed, bone)
        AttachEntityToEntity(object, playerPed, boneIndex, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot, false, false, false, false, 2, true)
        Weapons[weapon] = object
    end)
end

function RemoveGear(weapon)
    local _Weapons = {}
    for weaponName, entity in pairs(Weapons) do
        if weaponName ~= weapon then
            _Weapons[weaponName] = entity
        else
            DeleteWeaponObject(entity)
        end
    end
    Weapons = _Weapons
end

function RemoveGears()
    for weaponName, entity in pairs(Weapons) do
        DeleteWeaponObject(entity)
    end
    Weapons = {}
end

function SetGears()
    for weaponNameUpper, _ in pairs(OwnedWeapons) do
        local weaponData = RealWeaponsLookup[weaponNameUpper]
        if weaponData then      
            SetGear(weaponData.name)
        end
    end
end

-- Optimized Loop with Dynamic Latency
Citizen.CreateThread(function()
    while not Loaded do
        Citizen.Wait(500)
    end

    local playerPed = PlayerPedId()
    SetPedCanSwitchWeapon(playerPed, true)
    realWeapons = Config.RealWeapons
    weaponCategoryOffsets = Config.WeaponCategoryOffsets
    
    while true do
        Citizen.Wait(currentThreadDelay)
        playerPed = PlayerPedId()

        local inVehicle = IsPedInAnyVehicle(playerPed, true)
        
        -- Dynamic Optimization Adjustment
        if inVehicle then
            currentThreadDelay = 3000 -- Low priority check inside car
            if not removedByCar then
                removedByCar = true
            end
        else
            currentThreadDelay = 800 -- High responsiveness check on foot
            if removedByCar then
                removedByCar = false
            end
        end
        
        local selectedWeapon = GetSelectedPedWeapon(playerPed)
        
        -- 1. Remove gears that are no longer owned, are equipped, or if removedByCar/not showPistol is active.
        for weaponName, entity in pairs(Weapons) do
            local weaponData = RealWeaponsLookup[string.upper(weaponName)]
            local isSelected = weaponData and (weaponData.hash == selectedWeapon) or false
            local hasItem = HasWeaponItem(weaponName)
            
            if not hasItem or isSelected or removedByCar or not showPistol then
                RemoveGear(weaponName)
            end
        end

        -- 2. Add gears for weapons that are owned and not equipped.
        if showPistol and not removedByCar then
            for weaponNameUpper, _ in pairs(OwnedWeapons) do
                local weaponData = RealWeaponsLookup[weaponNameUpper]
                if weaponData then
                    local weaponName = weaponData.name
                    local isSelected = (weaponData.hash == selectedWeapon)
                    
                    if not isSelected and not Weapons[weaponName] then
                        if (weaponData.category == 'handguns' or weaponData.category == 'revolver' or weaponData.category == 'bighandgun' or weaponData.category == 'smallmelee') then
                            if showPistol then
                                SetGear(weaponName)
                            end
                        elseif weaponData.model ~= nil then
                            SetGear(weaponName)
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('weapons:RemoveWeapons', function()
    RemoveGears()
end)

RegisterNetEvent('weapons:SetWeapons', function()
    SetGears()
end)

AddEventHandler('fivem-appearance:SkinLoaded', function()
    RemoveGears()
    Loaded = true
end)

-- Clean exit cleanup handler
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveGears()
    end
end)

RegisterCommand('holster', function(source, args)
    if args[1] == nil then
        TriggerEvent('menuInteracciones:client:OpenHolsterMenu')
    elseif args[1] == 'handguns' or args[1] == 'waisthandgun' then
        handgunFlag = args[1]
        SetResourceKvp("m-westy_holster:handgunFlag", handgunFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    elseif args[1] == 'backhandgun' then 
        handgunFlag = args[1]
        SetResourceKvp("m-westy_holster:handgunFlag", handgunFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    elseif args[1] == 'leghandgun' or args[1] == 'hiphandgun' or args[1] == 'handguns2' then
        handgunFlag = args[1]
        SetResourceKvp("m-westy_holster:handgunFlag", handgunFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    elseif args[1] == 'chesthandgun' then
        handgunFlag = args[1]
        SetResourceKvp("m-westy_holster:handgunFlag", handgunFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    elseif args[1] == 'boxers' then
        handgunFlag = args[1]
        SetResourceKvp("m-westy_holster:handgunFlag", handgunFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    elseif args[1] == 'assault' then
        rifleFlag = args[1]
        SetResourceKvp("m-westy_holster:rifleFlag", rifleFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    elseif args[1] == 'tacticalrifle' then
        rifleFlag = args[1]
        SetResourceKvp("m-westy_holster:rifleFlag", rifleFlag)
        lib.notify({ description = "Você alterou a posição da arma.", type = "inform" })
    end
    RemoveGears()
    switched = true
end)

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(100)
    end
end

function CheckWeapon(ped, newWeap)
    if IsEntityDead(ped) then
        blocked = false
        return false
    else
        for i = 1, #realWeapons do
            if GetHashKey(realWeapons[i].name) == newWeap then
                return true
            end
        end
        return false
    end
end

function loadAnimDict2(dict)
    while ( not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(0)
    end
end

local newWeapon

RegisterNetEvent("m-westy_holster:client:NewWeapon", function(weapon)
    newWeapon = weapon
end)

Citizen.CreateThread(function()
    loadAnimDict("rcmjosh4")
    loadAnimDict("reaction@intimidation@cop@unarmed")
    loadAnimDict("reaction@intimidation@1h")
    loadAnimDict2("combat@combat_reactions@pistol_1h_gang")
    loadAnimDict2("combat@combat_reactions@pistol_1h_hillbilly")
    loadAnimDict2("reaction@male_stand@big_variations@d")
    local rot = 0
    local wepCat
    local lastWep

    Citizen.Wait(0)

    while (true) do
        local ped = PlayerPedId()
        Citizen.Wait(50)
        
        rot = GetEntityHeading(ped)
        if not IsPedInAnyVehicle(ped, true) then
            if (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and not IsPedInParachuteFreeFall(ped) then
                newWeapon = GetSelectedPedWeapon(ped)
                wepCat = GetWeapontypeGroup(newWeapon)
                if CheckWeapon(ped, newWeapon)  then
                    if(wepCat == 416676503 or wepCat == 690389602) then
                        if holstered or lastWep ~= wepCat then
                            if handgunFlag == 'backhandgun' then
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "intro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            elseif handgunFlag == 'boxers' then
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            elseif handgunFlag == 'chesthandgun' then
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            elseif handgunFlag == 'leghandgun' then
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "reaction@male_stand@big_variations@d", "react_big_variations_m", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            else
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            end
                        else
                            blocked = false
                        end
                    else
                        if holstered or lastWep ~= wepCat then
                            if rifleFlag == 'tacticalrifle' then
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_hillbilly", "0", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            else 
                                blocked   = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "intro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = false
                                lastWep = wepCat
                            end
                        else
                            blocked = false
                        end
                    end
                else
                    if (lastWep == 416676503 or lastWep == 690389602) then
                        if not holstered then
                            if handgunFlag == 'backhandgun' then
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "outro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            elseif handgunFlag == 'boxers' then
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            elseif handgunFlag == 'leghandgun' then
                                TaskPlayAnimAdvanced(ped, "reaction@male_stand@big_variations@d", "react_big_variations_m", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            elseif handgunFlag == 'chesthandgun' then
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            else
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@cop@unarmed", "outro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            end
                        end
                    else 
                        if not holstered then
                            if rifleFlag == 'tacticalrifle' then
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            else
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "outro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
                                Citizen.Wait(700)
                                ClearPedTasks(ped)
                                holstered = true
                            end
                        end
                    end
                end
            elseif (GetVehiclePedIsTryingToEnter (ped) == 0) then
                holstered = false
            else
                SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            end
        else
            holstered = true
        end
    end
end)
