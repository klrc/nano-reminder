#!/usr/bin/env node
const { spawn } = require("node:child_process");
const path = require("node:path");
const readline = require("node:readline");

const repoRoot = path.resolve(__dirname, "..");
const nanoReminder = path.join(repoRoot, "bin", "nano-reminder");

function respond(id, result) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", id, result })}\n`);
}

function reject(id, code, message) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", id, error: { code, message } })}\n`);
}

function runNano(args) {
  return new Promise((resolve, rejectPromise) => {
    const child = spawn(nanoReminder, args, {
      cwd: repoRoot,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    child.stdout.on("data", chunk => { stdout += chunk; });
    child.stderr.on("data", chunk => { stderr += chunk; });
    child.on("error", rejectPromise);
    child.on("close", code => {
      if (code === 0) {
        resolve(stdout.trim());
      } else {
        rejectPromise(new Error((stderr || stdout || `nano-reminder exited with ${code}`).trim()));
      }
    });
  });
}

const tools = [
  {
    name: "notify_now",
    description: "Show a Nano Reminder popup window immediately. Use this when the user asks to be notified after you finish a task.",
    inputSchema: {
      type: "object",
      properties: {
        text: {
          type: "string",
          description: "The reminder text to show in the popup window.",
        },
        shake: {
          type: "boolean",
          description: "Set true to briefly shake the popup for extra emphasis.",
        },
        mood: {
          type: "string",
          enum: ["calm", "happy", "grateful", "confused", "panic", "shocked"],
          description: "Optional Nano expression avatar mood.",
        },
      },
      required: ["text"],
      additionalProperties: false,
    },
  },
  {
    name: "schedule_reminder",
    description: "Create a one-time Nano Reminder popup for a future ISO-8601 timestamp.",
    inputSchema: {
      type: "object",
      properties: {
        at: {
          type: "string",
          description: "ISO-8601 time, for example 2026-04-28T18:00:00+08:00.",
        },
        text: {
          type: "string",
          description: "The reminder text to show when the reminder is due.",
        },
        shake: {
          type: "boolean",
          description: "Set true to briefly shake the popup when the reminder appears.",
        },
        mood: {
          type: "string",
          enum: ["calm", "happy", "grateful", "confused", "panic", "shocked"],
          description: "Optional Nano expression avatar mood.",
        },
      },
      required: ["at", "text"],
      additionalProperties: false,
    },
  },
];

async function handle(message) {
  if (!message || typeof message !== "object") return;
  const { id, method, params } = message;

  try {
    switch (method) {
    case "initialize":
      respond(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "nano-reminder", version: "0.1.0" },
      });
      break;
    case "notifications/initialized":
      break;
    case "tools/list":
      respond(id, { tools });
      break;
    case "tools/call": {
      const name = params?.name;
      const args = params?.arguments || {};
      if (name === "notify_now") {
        const nanoArgs = ["show", "--text", String(args.text || "")];
        if (args.shake === true) nanoArgs.push("--shake");
        if (typeof args.mood === "string" && args.mood) nanoArgs.push("--mood", args.mood);
        const output = await runNano(nanoArgs);
        respond(id, { content: [{ type: "text", text: output || "Notification shown." }] });
      } else if (name === "schedule_reminder") {
        const nanoArgs = ["add", "--at", String(args.at || ""), "--text", String(args.text || "")];
        if (args.shake === true) nanoArgs.push("--shake");
        if (typeof args.mood === "string" && args.mood) nanoArgs.push("--mood", args.mood);
        const output = await runNano(nanoArgs);
        respond(id, { content: [{ type: "text", text: output }] });
      } else {
        reject(id, -32601, `Unknown tool: ${name}`);
      }
      break;
    }
    default:
      if (id !== undefined) reject(id, -32601, `Unknown method: ${method}`);
    }
  } catch (error) {
    reject(id, -32000, error.message || String(error));
  }
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on("line", line => {
  if (!line.trim()) return;
  try {
    handle(JSON.parse(line));
  } catch (error) {
    reject(null, -32700, error.message || String(error));
  }
});
