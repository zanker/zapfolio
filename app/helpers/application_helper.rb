module ApplicationHelper
  def linkify_text(text, *args)
    text.scan(/(\{(.+?)\})/).each do |match|
      link = args.shift
      if link.is_a?(String)
        text = text.gsub(match.first, link_to(match.last, link)).html_safe
      elsif link.first == :email
        text = text.gsub(match.first, mail_to(link.last, match.last)).html_safe
      end
    end

    text
  end

  def main_page_title
    if response.code == "404"
      title = params[:action] == "no_site" ? t("titles.site_not_found") : t("titles.404")

    elsif response.code == "500"
      title = t("titles.500")

    elsif params[:controller] == "blogs"
      if @post
        title = @post.title
      else
        title = t("titles.blog")
      end

    elsif params[:controller] == "sessions"
      title = t("titles.login")

    elsif params[:controller] == "subscriptions"
      title = t("titles.subscription_plans")

    elsif params[:controller] == "home"
      if params[:action] == "privacy_policy"
        title = t("titles.privacy_policy")
      elsif params[:action] == "terms_conditions"
        title = t("titles.terms_conditions")
      elsif params[:action] == "not_setup"
        title = @website ? t("titles.not_setup", :name => @website.subdomain.capitalize) : t("titles.not_setup_generic")
      end
    end


    "#{title || t("titles.home")} - Zapfolio"
  end
end
