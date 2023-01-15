const { REST, Routes } = require('discord.js');
const { app_id, guild_id, bot_token } = require('./discordConfig.json');

const rest = new REST({ version: '10' }).setToken(bot_token);

// ...
const commandId = ""
// for guild-based commands
rest.delete(Routes.applicationGuildCommand(app_id, guild_id, commandId))
	.then(() => console.log('Successfully deleted guild command'))
	.catch(console.error);
