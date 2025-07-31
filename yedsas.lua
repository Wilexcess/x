--[[
    STANDO V5 - DEFINITIVE & POLISHED VERSION (Coroutine Execution)
    This version uses coroutine.wrap for maximum stability and compatibility.
    This should prevent the script from halting after initialization.
]]

-- This wrapper ensures the entire script runs in its own protected thread.
coroutine.wrap(function()
    
    if not game:IsLoaded() then
        print("Stando V5: Game not loaded, waiting...")
        game.Loaded:Wait()
    end
    print("Stando V5: Game loaded.")
    task.wait(2)

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
    
    local Config = getgenv().Configuration or {}
    local OwnerName = getgenv().Owner
    
    -- Script State
    local StandAccount, CurrentOwner, TargetPlayer, AltTarget
    local OwnerCharacter, TargetCharacter
    local Attacking, AutoSaving, AutoDropping, Boxing, AnnoyLoop = false, false, false, false, false
    local AutoKillLoop, GAutoKillLoop, AutoLettuce = false, false, false
    
    -- Data Tables
    local Commands, StandData, Positions, Locations, Aliases = {}, {}, {}, {}, {}
    local Prediction = { Velocity = Vector3.new() }
    local Remotes = {}
    
    --//=========================================================================\\
    --||                           INITIALIZATION                                ||
    --\\=========================================================================//
    
    function Initialize()
        print("Stando V5: Finding game RemoteEvents...")
        local success, err = pcall(function()
            Remotes.Stomp = ReplicatedStorage:WaitForChild("Main", 15)
            Remotes.SayMessage = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 15):WaitForChild("SayMessageRequest", 15)
            Remotes.Animation = ReplicatedStorage:WaitForChild("Animation", 15)
            Remotes.Gun = ReplicatedStorage:WaitForChild("Main", 15)
            Remotes.Melee = ReplicatedStorage:WaitForChild("Main", 15)
            Remotes.Purchase = ReplicatedStorage.Assets.Remotes:WaitForChild("RequestStorePurchase", 15)
            Remotes.DropCash = ReplicatedStorage.Remotes:WaitForChild("DropDHC", 15)
            Remotes.Vehicle = ReplicatedStorage.Assets.Remotes:WaitForChild("VehicleEvent", 15)
            Remotes.Code = ReplicatedStorage.Remotes:WaitForChild("RedeemCode", 15)
            Remotes.Heal = ReplicatedStorage:WaitForChild("Main", 15)
        end)
        if not success then
            warn("Stando V5 FATAL ERROR: Could not find critical remotes. The game may have updated. Error:", err)
            return false
        end
        print("Stando V5: RemoteEvents located.")
        return true
    end

    function PopulateDataTables()
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
            Back = CFrame.new(0, 0, 5), Left = CFrame.new(-5, 0, 0), Right = CFrame.new(5, 0, 0), Mid = CFrame.new(0, 0, 0),
            UpMid = CFrame.new(0, 5, 0), UpLeft = CFrame.new(-5, 5, 0), UpRight = CFrame.new(5, 5, 0),
            Target = CFrame.new(0, 0, 5), Under = CFrame.new(0, -3, 0), Walk = CFrame.new(0, 0, 0)
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
    function Say(message) if Remotes.SayMessage then pcall(function() Remotes.SayMessage:FireServer(message, "All") end) end end
    function SendStandMessage(message) if Config.ChatCmds then Say(message) end end
    function GetPlayer(name) for _, p in pairs(Players:GetPlayers()) do if p.Name:lower():sub(1, #name) == name:lower() then return p end end return nil end
    function GetTargetCharacter() return TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") and TargetPlayer.Character end
    function GetOwnerCharacter() return LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character end
    function PlaySound(id) if not Config.Sounds then return end local s = Instance.new("Sound", Workspace); s.SoundId = "rbxassetid://"..tostring(id); s:Play(); game.Debris:AddItem(s, 20) end
    function Animate(animId) if Remotes.Animation and GetOwnerCharacter() then local anim = Instance.new("StringValue", GetOwnerCharacter()); anim.Name = "playanimation"; anim.Value = animId; game.Debris:AddItem(anim, 1) end end
    function Invoke(remote, ...) local args = {...}; pcall(function() if Remotes[remote] then Remotes[remote]:InvokeServer(unpack(args)) end end) end
    function Fire(remote, ...) local args = {...}; pcall(function() if Remotes[remote] then Remotes[remote]:FireServer(unpack(args)) end end) end
    
    --//=========================================================================\\
    --||                           COMBAT FUNCTIONS                              ||
    --\\=========================================================================//
    
    function Attack()
        TargetCharacter, OwnerCharacter = GetTargetCharacter(), GetOwnerCharacter()
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
        local loopVar = useGun and "GAutoKillLoop" or "AutoKillLoop"
        getgenv()[loopVar] = true
        task.spawn(function()
            while getgenv()[loopVar] and TargetPlayer == target and GetTargetCharacter() and GetTargetCharacter().Humanoid.Health > 0 do
                if useGun then GunAttack() else Attack() end
                task.wait(0.1)
            end
            getgenv()[loopVar] = false
            SendStandMessage("Autokill loop for " .. target.Name .. " finished.")
        end)
    end
    
    --//=========================================================================\\
    --||                           COMMAND HANDLER                               ||
    --\\=========================================================================//
    do
        local C,A=Commands,Aliases;C.s=function()C.summon()end;C["/e q"]=C.s;C["/e q1"]=C.s;C["/e q2"]=C.s;C["/e q3"]=C.s;C["summon!"]=C.s;C["summon1!"]=C.s;C["summon2!"]=C.s;C["summon3!"]=C.s
        for n,_ in pairs(StandData) do C[n:lower().."!"]=function()Config.StandMode=n;C.summon()end end
        C.summon=function()Attacking=true;if Config.SummonPoses and Config.SummonPoses~="false" then local pN=tonumber(Config.SummonPoses:match("%d+"))or 1;if StandData[Config.StandMode]and StandData[Config.StandMode].Poses[pN]then Animate(StandData[Config.StandMode].Poses[pN])end end;if Config.SummonMusic then local sId=Config.SummonMusicID=='Default'and StandData[Config.StandMode]and StandData[Config.StandMode].SummonSound or Config.SummonMusicID;PlaySound(sId)end;Say(Config.CustomSummon)end
        C.vanish=function()Attacking,AnnoyLoop,AutoKillLoop,GAutoKillLoop=false,false,false,false;Say("Vanish!")end;A["vanish!"]=C.vanish;A["desummon!"]=C.vanish;A["/e w"]=C.vanish
        C["attack!"]=function()Attacking=true end;C["unattack!"]=function()Attacking=false end;A["stab!"]=C["attack!"];A["unstab!"]=C["unattack!"];A["gkill!"]=C["attack!"]
        C["combat!"]=function()Config.Melee="Punch"end;C["knife!"]=function()Config.Melee="Knife"end;C["pitch!"]=function()Config.Melee="Pitchfork"end;C["sign!"]=function()Config.Melee="Stopsign"end;C["whip!"]=function()Config.Melee="Whip"end
        C["hidden!"]=function()Config.AttackMode="Under"end;C["default!"]=function()Config.AttackMode="Sky"end;C["drop!"]=function()local c=GetTargetCharacter();if c then c.Humanoid.Sit=true end end
        C["throw!"]=function()local c=GetTargetCharacter();if c then c.HumanoidRootPart.Velocity=Camera.CFrame.LookVector*100+Vector3.new(0,50,0)end end
        C["resolver!"]=function()Config.Resolver=true end;C["unresolver!"]=function()Config.Resolver=false end
        C.target=function(a)local n=a[1];if not n then return end if n:lower()=="me"then TargetPlayer=CurrentOwner elseif n:lower()=="unlock"then TargetPlayer=nil;SendStandMessage("Unlocked.")else local f=GetPlayer(n);if f then TargetPlayer=f;SendStandMessage("Target: "..f.Name)else SendStandMessage("Not found: "..n)end end end
        C.bring=function()local t=GetTargetCharacter();if t and GetOwnerCharacter()then t.HumanoidRootPart.CFrame=GetOwnerCharacter().HumanoidRootPart.CFrame end end
        C.gbring=function()local t=GetTargetCharacter();if t and GetOwnerCharacter()then Fire("Melee","Social","Carry",t.Torso);task.wait(0.2);t.HumanoidRootPart.CFrame=GetOwnerCharacter().HumanoidRootPart.CFrame end end
        C.smite=function()local t=GetTargetCharacter();if t then t.HumanoidRootPart.Velocity=Vector3.new(0,2000,0)end end
        C.view=function()if GetTargetCharacter()then Camera.CameraSubject=GetTargetCharacter().Humanoid end end;C["view!"]=C.view
        C.frame=function()Config.Position="Target"end;C.bag=function()local t=GetTargetCharacter();if t then Invoke("Melee","Social","Bag",t.Torso)end end
        C.arrest=function()local t=GetTargetCharacter();if t then Invoke("Melee","Social","Arrest",t.Torso)end end
        C.knock=function()local t=GetTargetCharacter();if t then Invoke("Melee","Melee",Config.Melee,t.HumanoidRootPart.CFrame+Vector3.new(0,2,0),t.Torso)end end;C.k=C.knock
        C.pull=function()local t=GetTargetCharacter();if t then Invoke("Melee","Social","Hairpull",t.Torso)end end
        C.taser=function()local t=GetTargetCharacter();if t then Fire("Gun","Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,"Taser")end end
        C.autokill=function()AutoKillLoop=not AutoKillLoop;if AutoKillLoop and TargetPlayer then SendStandMessage("Autokill ON.");LoopKill(TargetPlayer,false)else AutoKillLoop=false;SendStandMessage("Autokill OFF.")end end
        C.stomp=function()local t=GetTargetCharacter();if t then Fire("Stomp","Stomp",t.Torso)end end
        C.annoy=function()AnnoyLoop=not AnnoyLoop;SendStandMessage("Annoy: "..tostring(AnnoyLoop))end;C.kannoy=C.annoy
        C.gknock=function()local t=GetTargetCharacter();if t then Fire("Gun","Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,Config.GunMode)end end;C.gstomp=C.gknock
        C.gauto=function()GAutoKillLoop=not GAutoKillLoop;if GAutoKillLoop and TargetPlayer then SendStandMessage("Gun Autokill ON.");LoopKill(TargetPlayer,true)else GAutoKillLoop=false;SendStandMessage("Gun Autokill OFF.")end end
        C.fstomp=function()local t=GetTargetCharacter();if t then Invoke("Melee","Melee","Flamethrower",t.HumanoidRootPart.CFrame,t.Torso)end end;C.fknock=C.fstomp
        C.rk=function()local t=GetTargetCharacter();if t and t:FindFirstChild("Right Leg")then t["Right Leg"]:Destroy()end end
        C.rm=function()local t=GetTargetCharacter();if t then for _,v in pairs(t:GetChildren())do if v:IsA("BasePart")then v:Destroy()end end end end
        C.blow=function()Animate("6522770228")end;C.doggy=function()Animate("6522765039")end
        C["hide!"]=function()Config.AutoMask=true end;C.surgeon=function()Config.MaskMode="Surgeon"end;C.paintball=function()Config.MaskMode="Paintball"end;C.pumpkin=function()Config.MaskMode="Pumpkin"end
        C.hockey=function()Config.MaskMode="Hockey"end;C.ninja=function()Config.MaskMode="Ninja"end;C.riot=function()Config.MaskMode="Riot"end;C.breathing=function()Config.MaskMode="Breathing"end;C.skull=function()Config.MaskMode="Skull"end
        C.hover=function()Config.FlyMode="Hover"end;C.flyv1=function()Config.FlyMode="FlyV1"end;C.flyv2=function()Config.FlyMode="FlyV2"end;C.glide=function()Config.FlyMode="Glide"end;C.heaven=function()Config.FlyMode="Heaven"end
        C.goto=function(a)local p=a[1]and a[1]:lower();if Locations[p]and GetOwnerCharacter()then GetOwnerCharacter().HumanoidRootPart.CFrame=CFrame.new(Locations[p])end end
        for _,al in ipairs({"goto!","tp!","to!",".tp",".to",".goto"})do C[al]=C.goto end
        C.give=function(a)local p=GetPlayer(a[1]);if p then CurrentOwner=p;SendStandMessage("Stand given to "..p.Name)end end;C["return"]=function()CurrentOwner=StandAccount;SendStandMessage("Stand returned.")end
        C["gun!"]=function()Invoke("Purchase",Config.GunMode,"Guns",100)end;C.rifle=function()Config.GunMode="Rifle"end;C.lmg=function()Config.GunMode="LMG"end;C.aug=function()Config.GunMode="Aug"end
        C["autodrop!"]=function()AutoDropping=true end;C["unautodrop!"]=function()AutoDropping=false end
        C["wallet!"]=function()local c=GetOwnerCharacter();if c and c:FindFirstChild("Wallet")then c.Wallet:Clone().Parent=c end end;C["unwallet!"]=function()local c=GetOwnerCharacter();if c and c:FindFirstChild("Wallet")then c.Wallet:Destroy()end end
        C.dcash=function()Fire("DropCash",15000)end
        C["left!"]=function()Config.Position="Left"end;C["right!"]=function()Config.Position="Right"end;C["back!"]=function()Config.Position="Back"end;C["under!"]=function()Config.Position="Under"end;C["alt!"]=function()Config.Position="Mid"end
        C["upright!"]=function()Config.Position="UpRight"end;C["upleft!"]=function()Config.Position="UpLeft"end;C["upcenter!"]=function()Config.Position="UpMid"end;C["walk!"]=function()Config.Position="Walk"end
        C["ac!"]=function()AutoCalling=not AutoCalling end;C["rejoin!"]=function()TeleportService:Teleport(game.PlaceId)end;C["rj!"]=C["rejoin!"];C["leave!"]=function()LocalPlayer:Kick()end
        C["autosave!"]=function()AutoSaving=true end;C["unautosave!"]=function()AutoSaving=false end;C["re!"]=function()if GetOwnerCharacter()then GetOwnerCharacter().Humanoid.Health=0 end end
        C["heal!"]=function()local h=GetOwnerCharacter().Humanoid;if h then h.Health=h.MaxHealth end end;C["song!"]=function()PlaySound(Config.CustomSong)end
        C["stopaudio!"]=function()for _,s in pairs(Workspace:GetChildren())do if s:IsA("Sound")then s:Stop()end end end;C["stop!"]=function()Config.Position="Stop"end
        C["crew!"]=function()if Config.CrewID then pcall(GroupService.JoinGroup,GroupService,Config.CrewID)end end;C["uncrew!"]=function()if Config.CrewID then pcall(GroupService.LeaveGroup,GroupService,Config.CrewID)end end
        C["moveset1"]=function()Invoke("Melee","Moveset",1)end;C["moveset2"]=function()Invoke("Melee","Moveset",2)end
        C["weld!"]=function()local c=GetOwnerCharacter();if c then c.HumanoidRootPart.Anchored=true end end;C["unblock!"]=function()local c=GetOwnerCharacter();if c then c.HumanoidRootPart.Anchored=false end end
        C.pose1=function()local p=StandData[Config.StandMode]and StandData[Config.StandMode].Poses;if p then Animate(p[1])end end;C.pose2=function()local p=StandData[Config.StandMode]and StandData[Config.StandMode].Poses;if p then Animate(p[2])end end;C.pose3=function()local p=StandData[Config.StandMode]and StandData[Config.StandMode].Poses;if p then Animate(p[3])end end
        C["police!"]=function()if Teams:FindFirstChild("Police")then LocalPlayer.Team=Teams.Police end end
        C["lettuce!"]=function()AutoLettuce=true end;C["unlettuce!"]=function()AutoLettuce=false end
        C["lowgfx!"]=function()settings().Rendering.QualityLevel="Level01"end;C["redeem!"]=function(a)Fire("Code",a[1])end
        C["unjail!"]=function()if GetOwnerCharacter()then GetOwnerCharacter().HumanoidRootPart.CFrame=CFrame.new(-520,18,50)end end
        C["barrage!"]=function()Animate("6522778945")end;C["muda!"]=C["barrage!"];C["ora!"]=C["barrage!"]
        C["altmode!"]=function(a)local f=GetPlayer(a[1]);if f then AltTarget=f;SendStandMessage("Alt target: "..f.Name)end end
        C["vhc!"]=function()Fire("Vehicle","Car")end
    end
    
    function ProcessCommand(message, speaker)
        if not CurrentOwner or speaker ~= CurrentOwner.Name then return end
        local prefix = Config.CustomPrefix or "."
        local args = {}; for word in message:gmatch("%S+") do table.insert(args, word) end
        if #args == 0 then return end
        local cmd = table.remove(args, 1):lower()
        if cmd:sub(1, 1) == prefix then cmd = cmd:sub(2) end
        if Commands[cmd] then print("Stando V5: Executing command '"..cmd.."'"); Commands[cmd](args) end
    end
    
    function RunMain()
        if not Initialize() then return end
        PopulateDataTables()
        
        if Config.LowGraphics then settings().Rendering.QualityLevel = "Level01" end
        if Config.Hidescreen then local s=Instance.new("ScreenGui", CoreGui); Instance.new("Frame",s).Size=UDim2.new(1,0,1,0) end
        Say("Stando V5 Initialized on " .. LocalPlayer.Name .. ". Awaiting Owner: " .. OwnerName)
        
        while not FindStand() do print("Stando V5: Searching for Owner..."); task.wait(1) end
        Say("Owner located: " .. StandAccount.Name)
        
        if not GetOwnerCharacter() then print("Stando V5: Waiting for character to spawn..."); LocalPlayer.CharacterAdded:Wait(); task.wait(3); print("Stando V5: Character loaded.") end
        
        pcall(function()
            if Config.AutoMask then Fire("Purchase", Config.MaskMode, "Masks") end
            task.wait(0.5); Fire("Purchase", Config.GunMode, "Guns", 100)
            print("Stando V5: Attempted to purchase initial gear.")
        end)
        
        TextChatService.MessageReceived:Connect(function(msg) ProcessCommand(msg.Text, msg.TextSource.Name) end)
        
        RunService.Heartbeat:Connect(function()
            local success, err = pcall(function()
                OwnerCharacter = GetOwnerCharacter()
                TargetCharacter = GetTargetCharacter()
                if TargetCharacter and TargetCharacter.Humanoid.Health > 0 then Prediction.Velocity = TargetCharacter.HumanoidRootPart.Velocity else Prediction.Velocity = Vector3.new() end
                if Attacking then if Config.Melee and Config.Melee ~= "Punch" then Attack() elseif Config.GunMode and Config.GunMode ~= "Rifle" then GunAttack() else Attack() end end
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
                        if Config.Smoothing then OwnerCharacter.HumanoidRootPart.CFrame = OwnerCharacter.HumanoidRootPart.CFrame:Lerp(goal, 0.2) else OwnerCharacter.HumanoidRootPart.CFrame = goal end
                    end
                end
            end)
            if not success then warn("Stando V5 Heartbeat Error:", err) end
        end)
        
        print("Stando V5: Main loop is now running.")
        SendStandMessage("Stando V5 is fully operational.")
    end
    
    local success, err = pcall(RunMain)
    if not success then
        warn("Stando V5 failed to initialize:", err)
        Say("Stando V5 failed to initialize: " .. tostring(err))
    end
    
end)() -- End and execute the coroutine wrapper
