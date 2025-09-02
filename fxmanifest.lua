fx_version 'adamant'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'Carrier Pigeon Messaging System'
author 'OuroDev'

ui_page 'nui/index.html'

files {
  'nui/index.html',
  'nui/style.css',
  'nui/script.js'
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  'config.lua',
  'server.lua'
}

client_scripts {
  'client.lua'
}
