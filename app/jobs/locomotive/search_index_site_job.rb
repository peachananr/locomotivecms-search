module Locomotive
  class SearchIndexSiteJob < BaseSearchJob

    def perform(site_id)
      site = Locomotive::Site.find(site_id)

      # 1. Clear existing index first
      search_backend(site, nil)&.clear_all_indices

      # 2. BucketListly Blog
      if site_id == "5adf778b6eabcc00190b75b1"
        target_slugs = %w[posts videos destinations]

        site.content_types.where(:slug.in => target_slugs).each do |content_type|
          index_content_type_in_batches(site, content_type) do |entry|
            build_bucketlistly_payload(site, entry)
          end
        end

      # 3. MintsMeals
      elsif site_id == "639b26afb83a540004858288"
        target_slugs = %w[posts]

        site.content_types.where(:slug.in => target_slugs).each do |content_type|
          index_content_type_in_batches(site, content_type) do |entry|
            build_mintsmeals_payload(site, entry)
          end
        end
      end
    end

    private

    # Batches entries to prevent Mongo cursor timeouts & Heroku OOM
    def index_content_type_in_batches(site, content_type, batch_size = 50)
      # Fetch all entry IDs into memory upfront -> closes Mongo cursor instantly
      entry_ids = content_type.entries.visible.pluck(:_id)

      entry_ids.each_slice(batch_size) do |batch_ids|
        algolia_objects = []

        # Load current 50 records
        entries = content_type.entries.where(:_id.in => batch_ids)

        entries.each do |entry|
          next if entry.no_index == true

          payload = yield(entry)
          algolia_objects << payload if payload.present?
        end

        # Bulk upload 50 records in 1 single HTTP request
        if algolia_objects.any?
          search_backend(site, locale)&.save_objects(algolia_objects)
        end

        # Force Ruby GC to clear Nokogiri memory between batches
        GC.start
      end
    end

    # BucketListly Payload Builder
    def build_bucketlistly_payload(site, entry)
      data_payload = entry.blog_post_data_to_index
      return nil if data_payload.nil?

      {
        objectID: entry._id.to_s,
        type:     "9-#{entry.content_type.slug}",
        title:    "#{entry.title} #{entry.subtitle}",
        visible:  entry.visible?,
        data:     data_payload
      }
    end

    # MintsMeals Payload Builder
    def build_mintsmeals_payload(site, entry)
      # Adapt to your MintsMeals data logic if different
      data_payload = entry.respond_to?(:blog_post_data_to_index) ? entry.blog_post_data_to_index : {}

      {
        objectID: entry._id.to_s,
        type:     "9-#{entry.content_type.slug}",
        title:    "#{entry.title}",
        visible:  entry.visible?,
        data:     data_payload
      }
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
    #end

  #end
#end
