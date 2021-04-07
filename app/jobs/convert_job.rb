class ConvertJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    upload = Upload.find_by_id(upload_id)
    p upload
    p upload_id
    if !upload.blank?
      system("cd #{Rails.root}/public && mkdir #{upload.uuid}")
      system("cd #{Rails.root}/public/#{upload.uuid} && convert -density 150 #{upload.attached_document_path} x-%04d.jpg")
      page_count = %x(ls #{Rails.root}/public/#{upload.uuid} | wc -l).to_i
      dimensions = {}
      for page in 0..(page_count - 1)
        d = %x(identify -format "%wx%h" #{Rails.root}/public/#{upload.uuid}/x-#{enumerator(page)}.jpg)
        a = d.split("x")
        dimensions["#{page}"] = { w: a[0], h: a[1] }
      end
      #system("cd #{Rails.root}/public/#{upload.uuid} && convert *.jpg #{upload.uuid}.pdf")
      upload.dimensions = dimensions
      upload.pages = page_count
      upload.converted = true
      upload.save
    end
  end

  def enumerator(e)
    return "000" + e.to_s if e < 10
    return "00" + e.to_s if e < 100
    return "0" + e.to_s if e < 1000
  end
end
