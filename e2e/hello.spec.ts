import { expect, test } from "@playwright/test";

test("home page shows the backend's greeting", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByText("Hello from FastAPI")).toBeVisible();
});
