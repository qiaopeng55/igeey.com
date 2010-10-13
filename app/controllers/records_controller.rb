class RecordsController < ApplicationController
  respond_to :html
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_record, :except => [:index,:new,:create]
  
  def new
    @record = Record.new(:action_id => params[:action_id],:venue_id => params[:venue_id])
    @venue = @record.venue
    @action = @record.action
  end
  
  def create
    @record = Record.new(params[:record])
    @record.user = current_user
    flash[:notice] = 'Record was successfully created.' if @record.save
    respond_with(@record)
  end
  
  def show
  end
  
  private
  def find_record
    @record = Record.find(params[:id])
  end
  
end
