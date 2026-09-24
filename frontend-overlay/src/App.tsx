import { useEffect, useState } from "react";

export default function App() {
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/hello")
      .then((res) => {
        if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
        return res.json();
      })
      .then((data: { message: string }) => setMessage(data.message))
      .catch((err: Error) => setError(err.message));
  }, []);

  return (
    <main>
      <h1>fullstack-template</h1>
      {error && <p role="alert">Failed to reach backend: {error}</p>}
      {!error && <p>{message ?? "Loading..."}</p>}
    </main>
  );
}
