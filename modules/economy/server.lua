--TODO: rework everything

---@param source Source
---@param playerMoney table
---@param moneyType MoneyType
---@param amount number
---@param actionType 'add' | 'remove' | 'set'
---@param direction boolean
---@param reason? string
local function emitMoneyEvents(source, playerMoney, moneyType, amount, actionType, direction, reason)
    TriggerClientEvent('hud:client:OnMoneyChange', source, moneyType, amount, direction)
    TriggerClientEvent('QBCore:Client:OnMoneyChange', source, moneyType, amount, actionType, reason)
    TriggerEvent('QBCore:Server:OnMoneyChange', source, moneyType, amount, actionType, reason)

    if moneyType == 'bank' and actionType == 'remove' then
        TriggerClientEvent('qb-phone:client:RemoveBankMoney', source, amount)
    end

    local oxMoneyType = moneyType == 'cash' and 'money' or moneyType

    if accountsAsItems[oxMoneyType] then
        exports.ox_inventory:SetItem(source, oxMoneyType, playerMoney[moneyType])
    end
end

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was added
function AddMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    player.PlayerData.money[moneyType] += amount

    if not player.Offline then
        UpdatePlayerData(identifier)

        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'add', false, reason)
    end

    return true
end

exports('AddMoney', AddMoney)

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was removed
function RemoveMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    for _, mType in pairs(config.money.dontAllowMinus) do
        if mType == moneyType then
            if (player.PlayerData.money[moneyType] - amount) < 0 then
                return false
            end
        end
    end

    player.PlayerData.money[moneyType] -= amount

    if not player.Offline then
        UpdatePlayerData(identifier)
        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'remove', false, reason)
    end

    return true
end

exports('RemoveMoney', RemoveMoney)

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was set
function SetMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    player.PlayerData.money[moneyType] = amount

    if not player.Offline then
        UpdatePlayerData(identifier)
    end

    return true
end

exports('SetMoney', SetMoney)

---@param identifier Source | string
---@param moneyType MoneyType
---@return boolean | number amount or false if moneytype does not exist
function GetMoney(identifier, moneyType)
    if not moneyType then return false end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    return player.PlayerData.money[moneyType]
end

exports('GetMoney', GetMoney)