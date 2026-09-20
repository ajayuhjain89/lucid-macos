"use client";

import React, { useState } from "react";
import Image from "next/image";
import { Lightbox } from "./lightbox";

interface WindowFrameProps {
  src?: string;
  alt?: string;
  title?: string;
  caption?: string;
  width?: number;
  height?: number;
  priority?: boolean;
  allowExpand?: boolean;
  className?: string;
  mode?: string;
  children?: React.ReactNode;
}

export function WindowFrame({
  src,
  alt = "Lucid macOS Window",
  title = "Lucid",
  caption,
  width = 2080,
  height = 1560,
  priority = false,
  allowExpand = true,
  className = "",
  mode,
  children,
}: WindowFrameProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <figure className={`flex flex-col items-center w-full ${className}`}>
      <div
        className={`relative w-full rounded-window overflow-hidden border border-border-strong bg-surface shadow-window transition-all duration-200 ${
          allowExpand ? "cursor-zoom-in group" : ""
        }`}
        onClick={() => allowExpand && setIsExpanded(true)}
      >
        {/* Subtle macOS Traffic Lights Titlebar */}
        <div className="flex items-center justify-between px-3.5 py-2.5 bg-surface border-b border-border-subtle select-none">
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-[#ff5f56]/80 border border-[#e0443e]/50" />
            <span className="w-3 h-3 rounded-full bg-[#ffbd2e]/80 border border-[#dea123]/50" />
            <span className="w-3 h-3 rounded-full bg-[#27c93f]/80 border border-[#1aab29]/50" />
          </div>

          <div className="text-[11px] font-medium text-text-tertiary tracking-tight truncate max-w-[50%]">
            {title}
          </div>

          <div className="w-12 flex justify-end">
            {allowExpand && (
              <span className="text-[10px] text-text-tertiary opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" />
                </svg>
                Expand
              </span>
            )}
          </div>
        </div>

        {/* Window Content */}
        {children ? (
          <div className="relative w-full bg-surface overflow-hidden">
            {children}
          </div>
        ) : src ? (
          <div className="relative w-full aspect-[4/3] bg-surface">
            <Image
              src={src}
              alt={alt}
              width={width}
              height={height}
              priority={priority}
              className="w-full h-full object-cover object-top"
              sizes="(max-width: 768px) 100vw, (max-width: 1280px) 90vw, 1200px"
            />
          </div>
        ) : null}
      </div>

      {caption && (
        <figcaption className="mt-3 text-xs text-text-secondary text-center max-w-xl">
          {caption}
        </figcaption>
      )}

      {allowExpand && src && (
        <Lightbox
          isOpen={isExpanded}
          onClose={() => setIsExpanded(false)}
          src={src}
          alt={alt}
          caption={caption}
        />
      )}
    </figure>
  );
}
