# encoding: UTF-8

ActiveRecord::Schema.define(:version => 0) do
  self.verbose = false

  # tables for virtual totals
  create_table "authors", :force => true do |t|
    t.string   "name"
    t.string   "nickname"
  end

  create_table "books", :force => true do |t|
    t.integer  "author_id"
    t.string   "author_type", :default => "Author"
    t.string   "name"
    t.boolean  "published", :default => false
    t.boolean  "special",   :default => false
    t.integer  "rating"
    t.datetime "created_on"
  end
  add_index "books", "author_id"
  #add_foreign_key("books", "authors", :column => "author_id")

  create_table "bookmarks", :force => true do |t|
    t.integer  "book_id"
    t.string   "name"
    t.datetime "created_on"
  end
  add_index "bookmarks", "book_id"
  #add_foreign_key("bookmarks", "books", :column => "book_id")
end

