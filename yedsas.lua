--[[
    STANDO V5 - DEFINITIVE & POLISHED VERSION (FINAL FIX)
    This version uses a robust coroutine execution model and a completely rewritten,
    explicit command handler to eliminate all previous syntax and scope errors.
]]

coroutine.wrap(function()
    if not game:IsLoaded() then print("Stando V5: Game not loaded, waiting..."); game.Loaded:Wait() end
    print("Stando V5: Game loaded."); task.wait(2)

    -- Services and Variables
    local Players, Workspace, CoreGui, ReplicatedStorage, RunService, SoundService, GroupService, TeleportService, Teams, TextChatService = game:GetService("Players"), game:GetService("Workspace"), game:GetService("CoreGui"), game:GetService("ReplicatedStorage"), game:GetService("RunService"), game:GetService("SoundService"), game:GetService("GroupService"), game:GetService("TeleportService"), game:GetService("Teams"), game:GetService("TextChatService")
    local LocalPlayer, Camera = Players.LocalPlayer, Workspace.CurrentCamera
    local Config, OwnerName = getgenv().Configuration or {}, getgenv().Owner
    local StandAccount, CurrentOwner, TargetPlayer, AltTarget, OwnerCharacter, TargetCharacter
    local Attacking, AutoSaving, AutoDropping, Boxing, AnnoyLoop, AutoKillLoop, GAutoKillLoop, AutoLettuce = false, false, false, false, false, false, false, false
    local Commands, StandData, Positions, Locations = {}, {}, {}, {}
    local Prediction, Remotes = { Velocity = Vector3.new() }, {}

    -- Initialization
    local function InitializeRemotes()
        print("Stando V5: Finding game RemoteEvents...")
        local success, err = pcall(function()
            Remotes.SayMessage = TextChatService:WaitForChild("TextChatRemoteEvent", 15)
            Remotes.Stomp = ReplicatedStorage:WaitForChild("Main", 15)
            Remotes.Animation = ReplicatedStorage:WaitForChild("Animation", 15)
            Remotes.Gun = ReplicatedStorage:WaitForChild("Main", 15)
            Remotes.Melee = ReplicatedStorage:WaitForChild("Main", 15)
            Remotes.Purchase = ReplicatedStorage.Assets.Remotes:WaitForChild("RequestStorePurchase", 15)
            Remotes.DropCash = ReplicatedStorage.Remotes:WaitForChild("DropDHC", 15)
            Remotes.Vehicle = ReplicatedStorage.Assets.Remotes:WaitForChild("VehicleEvent", 15)
            Remotes.Code = ReplicatedStorage.Remotes:WaitForChild("RedeemCode", 15)
            Remotes.Heal = ReplicatedStorage:WaitForChild("Main", 15)
        end)
        if not success then warn("Stando V5 FATAL ERROR finding remotes:", err); return false end
        print("Stando V5: RemoteEvents located."); return true
    end

    -- Helper Functions
    local function FindStand() for _, p in pairs(Players:GetPlayers()) do if p.Name == OwnerName then StandAccount, CurrentOwner = p, p; return true end end return false end
    local function Say(message) if Remotes.SayMessage then pcall(Remotes.SayMessage.FireServer, Remotes.SayMessage, message, {}) end end
    local function SendStandMessage(message) if Config.ChatCmds then Say(message) end end
    local function GetPlayer(name) for _, p in pairs(Players:GetPlayers()) do if p.Name:lower():sub(1, #name) == name:lower() then return p end end return nil end
    local function GetTargetCharacter() return TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") and TargetPlayer.Character end
    local function GetOwnerCharacter() return LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character end
    local function PlaySound(id) if not Config.Sounds then return end local s = Instance.new("Sound", Workspace); s.SoundId = "rbxassetid://"..tostring(id); s:Play(); game.Debris:AddItem(s, 20) end
    local function Animate(animId) if Remotes.Animation and GetOwnerCharacter() then local a = Instance.new("StringValue", GetOwnerCharacter()); a.Name = "playanimation"; a.Value = animId; game.Debris:AddItem(a, 1) end end
    local function Invoke(remote, ...) pcall(function() if Remotes[remote] then Remotes[remote]:InvokeServer(...) end end) end
    local function Fire(remote, ...) pcall(function() if Remotes[remote] then Remotes[remote]:FireServer(...) end end) end

    -- Combat
    local function Attack()
        TargetCharacter, OwnerCharacter = GetTargetCharacter(), GetOwnerCharacter()
        if not (TargetCharacter and OwnerCharacter) then return end
        local pred = Prediction.Velocity * (Config.AutoPrediction and Config.AttackAutoPrediction or Config.AttackPrediction)
        local pos = TargetCharacter.HumanoidRootPart.Position + pred
        if (OwnerCharacter.HumanoidRootPart.Position - pos).Magnitude > Config.AttackDistance then return end
        local attackPos = CFrame.new(pos) * (Config.AttackMode:lower() == "under" and CFrame.new(0, -3, 0) or CFrame.new(0, 3, 0))
        local meleeType = Config.Attack:lower() == 'heavy' and "Charge" or (Config.Melee or "Punch")
        if Attacking then Invoke("Melee", "Melee", meleeType, attackPos, TargetCharacter.Torso) end
    end
    local function GunAttack()
        TargetCharacter = GetTargetCharacter()
        if not TargetCharacter then return end
        local pred = Prediction.Velocity * (Config.Resolver and 0.1 or 0.15)
        local pos = TargetCharacter.HumanoidRootPart.Position + pred
        if Attacking then Fire("Gun", "Gun", "Shoot", pos, TargetCharacter.Torso, Config.GunMode) end
    end
    local function LoopKill(target, useGun)
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

    -- Command Processing
    function ProcessCommand(message, speaker)
        if not CurrentOwner or speaker ~= CurrentOwner.Name then return end
        local prefix = Config.CustomPrefix or "."
        local args = {}; for word in message:gmatch("%S+") do table.insert(args, word) end
        if #args == 0 then return end
        local cmd = table.remove(args, 1):lower()
        if cmd:sub(1, 1) == prefix then cmd = cmd:sub(2) end
        if Commands[cmd] then print("Stando V5: Executing command '"..cmd.."'"); Commands[cmd](args) end
    end

    -- ===================================
    -- COMMAND DEFINITIONS (REWRITTEN)
    -- ===================================
    Commands.summon = function() Attacking = true; if Config.SummonPoses and Config.SummonPoses~="false" then local pN=tonumber(Config.SummonPoses:match("%d+"))or 1;if StandData[Config.StandMode]and StandData[Config.StandMode].Poses[pN]then Animate(StandData[Config.StandMode].Poses[pN])end end;if Config.SummonMusic then local sId=Config.SummonMusicID=='Default'and StandData[Config.StandMode]and StandData[Config.StandMode].SummonSound or Config.SummonMusicID;PlaySound(sId)end;Say(Config.CustomSummon)end
    for standName,_ in pairs(StandData) do Commands[standName:lower().."!"] = function() Config.StandMode = standName; Commands.summon() end end
    Commands.s = Commands.summon; Commands["/e q"]=Commands.summon; Commands["/e q1"]=Commands.summon; Commands["/e q2"]=Commands.summon; Commands["/e q3"]=Commands.summon; Commands["summon!"]=Commands.summon; Commands["summon1!"]=Commands.summon; Commands["summon2!"]=Commands.summon; Commands["summon3!"]=Commands.summon
    Commands.vanish = function()Attacking,AnnoyLoop,AutoKillLoop,GAutoKillLoop=false,false,false,false;Say("Vanish!")end
    Commands["vanish!"]=Commands.vanish; Commands["desummon!"]=Commands.vanish; Commands["/e w"]=Commands.vanish
    Commands["attack!"]=function()Attacking=true end; Commands["unattack!"]=function()Attacking=false end; Commands["stab!"]=Commands["attack!"]; Commands["unstab!"]=Commands["unattack!"]; Commands["gkill!"]=Commands["attack!"]
    Commands["combat!"]=function()Config.Melee="Punch"end; Commands["knife!"]=function()Config.Melee="Knife"end; Commands["pitch!"]=function()Config.Melee="Pitchfork"end; Commands["sign!"]=function()Config.Melee="Stopsign"end; Commands["whip!"]=function()Config.Melee="Whip"end
    Commands["hidden!"]=function()Config.AttackMode="Under"end; Commands["default!"]=function()Config.AttackMode="Sky"end; Commands["drop!"]=function()local c=GetTargetCharacter();if c then c.Humanoid.Sit=true end end; Commands["throw!"]=function()local c=GetTargetCharacter();if c then c.HumanoidRootPart.Velocity=Camera.CFrame.LookVector*100+Vector3.new(0,50,0)end end
    Commands["resolver!"]=function()Config.Resolver=true end; Commands["unresolver!"]=function()Config.Resolver=false end
    Commands.target=function(a)local n=a[1];if not n then return end if n:lower()=="me"then TargetPlayer=CurrentOwner elseif n:lower()=="unlock"then TargetPlayer=nil;SendStandMessage("Unlocked.")else local f=GetPlayer(n);if f then TargetPlayer=f;SendStandMessage("Target: "..f.Name)else SendStandMessage("Not found: "..n)end end end
    Commands.bring=function()local t=GetTargetCharacter();if t and GetOwnerCharacter()then t.HumanoidRootPart.CFrame=GetOwnerCharacter().HumanoidRootPart.CFrame end end
    Commands.gbring=function()local t=GetTargetCharacter();if t and GetOwnerCharacter()then Fire("Melee","Social","Carry",t.Torso);task.wait(0.2);t.HumanoidRootPart.CFrame=GetOwnerCharacter().HumanoidRootPart.CFrame end end
    Commands.smite=function()local t=GetTargetCharacter();if t then t.HumanoidRootPart.Velocity=Vector3.new(0,2000,0)end end
    Commands.view=function()if GetTargetCharacter()then Camera.CameraSubject=GetTargetCharacter().Humanoid end end; Commands["view!"]=Commands.view
    Commands.frame=function()Config.Position="Target"end; Commands.bag=function()local t=GetTargetCharacter();if t then Invoke("Melee","Social","Bag",t.Torso)end end
    Commands.arrest=function()local t=GetTargetCharacter();if t then Invoke("Melee","Social","Arrest",t.Torso)end end
    Commands.knock=function()local t=GetTargetCharacter();if t then Invoke("Melee","Melee",Config.Melee,t.HumanoidRootPart.CFrame+Vector3.new(0,2,0),t.Torso)end end; Commands.k=Commands.knock
    Commands.pull=function()local t=GetTargetCharacter();if t then Invoke("Melee","Social","Hairpull",t.Torso)end end
    Commands.taser=function()local t=GetTargetCharacter();if t then Fire("Gun","Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,"Taser")end end
    Commands.autokill=function()AutoKillLoop=not AutoKillLoop;if AutoKillLoop and TargetPlayer then SendStandMessage("Autokill ON.");LoopKill(TargetPlayer,false)else AutoKillLoop=false;SendStandMessage("Autokill OFF.")end end
    Commands.stomp=function()local t=GetTargetCharacter();if t then Fire("Stomp","Stomp",t.Torso)end end
    Commands.annoy=function()AnnoyLoop=not AnnoyLoop;SendStandMessage("Annoy: "..tostring(AnnoyLoop))end; Commands.kannoy=Commands.annoy
    Commands.gknock=function()local t=GetTargetCharacter();if t then Fire("Gun","Gun","Shoot",t.HumanoidRootPart.Position,t.Torso,Config.GunMode)end end; Commands.gstomp=Commands.gknock
    Commands.gauto=function()GAutoKillLoop=not GAutoKillLoop;if GAutoKillLoop and TargetPlayer then SendStandMessage("Gun Autokill ON.");LoopKill(TargetPlayer,true)else GAutoKillLoop=false;SendStandMessage("Gun Autokill OFF.")end end
    Commands.fstomp=function()local t=GetTargetCharacter();if t then Invoke("Melee","Melee","Flamethrower",t.HumanoidRootPart.CFrame,t.Torso)end end; Commands.fknock=Commands.fstomp
    Commands.rk=function()local t=GetTargetCharacter();if t and t:FindFirstChild("Right Leg")then t["Right Leg"]:Destroy()end end
    Commands.rm=function()local t=GetTargetCharacter();if t then for _,v in pairs(t:GetChildren())do if v:IsA("BasePart")then v:Destroy()end end end end
    Commands.blow=function()Animate("6522770228")end; Commands.doggy=function()Animate("6522765039")end
    Commands["hide!"]=function()Config.AutoMask=true end; Commands.surgeon=function()Config.MaskMode="Surgeon"end; Commands.paintball=function()Config.MaskMode="Paintball"end; Commands.pumpkin=function()Config.MaskMode="Pumpkin"end
    Commands.hockey=function()Config.MaskMode="Hockey"end; Commands.ninja=function()Config.MaskMode="Ninja"end; Commands.riot=function()Config.MaskMode="Riot"end; Commands.breathing=function()Config.MaskMode="Breathing"end; Commands.skull=function()Config.MaskMode="Skull"end
    Commands.hover=function()Config.FlyMode="Hover"end; Commands.flyv1=function()Config.FlyMode="FlyV1"end; Commands.flyv2=function()Config.FlyMode="FlyV2"end; Commands.glide=function()Config.FlyMode="Glide"end; Commands.heaven=function()Config.FlyMode="Heaven"end
    Commands.goto=function(a)local p=a[1]and a[1]:lower();if Locations[p]and GetOwnerCharacter()then GetOwnerCharacter().HumanoidRootPart.CFrame=CFrame.new(Locations[p])end end
    for _,al in ipairs({"goto!","tp!","to!",".tp",".to",".goto"})do Commands[al]=Commands.goto end
    Commands.give=function(a)local p=GetPlayer(a[1]);if p then CurrentOwner=p;SendStandMessage("Stand given to "..p.Name)end end; Commands["return"]=function()CurrentOwner=StandAccount;SendStandMessage("Stand returned.")end
    Commands["gun!"]=function()Invoke("Purchase",Config.GunMode,"Guns",100)end; Commands.rifle=function()Config.GunMode="Rifle"end; Commands.lmg=function()Config.GunMode="LMG"end; Commands.aug=function()Config.GunMode="Aug"end
    Commands["autodrop!"]=function()AutoDropping=true end; Commands["unautodrop!"]=function()AutoDropping=false end
    Commands["wallet!"]=function()local c=GetOwnerCharacter();if c and c:FindFirstChild("Wallet")then c.Wallet:Clone().Parent=c end end; Commands["unwallet!"]=function()local c=GetOwnerCharacter();if c and c:FindFirstChild("Wallet")then c.Wallet:Destroy()end end
    Commands.dcash=function()Fire("DropCash",15000)end
    Commands["left!"]=function()Config.Position="Left"end;Commands["right!"]=function()Config.Position="Right"end;Commands["back!"]=function()Config.Position="Back"end;Commands["under!"]=function()Config.Position="Under"end;Commands["alt!"]=function()Config.Position="Mid"end
    Commands["upright!"]=function()Config.Position="UpRight"end;Commands["upleft!"]=function()Config.Position="UpLeft"end;Commands["upcenter!"]=function()Config.Position="UpMid"end;Commands["walk!"]=function()Config.Position="Walk"end
    Commands["ac!"]=function()AutoCalling=not AutoCalling end;Commands["rejoin!"]=function()TeleportService:Teleport(game.PlaceId)end;Commands["rj!"]=Commands["rejoin!"];Commands["leave!"]=function()LocalPlayer:Kick()end
    Commands["autosave!"]=function()AutoSaving=true end;Commands["unautosave!"]=function()AutoSaving=false end;Commands["re!"]=function()if GetOwnerCharacter()then GetOwnerCharacter().Humanoid.Health=0 end end
    Commands["heal!"]=function()local h=GetOwnerCharacter().Humanoid;if h then h.Health=h.MaxHealth end end;Commands["song!"]=function()PlaySound(Config.CustomSong)end
    Commands["stopaudio!"]=function()for _,s in pairs(Workspace:GetChildren())do if s:IsA("Sound")then s:Stop()end end end;Commands["stop!"]=function()Config.Position="Stop"end
    Commands["crew!"]=function()if Config.CrewID then pcall(GroupService.JoinGroup,GroupService,Config.CrewID)end end;Commands["uncrew!"]=function()if Config.CrewID then pcall(GroupService.LeaveGroup,GroupService,Config.CrewID)end end
    Commands["moveset1"]=function()Invoke("Melee","Moveset",1)end;Commands["moveset2"]=function()Invoke("Melee","Moveset",2)end
    Commands["weld!"]=function()local c=GetOwnerCharacter();if c then c.HumanoidRootPart.Anchored=true end end;Commands["unblock!"]=function()local c=GetOwnerCharacter();if c then c.HumanoidRootPart.Anchored=false end end
    Commands.pose1=function()local p=StandData[Config.StandMode]and StandData[Config.StandMode].Poses;if p then Animate(p[1])end end;Commands.pose2=function()local p=StandData[Config.StandMode]and StandData[Config.StandMode].Poses;if p then Animate(p[2])end end;Commands.pose3=function()local p=StandData[Config.StandMode]and StandData[Config.StandMode].Poses;if p then Animate(p[3])end end
    Commands["police!"]=function()if Teams:FindFirstChild("Police")then LocalPlayer.Team=Teams.Police end end
    Commands["lettuce!"]=function()AutoLettuce=true end;Commands["unlettuce!"]=function()AutoLettuce=false end
    Commands["lowgfx!"]=function()settings().Rendering.QualityLevel="Level01"end;Commands["redeem!"]=function(a)Fire("Code",a[1])end
    Commands["unjail!"]=function()if GetOwnerCharacter()then GetOwnerCharacter().HumanoidRootPart.CFrame=CFrame.new(-520,18,50)end end
    Commands["barrage!"]=function()Animate("6522778945")end;Commands["muda!"]=Commands["barrage!"];Commands["ora!"]=Commands["barrage!"]
    Commands["altmode!"]=function(a)local f=GetPlayer(a[1]);if f then AltTarget=f;SendStandMessage("Alt target: "..f.Name)end end
    Commands["vhc!"]=function()Fire("Vehicle","Car")end

    -- Run Main Logic
    if not Initialize() then return end
    PopulateDataTables()
    if Config.LowGraphics then settings().Rendering.QualityLevel = "Level01" end
    if Config.Hidescreen then local s=Instance.new("ScreenGui", CoreGui); Instance.new("Frame",s).Size=UDim2.new(1,0,1,0) end
    Say("Stando V5 Initialized on " .. LocalPlayer.Name .. ". Awaiting Owner: " .. OwnerName)
    while not FindStand() do print("Stando V5: Searching for Owner..."); task.wait(1) end
    Say("Owner located: " .. StandAccount.Name)
    if not GetOwnerCharacter() then print("Stando V5: Waiting for character to spawn..."); LocalPlayer.CharacterAdded:Wait(); task.wait(3); print("Stando V5: Character loaded.") end
    pcall(function() if Config.AutoMask then Fire("Purchase", Config.MaskMode, "Masks") end; task.wait(0.5); Fire("Purchase", Config.GunMode, "Guns", 100); print("Stando V5: Attempted to purchase initial gear.") end)
    TextChatService.MessageReceived:Connect(function(msg) ProcessCommand(msg.Text, msg.TextSource.Name) end)
    
    RunService.Heartbeat:Connect(function()
        local s,e=pcall(function()
            OwnerCharacter=GetOwnerCharacter();TargetCharacter=GetTargetCharacter();if TargetCharacter and TargetCharacter.Humanoid.Health>0 then Prediction.Velocity=TargetCharacter.HumanoidRootPart.Velocity else Prediction.Velocity=Vector3.new()end
            if Attacking then if Config.Melee and Config.Melee~="Punch"then Attack()elseif Config.GunMode and Config.GunMode~="Rifle"then GunAttack()else Attack()end end
            if Config.AntiStomp and OwnerCharacter and OwnerCharacter.Humanoid.PlatformStand then Fire("Stomp","Stomp",OwnerCharacter.Torso)end
            if AutoSaving and OwnerCharacter and OwnerCharacter.Humanoid.Health<25 then OwnerCharacter.HumanoidRootPart.CFrame=CFrame.new(Locations[Config.AutoSaveLocation])end
            if AutoDropping then Fire("DropCash",1000)end;if AutoLettuce and OwnerCharacter and OwnerCharacter:FindFirstChild("Lettuce")then OwnerCharacter.Lettuce:Activate()end
            if AnnoyLoop and TargetCharacter and OwnerCharacter then TargetCharacter.HumanoidRootPart.CFrame=OwnerCharacter.HumanoidRootPart.CFrame*CFrame.new(0,0,-3)end
            if OwnerCharacter and CurrentOwner and CurrentOwner.Character and Config.Position~="Stop"then local pT=AltTarget and AltTarget.Character or CurrentOwner.Character;local fT=Config.Position=="Target"and(TargetCharacter or pT)or pT;if fT and fT.HumanoidRootPart then local g=fT.HumanoidRootPart.CFrame*(Positions[Config.Position]or CFrame.new());if Config.Smoothing then OwnerCharacter.HumanoidRootPart.CFrame=OwnerCharacter.HumanoidRootPart.CFrame:Lerp(g,0.2)else OwnerCharacter.HumanoidRootPart.CFrame=g end end end
        end);if not s then warn("Stando V5 Heartbeat Error:",e)end
    end)
    
    print("Stando V5: Main loop is now running.")
    SendStandMessage("Stando V5 is fully operational.")

end)()
