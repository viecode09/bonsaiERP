# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class OrganisationsController < ApplicationController
  before_filter :check_authorization!
  before_filter :reset_search_path
  before_filter :destroy_organisation_session!, :except => [ :select, :edit, :update, :edit_preferences, :update_preferences ]

  #layout "application", :only => [:edit, :update]

  respond_to :html, :xml, :json

  # GET /organisations
  # GET /organisations.xml
  def index
    @organisations = current_user.organisations
    if current_user.organisations.any?
      set_organisation_session(current_user.organisations.first)
      @currency_rates = CurrencyRate.current_hash
      render "/dashboard/index"
    else
      reset_org
      session[:step] = params[:step] || 1
      session[:max_step] ||= 1

      send(:"get_step_#{session[:step]}")
      render :action => 'new'
    end
  end

  # GET /organisations/1
  # GET /organisations/1.xml
  def show
    session[:organisation] = nil
    @organisation = Organisation.find(params[:id])
    respond_with(@organisation)
  end

  # GET /organisations/new
  def new
    session[:organisation] = nil
    @organisation = Organisation.new(:currency_id => 1)
  end

  # GET /organisations/:id/schema
  def check_schema
    res = PgTools.schema_exists?(PgTools.get_schema_name(params[:id]))
    if res
      org = Organisation.find(params[:id])
      set_organisation_session(org)
    end
    render :json => {:success => res, :id => params[:id]}
  end

  # POST /organisations
  def create
    @organisation = Organisation.new(params[:organisation])
    @organisation.client_account_id = ClientAccount.find_by_name("Inicial").id
    @organisation.due_date = Date.today

    if @organisation.save
      flash[:notice] = "Se ha creado su empresa correctamente."
      job = Qu.enqueue CreateTenant, @organisation.id, session[:user_id]

      redirect_to @organisation
    else
      render 'new'
    end
  end

  # GET /organisations/:id/create_tenant
  def create_tenant
    @organisation = Organisation.find(params[:id])
    job = Qu.enqueue CreateTenant, @organisation.id, session[:user_id]
    render "show"
  end

  # GET /organisations/:id/edit
  def edit
    @organisation = Organisation.find(session[:organisation][:id])
  end

  # PUT /operations/:id
  def update
    p = params[:organisation]
    p.delete(:currency_id)
    @organisation = Organisation.find(params[:id])

    if @organisation.update_attributes(p)
      redirect_to "/configuration#organisation", :notice => "Se actualizo los datos correctamente."
    else
      render "edit"
    end
  end

  # GET /organisation/1/select
  # sets the organisation session
  #def select
  #  orgs = current_user.organisations.where(:organisation_id => params[:id]).any?
  #  res = !!PgTools.set_search_path(params[:id])
  #  
  #  case
  #  when(orgs and res)
  #  end
  #  begin
  #    @organisation = current_user.organisations.find(params[:id])

  #    redirect_to "/dashboard"
  #  rescue
  #    flash[:error] = "Error, ingrese de nuevo"
  #    redirect_to "/users/sign_out"
  #  end
  #end

  private

  def reset_search_path
    PgTools.reset_search_path
  end
end
