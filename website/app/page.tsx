import { HeroSection } from "@/components/sections/hero";
import { PlatformStrip } from "@/components/sections/platform-strip";
import { PhilosophySection } from "@/components/sections/philosophy";
import { ReaderExperienceSection } from "@/components/sections/reader-experience";
import { TechnicalShowcaseSection } from "@/components/sections/technical-showcase";
import { MermaidFeatureSection } from "@/components/sections/mermaid-feature";
import { ModesFeatureSection } from "@/components/sections/modes-feature";
import { NavigationPaletteSection } from "@/components/sections/navigation-palette";
import { ThemesFeatureSection } from "@/components/sections/themes-feature";
import { NativeMacSection } from "@/components/sections/native-mac";
import { DownloadCTASection } from "@/components/sections/download-cta";
import { FAQSection } from "@/components/sections/faq";

export default function HomePage() {
  return (
    <div className="flex flex-col">
      <HeroSection />
      <PlatformStrip />
      <PhilosophySection />
      <ReaderExperienceSection />
      <TechnicalShowcaseSection />
      <MermaidFeatureSection />
      <ModesFeatureSection />
      <NavigationPaletteSection />
      <ThemesFeatureSection />
      <NativeMacSection />
      <FAQSection />
      <DownloadCTASection />
    </div>
  );
}
