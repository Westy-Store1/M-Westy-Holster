-- M-Westy Holster Client Menu System using ox_lib

local function RegisterWeaponMenus()
    lib.registerContext({
        id = 'menu_armas_main',
        title = 'Menu de Posicionamento (Armas)',
        options = {
            {
                title = 'Posicionamento',
                description = 'Configurar a exibição e coldres de armas no corpo',
                arrow = true,
                menu = 'menu_armas_posicoes'
            }
        }
    })

    lib.registerContext({
        id = 'menu_armas_posicoes',
        title = 'Posições de Armas',
        menu = 'menu_armas_main',
        options = {
            {
                title = 'Posição (Pistola)',
                description = 'Escolher a posição ideal para suas pistolas',
                arrow = true,
                menu = 'menu_armas_pistolas'
            },
            {
                title = 'Posição (Rifles & Outras)',
                description = 'Escolher a posição para fuzis, SMGs e escopetas',
                arrow = true,
                menu = 'menu_armas_rifles'
            }
        }
    })

    lib.registerContext({
        id = 'menu_armas_pistolas',
        title = 'Posicionamento - Pistolas',
        menu = 'menu_armas_posicoes',
        options = {
            {
                title = 'Cintura (Frente)',
                description = 'Coldre frontal interno na calça',
                event = 'holster:client:SetPosition',
                args = { command = 'boxers' }
            },
            {
                title = 'Cintura (Atrás)',
                description = 'Posicionamento na lombar traseira',
                event = 'holster:client:SetPosition',
                args = { command = 'backhandgun' }
            },
            {
                title = 'Cintura (Lateral)',
                description = 'Posicionamento na lateral da cintura',
                event = 'holster:client:SetPosition',
                args = { command = 'waisthandgun' }
            },
            {
                title = 'Normal',
                description = 'Posicionamento padrão do coldre',
                event = 'holster:client:SetPosition',
                args = { command = 'handguns' }
            },
            {
                title = 'Peito Tático',
                description = 'Posicionado no peitoral do colete',
                event = 'holster:client:SetPosition',
                args = { command = 'chesthandgun' }
            },
            {
                title = 'Coldre de Cintura',
                description = 'Coldre externo tradicional na cintura',
                event = 'holster:client:SetPosition',
                args = { command = 'hiphandgun' }
            },
            {
                title = 'Coldre de Perna',
                description = 'Coldre de polímero acoplado na perna',
                event = 'holster:client:SetPosition',
                args = { command = 'leghandgun' }
            },
            {
                title = 'Coldre Universal',
                description = 'Posicionamento universal alternativo',
                event = 'holster:client:SetPosition',
                args = { command = 'handguns2' }
            }
        }
    })

    lib.registerContext({
        id = 'menu_armas_rifles',
        title = 'Posicionamento - Longas',
        menu = 'menu_armas_posicoes',
        options = {
            {
                title = 'Peitoral',
                description = 'Pendurado pela bandoleira no peito',
                event = 'holster:client:SetPosition',
                args = { command = 'tacticalrifle' }
            },
            {
                title = 'Costas',
                description = 'Preso pela bandoleira nas costas (Padrão)',
                event = 'holster:client:SetPosition',
                args = { command = 'assault' }
            }
        }
    })
end

-- Keymapping to easily open the menu
RegisterKeyMapping("menuInteracciones", "Menu de Posicionamento (Armas)", "keyboard", "F10")

RegisterCommand("menuInteracciones", function()
    menuInteracciones()
end)

function menuInteracciones()
    lib.showContext('menu_armas_main')
end

-- Networking Events for trigger integrations
RegisterNetEvent('menuInteracciones:client:OpenInteractionsMenu', function()
    menuInteracciones()
end)

RegisterNetEvent('menuInteracciones:client:OpenHolsterMenu', function()
    lib.showContext('menu_armas_posicoes')
end)

RegisterNetEvent('menuInteracciones:client:OpenPistolsMenu', function()
    lib.showContext('menu_armas_pistolas')
end)

RegisterNetEvent('menuInteracciones:client:OpenRiflesMenu', function()
    lib.showContext('menu_armas_rifles')
end)

RegisterNetEvent('holster:client:SetPosition', function(data)
    if data and data.command then
        ExecuteCommand("holster " .. data.command)
    end
end)

-- Execute setup on startup
RegisterWeaponMenus()
