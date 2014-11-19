class ItemsController < ApplicationController

  def index
    @items = Item.all

    offset = rand(Item.count)
    @rand_record = Item.offset(offset).first.id
  end

  def show
    @user = current_user
    @item = Item.find(params[:id])

    first = Item.first.id
    last = Item.last.id
    rand_number = (first..last).to_a.sample

    @next_item = next_item

  end

  def create_history

    user = current_user

    new_history = History.new
    new_history.user_id = user.id
    new_history.item_id = params['item_id']
    new_history.liked = if params['liked'] == 'true'
                          true
                        else
                          false
                        end
    new_history.in_wishlist = if params['liked'] == 'true'
                          true
                        else
                          false
                        end
    new_history.clicked_through = params['clicked_through']
    new_history.save

    redirect_to item_path(params['next_item'])

  end

  def create_history_from_buy
    user = current_user

    new_history = History.new
    new_history.user_id = user.id
    new_history.item_id = params['item_id']
    new_history.liked = if params['liked'] == 'true'
                          true
                        else
                          false
                        end
    new_history.in_wishlist = if params['liked'] == 'true'
                          true
                        else
                          false
                        end
    new_history.clicked_through = params['clicked_through']
    new_history.save

    redirect_to new_history.item.merchant_url

  end

  def edit_history
    user = current_user
    current_history_item = user.histories.where(:item_id => params['item_id']).first
    current_history_item.clicked_through = params['clicked_through']
    current_history_item.save

    redirect_to current_history_item.item.merchant_url
  end

  def delete_from_wishlist
    user = current_user
    current_history_item = user.histories.where(:item_id => params['item_id']).first
    current_history_item.in_wishlist = false
    current_history_item.save

    redirect_to user_wishlist_path
  end

  def details
    @item = Item.where(:id => params['id']).first
  end

  def convert_top_level_name(gender)
    category = gender

    if category == "womens"
      category = "female"
      @name = "Womens"
    elsif category == "mens"
      category = "male"
      @name = "Mens"
    end

    category
  end

  def top_category
    @gender_old = params[:gender]

    @gender = convert_top_level_name(@gender_old)

    id = Category.where(name: @gender).first.id

    @children = Category.find(id).children

    render '/items/category/index.html.erb'
  end

  def category_1
    @gender_old = params[:gender]
    @gender = convert_top_level_name(@gender_old)
    @cat1 = params[:category_1]

    id = Category.where(name: @cat1).first.id
    @children = Category.find(id).children

    render '/items/category/index.html.erb'
  end

  def category_1_view
    @gender = params[:gender]
    # @category_old = params[:category_1]
    # @category_old.capitalize!
    # @category = Category.where(name: @category_old)

    @items = Category.find_by(name: @gender).descendants.where("lower(name) = ?", params[:category_1]).first.items

    # gets all item ids in the chosen category
    @item_ids = []
    @items.each do |item|
      @item_ids << item.id
    end

    @item = @items.sample

    @next_item = @items.sample
    # @next_item = Item.where(:id => rand(1000)).first

    render '/items/category/show.html.erb'
  end

  def category_all
    @user = current_user

    @category = params[:category]
    @gender = params[:gender]

    case @category || @gender
      when 'womens'
        @category == 'womens'
        @items = Item.all.where(:gender => "female")
        @items += Item.all.where(:gender => "unisex")
        @item = @items.sample
      when 'mens'
        @items = Item.all.where(:gender => "male")
        @items += Item.all.where(:gender => "unisex")
        @item = @items.sample
    end

    @next_item = next_item

    render '/items/category/show.html.erb'
  end


  private

  def next_item

# Determines what will be shown next

    # if a first-time user (no history yet)
    if @user.histories.count < 20

      @next_item = Item.where(:id => rand(1000)).first

    # if user has history record
    else

      liked_items = @user.histories.where(:liked => true)

      brands_liked = liked_items.each_with_object(Hash.new(0)) { |item,counts| counts[item.item.brand] += 1 }
      categories_liked = liked_items.each_with_object(Hash.new(0)) { |item,counts| counts[item.item.category.name] += 1 }

      def get_favourite(list)
        counts = []
        # gets all the item counts and adds to 'counts' array
        list.each do |pair|
          counts << pair[1]
        end
        #finds out the two highest counts from the 'counts' array
        highest_counts = counts.sort.uniq

        if highest_counts.length > 1
          highest_counts = highest_counts[-2..-1]
        else
          highest_counts
        end

        #makes an array of the brand or category that has the highest counts
        list.map{|item, count| item if highest_counts.include?count }.compact
      end

      fave_brands = get_favourite(brands_liked)
      fave_categories = get_favourite(categories_liked)

      # selects what item to show next

      # takes only items that are not in the user's history
      items_not_in_history = Item.where.not(:id => @user.histories.pluck(:item_id))


      # color

      # gives two options: 1. a random item, 2. an item from a favourite brand
      items_to_show = [items_not_in_history.sample, items_not_in_history.sample, items_not_in_history.sample, items_not_in_history.where(brand: fave_brands.sample).sample ]

      #chooses randomly from the 'items_to_show' options

      @next_item = items_to_show.sample

    end

  end


end