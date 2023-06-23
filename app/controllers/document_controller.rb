class DocumentController < ApplicationController
  def index
    @documents = Document.all
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      redirect_to documents_path, notice: 'Successfully uploaded.'
    else
      render 'new'
    end
  end

  def destroy
    @document = document.find(params[:id])
    @document.destroy
    redirect_to documents_path, notice: 'Successfully deleted.'
  end

  private

  def document_params
    params.require(:document).permit(:name, :attachment)
  end
end
