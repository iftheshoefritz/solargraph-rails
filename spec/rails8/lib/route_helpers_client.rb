class RouteHelpersClient
  def link
    Rails.application.routes.url_helpers.posts_path
    Rails.application.routes.url_helpers.blog
  end

  def plain
    posts_path
  end
end
