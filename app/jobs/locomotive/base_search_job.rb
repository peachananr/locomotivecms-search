module Locomotive
  class BaseSearchJob < ApplicationJob

    queue_as :search

    protected

    def search_backend(site, locale)
      Rails.configuration.x.locomotive_search_backend.create(site, locale)
    end

    #def index_page(site, page, locale)
    #  search_backend(site, locale)&.save_object(
    #    type:       'page',
    #    object_id:  page._id.to_s,
    #    title:      page.title,
    #    content:    page.content_to_index,
    #    visible:    page.published?,
    #    data:       page.data_to_index
    #  )
    #end

    def index_content_entry(site, entry, locale)
      search_backend(entry.site, locale)&.save_object(
        type:       entry.content_type.slug,
        object_id:  entry._id.to_s,
        title:      entry._label,
        content:    entry.content_to_index,
        visible:    entry.visible?,
        data:       entry.data_to_index
      )
    end
    ## CUSTOM Index Job for BucketListly Blog Only
    def index_bucketlistly_post(site, entry, locale)
      return if entry.nil? || entry.content_type.nil?

      case entry.content_type.slug
      when "posts"
        data = entry.blog_post_data_to_index
        return if data.nil? # Guard against nil payload (no_index or invisible)

        formatted_title = [entry.title, entry.subtitle].map(&:presence).compact.join(' ')

        search_backend(entry.site, locale)&.save_object(
          type:       "9-#{entry.content_type.slug}",
          object_id:  entry._id.to_s,
          title:      formatted_title,
          visible:    entry.visible?,
          data:       data
        )

      #when "videos"
      #  data = entry.video_data_to_index
      #  return if data.nil?

      #  search_backend(entry.site, locale)&.save_object(
      #    type:       "5-#{entry.content_type.slug}",
      #    object_id:  entry._id.to_s,
      #    title:      "#{entry.title} Travel Video".strip,
      #    visible:    entry.visible?,
      #    data:       data
      #  )

      when "destinations"
        data = entry.destination_data_to_index
        return if data.nil?

        search_backend(entry.site, locale)&.save_object(
          type:       "1-#{entry.content_type.slug}",
          object_id:  entry._id.to_s,
          title:      "#{entry.name} Travel Guides".strip,
          visible:    entry.visible?,
          data:       data
        )
      end
    end

    def index_mintsmeals_post(site, entry, locale)
      if entry.content_type.slug == "posts"
        search_backend(entry.site, locale)&.save_object(
          type:       "9-#{entry.content_type.slug}",
          object_id:  entry._id.to_s,
          title:      "#{entry.title}",
          content:    entry.blog_post_to_index,
          visible:    entry.visible?,
          data:       entry.recipe_data_to_index
        )
      end
    end
  end
end
