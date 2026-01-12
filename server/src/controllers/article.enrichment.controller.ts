import { Request, Response } from "express";
import axios from "axios";
import { load } from "cheerio";

/**
 * Enrich an article by scraping its source URL
 * POST /api/v1/articles/enrich
 * Body: { articleId: string, sourceUrl: string }
 */
export const enrichArticle = async (req: Request, res: Response) => {
  try {
    const { articleId, sourceUrl } = req.body;

    if (!articleId || !sourceUrl) {
      return res.status(400).json({
        success: false,
        message: "articleId and sourceUrl are required",
      });
    }

    console.log(`📥 Enriching article: ${articleId} from ${sourceUrl}`);

    // Fetch the article page
    const response = await axios.get(sourceUrl, {
      timeout: 20000,
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
      },
    });

    const html = response.data as string;
    const $ = load(html);

    // Remove unwanted elements
    $("script, style, nav, header, footer, aside, .advertisement, .ads, .social-share, .related-articles, .comments").remove();

    // Find the main content container
    const contentSelectors = [
      "article",
      '[role="article"]',
      ".article-content",
      ".post-content",
      ".entry-content",
      ".content",
      "main",
    ];

    let contentElement = null;
    for (const selector of contentSelectors) {
      const element = $(selector).first();
      if (element.length > 0 && element.text().trim().length > 500) {
        contentElement = element;
        break;
      }
    }

    // Fallback to body if no specific content container found
    if (!contentElement) {
      contentElement = $("body");
    }

    // Extract structured content with formatting preserved
    interface ContentBlock {
      type: "heading" | "subheading" | "paragraph" | "image";
      content: string;
      level?: number;
      alt?: string;
      caption?: string;
    }

    const structuredContent: ContentBlock[] = [];
    let fullText = "";

    // Process each element in the content in document order
    contentElement.find("h1, h2, h3, h4, h5, h6, p, img, figure").each((_, el) => {
      const tagName = el.tagName.toLowerCase();
      const $el = $(el);

      if (tagName.match(/^h[1-6]$/)) {
        // Heading
        const text = $el.text().trim();
        if (text.length > 0 && text.length < 200) {
          const level = parseInt(tagName[1]);
          structuredContent.push({
            type: level === 1 ? "heading" : "subheading",
            content: text,
            level,
          });
          fullText += text + "\n\n";
        }
      } else if (tagName === "p") {
        // Paragraph
        const text = $el.text().trim();
        if (text.length > 30) {
          // Filter out very short paragraphs
          structuredContent.push({
            type: "paragraph",
            content: text,
          });
          fullText += text + "\n\n";
        }
      } else if (tagName === "img" || tagName === "figure") {
        // Image (handle both <img> and <figure><img></figure>)
        const $img = tagName === "figure" ? $el.find("img").first() : $el;
        const src = $img.attr("src") || $img.attr("data-src");

        if (src && !src.includes("data:image") && !src.includes("icon") && !src.includes("logo") && !src.includes("avatar")) {
          const absoluteUrl = src.startsWith("http") ? src : new URL(src, sourceUrl).href;
          const alt = $img.attr("alt") || "";
          const caption = tagName === "figure"
            ? $el.find("figcaption").text().trim()
            : ($img.attr("title") || "");

          structuredContent.push({
            type: "image",
            content: absoluteUrl,
            alt,
            caption,
          });
        }
      }
    });

    // Extract standalone images (for backward compatibility)
    const images: string[] = [];
    structuredContent
      .filter(item => item.type === "image")
      .forEach(item => images.push(item.content));

    // Extract videos
    const videos: string[] = [];
    $("article video, main video, iframe[src*='youtube'], iframe[src*='vimeo']").each((_, el) => {
      const src = $(el).attr("src");
      if (src) {
        const absoluteUrl = src.startsWith("http") ? src : new URL(src, sourceUrl).href;
        videos.push(absoluteUrl);
      }
    });

    // Extract author
    let author = "";
    const authorSelectors = [
      '[rel="author"]',
      ".author-name",
      ".byline",
      '[itemprop="author"]',
      ".post-author",
    ];

    for (const selector of authorSelectors) {
      const element = $(selector).first();
      if (element.length > 0) {
        author = element.text().trim();
        if (author) break;
      }
    }

    // Extract publish date
    let publishDate = "";
    const dateSelectors = [
      "time",
      '[itemprop="datePublished"]',
      ".publish-date",
      ".post-date",
      ".entry-date",
    ];

    for (const selector of dateSelectors) {
      const element = $(selector).first();
      if (element.length > 0) {
        publishDate = element.attr("datetime") || element.text().trim();
        if (publishDate) break;
      }
    }

    // Clean up the text
    fullText = fullText
      .replace(/\s+/g, " ")
      .replace(/\n\s*\n/g, "\n\n")
      .trim();

    console.log(`✅ Article enriched: ${articleId} (${fullText.length} characters, ${structuredContent.length} blocks)`);

    return res.status(200).json({
      success: true,
      articleId,
      sourceUrl,
      fullText,
      structuredContent: structuredContent.slice(0, 100), // Limit content blocks
      images: images.slice(0, 10), // Limit to 10 images
      videos: videos.slice(0, 5), // Limit to 5 videos
      author,
      publishDate,
      scrapedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error("Error enriching article:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to enrich article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Generate AI summary for an article (premium feature)
 * POST /api/v1/articles/ai-summary
 * Body: { articleId: string, fullText: string }
 */
export const generateAISummary = async (req: Request, res: Response) => {
  try {
    const { articleId, fullText } = req.body;

    if (!articleId || !fullText) {
      return res.status(400).json({
        success: false,
        message: "articleId and fullText are required",
      });
    }

    console.log(`🤖 Generating AI summary for: ${articleId}`);

    // TODO: Integrate with actual AI service (OpenAI, Anthropic, etc.)
    // For now, return a simple extractive summary (first 3 sentences)
    const sentences = fullText.match(/[^.!?]+[.!?]+/g) || [];
    const summary = sentences.slice(0, 3).join(" ").trim();

    // Generate key points (first sentence of each paragraph)
    const paragraphs = fullText.split("\n\n").filter((p: string) => p.trim().length > 50);
    const keyPoints = paragraphs
      .slice(0, 5)
      .map((p: string) => {
        const firstSentence = p.match(/[^.!?]+[.!?]+/)?.[0] || p.substring(0, 150);
        return firstSentence.trim();
      })
      .filter((point: string) => point.length > 20);

    console.log(`✅ AI summary generated for: ${articleId}`);

    return res.status(200).json({
      success: true,
      articleId,
      summary,
      keyPoints,
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error("Error generating AI summary:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to generate AI summary",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
