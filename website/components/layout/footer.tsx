import React from "react";
import Link from "next/link";
import Image from "next/image";
import { siteConfig } from "@/lib/site-config";
import { currentRelease } from "@/lib/release";

export function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="w-full border-t border-border-subtle bg-surface/50 mt-24">
      <div className="max-w-page mx-auto px-4 sm:px-6 py-12">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-8 mb-12">
          {/* Brand block */}
          <div className="col-span-2 space-y-3">
            <Link href="/" className="flex items-center gap-2">
              <div className="relative w-5 h-5 rounded-[4px] overflow-hidden">
                <Image
                  src="/images/app/icon.png"
                  alt="Lucid"
                  width={40}
                  height={40}
                  className="w-full h-full object-cover"
                />
              </div>
              <span className="font-semibold text-sm tracking-tight text-text-primary">
                Lucid
              </span>
            </Link>
            <p className="text-xs text-text-secondary max-w-sm leading-relaxed">
              A quiet, native macOS Markdown reader and editor built for technical documents — equations, chemistry, diagrams, code, and tables.
            </p>
            <div className="pt-1 flex items-center gap-2 text-[11px] text-text-tertiary font-mono">
              <span>macOS {currentRelease.minimumMacOS}+</span>
              <span>•</span>
              <span>Apple Silicon</span>
              <span>•</span>
              <a
                href={siteConfig.license.url}
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-text-primary transition-colors underline underline-offset-2"
              >
                {siteConfig.license.name}
              </a>
            </div>
          </div>

          {/* Product links */}
          <div className="space-y-2.5">
            <h4 className="text-[11px] font-semibold uppercase tracking-wider text-text-tertiary font-mono">
              Product
            </h4>
            <ul className="space-y-1.5 text-xs text-text-secondary">
              {siteConfig.footerLinks.product.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="hover:text-text-primary transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Resources links */}
          <div className="space-y-2.5">
            <h4 className="text-[11px] font-semibold uppercase tracking-wider text-text-tertiary font-mono">
              Resources
            </h4>
            <ul className="space-y-1.5 text-xs text-text-secondary">
              {siteConfig.footerLinks.resources.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="hover:text-text-primary transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal & Open Source */}
          <div className="space-y-2.5">
            <h4 className="text-[11px] font-semibold uppercase tracking-wider text-text-tertiary font-mono">
              Project
            </h4>
            <ul className="space-y-1.5 text-xs text-text-secondary">
              {siteConfig.footerLinks.legal.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="hover:text-text-primary transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
              <li>
                <a
                  href={siteConfig.githubUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-text-primary transition-colors inline-flex items-center gap-1"
                >
                  <span>GitHub</span>
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                    <polyline points="15 3 21 3 21 9" />
                    <line x1="10" y1="14" x2="21" y2="3" />
                  </svg>
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-8 border-t border-border-subtle flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-text-tertiary">
          <p>© {currentYear} {siteConfig.author.name}. Released under the {siteConfig.license.name}.</p>
          <p className="text-[11px]">
            Designed for native macOS. Built with Swift, AppKit, WebKit, and Next.js.
          </p>
        </div>
      </div>
    </footer>
  );
}
