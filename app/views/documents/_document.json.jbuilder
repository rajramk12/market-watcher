json.extract! document, :id, :doc_type, :title, :s3_key, :metadata, :Stock_id, :created_at, :updated_at
json.url document_url(document, format: :json)
