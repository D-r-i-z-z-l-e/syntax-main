import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { ConversationProvider } from '../components/providers/ConversationProvider';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Syntax - AI Software Architect',
  description: 'Your AI-powered software architect and implementation guide',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <ConversationProvider>{children}</ConversationProvider>
      </body>
    </html>
  );
}
