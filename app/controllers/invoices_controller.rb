class InvoicesController < ApplicationController
  unloadable

  before_filter :find_invoice, :except => [:new, :create, :index]
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper



  def new
    @invoice = TocatInvoice.new
  end


  def create
    @invoice = TocatInvoice.new(params[:invoice])
    if @invoice.save
      flash[:notice] = l(:notice_invoice_successful_created)
      respond_to do |format|
        format.html { redirect_back_or_default({:action => 'show', :id => @invoice}) }
        format.js do
          render :update do |page|
            page.replace_html 'invoice-form', :partial => 'tocat/invoices/edit', :locals => {:invoice => @invoice}
          end
        end
      end
    else
      @invoice_old = @invoice
      @invoice.reload
      respond_to do |format|
        format.html { render :template => 'invoices/edit' }
      end
    end
  end

  def edit
  end


  def index
    sort_update %w(external_id total paid)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:sort] = params[:sort] if params[:sort].present?

    @invoices = TocatInvoice.all(params: query_params)
    @invoice_count = @invoices.http_response['X-total'].to_i
    @invoice_pages = Paginator.new self, @invoice_count, @invoices.http_response['X-Per-Page'].to_i, params['page']
  end


  def show
  end


  def set_paid
    respond_to do |format|
      if @invoice.set_paid

      else

      end
    end
  end

  def set_unpaid
    respond_to do |format|
      if @invoice.set_unpaid

      else

      end
    end
  end

  private

  def find_invoice
    @invoice = TocatInvoice.find(params[:id])
  end

  def check_for_setup
    errors = false
    errors = true unless RedmineTocatClient.settings[:host].present?

    if errors
      respond_to do |format|
        format.html { render(:template => 'error', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
      end
    end
  end

end
