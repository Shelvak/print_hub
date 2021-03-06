class DocumentsController < ApplicationController
  before_action :require_user, :load_documents_for_printing
  helper_method :sort_column, :sort_direction

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /documents
  # GET /documents.json
  def index
    @title = t('view.documents.index_title')
    @searchable = true
    @tag = Tag.find(params[:tag_id]) if params[:tag_id]
    @documents = @tag ? @tag.documents : Document.all

    unless params[:clear_documents_for_printing].blank?
      @documents_for_printing = session[:documents_for_printing].clear

      redirect_to request.parameters.except(:clear_documents_for_printing)
    end

    @documents = Document.unscoped.disable if params[:disabled_documents]

    if params[:q].present?
      query = params[:q].sanitized_for_text_query
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @documents = @documents.full_text(@query_terms) unless @query_terms.empty?
    end

    @documents = @documents.order(
      "#{Document.table_name}.#{sort_column} #{sort_direction.upcase}"
    ).paginate(page: params[:page], per_page: lines_per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @documents }
    end
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @title = t('view.documents.show_title')
    @document = Document.unscoped.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @document }
    end
  end

  # GET /documents/new
  # GET /documents/new.json
  def new
    @title = t('view.documents.new_title')
    @document = Document.new

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render json: @document }
    end
  end

  # GET /documents/1/edit
  def edit
    @title = t('view.documents.edit_title')
    @document = Document.unscoped.find(params[:id])
  end

  # POST /documents
  # POST /documents.json
  def create
    @title = t('view.documents.new_title')
    params[:document][:tag_ids] ||= []
    @document = Document.new(document_params)

    respond_to do |format|
      if @document.save
        format.html { redirect_to(documents_url, notice: t('view.documents.correctly_created')) }
        format.json  { render json: @document, status: :created, location: @document }
      else
        format.html { render action: 'new' }
        format.json  { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.json
  def update
    @title = t('view.documents.edit_title')
    @document = Document.unscoped.find(params[:id])
    params[:document][:tag_ids] ||= []

    respond_to do |format|
      if @document.update(document_params)
        format.html { redirect_to(documents_url, notice: t('view.documents.correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit' }
        format.json  { render json: @document.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.documents.stale_object_error')
    redirect_to edit_document_url(@document)
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @document = Document.unscoped.find(params[:id])

    unless @document.destroy
      flash.alert = @document.errors.full_messages.join('; ')
    end

    respond_to do |format|
      format.html { redirect_to(documents_url) }
      format.json  { head :ok }
    end
  end

  # GET /document/1/barcode
  def barcode
    @document = Document.where(code: params[:id]).first_or_initialize
  end

  # POST /documents/1/add_to_next_print
  def add_to_next_print
    @document = Document.find(params[:id])

    unless @documents_for_printing.include?(@document.id)
      session[:documents_for_printing] << @document.id
    end
  end

  # DELETE /documents/1/remove_from_next_print
  def remove_from_next_print
    @document = Document.find(params[:id])

    session[:documents_for_printing].delete(@document.id)
  end

  # GET /documents/autocomplete_for_tag_name
  def autocomplete_for_tag_name
    tags = full_text_search_for(Tag.all.order(:id), params[:q])

    respond_to do |format|
      format.json { render json: tags }
    end
  end

  def generate_barcodes_range
    if params[:barcodes]
      Document.generate_barcodes_range(barcodes_params)

      redirect_to generate_barcodes_range_documents_path, notice: t('view.documents.barcodes_range.working')
    else
      render 'generate_barcodes_range'
    end
  end

  private

  def load_documents_for_printing
    @documents_for_printing = (session[:documents_for_printing] ||= [])
  end

  def sort_column
    %w(code name).include?(params[:sort]) ? params[:sort] : 'code'
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : default_direction
  end

  def default_direction
    sort_column == 'code' ? 'desc' : 'asc'
  end

  # Atributos permitidos
  def document_params
    params.require(:document).permit(
      :code, :name, :description, :media, :enable, :stock, :file_cache,
      :pages, :auto_tag_name, :lock_version, :file, :original_file,
      :original_file_cache, :is_public, tag_ids: []
    )
  end

  def barcodes_params
    params.require(:barcodes).permit(:from, :to, :email)
  end
end
