json.extract! document, :id, :user_id, :title, :body, :created_at, :updated_at
json.url document_url(document, format: :json)
