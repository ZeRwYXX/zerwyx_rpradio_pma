local Radio = {
	Has = true,
	Open = false,
	On = false,
	Enabled = true,
	Handle = nil,
	Prop = GetHashKey('prop_cs_hand_radio'),
	Bone = 28422,
	Offset = vector3(0.0, 0.0, 0.0),
	Rotation = vector3(0.0, 0.0, 0.0),
	Dictionary = {
		"cellphone@",
		"cellphone@in_car@ds",
		"cellphone@str",    
		"random@arrests",  
	},
	Animation = {
		"cellphone_text_in",
		"cellphone_text_out",
		"cellphone_call_listen_a",
		"generic_radio_chatter",
	},
	Clicks = true, 
}

local function isRestrictedFrequency(frequency)
	local playerData = ESX.GetPlayerData()
	if playerData and playerData.job then
		local playerJob = playerData.job.name
		if radioConfig.Frequency['police'][frequency] and playerJob ~= 'police' then
			return true
		elseif radioConfig.Frequency['ambulance'][frequency] and playerJob ~= 'ambulance' then
			return true
		end
	end
	return false
end

local function showNotification(message)
	SendNUIMessage({
		action = 'showNotification',
		message = message
	})
end

Radio.Labels = {}
local unarmed = GetHashKey('weapon_unarmed')
Radio.Commands = {
	{
		Enabled = true,
		Name = "radio", 
		Help = "Toggle hand radio", 
		Params = {},
		Handler = function(src, args, raw)
			local playerPed = PlayerPedId()
			local isFalling = IsPedFalling(playerPed)
			local isDead = IsEntityDead(playerPed)

			if not isFalling and Radio.Enabled and Radio.Has and not isDead then
				Radio:Toggle(not Radio.Open)
			elseif (Radio.Open or Radio.On) and ((not Radio.Enabled) or (not Radio.Has) or isDead) then
				Radio:Toggle(false)
				Radio.On = false
				Radio:Remove()
				exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
			elseif Radio.Open and isFalling then
				Radio:Toggle(false)
			end            
		end,
	},
	{
		Enabled = true, 
		Name = "frequency",
		Help = "Change radio frequency", 
		Params = {
			{name = "number", "Enter frequency"}
		},
		Handler = function(src, args, raw)
			if Radio.Has then
				if args[1] then
					local newFrequency = tonumber(args[1])
					if newFrequency then
						local minFrequency = radioConfig.Frequency.List[1]
						if newFrequency >= minFrequency and newFrequency <= radioConfig.Frequency.List[#radioConfig.Frequency.List] and newFrequency == math.floor(newFrequency) then
							if not radioConfig.Frequency.Private[newFrequency] or radioConfig.Frequency.Access[newFrequency] then
								local idx = nil
					
								for i = 1, #radioConfig.Frequency.List do
									if radioConfig.Frequency.List[i] == newFrequency then
										idx = i
										break
									end
								end
					
								if idx ~= nil then
									if Radio.Enabled then
										Radio:Remove()
									end

									radioConfig.Frequency.CurrentIndex = idx
									radioConfig.Frequency.Current = newFrequency

									if Radio.On then
										Radio:Add(radioConfig.Frequency.Current)
									end
								end
							end
						end
					end
				end                    
			end
		end,
	},
}

for i = 1, #Radio.Commands do
	if Radio.Commands[i].Enabled then
		RegisterCommand(Radio.Commands[i].Name, Radio.Commands[i].Handler, false)
		TriggerEvent("chat:addSuggestion", "/" .. Radio.Commands[i].Name, Radio.Commands[i].Help, Radio.Commands[i].Params)
	end
end

function Radio:Toggle(toggle)
	local playerPed = PlayerPedId()
	local count = 0

	if not self.Has or IsEntityDead(playerPed) then
		self.Open = false
		
		DetachEntity(self.Handle, true, false)
		DeleteEntity(self.Handle)
		
		return
	end

	if self.Open == toggle then
		return
	end

	self.Open = toggle

	if self.On and not radioConfig.AllowRadioWhenClosed then
		exports["pma-voice"]:setVoiceProperty("radioEnabled", toggle)
	end

	local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
	local animationType = 1 + (self.Open and 0 or 1)
	local dictionary = self.Dictionary[dictionaryType]
	local animation = self.Animation[animationType]

	RequestAnimDict(dictionary)

	while not HasAnimDictLoaded(dictionary) do
		Citizen.Wait(150)
	end

	if self.Open then
		RequestModel(self.Prop)

		while not HasModelLoaded(self.Prop) do
			Citizen.Wait(150)
		end

		self.Handle = CreateObject(self.Prop, 0.0, 0.0, 0.0, true, true, false)

		local bone = GetPedBoneIndex(playerPed, self.Bone)

		SetCurrentPedWeapon(playerPed, unarmed, true)
		AttachEntityToEntity(self.Handle, playerPed, bone, self.Offset.x, self.Offset.y, self.Offset.z, self.Rotation.x, self.Rotation.y, self.Rotation.z, true, false, false, false, 2, true)

		SetModelAsNoLongerNeeded(self.Handle)

		TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)
	else
		TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)

		Citizen.Wait(700)

		StopAnimTask(playerPed, dictionary, animation, 1.0)

		NetworkRequestControlOfEntity(self.Handle)

		while not NetworkHasControlOfEntity(self.Handle) and count < 5000 do
			Citizen.Wait(0)
			count = count + 1
		end
		
		DetachEntity(self.Handle, true, false)
		DeleteEntity(self.Handle)
	end
end

function Radio:Add(id)
	exports["pma-voice"]:setRadioChannel(id)
end

function Radio:Remove()
	exports["pma-voice"]:setRadioChannel(0)
end

function Radio:Decrease()
	if self.On then
		repeat
			if radioConfig.Frequency.CurrentIndex - 1 < 1 then
				radioConfig.Frequency.CurrentIndex = #radioConfig.Frequency.List
			else
				radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex - 1
			end
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		until not isRestrictedFrequency(radioConfig.Frequency.Current)
		self:Remove(radioConfig.Frequency.Current)
		self:Add(radioConfig.Frequency.Current)
	else
		repeat
			if radioConfig.Frequency.CurrentIndex - 1 < 1 then
				radioConfig.Frequency.CurrentIndex = #radioConfig.Frequency.List
			else
				radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex - 1
			end
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		until not isRestrictedFrequency(radioConfig.Frequency.Current)
	end
	SendNUIMessage({ radioFrequency = radioConfig.Frequency.Current, isRestricted = isRestrictedFrequency(radioConfig.Frequency.Current) })
end

function Radio:Increase()
	if self.On then
		repeat
			if radioConfig.Frequency.CurrentIndex + 1 > #radioConfig.Frequency.List then
				radioConfig.Frequency.CurrentIndex = 1
			else
				radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex + 1
			end
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		until not isRestrictedFrequency(radioConfig.Frequency.Current)
		self:Remove(radioConfig.Frequency.Current)
		self:Add(radioConfig.Frequency.Current)
	else
		repeat
			if radioConfig.Frequency.CurrentIndex + 1 > #radioConfig.Frequency.List then
				radioConfig.Frequency.CurrentIndex = 1
			else
				radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex + 1
			end
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		until not isRestrictedFrequency(radioConfig.Frequency.Current)
	end
	SendNUIMessage({ radioFrequency = radioConfig.Frequency.Current, isRestricted = isRestrictedFrequency(radioConfig.Frequency.Current) })
end

function GenerateFrequencyList()
	radioConfig.Frequency.List = {}

	for i = radioConfig.Frequency.Min, radioConfig.Frequency.Max do
		if not isRestrictedFrequency(i) then
			radioConfig.Frequency.List[#radioConfig.Frequency.List + 1] = i
		end
	end
end

function IsRadioOpen()
	return Radio.Open
end
function IsRadioOn()
	return Radio.On
end


function IsRadioAvailable()
	return Radio.Has
end


function IsRadioEnabled()
	return not Radio.Enabled
end


function CanRadioBeUsed()
	return Radio.Has and Radio.On and Radio.Enabled
end


function SetRadioEnabled(value)
	if type(value) == "string" then
		value = value == "true"
	elseif type(value) == "number" then
		value = value == 1
	end
	
	Radio.Enabled = value and true or false
end


function SetRadio(value)
	if type(value) == "string" then
		value = value == "true"
	elseif type(value) == "number" then
		value = value == 1
	end

	Radio.Has = value and true or false
end


function SetAllowRadioWhenClosed(value)
	radioConfig.AllowRadioWhenClosed = value

	if Radio.On and not Radio.Open and radioConfig.AllowRadioWhenClosed then
		exports["pma-voice"]:setVoiceProperty("radioEnabled", true)
	end
end

RegisterNUICallback('submitFrequency', function(data, cb)
	local frequency = tonumber(data.frequency)
	if frequency and frequency >= radioConfig.Frequency.Min and frequency <= radioConfig.Frequency.Max then
		local idx = nil
		for i = 1, #radioConfig.Frequency.List do
			if radioConfig.Frequency.List[i] == frequency then
				idx = i
				break
			end
		end
		if idx then
			radioConfig.Frequency.CurrentIndex = idx
			radioConfig.Frequency.Current = frequency
			if Radio.On then
				Radio:Remove()
				Radio:Add(radioConfig.Frequency.Current)
			end
		else
			showNotification('Vous n\'avez pas accès à cette fréquence.')
			radioConfig.Frequency.CurrentIndex = 1
			radioConfig.Frequency.Current = radioConfig.Frequency.List[1]
			if Radio.On then
				Radio:Remove()
				Radio:Add(radioConfig.Frequency.Current)
			end
		end
	end
	SetNuiFocus(false, false)
	cb('ok')
end)

RegisterNUICallback('closeInputMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb('ok')
end)

local isBroadcasting = false

Citizen.CreateThread(function()
	
	for i = 1, #Radio.Labels do
		AddTextEntry(Radio.Labels[i][1], Radio.Labels[i][2])
	end

	GenerateFrequencyList()

	while true do
		Citizen.Wait(500) 
		local playerPed = PlayerPedId()
		local isFalling = IsPedFalling(playerPed)
		local isDead = IsEntityDead(playerPed)
		local minFrequency = radioConfig.Frequency.List[1]
		local broadcastType = 3 + (radioConfig.AllowRadioWhenClosed and 1 or 0) + ((Radio.Open and radioConfig.AllowRadioWhenClosed) and -1 or 0)
		local broadcastDictionary = Radio.Dictionary[broadcastType]
		local broadcastAnimation = Radio.Animation[broadcastType]
		local isPlayingBroadcastAnim = IsEntityPlayingAnim(playerPed, broadcastDictionary, broadcastAnimation, 3)

		
		if (Radio.Open or Radio.On) and ((not Radio.Enabled) or (not Radio.Has) or isDead) then
			Radio:Remove()
			exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
			Radio:Toggle(false)
			Radio.On = false
		elseif Radio.Open and isFalling then
			Radio:Toggle(false)
		end
		
		
		if isRestrictedFrequency(radioConfig.Frequency.Current) then
			if Radio.On then
				Radio:Remove()
			end

			radioConfig.Frequency.CurrentIndex = 1
			radioConfig.Frequency.Current = minFrequency

			if Radio.On then
				Radio:Add(radioConfig.Frequency.Current)
			end
		end

		
		if Radio.Open then
			local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
			local openDictionary = Radio.Dictionary[dictionaryType]
			local openAnimation = Radio.Animation[1]
			local isPlayingOpenAnim = IsEntityPlayingAnim(playerPed, openDictionary, openAnimation, 3)
			local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, 1)

			
			if currentWeapon ~= unarmed then
				SetCurrentPedWeapon(playerPed, unarmed, true)
			end

			
			local isRestricted = isRestrictedFrequency(radioConfig.Frequency.Current)
			SendNUIMessage({ showMenu = true, radioStatus = Radio.On, radioFrequency = radioConfig.Frequency.Current, isRestricted = isRestricted })

			
			if Radio.On then
				if isBroadcasting and not isPlayingBroadcastAnim then
					RequestAnimDict(broadcastDictionary)
		
					while not HasAnimDictLoaded(broadcastDictionary) do
						Citizen.Wait(1000)
					end
		
					TaskPlayAnim(playerPed, broadcastDictionary, broadcastAnimation, 8.0, -8, -1, 49, 0, 0, 0, 0)
				elseif not isBroadcasting and isPlayingBroadcastAnim then
					StopAnimTask(playerPed, broadcastDictionary, broadcastAnimation, -4.0)
				end
			end

			
			if not isBroadcasting and not isPlayingOpenAnim then
				RequestAnimDict(openDictionary)
	
				while not HasAnimDictLoaded(openDictionary) do
					Citizen.Wait(1000)
				end

				TaskPlayAnim(playerPed, openDictionary, openAnimation, 4.0, -1, -1, 50, 0, false, false, false)
			end
		else
			SendNUIMessage({ showMenu = false })
			
			if radioConfig.AllowRadioWhenClosed then
				if Radio.Has and Radio.On and isBroadcasting and not isPlayingBroadcastAnim then
					RequestAnimDict(broadcastDictionary)
	
					while not HasAnimDictLoaded(broadcastDictionary) do
						Citizen.Wait(1000)
					end
		
					TaskPlayAnim(playerPed, broadcastDictionary, broadcastAnimation, 8.0, 0.0, -1, 49, 0, 0, 0, 0)                    
				elseif not isBroadcasting and isPlayingBroadcastAnim then
					StopAnimTask(playerPed, broadcastDictionary, broadcastAnimation, -4.0)
				end
			end
		end

		if Radio.On then
			
			local newBroadcasting = IsControlPressed(0, radioConfig.Controls.Broadcast.Key)
			if newBroadcasting ~= isBroadcasting then
				print("[CLIENT] Avant de TriggerEvent('pma-voice:radioActive') | newBroadcasting:", newBroadcasting)
				isBroadcasting = newBroadcasting
				print("[CLIENT] Après TriggerEvent('pma-voice:radioActive')")
				TriggerEvent('pma-voice:radioActive', isBroadcasting, radioConfig.Frequency.Current)
			
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0) 
		local playerPed = PlayerPedId()

		if IsControlJustPressed(0, radioConfig.Controls.Activator.Key) then
			TriggerEvent('radio:toggleActivator', playerPed)
		end

		if IsControlJustPressed(0, radioConfig.Controls.Toggle.Key) then
			TriggerEvent('radio:toggleRadio', playerPed)
		end

		if IsControlJustPressed(0, radioConfig.Controls.Decrease.Key) then
			TriggerEvent('radio:decreaseFrequency', playerPed)
		end

		if IsControlJustPressed(0, radioConfig.Controls.Increase.Key) then
			TriggerEvent('radio:increaseFrequency', playerPed)
		end

		if IsControlJustPressed(0, radioConfig.Controls.Input.Key) then
			TriggerEvent('radio:inputFrequency', playerPed)
		end

		if IsDisabledControlJustPressed(0, radioConfig.Controls.ToggleClicks.Key) then
			TriggerEvent('radio:toggleClicks', playerPed)
		end
	end
end)

AddEventHandler('radio:toggleActivator', function(playerPed)
	local isSecondaryPressed = (radioConfig.Controls.Secondary.Enabled == false and true or IsControlPressed(0, radioConfig.Controls.Secondary.Key))
	local isFalling = IsPedFalling(playerPed)
	local isDead = IsEntityDead(playerPed)

	if isSecondaryPressed and not isFalling and Radio.Enabled and Radio.Has and not isDead then
		Radio:Toggle(not Radio.Open)
	end
end)

AddEventHandler('radio:toggleRadio', function(playerPed)
	if not isRestrictedFrequency(radioConfig.Frequency.Current) then
		Radio.On = not Radio.On

		exports["pma-voice"]:setVoiceProperty("radioEnabled", Radio.On)

		if Radio.On then
			Radio:Add(radioConfig.Frequency.Current)
		else
			SendNUIMessage({ sound = "audio_off", volume = 0.5})
			Radio:Remove()
		end
	end
end)

AddEventHandler('radio:decreaseFrequency', function(playerPed)
	if not Radio.On then
		if not radioConfig.Controls.Decrease.Pressed then
			radioConfig.Controls.Decrease.Pressed = true
			Citizen.CreateThread(function()
				while IsControlPressed(0, radioConfig.Controls.Decrease.Key) do
					Radio:Decrease()
					Citizen.Wait(125)
				end
				radioConfig.Controls.Decrease.Pressed = false
			end)
		end
	end
end)

AddEventHandler('radio:increaseFrequency', function(playerPed)
	if not Radio.On then
		if not radioConfig.Controls.Increase.Pressed then
			radioConfig.Controls.Increase.Pressed = true
			Citizen.CreateThread(function()
				while IsControlPressed(0, radioConfig.Controls.Increase.Key) do
					Radio:Increase()
					Citizen.Wait(125)
				end
				radioConfig.Controls.Increase.Pressed = false
			end)
		end
	end
end)

AddEventHandler('radio:inputFrequency', function(playerPed)
	if not Radio.On then
		if not radioConfig.Controls.Input.Pressed then
			radioConfig.Controls.Input.Pressed = true
			Citizen.CreateThread(function()
				--DisplayOnscreenKeyboard(1, Radio.Labels[3][1], "", radioConfig.Frequency.Current, "", "", "", 3)

				while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
					Citizen.Wait(150)
				end

				local input = nil

				if UpdateOnscreenKeyboard() ~= 2 then
					input = GetOnscreenKeyboardResult()
				end

				Citizen.Wait(0)
				
				input = tonumber(input)

				if input ~= nil then
					if input >= radioConfig.Frequency.List[1] and input <= radioConfig.Frequency.List[#radioConfig.Frequency.List] and input == math.floor(input) then
						local idx = nil

						for i = 1, #radioConfig.Frequency.List do
							if radioConfig.Frequency.List[i] == input then
								idx = i
								break
							end
						end

						if idx ~= nil then
							radioConfig.Frequency.CurrentIndex = idx
							radioConfig.Frequency.Current = input
						end
					end
				end
				
				radioConfig.Controls.Input.Pressed = false
			end)
		end
	end
end)

AddEventHandler('radio:toggleClicks', function(playerPed)
	Radio.Clicks = not Radio.Clicks

	SendNUIMessage({ sound = "audio_off", volume = 0.5})
	
	exports["pma-voice"]:setVoiceProperty("micClicks", Radio.Clicks)
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio')
AddEventHandler('pma-voice:setTalkingOnRadio', function(talking, speakerId)
	local localId = GetPlayerServerId(PlayerId())
	
	

	if talking then
		if speakerId == localId then
			SendNUIMessage({ radioTalking = "own" })
		else
			SendNUIMessage({ radioTalking = "other" })
		end
	else
		SendNUIMessage({ radioTalking = false })
	end
end)

AddEventHandler("onClientResourceStart", function(resName)
	if GetCurrentResourceName() ~= resName and "pma-voice" ~= resName then
		return
	end
	
	exports["pma-voice"]:setVoiceProperty("radioEnabled", false) 

	if Radio.Open then
		Radio:Toggle(false)
	end
	
	Radio.On = false
end)

RegisterNetEvent("Radio.Toggle")
AddEventHandler("Radio.Toggle", function()
	local playerPed = PlayerPedId()
	local isFalling = IsPedFalling(playerPed)
	local isDead = IsEntityDead(playerPed)
	
	if not isFalling and not isDead and Radio.Enabled and Radio.Has then
		Radio:Toggle(not Radio.Open)
	end
end)

RegisterNetEvent("Radio.Set")
AddEventHandler("Radio.Set", function(value)
	if type(value) == "string" then
		value = value == "true"
	elseif type(value) == "number" then
		value = value == 1
	end

	Radio.Has = value and true or false
end)

AddEventHandler('pma-voice:radioActive', function(isTalking, freq)
		TriggerServerEvent('pma-voice:radioActive1', isTalking, radioConfig.Frequency.Current)
	

end)

