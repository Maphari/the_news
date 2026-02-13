import dotenv from 'dotenv';
dotenv.config();

import app from './app';
import { syncPodcastsInBackground } from './controllers/podcast.controller';

const PORT: number = Number(process.env.PORT);
const HOST: string = String(process.env.DEFAULT_PORT);

//? Start the server
app.listen(PORT, HOST, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📰 Environment: ${process.env.NODE_ENV || 'development'}`);

    const backgroundSyncEnabled = String(process.env.PODCAST_BACKGROUND_SYNC_ENABLED || "true")
      .toLowerCase() === "true";
    const syncMinutes = Math.max(
      10,
      Number.parseInt(process.env.PODCAST_BACKGROUND_SYNC_INTERVAL_MINUTES || "30", 10) || 30,
    );
    const syncLimitPerCategory = Math.max(
      5,
      Number.parseInt(process.env.PODCAST_BACKGROUND_SYNC_LIMIT_PER_CATEGORY || "12", 10) || 12,
    );

    if (!backgroundSyncEnabled) {
      console.log("⏸️ Podcast background sync disabled (PODCAST_BACKGROUND_SYNC_ENABLED=false)");
      return;
    }

    const runSync = async () => {
      try {
        const summary = await syncPodcastsInBackground({
          limitPerCategory: syncLimitPerCategory,
        });
        console.log(
          `🎧 Background podcast sync: ${summary.totalSynced} synced across ${summary.categories.length} categories`,
        );
      } catch (error) {
        console.error("Background podcast sync failed:", error);
      }
    };

    setTimeout(runSync, 10_000);
    setInterval(runSync, syncMinutes * 60 * 1000);
    console.log(`🗓️ Podcast background sync scheduled every ${syncMinutes} minutes`);
});
