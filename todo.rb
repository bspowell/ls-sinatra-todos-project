require 'pry'
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, "d61e074121811d3561aba7a3f9038d8bf39c698e48ea60d8aaa82d2a71d7e668"
end 

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# view all the lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

# create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end 
end

# view a single todo list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# edit an existing to do list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end

# Update an existing to do list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end 
end


# delete a todo list
post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/"
end

# adding a todo
post "/lists/:list_id/todos" do
  todo = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_todo(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: "#{todo}", completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# delete a todo item
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i

  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo item has been deleted."
  redirect "/lists/#{@list_id}"
end

# update status of a todo
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"

  @todo = @list[:todos][todo_id][:completed] = is_completed
  redirect "/lists/#{@list_id}"
end