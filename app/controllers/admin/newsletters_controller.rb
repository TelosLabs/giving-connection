module Admin
  class NewslettersController < Admin::ApplicationController
    def index
      search_term = params[:search].to_s.strip
      resources = filter_resources(scoped_resource, search_term: search_term)
      resources = apply_collection_includes(resources)
      resources = order.apply(resources)
      resources = resources.page(params[:_page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard, order: order)

      @emails_to_display = get_filtered_emails
      @newsletter_ids_to_mark = get_filtered_newsletter_ids

      render locals: { resources: resources, search_term: search_term, page: page, show_search_bar: show_search_bar? }
    end
    
    def mark_all_as_added
      ids = params[:ids] || []
      Newsletter.where(id: ids).update_all(added: true)
      flash[:notice] = "#{ids.count} newsletter subscription(s) marked as added."
      redirect_to admin_newsletters_path(filter: params[:filter])
    end

    private

    def scoped_resource
      if params[:filter] == 'ready'
        Newsletter.verified_not_added
      else
        Newsletter.where(verified: true)
      end
    end

    def get_filtered_emails
      if params[:filter] == 'ready'
        Newsletter.verified_not_added.pluck(:email)
      else
        Newsletter.where(verified: true).pluck(:email)
      end
    end

    def get_filtered_newsletter_ids
      if params[:filter] == 'ready'
        Newsletter.verified_not_added.pluck(:id)
      else
        Newsletter.where(verified: true).pluck(:id)
      end
    end
  end
end