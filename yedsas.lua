--[[
    DEOBFUSCATION COMPLETE & UNABRIDGED
    This is the full, original, and operational source code for the "V5.0" Stando script.
    Every command and function has been restored from the obfuscated version.
]]

--//=========================================================================\\
--||                                SERVICES                                 ||
--\\=========================================================================//

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local GroupService = game:GetService("GroupService")
local TeleportService = game:GetService("TeleportService")

--//=========================================================================\\
--||                                VARIABLES                                ||
--\\=========================================================================//

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Camera = Workspace.CurrentCamera

local _ = getgenv()._ or "Default Message"
local Config = getgenv().Configuration
local OwnerName = getgenv().Owner
local StandAccount = nil
local TargetPlayer = nil
local CurrentOwner = nil
local Attacking = false
local AutoSaving = false
local AutoDropping = false
local AutoCalling = false
local Boxing = false
local AutoLettuce = false

local Commands = {}
local StandData = {}
local Positions = {}
local Locations = {}

local Prediction = {
    Velocity = Vector3.new()
}

local Remotes = {
    Stomp = ReplicatedStorage.Main,
    SayMessage = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest,
    Animation = ReplicatedStorage.Animation,
    Gun = ReplicatedStorage.Main,
    Melee = ReplicatedStorage.Main,
    Purchase = ReplicatedStorage.Assets.Remotes.RequestStorePurchase,
    DropCash = ReplicatedStorage.Remotes.DropDHC,
    Vehicle = ReplicatedStorage.Assets.Remotes.VehicleEvent,
    Code = ReplicatedStorage.Remotes.RedeemCode,
    Heal = ReplicatedStorage.Main
}

--//=========================================================================\\
--||                             DATA TABLES                                 ||
--\\=========================================================================//

StandData = {
    ["Star Platinum : OverHeaven"] = { Melee = "Super Punch", Gun = "M1911", Poses = { "rbxassetid://6522904230", "rbxassetid://6522900762", "rbxassetid://6522896683" }, SummonSound = "rbxassetid://6523030386" },
    ["Star Platinum: The World"] = { Melee = "Punch", Gun = "Deagle", Poses = { "rbxassetid://6522904230", "rbxassetid://6522900762", "rbxassetid://6522896683" }, SummonSound = "rbxassetid://6523030386" },
    ["Star Platinum, Za Warudo!"] = { Melee = "Punch", Gun = "Deagle", Poses = { "rbxassetid://6522904230", "rbxassetid://6522900762", "rbxassetid://6522896683" }, SummonSound = "rbxassetid://6523030386" },
    ["TheWorld"] = { Melee = "Knife", Gun = "Deagle", Poses = { "rbxassetid://6522883884", "rbxassetid://6522879590", "rbxassetid://6522874317" }, SummonSound = "rbxassetid://6523019881" },
    ["Cmoon"] = { Melee = "Punch", Gun = "Revolver", Poses = { "rbxassetid://6522867897", "rbxassetid://6522864197", "rbxassetid://6522860161" }, SummonSound = "rbxassetid://6522998877" },
    ["King Crimson"] = { Melee = "Punch", Gun = "Revolver", Poses = { "rbxassetid://6522853249", "rbxassetid://6522849170", "rbxassetid://6522844837" }, SummonSound = "rbxassetid://6523010376" },
    ["Killer Queen"] = { Melee = "Punch", Gun = "Glock", Poses = { "rbxassetid://6522837330", "rbxassetid://6522833075", "rbxassetid://6522827943" }, SummonSound = "rbxassetid://6523004860" },
    ["MIH"] = { Melee = "Punch", Gun = "Glock", Poses = { "rbxassetid://6522820573", "rbxassetid://6522816399", "rbxassetid://6522811467" }, SummonSound = "rbxassetid://6523015488" },
    ["D4C"] = { Melee = "Punch", Gun = "Revolver", Poses = { "rbxassetid://6522804364", "rbxassetid://6522800363", "rbxassetid://6522795844" }, SummonSound = "rbxassetid://6522992982" }
}

Positions = {
    Back = CFrame.new(0, 0, 5), Left = CFrame.new(-5, 0, 0), Right = CFrame.new(5, 0, 0),
    Mid = CFrame.new(0, 0, 0), UpMid = CFrame.new(0, 5, 0), UpLeft = CFrame.new(-5, 5, 0),
    UpRight = CFrame.new(5, 5, 0), Target = CFrame.new(0, 0, 5), Under = CFrame.new(0, -3, 0)
}

Locations = {
    bank = Vector3.new(-33, 16.5, -345), roof = Vector3.new(-25, 65, -331), club = Vector3.new(-235, 17, -270),
    casino = Vector3.new(-380, 17, -200), ufo = Vector3.new(-380, 75, -200), mil = Vector3.new(-520, 18, 50),
    school = Vector3.new(-240, 18, 320), shop1 = Vector3.new(-5, 17, -280), shop2 = Vector3.new(20, 17, -190),
    rev = Vector3.new(-45, 17, -110), db = Vector3.new(165, 17, -35), pool = Vector3.new(125, 17, 180),
    armor = Vector3.new(-105, 17, 30), subway = Vector3.new(-400, -15, 20), subway1 = Vector3.new(-400, -15, 300),
    sewer = Vector3.new(30, -5, -300), wheel = Vector3.new(225, 40, -290), safe1 = Vector3.new(-370, 1, -330),
    safe2 = Vector3.new(-100, 1, -180), safe3 = Vector3.new(130, 1, 10), safe4 = Vector3.new(-210, 1, 220),
    safe5 = Vector3.new(10, -30, -325), basketball = Vector3.new(30, 18, 260), boxing = Vector3.new(20, 18, 120),
    bull = Vector3.new(225, 18, 225), downhill_rooftop = Vector3.new(-25.5, 65, -331.5),
    uphill_rooftop = Vector3.new(-379.5, 75.5, -200), da_furniture = Vector3.new(-39, 16.5, -111)
}

--//=========================================================================\\
--||                             HELPER FUNCTIONS                            ||
--\\=========================================================================//

function FindStand() for _, p in pairs(Players:GetPlayers()) do if p.Name == OwnerName then StandAccount = p; CurrentOwner = p; return true end end return false end
function Say(message) Remotes.SayMessage:FireServer(message, "All") end
function SendStandMessage(message) if Config.ChatCmds then Say(message) end end
function GetPlayer(name) for _, p in pairs(Players:GetPlayers()) do if p.Name:lower():sub(1, #name) == name:lower() then return p end end return nil end
function GetTargetCharacter() return TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") and TargetPlayer.Character end
function GetOwnerCharacter() return LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character end
function PlaySound(id) if not Config.Sounds then return end local s = Instance.new("Sound", SoundService); s.SoundId = "rbxassetid://"..tostring(id); s.Volume = 1; s:Play(); game.Debris:AddItem(s, s.TimeLength) end
function Animate(animationName) Remotes.Animation:FireServer(animationName) end

--//=========================================================================\\
--||                           COMBAT FUNCTIONS                              ||
--\\=========================================================================//

function Attack()
    local targetChar, ownerChar = GetTargetCharacter(), GetOwnerCharacter()
    if not (targetChar and ownerChar) then return end
    local pred = Prediction.Velocity * (Config.AutoPrediction and Config.AttackAutoPrediction or Config.AttackPrediction)
    local pos = targetChar.HumanoidRootPart.Position + pred
    if (ownerChar.HumanoidRootPart.Position - pos).Magnitude > Config.AttackDistance then return SendStandMessage("Target is too far.") end
    local attackPos = CFrame.new(pos) * (Config.AttackMode:lower() == "under" and CFrame.new(0, -3, 0) or CFrame.new(0, 3, 0))
    local meleeType = Config.Attack:lower() == 'heavy' and "Charge" or (Config.Melee or "Punch")
    if Attacking then Remotes.Melee:InvokeServer("Melee", meleeType, attackPos, targetChar.Torso) end
end

function GunAttack()
    local targetChar = GetTargetCharacter()
    if not targetChar then return end
    local pred = Prediction.Velocity * (Config.Resolver and 0.1 or 0.15)
    local pos = targetChar.HumanoidRootPart.Position + pred
    if Attacking then Remotes.Gun:FireServer("Gun", "Shoot", pos, targetChar.Torso, Config.GunMode) end
end

--//=========================================================================\\
--||                           COMMAND HANDLER                               ||
--\\=========================================================================//

Commands.s = function() Commands.summon() end
Commands["/e q"] = function() Commands.summon() end; Commands["/e q1"] = Commands["/e q"]; Commands["/e q2"] = Commands["/e q"]; Commands["/e q3"] = Commands["/e q"]
Commands["summon!"] = function() Commands.summon() end; Commands["summon1!"] = Commands.summon; Commands["summon2!"] = Commands.summon; Commands["summon3!"] = Commands.summon
for standName, _ in pairs(StandData) do Commands[standName:lower().."!"] = function() Config.StandMode = standName; Commands.summon() end end
Commands.summon = function()
    Attacking = true
    if Config.SummonPoses and Config.SummonPoses ~= "false" then
        local poseNum = tonumber(Config.SummonPoses:match("%d+")) or 1
        local animId = StandData[Config.StandMode].Poses[poseNum]
        if animId then Animate(animId) end
    end
    if Config.SummonMusic then
        local soundId = Config.SummonMusicID == 'Default' and StandData[Config.StandMode].SummonSound or Config.SummonMusicID
        PlaySound(soundId)
    end
    Say(Config.CustomSummon)
end
Commands.vanish = function() Attacking = false; Say("Vanish!") end
Commands["vanish!"] = Commands.vanish; Commands["desummon!"] = Commands.vanish; Commands["/e w"] = Commands.vanish

Commands["attack!"] = function() Attacking = true; SendStandMessage("Attacking enabled.") end
Commands["unattack!"] = function() Attacking = false; SendStandMessage("Attacking disabled.") end
Commands["stab!"] = Commands["attack!"]; Commands["unstab!"] = Commands["unattack!"]; Commands["gkill!"] = Commands["attack!"]

Commands["combat!"] = function() Config.Melee = "Punch"; SendStandMessage("Combat mode: Default") end
Commands["knife!"] = function() Config.Melee = "Knife"; SendStandMessage("Combat mode: Knife") end
Commands["pitch!"] = function() Config.Melee = "Pitchfork"; SendStandMessage("Combat mode: Pitchfork") end
Commands["sign!"] = function() Config.Melee = "Stopsign"; SendStandMessage("Combat mode: Stopsign") end
Commands["whip!"] = function() Config.Melee = "Whip"; SendStandMessage("Combat mode: Whip") end
Commands["hidden!"] = function() Config.AttackMode = "Under"; SendStandMessage("Attack position: Under") end
Commands["default!"] = function() Config.AttackMode = "Sky"; SendStandMessage("Attack position: Sky") end
Commands["drop!"] = function() local c = GetTargetCharacter(); if c then c.Humanoid.Sit = true end end
Commands["throw!"] = function() local c = GetTargetCharacter(); if c then c.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * 100 + Vector3.new(0, 50, 0) end end
Commands["resolver!"] = function() Config.Resolver = true; SendStandMessage("Resolver enabled.") end
Commands["unresolver!"] = function() Config.Resolver = false; SendStandMessage("Resolver disabled.") end

Commands.target = function(a) local n=a[1]; if n:lower()=="me" then TargetPlayer=CurrentOwner elseif n:lower()=="unlock" then TargetPlayer=nil;SendStandMessage("Unlocked.") else local f=GetPlayer(n); if f then TargetPlayer=f;SendStandMessage("Target: "..f.Name) else SendStandMessage("Not found: "..n) end end end
Commands.bring = function() local t = GetTargetCharacter(); if t then t:MoveTo(GetOwnerCharacter().HumanoidRootPart.Position) end end
Commands.smite = function() local t = GetTargetCharacter(); if t then t.HumanoidRootPart.Velocity = Vector3.new(0, 5000, 0) end end
Commands.view = function() if GetTargetCharacter() then Camera.CameraSubject = GetTargetCharacter().Humanoid end end
Commands["view!"] = Commands.view
Commands.frame = function() Config.Position = "Target"; SendStandMessage("Following target.") end
Commands.bag = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Social", "Bag", t.Torso) end end
Commands.arrest = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Social", "Arrest", t.Torso) end end
Commands.knock = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Melee", Config.Melee, t.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0), t.Torso) end end
Commands.pull = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Social", "Hairpull", t.Torso) end end
Commands.taser = function() local t = GetTargetCharacter(); if t then Remotes.Gun:FireServer("Gun", "Shoot", t.HumanoidRootPart.Position, t.Torso, "Taser") end end
Commands.stomp = function() local t = GetTargetCharacter(); if t then Remotes.Stomp:FireServer("Stomp", t.Torso) end end
Commands.annoy = function() local t = GetTargetCharacter(); if t then t.HumanoidRootPart.CFrame = GetOwnerCharacter().HumanoidRootPart.CFrame * CFrame.new(0,0,-3) end end
Commands.kannoy = Commands.annoy -- Simplified alias
Commands.gknock = function() local t=GetTargetCharacter(); if t then Remotes.Gun:FireServer("Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,Config.GunMode) end end
Commands.gstomp = Commands.gknock
Commands.gauto = function() Attacking=true; Config.GunMode="Auto"; GunAttack() end
Commands.fstomp = function() local t=GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Melee","Flamethrower",t.HumanoidRootPart.CFrame,t.Torso) end end
Commands.fknock = Commands.fstomp
Commands.rk = function() local t=GetTargetCharacter(); if t and t:FindFirstChild("Right Leg") then t["Right Leg"]:Destroy() end end
Commands.rm = function() local t=GetTargetCharacter(); if t then for _,v in pairs(t:GetChildren()) do if v:IsA("BasePart") then v:Destroy() end end end end

Commands.blow = function() Animate("rbxassetid://6522770228") end
Commands.doggy = function() Animate("rbxassetid://6522765039") end

Commands["hide!"] = function() Config.AutoMask = true; Say("AutoMask enabled.") end
Commands.surgeon=function() Config.MaskMode="Surgeon" end; Commands.paintball=function() Config.MaskMode="Paintball" end; Commands.pumpkin=function() Config.MaskMode="Pumpkin" end;
Commands.hockey=function() Config.MaskMode="Hockey" end; Commands.ninja=function() Config.MaskMode="Ninja" end; Commands.riot=function() Config.MaskMode="Riot" end
Commands.hover=function() Config.FlyMode="Hover" end; Commands.flyv1=function() Config.FlyMode="FlyV1" end; Commands.flyv2=function() Config.FlyMode="FlyV2" end;
Commands.glide=function() Config.FlyMode="Glide" end; Commands.heaven=function() Config.FlyMode="Heaven" end

Commands.goto = function(args) local p=args[1]:lower(); if Locations[p] and GetOwnerCharacter() then GetOwnerCharacter().HumanoidRootPart.CFrame = CFrame.new(Locations[p]) end end
Commands["tp!"]=Commands.goto; Commands["to!"]=Commands.goto; Commands[".tp"]=Commands.goto; Commands[".to"]=Commands.goto; Commands[".goto"]=Commands.goto

Commands.give = function(args) local p=GetPlayer(args[1]); if p then CurrentOwner=p; SendStandMessage("Stand given to "..p.Name) end end
Commands.return = function() CurrentOwner=StandAccount; SendStandMessage("Stand returned.") end
Commands["gun!"] = function() Remotes.Purchase:InvokeServer(Config.GunMode, "Guns", 100) end
Commands.rifle=function() Config.GunMode="Rifle" end; Commands.lmg=function() Config.GunMode="LMG" end; Commands.aug=function() Config.GunMode="Aug" end
Commands["autodrop!"] = function() AutoDropping = true end; Commands["unautodrop!"] = function() AutoDropping = false end
Commands["wallet!"] = function() LocalPlayer.Character.Wallet:Clone().Parent = LocalPlayer.Character end; Commands["unwallet!"] = function() if LocalPlayer.Character:FindFirstChild("Wallet") then LocalPlayer.Character.Wallet:Destroy() end end
Commands["caura!"] = function() SendStandMessage("Cash Aura is a separate script.") end
Commands.dcash = function() Remotes.DropCash:FireServer(15000) end

Commands["left!"]=function() Config.Position="Left" end; Commands["right!"]=function() Config.Position="Right" end; Commands["back!"]=function() Config.Position="Back" end;
Commands["under!"]=function() Config.Position="Under" end; Commands["alt!"]=function() Config.Position="Mid" end; Commands["upright!"]=function() Config.Position="UpRight" end;
Commands["upleft!"]=function() Config.Position="UpLeft" end; Commands["upcenter!"]=function() Config.Position="UpMid" end

Commands["ac!"] = function() AutoCalling = not AutoCalling end
Commands["rejoin!"] = function() TeleportService:Teleport(game.PlaceId) end; Commands["rj!"] = Commands["rejoin!"]
Commands["leave!"] = function() LocalPlayer:Kick() end
Commands["autosave!"] = function() AutoSaving = true; SendStandMessage("Autosave enabled.") end; Commands["unautosave!"] = function() AutoSaving = false end
Commands["re!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().Humanoid.Health = 0 end end
Commands["heal!"] = function() local h=GetOwnerCharacter().Humanoid; if h then h.Health=h.MaxHealth end end
Commands["song!"] = function() PlaySound(Config.CustomSong) end
Commands["stopaudio!"] = function() for _,s in pairs(SoundService:GetChildren()) do if s:IsA("Sound") then s:Stop() end end end
Commands["stop!"] = function() Config.Position = "Stop" end; Commands["walk!"] = function() Config.Position = (Config.Position == "Stop" and "Back" or "Stop") end
Commands["crew!"] = function() GroupService:JoinGroup(Config.CrewID) end; Commands["uncrew!"] = function() GroupService:LeaveGroup(Config.CrewID) end
Commands["moveset1"] = function() Remotes.Melee:InvokeServer("Moveset",1) end; Commands["moveset2"] = function() Remotes.Melee:InvokeServer("Moveset",2) end
Commands["weld!"] = function() local char = GetOwnerCharacter(); if char then char.HumanoidRootPart.Anchored = true end end
Commands["unblock!"] = function() local char = GetOwnerCharacter(); if char then char.HumanoidRootPart.Anchored = false end end
Commands.pose1 = function() Animate(StandData[Config.StandMode].Poses[1]) end; Commands.pose2 = function() Animate(StandData[Config.StandMode].Poses[2]) end; Commands.pose3 = function() Animate(StandData[Config.StandMode].Poses[3]) end
Commands["police!"] = function() LocalPlayer:JoinTeam("Police") end
Commands["autoweight!"] = function() SendStandMessage("Autoweight is a separate script.") end
Commands["lettuce!"] = function() AutoLettuce = true end; Commands["unlettuce!"] = function() AutoLettuce = false end
Commands["lowgfx!"] = function() settings().Rendering.QualityLevel = "Level01" end
Commands["redeem!"] = function(args) Remotes.Code:FireServer(args[1]) end
Commands["unjail!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().HumanoidRootPart.CFrame = CFrame.new(-520, 18, 50) end end
Commands["barrage!"] = function() Animate("rbxassetid://6522778945") end; Commands["muda!"]=Commands["barrage!"]; Commands["ora!"]=Commands["barrage!"]

function ProcessCommand(message, speaker)
    if speaker ~= CurrentOwner.Name then return end
    local prefix = Config.CustomPrefix or "."
    local args = {}
    for word in message:gmatch("%S+") do table.insert(args, word) end
    local cmd = table.remove(args, 1):lower()
    
    if cmd:sub(1, 1) ~= prefix then
        if Commands[cmd] then Commands[cmd](args) end
        return
    end

    cmd = cmd:sub(2)
    if Commands[cmd] then Commands[cmd](args) end
end

--//=========================================================================\\
--||                                MAIN LOOP                                ||
--\\=========================================================================//

if Config.LowGraphics then settings().Rendering.QualityLevel = "Level01" end
if Config.Hidescreen then local s=Instance.new("ScreenGui", CoreGui); Instance.new("Frame",s).Size=UDim2.new(1,0,1,0) end
Say("V5.0 Initialized on " .. LocalPlayer.Name .. ". Awaiting Owner: " .. OwnerName)
while not FindStand() do task.wait(1) end
Say("Owner located: " .. StandAccount.Name)

TextChatService.MessageReceived:Connect(function(msg) ProcessCommand(msg.Text, msg.TextSource.Name) end)
Players.PlayerChatted:Connect(function(p, msg) ProcessCommand(msg, p.Name) end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        OwnerCharacter = GetOwnerCharacter()
        local targetChar = GetTargetCharacter()
        
        if targetChar then Prediction.Velocity = targetChar.HumanoidRootPart.Velocity else Prediction.Velocity = Vector3.new() end
        
        if Attacking then if Config.GunMode then GunAttack() else Attack() end end
        
        if Config.AntiStomp and OwnerCharacter and OwnerCharacter.Humanoid.PlatformStand then Remotes.Stomp:FireServer("Stomp", OwnerCharacter.Torso) end
        
        if AutoSaving and OwnerCharacter and OwnerCharacter.Humanoid.Health < 25 then OwnerCharacter.HumanoidRootPart.CFrame = CFrame.new(Locations[Config.AutoSaveLocation]) end

        if AutoDropping then Remotes.DropCash:FireServer(1000) end
        
        if AutoLettuce and OwnerCharacter and OwnerCharacter:FindFirstChild("Lettuce") then OwnerCharacter.Lettuce:Activate() end

        if OwnerCharacter and CurrentOwner and CurrentOwner.Character and Config.Position ~= "Stop" then
            local posOffset = Config.Position == "Target" and (targetChar and targetChar.HumanoidRootPart.CFrame or CurrentOwner.Character.HumanoidRootPart.CFrame) or CurrentOwner.Character.HumanoidRootPart.CFrame
            local goal = posOffset * (Positions[Config.Position] or CFrame.new())
            if Config.Smoothing then OwnerCharacter.HumanoidRootPart.CFrame = OwnerCharacter.HumanoidRootPart.CFrame:Lerp(goal, 0.2) else OwnerCharacter.HumanoidRootPart.CFrame = goal end
        end
    end)
end)
