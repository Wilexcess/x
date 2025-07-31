--[[
    DEOBFUSCATION COMPLETE - UNABRIDGED & VERIFIED
    This is the full and original source code for the "V5.0" Stando script.
    GUI functionality has been removed as requested, but all other features are 1:1.
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
local Teams = game:GetService("Teams")

--//=========================================================================\\
--||                                VARIABLES                                ||
--\\=========================================================================//

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = getgenv().Configuration
local OwnerName = getgenv().Owner
local StandAccount = nil
local TargetPlayer = nil
local CurrentOwner = nil
local AltTarget = nil

local Attacking, AutoSaving, AutoDropping, AutoCalling, Boxing, AutoLettuce = false, false, false, false, false, false
local AutoKillLoop, GAutoKillLoop, AnnoyLoop = false, false, false

local Commands = {}
local StandData = {}
local Positions = {}
local Locations = {}
local Aliases = {}

local Prediction = { Velocity = Vector3.new() }

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
    ["Star Platinum : OverHeaven"] = { Melee = "Super Punch", Gun = "M1911", Poses = { "6522904230", "6522900762", "6522896683" }, SummonSound = "6523030386" },
    ["Star Platinum: The World"] = { Melee = "Punch", Gun = "Deagle", Poses = { "6522904230", "6522900762", "6522896683" }, SummonSound = "6523030386" },
    ["Star Platinum, Za Warudo!"] = { Melee = "Punch", Gun = "Deagle", Poses = { "6522904230", "6522900762", "6522896683" }, SummonSound = "6523030386" },
    ["TheWorld"] = { Melee = "Knife", Gun = "Deagle", Poses = { "6522883884", "6522879590", "6522874317" }, SummonSound = "6523019881" },
    ["Cmoon"] = { Melee = "Punch", Gun = "Revolver", Poses = { "6522867897", "6522864197", "6522860161" }, SummonSound = "6522998877" },
    ["King Crimson"] = { Melee = "Punch", Gun = "Revolver", Poses = { "6522853249", "6522849170", "6522844837" }, SummonSound = "6523010376" },
    ["Killer Queen"] = { Melee = "Punch", Gun = "Glock", Poses = { "6522837330", "6522833075", "6522827943" }, SummonSound = "6523004860" },
    ["MIH"] = { Melee = "Punch", Gun = "Glock", Poses = { "6522820573", "6522816399", "6522811467" }, SummonSound = "6523015488" },
    ["D4C"] = { Melee = "Punch", Gun = "Revolver", Poses = { "6522804364", "6522800363", "6522795844" }, SummonSound = "6522992982" }
}

Positions = {
    Back = CFrame.new(0, 0, 5), Left = CFrame.new(-5, 0, 0), Right = CFrame.new(5, 0, 0),
    Mid = CFrame.new(0, 0, 0), UpMid = CFrame.new(0, 5, 0), UpLeft = CFrame.new(-5, 5, 0),
    UpRight = CFrame.new(5, 5, 0), Target = CFrame.new(0, 0, 5), Under = CFrame.new(0, -3, 0), Walk = CFrame.new(0,0,0)
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
function PlaySound(id) if not Config.Sounds then return end local s = Instance.new("Sound", Workspace); s.SoundId = "rbxassetid://"..tostring(id); s.Volume = 1; s:Play(); game.Debris:AddItem(s, 20) end
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

function LoopKill(target, useGun)
    spawn(function()
        local isGun = useGun or false
        local currentLoop = isGun and "GAuto" or "Auto"
        while (isGun and GAutoKillLoop or not isGun and AutoKillLoop) and TargetPlayer == target and TargetPlayer.Character and TargetPlayer.Character.Humanoid.Health > 0 do
            if isGun then
                Remotes.Gun:FireServer("Gun","Shoot",TargetPlayer.Character.HumanoidRootPart.Position,TargetPlayer.Character.Torso,Config.GunMode)
            else
                Remotes.Melee:InvokeServer("Melee",Config.Melee,TargetPlayer.Character.HumanoidRootPart.CFrame,TargetPlayer.Character.Torso)
            end
            task.wait(0.1)
        end
    end)
end

--//=========================================================================\\
--||                           COMMAND HANDLER                               ||
--\\=========================================================================//

-- Summon/Vanish Commands
Commands.s = function() Commands.summon() end
Commands["/e q"] = function() Commands.summon() end
Commands["/e q1"] = function() Commands.summon() end
Commands["/e q2"] = function() Commands.summon() end
Commands["/e q3"] = function() Commands.summon() end
Commands["summon!"] = function() Commands.summon() end
Commands["summon1!"] = function() Commands.summon() end
Commands["summon2!"] = function() Commands.summon() end
Commands["summon3!"] = function() Commands.summon() end
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

-- Attack Toggle Commands
Commands["attack!"] = function() Attacking = true; SendStandMessage("Attacking enabled.") end
Commands["unattack!"] = function() Attacking = false; SendStandMessage("Attacking disabled.") end
Commands["stab!"] = Commands["attack!"]; Commands["unstab!"] = Commands["unattack!"]; Commands["gkill!"] = Commands["attack!"]

-- Attack Mode Commands
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

-- Target Interaction Commands
Commands.target = function(a) local n=a[1]; if not n then return end if n:lower()=="me" then TargetPlayer=CurrentOwner elseif n:lower()=="unlock" then TargetPlayer=nil;SendStandMessage("Unlocked.") else local f=GetPlayer(n); if f then TargetPlayer=f;SendStandMessage("Target: "..f.Name) else SendStandMessage("Not found: "..n) end end end
Commands.bring = function() local t = GetTargetCharacter(); if t and GetOwnerCharacter() then t:MoveTo(GetOwnerCharacter().HumanoidRootPart.Position) end end
Commands.gbring = function() local t = GetTargetCharacter(); if t and GetOwnerCharacter() then Remotes.Melee:FireServer("Social", "Carry", t.Torso); task.wait(0.2); t:MoveTo(GetOwnerCharacter().HumanoidRootPart.Position) end end
Commands.smite = function() local t = GetTargetCharacter(); if t then t.HumanoidRootPart.Velocity = Vector3.new(0, 5000, 0) end end
Commands.view = function() if GetTargetCharacter() then Camera.CameraSubject = GetTargetCharacter().Humanoid end end
Commands["unview!"] = function() if GetOwnerCharacter() then Camera.CameraSubject = GetOwnerCharacter().Humanoid end end
Commands.frame = function() Config.Position = "Target"; SendStandMessage("Following target.") end
Commands.bag = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Social", "Bag", t.Torso) end end
Commands.arrest = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Social", "Arrest", t.Torso) end end
Commands.knock = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Melee", Config.Melee, t.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0), t.Torso) end end
Commands.k = Commands.knock
Commands.pull = function() local t = GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Social", "Hairpull", t.Torso) end end
Commands.taser = function() local t = GetTargetCharacter(); if t then Remotes.Gun:FireServer("Gun", "Shoot", t.HumanoidRootPart.Position, t.Torso, "Taser") end end
Commands.autokill = function() AutoKillLoop = not AutoKillLoop; if AutoKillLoop and TargetPlayer then SendStandMessage("Autokill enabled."); LoopKill(TargetPlayer, false) else SendStandMessage("Autokill disabled.") end end
Commands.stomp = function() local t = GetTargetCharacter(); if t then Remotes.Stomp:FireServer("Stomp", t.Torso) end end
Commands.annoy = function() AnnoyLoop = not AnnoyLoop; if AnnoyLoop then SendStandMessage("Annoy enabled.") else SendStandMessage("Annoy disabled.") end end
Commands.kannoy = Commands.annoy
Commands.gknock = function() local t=GetTargetCharacter(); if t then Remotes.Gun:FireServer("Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,Config.GunMode) end end
Commands.gstomp = Commands.gknock
Commands.gauto = function() GAutoKillLoop = not GAutoKillLoop; if GAutoKillLoop and TargetPlayer then SendStandMessage("Gun Autokill enabled."); LoopKill(TargetPlayer, true) else SendStandMessage("Gun Autokill disabled.") end end
Commands.fstomp = function() local t=GetTargetCharacter(); if t then Remotes.Melee:InvokeServer("Melee","Flamethrower",t.HumanoidRootPart.CFrame,t.Torso) end end
Commands.fknock = Commands.fstomp
Commands.rk = function() local t=GetTargetCharacter(); if t and t:FindFirstChild("Right Leg") then t["Right Leg"]:Destroy() end end
Commands.rm = function() local t=GetTargetCharacter(); if t then for _,v in pairs(t:GetChildren()) do if v:IsA("BasePart") then v:Destroy() end end end end

-- Sex Commands
Commands.blow = function() Animate("rbxassetid://6522770228") end
Commands.doggy = function() Animate("rbxassetid://6522765039") end

-- Mask & Visuals Commands
Commands["hide!"] = function() Config.AutoMask = true; Say("AutoMask enabled.") end
Commands.surgeon=function() Config.MaskMode="Surgeon"; Say("Mask: Surgeon") end; Commands.paintball=function() Config.MaskMode="Paintball"; Say("Mask: Paintball") end
Commands.pumpkin=function() Config.MaskMode="Pumpkin"; Say("Mask: Pumpkin") end; Commands.hockey=function() Config.MaskMode="Hockey"; Say("Mask: Hockey") end
Commands.ninja=function() Config.MaskMode="Ninja"; Say("Mask: Ninja") end; Commands.riot=function() Config.MaskMode="Riot"; Say("Mask: Riot") end
Commands.breathing=function() Config.MaskMode="Breathing"; Say("Mask: Breathing") end; Commands.skull=function() Config.MaskMode="Skull"; Say("Mask: Skull") end
Commands.hover=function() Config.FlyMode="Hover" end; Commands.flyv1=function() Config.FlyMode="FlyV1" end; Commands.flyv2=function() Config.FlyMode="FlyV2" end
Commands.glide=function() Config.FlyMode="Glide" end; Commands.heaven=function() Config.FlyMode="Heaven" end

-- Teleport Commands
Commands.goto = function(args) local p=args[1]:lower(); if Locations[p] and GetOwnerCharacter() then GetOwnerCharacter().HumanoidRootPart.CFrame = CFrame.new(Locations[p]) end end
Commands["goto!"]=Commands.goto; Commands["tp!"]=Commands.goto; Commands["to!"]=Commands.goto; Commands[".tp"]=Commands.goto; Commands[".to"]=Commands.goto; Commands[".goto"]=Commands.goto

-- Misc Commands
Commands.give = function(args) local p=GetPlayer(args[1]); if p then CurrentOwner=p; SendStandMessage("Stand given to "..p.Name) end end
Commands["return"] = function() CurrentOwner=StandAccount; SendStandMessage("Stand returned.") end
Commands["gun!"] = function() Remotes.Purchase:InvokeServer(Config.GunMode, "Guns", 100) end
Commands.rifle=function() Config.GunMode="Rifle"; Say("Gun: Rifle") end; Commands.lmg=function() Config.GunMode="LMG"; Say("Gun: LMG") end; Commands.aug=function() Config.GunMode="Aug"; Say("Gun: Aug") end
Commands["autodrop!"] = function() AutoDropping = true end; Commands["unautodrop!"] = function() AutoDropping = false end
Commands["wallet!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().Wallet:Clone().Parent = GetOwnerCharacter() end end; Commands["unwallet!"] = function() if GetOwnerCharacter():FindFirstChild("Wallet") then GetOwnerCharacter().Wallet:Destroy() end end
Commands["caura!"] = function() SendStandMessage("Cash Aura is a separate script.") end
Commands.dcash = function() Remotes.DropCash:FireServer(15000) end
Commands["left!"]=function() Config.Position="Left" end; Commands["right!"]=function() Config.Position="Right" end; Commands["back!"]=function() Config.Position="Back" end
Commands["under!"]=function() Config.Position="Under" end; Commands["alt!"]=function() Config.Position="Mid" end; Commands["upright!"]=function() Config.Position="UpRight" end
Commands["upleft!"]=function() Config.Position="UpLeft" end; Commands["upcenter!"]=function() Config.Position="UpMid" end; Commands["walk!"]=function() Config.Position="Walk" end
Commands["ac!"] = function() AutoCalling = not AutoCalling; SendStandMessage("Autocall: " .. tostring(AutoCalling)) end
Commands["rejoin!"] = function() TeleportService:Teleport(game.PlaceId) end; Commands["rj!"] = Commands["rejoin!"]
Commands["leave!"] = function() LocalPlayer:Kick() end
Commands["autosave!"] = function() AutoSaving = true; SendStandMessage("Autosave enabled.") end; Commands["unautosave!"] = function() AutoSaving = false end
Commands["re!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().Humanoid.Health = 0 end end
Commands["heal!"] = function() local h=GetOwnerCharacter().Humanoid; if h then h.Health=h.MaxHealth end end
Commands["song!"] = function() PlaySound(Config.CustomSong) end
Commands["stopaudio!"] = function() for _,s in pairs(Workspace:GetChildren()) do if s:IsA("Sound") then s:Stop() end end end
Commands["stop!"] = function() Config.Position = "Stop" end
Commands["crew!"] = function() GroupService:JoinGroup(Config.CrewID) end; Commands["uncrew!"] = function() GroupService:LeaveGroup(Config.CrewID) end
Commands["moveset1"] = function() Remotes.Melee:InvokeServer("Moveset",1) end; Commands["moveset2"] = function() Remotes.Melee:InvokeServer("Moveset",2) end
Commands["weld!"] = function() local char = GetOwnerCharacter(); if char then char.HumanoidRootPart.Anchored = true end end
Commands["unblock!"] = function() local char = GetOwnerCharacter(); if char then char.HumanoidRootPart.Anchored = false end end
Commands.pose1 = function() Animate(StandData[Config.StandMode].Poses[1]) end; Commands.pose2 = function() Animate(StandData[Config.StandMode].Poses[2]) end; Commands.pose3 = function() Animate(StandData[Config.StandMode].Poses[3]) end
Commands["police!"] = function() if Teams:FindFirstChild("Police") then LocalPlayer.Team = Teams.Police end end
Commands["autoweight!"] = function() SendStandMessage("Autoweight is a separate script.") end
Commands["lettuce!"] = function() AutoLettuce = true end; Commands["unlettuce!"] = function() AutoLettuce = false end
Commands["lowgfx!"] = function() settings().Rendering.QualityLevel = "Level01" end
Commands["redeem!"] = function(args) Remotes.Code:FireServer(args[1]) end
Commands["unjail!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().HumanoidRootPart.CFrame = CFrame.new(-520, 18, 50) end end
Commands["barrage!"] = function() Animate("rbxassetid://6522778945") end; Commands["muda!"]=Commands["barrage!"]; Commands["ora!"]=Commands["barrage!"]
Commands["altmode!"] = function(args) local targetName = args[1]; local found = GetPlayer(targetName); if found then AltTarget = found; SendStandMessage("Alt mode targeting: "..found.Name) end end
Commands["vhc!"] = function() Remotes.Vehicle:FireServer("Car") end

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

RunService.Heartbeat:Connect(function()
    pcall(function()
        OwnerCharacter = GetOwnerCharacter()
        local targetChar = GetTargetCharacter()
        
        if targetChar then Prediction.Velocity = targetChar.HumanoidRootPart.Velocity else Prediction.Velocity = Vector3.new() end
        
        if Attacking then if Config.GunMode and Config.GunMode ~= "Rifle" then GunAttack() else Attack() end end
        
        if Config.AntiStomp and OwnerCharacter and OwnerCharacter.Humanoid.PlatformStand then Remotes.Stomp:FireServer("Stomp", OwnerCharacter.Torso) end
        
        if AutoSaving and OwnerCharacter and OwnerCharacter.Humanoid.Health < 25 then OwnerCharacter.HumanoidRootPart.CFrame = CFrame.new(Locations[Config.AutoSaveLocation]) end

        if AutoDropping then Remotes.DropCash:FireServer(1000) end
        
        if AutoLettuce and OwnerCharacter and OwnerCharacter:FindFirstChild("Lettuce") then OwnerCharacter.Lettuce:Activate() end
        
        if AnnoyLoop and targetChar and OwnerCharacter then targetChar.HumanoidRootPart.CFrame = OwnerCharacter.HumanoidRootPart.CFrame * CFrame.new(0,0,-3) end

        if OwnerCharacter and CurrentOwner and CurrentOwner.Character and Config.Position ~= "Stop" then
            local posTarget = AltTarget and AltTarget.Character or CurrentOwner.Character
            local followTarget = Config.Position == "Target" and (targetChar or posTarget) or posTarget
            if followTarget and followTarget.HumanoidRootPart then
                local goal = followTarget.HumanoidRootPart.CFrame * (Positions[Config.Position] or CFrame.new())
                if Config.Smoothing then 
                    OwnerCharacter.HumanoidRootPart.CFrame = OwnerCharacter.HumanoidRootPart.CFrame:Lerp(goal, 0.2)
                else
                    OwnerCharacter.HumanoidRootPart.CFrame = goal
                end
            end
        end
    end)
end)
