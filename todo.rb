require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, "d61e074121811d3561aba7a3f9038d8bf39c698e48ea60d8aaa82d2a71d7e668"
  set :erb, :escape_html => true
end 

before do
  session[:lists] ||= []
end

helpers do 
  def list_complete?(list)
    list[:todos].size > 0 && todos_completed(list) == list[:todos].size
  end

  def todos_completed(list)
    total = 0
    list[:todos].each do |todo|
      total += 1 if todo[:completed]
    end
    total
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}

    todos.each_with_index do |todo, index|
      if todo[:completed]
        complete_todos[todo] = index
      else
        incomplete_todos[todo] = index
      end
    end
    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
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

# loads the list to verify if valid list or not
def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
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
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# edit an existing to do list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Update an existing to do list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id)

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
  @list = load_list(@list_id)

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
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i

  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo item has been deleted."
  redirect "/lists/#{@list_id}"
end

# update status of a todo
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"

  @todo = @list[:todos][todo_id][:completed] = is_completed
  redirect "/lists/#{@list_id}"
end

# mark all the todos as complete for a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end