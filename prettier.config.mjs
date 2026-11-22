/** @type {import("prettier").Config} */
export default {
	printWidth: 120,
	useTabs: true,
	tabWidth: 4,
	trailingComma: "all",
	overrides: [
		{
			files: ["*.yaml", "*.yml", "*.md"],
			options: { useTabs: false, tabWidth: 2 },
		},
	],
};
