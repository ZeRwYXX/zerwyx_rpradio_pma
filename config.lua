radioConfig = {
    Controls = {
        Activator = { 
            Name = "INPUT_REPLAY_START_STOP_RECORDING_SECONDARY", 
            Key = 289, 
        },
        Secondary = {
            Name = "INPUT_SPRINT",
            Key = 21, 
            Enabled = true, 
        },
        Toggle = { 
            Name = "INPUT_CONTEXT", 
            Key = 51, 
        },
        Increase = { 
            Name = "INPUT_CELLPHONE_RIGHT", 
            Key = 175, 
            Pressed = false,
        },
        Decrease = { 
            Name = "INPUT_CELLPHONE_LEFT", 
            Key = 174, 
            Pressed = false,
        },
        Input = { 
            Name = "INPUT_FRONTEND_ACCEPT", 
            Key = 201, 
            Pressed = false,
        },
        Broadcast = {
            Name = "INPUT_VEH_PUSHBIKE_SPRINT", 
            Key = 137, 
        },
        ToggleClicks = { 
            Name = "INPUT_SELECT_WEAPON", 
            Key = 37, 
        }
    },
    Frequency = {
        ['police'] = {
            [1] = true,
        },
        ['ambulance'] = {
            [2] = true,
        },
        Current = 1, 
        CurrentIndex = 1, 
        Min = 1, 
        Max = 1000, 
        List = {}, 
        Access = {}, 
    },
    AllowRadioWhenClosed = true 
}
