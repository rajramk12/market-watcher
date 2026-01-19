class Admin::UploadsController < Admin::BaseController
  def new
  end

  def create
    file = params[:file]

    unless file&.content_type == 'text/csv'
      redirect_to new_admin_upload_path, alert: 'Invalid file type'
      return
    end

    # Save file to persistent location before enqueueing job
    # Use Rails.root/tmp/uploads instead of Rack's temporary directory
    uploads_dir = Rails.root.join('tmp', 'uploads')
    FileUtils.mkdir_p(uploads_dir)

    # Create unique filename to avoid collisions
    filename = "bhav_#{Time.current.to_i}_#{SecureRandom.hex(4)}.csv"
    persistent_path = uploads_dir.join(filename).to_s

    # Copy file to persistent location
    FileUtils.cp(file.path, persistent_path)

    # Enqueue worker with persistent file path
    CsvUploadWorker.perform_async(persistent_path)
    redirect_to new_admin_upload_path, notice: 'File uploaded and processing started'
  rescue StandardError => e
    redirect_to new_admin_upload_path, alert: "Upload failed: #{e.message}"
  end
end
