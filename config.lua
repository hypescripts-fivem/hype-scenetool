Config = {}

Config.Command = 'scene'            -- /scene opens the menu
Config.Keybind = 'F7'               -- default key (players can rebind it), false = command only
Config.Ace = 'hypescene.use'        -- ace needed to use the tool, false = everyone
Config.Plate = 'HYPE'               -- plate text of spawned vehicles
Config.SpawnDistance = 6.0          -- spawn distance when you are not looking at the ground

Config.Editor = {
    moveStep = 0.03,                -- meters per frame
    rotateStep = 0.75,              -- degrees per frame
    fastMultiplier = 5.0,           -- Shift
    slowMultiplier = 0.15,          -- Ctrl
}

Config.TimeStop = {
    radius = 150.0,                 -- meters around you that freeze
    key = '',                       -- quick toggle key while filming, '' = unbound (bind it in FiveM settings)
}

Config.Drive = {
    speed = 15.0,                   -- m/s (about 54 km/h)
    style = 786603,                 -- normal, obeys traffic
}

-- label: a key from locales/*.json (shown in the player's language) or plain text
Config.Vehicles = {
    { label = 'preset.vehicle.phantom', model = 'phantom' },
    { label = 'preset.vehicle.hauler', model = 'hauler' },
    { label = 'preset.vehicle.packer', model = 'packer' },
    { label = 'preset.vehicle.phantom3', model = 'phantom3' },
    { label = 'preset.vehicle.mule', model = 'mule' },
    { label = 'preset.vehicle.pounder', model = 'pounder' },
    { label = 'preset.vehicle.benson', model = 'benson' },
    { label = 'preset.vehicle.boxville', model = 'boxville2' },
    { label = 'preset.vehicle.mixer', model = 'mixer' },
    { label = 'preset.vehicle.flatbed', model = 'flatbed' },
    { label = 'preset.vehicle.forklift', model = 'forklift' },
    { label = 'preset.vehicle.speedo', model = 'speedo' },
}

Config.Trailers = {
    { label = 'preset.trailer.box', model = 'trailers' },
    { label = 'preset.trailer.box2', model = 'trailers2' },
    { label = 'preset.trailer.tanker', model = 'tanker' },
    { label = 'preset.trailer.car_carrier', model = 'tr2' },
    { label = 'preset.trailer.car_carrier_full', model = 'tr4' },
    { label = 'preset.trailer.flatbed', model = 'trflat' },
    { label = 'preset.trailer.container', model = 'docktrailer' },
    { label = 'preset.trailer.logs', model = 'trailerlogs' },
}

Config.Peds = {
    { label = 'preset.ped.trucker', model = 's_m_m_trucker_01' },
    { label = 'preset.ped.business', model = 'a_m_y_business_02' },
    { label = 'preset.ped.business2', model = 'a_m_m_business_01' },
    { label = 'preset.ped.construction', model = 's_m_y_construct_01' },
    { label = 'preset.ped.dockworker', model = 's_m_m_dockwork_01' },
    { label = 'preset.ped.warehouse', model = 's_m_y_airworker' },
    { label = 'preset.ped.foreman', model = 's_m_m_gaffer_01' },
    { label = 'preset.ped.farmer', model = 'a_m_m_farmer_01' },
}

Config.Props = {
    { label = 'preset.prop.box_pile', model = 'prop_boxpile_06b' },
    { label = 'preset.prop.cardboard_box', model = 'prop_cs_cardbox_01' },
    { label = 'preset.prop.wooden_crate', model = 'prop_mb_crate_01a' },
    { label = 'preset.prop.pallet', model = 'prop_pallet_01a' },
    { label = 'preset.prop.traffic_cone', model = 'prop_roadcone02a' },
    { label = 'preset.prop.road_barrier', model = 'prop_barrier_work05' },
    { label = 'preset.prop.tool_chest', model = 'prop_toolchest_05' },
}

-- Talking: while you speak in voice chat your character gestures and its lips move.
Config.Talk = {
    command = 'konusma',            -- toggles the gestures for yourself, no permission needed
    lipSyncDistance = 30.0,         -- lips of talking players within this range move
    gestureDict = 'gestures@m@standing@casual',
    gestures = {
        'gesture_hand_down', 'gesture_why', 'gesture_you_soft', 'gesture_easy_now', 'gesture_me',
        'gesture_hello', 'gesture_no_way', 'gesture_pleased', 'gesture_i_will', 'gesture_shrug_hard',
    },
    pause = { 200, 900 },           -- random pause between two gestures (ms)
}

-- flag: 0 once, 1 loop, 2 freeze on last frame, 48 once upper body, 49 loop upper body (can walk)
-- talk = true: the lips move while the animation plays
Config.Animations = {
    { label = 'preset.anim.chat', dict = 'missfbi3_party_d', clip = 'stand_talk_loop_a_male1', flag = 49, talk = true },
    { label = 'preset.anim.argue', dict = 'misscarsteal4@actor', clip = 'actor_berating_loop', flag = 49, talk = true },
    { label = 'preset.anim.argue2', dict = 'oddjobs@assassinate@vice@hooker', clip = 'argue_a', flag = 49, talk = true },
    { label = 'preset.anim.explain', dict = 'gestures@m@standing@casual', clip = 'gesture_you_soft', flag = 49, talk = true },
    { label = 'preset.anim.why', dict = 'gestures@m@standing@casual', clip = 'gesture_why', flag = 48, talk = true },
    { label = 'preset.anim.easy', dict = 'gestures@m@standing@casual', clip = 'gesture_easy_now', flag = 48, talk = true },
    { label = 'preset.anim.no_way', dict = 'gestures@m@standing@casual', clip = 'gesture_no_way', flag = 48, talk = true },
    { label = 'preset.anim.come_here', dict = 'gestures@m@standing@casual', clip = 'gesture_come_here_soft', flag = 48 },
    { label = 'preset.anim.hello', dict = 'gestures@m@standing@casual', clip = 'gesture_hello', flag = 48 },
    { label = 'preset.anim.carry_box', dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49,
      prop = { model = 'hei_prop_heist_box', bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) } },
    { label = 'preset.anim.tablet', dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', clip = 'base', flag = 49,
      prop = { model = 'prop_cs_tablet', bone = 60309, pos = vec3(0.03, 0.002, -0.0), rot = vec3(10.0, 160.0, 0.0) } },
    { label = 'preset.anim.clipboard', dict = 'missfam4', clip = 'base', flag = 49,
      prop = { model = 'p_amb_clipboard_01', bone = 36029, pos = vec3(0.16, 0.08, 0.1), rot = vec3(-130.0, -50.0, 0.0) } },
    { label = 'preset.anim.phone_text', dict = 'cellphone@', clip = 'cellphone_text_read_base', flag = 49,
      prop = { model = 'prop_npc_phone_02', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) } },
    { label = 'preset.anim.phone_call', dict = 'cellphone@', clip = 'cellphone_call_listen_base', flag = 49,
      prop = { model = 'prop_npc_phone_02', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) } },
    { label = 'preset.anim.radio', dict = 'random@arrests', clip = 'generic_radio_chatter', flag = 49 },
    { label = 'preset.anim.arms_crossed', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', clip = 'base', flag = 49 },
    { label = 'preset.anim.think', dict = 'misscarsteal4@aliens', clip = 'rehearsal_base_idle_director', flag = 49 },
    { label = 'preset.anim.point', dict = 'gestures@m@standing@casual', clip = 'gesture_point', flag = 48 },
    { label = 'preset.anim.shrug', dict = 'gestures@m@standing@casual', clip = 'gesture_shrug_hard', flag = 48 },
    { label = 'preset.anim.wave', dict = 'friends@frj@ig_1', clip = 'wave_a', flag = 49 },
    { label = 'preset.anim.facepalm', dict = 'anim@mp_player_intcelebrationmale@face_palm', clip = 'face_palm', flag = 48 },
    { label = 'preset.anim.cheer', dict = 'amb@world_human_cheering@male_a', clip = 'base', flag = 1 },
}

Config.Scenarios = {
    { label = 'preset.scenario.clipboard', name = 'WORLD_HUMAN_CLIPBOARD' },
    { label = 'preset.scenario.phone', name = 'WORLD_HUMAN_STAND_MOBILE' },
    { label = 'preset.scenario.lean', name = 'WORLD_HUMAN_LEANING' },
    { label = 'preset.scenario.coffee', name = 'WORLD_HUMAN_AA_COFFEE' },
    { label = 'preset.scenario.impatient', name = 'WORLD_HUMAN_STAND_IMPATIENT' },
    { label = 'preset.scenario.guard', name = 'WORLD_HUMAN_GUARD_STAND' },
    { label = 'preset.scenario.hammer', name = 'WORLD_HUMAN_HAMMERING' },
    { label = 'preset.scenario.drill', name = 'WORLD_HUMAN_CONST_DRILL' },
    { label = 'preset.scenario.weld', name = 'WORLD_HUMAN_WELDING' },
    { label = 'preset.scenario.smoke', name = 'WORLD_HUMAN_SMOKING' },
    { label = 'preset.scenario.cheer', name = 'WORLD_HUMAN_CHEERING' },
}

Config.Weathers = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'CLEARING', 'RAIN', 'THUNDER', 'FOGGY', 'SMOG', 'XMAS' }
