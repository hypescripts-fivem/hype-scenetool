fx_version 'cerulean'
game 'gta5'

author 'vezironi'
description 'Hype Scene Tool: spawn and pose vehicles, NPCs and props for filming trailers and TikTok videos.'
version '1.0.0'

dependencies {
    'ox_lib',
}

-- language: set `setr ox:locale "en"` (tr, en, de, es, fr ...) in server.cfg, falls back to English
ox_lib 'locale'

files {
    'locales/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/spawn.lua',
    'client/anim.lua',
    'client/editor.lua',
    'client/talk.lua',
    'client/cinema.lua',
    'client/scenes.lua',
    'client/menus.lua',
}

server_scripts {
    'server/main.lua',
}

lua54 'yes'
