class GroupsController < InheritedResources::Base
  respond_to :html, :xml, :js
  
  def index
    @groups = Group.alphabetic.
                    letter(params[:letter]).
                    search(params[:search]).
                    paginate(:per_page => 10, :page => params[:page])

    index! do |format|
      format.html { render :layout => (user_signed_in? ? 'application' : 'frontpage') }
    end
  end

  protected

  # Overwrite resource method to support slug
  # See InheritedResources::BaseHelpers#resource
  def resource
    @group ||= end_of_association_chain.find_by_slug!(params[:id])
  end
end
