import { defineConfig } from "eslint/config";
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-plugin-prettier";
import prettierConfig from "eslint-config-prettier";
import { FlatCompat } from "@eslint/eslintrc";

const compat = new FlatCompat({
	baseDirectory: import.meta.dirname,
});

export default defineConfig([
	{
		ignores: ["out/", "generated/"],
	},

	eslint.configs.recommended,

	...tseslint.configs.recommended,

	{
		files: ["**/*.ts", "**/*.tsx"],
		languageOptions: {
			parser: tseslint.parser,
			parserOptions: {
				project: "./tsconfig.json",
				sourceType: "module",
				ecmaVersion: 2018,
				ecmaFeatures: {
					jsx: true,
				},
			},
		},
	},

	...compat.extends("plugin:roblox-ts/recommended-legacy"),

	prettierConfig,

	{
		plugins: {
			prettier,
		},
		rules: {
			"prettier/prettier": "error",
		},
	},
]);