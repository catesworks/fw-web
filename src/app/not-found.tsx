import Link from 'next/link';
import styles from './status.module.css';

export default function NotFound() {
  return (
    <main className={styles.page}>
      <div className={styles.inner}>
        <h1 className={styles.headline}>Page not found</h1>
        <p className={styles.body}>The page you are looking for does not exist or has moved.</p>
        <Link href="/" className={styles.action}>
          Back to home
        </Link>
      </div>
    </main>
  );
}
