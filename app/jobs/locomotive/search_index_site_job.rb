

module Locomotive
  class SearchIndexSiteJob < BaseSearchJob

    def perform(site_id)
      site = Locomotive::Site.find(site_id)

      # 1. Clear existing indices
      search_backend(site, nil)&.clear_all_indices

      # 2. BucketListly Blog
      if site_id == "5adf778b6eabcc00190b75b1"
        target_slugs = %w[posts videos destinations]
        process_entries_in_batches(site, target_slugs) do |entry|
          index_bucketlistly_post(site, entry, locale)
        end

      # 3. MintsMeals
      elsif site_id == "639b26afb83a540004858288"
        target_slugs = %w[posts]
        process_entries_in_batches(site, target_slugs) do |entry|
          index_mintsmeals_post(site, entry, locale)
        end
      end
      #else
      #  # index the content in each locale
      #  site.each_locale do |locale|
      #    # index all the pages (except the 404 one and the templatized ones)
      #    site.pages.published.each do |page|
      #      next if page.not_found? || page.templatized? || page.redirect?
      #      index_page(site, page, locale)
      #    end
      #    # index all the content entries
      #    site.content_types.each do |content_type|
      #      content_type.entries.visible.each do |entry|
      #        index_content_entry(site, entry, locale)
      #      end
      #    end
      #  end
      #end
    end

    private

    def process_entries_in_batches(site, target_slugs, batch_size = 50)
      site.content_types.where(:slug.in => target_slugs).each do |content_type|
        # 1. Fetch IDs upfront -> closes MongoDB cursor instantly (prevents CursorNotFound)
        entry_ids = content_type.entries.visible.pluck(:_id)

        # 2. Process only 50 records in RAM at a time
        entry_ids.each_slice(batch_size) do |batch_ids|
          content_type.entries.where(:_id.in => batch_ids).each do |entry|
            yield(entry)
          end

          # 3. Force Ruby Garbage Collection to immediately free Nokogiri DOM RAM
          GC.start
        end
      end
    end

  end
end