class Supply::OrdersController < BaseController
  before_filter :need_login
  def index
    @key = params[:key]
    @date_start = params[:date_start].blank? ? Time.now.to_date : params[:date_start]
    @date_end = params[:date_end].blank? ? Time.now.to_date : params[:date_end]
    @orders = current_user.company.in_orders.valid_orders
    @orders = @orders.where(reach_order_date: @date_start..@date_end)
    @orders = @orders.where(customer_id: params[:customer_id]) unless params[:customer_id].blank?
    @orders = @orders.where(store_id: params[:store_id]) unless params[:store_id].blank?
    unless @key.blank?
      company = Company.find_by_simple_name(@key)
      @orders = @orders.where("id = ? or customer_id = ? or customer_id = ?", @key, @key, company.blank? ? nil : company.id)
    end
    @orders = @orders.paginate(page: params[:page], per_page: 10)
  end

  def edit
    @order = Order.find(params[:id])
    @pre_order = @order.previous @order.order_type.previous
    @next_order = @order.next @order.order_type.next
    @order_items = @order.order_items
  end

  def update
    hash = params[:order_item]
    Order.transaction do
      hash.each do |key,value|
        order_item = OrderItem.find(key)

          order_item.update_attribute :real_weight, value.blank? ? 0 : value
          order_item.update_money
      end
    end
    redirect_to "/supply/orders/#{params[:order_id]}/edit?t=#{Time.now.to_i}"
  end

  def comment
    begin
      comment = Comment.create! order_id: params[:order_id], content: params[:content], user_id: current_user.id
      OrderMessageMailer.reply_question_order_message(params[:content],comment.created_at,params[:order_id]).deliver
      redirect_to edit_supply_order_path(params[:order_id])
    rescue Exception => e
      flash[:alert] = dispose_exception e
      redirect_to edit_supply_order_path(params[:order_id])
    end
  end

end

# Parameters: {"order_id"=>"80",
# "order_item"=>{"98"=>[""], "99"=>[""], "100"=>[""], "101"=>[""], "102"=>[""], "103"=>[""], "104"=>[""], "105"=>[""], "106"=>[""], "107"=>[""], "108"=>[""]}, "commit"=>"提交", "id"=>"80"}
# User Load (39.5ms)  SELECT  `users`.* FROM `users`  WHERE `users`.`id` = 1  ORDER BY `users`.`id` ASC LIMIT 1