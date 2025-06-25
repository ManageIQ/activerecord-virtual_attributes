# encoding: UTF-8

ActiveRecord::Schema.define(:version => 0) do
  self.verbose = false

  create_table "authors", :force => true do |t|
    t.integer  "teacher_id", :index => true
    t.string   "name"
    t.string   "nickname"
    t.string   "blurb"
  end

  create_table "books", :force => true do |t|
    t.references "author", :index => true
    t.string     "author_type", :default => "Author"
    t.string     "name"
    t.boolean    "published", :default => false
    t.boolean    "special",   :default => false
    t.integer    "rating"
    t.datetime   "created_on"
  end

  create_table "bookmarks", :force => true do |t|
    t.references "book", :index => true
    t.string     "name"
    t.datetime   "created_on"
  end

  create_join_table "authors", "books", :force => true do |t|
    t.index "author_id"
    t.index "book_id"
  end

  create_table "photos", :force => true do |t|
    t.references "imageable", :polymorphic => true
    t.string "purpose"
    t.string "description"
  end
end
