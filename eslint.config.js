
const js = require("@eslint/js");

module.exports = [
  {
    ignores: [
      "node_modules/**",
      "coverage/**",
      ".git/**"
    ]
  },
  js.configs.recommended,
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "commonjs",
      globals: {
        require: "readonly",
        module: "readonly",
        exports: "readonly",
        process: "readonly",
        __dirname: "readonly",
        console: "readonly",
        Buffer: "readonly",
        setTimeout: "readonly",
        clearTimeout: "readonly"
      }
    },
    rules: {
      "no-unused-vars": ["error", {
        argsIgnorePattern: "^_"
      }],
      "no-undef": "error"
    }
  }
];
