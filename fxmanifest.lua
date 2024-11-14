fx_version 'cerulean'
game 'gta5'

name 'y_core'
description 'The core resource for the Ybox Framework'
repository 'https://github.com/Ybox-project/y_core'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'modules/lib.lua',
    'shared/locale.lua',
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/loops.lua',
    'client/events.lua',
    'client/character.lua',
    'client/discord.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/motd.lua',
    'server/main.lua',
    'server/functions.lua',
    'server/player.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/loops.lua',
    'server/character.lua',
}

files {
    --TODO: load modules correctly (only client files)
    'modules/*.lua',
    'data/*.lua',
    'shared/gangs.lua',
    'shared/items.lua',
    'shared/jobs.lua',
    'shared/main.lua',
    'shared/vehicles.lua',
    'shared/weapons.lua',
    'config/client.lua',
    'config/shared.lua',
    'locales/*.json'
}

dependencies {
    '/server:7290',
    '/onesync',
    'ox_lib',
    'oxmysql',
}

provide 'qbx_core'
lua54 'yes'
use_experimental_fxv2_oal 'yes'