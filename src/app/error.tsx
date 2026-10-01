'use client';

import styles from './status.module.css';

// Segment-level boundary: renders inside the root layout (header/footer stay).
export default function Error({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className={styles.page}>
      <div role="alert" className={styles.inner}>
        <h1 className={styles.headline}>Something went wrong</h1>
        <p className={styles.body}>An unexpected error occurred. Please try again.</p>
        <button type="button" className={styles.action} onClick={reset}>
          Try again
        </button>
      </div>
    </main>
  );
}
