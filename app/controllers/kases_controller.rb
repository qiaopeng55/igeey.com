class KasesController < ApplicationController
  respond_to :html
  before_filter :login_required, :except => [:index]
  
  def index
    @problem = Problem.find(params[:problem_id])
    @kases = @problem.kases
  end
  
  def new
    @problem = Problem.find(params[:problem_id])
    @kase = @problem.kases.build
  end
  
  def create
    @problem = Problem.find(params[:problem_id])
    @kase = @problem.kases.build(params[:kase])
    @kase.save
    redirect_to problem_path(@problem)
  end
end