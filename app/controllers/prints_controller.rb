class PrintsController < ApplicationController
  before_filter :require_user, except: [:revoke, :related_by_customer]
  before_filter :require_admin_user, only: [:revoke, :related_by_customer]
  before_filter :load_customer

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /prints
  # GET /prints.json
  def index
    @title = t('view.prints.index_title')
    order = params[:status] == 'scheduled' ? 'scheduled_at ASC' :
      'created_at DESC'
    
    @prints = prints_scope.order(order).paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @prints }
    end
  end

  # GET /prints/1
  # GET /prints/1.json
  def show
    @title = t('view.prints.show_title')
    @print = prints_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @print }
    end
  end

  # GET /prints/new
  # GET /prints/new.json
  def new
    @title = t('view.prints.new_title')
    
    unless params[:clear_documents_for_printing].blank?
      session[:documents_for_printing].try(:clear)
    end

    @print = current_user.prints.build(
      order_id: params[:order_id],
      include_documents: session[:documents_for_printing]
    )

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render json: @print }
    end
  end

  # GET /prints/1/edit
  def edit
    @title = t('view.prints.edit_title')
    @print = prints_scope.find(params[:id])

    if !@print.pending_payment? && !@print.scheduled?
      raise 'This print is readonly!'
    end
  end

  # POST /prints
  # POST /prints.json
  def create
    @title = t('view.prints.new_title')
    @print = current_user.prints.build(params[:print])
    session[:documents_for_printing].try(:clear)

    respond_to do |format|
      if @print.save
        format.html { redirect_to(@print, notice: t('view.prints.correctly_created')) }
        format.json  { render json: @print, status: :created, location: @print }
      else
        format.html { render action: 'new' }
        format.json  { render json: @print.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /prints/1
  # PUT /prints/1.json
  def update
    @title = t('view.prints.edit_title')
    @print = prints_scope.find(params[:id])

    if !@print.pending_payment? && !@print.scheduled?
      raise 'This print is readonly!'
    end

    respond_to do |format|
      if @print.update_attributes(params[:print])
        format.html { redirect_to(@print, notice: t('view.prints.correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit' }
        format.json  { render json: @print.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.prints.stale_object_error')
    redirect_to edit_print_url(@print)
  end
  
  # DELETE /prints/1/revoke
  # DELETE /prints/1/revoke.json
  def revoke
    @print = prints_scope.find(params[:id])
    @print.revoke!
    
    respond_to do |format|
      format.html { redirect_to(prints_url, notice: t('view.prints.correctly_revoked')) }
      format.json  { head :ok }
    end
  end

  # GET /prints/autocomplete_for_document_name
  def autocomplete_for_document_name
    query = params[:q].sanitized_for_text_query
    @query_terms = query.split(/\s+/).reject(&:blank?)
    @docs = Document.scoped
    @docs = @docs.full_text(@query_terms) unless @query_terms.empty?
    @docs = @docs.limit(10)
    
    respond_to do |format|
      format.json { render json: @docs }
    end
  end

  # GET /prints/autocomplete_for_article_name
  def autocomplete_for_article_name
    query = params[:q].sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    articles = Article.scoped
    articles = articles.full_text(query_terms) unless query_terms.empty?
    articles = articles.limit(10)
    
    respond_to do |format|
      format.json { render json: articles }
    end
  end
  
  # GET /prints/autocomplete_for_customer_name
  def autocomplete_for_customer_name
    query = params[:q].sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    customers = Customer.scoped
    customers = customers.full_text(query_terms) unless query_terms.empty?
    customers = customers.limit(10)
    
    respond_to do |format|
      format.json { render json: customers }
    end
  end

  # PUT /prints/cancel_job
  def cancel_job
    @print_job = PrintJob.find(params[:id])
    @cancelled = @print_job.cancel
  end

  def related_by_customer
    current_print = prints_scope.find(params[:id])
    print = current_print.related_by_customer(params[:type])

    redirect_to prints_scope.exists?(print) ? print : current_print
  end

  private
  
  def load_customer
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
  end

  def prints_scope
    if @customer
      scope = @customer.prints
    else
      scope = current_user.admin ? Print.scoped : current_user.prints
    end

    case params[:status]
      when 'pending'
        scope = scope.pending
      when 'scheduled'
        scope = scope.scheduled
      when 'pay_later'
        scope = scope.pay_later
    end

    scope
  end
end
