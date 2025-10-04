import fs from "fs";
import path from "path";

interface CardImageMap {
  [cardName: string]: string;
}

export class CardImageLoader {
  private imageMap: CardImageMap = {};
  private assetsPath: string;

  constructor() {
    this.assetsPath = path.resolve(process.cwd(), "attached_assets", "cards");
    this.ensureDirectoryExists();
    this.scanImages();
  }

  private ensureDirectoryExists() {
    if (!fs.existsSync(this.assetsPath)) {
      fs.mkdirSync(this.assetsPath, { recursive: true });
      console.log(`Created card images directory: ${this.assetsPath}`);
    }
  }

  private scanImages() {
    try {
      const files = fs.readdirSync(this.assetsPath);
      const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

      files.forEach(file => {
        const ext = path.extname(file).toLowerCase();
        if (imageExtensions.includes(ext)) {
          const cardName = path.basename(file, ext)
            .replace(/-/g, ' ')
            .replace(/_/g, ' ');
          
          this.imageMap[cardName.toLowerCase()] = `/assets/cards/${file}`;
          console.log(`Loaded image for: ${cardName}`);
        }
      });

      console.log(`Loaded ${Object.keys(this.imageMap).length} card images`);
    } catch (error) {
      console.error("Error scanning card images:", error);
    }
  }

  getImageUrl(cardName: string): string {
    const normalized = cardName.toLowerCase();
    return this.imageMap[normalized] || this.getPlaceholder(cardName);
  }

  private getPlaceholder(cardName: string): string {
    const seed = cardName.replace(/\s+/g, '-').toLowerCase();
    return `https://api.dicebear.com/7.x/shapes/svg?seed=${seed}&backgroundColor=1e293b`;
  }

  refresh() {
    this.imageMap = {};
    this.scanImages();
  }
}

export const cardImageLoader = new CardImageLoader();