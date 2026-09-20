import type { Metadata } from "next";
import { siteConfig } from "@/lib/site-config";
import { Navbar } from "@/components/layout/navbar";
import { Footer } from "@/components/layout/footer";
import "@/styles/globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.siteUrl),
  title: {
    default: `${siteConfig.name} — ${siteConfig.tagline}`,
    template: `%s | ${siteConfig.name}`,
  },
  description: siteConfig.description,
  keywords: [
    "macOS markdown reader",
    "technical markdown editor",
    "KaTeX mac",
    "Mermaid diagrams mac",
    "mhchem chemistry markdown",
    "native mac markdown viewer",
    "Apple silicon markdown",
    "local-first markdown",
  ],
  authors: [{ name: siteConfig.author.name, url: siteConfig.author.url }],
  creator: siteConfig.author.name,
  openGraph: {
    type: "website",
    locale: "en_US",
    url: siteConfig.siteUrl,
    title: `${siteConfig.name} — ${siteConfig.tagline}`,
    description: siteConfig.description,
    siteName: siteConfig.name,
    images: [
      {
        url: "/images/app/reader-dark.png",
        width: 1200,
        height: 630,
        alt: "Lucid macOS Technical Markdown Reader",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: `${siteConfig.name} — ${siteConfig.tagline}`,
    description: siteConfig.description,
    images: ["/images/app/reader-dark.png"],
  },
  icons: {
    icon: [
      { url: "/images/app/favicon.png", sizes: "32x32", type: "image/png" },
      { url: "/images/app/icon.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [
      { url: "/images/app/apple-touch-icon.png", sizes: "180x180", type: "image/png" },
    ],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        {/* Anti-flash inline script to apply dark/light theme before paint */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  var params = new URLSearchParams(window.location.search);
                  var queryTheme = params.get('theme');
                  var saved = localStorage.getItem('lucid-theme');
                  var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                  
                  if (queryTheme === 'light') {
                    document.documentElement.classList.remove('dark');
                  } else if (queryTheme === 'dark') {
                    document.documentElement.classList.add('dark');
                  } else if (saved === 'dark' || (!saved && prefersDark)) {
                    document.documentElement.classList.add('dark');
                  } else {
                    document.documentElement.classList.remove('dark');
                  }
                } catch (e) {}
              })();
            `,
          }}
        />
      </head>
      <body className="min-h-screen flex flex-col bg-background text-text-primary antialiased selection:bg-accent-soft selection:text-text-primary">
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-surface focus:border focus:border-border-strong focus:rounded-md focus:shadow-md text-sm font-medium text-text-primary"
        >
          Skip to main content
        </a>
        <Navbar />
        <main id="main-content" className="flex-1">
          {children}
        </main>
        <Footer />
      </body>
    </html>
  );
}
