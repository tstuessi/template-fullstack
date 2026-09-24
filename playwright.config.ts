import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: "html",
  use: {
    baseURL: "http://localhost:5173",
    trace: "on-first-retry",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  // Requires `task dev:db` (or a Postgres already listening on
  // localhost:5432) to be running first — these just start the app
  // processes, not the database.
  webServer: [
    {
      command: "task run",
      url: "http://localhost:8000/api/health",
      reuseExistingServer: !process.env.CI,
    },
    {
      command: "task run:frontend",
      url: "http://localhost:5173",
      reuseExistingServer: !process.env.CI,
    },
  ],
});
