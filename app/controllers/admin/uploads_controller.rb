class Admin::UploadsController < Admin::BaseController
def new
end


def create
file = params[:file]


unless file&.content_type == 'text/csv'
redirect_to new_admin_upload_path, alert: 'Invalid file type'
return
end


CsvUploadWorker.new.perform(file.path)
redirect_to new_admin_upload_path, notice: 'File uploaded and processing started'
end
end
