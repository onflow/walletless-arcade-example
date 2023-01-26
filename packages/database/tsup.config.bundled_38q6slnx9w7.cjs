"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// tsup.config.js
var tsup_config_exports = {};
__export(tsup_config_exports, {
  default: () => tsup_config_default
});
module.exports = __toCommonJS(tsup_config_exports);
var import_tsup = require("tsup");
var isProduction = process.env.NODE_ENV === "production";
var tsup_config_default = (0, import_tsup.defineConfig)({
  clean: true,
  dts: true,
  entry: ["src/index.ts"],
  format: ["cjs", "esm"],
  minify: isProduction,
  sourcemap: true
});
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {});
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidHN1cC5jb25maWcuanMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9faW5qZWN0ZWRfZmlsZW5hbWVfXyA9IFwiL1VzZXJzL2dyZWdzYW50b3MvRGV2L0Zsb3cvZmxvdy1nYW1lcy93YWxsZXRsZXNzLWFyY2FkZS1leGFtcGxlL3BhY2thZ2VzL2RhdGFiYXNlL3RzdXAuY29uZmlnLmpzXCI7Y29uc3QgX19pbmplY3RlZF9kaXJuYW1lX18gPSBcIi9Vc2Vycy9ncmVnc2FudG9zL0Rldi9GbG93L2Zsb3ctZ2FtZXMvd2FsbGV0bGVzcy1hcmNhZGUtZXhhbXBsZS9wYWNrYWdlcy9kYXRhYmFzZVwiO2NvbnN0IF9faW5qZWN0ZWRfaW1wb3J0X21ldGFfdXJsX18gPSBcImZpbGU6Ly8vVXNlcnMvZ3JlZ3NhbnRvcy9EZXYvRmxvdy9mbG93LWdhbWVzL3dhbGxldGxlc3MtYXJjYWRlLWV4YW1wbGUvcGFja2FnZXMvZGF0YWJhc2UvdHN1cC5jb25maWcuanNcIjtpbXBvcnQge2RlZmluZUNvbmZpZ30gZnJvbSBcInRzdXBcIlxuXG5jb25zdCBpc1Byb2R1Y3Rpb24gPSBwcm9jZXNzLmVudi5OT0RFX0VOViA9PT0gXCJwcm9kdWN0aW9uXCJcblxuZXhwb3J0IGRlZmF1bHQgZGVmaW5lQ29uZmlnKHtcbiAgY2xlYW46IHRydWUsXG4gIGR0czogdHJ1ZSxcbiAgZW50cnk6IFtcInNyYy9pbmRleC50c1wiXSxcbiAgZm9ybWF0OiBbXCJjanNcIiwgXCJlc21cIl0sXG4gIG1pbmlmeTogaXNQcm9kdWN0aW9uLFxuICBzb3VyY2VtYXA6IHRydWUsXG59KVxuIl0sCiAgIm1hcHBpbmdzIjogIjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQWlZLGtCQUEyQjtBQUU1WixJQUFNLGVBQWUsUUFBUSxJQUFJLGFBQWE7QUFFOUMsSUFBTywwQkFBUSwwQkFBYTtBQUFBLEVBQzFCLE9BQU87QUFBQSxFQUNQLEtBQUs7QUFBQSxFQUNMLE9BQU8sQ0FBQyxjQUFjO0FBQUEsRUFDdEIsUUFBUSxDQUFDLE9BQU8sS0FBSztBQUFBLEVBQ3JCLFFBQVE7QUFBQSxFQUNSLFdBQVc7QUFDYixDQUFDOyIsCiAgIm5hbWVzIjogW10KfQo=
