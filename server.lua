
ESX = exports["es_extended"]:getSharedObject()
ESX.RegisterUsableItem('radio', function(source) local xPlayer = ESX.GetPlayerFromId(source) TriggerClientEvent('Radio.Set', source, true) TriggerClientEvent('Radio.Toggle', source) end)