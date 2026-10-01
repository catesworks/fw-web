'use client';

// Replaces the root layout when it throws, so it must render its own <html>/<body>.
// Inline styles only: the layout's stylesheets are not guaranteed to load here.
export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="en">
      <body style={{ fontFamily: 'system-ui, sans-serif', margin: 0, padding: '64px 24px' }}>
        <div role="alert" style={{ maxWidth: 720, margin: '0 auto' }}>
          <h1>Something went wrong</h1>
          <p>An unexpected error occurred. Please try again.</p>
          <button type="button" onClick={reset}>
            Try again
          </button>
        </div>
      </body>
    </html>
  );
}
