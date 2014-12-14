class NormalPostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
  end

  def edit
    @post = Post.find(params[:id])
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to [:normal, @post]
    else
      render :new
    end
  end

  def update
    @post = Post.find(params[:id])

    if @post.update_attributes(post_params)
      redirect_to [:normal, @post]
    else
      render :edit
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :image, :image_cache_id, :document, :document_cache_id, :remove_document, :remote_document_url)
  end
end
