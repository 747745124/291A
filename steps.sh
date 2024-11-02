# First, ensure you have Ruby and Rails installed
# Ruby version: 3.2.0 or higher recommended
# Rails version: 7.0.0 or higher recommended

# 1. Create a new Rails application
rails new social_posts --database=postgresql

# 2. Navigate to the application directory
cd social_posts

# 3. Add these gems to your Gemfile
source "https://rubygems.org"
gem "rails", "~> 7.0.0"
gem "pg"
gem "puma"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end

# 4. Install the gems
bundle install

# 5. Generate the migrations and run them
rails generate migration CreateUsers username:string:uniq
rails generate migration CreatePosts content:text user:references
rails generate migration CreateComments content:text user:references post:references

# 6. Update config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: social_posts_development

test:
  <<: *default
  database: social_posts_test

production:
  <<: *default
  database: social_posts_production
  username: social_posts
  password: <%= ENV["SOCIAL_POSTS_DATABASE_PASSWORD"] %>

# 7. Create and migrate the database
rails db:create
rails db:migrate

# 8. Create necessary directories
mkdir -p app/views/sessions
mkdir -p app/views/posts
mkdir -p app/views/comments

# 9. Create view templates

# app/views/layouts/application.html.erb
<!DOCTYPE html>
<html>
  <head>
    <title>Social Posts</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="bg-gray-100">
    <nav class="bg-white shadow-lg">
      <div class="max-w-6xl mx-auto px-4">
        <div class="flex justify-between">
          <div class="flex space-x-7">
            <%= link_to "Home", root_path, class: "py-4 px-2 text-gray-500 font-semibold" %>
          </div>
          <div class="flex items-center space-x-3">
            <% if current_user %>
              <span class="text-gray-500">Welcome, <%= current_user.username %></span>
              <%= link_to "Logout", logout_path, class: "py-2 px-2 font-medium text-gray-500 rounded hover:bg-gray-100 hover:text-gray-900" %>
            <% end %>
          </div>
        </div>
      </div>
    </nav>

    <div class="container mx-auto px-4 py-8">
      <% if notice %>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4" role="alert">
          <span class="block sm:inline"><%= notice %></span>
        </div>
      <% end %>
      
      <% if alert %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4" role="alert">
          <span class="block sm:inline"><%= alert %></span>
        </div>
      <% end %>

      <%= yield %>
    </div>
  </body>
</html>

# app/views/sessions/new.html.erb
<div class="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl p-6">
  <h2 class="text-2xl font-bold mb-4">Login</h2>
  <%= form_tag login_path do %>
    <div class="mb-4">
      <%= label_tag :username, "Username", class: "block text-gray-700 text-sm font-bold mb-2" %>
      <%= text_field_tag :username, nil, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" %>
    </div>
    <%= submit_tag "Login", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" %>
  <% end %>
</div>

# app/views/posts/index.html.erb
<div class="max-w-4xl mx-auto">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Posts</h1>
    <%= link_to "New Post", new_post_path, class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
  </div>

  <%= form_tag root_path, method: :get, class: "mb-6" do %>
    <div class="flex gap-2">
      <%= text_field_tag :username, params[:username], placeholder: "Filter by username", class: "shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline flex-grow" %>
      <%= submit_tag "Filter", class: "bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded" %>
    </div>
  <% end %>

  <div class="space-y-6">
    <% @posts.each do |post| %>
      <div class="bg-white shadow rounded-lg p-6">
        <div class="flex justify-between items-start mb-4">
          <div>
            <h2 class="text-xl font-semibold"><%= post.user.username %></h2>
            <p class="text-gray-500 text-sm">
              <%= time_ago_in_words(post.updated_at) %> ago
            </p>
          </div>
          <% if post.user == current_user %>
            <div class="space-x-2">
              <%= link_to "Edit", edit_post_path(post), class: "text-blue-500 hover:text-blue-700" %>
              <%= button_to "Delete", post_path(post), method: :delete, class: "text-red-500 hover:text-red-700", data: { confirm: "Are you sure?" } %>
            </div>
          <% end %>
        </div>
        
        <p class="text-gray-700 mb-4"><%= post.content %></p>
        
        <%= link_to post_path(post), class: "text-blue-500 hover:text-blue-700" do %>
          <%= pluralize(post.comments.count, 'comment') %>
        <% end %>
      </div>
    <% end %>
  </div>
</div>

# app/views/posts/show.html.erb
<div class="max-w-4xl mx-auto">
  <div class="bg-white shadow rounded-lg p-6 mb-6">
    <div class="flex justify-between items-start mb-4">
      <div>
        <h2 class="text-xl font-semibold"><%= @post.user.username %></h2>
        <p class="text-gray-500 text-sm">
          <%= time_ago_in_words(@post.updated_at) %> ago
        </p>
      </div>
      <% if @post.user == current_user %>
        <div class="space-x-2">
          <%= link_to "Edit", edit_post_path(@post), class: "text-blue-500 hover:text-blue-700" %>
          <%= button_to "Delete", post_path(@post), method: :delete, class: "text-red-500 hover:text-red-700", data: { confirm: "Are you sure?" } %>
        </div>
      <% end %>
    </div>
    
    <p class="text-gray-700"><%= @post.content %></p>
  </div>

  <div class="bg-white shadow rounded-lg p-6 mb-6">
    <h3 class="text-xl font-semibold mb-4">Add a Comment</h3>
    <%= form_for [@post, @comment] do |f| %>
      <% if @comment.errors.any? %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">
          <ul>
            <% @comment.errors.full_messages.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <div class="mb-4">
        <%= f.text_area :content, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline", rows: 3 %>
      </div>
      <%= f.submit "Add Comment", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
    <% end %>
  </div>

  <div class="bg-white shadow rounded-lg p-6">
    <h3 class="text-xl font-semibold mb-4">Comments</h3>
    <div class="space-y-4">
      <% @post.comments.includes(:user).each do |comment| %>
        <div class="border-b pb-4">
          <div class="flex justify-between items-start mb-2">
            <div>
              <p class="font-semibold"><%= comment.user.username %></p>
              <p class="text-gray-500 text-sm">
                <%= time_ago_in_words(comment.created_at) %> ago
              </p>
            </div>
          </div>
          <p class="text-gray-700"><%= comment.content %></p>
        </div>
      <% end %>
    </div>
  </div>
</div>

# app/views/posts/new.html.erb
<div class="max-w-4xl mx-auto">
  <h1 class="text-3xl font-bold mb-6">New Post</h1>
  
  <%= form_for @post do |f| %>
    <% if @post.errors.any? %>
      <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">
        <ul>
          <% @post.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="mb-4">
      <%= f.label :content, class: "block text-gray-700 text-sm font-bold mb-2" %>
      <%= f.text_area :content, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline", rows: 5 %>
    </div>

    <%= f.submit "Create Post", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
  <% end %>
</div>

# app/views/posts/edit.html.erb
<div class="max-w-4xl mx-auto">
  <h1 class="text-3xl font-bold mb-6">Edit Post</h1>
  
  <%= form_for @post do |f| %>
    <% if @post.errors.any? %>
      <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">
        <ul>
          <% @post.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="mb-4">
      <%= f.label :content, class: "block text-gray-700 text-sm font-bold mb-2" %>
      <%= f.text_area :content, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline", rows: 5 %>
    </div>

    <%= f.submit "Update Post", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
  <% end %>
</div>