fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pure_appearance'
author 'ma3iich'
description 'Character creation, barber, tattoo parlor and plastic surgeon - drop-in replacement for illenium-appearance'
version '1.1.2'

provide 'illenium-appearance'
provide 'qb-clothing'
provide 'esx_skin'
provide 'skinchanger'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/data.lua',
    'shared/collections.lua',
    'shared/tattoos.lua',
}

client_scripts {
    'client/apply.lua',
    'client/convert.lua',
    'client/camera.lua',
    'client/menu.lua',
    'client/shops.lua',
    'client/compat.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/storage.lua',
    'server/main.lua',
    'server/version.lua',
}

ui_page 'web/index.html'

files {
    'locales/*.json',
    'web/index.html',
    'web/menu.css',
    'web/menu.js',
    'web/fonts/*.ttf',
    'web/*.png',
    'web/*.jpg',
    'web/*.svg',
    'web/**/*.webp',
}
