--[[
    STANDO V5 - POLISHED & COMPLETE VERSION
    This script is a from-scratch rewrite based on the original's features.
    It is stable, includes all commands, and provides clear feedback.
    GUI has been removed as requested.
]]

task.wait(1) -- Wait for the game to fully load before starting

--//=========================================================================\\
--||                                SERVICES                                 ||
--\\=========================================================================//

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local GroupService = game:GetService("GroupService")
local TeleportService = game:GetService("TeleportService")
local Teams = game:GetService("Teams")
local TextChatService = game:GetService("TextChatService")

--//=========================================================================\\
--||                                VARIABLES                                ||
--\\=========================================================================//

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load config safely
local Config = getgenv().Configuration or {}
local OwnerName = getgenv().Owner

-- Script State
local StandAccount, CurrentOwner, TargetPlayer, AltTarget
local OwnerCharacter, TargetCharacter
local Attacking, AutoSaving, AutoDropping, AutoCalling, Boxing, AnnoyLoop = false, false, false, false, false, false
local AutoKillLoop, GAutoKillLoop, AutoLettuce = false, false, false

-- Data Tables
local Commands, StandData, Positions, Locations, Aliases = {}, {}, {}, {}, {}
local Prediction = { Velocity = Vector3.new() }
local Remotes = {}

--//=========================================================================\\
--||                           INITIALIZATION                                ||
--\\=========================================================================//

function Initialize()
    -- Safely find remotes
    Remotes.Stomp = ReplicatedStorage:FindFirstChild("Main", true)
    Remotes.SayMessage = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents", true) and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
    Remotes.Animation = ReplicatedStorage:FindFirstChild("Animation", true)
    Remotes.Gun = ReplicatedStorage:FindFirstChild("Main", true)
    Remotes.Melee = ReplicatedStorage:FindFirstChild("Main", true)
    Remotes.Purchase = ReplicatedStorage:FindFirstChild("Assets", true) and ReplicatedStorage.Assets:FindFirstChild("Remotes", true) and ReplicatedStorage.Assets.Remotes:FindFirstChild("RequestStorePurchase")
    Remotes.DropCash = ReplicatedStorage:FindFirstChild("Remotes", true) and ReplicatedStorage.Remotes:FindFirstChild("DropDHC")
    Remotes.Vehicle = ReplicatedStorage:FindFirstChild("Assets", true) and ReplicatedStorage.Assets:FindFirstChild("Remotes", true) and ReplicatedStorage.Assets.Remotes:FindFirstChild("VehicleEvent")
    Remotes.Code = ReplicatedStorage:FindFirstChild("Remotes", true) and ReplicatedStorage.Remotes:FindFirstChild("RedeemCode")
    Remotes.Heal = ReplicatedStorage:FindFirstChild("Main", true)
    
    for name, remote in pairs(Remotes) do
        if not remote then
            warn("Stando V5 Warning: Could not find RemoteEvent '"..name.."'. Some functions may not work.")
        end
    end

    -- Populate data tables
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
end

--//=========================================================================\\
--||                             HELPER FUNCTIONS                            ||
--\\=========================================================================//

function FindStand() for _, p in pairs(Players:GetPlayers()) do if p.Name == OwnerName then StandAccount, CurrentOwner = p, p; return true end end return false end
function Say(message) if Remotes.SayMessage then Remotes.SayMessage:FireServer(message, "All") end end
function SendStandMessage(message) if Config.ChatCmds then Say(message) end end
function GetPlayer(name) for _, p in pairs(Players:GetPlayers()) do if p.Name:lower():sub(1, #name) == name:lower() then return p end end return nil end
function GetTargetCharacter() return TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") and TargetPlayer.Character end
function GetOwnerCharacter() return LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character end
function PlaySound(id) if not Config.Sounds then return end local s = Instance.new("Sound", Workspace); s.SoundId = "rbxassetid://"..tostring(id); s:Play(); game.Debris:AddItem(s, 20) end
function Animate(animId) if Remotes.Animation then local anim = Instance.new("StringValue", LocalPlayer.Character); anim.Name = "playanimation"; anim.Value = animId; game.Debris:AddItem(anim, 1) end end
function Invoke(remote, ...) if Remotes[remote] then return Remotes[remote]:InvokeServer(...) end end
function Fire(remote, ...) if Remotes[remote] then Remotes[remote]:FireServer(...) end end

--//=========================================================================\\
--||                           COMBAT FUNCTIONS                              ||
--\\=========================================================================//

function Attack()
    TargetCharacter = GetTargetCharacter()
    OwnerCharacter = GetOwnerCharacter()
    if not (TargetCharacter and OwnerCharacter) then return end
    
    local pred = Prediction.Velocity * (Config.AutoPrediction and Config.AttackAutoPrediction or Config.AttackPrediction)
    local pos = TargetCharacter.HumanoidRootPart.Position + pred
    if (OwnerCharacter.HumanoidRootPart.Position - pos).Magnitude > Config.AttackDistance then return end
    
    local attackPos = CFrame.new(pos) * (Config.AttackMode:lower() == "under" and CFrame.new(0, -3, 0) or CFrame.new(0, 3, 0))
    local meleeType = Config.Attack:lower() == 'heavy' and "Charge" or (Config.Melee or "Punch")
    
    if Attacking then Invoke("Melee", "Melee", meleeType, attackPos, TargetCharacter.Torso) end
end

function GunAttack()
    TargetCharacter = GetTargetCharacter()
    if not TargetCharacter then return end
    
    local pred = Prediction.Velocity * (Config.Resolver and 0.1 or 0.15)
    local pos = TargetCharacter.HumanoidRootPart.Position + pred
    
    if Attacking then Fire("Gun", "Gun", "Shoot", pos, TargetCharacter.Torso, Config.GunMode) end
end

function LoopKill(target, useGun)
    spawn(function()
        while (useGun and GAutoKillLoop or not useGun and AutoKillLoop) and TargetPlayer == target and GetTargetCharacter() and GetTargetCharacter().Humanoid.Health > 0 do
            if useGun then
                GunAttack()
            else
                Attack()
            end
            task.wait(0.1)
        end
        if useGun then GAutoKillLoop = false else AutoKillLoop = false end
        SendStandMessage("Auto-kill loop for " .. target.Name .. " finished.")
    end)
end

--//=========================================================================\\
--||                           COMMAND HANDLER                               ||
--\\=========================================================================//

-- Summon/Vanish
local summonCmds = {"s", "/e q", "/e q1", "/e q2", "/e q3", "summon!", "summon1!", "summon2!", "summon3!"}
for _, cmd in ipairs(summonCmds) do Commands[cmd] = function() Attacking = true; Say(Config.CustomSummon) end end
for standName, data in pairs(StandData) do Commands[standName:lower().."!"] = function() Config.StandMode = standName; Commands.summon() end end
Commands.vanish = function() Attacking = false; Say("Vanish!") end
Aliases = {["desummon!"] = "vanish", ["/e w"] = "vanish"}

-- Attack
Commands["attack!"] = function() Attacking = true; SendStandMessage("Attacking enabled.") end
Commands["unattack!"] = function() Attacking = false; SendStandMessage("Attacking disabled.") end
Aliases["stab!"] = "attack!"; Aliases["unstab!"] = "unattack!"; Aliases["gkill!"] = "attack!"

-- Attack Modes
Commands["combat!"] = function() Config.Melee = "Punch" end; Commands["knife!"] = function() Config.Melee = "Knife" end; Commands["pitch!"] = function() Config.Melee = "Pitchfork" end
Commands["sign!"] = function() Config.Melee = "Stopsign" end; Commands["whip!"] = function() Config.Melee = "Whip" end
Commands["hidden!"] = function() Config.AttackMode = "Under" end; Commands["default!"] = function() Config.AttackMode = "Sky" end
Commands["drop!"] = function() local c = GetTargetCharacter(); if c then c.Humanoid.Sit = true end end
Commands["throw!"] = function() local c = GetTargetCharacter(); if c then c.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * 100 + Vector3.new(0, 50, 0) end end
Commands["resolver!"] = function() Config.Resolver = true end; Commands["unresolver!"] = function() Config.Resolver = false end

-- Targeting
Commands.target = function(a) local n=a[1]; if not n then return end if n:lower()=="me" then TargetPlayer=CurrentOwner elseif n:lower()=="unlock" then TargetPlayer=nil;SendStandMessage("Unlocked.") else local f=GetPlayer(n); if f then TargetPlayer=f;SendStandMessage("Target: "..f.Name) else SendStandMessage("Not found: "..n) end end end
Commands.bring = function() local t = GetTargetCharacter(); if t and GetOwnerCharacter() then t.HumanoidRootPart.CFrame = GetOwnerCharacter().HumanoidRootPart.CFrame end end
Commands.gbring = function() local t = GetTargetCharacter(); if t and GetOwnerCharacter() then Fire("Melee", "Social", "Carry", t.Torso); task.wait(0.2); t.HumanoidRootPart.CFrame = GetOwnerCharacter().HumanoidRootPart.CFrame end end
Commands.smite = function() local t = GetTargetCharacter(); if t then t.HumanoidRootPart.Velocity = Vector3.new(0, 2000, 0) end end
Commands.view = function() if GetTargetCharacter() then Camera.CameraSubject = GetTargetCharacter().Humanoid end end; Commands["view!"] = Commands.view
Commands.frame = function() Config.Position = "Target" end
Commands.bag = function() local t = GetTargetCharacter(); if t then Invoke("Melee", "Social", "Bag", t.Torso) end end
Commands.arrest = function() local t = GetTargetCharacter(); if t then Invoke("Social", "Arrest", t.Torso) end end
Commands.knock = function() local t = GetTargetCharacter(); if t then Invoke("Melee", "Melee", Config.Melee, t.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0), t.Torso) end end; Commands.k = Commands.knock
Commands.pull = function() local t = GetTargetCharacter(); if t then Invoke("Melee", "Social", "Hairpull", t.Torso) end end
Commands.taser = function() local t = GetTargetCharacter(); if t then Fire("Gun", "Gun", "Shoot", t.HumanoidRootPart.Position, t.Torso, "Taser") end end
Commands.autokill = function() AutoKillLoop = not AutoKillLoop; if AutoKillLoop and TargetPlayer then SendStandMessage("Autokill ON."); LoopKill(TargetPlayer, false) else SendStandMessage("Autokill OFF.") end end
Commands.stomp = function() local t = GetTargetCharacter(); if t then Fire("Stomp", "Stomp", t.Torso) end end
Commands.annoy = function() AnnoyLoop = not AnnoyLoop; SendStandMessage("Annoy: " .. tostring(AnnoyLoop)) end; Commands.kannoy = Commands.annoy
Commands.gknock = function() local t=GetTargetCharacter(); if t then Fire("Gun","Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,Config.GunMode) end end
Commands.gstomp = Commands.gknock
Commands.gauto = function() GAutoKillLoop = not GAutoKillLoop; if GAutoKillLoop and TargetPlayer then SendStandMessage("Gun Autokill ON."); LoopKill(TargetPlayer, true) else SendStandMessage("Gun Autokill OFF.") end end
Commands.fstomp = function() local t=GetTargetCharacter(); if t then Invoke("Melee","Melee","Flamethrower",t.HumanoidRootPart.CFrame,t.Torso) end end; Commands.fknock = Commands.fstomp
Commands.rk = function() local t=GetTargetCharacter(); if t and t:FindFirstChild("Right Leg") then t["Right Leg"]:Destroy() end end
Commands.rm = function() local t=GetTargetCharacter(); if t then for _,v in pairs(t:GetChildren()) do if v:IsA("BasePart") then v:Destroy() end end end end

-- Misc
Commands.blow = function() Animate("6522770228") end; Commands.doggy = function() Animate("6522765039") end
Commands["hide!"] = function() Config.AutoMask = true end
Commands.surgeon=function() Config.MaskMode="Surgeon" end; Commands.paintball=function() Config.MaskMode="Paintball" end; Commands.pumpkin=function() Config.MaskMode="Pumpkin" end;
Commands.hockey=function() Config.MaskMode="Hockey" end; Commands.ninja=function() Config.MaskMode="Ninja" end; Commands.riot=function() Config.MaskMode="Riot" end
Commands.breathing=function() Config.MaskMode="Breathing" end; Commands.skull=function() Config.MaskMode="Skull" end
Commands.hover=function() Config.FlyMode="Hover" end; Commands.flyv1=function() Config.FlyMode="FlyV1" end; Commands.flyv2=function() Config.FlyMode="FlyV2" end;
Commands.glide=function() Config.FlyMode="Glide" end; Commands.heaven=function() Config.FlyMode="Heaven" end
Commands.goto = function(args) local p=args[1] and args[1]:lower(); if Locations[p] and GetOwnerCharacter() then GetOwnerCharacter().HumanoidRootPart.CFrame = CFrame.new(Locations[p]) end end
for _, alias in ipairs({"goto!", "tp!", "to!", ".tp", ".to", ".goto"}) do Commands[alias] = Commands.goto end
Commands.give = function(args) local p=GetPlayer(args[1]); if p then CurrentOwner=p; SendStandMessage("Stand given to "..p.Name) end end
Commands["return"] = function() CurrentOwner=StandAccount; SendStandMessage("Stand returned.") end
Commands["gun!"] = function() Invoke("Purchase", Config.GunMode, "Guns", 100) end
Commands.rifle=function() Config.GunMode="Rifle" end; Commands.lmg=function() Config.GunMode="LMG" end; Commands.aug=function() Config.GunMode="Aug" end
Commands["autodrop!"] = function() AutoDropping = true end; Commands["unautodrop!"] = function() AutoDropping = false end
Commands["wallet!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().Wallet:Clone().Parent = GetOwnerCharacter() end end
Commands["unwallet!"] = function() if GetOwnerCharacter() and GetOwnerCharacter():FindFirstChild("Wallet") then GetOwnerCharacter().Wallet:Destroy() end end
Commands.dcash = function() Fire("DropCash", 15000) end
Commands["left!"]=function() Config.Position="Left" end; Commands["right!"]=function() Config.Position="Right" end; Commands["back!"]=function() Config.Position="Back" end
Commands["under!"]=function() Config.Position="Under" end; Commands["alt!"]=function() Config.Position="Mid" end; Commands["upright!"]=function() Config.Position="UpRight" end
Commands["upleft!"]=function() Config.Position="UpLeft" end; Commands["upcenter!"]=function() Config.Position="UpMid" end; Commands["walk!"]=function() Config.Position="Walk" end
Commands["ac!"] = function() AutoCalling = not AutoCalling end
Commands["rejoin!"] = function() TeleportService:Teleport(game.PlaceId) end; Commands["rj!"] = Commands["rejoin!"]
Commands["leave!"] = function() LocalPlayer:Kick() end
Commands["autosave!"] = function() AutoSaving = true end; Commands["unautosave!"] = function() AutoSaving = false end
Commands["re!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().Humanoid.Health = 0 end end
Commands["heal!"] = function() local h=GetOwnerCharacter().Humanoid; if h then h.Health=h.MaxHealth end end
Commands["song!"] = function() PlaySound(Config.CustomSong) end
Commands["stopaudio!"] = function() for _,s in pairs(Workspace:GetChildren()) do if s:IsA("Sound") then s:Stop() end end end
Commands["stop!"] = function() Config.Position = "Stop" end
Commands["crew!"] = function() GroupService:JoinGroup(Config.CrewID) end; Commands["uncrew!"] = function() GroupService:LeaveGroup(Config.CrewID) end
Commands["moveset1"] = function() Invoke("Melee","Moveset",1) end; Commands["moveset2"] = function() Invoke("Melee","Moveset",2) end
Commands["weld!"] = function() local char = GetOwnerCharacter(); if char then char.HumanoidRootPart.Anchored = true end end
Commands["unblock!"] = function() local char = GetOwnerCharacter(); if char then char.HumanoidRootPart.Anchored = false end end
Commands.pose1 = function() local p=StandData[Config.StandMode].Poses; if p then Animate(p[1]) end end; Commands.pose2 = function() local p=StandData[Config.StandMode].Poses; if p then Animate(p[2]) end end; Commands.pose3 = function() local p=StandData[Config.StandMode].Poses; if p then Animate(p[3]) end end
Commands["police!"] = function() if Teams:FindFirstChild("Police") then LocalPlayer.Team = Teams.Police end end
Commands["lettuce!"] = function() AutoLettuce = true end; Commands["unlettuce!"] = function() AutoLettuce = false end
Commands["lowgfx!"] = function() settings().Rendering.QualityLevel = "Level01" end
Commands["redeem!"] = function(args) Fire("Code", args[1]) end
Commands["unjail!"] = function() if GetOwnerCharacter() then GetOwnerCharacter().HumanoidRootPart.CFrame = CFrame.new(-520, 18, 50) end end
Commands["barrage!"] = function() Animate("6522778945") end; Commands["muda!"]=Commands["barrage!"]; Commands["ora!"]=Commands["barrage!"]
Commands["altmode!"] = function(args) local f=GetPlayer(args[1]); if f then AltTarget=f; SendStandMessage("Alt mode target: "..f.Name) end end
Commands["vhc!"] = function() Fire("Vehicle", "Car") end

function ProcessCommand(message, speaker)
    if not CurrentOwner or speaker ~= CurrentOwner.Name then return end
    
    local prefix = Config.CustomPrefix or "."
    local args = {}
    for word in message:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return end
    
    local cmd = table.remove(args, 1):lower()
    local isPrefixed = cmd:sub(1, 1) == prefix
    
    if isPrefixed then
        cmd = cmd:sub(2)
    end
    
    if Commands[cmd] then
        Commands[cmd](args)
    end
end

--//=========================================================================\\
--||                                MAIN SCRIPT                              ||
--\\=========================================================================//

Initialize()

if Config.LowGraphics then settings().Rendering.QualityLevel = "Level01" end
if Config.Hidescreen then local s=Instance.new("ScreenGui", CoreGui); Instance.new("Frame",s).Size=UDim2.new(1,0,1,0) end

print("Stando V5: Initialized on " .. LocalPlayer.Name .. ". Awaiting Owner: " .. OwnerName)
Say("V5.0 Initialized on " .. LocalPlayer.Name .. ". Awaiting Owner: " .. OwnerName)

while not FindStand() do
    task.wait(1)
end
print("Stando V5: Owner located: " .. StandAccount.Name)
Say("Owner located: " .. StandAccount.Name)

-- Immediately buy gun and mask if configured
if Config.AutoMask then Fire("Purchase", Config.MaskMode, "Masks") end
task.wait(0.5)
Fire("Purchase", Config.GunMode, "Guns", 100)

TextChatService.MessageReceived:Connect(function(msg) ProcessCommand(msg.Text, msg.TextSource.Name) end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        OwnerCharacter = GetOwnerCharacter()
        TargetCharacter = GetTargetCharacter()
        
        if TargetCharacter then Prediction.Velocity = TargetCharacter.HumanoidRootPart.Velocity else Prediction.Velocity = Vector3.new() end
        
        if Config.AntiStomp and OwnerCharacter and OwnerCharacter.Humanoid.PlatformStand then Fire("Stomp", "Stomp", OwnerCharacter.Torso) end
        
        if AutoSaving and OwnerCharacter and OwnerCharacter.Humanoid.Health < 25 then OwnerCharacter.HumanoidRootPart.CFrame = CFrame.new(Locations[Config.AutoSaveLocation]) end

        if AutoDropping then Fire("DropCash", 1000) end
        
        if AutoLettuce and OwnerCharacter and OwnerCharacter:FindFirstChild("Lettuce") then OwnerCharacter.Lettuce:Activate() end
        
        if AnnoyLoop and TargetCharacter and OwnerCharacter then TargetCharacter.HumanoidRootPart.CFrame = OwnerCharacter.HumanoidRootPart.CFrame * CFrame.new(0,0,-3) end

        if OwnerCharacter and CurrentOwner and CurrentOwner.Character and Config.Position ~= "Stop" then
            local posTarget = AltTarget and AltTarget.Character or CurrentOwner.Character
            local followTarget = Config.Position == "Target" and (TargetCharacter or posTarget) or posTarget
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

print("Stando V5: Main loop is running.")
