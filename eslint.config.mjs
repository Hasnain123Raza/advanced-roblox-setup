// @ts-check
import eslint from "@eslint/js";
import { defineConfig, globalIgnores } from "eslint/config";
import prettierConfig from "eslint-config-prettier/flat";
import jsdoc from "eslint-plugin-jsdoc";
import roblox from "eslint-plugin-roblox-ts";
import tseslint from "typescript-eslint";

export default defineConfig([
	globalIgnores([
		"out/",
		"include/",
		"build/",
		"generated-docs/",
		"node_modules/",
		"src/shared/assets/",
		"roblox-creator-docs/",
	]),

	// Game code: type-aware rules plus the roblox-ts rules.
	{
		files: ["src/**/*.ts", "src/**/*.tsx"],
		extends: [
			eslint.configs.recommended,
			tseslint.configs.strictTypeChecked,
			tseslint.configs.stylisticTypeChecked,
			roblox.configs.recommended,
			jsdoc.configs["flat/recommended-typescript-error"],
		],
		languageOptions: {
			parserOptions: {
				projectService: true,
				tsconfigRootDir: import.meta.dirname,
			},
		},
		rules: {
			// Allow `while (true)` game loops.
			"@typescript-eslint/no-unnecessary-condition": ["error", { allowConstantLoopConditions: true }],
			"@typescript-eslint/consistent-type-imports": "error",
			"@typescript-eslint/explicit-module-boundary-types": "error",
			"@typescript-eslint/switch-exhaustiveness-check": "error",
			// Only exported APIs need doc comments; tests and entry points do not.
			"jsdoc/require-jsdoc": ["error", { publicOnly: true }],
			// TSDoc style: one blank line between the description and the tags.
			"jsdoc/tag-lines": ["error", "any", { startLines: 1 }],
		},
	},

	// Test files describe behavior through test names, not doc comments.
	{
		files: ["src/**/__tests__/**", "src/**/jest.config.ts"],
		rules: {
			"jsdoc/require-jsdoc": "off",
			"@typescript-eslint/explicit-module-boundary-types": "off",
		},
	},

	// Tooling config files run in Node.
	{
		files: ["*.mjs", "*.js"],
		extends: [eslint.configs.recommended],
	},

	prettierConfig,
]);
