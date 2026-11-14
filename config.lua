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

Config.Vehicles = {
    { label = 'Phantom (Tır)', model = 'phantom' },
    { label = 'Hauler (Tır)', model = 'hauler' },
    { label = 'Packer (Tır)', model = 'packer' },
    { label = 'Phantom Custom', model = 'phantom3' },
    { label = 'Mule (Kamyon)', model = 'mule' },
    { label = 'Pounder (Kamyon)', model = 'pounder' },
    { label = 'Benson (Kamyon)', model = 'benson' },
    { label = 'Boxville (Kasalı)', model = 'boxville2' },
    { label = 'Mixer (Beton)', model = 'mixer' },
    { label = 'Flatbed', model = 'flatbed' },
    { label = 'Forklift', model = 'forklift' },
    { label = 'Speedo (Van)', model = 'speedo' },
}

Config.Trailers = {
    { label = 'Kasalı dorse', model = 'trailers' },
    { label = 'Kasalı dorse 2', model = 'trailers2' },
    { label = 'Tanker', model = 'tanker' },
    { label = 'Araba taşıyıcı', model = 'tr2' },
    { label = 'Araba taşıyıcı (dolu)', model = 'tr4' },
    { label = 'Platform (flatbed)', model = 'trflat' },
    { label = 'Konteyner', model = 'docktrailer' },
    { label = 'Kütük', model = 'trailerlogs' },
}

Config.Peds = {
    { label = 'Tırcı', model = 's_m_m_trucker_01' },
    { label = 'İş adamı', model = 'a_m_y_business_02' },
    { label = 'İş adamı 2', model = 'a_m_m_business_01' },
    { label = 'İnşaat işçisi', model = 's_m_y_construct_01' },
    { label = 'Liman işçisi', model = 's_m_m_dockwork_01' },
    { label = 'Depo işçisi', model = 's_m_y_airworker' },
    { label = 'Ustabaşı', model = 's_m_m_gaffer_01' },
    { label = 'Çiftçi', model = 'a_m_m_farmer_01' },
}

Config.Props = {
    { label = 'Koli yığını', model = 'prop_boxpile_06b' },
    { label = 'Karton koli', model = 'prop_cs_cardbox_01' },
    { label = 'Tahta sandık', model = 'prop_mb_crate_01a' },
    { label = 'Palet', model = 'prop_pallet_01a' },
    { label = 'Trafik konisi', model = 'prop_roadcone02a' },
    { label = 'Yol bariyeri', model = 'prop_barrier_work05' },
    { label = 'Alet dolabı', model = 'prop_toolchest_05' },
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
    { label = 'Konuş (sohbet)', dict = 'missfbi3_party_d', clip = 'stand_talk_loop_a_male1', flag = 49, talk = true },
    { label = 'Tartış', dict = 'misscarsteal4@actor', clip = 'actor_berating_loop', flag = 49, talk = true },
    { label = 'Tartış 2', dict = 'oddjobs@assassinate@vice@hooker', clip = 'argue_a', flag = 49, talk = true },
    { label = 'Açıkla (el kol)', dict = 'gestures@m@standing@casual', clip = 'gesture_you_soft', flag = 49, talk = true },
    { label = 'Neden?', dict = 'gestures@m@standing@casual', clip = 'gesture_why', flag = 48, talk = true },
    { label = 'Sakin ol', dict = 'gestures@m@standing@casual', clip = 'gesture_easy_now', flag = 48, talk = true },
    { label = 'Olmaz', dict = 'gestures@m@standing@casual', clip = 'gesture_no_way', flag = 48, talk = true },
    { label = 'Buraya gel', dict = 'gestures@m@standing@casual', clip = 'gesture_come_here_soft', flag = 48 },
    { label = 'Selam ver', dict = 'gestures@m@standing@casual', clip = 'gesture_hello', flag = 48 },
    { label = 'Kutu taşı', dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49,
      prop = { model = 'hei_prop_heist_box', bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) } },
    { label = 'Tablet kullan', dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', clip = 'base', flag = 49,
      prop = { model = 'prop_cs_tablet', bone = 60309, pos = vec3(0.03, 0.002, -0.0), rot = vec3(10.0, 160.0, 0.0) } },
    { label = 'Pano ile not al', dict = 'missfam4', clip = 'base', flag = 49,
      prop = { model = 'p_amb_clipboard_01', bone = 36029, pos = vec3(0.16, 0.08, 0.1), rot = vec3(-130.0, -50.0, 0.0) } },
    { label = 'Telefonda mesaj', dict = 'cellphone@', clip = 'cellphone_text_read_base', flag = 49,
      prop = { model = 'prop_npc_phone_02', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) } },
    { label = 'Telefonla konuş', dict = 'cellphone@', clip = 'cellphone_call_listen_base', flag = 49,
      prop = { model = 'prop_npc_phone_02', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) } },
    { label = 'Telsizle konuş', dict = 'random@arrests', clip = 'generic_radio_chatter', flag = 49 },
    { label = 'Kollar bağlı', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', clip = 'base', flag = 49 },
    { label = 'Düşün', dict = 'misscarsteal4@aliens', clip = 'rehearsal_base_idle_director', flag = 49 },
    { label = 'İşaret et', dict = 'gestures@m@standing@casual', clip = 'gesture_point', flag = 48 },
    { label = 'Omuz silk', dict = 'gestures@m@standing@casual', clip = 'gesture_shrug_hard', flag = 48 },
    { label = 'El salla', dict = 'friends@frj@ig_1', clip = 'wave_a', flag = 49 },
    { label = 'Facepalm', dict = 'anim@mp_player_intcelebrationmale@face_palm', clip = 'face_palm', flag = 48 },
    { label = 'Sevin', dict = 'amb@world_human_cheering@male_a', clip = 'base', flag = 1 },
}

Config.Scenarios = {
    { label = 'Pano tut', name = 'WORLD_HUMAN_CLIPBOARD' },
    { label = 'Telefonla oyalan', name = 'WORLD_HUMAN_STAND_MOBILE' },
    { label = 'Duvara yaslan', name = 'WORLD_HUMAN_LEANING' },
    { label = 'Kahve iç', name = 'WORLD_HUMAN_AA_COFFEE' },
    { label = 'Sabırsız bekle', name = 'WORLD_HUMAN_STAND_IMPATIENT' },
    { label = 'Güvenlik gibi dur', name = 'WORLD_HUMAN_GUARD_STAND' },
    { label = 'Çekiçle çalış', name = 'WORLD_HUMAN_HAMMERING' },
    { label = 'Matkapla çalış', name = 'WORLD_HUMAN_CONST_DRILL' },
    { label = 'Kaynak yap', name = 'WORLD_HUMAN_WELDING' },
    { label = 'Sigara iç', name = 'WORLD_HUMAN_SMOKING' },
    { label = 'Tezahürat', name = 'WORLD_HUMAN_CHEERING' },
}

Config.Weathers = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'CLEARING', 'RAIN', 'THUNDER', 'FOGGY', 'SMOG', 'XMAS' }
