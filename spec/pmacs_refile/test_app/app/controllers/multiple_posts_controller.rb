class MultiplePostsController < ApplicationController
  def new
    @post = Post.new
    render :form
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to [:normal, @post]
    else
      render :form
    end
  end

  def edit
    @post = Post.find(params[:id])
    render :form
  end

  def update
    @post = Post.find(params[:id])

    if @post.update_attributes(post_params)
      redirect_to [:normal, @post]
    else
      render :form
    end
  end

private

  def post_params
    params.require(:post).permit(:title, documents_files: [])
  end
end
