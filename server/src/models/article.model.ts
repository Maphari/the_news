export interface Article {
  articleId: string;
  link: string;
  title: string;
  description: string;
  content: string;
  keywords?: string[];
  creator?: string[];
  language: string;
  country?: string[];
  category?: string[];
  datatype: string;
  pubDate: FirebaseFirestore.Timestamp | Date | string;
  pubDateTZ: string;
  imageUrl?: string | null;
  videoUrl?: string | null;
  sourceId: string;
  sourceName: string;
  sourcePriority: number;
  sourceUrl: string;
  sourceIcon?: string | null;
  sentiment?: string;
  sentimentStats?: {
    negative: number;
    neutral: number;
    positive: number;
  };
  aiTag?: string[];
  aiRegion?: string[];
  aiOrg?: string | null;
  aiSummary?: string;
  duplicate: boolean;
  createdAt?: FirebaseFirestore.Timestamp | Date | string;
  updatedAt?: FirebaseFirestore.Timestamp | Date | string;
}

export interface ArticleBatchRequest {
  articles: Article[];
}

export interface ArticleSaveResponse {
  success: boolean;
  message: string;
  savedCount: number;
  skippedCount: number;
  articles?: Article[];
}
