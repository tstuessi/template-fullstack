import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import App from "./App";

describe("App", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ message: "Hello from FastAPI" }),
        } as Response),
      ),
    );
  });

  it("renders the backend's greeting once the fetch resolves", async () => {
    render(<App />);
    expect(await screen.findByText("Hello from FastAPI")).toBeInTheDocument();
  });
});
