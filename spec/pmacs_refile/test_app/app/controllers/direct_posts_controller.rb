class DirectPostsController < ApplicationController
  def new
    @post = Post.new
  end

  def create
    @post = Post.new(params.require(:post).permit(:title, :document, :image, :requires_document, documents_files: []))

    if @post.save
      redirect_to [:normal, @post]
    else
      render :new
    end
  end
end
