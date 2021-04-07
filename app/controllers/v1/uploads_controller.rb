class V1::UploadsController < ApplicationController
  def recent
    upload = Upload.where(room_id: params[:id]).last
    if !upload.blank?
      render json: { data: UploadSerializer.new(upload).as_json, klass: "Upload" }, status: :ok
    end
  end

  def download
    upload = Upload.find_by_uuid(params[:uuid])
    if !upload.blank?
      send_file "#{Rails.root}/public/#{upload.uuid}/#{upload.uuid}.pdf"
    end
  end

  def index
    uploads = Upload.where(room_id: params[:room_id])
    if !uploads.blank?
      render json: { data: ActiveModel::SerializableResource.new(uploads, user_id: current_user.id, each_serializer: UploadSerializer).as_json, klass: "Upload" }, status: :ok
    end
  end

  def show
    @upload = Upload.find_by_uuid(params[:uuid])
    if !@upload.blank?
      render json: { data: UploadSerializer.new(@upload).as_json, klass: "UploadShow" }, status: :ok
    end
  end

  def create
    @upload = Upload.new(upload_params)
    @upload.user_id = current_user.id
    if @upload.save
      render json: { data: UploadSerializer.new(@upload).as_json, klass: "Upload" }, status: :ok
    end
  end

  def destroy
    @upload = Upload.find(params[:id])
    if @upload.destroy
      render json: { data: @upload, klass: "Upload" }, status: :ok
    else
      render json: { data: @upload.errors.full_messages }, status: :ok
    end
  end

  def upload_params
    params.require(:upload).permit!
  end
end
