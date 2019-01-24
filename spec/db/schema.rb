# encoding: UTF-8

ActiveRecord::Schema.define(:version => 0) do
  self.verbose = false

  # tables for virtual totals
  create_table "vt_authors", :force => true, :id => :integer do |t|
    t.string   "name"
    t.string   "nickname"
  end

  create_table "vt_books", :force => true, :id => :integer do |t|
    t.integer  "author_id"
    t.string   "name"
    t.boolean  "published", :default => false
    t.boolean  "special",   :default => false
    t.integer  "rating"
    t.datetime "created_on"
  end
  #add_index "vt_books", "author_id"
  add_foreign_key("vt_books", "vt_authors", :column => "author_id")

  create_table "vt_bookmarks", :force => true, :id => :integer do |t|
    t.integer  "book_id"
    t.string   "name"
    t.datetime "created_on"
  end
  #add_index "vt_bookmarks", "book_id"
  add_foreign_key("vt_bookmarks", "vt_books", :column => "book_id")
end

