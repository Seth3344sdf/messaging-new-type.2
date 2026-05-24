import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Messaging — AI-native, privacy-first team chat',
  description:
    'A quieter place for teams to talk. Fast, encrypted in transit, with an AI that quietly turns your conversations into shared knowledge.',
  openGraph: {
    title: 'Messaging — AI-native, privacy-first team chat',
    description:
      'A quieter place for teams to talk. Encrypted in transit, with an AI that turns conversations into knowledge.',
    type: 'website',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
