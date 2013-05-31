class BlogsController < ApplicationController
  def show
    @post = BlogPost.where(:slug => params[:slug]).first
    return render_404 unless @post
  end

  def index
    @posts = BlogPost.where(:news_hidden.ne => true)

    if params[:tag] and params[:tag].length <= 40
      @posts = @posts.where("tags.#{params[:tag]}" => {"$exists" => true})
    end
  end
end