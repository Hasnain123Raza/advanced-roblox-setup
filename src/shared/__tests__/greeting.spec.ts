import { describe, expect, it } from "@rbxts/jest-globals";

import { makeGreeting } from "shared/greeting";

describe("makeGreeting", () => {
	it("includes the name", () => {
		expect(makeGreeting("tests")).toBe("Hello from tests!");
	});
});
