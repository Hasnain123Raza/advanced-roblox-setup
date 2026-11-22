import { Players } from "@rbxts/services";

import { makeGreeting } from "shared/greeting";

print(makeGreeting("main.server.ts"));

Players.PlayerAdded.Connect((player) => {
	print(makeGreeting(player.Name));
});
