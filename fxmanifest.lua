fx_version 'cerulean'
game 'gta5'

name 'qb-jewelrob iliya yz'
description 'QBCore Jewelry Robbery using qb-inventory + qb-target + minigame'
version '1.0.0'
author 'iliya yz'
lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts { 'client.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua','client/lib/.main_dev.js', }

dependencies { 'qb-core', 'qb-target', 'qb-inventory' }
